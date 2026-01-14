const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Stripe
const stripeSecretKey = functions.config().stripe?.secret_key;
const stripeClient = stripe(stripeSecretKey);

/**
 * Cloud Function: cancelSubscription
 *
 * Annule un abonnement Stripe
 *
 * Inputs:
 * - subscriptionId (String): ID de l'abonnement à annuler
 *
 * Output (JSON):
 * {
 *   "success": true,
 *   "status": "canceled"
 * }
 */
exports.cancelSubscription = functions.region('europe-west1')
    .runWith({
        timeoutSeconds: 60,
        memory: '256MB'
    }).https.onCall((data, context) => {
        return new Promise(async (resolve, reject) => {
            try {
                const subscriptionId = data.subscriptionId;

                if (!subscriptionId) {
                    reject(new functions.https.HttpsError(
                        'invalid-argument',
                        'Le subscriptionId est requis'
                    ));
                    return;
                }

                // Annuler l'abonnement sur Stripe
                const subscription = await stripeClient.subscriptions.cancel(subscriptionId);

                // Mettre à jour Firestore
                await admin.firestore()
                    .collection('subscriptions')
                    .doc(subscriptionId)
                    .update({
                        status: 'canceled',
                        canceledAt: admin.firestore.FieldValue.serverTimestamp(),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                // Retourner le résultat
                resolve({
                    success: true,
                    status: subscription.status
                });

            } catch (error) {
                console.error('Erreur cancelSubscription:', error);
                reject(new functions.https.HttpsError(
                    'internal',
                    error.message || 'Erreur lors de l\'annulation'
                ));
            }
        });
    });
