# 🔧 Guide de Dépannage

Solutions aux problèmes courants lors de l'intégration Stripe avec Flutter Flow.

## 📋 Table des matières

1. [Problèmes Firebase Functions](#firebase-functions)
2. [Problèmes Stripe](#stripe)
3. [Problèmes Flutter Flow](#flutter-flow)
4. [Problèmes de paiement](#paiement)
5. [Problèmes Firestore](#firestore)
6. [Problèmes de webhook](#webhooks)

---

## 🔥 Firebase Functions

### Erreur: "Function not found"

**Symptôme:**
```
Error: Function createPaymentIntent not found
```

**Solutions:**

1. **Vérifiez que les functions sont déployées:**
   ```bash
   firebase functions:list
   ```
   Vous devriez voir:
   - createPaymentIntent
   - createSubscription
   - confirmPayment
   - stripeWebhook

2. **Redéployez les functions:**
   ```bash
   cd firebase-functions
   firebase deploy --only functions
   ```

3. **Vérifiez la région:**
   Les functions sont en `europe-west1`. Dans Flutter Flow:
   ```dart
   FirebaseFunctions.instanceFor(region: 'europe-west1')
   ```

### Erreur: "Stripe is not defined"

**Symptôme:**
```
ReferenceError: stripe is not defined
```

**Solution:**

1. **Vérifiez les dépendances:**
   ```bash
   cd firebase-functions
   cat package.json
   ```
   Doit contenir: `"stripe": "^14.10.0"`

2. **Réinstallez:**
   ```bash
   npm install
   firebase deploy --only functions
   ```

### Erreur: "Configuration not found"

**Symptôme:**
```
Error: stripe.secret_key is undefined
```

**Solution:**

1. **Définissez la configuration:**
   ```bash
   firebase functions:config:set stripe.secret_key="sk_test_..."
   ```

2. **Vérifiez:**
   ```bash
   firebase functions:config:get
   ```

3. **Redéployez:**
   ```bash
   firebase deploy --only functions
   ```

### Les logs ne s'affichent pas

**Solution:**

```bash
# Logs en temps réel
firebase functions:log

# Derniers logs
firebase functions:log --only createPaymentIntent

# Ou dans Firebase Console
# Functions > Logs
```

---

## 💳 Stripe

### Le Payment Element ne s'affiche pas

**Symptôme:**
Widget vide ou erreur dans la console

**Solutions:**

1. **Vérifiez le clientSecret:**
   ```dart
   // Dans Flutter Flow, ajoutez un Text widget pour debug
   Text(AppState.clientSecret ?? "null")
   ```
   Si null, le Payment Intent n'a pas été créé.

2. **Vérifiez la clé publique:**
   ```dart
   // Doit commencer par pk_test_ ou pk_live_
   AppState.stripePublicKey
   ```

3. **Vérifiez la console du navigateur (F12):**
   ```
   Recherchez les erreurs Stripe.js
   ```

### Erreur: "Invalid API Key"

**Symptôme:**
```
Error: Invalid API Key provided
```

**Solutions:**

1. **Mode Test vs Production:**
   - Utilisez `pk_test_...` avec `sk_test_...`
   - Utilisez `pk_live_...` avec `sk_live_...`
   - Ne mélangez JAMAIS test et live!

2. **Vérifiez les clés:**
   - Dashboard Stripe > Developers > API Keys
   - Copiez à nouveau les clés

3. **Mettez à jour Firebase:**
   ```bash
   firebase functions:config:set stripe.secret_key="NOUVELLE_CLE"
   firebase deploy --only functions
   ```

### Erreur: "No such payment_intent"

**Symptôme:**
```
Error: No such payment_intent: 'pi_...'
```

**Solutions:**

1. **Vérifiez le mode (test vs live):**
   - Un Payment Intent créé en test n'existe pas en live
   - Vérifiez que vous êtes dans le bon mode

2. **Le Payment Intent a expiré:**
   - Ils expirent après 24h
   - Créez-en un nouveau

---

## 🎨 Flutter Flow

### Le Custom Widget n'apparaît pas

**Symptôme:**
Widget invisible sur la page

**Solutions:**

1. **Vérifiez la condition d'affichage:**
   ```
   Conditional Widget
   └─ Condition: AppState.clientSecret != null
       └─ Si null, le widget ne s'affiche pas
   ```

2. **Vérifiez les dimensions:**
   ```
   Width: Set value (ex: parent width)
   Height: Set value (ex: 400)
   ```

3. **Vérifiez que le widget est ajouté:**
   - Custom Code > Custom Widgets
   - "StripePaymentElement" doit être dans la liste

### Les Custom Actions ne fonctionnent pas

**Symptôme:**
```
Action failed to execute
```

**Solutions:**

1. **Vérifiez les dépendances:**
   - Settings > Dependencies
   - `cloud_functions: ^4.5.0` doit être présent

2. **Vérifiez les paramètres:**
   ```
   createPaymentIntent(
     amount: 10.00,  // Double, pas String!
     customerEmail: "test@test.com"  // Requis
   )
   ```

3. **Vérifiez le type de retour:**
   - Doit être "JSON"

### Erreur: "Missing required parameter"

**Symptôme:**
Action échoue avec paramètre manquant

**Solution:**

Vérifiez tous les paramètres requis:

**createPaymentIntent:**
- ✅ amount (Double)
- ✅ customerEmail (String)

**createSubscription:**
- ✅ priceId (String)
- ✅ customerEmail (String)

---

## 💰 Paiement

### Le paiement échoue toujours

**Symptôme:**
Tous les paiements sont déclinés

**Solutions:**

1. **Utilisez une carte de test valide:**
   ```
   4242 4242 4242 4242
   Date: N'importe quelle date future
   CVC: 123
   ```

2. **Vérifiez le mode:**
   - En mode Test, utilisez des cartes de test
   - En mode Live, utilisez de vraies cartes

3. **Vérifiez le montant:**
   ```dart
   // Le montant doit être > 0
   amount: 10.00  // ✅
   amount: 0      // ❌
   ```

### Erreur: "Your card was declined"

**Symptôme:**
La carte de test est refusée

**Solutions:**

1. **Cartes de test intentionnellement déclinées:**
   ```
   4000 0000 0000 0002  → Décliné (generic)
   4000 0000 0000 9995  → Insufficient funds
   ```

2. **Utilisez la carte de succès:**
   ```
   4242 4242 4242 4242  → Toujours acceptée
   ```

### Le paiement reste en "processing"

**Symptôme:**
Status = "processing" indéfiniment

**Solutions:**

1. **3D Secure requis:**
   ```
   Carte 4000 0027 6000 3184 nécessite 3DS
   → Stripe affichera un popup d'authentification
   ```

2. **Webhook non configuré:**
   ```
   Le webhook confirme le paiement
   Vérifiez: Stripe > Developers > Webhooks
   ```

### onPaymentSuccess n'est jamais appelé

**Symptôme:**
Le callback de succès ne se déclenche pas

**Solutions:**

1. **Vérifiez que le callback est configuré:**
   ```
   StripePaymentElement
   └─ onPaymentSuccess: [Votre action]
   ```

2. **Vérifiez la console:**
   ```
   F12 > Console
   Recherchez les erreurs JavaScript
   ```

3. **Testez avec une carte simple:**
   ```
   4242 4242 4242 4242  (pas de 3DS)
   ```

---

## 📚 Firestore

### Erreur: "Permission denied"

**Symptôme:**
```
Error: Missing or insufficient permissions
```

**Solutions:**

1. **Déployez les règles:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Vérifiez l'authentification:**
   ```
   User doit être authentifié pour lire/écrire
   ```

3. **Vérifiez les règles:**
   ```javascript
   // firestore.rules
   match /orders/{orderId} {
     allow create: if request.auth.uid == request.resource.data.userId;
   }
   ```

### Les documents ne sont pas créés

**Symptôme:**
Aucun document dans Firestore après paiement

**Solutions:**

1. **Vérifiez onPaymentSuccess:**
   ```
   Dans le callback, ajoutez:
   Create Firestore Document
   └─ Collection: orders
   ```

2. **Vérifiez les champs requis:**
   ```
   Tous les champs doivent avoir une valeur
   userId: AuthUser.uid (pas null)
   ```

3. **Vérifiez les logs:**
   ```bash
   firebase functions:log
   ```

---

## 🔔 Webhooks

### Le webhook n'est pas appelé

**Symptôme:**
Pas d'événements reçus

**Solutions:**

1. **Vérifiez l'URL:**
   ```
   https://europe-west1-VOTRE_PROJECT.cloudfunctions.net/stripeWebhook

   ⚠️ Remplacez VOTRE_PROJECT par votre vrai ID!
   ```

2. **Testez le webhook:**
   ```
   Stripe > Developers > Webhooks
   Cliquez sur votre webhook
   Send test webhook
   ```

3. **Vérifiez les logs:**
   ```bash
   firebase functions:log --only stripeWebhook
   ```

### Erreur: "Webhook signature verification failed"

**Symptôme:**
```
Error: No signatures found matching the expected signature
```

**Solutions:**

1. **Configurez le webhook secret:**
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_..."
   firebase deploy --only functions
   ```

2. **Récupérez le bon secret:**
   ```
   Stripe > Developers > Webhooks
   Cliquez sur votre webhook
   Signing secret > Reveal
   ```

---

## 🔍 Debugging général

### Activer les logs détaillés

**Firebase Functions:**
```javascript
// Dans index.js, ajoutez:
console.log('Payment Intent:', paymentIntent);
console.log('Customer:', customer);
```

**Flutter Flow:**
```
Ajoutez des Text widgets pour afficher:
- AppState.clientSecret
- AppState.paymentIntentId
- Résultats des actions
```

**Stripe Dashboard:**
```
Developers > Events
└─ Voir tous les événements en temps réel

Developers > Logs
└─ Voir toutes les requêtes API
```

### Console navigateur (F12)

Ouvrez les Developer Tools:

**Console:**
```javascript
// Erreurs JavaScript/Stripe
console.log()
```

**Network:**
```
Voir les requêtes HTTP
Filtrer: "stripe" ou "firebase"
```

**Application:**
```
Voir les variables App State
Local Storage / Session Storage
```

### Tester localement

**Firebase Functions:**
```bash
cd firebase-functions
npm run serve

# Les functions seront disponibles sur:
# http://localhost:5001/PROJET/europe-west1/createPaymentIntent
```

**Stripe CLI:**
```bash
stripe listen --forward-to http://localhost:5001/.../stripeWebhook
stripe trigger payment_intent.succeeded
```

---

## 📞 Obtenir de l'aide

### Documentation

- [SETUP.md](SETUP.md) - Configuration complète
- [STRIPE-CONFIGURATION.md](STRIPE-CONFIGURATION.md) - Config Stripe
- [FLUTTER-FLOW-GUIDE.md](FLUTTER-FLOW-GUIDE.md) - Guide Flutter Flow
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Référence rapide

### Support officiel

- [Stripe Support](https://support.stripe.com)
- [Firebase Support](https://firebase.google.com/support)
- [Flutter Flow Discord](https://flutterflow.io/discord)

### Forums

- [Stripe Community](https://stripe.com/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/stripe-payments)

---

## ✅ Checklist de vérification

Avant de demander de l'aide, vérifiez:

- [ ] Firebase Functions déployées
- [ ] Configuration Stripe définie
- [ ] Clés API correctes (test vs live)
- [ ] Custom Widget ajouté
- [ ] Custom Actions ajoutées
- [ ] Dépendances installées
- [ ] Webhooks configurés
- [ ] Règles Firestore déployées
- [ ] Carte de test valide utilisée
- [ ] Logs consultés (Firebase + Stripe)
- [ ] Console navigateur vérifiée (F12)

---

**Problème non résolu?**

Consultez les logs détaillés:
```bash
firebase functions:log --lines 100
```

Vérifiez Stripe Dashboard:
```
Developers > Events > Voir les erreurs
```

Contactez le support avec:
- Message d'erreur exact
- Logs Firebase Functions
- Event ID Stripe (si applicable)
- Étapes pour reproduire
