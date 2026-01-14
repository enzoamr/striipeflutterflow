# 📖 Guide de Configuration Complète

Ce guide vous accompagne pas à pas pour configurer l'intégration Stripe dans votre application Flutter Flow web avec Firebase.

## 🎯 Vue d'ensemble

Vous allez configurer:
1. ✅ Un compte Stripe (gratuit en mode test)
2. ✅ Les Firebase Functions pour le backend sécurisé
3. ✅ Les Custom Widgets et Actions dans Flutter Flow
4. ✅ Les règles de sécurité Firestore
5. ✅ Les webhooks Stripe pour les confirmations

**Temps estimé:** 30-45 minutes

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir:
- ✅ Un compte Firebase avec Firestore activé
- ✅ Firebase CLI installé (`npm install -g firebase-tools`)
- ✅ Un projet Flutter Flow web
- ✅ Node.js 18+ installé
- ✅ Un compte Google pour Firebase Functions (plan Blaze requis)

## 1️⃣ Configuration Stripe

### 1.1 Créer un compte Stripe

1. Allez sur https://stripe.com
2. Cliquez sur "Start now" ou "S'inscrire"
3. Remplissez vos informations
4. **Restez en mode TEST** pour l'instant (bandeau orange en haut)

### 1.2 Récupérer vos clés API

1. Dans le Dashboard Stripe, allez dans **Developers** > **API Keys**
2. Vous verrez deux clés en mode Test:
   - **Publishable key** (pk_test_...) → Pour Flutter Flow
   - **Secret key** (sk_test_...) → Pour Firebase Functions

3. **Notez ces clés quelque part** (vous en aurez besoin)

⚠️ **IMPORTANT:**
- La clé **Publishable** (pk_...) va dans votre app Flutter Flow
- La clé **Secret** (sk_...) va UNIQUEMENT dans Firebase Functions
- Ne partagez JAMAIS votre clé secrète publiquement

### 1.3 Créer des produits pour les abonnements (optionnel)

Si vous voulez des paiements récurrents:

1. Allez dans **Products** > **Add product**
2. Remplissez:
   - Name: ex. "Abonnement Premium"
   - Description: ex. "Accès premium mensuel"
3. Dans **Pricing**:
   - Price: ex. 9.99 EUR
   - Billing period: Monthly (ou autre)
4. Cliquez sur **Add product**
5. **Copiez le Price ID** (commence par `price_...`)

Répétez pour chaque type d'abonnement.

## 2️⃣ Configuration Firebase Functions

### 2.1 Initialiser Firebase dans votre projet

Si ce n'est pas déjà fait:

```bash
# Se connecter à Firebase
firebase login

# Initialiser dans le dossier du projet
cd /path/to/striipeflutterflow
firebase init

# Sélectionnez:
# - Functions (Cloud Functions)
# - Firestore (Cloud Firestore)
# - Hosting (optionnel)

# Choisissez:
# - Un projet Firebase existant
# - JavaScript ou TypeScript (choisissez JavaScript)
# - ESLint: Non (ou Oui si vous voulez)
# - Install dependencies: Oui
```

### 2.2 Configurer les Firebase Functions

1. **Copiez les fichiers Functions:**
   ```bash
   # Les fichiers sont déjà dans firebase-functions/
   cd firebase-functions
   ```

2. **Installez les dépendances:**
   ```bash
   npm install
   ```

3. **Configurez les clés Stripe:**
   ```bash
   # Remplacez par vos vraies clés
   firebase functions:config:set \
     stripe.secret_key="sk_test_VOTRE_CLE_SECRETE" \
     stripe.publishable_key="pk_test_VOTRE_CLE_PUBLIQUE"
   ```

4. **Vérifiez la configuration:**
   ```bash
   firebase functions:config:get
   ```

5. **Déployez les Functions:**
   ```bash
   firebase deploy --only functions
   ```

   Attendez quelques minutes. Vous devriez voir:
   ```
   ✔  functions: Deployed createPaymentIntent (region: europe-west1)
   ✔  functions: Deployed createSubscription (region: europe-west1)
   ✔  functions: Deployed stripeWebhook (region: europe-west1)
   ✔  functions: Deployed confirmPayment (region: europe-west1)
   ```

### 2.3 Noter les URLs des Functions

Après le déploiement, notez les URLs de vos functions:
```
https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/createPaymentIntent
https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
```

## 3️⃣ Configuration des Webhooks Stripe

Les webhooks permettent à Stripe de notifier votre backend quand un paiement réussit/échoue.

### 3.1 Créer un webhook

1. Dans Stripe Dashboard, allez dans **Developers** > **Webhooks**
2. Cliquez sur **Add endpoint**
3. Endpoint URL:
   ```
   https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
   ```
4. Events à écouter:
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `customer.subscription.created`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`

5. Cliquez sur **Add endpoint**

### 3.2 Récupérer le Webhook Secret

1. Cliquez sur votre webhook créé
2. Dans la section **Signing secret**, cliquez sur **Reveal**
3. Copiez le secret (commence par `whsec_...`)
4. Configurez-le dans Firebase:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_VOTRE_SECRET"
   firebase deploy --only functions
   ```

