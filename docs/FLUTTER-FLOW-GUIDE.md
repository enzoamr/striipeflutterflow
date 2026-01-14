# 🎨 Guide Flutter Flow - Intégration Stripe

Ce guide détaille comment utiliser les Custom Widgets et Actions Stripe dans votre application Flutter Flow.

## 📋 Table des matières

1. [Configuration initiale](#1-configuration-initiale)
2. [Créer la page de paiement](#2-créer-la-page-de-paiement)
3. [Paiement unique](#3-paiement-unique-exemple-complet)
4. [Abonnement récurrent](#4-abonnement-récurrent)
5. [Gestion des erreurs](#5-gestion-des-erreurs)
6. [Après le paiement](#6-après-le-paiement)
7. [Exemples de pages](#7-exemples-de-pages)

## 1. Configuration initiale

### 1.1 Ajouter les dépendances

1. **Settings & Integrations** > **Dependencies**
2. Ajoutez:
   ```
   cloud_functions: ^4.5.0
   ```

### 1.2 Configurer Firebase

1. **Settings & Integrations** > **Firebase**
2. Assurez-vous que:
   - ✅ Firebase est configuré
   - ✅ Firestore est activé
   - ✅ Authentication est activée (si vous voulez lier users/paiements)

### 1.3 Créer les App State

**App Settings** > **App State** > **Add Field**

Créez ces variables:

| Nom | Type | Valeur par défaut | Description |
|-----|------|-------------------|-------------|
| stripePublicKey | String | `pk_test_...` | Clé publique Stripe |
| clientSecret | String | (vide) | Secret du Payment Intent |
| paymentIntentId | String | (vide) | ID du paiement |
| subscriptionId | String | (vide) | ID de l'abonnement |
| isPaymentLoading | Boolean | false | État de chargement |
| paymentAmount | Double | 0 | Montant du paiement |
| customerEmail | String | (vide) | Email du client |

⚠️ **Important:** Pour la production, changez `stripePublicKey` en `pk_live_...`

## 2. Créer la page de paiement

### 2.1 Structure de base

```
Page: CheckoutPage
├── AppBar
│   └── Title: "Paiement"
├── Column (ou ListView)
│   ├── Container (résumé de commande)
│   │   ├── Text: "Total:"
│   │   └── Text: "${AppState.paymentAmount}€"
│   │
│   ├── Button: "Procéder au paiement"
│   │   └── Actions: [Initialiser le paiement]
│   │
│   └── Conditional Widget
│       Condition: AppState.clientSecret != null
│       └── StripePaymentElement (Custom Widget)
```

### 2.2 Ajouter le Custom Widget

1. Cherchez "Custom Widget" dans les widgets
2. Sélectionnez **StripePaymentElement**
3. Configurez:

**Paramètres:**
- `width`: Remplir parent (ou fixe)
- `height`: 400 (ou selon besoin)
- `stripePublishableKey`: **App State** > stripePublicKey
- `clientSecret`: **App State** > clientSecret
- `buttonText`: "Payer maintenant" (ou votre texte)
- `buttonColor`: Votre couleur de marque

**Callbacks:**
- `onPaymentSuccess`: [Action personnalisée]
- `onPaymentError`: [Action personnalisée]

## 3. Paiement unique (exemple complet)

### 3.1 Bouton "Procéder au paiement"

**Actions du bouton:**

```
┌─ Action Chain ────────────────────────────────────┐
│                                                    │
│  1. Update App State                              │
│     └─ isPaymentLoading = true                    │
│                                                    │
│  2. Backend Call - createPaymentIntent            │
│     Parameters:                                    │
│     ├─ amount: AppState.paymentAmount             │
│     ├─ customerEmail: AuthUser.email              │
│     │   (ou TextField value)                      │
│     └─ customerName: AuthUser.displayName         │
│                                                    │
│  3. Update App State (Action Output)              │
│     ├─ clientSecret = [result].clientSecret       │
│     ├─ paymentIntentId = [result].paymentIntentId │
│     └─ isPaymentLoading = false                   │
│                                                    │
│  4. Conditional                                    │
│     If: [result].success == false                 │
│     Then:                                          │
│       └─ Show Snackbar                            │
│           └─ Message: [result].error              │
│                                                    │
└────────────────────────────────────────────────────┘
```

### 3.2 Configuration détaillée des actions

**Action 1: Update App State**
```
Variable: isPaymentLoading
Type: Set
Value: true
```

**Action 2: Backend Call**
```
Action: Custom Action
Name: createPaymentIntent

Parameters:
┌──────────────────┬──────────────────────────────┐
│ amount           │ App State > paymentAmount    │
│ customerEmail    │ Authenticated User > email   │
│ customerName     │ Authenticated User > name    │
│ description      │ "Achat sur MonApp"           │
│ metadata         │ {                            │
│                  │   "orderId": "...",          │
│                  │   "userId": "..."            │
│                  │ }                            │
└──────────────────┴──────────────────────────────┘

Return Type: JSON
Output Variable Name: paymentIntentResult
```

**Action 3: Update App State**
```
Variables (multiple):
┌──────────────────┬──────────────────────────────────────┐
│ clientSecret     │ Action Outputs >                     │
│                  │ paymentIntentResult > clientSecret   │
│ paymentIntentId  │ Action Outputs >                     │
│                  │ paymentIntentResult > paymentIntentId│
│ isPaymentLoading │ false                                │
└──────────────────┴──────────────────────────────────────┘
```

**Action 4: Conditional**
```
Condition:
  Action Outputs > paymentIntentResult > success
  Equals: false (Boolean)

Then Actions:
  └─ Show Snackbar
      Message: Action Outputs > paymentIntentResult > error
      Type: Error
```

### 3.3 Callback onPaymentSuccess

Quand le paiement réussit, cette action est appelée:

```
┌─ onPaymentSuccess ─────────────────────────────────┐
│                                                     │
│  1. Show Snackbar (optionnel)                      │
│     └─ Message: "Paiement réussi!"                 │
│                                                     │
│  2. Firestore Create Document                      │
│     Collection: orders                             │
│     Fields:                                         │
│     ├─ userId: AuthUser.uid                        │
│     ├─ paymentIntentId: AppState.paymentIntentId   │
│     ├─ amount: AppState.paymentAmount              │
│     ├─ status: "paid"                              │
│     ├─ createdAt: Current Time                     │
│     └─ [Vos autres champs...]                      │
│                                                     │
│  3. Update App State                               │
│     └─ Reset des variables                         │
│                                                     │
│  4. Navigate To                                     │
│     └─ Success Page                                │
│         └─ Pass paymentIntentId as parameter       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 3.4 Callback onPaymentError

Quand le paiement échoue:

```
┌─ onPaymentError ───────────────────────────────────┐
│                                                     │
│  Parameter: error (String)                         │
│                                                     │
│  1. Show Snackbar                                  │
│     ├─ Message: "Erreur: " + error                │
│     └─ Type: Error                                 │
│                                                     │
│  2. Update App State (optionnel)                   │
│     └─ clientSecret = null (pour réinitialiser)    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 4. Abonnement récurrent

### 4.1 Différences avec paiement unique

Au lieu de `createPaymentIntent`, utilisez `createSubscription`:

**Action 2: Backend Call**
```
Action: Custom Action
Name: createSubscription

Parameters:
┌──────────────────┬──────────────────────────────┐
│ priceId          │ "price_1234567890"           │
│                  │ (depuis Stripe Dashboard)     │
│ customerEmail    │ Authenticated User > email   │
│ customerName     │ Authenticated User > name    │
│ metadata         │ {                            │
│                  │   "plan": "premium",         │
│                  │   "userId": "..."            │
│                  │ }                            │
└──────────────────┴──────────────────────────────┘
```

**Action 3: Update App State**
```
Variables:
┌──────────────────┬──────────────────────────────────────┐
│ clientSecret     │ Action Outputs >                     │
│                  │ subscriptionResult > clientSecret    │
│ subscriptionId   │ Action Outputs >                     │
│                  │ subscriptionResult > subscriptionId  │
└──────────────────┴──────────────────────────────────────┘
```

### 4.2 Gérer plusieurs plans

Créez des boutons pour chaque plan:

```
┌─ Premium Monthly ─────────────────────────┐
│  Button: "9.99€/mois"                     │
│  OnTap:                                    │
│    ├─ Set App State > selectedPriceId     │
│    │   = "price_monthly_premium"          │
│    └─ Call createSubscription             │
└───────────────────────────────────────────┘

┌─ Premium Yearly ──────────────────────────┐
│  Button: "99.99€/an"                      │
│  OnTap:                                    │
│    ├─ Set App State > selectedPriceId     │
│    │   = "price_yearly_premium"           │
│    └─ Call createSubscription             │
└───────────────────────────────────────────┘
```

## 5. Gestion des erreurs

### 5.1 Erreurs courantes

**Pas de clientSecret:**
```
Conditional Widget:
  If: AppState.clientSecret == null
  Show: "Initialisation..."

  Else:
  Show: StripePaymentElement
```

**Firebase Functions indisponibles:**
```
Backend Call Error:
  Show Snackbar: "Service temporairement indisponible"
  Log Error pour debugging
```

**Stripe erreur:**
```
onPaymentError callback reçoit le message d'erreur:
  - "Your card was declined."
  - "Insufficient funds."
  - etc.
```

### 5.2 Améliorer l'UX

**Ajouter un loader:**
```
Conditional:
  If: AppState.isPaymentLoading == true
  Show: CircularProgressIndicator
```

**Désactiver le bouton pendant le chargement:**
```
Button Properties:
  Disabled: AppState.isPaymentLoading == true
```

## 6. Après le paiement

### 6.1 Créer une commande dans Firestore

Dans `onPaymentSuccess`:

```
Firestore Create:
  Collection: orders

  Document Fields:
  ┌──────────────────┬─────────────────────────────┐
  │ userId           │ Authenticated User > uid    │
  │ paymentIntentId  │ AppState.paymentIntentId    │
  │ amount           │ AppState.paymentAmount      │
  │ currency         │ "EUR"                       │
  │ status           │ "paid"                      │
  │ customerEmail    │ Authenticated User > email  │
  │ createdAt        │ Current Time                │
  │ items            │ [Vos produits]              │
  └──────────────────┴─────────────────────────────┘
```

### 6.2 Page de confirmation

Créez une page **OrderSuccessPage**:

```
Page Parameters:
  - paymentIntentId (String)

Page Content:
  ├─ Icon: ✅ (checkmark)
  ├─ Title: "Paiement réussi!"
  ├─ Text: "Merci pour votre achat"
  ├─ Text: "Référence: ${paymentIntentId}"
  │
  └─ Button: "Retour à l'accueil"
      OnTap: Navigate to HomePage
```

### 6.3 Envoyer un email (optionnel)

Stripe peut envoyer des reçus automatiquement:

1. Dashboard Stripe > **Settings** > **Emails**
2. Activez "Successful payments"

Ou utilisez Firebase Extensions:
- Trigger Email (Firestore)
- SendGrid
- Mailgun

## 7. Exemples de pages

### 7.1 Page simple (paiement rapide)

```
┌─────────────────────────────────────────┐
│  AppBar: "Checkout"                     │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ Résumé                            │ │
│  │ Total: 29.99€                     │ │
│  └───────────────────────────────────┘ │
│                                         │
│  [Bouton: Procéder au paiement]        │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │                                   │ │
│  │  Stripe Payment Element           │ │
│  │  (si clientSecret existe)         │ │
│  │                                   │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 7.2 Page avec formulaire

```
┌─────────────────────────────────────────┐
│  AppBar: "Finaliser la commande"        │
├─────────────────────────────────────────┤
│                                         │
│  TextField: Email                       │
│  TextField: Nom                         │
│  TextField: Adresse                     │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ Produit 1    19.99€               │ │
│  │ Produit 2     9.99€               │ │
│  │ ─────────────────────             │ │
│  │ Total        29.98€               │ │
│  └───────────────────────────────────┘ │
│                                         │
│  [Bouton: Payer 29.98€]                │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Stripe Payment Element           │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 7.3 Page d'abonnement

```
┌─────────────────────────────────────────┐
│  AppBar: "Choisir un plan"              │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💎 PREMIUM MENSUEL              │   │
│  │ 9.99€ / mois                    │   │
│  │                                 │   │
│  │ ✓ Fonctionnalité 1              │   │
│  │ ✓ Fonctionnalité 2              │   │
│  │                                 │   │
│  │ [S'abonner]                     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 💎 PREMIUM ANNUEL               │   │
│  │ 99.99€ / an                     │   │
│  │ Économisez 20€!                 │   │
│  │                                 │   │
│  │ ✓ Fonctionnalité 1              │   │
│  │ ✓ Fonctionnalité 2              │   │
│  │                                 │   │
│  │ [S'abonner]                     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  (Payment Element affiché après        │
│   sélection d'un plan)                 │
│                                         │
└─────────────────────────────────────────┘
```

## 🎯 Checklist d'intégration

Avant de publier:

- [ ] Custom Widget ajouté et testé
- [ ] Custom Actions ajoutées
- [ ] App State configuré avec clé publique
- [ ] Page de paiement créée
- [ ] Callbacks success/error configurés
- [ ] Création de commande dans Firestore
- [ ] Page de confirmation créée
- [ ] Tests avec cartes de test effectués
- [ ] Gestion des erreurs testée
- [ ] Loading states ajoutés
- [ ] Messages d'erreur clairs

## 💡 Astuces

### Performance
- Créez le Payment Intent seulement quand nécessaire (clic bouton)
- Ne le créez pas au chargement de la page

### UX
- Affichez le montant total clairement
- Ajoutez un résumé de commande
- Montrez un loader pendant le traitement
- Donnez du feedback immédiat

### Sécurité
- Validez les montants côté serveur (Firebase Functions)
- Vérifiez l'authentification de l'utilisateur
- Utilisez les règles Firestore

### Debugging
- Utilisez la console du navigateur (F12)
- Vérifiez les logs Firebase Functions
- Regardez les événements dans Stripe Dashboard

## 🆘 Problèmes courants

**Le widget ne s'affiche pas:**
- Vérifiez que `clientSecret` n'est pas null
- Vérifiez la clé publique Stripe
- Regardez la console du navigateur

**Le paiement échoue toujours:**
- Utilisez une carte de test valide (4242 4242 4242 4242)
- Vérifiez que les Firebase Functions sont déployées
- Vérifiez les clés Stripe (test vs live)

**Erreur "Function not found":**
- Les Firebase Functions ne sont pas déployées
- Mauvaise région configurée
- Mauvais nom de fonction

---

Vous êtes prêt à accepter des paiements ! 🚀
