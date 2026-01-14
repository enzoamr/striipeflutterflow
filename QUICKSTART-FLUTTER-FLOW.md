# ⚡ Démarrage Rapide - Flutter Flow

Guide ultra-rapide pour intégrer Stripe dans votre app Flutter Flow en **30 minutes**.

## ✅ Checklist

- [ ] Compte Stripe (gratuit)
- [ ] Projet Flutter Flow avec Firebase
- [ ] Plan Firebase Blaze

## 🎯 Les 4 étapes

### 1️⃣ Récupérer les clés Stripe (5 min)

1. Allez sur https://dashboard.stripe.com/test/apikeys
2. Notez:
   - **Publishable key** (pk_test_...) → Pour Flutter Flow
   - **Secret key** (sk_test_...) → Pour Firebase

### 2️⃣ Déployer les Cloud Functions (10 min)

1. **Ouvrir Flutter Flow** > Cloud Functions

2. **Configurer package.json:**
   ```json
   {
     "dependencies": {
       "firebase-admin": "^12.0.0",
       "firebase-functions": "^4.5.0",
       "stripe": "^14.10.0"
     }
   }
   ```

3. **Configurer les clés Stripe:**
   - Firebase Console > Functions > Configuration
   - Ajoutez: `stripe.secret_key` = `sk_test_...`

4. **Ajouter les 5 Cloud Functions:**

   Pour chaque function, cliquez **+ Add** et configurez:

   | Nom | Memory | Timeout | Inputs | Return |
   |-----|--------|---------|--------|--------|
   | createPaymentIntent | 512MB | 120s | amount, customerEmail | JSON |
   | createSubscription | 512MB | 120s | priceId, customerEmail | JSON |
   | confirmPayment | 256MB | 60s | paymentIntentId | JSON |
   | cancelSubscription | 256MB | 60s | subscriptionId | JSON |
   | stripeWebhook | 512MB | 60s | (HTTP) | - |

   **Copiez le code depuis:** `flutter-flow-cloud-functions/[nom-function].js`

   Puis: **Save** > **Deploy**

   ✅ Guide détaillé: [flutter-flow-cloud-functions/FLUTTER-FLOW-DEPLOYMENT.md](flutter-flow-cloud-functions/FLUTTER-FLOW-DEPLOYMENT.md)

### 3️⃣ Ajouter le code Flutter Flow (10 min)

#### A. Dépendance

**Settings** > **Dependencies** > Ajoutez:
```
cloud_functions: ^4.5.0
```

#### B. App State

**App Settings** > **App State** > Ajoutez:

| Nom | Type | Valeur par défaut |
|-----|------|-------------------|
| stripePublicKey | String | `pk_test_...` |
| clientSecret | String | (vide) |
| paymentIntentId | String | (vide) |

#### C. Custom Widget

**Custom Code** > **Custom Widgets** > **Add**

- Nom: `StripePaymentElement`
- Copiez: `flutter-flow/custom-widgets/stripe_payment_element.dart`

Paramètres:
- stripePublishableKey (String)
- clientSecret (String)
- buttonText (String)
- onPaymentSuccess (Action)
- onPaymentError (Action)

#### D. Custom Actions

**Custom Code** > **Custom Actions** > **Add** (x3)

1. **createPaymentIntent**
   - Copiez: `flutter-flow/custom-actions/create_payment_intent.dart`
   - Return: JSON

2. **createSubscription**
   - Copiez: `flutter-flow/custom-actions/create_subscription.dart`
   - Return: JSON

3. **confirmPaymentStatus**
   - Copiez: `flutter-flow/custom-actions/confirm_payment_status.dart`
   - Return: JSON

### 4️⃣ Créer la page de paiement (5 min)

#### Structure de la page

```
CheckoutPage
├── Column
│   ├── Text: "Total: ${montant}€"
│   │
│   ├── Button: "Payer"
│   │   └── Actions:
│   │       1. Update App State > isLoading = true
│   │       2. Backend Call > createPaymentIntent
│   │          - amount: 10.50
│   │          - customerEmail: AuthUser.email
│   │          - Output: paymentResult
│   │       3. Update App State
│   │          - clientSecret = paymentResult.clientSecret
│   │          - paymentIntentId = paymentResult.paymentIntentId
│   │          - isLoading = false
│   │
│   └── Conditional: Si clientSecret != null
│       └── StripePaymentElement
│           - stripePublishableKey: AppState.stripePublicKey
│           - clientSecret: AppState.clientSecret
│           - buttonText: "Payer maintenant"
│           - onPaymentSuccess:
│               1. Create Firestore Document (orders)
│               2. Navigate to SuccessPage
│           - onPaymentError:
│               1. Show Snackbar (error)
```

## 🧪 Tester

1. Lancez votre app Flutter Flow
2. Allez sur la page de paiement
3. Cliquez sur "Payer"
4. Le Payment Element s'affiche
5. Entrez la carte de test:
   ```
   Numéro: 4242 4242 4242 4242
   Date: 12/34
   CVC: 123
   ```
6. Cliquez sur "Payer maintenant"
7. ✅ Succès !

## 🎉 C'est fini !

Vous avez maintenant Stripe intégré dans votre app Flutter Flow !

## 📚 Aller plus loin

- [Guide complet Flutter Flow](docs/FLUTTER-FLOW-GUIDE.md)
- [Configuration Stripe avancée](docs/STRIPE-CONFIGURATION.md)
- [Dépannage](docs/TROUBLESHOOTING.md)
- [Référence rapide](docs/QUICK-REFERENCE.md)

## 💡 Prochaines étapes

- [ ] Configurer le webhook Stripe
- [ ] Ajouter la gestion des abonnements
- [ ] Créer la page de succès
- [ ] Tester les erreurs
- [ ] Passer en production (clés live)

## 🆘 Problèmes ?

**Le widget ne s'affiche pas:**
- Vérifiez que `clientSecret` n'est pas null
- Regardez la console (F12)

**Le paiement échoue:**
- Vérifiez les Firebase Functions déployées
- Vérifiez les clés Stripe

**Erreur "Function not found":**
- Attendez 2-3 min après déploiement
- Vérifiez le plan Firebase Blaze

Plus de solutions: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

**Besoin d'aide ?** Consultez la documentation complète dans le dossier `docs/`
