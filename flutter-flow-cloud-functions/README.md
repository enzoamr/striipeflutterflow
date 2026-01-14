# ☁️ Cloud Functions Stripe pour Flutter Flow

Ce dossier contient les Cloud Functions optimisées pour être déployées **directement dans Flutter Flow**.

## 📁 Contenu

```
flutter-flow-cloud-functions/
├── createPaymentIntent.js         # Paiements uniques
├── createSubscription.js          # Abonnements récurrents
├── confirmPayment.js              # Vérification de paiement
├── cancelSubscription.js          # Annulation d'abonnement
├── stripeWebhook.js               # Webhook Stripe
├── package.json                   # Dépendances npm
├── FLUTTER-FLOW-DEPLOYMENT.md     # Guide de déploiement détaillé
└── README.md                      # Ce fichier
```

## 🚀 Démarrage rapide

### 1. Prérequis
- Projet Flutter Flow avec Firebase configuré
- Plan Firebase **Blaze** (obligatoire)
- Compte Stripe avec clés API

### 2. Ajouter les functions

1. **Ouvrir Flutter Flow** > Cloud Functions
2. **Configurer package.json** (ajouter `stripe: ^14.10.0`)
3. **Pour chaque function:**
   - Cliquer sur **+ Add**
   - Copier le code depuis les fichiers `.js`
   - Configurer les paramètres (voir ci-dessous)
   - **Deploy**

### 3. Configuration des functions

| Function | Memory | Timeout | Return Type |
|----------|--------|---------|-------------|
| createPaymentIntent | 512MB | 120s | JSON |
| createSubscription | 512MB | 120s | JSON |
| confirmPayment | 256MB | 60s | JSON |
| cancelSubscription | 256MB | 60s | JSON |
| stripeWebhook | 512MB | 60s | HTTP (pas de return) |

**Région:** `europe-west1` (pour toutes)

## 📋 Paramètres de chaque function

### createPaymentIntent
**Inputs:**
- `amount` (Number) - Montant en euros
- `customerEmail` (String) - Email du client
- `customerName` (String, optionnel) - Nom
- `description` (String, optionnel) - Description
- `metadata` (JSON, optionnel) - Métadonnées

**Output:** JSON
```json
{
  "success": true,
  "clientSecret": "pi_..._secret_...",
  "paymentIntentId": "pi_...",
  "customerId": "cus_..."
}
```

### createSubscription
**Inputs:**
- `priceId` (String) - ID du prix Stripe
- `customerEmail` (String) - Email du client
- `customerName` (String, optionnel) - Nom
- `metadata` (JSON, optionnel) - Métadonnées

**Output:** JSON
```json
{
  "success": true,
  "clientSecret": "pi_..._secret_...",
  "subscriptionId": "sub_...",
  "customerId": "cus_..."
}
```

### confirmPayment
**Inputs:**
- `paymentIntentId` (String) - ID du Payment Intent

**Output:** JSON
```json
{
  "success": true,
  "status": "succeeded",
  "paymentIntentId": "pi_..."
}
```

### cancelSubscription
**Inputs:**
- `subscriptionId` (String) - ID de l'abonnement

**Output:** JSON
```json
{
  "success": true,
  "status": "canceled"
}
```

### stripeWebhook
**Type:** HTTP Request Function (pas Callable)

**Pas de paramètres** - Reçoit les événements Stripe directement

**URL après déploiement:**
```
https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
```

## 🔐 Configuration Stripe

Avant de déployer, configurez vos clés Stripe dans Firebase:

### Via Firebase Console:
1. https://console.firebase.google.com
2. Votre projet > Functions > Configuration
3. Ajoutez:
   - `stripe.secret_key` = `sk_test_...`
   - `stripe.publishable_key` = `pk_test_...`
   - `stripe.webhook_secret` = `whsec_...`

### Via CLI (optionnel):
```bash
firebase functions:config:set \
  stripe.secret_key="sk_test_..." \
  stripe.publishable_key="pk_test_..." \
  stripe.webhook_secret="whsec_..."
```

## 📖 Documentation complète

Pour un guide détaillé pas-à-pas:
👉 **Consultez [FLUTTER-FLOW-DEPLOYMENT.md](FLUTTER-FLOW-DEPLOYMENT.md)**

## 🎨 Utilisation dans Flutter Flow

Une fois les functions déployées, utilisez-les dans vos actions:

```
Backend Call > Cloud Function
└─ Function: createPaymentIntent
└─ Parameters:
    - amount: 10.50
    - customerEmail: "user@example.com"
└─ Action Output Variable: paymentResult
```

Puis récupérez le résultat:
```
Update App State
└─ clientSecret = paymentResult.clientSecret
```

## 🔍 Différences avec les functions standard

Ces functions sont optimisées pour Flutter Flow:

| Aspect | Standard | Flutter Flow |
|--------|----------|--------------|
| Format | `exports.func = functions...` | ✅ Compatible |
| Promises | Oui | ✅ return new Promise |
| Error handling | HttpsError | ✅ HttpsError |
| Logs | console.log | ✅ console.log |
| Region | Configurable | ✅ europe-west1 |

## ✅ Checklist de déploiement

- [ ] Plan Firebase Blaze activé
- [ ] package.json mis à jour avec Stripe
- [ ] Clés Stripe configurées dans Firebase
- [ ] 5 Cloud Functions ajoutées dans Flutter Flow
- [ ] Toutes les functions déployées avec succès
- [ ] Webhook configuré dans Stripe Dashboard
- [ ] Tests effectués

## 🐛 Debug

### Voir les logs:
- Flutter Flow > Cloud Functions > [Function] > Logs
- Firebase Console > Functions > Logs
- Google Cloud Console > Logging

### Problèmes courants:
- **"stripe is not defined"** → Vérifiez package.json
- **"Configuration not found"** → Configurez les clés Stripe
- **"Invalid API key"** → Vérifiez test vs live

## 🆘 Support

- [Guide de déploiement complet](FLUTTER-FLOW-DEPLOYMENT.md)
- [Documentation Flutter Flow](https://docs.flutterflow.io/actions/cloud-functions)
- [Documentation Stripe](https://stripe.com/docs)

---

**Prêt à déployer !** 🚀
