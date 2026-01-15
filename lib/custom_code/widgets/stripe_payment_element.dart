// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/flutter_flow/custom_functions.dart'; // Imports custom functionss

import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';
import 'dart:math' as math;

// ✅ FIX: platformViewRegistry est maintenant dans dart:ui_web (Flutter Web récent)
import 'dart:ui_web' as ui_web;

/// ✨ VERSION AVEC JAVASCRIPT BRIDGE + FIX ISOLATION ÉVÉNEMENTS + FIX SCROLL VISIBILITY ✨
///
/// Cette version résout le problème d'isolation des événements entre
/// HtmlElementView et Flutter, ainsi que le problème de collapse au scroll.
///
/// NOUVEAUTÉS:
/// - hideButton: bool → Cache le bouton intégré si true
/// - Expose une fonction JavaScript 'triggerStripePayment' pour déclencher le paiement depuis l'extérieur
/// - ✨ FIX ISOLATION: Pont d'événements DOM qui capture les clics externes
/// - ✨ FIX SCROLL VISIBILITY: Ne mesure la hauteur QUE si l'élément est visible dans le viewport
///   → Évite le collapse du widget quand on scroll et qu'il sort de la vue
///   → Conserve la dernière hauteur valide au lieu de mesurer 0px
///
/// TOUTES LES AUTRES FONCTIONNALITÉS SONT IDENTIQUES:
/// - ResizeObserver pour hauteur dynamique
/// - Auto-height management
/// - ClipRect pour éviter débordement
/// - Gestion 3D Secure
/// - etc.
class StripePaymentElement extends StatefulWidget {
  const StripePaymentElement({
    Key? key,
    this.width,
    this.height, // si null => auto-height
    this.maxHeight, // ✅ optionnel pour éviter des hauteurs énormes
    required this.stripePublishableKey,
    required this.clientSecret,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.buttonText = 'Payer',
    this.buttonColor = const Color(0xFF0570DE),
    this.hideButton = false, // ✨ Cache le bouton intégré
  }) : super(key: key);

  final double? width;
  final double? height;
  final double? maxHeight;

  final String stripePublishableKey;
  final String clientSecret;
  final Future<dynamic> Function()? onPaymentSuccess;
  final Future<dynamic> Function(String error)? onPaymentError;
  final String buttonText;
  final Color buttonColor;
  final bool hideButton;

  @override
  _StripePaymentElementState createState() => _StripePaymentElementState();
}

class _StripePaymentElementState extends State<StripePaymentElement> {
  final String viewId =
      'stripe-payment-element-${DateTime.now().millisecondsSinceEpoch}';

  bool _isProcessing = false;
  String? _errorMessage;

  double? _measuredElementHeight;
  Timer? _measureDebounce;
  dynamic _resizeObserver;
  dynamic _paymentElement;

  String get _containerId => 'payment-element-container-$viewId';
  String get _containerSelector => '#$_containerId';

  // --- Helpers ---
  void _log(String msg) {
    // ignore: avoid_print
    print('[StripePaymentElement][$viewId] $msg');
  }

  double get _minH => 220.0; // ✅ minimum visuel réaliste
  double get _maxH =>
      widget.maxHeight ?? 720.0; // ✅ max pour éviter les délires

  @override
  void initState() {
    super.initState();
    _log('initState() clientSecretLen=${widget.clientSecret.length}');
    _registerView();
  }

