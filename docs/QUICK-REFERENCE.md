# ⚡ Référence Rapide - Stripe Flutter Flow

Guide de référence rapide pour l'intégration Stripe.

## 🔑 Clés Stripe

```
Test:
  Public:  pk_test_...  → Flutter Flow (App State)
  Secret:  sk_test_...  → Firebase Functions

Production:
  Public:  pk_live_...  → Flutter Flow (App State)
  Secret:  sk_live_...  → Firebase Functions
```

## 🎯 URLs importantes

**Stripe Dashboard (Test):**
https://dashboard.stripe.com/test/payments

**Stripe Dashboard (Production):**
https://dashboard.stripe.com/payments

**Stripe API Keys:**
https://dashboard.stripe.com/test/apikeys

**Webhooks:**
https://dashboard.stripe.com/test/webhooks

## 💳 Cartes de test

```
Succès:         4242 4242 4242 4242
Décliné:        4000 0000 0000 0002
3D Secure:      4000 0027 6000 3184
Insufficient:   4000 0000 0000 9995

Exp: N'importe quelle date future
CVC: N'importe quel 3 chiffres
```

## 📱 Custom Actions - Paramètres

### createPaymentIntent
```dart
createPaymentIntent(
  amount: 10.50,              // Double (en euros)
  customerEmail: "a@b.com",   // String
  customerName: "John",       // String? (optionnel)
  description: "Achat",       // String? (optionnel)
  metadata: {...}             // Map? (optionnel)
)

// Retourne:
{
  "success": true,
  "clientSecret": "pi_..._secret_...",
  "paymentIntentId": "pi_...",
  "customerId": "cus_..."
}
```

### createSubscription
```dart
createSubscription(
  priceId: "price_...",       // String (depuis Stripe)
  customerEmail: "a@b.com",   // String
  customerName: "John",       // String? (optionnel)
  metadata: {...}             // Map? (optionnel)
)

// Retourne:
{
  "success": true,
  "clientSecret": "pi_..._secret_...",
  "subscriptionId": "sub_...",
  "customerId": "cus_..."
}
```

### confirmPaymentStatus
```dart
confirmPaymentStatus(
  paymentIntentId: "pi_..."   // String
)

// Retourne:
{
  "success": true,
  "status": "succeeded",
  "paymentIntentId": "pi_..."
}
```

## 🎨 Custom Widget - Paramètres

```dart
StripePaymentElement(
  // Requis
  stripePublishableKey: "pk_test_...",
  clientSecret: "pi_..._secret_...",

  // Optionnel
  width: double?,
  height: double?,
  buttonText: "Payer",
  buttonColor: Color,

  // Callbacks
  onPaymentSuccess: () async { ... },
  onPaymentError: (error) async { ... }
)
```

## 🔥 Firebase Functions

### Configuration
```bash
# Définir les clés
firebase functions:config:set \
  stripe.secret_key="sk_test_..." \
  stripe.publishable_key="pk_test_..." \
  stripe.webhook_secret="whsec_..."

# Voir la config
firebase functions:config:get

# Déployer
firebase deploy --only functions

# Voir les logs
firebase functions:log
```

### URL du webhook
```
https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
```

## 📊 Collections Firestore

### payment_intents
```json
{
  "paymentIntentId": "pi_...",
  "amount": 1000,
  "currency": "eur",
  "status": "succeeded",
  "customerEmail": "user@example.com",
  "customerId": "cus_...",
  "firebaseUid": "...",
  "metadata": {},
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### subscriptions
```json
{
  "subscriptionId": "sub_...",
  "priceId": "price_...",
  "status": "active",
  "customerEmail": "user@example.com",
  "customerId": "cus_...",
  "firebaseUid": "...",
  "currentPeriodStart": Timestamp,
  "currentPeriodEnd": Timestamp,
  "metadata": {},
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### orders (exemple - à créer)
```json
{
  "userId": "...",
  "paymentIntentId": "pi_...",
  "amount": 29.99,
  "currency": "EUR",
  "status": "paid",
  "customerEmail": "user@example.com",
  "items": [...],
  "createdAt": Timestamp
}
```

## 🔐 Règles Firestore

```javascript
// payment_intents & subscriptions
// Lecture: uniquement le propriétaire
// Écriture: uniquement via Cloud Functions

// orders
allow read: if request.auth.uid == resource.data.userId;
allow create: if request.auth.uid == request.resource.data.userId;
```

## 📋 Workflow de paiement

```
1. User clique "Payer"
   ↓
2. Custom Action: createPaymentIntent
   ↓
3. Récupération du clientSecret
   ↓
4. Affichage du StripePaymentElement
   ↓
5. User entre ses infos de carte
   ↓
6. User clique "Payer maintenant"
   ↓
7. Stripe traite le paiement
   ↓
8a. Succès → onPaymentSuccess
    └─ Créer commande Firestore
    └─ Rediriger vers confirmation

8b. Échec → onPaymentError
    └─ Afficher message d'erreur
```

## 🛠️ Commandes utiles

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Initialiser le projet
firebase init

# Déployer tout
firebase deploy

# Déployer functions uniquement
firebase deploy --only functions

# Déployer firestore rules uniquement
firebase deploy --only firestore:rules

# Logs en temps réel
firebase functions:log --only

# Tester localement
cd firebase-functions
npm run serve
```

## 🐛 Debugging

### Console navigateur (F12)
```javascript
// Voir les erreurs Stripe
console.log()

// Vérifier les variables
AppState.clientSecret
AppState.paymentIntentId
```

### Firebase Functions logs
```bash
firebase functions:log

# Ou dans Firebase Console:
# Functions > Logs
```

### Stripe Dashboard
```
Developers > Events
  └─ Voir tous les événements en temps réel

Developers > Logs
  └─ Voir les requêtes API
```

## ⚡ Raccourcis Stripe Dashboard

| Page | URL |
|------|-----|
| Paiements | /test/payments |
| Clients | /test/customers |
| Produits | /test/products |
| Abonnements | /test/subscriptions |
| API Keys | /test/apikeys |
| Webhooks | /test/webhooks |
| Événements | /test/events |
| Logs | /test/logs |

## 📚 Documentation

| Resource | URL |
|----------|-----|
| Setup complet | docs/SETUP.md |
| Config Stripe | docs/STRIPE-CONFIGURATION.md |
| Guide Flutter Flow | docs/FLUTTER-FLOW-GUIDE.md |
| Stripe Docs | https://stripe.com/docs |
| Stripe API | https://stripe.com/docs/api |
| Firebase Docs | https://firebase.google.com/docs |
| Flutter Flow | https://docs.flutterflow.io |

## 🎯 Checklist Go-Live

- [ ] Tests complets effectués
- [ ] Webhooks configurés
- [ ] Compte Stripe activé
- [ ] Clés Live configurées
- [ ] Firestore rules déployées
- [ ] Firebase Functions déployées
- [ ] App State mis à jour (pk_live)
- [ ] Tests en production
- [ ] Emails de reçu activés
- [ ] Support client préparé

---

Pour plus de détails, consultez la documentation complète dans `/docs/`
