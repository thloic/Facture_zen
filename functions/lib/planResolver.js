const {timingSafeEqual} = require('crypto');

// Doit rester synchronisé avec PLAN_LIMITS dans
// lib/features/invoicing/services/subscription_sync_service.dart
const PLAN_LIMITS = {
  zen_gratuit: {name: 'Zen Gratuit', monthlyInvoiceLimit: 3, allowedTemplatesCount: 2, isPremium: false},
  zen_basic: {name: 'Zen Basic', monthlyInvoiceLimit: 100, allowedTemplatesCount: 7, isPremium: true},
  zen_pro: {name: 'Zen Pro', monthlyInvoiceLimit: 500, allowedTemplatesCount: -1, isPremium: true},
  zen_entreprise: {name: 'Zen Entreprise', monthlyInvoiceLimit: 5000, allowedTemplatesCount: -1, isPremium: true},
  rent_up_pro: {name: 'Zen Pro', monthlyInvoiceLimit: 500, allowedTemplatesCount: -1, isPremium: true},
};

function resolvePlanKey(normalizedId) {
  if (normalizedId.includes('basic')) return 'zen_basic';
  if (normalizedId === 'zen_pro') return 'zen_pro';
  if (normalizedId === 'rent_up_pro') return 'rent_up_pro';
  if (normalizedId.includes('pro')) return 'zen_pro';
  if (normalizedId.includes('entreprise') || normalizedId.includes('enterprise')) return 'zen_entreprise';
  return normalizedId;
}

function resolvePlanFromEntitlements(entitlements, now = Date.now()) {
  let highestPlan = null;

  for (const [entitlementId, info] of Object.entries(entitlements || {})) {
    const expiresMs = info.expires_date ? Date.parse(info.expires_date) : null;
    const isActive = expiresMs === null || Number.isNaN(expiresMs) || expiresMs > now;
    if (!isActive) continue;

    const normalizedId = entitlementId.toLowerCase().replace(/ /g, '_').replace(/-/g, '_');
    const plan = PLAN_LIMITS[resolvePlanKey(normalizedId)];
    if (plan && (!highestPlan || plan.monthlyInvoiceLimit > highestPlan.monthlyInvoiceLimit)) {
      highestPlan = plan;
    }
  }

  return highestPlan || PLAN_LIMITS.zen_gratuit;
}

function isAuthorized(receivedHeader, expected) {
  if (!expected || !receivedHeader) return false;
  const a = Buffer.from(receivedHeader);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

module.exports = {PLAN_LIMITS, resolvePlanKey, resolvePlanFromEntitlements, isAuthorized};
