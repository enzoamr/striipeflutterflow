# 🔧 Fix: Problème de Scroll et Visibilité du Widget Stripe

## 🐛 Problème Identifié

### Comment la taille était définie (VERSION ORIGINALE)

```dart
// ligne ~297-298
final double elementHeight = widget.height ?? (_measuredElementHeight ?? 360.0);
```

La hauteur du widget est définie selon cette priorité:
1. **`widget.height`** (si fourni) → hauteur fixe
2. **`_measuredElementHeight`** → hauteur mesurée dynamiquement via DOM
3. **`360.0`** → valeur par défaut

### Le Bug de Scroll

Quand tu scrolls et que le widget sort du viewport visible:

```dart
// ligne ~191-210 (VERSION BUGGÉE)
void _measureHeightNow() {
  final el = html.document.querySelector(_containerSelector);
  if (el == null) return;

  final rect = el.getBoundingClientRect();  // ❌ PROBLÈME ICI
  double h = rect.height.isFinite ? rect.height.toDouble() : 0.0;

  final next = math.min(_maxH, math.max(_minH, h + 8));
  setState(() => _measuredElementHeight = next);
}
```

#### Ce qui se passait:

1. **Tu scrolls** → Le widget sort du viewport
2. **`getBoundingClientRect().height` retourne 0 ou une valeur incorrecte** car l'élément n'est plus visible
3. **Le `ResizeObserver` ou les timers continuent d'appeler `_measureHeightNow()`**
4. **La hauteur mesurée devient 220px (minimum)** ou pire, collapse complètement
5. **Flutter re-render avec cette hauteur incorrecte**
6. **🔴 RÉSULTAT: Toute ta page FlutterFlow perd son layout** car le widget prend maintenant 220px au lieu de 400-500px

---

## ✅ Solution Implémentée

### 1. Vérification de Visibilité dans le Viewport

```dart
// NOUVEAU: ligne ~197-217
bool _isElementVisibleInViewport(html.Element el) {
  try {
    final rect = el.getBoundingClientRect();

    // ✅ Vérifie que l'élément a une taille réelle (pas collapsed)
    if (rect.width <= 0 || rect.height <= 0) {
      return false;
    }

    // ✅ Vérifie que l'élément est au moins partiellement visible
    final windowHeight = html.window.innerHeight ?? 0;
    final windowWidth = html.window.innerWidth ?? 0;

    final isVisible = rect.bottom > 0 &&
                     rect.right > 0 &&
                     rect.top < windowHeight &&
                     rect.left < windowWidth;

    return isVisible;
  } catch (e) {
    return false;
  }
}
```

### 2. Ne Mesurer QUE si Visible

```dart
// CORRIGÉ: ligne ~219-246
void _measureHeightNow() {
  final el = html.document.querySelector(_containerSelector);
  if (el == null) return;

  // ✨ FIX: Ne mesure QUE si l'élément est visible dans le viewport
  if (!_isElementVisibleInViewport(el)) {
    _log('⏸️ Element not visible, keeping last height: $_measuredElementHeight');
    return; // ✅ Garde la dernière hauteur valide au lieu de mesurer 0px
  }

  final rect = el.getBoundingClientRect();
  double h = rect.height.isFinite ? rect.height.toDouble() : 0.0;

  // fallback scrollHeight
  try {
    final sh = (el as dynamic).scrollHeight;
    if (sh is num && sh.toDouble() > h) h = sh.toDouble();
  } catch (_) {}

  // ✅ Si on obtient quand même 0, on ignore (garde la dernière hauteur)
  if (h <= 0) {
    _log('⚠️ Measured height is 0, ignoring');
    return;
  }

  // ✅ clamp + marge pour éviter coupure bas
  final next = math.min(_maxH, math.max(_minH, h + 8));

  if (!mounted) return;

  if (_measuredElementHeight == null ||
      (next - _measuredElementHeight!).abs() > 6) {
    _log('✅ height update -> $next (was: $_measuredElementHeight)');
    setState(() => _measuredElementHeight = next);
  }
}
```

---

## 🎯 Comportement Après le Fix

### Avant (BUGGÉ):
```
1. Widget visible → hauteur = 420px ✅
2. Tu scrolls vers le bas → Widget sort du viewport
3. getBoundingClientRect() → hauteur = 0px ❌
4. setState() → hauteur = 220px (minimum) ❌
5. Page FlutterFlow collapse → Tout disparaît 💥
```

