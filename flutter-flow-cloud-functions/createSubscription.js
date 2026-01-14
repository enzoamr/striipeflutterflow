const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Initialize Stripe
const stripeSecretKey = functions.config().stripe?.secret_key;
const stripeClient = stripe(stripeSecretKey);

/**
 * Cloud Function: createSubscription
 *
 * Crée un abonnement Stripe récurrent
 *
 * Inputs:
 * - priceId (String): ID du prix Stripe (ex: "price_1234...")
 * - customerEmail (String): Email du client
 * - customerName (String, optional): Nom du client
 * - metadata (JSON, optional): Métadonnées additionnelles
 *
 * Output (JSON):
 * {
 *   "success": true,
 *   "clientSecret": "pi_..._secret_...",
 *   "subscriptionId": "sub_...",
 *   "customerId": "cus_..."
 * }
 */
exports.createSubscription = functions.region('europe-west1')
    .runWith({
        timeoutSeconds: 120,
        memory: '512MB'
    }).https.onCall((data, context) => {
        return new Promise(async (resolve, reject) => {
            try {
                // Validation des paramètres
                const priceId = data.priceId;
                const customerEmail = data.customerEmail;

                if (!priceId) {
                    reject(new functions.https.HttpsError(
                        'invalid-argument',
                        'Le priceId est requis'
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

                // Créer l'abonnement
                const subscription = await stripeClient.subscriptions.create({
                    customer: customer.id,
                    items: [{ price: priceId }],
                    payment_behavior: 'default_incomplete',
                    payment_settings: {
                        save_default_payment_method: 'on_subscription',
                        payment_method_types: ['card']
                    },
                    expand: ['latest_invoice.payment_intent'],
                    metadata: {
                        firebaseUid: context.auth?.uid || 'anonymous',
                        customerEmail: customerEmail,
                        ...data.metadata
                    }
                });

                // Sauvegarder dans Firestore
                await admin.firestore().collection('subscriptions').doc(subscription.id).set({
                    subscriptionId: subscription.id,
                    priceId: priceId,
                    status: subscription.status,
                    customerEmail: customerEmail,
                    customerId: customer.id,
                    firebaseUid: context.auth?.uid || 'anonymous',
                    metadata: data.metadata || {},
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                const clientSecret = subscription.latest_invoice.payment_intent.client_secret;

                // Retourner le résultat
                resolve({
                    success: true,
                    clientSecret: clientSecret,
                    subscriptionId: subscription.id,
                    customerId: customer.id
                });

            } catch (error) {
                console.error('Erreur createSubscription:', error);
                reject(new functions.https.HttpsError(
                    'internal',
                    error.message || 'Erreur lors de la création de l\'abonnement'
                ));
            }
        });
    });
