# Firebase Functions - Stripe Integration

Ce dossier contient les Cloud Functions Firebase pour gérer les paiements Stripe de manière sécurisée.

## 📦 Installation

```bash
cd firebase-functions
npm install
```

## ⚙️ Configuration

### 1. Définir les variables d'environnement

```bash
firebase functions:config:set \
  stripe.secret_key="sk_test_VOTRE_CLE_SECRETE" \
  stripe.publishable_key="pk_test_VOTRE_CLE_PUBLIQUE" \
  stripe.webhook_secret="whsec_VOTRE_WEBHOOK_SECRET"
```

### 2. Vérifier la configuration

```bash
firebase functions:config:get
```

### 3. Déployer

```bash
firebase deploy --only functions
```

## 🔥 Functions disponibles

### createPaymentIntent
Crée un Payment Intent pour un paiement unique.

**Région:** europe-west1
**Type:** onCall (HTTPS Callable)

**Paramètres:**
- `amount` (number) - Montant en centimes
- `currency` (string) - Devise (défaut: "eur")
- `customerEmail` (string) - Email du client
- `customerName` (string, optionnel) - Nom du client
- `metadata` (object, optionnel) - Métadonnées

**Retour:**
```json
{
  "success": true,
  "clientSecret": "pi_..._secret_...",
  "paymentIntentId": "pi_...",
  "customerId": "cus_..."
}
```

### createSubscription
Crée un abonnement récurrent.

**Région:** europe-west1
**Type:** onCall (HTTPS Callable)

**Paramètres:**
- `priceId` (string) - ID du prix Stripe
- `customerEmail` (string) - Email du client
- `customerName` (string, optionnel) - Nom du client
- `metadata` (object, optionnel) - Métadonnées

**Retour:**
```json
{
  "success": true,
  "clientSecret": "pi_..._secret_...",
  "subscriptionId": "sub_...",
  "customerId": "cus_..."
}
```

### confirmPayment
Vérifie le statut d'un paiement.

**Région:** europe-west1
**Type:** onCall (HTTPS Callable)

**Paramètres:**
- `paymentIntentId` (string) - ID du Payment Intent

**Retour:**
```json
{
  "success": true,
  "status": "succeeded",
  "paymentIntentId": "pi_..."
}
```

### stripeWebhook
Endpoint pour recevoir les webhooks Stripe.

**Région:** europe-west1
**Type:** onRequest (HTTPS)

**URL:**
```
https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
```

**Événements gérés:**
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`

### cancelSubscription
Annule un abonnement.

**Région:** europe-west1
**Type:** onCall (HTTPS Callable)

**Paramètres:**
- `subscriptionId` (string) - ID de l'abonnement

**Retour:**
```json
{
  "success": true,
  "status": "canceled"
}
```

## 🧪 Tests locaux

### Lancer l'émulateur

```bash
npm run serve
```

Les functions seront disponibles sur:
```
http://localhost:5001/VOTRE_PROJECT/europe-west1/createPaymentIntent
```

### Tester avec curl

```bash
# Test createPaymentIntent
curl -X POST \
  http://localhost:5001/VOTRE_PROJECT/europe-west1/createPaymentIntent \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "amount": 1000,
      "customerEmail": "test@example.com"
    }
  }'
```

## 📊 Logs

### Voir les logs en temps réel

```bash
firebase functions:log
```

### Voir les logs d'une function spécifique

```bash
firebase functions:log --only createPaymentIntent
```

### Derniers logs

```bash
firebase functions:log --lines 50
```

## 🔒 Sécurité

- ✅ Les clés secrètes sont stockées dans Firebase Config
- ✅ Tous les paiements sont validés côté serveur
- ✅ Les webhooks sont vérifiés avec le signing secret
- ✅ Les données sont sauvegardées dans Firestore de manière sécurisée

## 📝 Firestore Collections

Les functions créent automatiquement ces collections:

### payment_intents
Stocke les informations sur les paiements uniques.

### subscriptions
Stocke les informations sur les abonnements.

## 🐛 Debugging

### Problème: "Function not found"

Vérifiez que les functions sont déployées:
```bash
firebase functions:list
```

### Problème: "Configuration not found"

Définissez la configuration:
```bash
firebase functions:config:set stripe.secret_key="sk_test_..."
```

### Problème: "Stripe is not defined"

Réinstallez les dépendances:
```bash
rm -rf node_modules
npm install
firebase deploy --only functions
```

## 🚀 Déploiement

### Déployer toutes les functions

```bash
firebase deploy --only functions
```

### Déployer une function spécifique

```bash
firebase deploy --only functions:createPaymentIntent
```

### Déployer en production

1. Changez les clés test en clés live:
   ```bash
   firebase functions:config:set \
     stripe.secret_key="sk_live_..." \
     stripe.publishable_key="pk_live_..."
   ```

2. Déployez:
   ```bash
   firebase deploy --only functions
   ```

## 📚 Ressources

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Stripe Node.js Library](https://github.com/stripe/stripe-node)
- [Stripe API Reference](https://stripe.com/docs/api)

## 🆘 Support

En cas de problème, consultez:
- [../docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
- [../docs/SETUP.md](../docs/SETUP.md)
