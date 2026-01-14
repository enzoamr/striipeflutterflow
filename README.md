# 💳 Stripe Payment Integration pour Flutter Flow Web + Firebase

Ce dépôt contient **tout le code nécessaire** pour intégrer Stripe Payment Element dans votre application Flutter Flow web avec Firebase.

## 🎯 Fonctionnalités

- ✅ **Paiements uniques** (one-time payments)
- ✅ **Abonnements récurrents** (subscriptions)
- ✅ **Stripe Payment Element** intégré directement dans Flutter Flow
- ✅ **Firebase Functions** pour backend sécurisé
- ✅ **Firestore** pour stocker les transactions
- ✅ **Custom Widget** + **Custom Action** prêts à l'emploi
- ✅ **Gestion des erreurs** et retours de statut

## 📁 Structure du projet

```
striipeflutterflow/
├── README.md                             # Ce fichier
│
├── flutter-flow-cloud-functions/         # ⭐ RECOMMANDÉ pour Flutter Flow
│   ├── createPaymentIntent.js           # Functions à copier dans Flutter Flow
│   ├── createSubscription.js
│   ├── confirmPayment.js
│   ├── cancelSubscription.js
│   ├── stripeWebhook.js
│   ├── package.json                     # Dépendances npm
│   ├── FLUTTER-FLOW-DEPLOYMENT.md       # Guide de déploiement Flutter Flow
│   └── README.md
│
├── firebase-functions/                   # Alternative: Déploiement CLI
│   ├── package.json
│   ├── index.js                         # Toutes les functions en un fichier
│   ├── .env.example
│   └── README.md
│
├── flutter-flow/                         # Code pour Flutter Flow
│   ├── custom-widgets/
│   │   └── stripe_payment_element.dart  # Widget Payment Element
│   ├── custom-actions/
│   │   ├── create_payment_intent.dart   # Actions de paiement
│   │   ├── create_subscription.dart
│   │   └── confirm_payment_status.dart
│   └── README.md                        # Guide d'intégration
│
├── firestore/
│   └── firestore.rules                  # Règles de sécurité Firestore
│
└── docs/
    ├── SETUP.md                         # Configuration complète
    ├── STRIPE-CONFIGURATION.md          # Configuration Stripe
    ├── FLUTTER-FLOW-GUIDE.md            # Guide Flutter Flow détaillé
    ├── QUICK-REFERENCE.md               # Référence rapide
    └── TROUBLESHOOTING.md               # Dépannage
```

## 🚀 Démarrage rapide

### Choix du mode de déploiement

**Option A: Via Flutter Flow** ⭐ **RECOMMANDÉ** - Tout dans l'interface
- Déploiement en 1 clic depuis Flutter Flow
- Pas besoin de Firebase CLI
- Guide: [flutter-flow-cloud-functions/FLUTTER-FLOW-DEPLOYMENT.md](flutter-flow-cloud-functions/FLUTTER-FLOW-DEPLOYMENT.md)

**Option B: Via ligne de commande** - Déploiement traditionnel
- Nécessite Firebase CLI sur votre machine
- Plus de contrôle technique
- Guide: [docs/SETUP.md](docs/SETUP.md)

---

### Option A: Déploiement Flutter Flow (RECOMMANDÉ)

### 1. Configuration Stripe
1. Créez un compte sur [stripe.com](https://stripe.com)
2. Récupérez vos clés API (test et production)
3. Voir [docs/STRIPE-CONFIGURATION.md](docs/STRIPE-CONFIGURATION.md)

### 2. Cloud Functions dans Flutter Flow
1. Ouvrez **Cloud Functions** dans Flutter Flow
2. Ajoutez `stripe: ^14.10.0` dans le **package.json**
3. Pour chaque function dans `flutter-flow-cloud-functions/`:
   - Créez une nouvelle Cloud Function
   - Copiez/collez le code
   - Configurez les paramètres (memory, timeout, inputs/outputs)
   - **Deploy**
4. Guide détaillé: [flutter-flow-cloud-functions/FLUTTER-FLOW-DEPLOYMENT.md](flutter-flow-cloud-functions/FLUTTER-FLOW-DEPLOYMENT.md)

### 3. Custom Widgets & Actions
1. Ajoutez le **Custom Widget** `StripePaymentElement`
2. Ajoutez les 3 **Custom Actions** (create_payment_intent, etc.)
3. Configurez vos App State variables
4. Voir [docs/FLUTTER-FLOW-GUIDE.md](docs/FLUTTER-FLOW-GUIDE.md)

---

### Option B: Déploiement CLI (Alternative)

### 1. Configuration Stripe
Même que l'Option A

### 2. Déploiement Firebase Functions via CLI
```bash
cd firebase-functions
npm install
firebase functions:config:set \
  stripe.secret_key="sk_test_..." \
  stripe.publishable_key="pk_test_..."
firebase deploy --only functions
```

### 3. Intégration Flutter Flow
Même que l'Option A

## 📚 Documentation complète

- [📖 Guide de configuration complet](docs/SETUP.md)
- [🔧 Configuration Stripe](docs/STRIPE-CONFIGURATION.md)
- [🎨 Guide Flutter Flow](docs/FLUTTER-FLOW-GUIDE.md)

## 💶 Informations

- **Devise** : EUR (€)
- **Région Firebase** : europe-west1 (Europe)
- **Montants** : Variables (passés en paramètres)

## 🔐 Sécurité

- ❌ **Jamais de clés secrètes côté client**
- ✅ Toutes les opérations sensibles via Firebase Functions
- ✅ Règles Firestore sécurisées
- ✅ Validation des paiements côté serveur

## 📝 Workflow de paiement

1. L'utilisateur arrive sur votre page avec le Custom Widget
2. Le Payment Element s'affiche (carte bancaire)
3. L'utilisateur entre ses infos et clique sur "Payer"
4. La Custom Action traite le paiement
5. Retour : `success: true/false` + `paymentIntentId` ou `error`
6. Vous gérez les actions dans Flutter Flow :
   - Si succès → Créer commande dans Firestore, redirection, etc.
   - Si échec → Afficher message d'erreur

## 🛠️ Support

Pour toute question, consultez la documentation dans le dossier `docs/`

---

**Auteur** : Claude AI pour enzoamr
**Dernière mise à jour** : Janvier 2026