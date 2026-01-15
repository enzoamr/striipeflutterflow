# Stripe Payment Element Widget for FlutterFlow

Custom Flutter widget pour intégrer Stripe Payment Element dans FlutterFlow avec fix du problème de scroll/visibilité.

## 🔧 Problème Résolu

Ce widget corrige un bug critique où le widget Stripe collapsait et faisait disparaître toute la page FlutterFlow quand on scrollait et que le widget sortait du viewport.

**Symptômes avant le fix:**
- Scroll vers le bas → Widget sort de la vue
- Toute la page FlutterFlow disparaît ou se déforme
- Il faut re-scroller pour que le widget redevienne visible pour que la page réapparaisse

**Solution:**
Le widget vérifie maintenant si l'élément est visible dans le viewport avant de mesurer sa hauteur, et conserve la dernière hauteur valide au lieu de mesurer 0px.

## 📁 Structure

```
lib/
├── backend/
│   └── backend.dart
├── custom_code/
│   ├── actions/
│   │   └── index.dart
│   └── widgets/
│       ├── index.dart
│       └── stripe_payment_element.dart  ← Widget principal avec fix
├── flutter_flow/
│   ├── custom_functions.dart
│   ├── flutter_flow_theme.dart
│   └── flutter_flow_util.dart
```

## 🚀 Utilisation dans FlutterFlow

### Installation

1. Copier le fichier `lib/custom_code/widgets/stripe_payment_element.dart` dans votre projet FlutterFlow
2. Ajouter le widget dans votre page FlutterFlow

### Paramètres

```dart
StripePaymentElement(
  stripePublishableKey: 'pk_test_...',  // Requis
  clientSecret: 'pi_..._secret_...',     // Requis
  width: 400.0,                          // Optionnel
  height: null,                          // Optionnel (null = auto-height)
  maxHeight: 720.0,                      // Optionnel (limite max)
  buttonText: 'Payer',                   // Optionnel
  buttonColor: Color(0xFF0570DE),        // Optionnel
  hideButton: false,                     // Optionnel (cache le bouton)
  onPaymentSuccess: () async {           // Optionnel
    // Actions après succès
  },
  onPaymentError: (error) async {        // Optionnel
    // Actions après erreur
  },
)
```

## ✨ Fonctionnalités

- ✅ **Fix Scroll/Visibilité**: Ne collapse plus au scroll
- ✅ **Auto-height dynamique**: S'adapte au contenu Stripe
- ✅ **Event Bridge**: Résout l'isolation HtmlElementView ↔ Flutter
- ✅ **JavaScript Bridge**: Déclenchement externe avec `triggerStripePayment()`
- ✅ **3D Secure**: Gestion complète des paiements
- ✅ **ResizeObserver**: Hauteur dynamique intelligente
- ✅ **Gestion d'erreurs**: Messages d'erreur clairs

## 📖 Documentation Détaillée

Voir [SOLUTION.md](SOLUTION.md) pour:
- Explication technique du problème
- Comparaison avant/après
- Logs de debug
- Diagrammes visuels

## 🔍 Comment ça marche

Le widget utilise:
1. **`_isElementVisibleInViewport()`**: Vérifie si l'élément est dans le viewport avant de mesurer
2. **Hauteur conservée**: Garde la dernière hauteur valide si hors viewport
3. **ResizeObserver**: Détecte les changements de taille uniquement si visible
4. **ClipRect + SizedBox**: Garantit une hauteur stable

## 🛠️ Développement

### Logs de Debug

Le widget génère des logs pour faciliter le debug:
```
[StripePaymentElement][...] ✅ height update -> 420.0
[StripePaymentElement][...] ⏸️ Element not visible, keeping last height: 420.0
```

### Tests

Pour tester le fix:
1. Intégrer le widget dans une page FlutterFlow
2. Ajouter du contenu avant et après le widget
3. Scroller vers le bas jusqu'à ce que le widget sorte de la vue
4. Vérifier que la page reste stable (pas de collapse)

## 📝 Notes

- Compatible Flutter Web uniquement (utilise `dart:html` et `HtmlElementView`)
- Nécessite Stripe.js chargé depuis `https://js.stripe.com/v3/`
- Testé avec Stripe API 2024+

## 📄 License

MIT