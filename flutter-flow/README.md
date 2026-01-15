# 🎨 Flutter Flow - Intégration Stripe

Ce dossier contient tous les Custom Widgets et Custom Actions à ajouter dans votre projet Flutter Flow.

## 📦 Contenu

### Custom Widgets

#### 🔹 stripe_payment_element.dart (RECOMMANDÉ)
Widget standard avec bouton intégré personnalisable.
- ✅ Simple à utiliser
- ✅ Bouton inclus avec texte et couleur personnalisables
- ✅ Parfait pour 95% des cas d'usage

#### 🔸 stripe_payment_element_with_js_bridge.dart (Avancé)
Version avec support de bouton externe Flutter Flow.
- ✅ Même fonctionnalités que la version standard
- ✅ Permet de cacher le bouton intégré (`hideButton: true`)
- ✅ Expose une fonction JavaScript pour déclencher le paiement
- ✅ Utilisez avec la Custom Action `trigger_stripe_payment`
- 📚 Documentation: [docs/EXTERNAL-BUTTON-GUIDE.md](../docs/EXTERNAL-BUTTON-GUIDE.md)

### Custom Actions

#### Actions principales
- **create_payment_intent.dart** - Créer un paiement unique
- **create_subscription.dart** - Créer un abonnement récurrent
- **confirm_payment_status.dart** - Vérifier le statut d'un paiement

#### Action avancée
- **trigger_stripe_payment.dart** - Déclencher le paiement depuis un bouton Flutter Flow externe
  - À utiliser avec `stripe_payment_element_with_js_bridge.dart`
  - Permet de placer votre bouton de paiement n'importe où sur la page

## 🚀 Installation dans Flutter Flow

### Étape 1: Ajouter les dépendances

1. Allez dans **Settings & Integrations** > **Dependencies**
2. Ajoutez la dépendance suivante:
   ```
   cloud_functions: ^4.5.0
   ```

### Étape 2: Ajouter le Custom Widget

1. Dans Flutter Flow, allez dans **Custom Code** > **Custom Widgets**
2. Cliquez sur **Add Widget**
3. Nommez-le: `StripePaymentElement`
4. Copiez le contenu de `custom-widgets/stripe_payment_element.dart`
5. Configurez les paramètres du widget:

   **Paramètres requis:**
   - `stripePublishableKey` (String) - Votre clé publique Stripe
   - `clientSecret` (String) - Le client secret du Payment Intent

   **Paramètres optionnels:**
   - `buttonText` (String) - Texte du bouton (défaut: "Payer")
   - `buttonColor` (Color) - Couleur du bouton
   - `onPaymentSuccess` (Action) - Callback en cas de succès
   - `onPaymentError` (Action) - Callback en cas d'erreur

6. Sauvegardez le widget

### Étape 3: Ajouter les Custom Actions

Pour chaque fichier dans `custom-actions/`:

1. Allez dans **Custom Code** > **Custom Actions**
2. Cliquez sur **Add Action**
3. Nommez l'action selon le fichier (ex: `createPaymentIntent`)
4. Copiez le contenu du fichier correspondant
5. Configurez les paramètres et le type de retour:

#### createPaymentIntent
**Paramètres:**
- `amount` (double) - Montant en euros
- `customerEmail` (String) - Email du client
- `customerName` (String, optionnel) - Nom du client
- `description` (String, optionnel) - Description
- `metadata` (Map<String, String>, optionnel) - Métadonnées

**Type de retour:** JSON

#### createSubscription
**Paramètres:**
- `priceId` (String) - ID du prix Stripe
- `customerEmail` (String) - Email du client
- `customerName` (String, optionnel) - Nom du client
- `metadata` (Map<String, String>, optionnel) - Métadonnées

**Type de retour:** JSON

#### confirmPaymentStatus
**Paramètres:**
- `paymentIntentId` (String) - ID du Payment Intent

**Type de retour:** JSON

## 💡 Utilisation - Paiement Unique

### Configuration de la page

1. **Créez des App State Variables:**
   - `clientSecret` (String) - Pour stocker le client secret
   - `paymentIntentId` (String) - Pour stocker l'ID du paiement
   - `isPaymentLoading` (bool) - Pour l'état de chargement
   - `stripePublicKey` (String) - Votre clé publique Stripe

