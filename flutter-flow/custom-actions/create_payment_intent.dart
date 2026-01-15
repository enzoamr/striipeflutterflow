// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

/// Custom Action: createPaymentIntent
///
/// Appelle la Firebase Function `createPaymentIntent` pour créer un PaymentIntent Stripe.
///
/// Params (FlutterFlow-friendly):
/// - amount: montant en euros (ex: 10.50)
/// - customerEmail: email du client
/// - customerName: nom du client (optionnel, mettre '' si non utilisé)
/// - description: description (optionnel, mettre '' si non utilisé)
/// - metadataJson: JSON string optionnel (ex: {"orderId":"123"}), mettre '' si non utilisé
///
/// Return (Map):
/// - success: bool
/// - clientSecret: String?
/// - paymentIntentId: String?
/// - customerId: String?
/// - error: String?
///
/// Exemple d'utilisation dans Flutter Flow:
/// 1. Créez un App State "clientSecret" (String)
/// 2. Avant d'afficher le widget, appelez cette action
/// 3. Stockez le résultat dans App State
/// 4. Passez le clientSecret au Custom Widget
Future<dynamic> createPaymentIntent(
  double amount,
  String customerEmail,
  String customerName,
  String description,
  String metadataJson,
) async {
  try {
    final int amountInCents = (amount * 100).round();

    final Map<String, dynamic> data = {
      'amount': amountInCents,
      'currency': 'eur',
      'customerEmail': customerEmail,
    };

    if (customerName.trim().isNotEmpty) {
      data['customerName'] = customerName.trim();
    }

    if (description.trim().isNotEmpty) {
      data['description'] = description.trim();
    }

    if (metadataJson.trim().isNotEmpty) {
      // metadataJson doit être un JSON valide: {"key":"value"}
      final dynamic decoded = jsonDecode(metadataJson);
      if (decoded is Map) {
        data['metadata'] = Map<String, dynamic>.from(decoded);
      }
    }

    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('createPaymentIntent');

    final response = await callable.call(data);

    final Map<String, dynamic> resp =
        (response.data is Map) ? Map<String, dynamic>.from(response.data) : {};

    if (resp['success'] == true) {
      return {
        'success': true,
        'clientSecret': resp['clientSecret'],
        'paymentIntentId': resp['paymentIntentId'],
        'customerId': resp['customerId'],
      };
    }

    return {
      'success': false,
      'error': resp['error'] ?? 'Erreur inconnue',
    };
  } catch (e) {
    print('Erreur lors de la création du Payment Intent: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
