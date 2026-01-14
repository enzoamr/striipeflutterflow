const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Stripe
const stripeSecretKey = functions.config().stripe?.secret_key;
const webhookSecret = functions.config().stripe?.webhook_secret;
const stripeClient = stripe(stripeSecretKey);

/**
 * Cloud Function: stripeWebhook
 *
 * Webhook pour recevoir les événements Stripe
 * ATTENTION: C'est une fonction onRequest (HTTP), pas onCall
 *
 * Configuration dans Flutter Flow:
 * - Type: HTTP Request Function (pas callable)
 * - Memory: 512MB
 * - Timeout: 60s
 * - Region: europe-west1
 *
 * URL du webhook à configurer dans Stripe Dashboard:
 * https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
 *
 * Événements gérés:
 * - payment_intent.succeeded
 * - payment_intent.payment_failed
 * - customer.subscription.created
 * - customer.subscription.updated
 * - customer.subscription.deleted
 */
exports.stripeWebhook = functions.region('europe-west1')
    .runWith({
        timeoutSeconds: 60,
        memory: '512MB'
    }).https.onRequest(async (req, res) => {
        // CORS headers
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type, stripe-signature');

        if (req.method === 'OPTIONS') {
            res.status(204).send('');
            return;
        }

        const sig = req.headers['stripe-signature'];
        let event;

        try {
            // Vérifier la signature du webhook
            event = stripeClient.webhooks.constructEvent(
                req.rawBody,
                sig,
                webhookSecret
            );
        } catch (err) {
            console.error('Erreur webhook signature:', err.message);
            res.status(400).send(`Webhook Error: ${err.message}`);
            return;
        }

        console.log('Webhook reçu:', event.type);

        // Gérer les différents types d'événements
        try {
            switch (event.type) {
                case 'payment_intent.succeeded':
                    const paymentIntent = event.data.object;
                    await admin.firestore()
                        .collection('payment_intents')
                        .doc(paymentIntent.id)
                        .set({
                            status: 'succeeded',
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        }, { merge: true });
                    console.log('PaymentIntent succeeded:', paymentIntent.id);
                    break;

                case 'payment_intent.payment_failed':
                    const failedIntent = event.data.object;
                    await admin.firestore()
                        .collection('payment_intents')
                        .doc(failedIntent.id)
                        .set({
                            status: 'failed',
                            error: failedIntent.last_payment_error?.message || 'Paiement échoué',
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        }, { merge: true });
                    console.log('PaymentIntent failed:', failedIntent.id);
                    break;

                case 'customer.subscription.created':
                case 'customer.subscription.updated':
                    const subscription = event.data.object;
                    await admin.firestore()
                        .collection('subscriptions')
                        .doc(subscription.id)
                        .set({
                            subscriptionId: subscription.id,
                            status: subscription.status,
                            currentPeriodStart: new Date(subscription.current_period_start * 1000),
                            currentPeriodEnd: new Date(subscription.current_period_end * 1000),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        }, { merge: true });
                    console.log('Subscription updated:', subscription.id);
                    break;

                case 'customer.subscription.deleted':
                    const deletedSub = event.data.object;
                    await admin.firestore()
                        .collection('subscriptions')
                        .doc(deletedSub.id)
                        .set({
                            status: 'canceled',
                            canceledAt: admin.firestore.FieldValue.serverTimestamp(),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        }, { merge: true });
                    console.log('Subscription canceled:', deletedSub.id);
                    break;

                default:
                    console.log(`Événement non géré: ${event.type}`);
            }

            res.json({ received: true });
        } catch (error) {
            console.error('Erreur traitement webhook:', error);
            res.status(500).send('Erreur serveur');
        }
    });
