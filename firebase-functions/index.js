const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');
const cors = require('cors')({ origin: true });

// Initialiser Firebase Admin
admin.initializeApp();

// Initialiser Stripe avec la clé secrète
// En production, utilisez: firebase functions:config:set stripe.secret_key="sk_live_..."
const stripeSecretKey = functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY;
const stripeClient = stripe(stripeSecretKey);

/**
 * Fonction pour créer un Payment Intent (paiement unique)
 *
 * Paramètres attendus:
 * - amount: montant en centimes (ex: 1000 = 10.00€)
 * - currency: devise (ex: "eur")
 * - customerEmail: email du client
 * - customerName: nom du client (optionnel)
 * - metadata: données additionnelles (optionnel)
 */
exports.createPaymentIntent = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    try {
      // Validation des paramètres
      if (!data.amount || data.amount <= 0) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Le montant doit être supérieur à 0'
        );
      }

      if (!data.customerEmail) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          "L'email du client est requis"
        );
      }

      // Créer ou récupérer le client Stripe
      let customer;
      const existingCustomers = await stripeClient.customers.list({
        email: data.customerEmail,
        limit: 1
      });

      if (existingCustomers.data.length > 0) {
        customer = existingCustomers.data[0];
      } else {
        customer = await stripeClient.customers.create({
          email: data.customerEmail,
          name: data.customerName || undefined,
          metadata: {
            firebaseUid: context.auth?.uid || 'anonymous'
          }
        });
      }

      // Créer le Payment Intent
      const paymentIntent = await stripeClient.paymentIntents.create({
        amount: Math.round(data.amount), // Montant en centimes
        currency: data.currency || 'eur',
        customer: customer.id,
        metadata: {
          firebaseUid: context.auth?.uid || 'anonymous',
          customerEmail: data.customerEmail,
          ...data.metadata
        },
        automatic_payment_methods: {
          enabled: true,
        },
      });

      // Sauvegarder dans Firestore
      await admin.firestore().collection('payment_intents').doc(paymentIntent.id).set({
        paymentIntentId: paymentIntent.id,
        amount: data.amount,
        currency: data.currency || 'eur',
        status: paymentIntent.status,
        customerEmail: data.customerEmail,
        customerId: customer.id,
        firebaseUid: context.auth?.uid || 'anonymous',
        metadata: data.metadata || {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        customerId: customer.id
      };

    } catch (error) {
      console.error('Erreur lors de la création du Payment Intent:', error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de la création du paiement'
      );
    }
  });

/**
 * Fonction pour créer un abonnement (paiement récurrent)
 *
 * Paramètres attendus:
 * - priceId: ID du prix Stripe (ex: "price_...")
 * - customerEmail: email du client
 * - customerName: nom du client (optionnel)
 * - metadata: données additionnelles (optionnel)
 */
exports.createSubscription = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    try {
      // Validation des paramètres
      if (!data.priceId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Le priceId est requis'
        );
      }

      if (!data.customerEmail) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          "L'email du client est requis"
        );
      }

      // Créer ou récupérer le client Stripe
      let customer;
      const existingCustomers = await stripeClient.customers.list({
        email: data.customerEmail,
        limit: 1
      });

      if (existingCustomers.data.length > 0) {
        customer = existingCustomers.data[0];
      } else {
        customer = await stripeClient.customers.create({
          email: data.customerEmail,
          name: data.customerName || undefined,
          metadata: {
            firebaseUid: context.auth?.uid || 'anonymous'
          }
        });
      }

      // Créer l'abonnement
      const subscription = await stripeClient.subscriptions.create({
        customer: customer.id,
        items: [{ price: data.priceId }],
        payment_behavior: 'default_incomplete',
        payment_settings: {
          save_default_payment_method: 'on_subscription',
          payment_method_types: ['card']
        },
        expand: ['latest_invoice.payment_intent'],
        metadata: {
          firebaseUid: context.auth?.uid || 'anonymous',
          customerEmail: data.customerEmail,
          ...data.metadata
        }
      });

      // Sauvegarder dans Firestore
      await admin.firestore().collection('subscriptions').doc(subscription.id).set({
        subscriptionId: subscription.id,
        priceId: data.priceId,
        status: subscription.status,
        customerEmail: data.customerEmail,
        customerId: customer.id,
        firebaseUid: context.auth?.uid || 'anonymous',
        metadata: data.metadata || {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      const clientSecret = subscription.latest_invoice.payment_intent.client_secret;

      return {
        success: true,
        clientSecret: clientSecret,
        subscriptionId: subscription.id,
        customerId: customer.id
      };

    } catch (error) {
      console.error('Erreur lors de la création de l\'abonnement:', error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de la création de l\'abonnement'
      );
    }
  });

/**
 * Webhook Stripe pour gérer les événements
 * (confirmation de paiement, échec, etc.)
 */
exports.stripeWebhook = functions
  .region('europe-west1')
  .https.onRequest((req, res) => {
    return cors(req, res, async () => {
      const sig = req.headers['stripe-signature'];
      const webhookSecret = functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET;

      let event;

      try {
        event = stripeClient.webhooks.constructEvent(
          req.rawBody,
          sig,
          webhookSecret
        );
      } catch (err) {
        console.error('Erreur webhook:', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
      }

      // Gérer les différents types d'événements
      switch (event.type) {
        case 'payment_intent.succeeded':
          const paymentIntent = event.data.object;
          await admin.firestore()
            .collection('payment_intents')
            .doc(paymentIntent.id)
            .update({
              status: 'succeeded',
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          console.log('PaymentIntent succeeded:', paymentIntent.id);
          break;

        case 'payment_intent.payment_failed':
          const failedIntent = event.data.object;
          await admin.firestore()
            .collection('payment_intents')
            .doc(failedIntent.id)
            .update({
              status: 'failed',
              error: failedIntent.last_payment_error?.message || 'Paiement échoué',
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
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
            .update({
              status: 'canceled',
              canceledAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          console.log('Subscription canceled:', deletedSub.id);
          break;

        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      res.json({ received: true });
    });
  });

/**
 * Fonction pour confirmer un paiement
 * (appelée après que l'utilisateur ait soumis le formulaire)
 */
exports.confirmPayment = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    try {
      const { paymentIntentId } = data;

      if (!paymentIntentId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Le paymentIntentId est requis'
        );
      }

      const paymentIntent = await stripeClient.paymentIntents.retrieve(paymentIntentId);

      return {
        success: paymentIntent.status === 'succeeded',
        status: paymentIntent.status,
        paymentIntentId: paymentIntent.id
      };

    } catch (error) {
      console.error('Erreur lors de la confirmation du paiement:', error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de la confirmation'
      );
    }
  });

/**
 * Fonction pour annuler un abonnement
 */
exports.cancelSubscription = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    try {
      const { subscriptionId } = data;

      if (!subscriptionId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Le subscriptionId est requis'
        );
      }

      const subscription = await stripeClient.subscriptions.cancel(subscriptionId);

      await admin.firestore()
        .collection('subscriptions')
        .doc(subscriptionId)
        .update({
          status: 'canceled',
          canceledAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

      return {
        success: true,
        status: subscription.status
      };

    } catch (error) {
      console.error('Erreur lors de l\'annulation de l\'abonnement:', error);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Erreur lors de l\'annulation'
      );
    }
  });
