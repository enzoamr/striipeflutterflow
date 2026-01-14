const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Stripe - La clé sera configurée dans Firebase Config
const stripeSecretKey = functions.config().stripe?.secret_key;
const stripeClient = stripe(stripeSecretKey);

/**
 * Cloud Function: createPaymentIntent
 *
 * Crée un Payment Intent Stripe pour un paiement unique
 *
 * Inputs:
 * - amount (Number): Montant en euros (ex: 10.50)
 * - customerEmail (String): Email du client
 * - customerName (String, optional): Nom du client
 * - description (String, optional): Description du paiement
 * - metadata (JSON, optional): Métadonnées additionnelles
 *
 * Output (JSON):
 * {
 *   "success": true,
 *   "clientSecret": "pi_..._secret_...",
 *   "paymentIntentId": "pi_...",
 *   "customerId": "cus_..."
 * }
 */
exports.createPaymentIntent = functions.region('europe-west1')
    .runWith({
        timeoutSeconds: 120,
        memory: '512MB'
    }).https.onCall((data, context) => {
        return new Promise(async (resolve, reject) => {
            try {
                // Validation des paramètres
                const amount = data.amount;
                const customerEmail = data.customerEmail;

                if (!amount || amount <= 0) {
                    reject(new functions.https.HttpsError(
                        'invalid-argument',
                        'Le montant doit être supérieur à 0'
                    ));
                    return;
                }

                if (!customerEmail) {
                    reject(new functions.https.HttpsError(
                        'invalid-argument',
                        "L'email du client est requis"
                    ));
                    return;
                }

                // Convertir le montant en centimes
                const amountInCents = Math.round(amount * 100);

                // Créer ou récupérer le client Stripe
                let customer;
                const existingCustomers = await stripeClient.customers.list({
                    email: customerEmail,
                    limit: 1
                });

                if (existingCustomers.data.length > 0) {
                    customer = existingCustomers.data[0];
                } else {
                    customer = await stripeClient.customers.create({
                        email: customerEmail,
                        name: data.customerName || undefined,
                        metadata: {
                            firebaseUid: context.auth?.uid || 'anonymous'
                        }
                    });
                }

                // Créer le Payment Intent
                const paymentIntent = await stripeClient.paymentIntents.create({
                    amount: amountInCents,
                    currency: 'eur',
                    customer: customer.id,
                    description: data.description || undefined,
                    metadata: {
                        firebaseUid: context.auth?.uid || 'anonymous',
                        customerEmail: customerEmail,
                        ...data.metadata
                    },
                    automatic_payment_methods: {
                        enabled: true,
                    },
                });

                // Sauvegarder dans Firestore
                await admin.firestore().collection('payment_intents').doc(paymentIntent.id).set({
                    paymentIntentId: paymentIntent.id,
                    amount: amountInCents,
                    currency: 'eur',
                    status: paymentIntent.status,
                    customerEmail: customerEmail,
                    customerId: customer.id,
                    firebaseUid: context.auth?.uid || 'anonymous',
                    metadata: data.metadata || {},
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Retourner le résultat
                resolve({
                    success: true,
                    clientSecret: paymentIntent.client_secret,
                    paymentIntentId: paymentIntent.id,
                    customerId: customer.id
                });

            } catch (error) {
                console.error('Erreur createPaymentIntent:', error);
                reject(new functions.https.HttpsError(
                    'internal',
                    error.message || 'Erreur lors de la création du paiement'
                ));
            }
        });
    });
