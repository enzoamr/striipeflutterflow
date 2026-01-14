# 🚀 Guide de Déploiement Flutter Flow - Cloud Functions Stripe

Ce guide vous montre comment ajouter et déployer les Cloud Functions Stripe **directement dans Flutter Flow**.

## 📋 Prérequis

- ✅ Projet Flutter Flow créé
- ✅ Firebase configuré dans Flutter Flow
- ✅ Plan Firebase **Blaze** (requis pour Cloud Functions)
- ✅ Compte Stripe avec clés API

## 🎯 Vue d'ensemble

Vous allez ajouter **5 Cloud Functions** dans Flutter Flow:

1. **createPaymentIntent** - Paiements uniques
2. **createSubscription** - Abonnements récurrents
3. **confirmPayment** - Vérification de paiement
4. **cancelSubscription** - Annulation d'abonnement
5. **stripeWebhook** - Réception des événements Stripe

## 📦 Étape 1: Configurer le package.json

### Dans Flutter Flow:

1. Allez dans **Cloud Functions** (menu de gauche)
2. Cliquez sur l'onglet **package.json**
3. Ajoutez la dépendance Stripe dans la section `dependencies`:

```json
{
  "name": "functions",
  "description": "Cloud Functions for Firebase",
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "stripe": "^14.10.0"
  }
}
```

4. **Sauvegardez** le fichier

## 🔑 Étape 2: Configurer les clés Stripe dans Firebase

Vous devez ajouter vos clés Stripe dans la configuration Firebase.

### Option A: Via Firebase Console (plus simple)

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet
3. Allez dans **Functions** > **Configuration**
4. Ajoutez ces variables:
   - Clé: `stripe.secret_key` → Valeur: `sk_test_VOTRE_CLE`
   - Clé: `stripe.publishable_key` → Valeur: `pk_test_VOTRE_CLE`
   - Clé: `stripe.webhook_secret` → Valeur: `whsec_VOTRE_SECRET` (après configuration webhook)

### Option B: Via ligne de commande (si vous avez Firebase CLI)

```bash
firebase functions:config:set \
  stripe.secret_key="sk_test_VOTRE_CLE" \
  stripe.publishable_key="pk_test_VOTRE_CLE" \
  stripe.webhook_secret="whsec_VOTRE_SECRET"
```

## ⚡ Étape 3: Ajouter les Cloud Functions

### 3.1 createPaymentIntent

1. Dans Flutter Flow, allez dans **Cloud Functions**
2. Cliquez sur **+ Add**
3. Configurez:

**Nom:** `createPaymentIntent`

**Boilerplate Settings:**
- Memory: `512MB`
- Timeout: `120` secondes
- Region: `europe-west1`
- Require Authentication: ❌ Non (ou ✅ Oui si vous voulez)

**Input Parameters:**
```
+ amount (Number, Required)
+ customerEmail (String, Required)
+ customerName (String, Optional)
+ description (String, Optional)
+ metadata (JSON, Optional)
```

**Return Value:**
- ✅ Activé
- Type: `JSON`

**Code:**

Cliquez sur **[</>] Copy to Editor** et remplacez par le code du fichier `createPaymentIntent.js`

4. Cliquez sur **Save Cloud Function**
5. Cliquez sur **Deploy**
6. Attendez la fin du déploiement ✅

---

### 3.2 createSubscription

1. Cliquez sur **+ Add**
2. Configurez:

**Nom:** `createSubscription`

**Boilerplate Settings:**
- Memory: `512MB`
- Timeout: `120` secondes
- Region: `europe-west1`

**Input Parameters:**
```
+ priceId (String, Required)
+ customerEmail (String, Required)
+ customerName (String, Optional)
+ metadata (JSON, Optional)
```

**Return Value:**
- ✅ Activé
- Type: `JSON`

**Code:** Copiez le contenu de `createSubscription.js`

3. **Save** et **Deploy**

---

### 3.3 confirmPayment

1. Cliquez sur **+ Add**
2. Configurez:

**Nom:** `confirmPayment`

**Boilerplate Settings:**
- Memory: `256MB`
- Timeout: `60` secondes
- Region: `europe-west1`

**Input Parameters:**
```
+ paymentIntentId (String, Required)
```

**Return Value:**
- ✅ Activé
- Type: `JSON`

**Code:** Copiez le contenu de `confirmPayment.js`

3. **Save** et **Deploy**

---

### 3.4 cancelSubscription

1. Cliquez sur **+ Add**
2. Configurez:

**Nom:** `cancelSubscription`