## 4️⃣ Configuration Firestore

### 4.1 Déployer les règles de sécurité

1. **Copiez les règles:**
   ```bash
   # Le fichier firestore.rules est dans firestore/
   cp firestore/firestore.rules ./firestore.rules
   ```

2. **Déployez:**
   ```bash
   firebase deploy --only firestore:rules
   ```

### 4.2 Créer les index (si nécessaire)

Si Firebase vous demande des index, suivez les liens fournis dans les erreurs.

## 5️⃣ Configuration Flutter Flow

### 5.1 Ajouter les dépendances

1. Dans Flutter Flow, allez dans **Settings & Integrations** > **Dependencies**
2. Ajoutez:
   ```
   cloud_functions: ^4.5.0
   ```

### 5.2 Ajouter le Custom Widget

Suivez les instructions dans [flutter-flow/README.md](../flutter-flow/README.md)

1. **Custom Code** > **Custom Widgets** > **Add Widget**
2. Nom: `StripePaymentElement`
3. Copiez le code de `flutter-flow/custom-widgets/stripe_payment_element.dart`
4. Configurez les paramètres (voir README)

### 5.3 Ajouter les Custom Actions

Pour chaque action:

1. **Custom Code** > **Custom Actions** > **Add Action**
2. Copiez le code correspondant
3. Configurez les paramètres

Actions à ajouter:
- ✅ `createPaymentIntent`
- ✅ `createSubscription`
- ✅ `confirmPaymentStatus`

### 5.4 Créer les App State Variables

1. **App Settings** > **App State**
2. Ajoutez:
   - `clientSecret` (String) - null par défaut
   - `paymentIntentId` (String) - null par défaut
   - `subscriptionId` (String) - null par défaut
   - `isPaymentLoading` (bool) - false par défaut
   - `stripePublicKey` (String) - `pk_test_VOTRE_CLE`

⚠️ **Pour la production:** Changez `stripePublicKey` en `pk_live_...`

## 6️⃣ Tester l'intégration

### 6.1 Créer une page de test

1. Créez une nouvelle page "Checkout"
2. Ajoutez un bouton "Initialiser le paiement"
3. Ajoutez une condition pour afficher le widget uniquement si `clientSecret` existe
4. Ajoutez le widget `StripePaymentElement`

### 6.2 Tester avec une carte test

Utilisez ces cartes de test Stripe:

| Carte | Résultat |
|-------|----------|
| 4242 4242 4242 4242 | ✅ Succès |
| 4000 0000 0000 0002 | ❌ Échec |
| 4000 0027 6000 3184 | 🔐 3D Secure |

- Date d'expiration: N'importe quelle date future
- CVC: N'importe quel 3 chiffres
- Code postal: N'importe quel code

### 6.3 Vérifier dans Stripe Dashboard

1. Allez dans **Payments** > **All payments**
2. Vous devriez voir vos paiements de test
3. Dans **Developers** > **Events**, vous verrez tous les événements

### 6.4 Vérifier dans Firestore

1. Dans Firebase Console, allez dans **Firestore Database**
2. Vous devriez voir les collections:
   - `payment_intents`
   - `subscriptions` (si vous avez testé les abonnements)

## 7️⃣ Passer en Production

Quand vous êtes prêt pour le mode production:

### 7.1 Activer votre compte Stripe

1. Dans Stripe Dashboard, désactivez le "Test mode"
2. Remplissez les informations de votre entreprise
3. Validez votre compte

### 7.2 Récupérer les clés de production

1. **Developers** > **API Keys**
2. Notez les clés **Live** (pk_live_... et sk_live_...)

### 7.3 Mettre à jour Firebase Functions

```bash
firebase functions:config:set \
  stripe.secret_key="sk_live_VOTRE_CLE" \
  stripe.publishable_key="pk_live_VOTRE_CLE"

firebase deploy --only functions
```

### 7.4 Mettre à jour Flutter Flow

1. Changez `stripePublicKey` en App State avec `pk_live_...`
2. Republiez votre application

### 7.5 Mettre à jour les webhooks

Créez un nouveau webhook avec vos clés de production.

## ✅ Checklist finale

Avant de lancer en production:

- [ ] Tests avec différentes cartes effectués
- [ ] Webhooks configurés et testés
- [ ] Règles Firestore déployées
- [ ] Firebase Functions déployées
- [ ] Clés de production configurées
- [ ] Gestion des erreurs testée
- [ ] Messages de confirmation testés
- [ ] Emails de reçu activés dans Stripe
- [ ] Politique de remboursement définie

## 🆘 Besoin d'aide?

Consultez:
- [STRIPE-CONFIGURATION.md](STRIPE-CONFIGURATION.md) - Configuration Stripe détaillée
- [FLUTTER-FLOW-GUIDE.md](FLUTTER-FLOW-GUIDE.md) - Guide Flutter Flow
- [Documentation Stripe](https://stripe.com/docs)
- [Documentation Firebase](https://firebase.google.com/docs)

## 🎉 C'est terminé !

Vous avez maintenant une intégration Stripe complète et sécurisée !

Pour des questions ou problèmes, consultez la documentation dans ce dossier.
