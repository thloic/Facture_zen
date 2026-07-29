const test = require('node:test');
const assert = require('node:assert/strict');
const {resolvePlanKey, resolvePlanFromEntitlements, isAuthorized, PLAN_LIMITS} = require('../lib/planResolver');

test('resolvePlanKey: reconnaît les variantes de nommage RevenueCat', () => {
  assert.equal(resolvePlanKey('zen_basic'), 'zen_basic');
  assert.equal(resolvePlanKey('basic_annuel'), 'zen_basic');
  assert.equal(resolvePlanKey('zen_pro'), 'zen_pro');
  assert.equal(resolvePlanKey('pro_mensuel'), 'zen_pro');
  assert.equal(resolvePlanKey('rent_up_pro'), 'rent_up_pro');
  assert.equal(resolvePlanKey('zen_entreprise'), 'zen_entreprise');
  assert.equal(resolvePlanKey('zen_enterprise'), 'zen_entreprise');
  assert.equal(resolvePlanKey('inconnu'), 'inconnu');
});

test('resolvePlanFromEntitlements: aucun entitlement -> Zen Gratuit', () => {
  const plan = resolvePlanFromEntitlements({});
  assert.deepEqual(plan, PLAN_LIMITS.zen_gratuit);
});

test('resolvePlanFromEntitlements: entitlement actif sans expiration -> plan correspondant', () => {
  const plan = resolvePlanFromEntitlements({
    'Zen Pro': {expires_date: null},
  });
  assert.equal(plan.name, 'Zen Pro');
  assert.equal(plan.isPremium, true);
  assert.equal(plan.monthlyInvoiceLimit, 500);
});

test('resolvePlanFromEntitlements: entitlement expiré est ignoré -> Zen Gratuit', () => {
  const now = Date.parse('2026-07-29T00:00:00Z');
  const plan = resolvePlanFromEntitlements(
    {'Zen Pro': {expires_date: '2026-01-01T00:00:00Z'}},
    now,
  );
  assert.deepEqual(plan, PLAN_LIMITS.zen_gratuit);
});

test('resolvePlanFromEntitlements: entitlement encore valide (non expiré) reste actif', () => {
  const now = Date.parse('2026-07-29T00:00:00Z');
  const plan = resolvePlanFromEntitlements(
    {'Zen Basic': {expires_date: '2026-08-01T00:00:00Z'}},
    now,
  );
  assert.equal(plan.name, 'Zen Basic');
});

test('resolvePlanFromEntitlements: garde le plan le plus élevé parmi plusieurs entitlements actifs', () => {
  const plan = resolvePlanFromEntitlements({
    'zen-basic': {expires_date: null},
    'zen-entreprise': {expires_date: null},
  });
  assert.equal(plan.name, 'Zen Entreprise');
  assert.equal(plan.monthlyInvoiceLimit, 5000);
});

test('resolvePlanFromEntitlements: normalise espaces et tirets', () => {
  const plan = resolvePlanFromEntitlements({
    'Zen Entreprise': {expires_date: null},
  });
  assert.equal(plan.name, 'Zen Entreprise');
});

test('isAuthorized: rejette un secret manquant ou vide', () => {
  assert.equal(isAuthorized(undefined, 'expected'), false);
  assert.equal(isAuthorized('', 'expected'), false);
  assert.equal(isAuthorized('anything', ''), false);
  assert.equal(isAuthorized('anything', undefined), false);
});

test('isAuthorized: rejette une valeur incorrecte', () => {
  assert.equal(isAuthorized('wrong-value', 'expected-secret'), false);
});

test('isAuthorized: accepte la valeur exacte attendue', () => {
  assert.equal(isAuthorized('expected-secret', 'expected-secret'), true);
});

test('isAuthorized: rejette même avec un préfixe correct (pas de faille de comparaison partielle)', () => {
  assert.equal(isAuthorized('expected-secre', 'expected-secret'), false);
  assert.equal(isAuthorized('expected-secretX', 'expected-secret'), false);
});
