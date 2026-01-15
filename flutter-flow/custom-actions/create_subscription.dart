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

/// Custom Action: createSubscription
///
/// Appelle la Firebase Function `createSubscription` pour créer un abonnement Stripe.
///
/// Params (FlutterFlow-friendly):
/// - priceId: ID du prix Stripe (ex: "price_1234...")
/// - customerEmail: email du client
/// - customerName: nom du client (optionnel, mettre '' si non utilisé)
/// - metadataJson: JSON string optionnel (ex: {"plan":"premium"}), mettre '' si non utilisé
///
/// Return (Map):
/// - success: bool
/// - clientSecret: String?
/// - subscriptionId: String?
/// - customerId: String?
/// - error: String?
///
/// Comment créer un Price ID dans Stripe:
/// 1. Allez sur https://dashboard.stripe.com/test/products
/// 2. Créez un nouveau produit
/// 3. Ajoutez un prix récurrent (mensuel, annuel, etc.)
/// 4. Copiez le Price ID (commence par "price_")
///
/// Exemple d'utilisation dans Flutter Flow:
/// 1. Créez un App State "clientSecret" (String)
/// 2. Avant d'afficher le widget, appelez cette action avec votre priceId
/// 3. Stockez le résultat dans App State
/// 4. Passez le clientSecret au Custom Widget
Future<dynamic> createSubscription(
  String priceId,
  String customerEmail,
  String customerName,
  String metadataJson,
) async {
  try {
    final Map<String, dynamic> data = {
      'priceId': priceId,
      'customerEmail': customerEmail,
    };

    if (customerName.trim().isNotEmpty) {
      data['customerName'] = customerName.trim();
    }

    if (metadataJson.trim().isNotEmpty) {
      // metadataJson doit être un JSON valide: {"key":"value"}
      final dynamic decoded = jsonDecode(metadataJson);
      if (decoded is Map) {
        data['metadata'] = Map<String, dynamic>.from(decoded);
      }
    }

    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('createSubscription');

    final response = await callable.call(data);

    final Map<String, dynamic> resp =
        (response.data is Map) ? Map<String, dynamic>.from(response.data) : {};

    if (resp['success'] == true) {
      return {
        'success': true,
        'clientSecret': resp['clientSecret'],
        'subscriptionId': resp['subscriptionId'],
        'customerId': resp['customerId'],
      };
    }

    return {
      'success': false,
      'error': resp['error'] ?? 'Erreur inconnue',
    };
  } catch (e) {
    print('Erreur lors de la création de l\'abonnement: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
