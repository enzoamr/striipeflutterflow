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
├── README.md                           # Ce fichier
├── firebase-functions/                 # Backend Firebase
│   ├── package.json
│   ├── index.js                       # Cloud Functions
│   └── .env.example                   # Variables d'environnement
├── flutter-flow/                       # Code pour Flutter Flow
│   ├── custom-widgets/
│   │   └── stripe_payment_element.dart # Widget Payment Element
│   ├── custom-actions/
│   │   └── process_stripe_payment.dart # Action de paiement
│   └── README.md                      # Guide d'intégration Flutter Flow
├── firestore/
│   └── firestore.rules                # Règles de sécurité Firestore
└── docs/
    ├── SETUP.md                       # Configuration complète
    ├── STRIPE-CONFIGURATION.md        # Configuration Stripe
    └── FLUTTER-FLOW-GUIDE.md          # Guide Flutter Flow détaillé
```

## 🚀 Démarrage rapide

### 1. Configuration Stripe
1. Créez un compte sur [stripe.com](https://stripe.com)
2. Récupérez vos clés API (test et production)
3. Voir [docs/STRIPE-CONFIGURATION.md](docs/STRIPE-CONFIGURATION.md)

### 2. Configuration Firebase Functions
```bash
cd firebase-functions
npm install
# Configurez vos variables d'environnement
firebase functions:config:set stripe.secret_key="sk_test_..." stripe.publishable_key="pk_test_..."
firebase deploy --only functions
```

### 3. Intégration dans Flutter Flow
1. Ajoutez le **Custom Widget** `StripePaymentElement`
2. Ajoutez la **Custom Action** `processStripePayment`
3. Configurez votre page de paiement
4. Voir [docs/FLUTTER-FLOW-GUIDE.md](docs/FLUTTER-FLOW-GUIDE.md)

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