  void _registerView() {
    _log('_registerView() registerViewFactory');

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int factoryViewId) {
        _log('registerViewFactory callback (factoryViewId=$factoryViewId)');

        final element = html.DivElement()
          ..id = _containerId
          ..style.width = '100%'
          ..style.minHeight = '1px'
          // ✅ Empêche le HTML de déborder visuellement
          ..style.overflow = 'hidden'
          ..style.boxSizing = 'border-box';

        _loadStripeScript().then((_) {
          _log(
              'Stripe.js loaded. window.Stripe=${js.context.hasProperty('Stripe')}');
          _initializeStripeElement();
        }).catchError((e) {
          _log('Stripe.js load FAILED: $e');
          if (!mounted) return;
          setState(() => _errorMessage = e.toString());
          widget.onPaymentError?.call(e.toString());
        });

        return element;
      },
    );
  }

  Future<void> _loadStripeScript() async {
    _log(
        '_loadStripeScript() Stripe present=${js.context.hasProperty('Stripe')}');

    if (js.context.hasProperty('Stripe')) return;

    final existing = html.document.querySelector('script[data-stripe-js="1"]');
    if (existing != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!js.context.hasProperty('Stripe')) {
        throw Exception(
            'Stripe.js tag présent mais window.Stripe absent (bloqué ?)');
      }
      return;
    }

    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src = 'https://js.stripe.com/v3/'
      ..async = true
      ..setAttribute('data-stripe-js', '1');

    script.onLoad.listen((_) {
      _log(
          '_loadStripeScript() onLoad -> Stripe present=${js.context.hasProperty('Stripe')}');
      if (!completer.isCompleted) completer.complete();
    });

    script.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError('Erreur chargement Stripe.js (AdBlock/CSP ?)');
      }
    });

    html.document.head!.append(script);

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw Exception('Timeout chargement Stripe.js'),
    );
  }

  void _debouncedMeasure() {
    _measureDebounce?.cancel();
    _measureDebounce =
        Timer(const Duration(milliseconds: 90), _measureHeightNow);
  }

  /// ✨ FIX SCROLL VISIBILITY: Vérifie si l'élément est visible dans le viewport
  /// avant de mesurer sa hauteur. Évite le collapse quand on scroll.
  bool _isElementVisibleInViewport(html.Element el) {
    try {
      final rect = el.getBoundingClientRect();

      // ✅ Vérifie que l'élément a une taille réelle (pas collapsed)
      if (rect.width <= 0 || rect.height <= 0) {
        return false;
      }

      // ✅ Vérifie que l'élément est au moins partiellement visible dans le viewport
      final windowHeight = html.window.innerHeight ?? 0;
      final windowWidth = html.window.innerWidth ?? 0;

      final isVisible = rect.bottom > 0 &&
                       rect.right > 0 &&
                       rect.top < windowHeight &&
                       rect.left < windowWidth;

      return isVisible;
    } catch (e) {
      _log('⚠️ _isElementVisibleInViewport error: $e');
      return false;
    }
  }

  void _measureHeightNow() {
    final el = html.document.querySelector(_containerSelector);
    if (el == null) return;

    // ✨ FIX: Ne mesure QUE si l'élément est visible dans le viewport
    if (!_isElementVisibleInViewport(el)) {
      _log('⏸️ Element not visible in viewport, keeping last height: $_measuredElementHeight');
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

  void _installResizeObserver() {
    if (!js.context.hasProperty('ResizeObserver')) return;

    try {
      final ro = js.JsObject(js.context['ResizeObserver'],
          [js.JsFunction.withThis((_, __) => _debouncedMeasure())]);

      final el = html.document.querySelector(_containerSelector);
      if (el != null) {
        ro.callMethod('observe', [el]);
        _resizeObserver = ro;
        _log('ResizeObserver installed');
      }
    } catch (e) {
      _log('ResizeObserver install failed: $e');
    }
  }

  void _disposeResizeObserver() {
    try {
      _resizeObserver?.callMethod('disconnect');
    } catch (_) {}
    _resizeObserver = null;
  }

  // ✨ PONT D'ÉVÉNEMENTS: Solution propre au problème d'isolation HtmlElementView
  // Le HtmlElementView bloque TOUS les événements entre Flutter et HTML.
  // Cette fonction installe un listener global au niveau DOM qui :
  // 1. Capture TOUS les clics (phase capture, avant propagation)
  // 2. Vérifie si le clic est en dehors du container HTML
  // 3. Si oui, blur automatiquement l'élément actif (input, button, etc)
  // Fonctionne pour TOUS les éléments interactifs, pas juste les inputs.
  void _installEventBridge() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          var containerId = '$_containerId';

          // Handler universel pour tous les événements de pointeur
          var pointerHandler = function(event) {
            var container = document.getElementById(containerId);
            if (!container) return;

            var target = event.target;

            // Si le clic/touch est en dehors du container HTML
            if (!container.contains(target)) {
              var activeElement = document.activeElement;

              // Si un élément à l'intérieur du container a le focus
              if (activeElement && container.contains(activeElement)) {
                activeElement.blur();
              }
            }
          };

          // Écoute en phase capture (avant que l'événement atteigne la cible)
          // pour intercepter TOUS les clics, même ceux gérés par Flutter
          document.addEventListener('pointerdown', pointerHandler, true);
          document.addEventListener('touchstart', pointerHandler, true);

          // Stocke le handler pour le cleanup
          window['eventBridge_$viewId'] = pointerHandler;
        })();
      '''
      ]);

      _log('✅ Event bridge installed (fixes HtmlElementView isolation)');
    } catch (e) {
      _log('⚠️ Failed to install event bridge: $e');
    }
  }

  void _removeEventBridge() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          var handler = window['eventBridge_$viewId'];
          if (handler) {
            document.removeEventListener('pointerdown', handler, true);
            document.removeEventListener('touchstart', handler, true);
            delete window['eventBridge_$viewId'];
          }
        })();
      '''
      ]);

      _log('✅ Event bridge removed');
    } catch (e) {
      _log('⚠️ Failed to remove event bridge: $e');
    }
  }

  Future<void> _mountWhenReady({
    required dynamic paymentElement,
    required dynamic stripe,
    required dynamic elements,
    int attempts = 40,
    Duration delay = const Duration(milliseconds: 60),
  }) async {
    for (int i = 0; i < attempts; i++) {
      final exists = html.document.querySelector(_containerSelector) != null;
      if (exists) {
        paymentElement.callMethod('mount', [_containerSelector]);

        js.context['stripeInstance_$viewId'] = stripe;
        js.context['elementsInstance_$viewId'] = elements;
        _paymentElement = paymentElement;

        // ✨ JAVASCRIPT BRIDGE: Exposer la fonction de paiement
        // Permet d'appeler _handlePayment() depuis un bouton externe Flutter Flow
        js.context['triggerStripePayment'] = js.allowInterop(() {
          _handlePayment();
        });
        _log('✅ JavaScript Bridge exposé: triggerStripePayment()');

        // ✨ PONT D'ÉVÉNEMENTS: Résout l'isolation HtmlElementView <-> Flutter
        _installEventBridge();

        _debouncedMeasure();
        Future.delayed(const Duration(milliseconds: 220), _measureHeightNow);
        Future.delayed(const Duration(milliseconds: 520), _measureHeightNow);

        _installResizeObserver();

        try {
          paymentElement.callMethod('on', [
            'change',
            js.JsFunction.withThis((_, __) => _debouncedMeasure())
          ]);
        } catch (_) {}

        return;
      }
      await Future.delayed(delay);
    }

    if (!mounted) return;
    setState(() {
      _errorMessage =
          'Stripe mount() impossible: container DOM introuvable (${_containerSelector}).';
    });
  }

  void _initializeStripeElement() {
    if (widget.clientSecret.isEmpty) {
      if (!mounted) return;
      setState(() => _errorMessage = 'clientSecret vide');
      return;
    }

    if (!js.context.hasProperty('Stripe')) {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'Stripe.js non chargé (window.Stripe absent)');
      return;
    }

    try {
      final stripe =
          js.context.callMethod('Stripe', [widget.stripePublishableKey]);

      final options = js.JsObject.jsify({
        'clientSecret': widget.clientSecret,
        'appearance': {
          'theme': 'stripe',
          'variables': {
            'colorPrimary':
                '#${widget.buttonColor.value.toRadixString(16).substring(2)}',
          }
        },
        // ✅ optionnel: désactiver Link côté UI
        // 'link': 'never',
      });

      final elements = stripe.callMethod('elements', [options]);
      final paymentElement = elements.callMethod('create', ['payment']);

      _mountWhenReady(
          paymentElement: paymentElement, stripe: stripe, elements: elements);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Init Stripe Elements failed: $e');
    }
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return;

    final stripe = js.context['stripeInstance_$viewId'];
    final elements = js.context['elementsInstance_$viewId'];

    if (stripe == null || elements == null) {
      final msg = 'Stripe non initialisé (attends 1-2s après affichage).';
      if (!mounted) return;
      setState(() => _errorMessage = msg);
      await widget.onPaymentError?.call(msg);
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _confirmPayment(stripe, elements);

      if (result['error'] != null) {
        final msg = (result['error'] as Map?)?['message']?.toString() ??
            'Erreur paiement';
        if (!mounted) return;
        setState(() => _errorMessage = msg);
        await widget.onPaymentError?.call(msg);
      } else if ((result['paymentIntent'] as Map?)?['status'] == 'succeeded') {
        await widget.onPaymentSuccess?.call();
      }

      _debouncedMeasure();
      Future.delayed(const Duration(milliseconds: 250), _measureHeightNow);
    } catch (e) {
      final msg = e.toString();
      if (!mounted) return;
      setState(() => _errorMessage = msg);
      await widget.onPaymentError?.call(msg);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, dynamic>> _confirmPayment(
      dynamic stripe, dynamic elements) async {
    final completer = Completer<Map<String, dynamic>>();

    final payload = js.JsObject.jsify({
      'elements': elements,
      'confirmParams': {'return_url': html.window.location.href},
      'redirect': 'if_required',
    });

    final promise = stripe.callMethod('confirmPayment', [payload]);

    final then = js.JsFunction.withThis((_, result) {
      final out = <String, dynamic>{};

      try {
        if (result != null && result['error'] != null) {
          out['error'] = {
            'message': result['error']['message'],
            'type': result['error']['type'],
          };
        } else if (result != null && result['paymentIntent'] != null) {
          out['paymentIntent'] = {
            'id': result['paymentIntent']['id'],
            'status': result['paymentIntent']['status'],
          };
        }
      } catch (e) {
        out['error'] = {'message': 'Réponse Stripe invalide: $e'};
      }

      if (!completer.isCompleted) completer.complete(out);
    });

    final catchErr = js.JsFunction.withThis((_, error) {
      if (!completer.isCompleted) {
        completer.complete({
          'error': {'message': error.toString()}
        });
      }
    });

    promise.callMethod('then', [then]).callMethod('catch', [catchErr]);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ height prioritaire si fourni, sinon hauteur mesurée avec défaut sécurisé
    final double elementHeight =
        widget.height ?? (_measuredElementHeight ?? 360.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: widget.width,
        // ✅ si ton parent ne contraint pas, au moins on empêche de déborder visuellement
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ IMPORTANT: on clippe aussi la partie HTML
            ClipRect(
              child: SizedBox(
                height: elementHeight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: HtmlElementView(viewType: viewId),
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ✨ Bouton visible seulement si hideButton = false
            if (!widget.hideButton)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.buttonText,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),

            // ✨ Indicateur de chargement si bouton caché
            if (widget.hideButton && _isProcessing)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Traitement du paiement...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _measureDebounce?.cancel();
    _disposeResizeObserver();

    // ✨ Retire le pont d'événements avant de disposer
    _removeEventBridge();

    js.context.deleteProperty('stripeInstance_$viewId');
    js.context.deleteProperty('elementsInstance_$viewId');
    js.context.deleteProperty('triggerStripePayment');

    try {
      _paymentElement?.callMethod('off', ['change']);
    } catch (_) {}

    super.dispose();
  }
}
