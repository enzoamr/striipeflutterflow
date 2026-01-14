// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_functions/cloud_functions.dart';

/// Custom Action: createPaymentIntent
///
/// Cette action appelle la Firebase Function pour créer un Payment Intent Stripe
/// Utilisez-la AVANT d'afficher le Custom Widget StripePaymentElement
///
/// Paramètres:
/// - amount: Montant en euros (ex: 10.50 pour 10,50€)
/// - customerEmail: Email du client
/// - customerName: Nom du client (optionnel)
/// - description: Description du paiement (optionnel)
/// - metadata: Map de métadonnées additionnelles (optionnel)
///
/// Retourne:
/// - clientSecret: À passer au Custom Widget
/// - paymentIntentId: ID du paiement pour référence
/// - customerId: ID du client Stripe
///
/// Exemple d'utilisation dans Flutter Flow:
/// 1. Créez un App State "clientSecret" (String)
/// 2. Avant d'afficher le widget, appelez cette action
/// 3. Stockez le résultat dans App State
/// 4. Passez le clientSecret au Custom Widget

Future<dynamic> createPaymentIntent(
  double amount,
  String customerEmail, {
  String? customerName,
  String? description,
  Map<String, String>? metadata,
}) async {
  try {
    // Convertir le montant en centimes (Stripe utilise les centimes)
    final int amountInCents = (amount * 100).round();

    // Préparer les données pour la Cloud Function
    final Map<String, dynamic> data = {
      'amount': amountInCents,
      'currency': 'eur',
      'customerEmail': customerEmail,
    };

    if (customerName != null && customerName.isNotEmpty) {
      data['customerName'] = customerName;
    }

    if (description != null && description.isNotEmpty) {
      data['description'] = description;
    }

    if (metadata != null && metadata.isNotEmpty) {
      data['metadata'] = metadata;
    }

    // Appeler la Firebase Function
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('createPaymentIntent');

    final response = await callable.call(data);

    // Vérifier la réponse
    if (response.data['success'] == true) {
      return {
        'success': true,
        'clientSecret': response.data['clientSecret'],
        'paymentIntentId': response.data['paymentIntentId'],
        'customerId': response.data['customerId'],
      };
    } else {
      return {
        'success': false,
        'error': response.data['error'] ?? 'Erreur inconnue',
      };
    }
  } catch (e) {
    print('Erreur lors de la création du Payment Intent: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
