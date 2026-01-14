const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Stripe
const stripeSecretKey = functions.config().stripe?.secret_key;
const stripeClient = stripe(stripeSecretKey);

/**
 * Cloud Function: confirmPayment
 *
 * Vérifie le statut d'un Payment Intent
 *
 * Inputs:
 * - paymentIntentId (String): ID du Payment Intent à vérifier
 *
 * Output (JSON):
 * {
 *   "success": true,
 *   "status": "succeeded",
 *   "paymentIntentId": "pi_..."
 * }
 */
exports.confirmPayment = functions.region('europe-west1')
    .runWith({
        timeoutSeconds: 60,
        memory: '256MB'
    }).https.onCall((data, context) => {
        return new Promise(async (resolve, reject) => {
            try {
                const paymentIntentId = data.paymentIntentId;

                if (!paymentIntentId) {
                    reject(new functions.https.HttpsError(
                        'invalid-argument',
                        'Le paymentIntentId est requis'
                    ));
                    return;
                }

                // Récupérer le Payment Intent depuis Stripe
                const paymentIntent = await stripeClient.paymentIntents.retrieve(paymentIntentId);

                // Mettre à jour Firestore si nécessaire
                const docRef = admin.firestore().collection('payment_intents').doc(paymentIntentId);
                const doc = await docRef.get();

                if (doc.exists) {
                    await docRef.update({
                        status: paymentIntent.status,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }

                // Retourner le résultat
                resolve({
                    success: paymentIntent.status === 'succeeded',
                    status: paymentIntent.status,
                    paymentIntentId: paymentIntent.id
                });

            } catch (error) {
                console.error('Erreur confirmPayment:', error);
                reject(new functions.https.HttpsError(
                    'internal',
                    error.message || 'Erreur lors de la confirmation'
                ));
            }
        });
    });
