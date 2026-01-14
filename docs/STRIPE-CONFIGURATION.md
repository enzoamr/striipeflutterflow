# 🔧 Configuration Stripe Détaillée

Ce guide explique en détail comment configurer Stripe pour votre intégration Flutter Flow.

## 📌 Table des matières

1. [Compte Stripe](#1-compte-stripe)
2. [Clés API](#2-clés-api)
3. [Produits et Prix](#3-produits-et-prix)
4. [Webhooks](#4-webhooks)
5. [Sécurité](#5-sécurité)
6. [Tests](#6-tests)

## 1. Compte Stripe

### Créer un compte

1. Allez sur https://stripe.com
2. Cliquez sur "Start now"
3. Remplissez:
   - Email
   - Nom complet
   - Pays (France)
   - Mot de passe

### Modes Test vs Production

Stripe a deux modes:

**🧪 Mode Test (bandeau orange)**
- Pour le développement
- Cartes de test uniquement
- Pas de vrais paiements
- Pas besoin d'activation du compte

**💰 Mode Production (bandeau vert ou pas de bandeau)**
- Pour les vrais clients
- Vraies cartes bancaires
- Vrais paiements
- Nécessite activation du compte

⚠️ **Restez en mode Test** jusqu'à ce que tout fonctionne parfaitement.

## 2. Clés API

### Types de clés

Stripe utilise 4 types de clés:

| Clé | Préfixe | Usage | Où ? |
|-----|---------|-------|------|
| Publishable Test | pk_test_... | Client (visible) | Flutter Flow |
| Secret Test | sk_test_... | Serveur (confidentiel) | Firebase Functions |
| Publishable Live | pk_live_... | Production client | Flutter Flow (prod) |
| Secret Live | sk_live_... | Production serveur | Firebase Functions (prod) |

### Récupérer vos clés

1. Dashboard Stripe > **Developers** > **API Keys**
2. En mode Test, vous verrez:
   ```
   Publishable key: pk_test_51...
   Secret key: sk_test_51... (cliquez sur "Reveal test key")
   ```

### Où utiliser chaque clé

**Dans Flutter Flow (App State):**
```
stripePublicKey = "pk_test_51..."
```

**Dans Firebase Functions:**
```bash
firebase functions:config:set stripe.secret_key="sk_test_51..."
```

### ⚠️ Sécurité des clés

- ✅ La clé `pk_` peut être publique (dans votre app)
- ❌ La clé `sk_` doit TOUJOURS rester secrète
- ❌ Ne committez JAMAIS les clés secrètes dans Git
- ❌ Ne les partagez JAMAIS publiquement
- ✅ Utilisez Firebase Config pour les stocker

## 3. Produits et Prix

### Pour les paiements uniques

Pas besoin de créer de produits ! Vous pouvez créer des paiements à la volée avec `createPaymentIntent`.

```dart
createPaymentIntent(
  amount: 10.00, // 10€
  customerEmail: "client@example.com"
)
```

### Pour les abonnements récurrents

Vous devez créer des produits et prix dans Stripe.

#### 3.1 Créer un produit

1. Dashboard > **Products** > **Add product**
2. Remplissez:
   - **Name:** ex. "Abonnement Premium"
   - **Description:** ex. "Accès illimité à toutes les fonctionnalités"
   - **Image:** (optionnel) ajoutez une image

#### 3.2 Ajouter un prix récurrent

Dans la même page:

1. **Pricing model:** Standard pricing
2. **Price:** ex. 9.99
3. **Billing period:**
   - Monthly (mensuel)
   - Yearly (annuel)
   - Weekly (hebdomadaire)
   - etc.
4. **Currency:** EUR (€)

5. Cliquez sur **Add product**

#### 3.3 Récupérer le Price ID

1. Cliquez sur votre produit créé
2. Dans la section **Pricing**, vous verrez le prix avec un ID: `price_1234567890`
3. **Copiez cet ID**

#### 3.4 Utiliser le Price ID

Dans Flutter Flow:

```dart
createSubscription(
  priceId: "price_1234567890", // Votre Price ID
  customerEmail: "client@example.com"
)
```

### Exemples de produits courants

**Abonnement mensuel:**
- Nom: Premium Monthly
- Prix: 9.99 EUR / mois
- Price ID: price_monthly_premium

**Abonnement annuel:**
- Nom: Premium Yearly
- Prix: 99.99 EUR / an
- Price ID: price_yearly_premium

**Essai gratuit puis abonnement:**
- Créez un prix avec "Free trial" activé
- Trial period: 7 days (ou autre)

## 4. Webhooks

Les webhooks permettent à Stripe de notifier votre backend quand des événements se produisent.

### 4.1 Pourquoi les webhooks?

- ✅ Confirmation que le paiement a vraiment réussi
- ✅ Notification des paiements échoués
- ✅ Gestion des abonnements (renouvellement, annulation)
- ✅ Remboursements
- ✅ Disputes (chargebacks)

### 4.2 Créer un webhook

1. **Developers** > **Webhooks** > **Add endpoint**

2. **Endpoint URL:**
   ```
   https://europe-west1-VOTRE_PROJECT_ID.cloudfunctions.net/stripeWebhook
   ```

   Remplacez `VOTRE_PROJECT_ID` par votre ID de projet Firebase

3. **Events to send:**

   Sélectionnez ces événements:

   **Pour paiements uniques:**
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `payment_intent.canceled`

   **Pour abonnements:**
   - ✅ `customer.subscription.created`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`
   - ✅ `invoice.payment_succeeded`
   - ✅ `invoice.payment_failed`

4. Cliquez sur **Add endpoint**

### 4.3 Sécuriser le webhook

1. Cliquez sur votre webhook
2. Cherchez **Signing secret**
3. Cliquez sur **Reveal**
4. Copiez le secret (commence par `whsec_...`)

5. Configurez dans Firebase:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_..."
   firebase deploy --only functions
   ```

### 4.4 Tester le webhook

1. Dans la page du webhook, cliquez sur **Send test webhook**
2. Choisissez `payment_intent.succeeded`
3. Cliquez sur **Send test webhook**

4. Vérifiez les logs Firebase:
   ```bash
   firebase functions:log
   ```

Vous devriez voir: `PaymentIntent succeeded: pi_...`

## 5. Sécurité

### 5.1 Bonnes pratiques

✅ **À FAIRE:**
- Utiliser HTTPS partout
- Stocker les clés secrètes dans Firebase Config
- Valider les webhooks avec le signing secret
- Vérifier les montants côté serveur
- Logger les erreurs
- Utiliser les règles Firestore

❌ **À NE PAS FAIRE:**
- Mettre les clés secrètes dans le code
- Faire confiance aux montants envoyés par le client
- Ignorer les erreurs de webhook
- Créer des paiements sans authentification

### 5.2 PCI Compliance

Stripe gère la conformité PCI DSS pour vous:

- ✅ Les données de carte ne touchent jamais votre serveur
- ✅ Stripe.js tokenise les cartes
- ✅ Le Payment Element est hébergé par Stripe
- ✅ Vous n'avez pas besoin de certification PCI

### 5.3 Authentification forte (3D Secure)

Le Payment Element gère automatiquement:
- 3D Secure / 3DS2
- Authentification forte pour l'Europe (PSD2)
- Biométrie

Vous n'avez rien à faire, c'est automatique !

## 6. Tests

### 6.1 Cartes de test

Stripe fournit des cartes pour tester différents scénarios:

**✅ Succès:**
```
Numéro: 4242 4242 4242 4242
Exp: N'importe quelle date future
CVC: N'importe quel 3 chiffres
```

**❌ Décliné (insufficient funds):**
```
Numéro: 4000 0000 0000 9995
```

**❌ Décliné (generic decline):**
```
Numéro: 4000 0000 0000 0002
```

**🔐 Requiert 3D Secure:**
```
Numéro: 4000 0027 6000 3184
```

**⚠️ Paiement incomplet:**
```
Numéro: 4000 0000 0000 9979
```

### 6.2 Tester les webhooks

1. Allez dans **Developers** > **Webhooks**
2. Cliquez sur votre webhook
3. Onglet **Test webhook**
4. Envoyez différents événements

### 6.3 Utiliser Stripe CLI (avancé)

Pour tester les webhooks localement:

```bash
# Installer Stripe CLI
brew install stripe/stripe-cli/stripe
# ou
npm install -g stripe-cli

# Se connecter
stripe login

# Forwarder les webhooks vers votre local
stripe listen --forward-to http://localhost:5001/VOTRE_PROJECT/europe-west1/stripeWebhook

# Déclencher un événement
stripe trigger payment_intent.succeeded
```

## 📊 Dashboard Stripe

### Sections importantes

**💰 Payments**
- Voir tous les paiements
- Rechercher par email, montant, date
- Rembourser un paiement

**👥 Customers**
- Liste de vos clients
- Historique de paiements par client
- Moyens de paiement sauvegardés

**📦 Products**
- Gérer vos produits et prix
- Créer des coupons/promotions
- Voir les abonnements actifs

**📈 Reports**
- Revenus
- Analyses
- Exports

**⚙️ Developers**
- API keys
- Webhooks
- Logs
- Events

## 🌍 Internationalisation

### Devises supportées

Stripe supporte 135+ devises. Pour changer:

```dart
createPaymentIntent(
  amount: 10.00,
  currency: 'usd', // ou 'eur', 'gbp', etc.
  customerEmail: email
)
```

### Langues du Payment Element

Le Payment Element détecte automatiquement la langue du navigateur.

Langues supportées: EN, FR, DE, ES, IT, NL, PT, etc.

## 💡 Conseils

### Pour débuter
1. Restez en mode Test
2. Testez avec les cartes de test
3. Vérifiez les paiements dans le Dashboard
4. Configurez les webhooks
5. Testez les erreurs

### Avant la production
1. Complétez les informations de votre entreprise
2. Activez votre compte
3. Basculez vers les clés Live
4. Testez encore avec une vraie carte (petit montant)
5. Configurez les emails de reçu
6. Définissez votre politique de remboursement

### Optimisations
- Utilisez des coupons pour les promotions
- Configurez des emails automatiques
- Activez Radar (détection de fraude)
- Utilisez Billing pour gérer les abonnements

## 🔗 Ressources

- [Documentation Stripe](https://stripe.com/docs)
- [API Reference](https://stripe.com/docs/api)
- [Dashboard Stripe](https://dashboard.stripe.com)
- [Stripe Testing](https://stripe.com/docs/testing)
- [Support Stripe](https://support.stripe.com)

---

Vous êtes maintenant prêt à utiliser Stripe ! 🎉
