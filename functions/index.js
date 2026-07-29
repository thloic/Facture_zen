const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const {resolvePlanFromEntitlements, isAuthorized} = require('./lib/planResolver');

admin.initializeApp();

// Configurés via `firebase functions:secrets:set` (voir README de ce dossier).
const REVENUECAT_AUTH_HEADER = defineSecret('REVENUECAT_AUTH_HEADER');
const REVENUECAT_SECRET_API_KEY = defineSecret('REVENUECAT_SECRET_API_KEY');

async function fetchSubscriber(appUserId, secretApiKey) {
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    {headers: {Authorization: `Bearer ${secretApiKey}`}},
  );
  if (!response.ok) {
    throw new Error(`RevenueCat API error ${response.status}: ${await response.text()}`);
  }
  const data = await response.json();
  return data.subscriber;
}

/**
 * Receives RevenueCat webhook events and is the ONLY writer allowed (via the
 * Admin SDK, which bypasses database.rules.json) for users/$uid's isPremium,
 * monthlyInvoiceLimit, allowedTemplatesCount and planName fields.
 *
 * Configure this URL + the REVENUECAT_AUTH_HEADER value in the RevenueCat
 * dashboard: Project Settings → Integrations → Webhooks.
 */
exports.revenueCatWebhook = onRequest(
  {secrets: [REVENUECAT_AUTH_HEADER, REVENUECAT_SECRET_API_KEY], region: 'europe-west1'},
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    if (!isAuthorized(req.get('Authorization'), REVENUECAT_AUTH_HEADER.value())) {
      logger.warn('Rejected RevenueCat webhook call: invalid Authorization header');
      res.status(401).send('Unauthorized');
      return;
    }

    const event = req.body && req.body.event;
    const appUserId = event && event.app_user_id;

    if (!appUserId) {
      logger.warn('RevenueCat webhook payload missing event.app_user_id', {body: req.body});
      res.status(400).send('Missing app_user_id');
      return;
    }

    // Purchases made before RevenueCat login() is called against a Firebase
    // UID use RevenueCat's own anonymous ID — there is no matching Firebase
    // user node to update yet, so there is nothing to do.
    if (appUserId.startsWith('$RCAnonymousID:')) {
      res.status(200).send('Ignored: anonymous app_user_id');
      return;
    }

    try {
      const subscriber = await fetchSubscriber(appUserId, REVENUECAT_SECRET_API_KEY.value());
      const plan = resolvePlanFromEntitlements(subscriber.entitlements);

      await admin.database().ref(`users/${appUserId}`).update({
        isPremium: plan.isPremium,
        monthlyInvoiceLimit: plan.monthlyInvoiceLimit,
        allowedTemplatesCount: plan.allowedTemplatesCount,
        planName: plan.name,
        lastUpdated: admin.database.ServerValue.TIMESTAMP,
      });

      logger.info(`Updated plan for ${appUserId}: ${plan.name}`, {eventType: event.type});
      res.status(200).send('OK');
    } catch (err) {
      logger.error('Failed to process RevenueCat webhook', err);
      res.status(500).send('Internal error');
    }
  },
);
