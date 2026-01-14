// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:js' as js;

/// Custom Widget: StripePaymentElement
///
/// Ce widget affiche le Stripe Payment Element pour accepter les paiements
/// Il s'intègre avec les Firebase Functions pour créer des Payment Intents
///
/// Paramètres:
/// - width & height: Dimensions du widget
/// - stripePublishableKey: Votre clé publique Stripe (pk_test_... ou pk_live_...)
/// - clientSecret: Le client secret du Payment Intent (obtenu depuis Firebase Function)
/// - onPaymentSuccess: Callback appelé quand le paiement réussit
/// - onPaymentError: Callback appelé en cas d'erreur
///
/// Utilisation dans Flutter Flow:
/// 1. Ajoutez ce Custom Widget à votre page
/// 2. Configurez les paramètres (clé publique, client secret)
/// 3. Utilisez les callbacks pour gérer le succès/échec
class StripePaymentElement extends StatefulWidget {
  const StripePaymentElement({
    Key? key,
    this.width,
    this.height,
    required this.stripePublishableKey,
    required this.clientSecret,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.buttonText = 'Payer',
    this.buttonColor = const Color(0xFF0570DE),
  }) : super(key: key);

  final double? width;
  final double? height;
  final String stripePublishableKey;
  final String clientSecret;
  final Future<dynamic> Function()? onPaymentSuccess;
  final Future<dynamic> Function(String error)? onPaymentError;
  final String buttonText;
  final Color buttonColor;

  @override
  _StripePaymentElementState createState() => _StripePaymentElementState();
}

class _StripePaymentElementState extends State<StripePaymentElement> {
  final String viewId = 'stripe-payment-element-${DateTime.now().millisecondsSinceEpoch}';
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  void _registerView() {
    // Enregistrer la vue HTML pour le Payment Element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final element = html.DivElement()
          ..id = 'payment-element-container-${this.viewId}'
          ..style.width = '100%'
          ..style.height = '100%';

        // Charger le script Stripe.js si ce n'est pas déjà fait
        _loadStripeScript().then((_) {
          _initializeStripeElement(element);
        });

        return element;
      },
    );
  }

  Future<void> _loadStripeScript() async {
    // Vérifier si Stripe.js est déjà chargé
    if (js.context.hasProperty('Stripe')) {
      return;
    }

    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src = 'https://js.stripe.com/v3/'
      ..async = true;

    script.onLoad.listen((event) {
      completer.complete();
    });

    script.onError.listen((event) {
      completer.completeError('Erreur lors du chargement de Stripe.js');
    });

    html.document.head!.append(script);
    return completer.future;
  }

  void _initializeStripeElement(html.Element container) {
    // Initialiser Stripe avec la clé publique
    final stripe = js.context.callMethod('Stripe', [widget.stripePublishableKey]);

    // Options pour le Payment Element
    final options = js.JsObject.jsify({
      'clientSecret': widget.clientSecret,
      'appearance': {
        'theme': 'stripe',
        'variables': {
          'colorPrimary': '#${widget.buttonColor.value.toRadixString(16).substring(2)}',
        }
      }
    });

    // Créer les Elements
    final elements = stripe.callMethod('elements', [options]);

    // Créer le Payment Element
    final paymentElement = elements.callMethod('create', ['payment']);

    // Monter le Payment Element dans le conteneur
    paymentElement.callMethod('mount', ['#payment-element-container-${this.viewId}']);

    // Stocker les objets Stripe pour utilisation ultérieure
    js.context['stripeInstance_${this.viewId}'] = stripe;
    js.context['elementsInstance_${this.viewId}'] = elements;
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final stripe = js.context['stripeInstance_${viewId}'];
      final elements = js.context['elementsInstance_${viewId}'];

      if (stripe == null || elements == null) {
        throw Exception('Stripe non initialisé');
      }

      // Confirmer le paiement
      final result = await _confirmPayment(stripe, elements);

      if (result['error'] != null) {
        final errorMessage = result['error']['message'] ?? 'Erreur de paiement';
        setState(() {
          _errorMessage = errorMessage;
        });
        if (widget.onPaymentError != null) {
          await widget.onPaymentError!(errorMessage);
        }
      } else if (result['paymentIntent']['status'] == 'succeeded') {
        // Paiement réussi
        if (widget.onPaymentSuccess != null) {
          await widget.onPaymentSuccess!();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (widget.onPaymentError != null) {
        await widget.onPaymentError!(e.toString());
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<Map<String, dynamic>> _confirmPayment(dynamic stripe, dynamic elements) async {
    final completer = Completer<Map<String, dynamic>>();

    final resultPromise = stripe.callMethod('confirmPayment', [
      js.JsObject.jsify({
        'elements': elements,
        'confirmParams': {
          'return_url': html.window.location.href,
        },
        'redirect': 'if_required',
      })
    ]);

    // Convertir la Promise JavaScript en Future Dart
    final then = js.JsFunction.withThis((thisArg, result) {
      final resultMap = <String, dynamic>{};
      if (result['error'] != null) {
        resultMap['error'] = {
          'message': result['error']['message'],
          'type': result['error']['type'],
        };
      } else if (result['paymentIntent'] != null) {
        resultMap['paymentIntent'] = {
          'id': result['paymentIntent']['id'],
          'status': result['paymentIntent']['status'],
        };
      }
      completer.complete(resultMap);
    });

    final catchError = js.JsFunction.withThis((thisArg, error) {
      completer.complete({
        'error': {'message': error.toString()}
      });
    });

    resultPromise.callMethod('then', [then]).callMethod('catch', [catchError]);

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Element
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: HtmlElementView(viewType: viewId),
            ),
          ),

          // Message d'erreur
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
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bouton de paiement
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Nettoyer les instances Stripe
    js.context.deleteProperty('stripeInstance_${viewId}');
    js.context.deleteProperty('elementsInstance_${viewId}');
    super.dispose();
  }
}