2. **Structure de la page:**
   ```
   Page: Checkout
   ├── Column
   │   ├── [Vos informations produit/prix]
   │   ├── Button "Initialiser le paiement"
   │   └── Conditional: Si clientSecret existe
   │       └── StripePaymentElement (Custom Widget)
   ```

3. **Actions du bouton "Initialiser le paiement":**
   ```
   Action 1: Update App State
     - isPaymentLoading = true

   Action 2: Backend Call - createPaymentIntent
     - amount: [Votre montant]
     - customerEmail: [Email de l'utilisateur]
     - customerName: [Nom de l'utilisateur]

   Action 3: Update App State
     - clientSecret = [Résultat].clientSecret
     - paymentIntentId = [Résultat].paymentIntentId
     - isPaymentLoading = false
   ```

4. **Configuration du StripePaymentElement:**
   - `stripePublishableKey`: App State > stripePublicKey
   - `clientSecret`: App State > clientSecret
   - `buttonText`: "Payer maintenant"
   - `onPaymentSuccess`: [Vos actions de succès]
   - `onPaymentError`: [Vos actions d'erreur]

5. **Actions onPaymentSuccess:**
   ```
   Action 1: Backend Call - confirmPaymentStatus
     - paymentIntentId: App State > paymentIntentId

   Action 2: Conditional
     - Si success = true:
       - Firestore Create Document (collection: orders)
       - Navigate to Success Page
     - Sinon:
       - Show Snackbar "Erreur de paiement"
   ```

## 💡 Utilisation - Abonnement

### Configuration de la page

1. **Créez les mêmes App State que pour le paiement unique**

2. **Actions du bouton "S'abonner":**
   ```
   Action 1: Update App State
     - isPaymentLoading = true

   Action 2: Backend Call - createSubscription
     - priceId: "price_VOTRE_PRICE_ID" (depuis Stripe Dashboard)
     - customerEmail: [Email de l'utilisateur]
     - customerName: [Nom de l'utilisateur]

   Action 3: Update App State
     - clientSecret = [Résultat].clientSecret
     - subscriptionId = [Résultat].subscriptionId
     - isPaymentLoading = false
   ```

3. **Le reste est identique au paiement unique**

## 🎯 Exemple de flux complet

```
1. Utilisateur arrive sur la page Checkout
2. Il voit le prix et un bouton "Payer"
3. Il clique sur "Payer"
   → Custom Action createPaymentIntent est appelée
   → clientSecret est stocké dans App State
4. Le StripePaymentElement s'affiche automatiquement
5. L'utilisateur entre ses infos de carte
6. Il clique sur le bouton "Payer maintenant" du widget
   → Le paiement est traité par Stripe
7. Si succès:
   → onPaymentSuccess est appelé
   → Vous créez la commande dans Firestore
   → Redirection vers page de confirmation
8. Si échec:
   → onPaymentError est appelé
   → Message d'erreur affiché
```

## 🔑 Obtenir votre clé publique Stripe

1. Allez sur https://dashboard.stripe.com/test/apikeys
2. Copiez la **Publishable key** (commence par `pk_test_...`)
3. Stockez-la dans un App State `stripePublicKey`
4. **IMPORTANT:** Pour la production, utilisez `pk_live_...`

## ⚠️ Sécurité

- ✅ La clé **publique** (pk_...) peut être dans votre app
- ❌ La clé **secrète** (sk_...) doit UNIQUEMENT être dans Firebase Functions
- ✅ Toutes les opérations sensibles passent par Firebase Functions
- ✅ Les règles Firestore protègent les données

## 🐛 Debugging

### Le widget ne s'affiche pas
- Vérifiez que `clientSecret` n'est pas null/vide
- Vérifiez que la clé publique est correcte
- Regardez la console du navigateur (F12)

### Le paiement échoue
- Vérifiez que les Firebase Functions sont déployées
- Vérifiez la configuration Stripe dans Firebase
- Testez avec une carte de test: `4242 4242 4242 4242`

### Cartes de test Stripe
- **Succès:** 4242 4242 4242 4242
- **Échec:** 4000 0000 0000 0002
- **3D Secure:** 4000 0027 6000 3184
- Date d'expiration: N'importe quelle date future
- CVC: N'importe quel 3 chiffres

## 📚 Ressources

- [Documentation Stripe](https://stripe.com/docs)
- [Flutter Flow Custom Code](https://docs.flutterflow.io/customizing-your-app/custom-code)
- [Firebase Functions](https://firebase.google.com/docs/functions)
