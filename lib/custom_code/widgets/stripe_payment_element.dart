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

import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';

// ✅ FIX: platformViewRegistry est maintenant dans dart:ui_web (Flutter Web récent)
import 'dart:ui_web' as ui_web;

/// ✨ VERSION AUTO-SIZING - Le widget s'adapte à la hauteur réelle du Stripe element
/// - IGNORE widget.height (imposé par FlutterFlow mais non utilisé)
/// - Utilise ResizeObserver pour détecter la hauteur réelle du contenu Stripe
/// - Le container parent s'adapte automatiquement, pas de scroll interne
class StripePaymentElement extends StatefulWidget {
  const StripePaymentElement({
    Key? key,
    this.width,
    this.height, // ⚠️ IGNORÉ - FlutterFlow force à le mettre mais on ne l'utilise pas
    this.maxHeight, // Utilisé comme limite maximale si défini
    required this.stripePublishableKey,
    required this.clientSecret,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.buttonText = 'Payer',
    this.buttonColor = const Color(0xFF0570DE),
    this.hideButton = false,
  }) : super(key: key);

  final double? width;
  final double? height; // ⚠️ NON UTILISÉ
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

  dynamic _paymentElement;

  // ✅ Hauteur mesurée dynamiquement par ResizeObserver
  double? _measuredHeight;

  String get _containerId => 'payment-element-container-$viewId';
  String get _containerSelector => '#$_containerId';

  void _log(String msg) {
    // ignore: avoid_print
    print('[StripePaymentElement][$viewId] $msg');
  }

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
          ..style.height = '100%' // ✅ Prend 100% de la hauteur du parent Flutter
          ..style.minHeight = '1px'
          ..style.display = 'block'
          // ✅ PAS de overflow - on laisse le contenu prendre sa taille naturelle
          ..style.overflowY = 'visible'
          ..style.overflowX = 'hidden'
          ..style.boxSizing = 'border-box';

        // ✅ Applique maxHeight si défini (limite CSS)
        if (widget.maxHeight != null) {
          element.style.maxHeight = '${widget.maxHeight!.toStringAsFixed(0)}px';
          element.style.overflowY = 'auto'; // Scroll seulement si maxHeight dépassé
        }

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

  // ✨ PONT D'ÉVÉNÉMENTS: Fix isolation HtmlElementView
  void _installEventBridge() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          var containerId = '$_containerId';

          var pointerHandler = function(event) {
            var container = document.getElementById(containerId);
            if (!container) return;

            var target = event.target;
            if (!container.contains(target)) {
              var activeElement = document.activeElement;
              if (activeElement && container.contains(activeElement)) {
                activeElement.blur();
              }
            }
          };

          document.addEventListener('pointerdown', pointerHandler, true);
          document.addEventListener('touchstart', pointerHandler, true);

          window['eventBridge_$viewId'] = pointerHandler;
        })();
      '''
      ]);

      _log('✅ Event bridge installed');
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

  // ✅ Polling de la hauteur réelle du Stripe element (plus fiable que ResizeObserver)
  void _installResizeObserver() {
    try {
      // Callback Dart appelé quand la hauteur change
      final callback = js.allowInterop((double height) {
        _log('📏 Height detected: ${height.toStringAsFixed(1)}px');
        if (!mounted) return;

        setState(() {
          _measuredHeight = height;
        });
      });

      // Installation du polling côté JavaScript
      js.context['heightCallback_$viewId'] = callback;

      js.context.callMethod('eval', [
        '''
        (function() {
          var containerId = '$_containerId';
          var viewId = '$viewId';
          var lastHeight = 0;
          var stableCount = 0;

          // Fonction qui mesure la hauteur du premier enfant
          var measureHeight = function() {
            var container = document.getElementById(containerId);
            if (!container || !container.firstElementChild) {
              return;
            }

            var element = container.firstElementChild;
            var height = element.scrollHeight; // scrollHeight = hauteur totale du contenu

            console.log('[StripePaymentElement] Measured height:', height + 'px');

            // Si la hauteur a changé, appelle le callback
            if (Math.abs(height - lastHeight) > 5) { // Seuil de 5px pour éviter les micro-changements
              console.log('[StripePaymentElement] Height changed:', lastHeight + 'px -> ' + height + 'px');
              lastHeight = height;
              stableCount = 0;

              if (window['heightCallback_$viewId'] && height > 0) {
                window['heightCallback_$viewId'](height);
              }
            } else if (height > 0) {
              stableCount++;
              // Après 5 mesures stables, on arrête le polling fréquent et on passe à un polling lent
              if (stableCount === 5) {
                console.log('[StripePaymentElement] Height stabilized at ' + height + 'px, slowing down polling');
                clearInterval(window['heightInterval_$viewId']);
                // Polling lent toutes les 2 secondes pour détecter les changements tardifs
                window['heightInterval_$viewId'] = setInterval(measureHeight, 2000);
              }
            }
          };

          // Mesure initiale immédiate
          setTimeout(measureHeight, 100);

          // Polling rapide toutes les 100ms pendant les premières secondes
          var interval = setInterval(measureHeight, 100);
          window['heightInterval_$viewId'] = interval;

          console.log('[StripePaymentElement] Height polling started');
        })();
      '''
      ]);

      _log('✅ Height polling installed');
    } catch (e) {
      _log('⚠️ Failed to install height polling: $e');
    }
  }

  void _removeResizeObserver() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          var interval = window['heightInterval_$viewId'];
          if (interval) {
            clearInterval(interval);
            delete window['heightInterval_$viewId'];
          }

          delete window['heightCallback_$viewId'];
          console.log('[StripePaymentElement] Height polling stopped');
        })();
      '''
      ]);

      _log('✅ Height polling removed');
    } catch (e) {
      _log('⚠️ Failed to remove height polling: $e');
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

        // ✨ Expose triggerStripePayment() pour bouton externe FlutterFlow
        js.context['triggerStripePayment'] = js.allowInterop(() {
          _handlePayment();
        });
        _log('✅ JavaScript Bridge exposé: triggerStripePayment()');

        _installEventBridge();

        // ✅ Installe le polling de hauteur après le mount (délai pour laisser Stripe charger)
        await Future.delayed(const Duration(milliseconds: 300));
        _installResizeObserver();

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
    // ✅ Utilise la hauteur mesurée dynamiquement, ou une hauteur initiale réaliste
    final double displayHeight = _measuredHeight ?? 400.0; // Hauteur initiale avant mesure (Stripe fait ~350-400px)

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ S'adapte au contenu
          children: [
            // ✅ Le HTML prend la hauteur mesurée dynamiquement
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: displayHeight,
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
    _removeEventBridge();
    _removeResizeObserver();

    js.context.deleteProperty('stripeInstance_$viewId');
    js.context.deleteProperty('elementsInstance_$viewId');
    js.context.deleteProperty('triggerStripePayment');

    try {
      _paymentElement?.callMethod('off', ['change']);
    } catch (_) {}

    super.dispose();
  }
}