### Après (FIXÉ):
```
1. Widget visible → hauteur = 420px ✅
2. Tu scrolls vers le bas → Widget sort du viewport
3. _isElementVisibleInViewport() → false 🛑
4. _measureHeightNow() → SKIP, garde 420px ✅
5. Page FlutterFlow stable → Rien ne change ✅
```

---

## 📊 Comparaison Visuelle

### Avant le Fix:
```
[Page FlutterFlow normale]
     ↓ scroll
[Widget Stripe visible: 420px]
     ↓ scroll + widget sort du viewport
[Widget collapse à 220px] ← ❌ Mauvaise mesure
     ↓
[💥 Toute la page perd son layout]
```

### Après le Fix:
```
[Page FlutterFlow normale]
     ↓ scroll
[Widget Stripe visible: 420px]
     ↓ scroll + widget sort du viewport
[Widget garde 420px] ← ✅ Garde la dernière hauteur valide
     ↓
[✅ Page stable, layout préservé]
```

---

## 🔍 Logs de Debug

Avec le fix, tu verras dans la console:

```
[StripePaymentElement][...] ✅ height update -> 420.0 (was: null)
[StripePaymentElement][...] ⏸️ Element not visible, keeping last height: 420.0
[StripePaymentElement][...] ⏸️ Element not visible, keeping last height: 420.0
```

Au lieu de:
```
[StripePaymentElement][...] height update -> 420.0
[StripePaymentElement][...] height update -> 0.0    ← ❌ BAD
[StripePaymentElement][...] height update -> 220.0  ← ❌ MINIMUM FORCÉ
```

---

## 🚀 Utilisation dans FlutterFlow

### Option 1: Hauteur Dynamique (Recommandée)
```dart
StripePaymentElement(
  stripePublishableKey: 'pk_test_...',
  clientSecret: '...',
  // Ne pas spécifier height → Auto-height avec fix de scroll
)
```

### Option 2: Hauteur Fixe (Pas de problème de scroll)
```dart
StripePaymentElement(
  stripePublishableKey: 'pk_test_...',
  clientSecret: '...',
  height: 450.0,  // Hauteur fixe → Pas de mesure dynamique
)
```

### Option 3: Avec Limite Maximum
```dart
StripePaymentElement(
  stripePublishableKey: 'pk_test_...',
  clientSecret: '...',
  maxHeight: 600.0,  // Empêche des hauteurs trop grandes
)
```

---

## 🎉 Avantages du Fix

1. **✅ Stabilité du Layout**: Plus de collapse au scroll
2. **✅ Performance**: Évite les re-renders inutiles quand hors viewport
3. **✅ Expérience Utilisateur**: Page FlutterFlow reste stable
4. **✅ Hauteur Conservée**: Garde la dernière hauteur valide mesurée
5. **✅ Logs Clairs**: Debug facilité avec logs explicites

---

## 📝 Notes Techniques

### Pourquoi `getBoundingClientRect()` retourne 0?

Quand un élément est **hors du viewport** (scrollé en dehors de la vue):
- Le navigateur peut optimiser le rendu
- `getBoundingClientRect()` peut retourner des dimensions incorrectes
- Certains navigateurs retournent `height: 0` pour les éléments non visibles

### Pourquoi ne pas désactiver le ResizeObserver?

Le `ResizeObserver` est utile pour détecter:
- Les changements de contenu du formulaire Stripe
- L'affichage d'erreurs de validation
- Les animations de champs

On garde le `ResizeObserver` mais on filtre les mesures invalides.

---

## 🔗 Fichiers Modifiés

- `lib/custom_code/widgets/stripe_payment_element.dart`: Widget corrigé avec fix de visibilité
- `lib/custom_code/widgets/index.dart`: Export du widget
- Ajout de la fonction `_isElementVisibleInViewport()` (ligne ~197-217)
- Modification de `_measureHeightNow()` pour vérifier la visibilité (ligne ~219-246)

---

## ✨ Bonus: Autres Fixes Inclus

1. **Event Bridge**: Résout l'isolation HtmlElementView ↔ Flutter
2. **JavaScript Bridge**: `triggerStripePayment()` pour boutons externes
3. **ResizeObserver**: Hauteur dynamique intelligente
4. **3D Secure**: Gestion complète des paiements