**Boilerplate Settings:**
- Memory: `256MB`
- Timeout: `60` secondes
- Region: `europe-west1`

**Input Parameters:**
```
+ subscriptionId (String, Required)
```

**Return Value:**
- ✅ Activé
- Type: `JSON`

**Code:** Copiez le contenu de `cancelSubscription.js`

3. **Save** et **Deploy**

---

### 3.5 stripeWebhook (ATTENTION: Type différent)

⚠️ **Important:** Cette function est de type **HTTP Request**, pas **Callable**

1. Cliquez sur **+ Add**
2. Configurez:

**Nom:** `stripeWebhook`

**Type:** HTTP Request Function (pas Callable!)

**Boilerplate Settings:**
- Memory: `512MB`
- Timeout: `60` secondes
- Region: `europe-west1`

**Pas de Input/Output** (c'est une fonction HTTP brute)

**Code:** Copiez le contenu de `stripeWebhook.js`

3. **Save** et **Deploy**

4. **Notez l'URL** de la function (vous en aurez besoin pour Stripe):
   ```
   https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
   ```

## 🔔 Étape 4: Configurer le Webhook dans Stripe

1. Allez sur https://dashboard.stripe.com/test/webhooks
2. Cliquez sur **Add endpoint**
3. **Endpoint URL:** Collez l'URL de votre function `stripeWebhook`
4. **Events to send:**
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `customer.subscription.created`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`
5. Cliquez sur **Add endpoint**
6. Dans la page du webhook, cliquez sur **Reveal** dans **Signing secret**
7. Copiez le secret (commence par `whsec_...`)
8. Ajoutez-le dans la configuration Firebase (Étape 2)

## ✅ Vérification

### Dans Flutter Flow:

1. Allez dans **Cloud Functions**
2. Vous devriez voir les 5 functions listées
3. Chacune doit avoir un statut ✅ **Deployed**

### Test rapide:

Vous pouvez tester via Google Cloud Console:
1. https://console.cloud.google.com/functions
2. Cliquez sur une function
3. Onglet **Testing**
4. Entrez des données de test
5. Cliquez sur **Test the function**

## 🎨 Utilisation dans Flutter Flow

Maintenant que les Cloud Functions sont déployées, vous pouvez les utiliser dans vos actions:

### Exemple: Bouton "Payer"

**Actions:**
```
1. Backend Call > Cloud Function
   └─ Function: createPaymentIntent
   └─ amount: AppState.amount
   └─ customerEmail: AuthUser.email
   └─ Action Output Variable: paymentResult

2. Update App State
   └─ clientSecret = paymentResult.clientSecret
   └─ paymentIntentId = paymentResult.paymentIntentId

3. Conditional
   └─ If paymentResult.success == true:
       └─ Show Payment Widget
   └─ Else:
       └─ Show Error
```

## 🐛 Debugging

### Voir les logs:

1. **Dans Flutter Flow:**
   - Cloud Functions > Sélectionnez une function > Onglet **Logs**

2. **Dans Firebase Console:**
   - https://console.firebase.google.com
   - Functions > Logs

3. **Dans Google Cloud Console:**
   - https://console.cloud.google.com/logs

### Problèmes courants:

**"Function not deployed"**
- Attendez quelques minutes après le déploiement
- Vérifiez que le plan Firebase est Blaze

**"stripe is not defined"**
- Vérifiez que `stripe` est dans le package.json
- Redéployez après modification du package.json

**"Configuration stripe.secret_key not found"**
- Configurez les clés Stripe (Étape 2)
- Redéployez les functions

**"Invalid API key"**
- Vérifiez que vous utilisez les bonnes clés (test vs live)
- Mode test: pk_test_... et sk_test_...
- Mode live: pk_live_... et sk_live_...

## 📚 Prochaines étapes

Maintenant que les Cloud Functions sont déployées:

1. ✅ Ajoutez les Custom Widgets dans Flutter Flow
2. ✅ Ajoutez les Custom Actions dans Flutter Flow
3. ✅ Créez votre page de paiement
4. ✅ Testez avec les cartes de test Stripe

Consultez le guide `FLUTTER-FLOW-GUIDE.md` pour la suite !

## 🆘 Besoin d'aide?

- [Documentation Flutter Flow Cloud Functions](https://docs.flutterflow.io/actions/cloud-functions)
- [Documentation Stripe](https://stripe.com/docs)
- [Forum Flutter Flow](https://community.flutterflow.io)

---

**Vous êtes prêt !** Les Cloud Functions Stripe sont maintenant déployées et prêtes à être utilisées dans votre app Flutter Flow ! 🎉
