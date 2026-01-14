// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_functions/cloud_functions.dart';

/// Custom Action: createSubscription
///
/// Cette action appelle la Firebase Function pour créer un abonnement Stripe récurrent
/// Utilisez-la AVANT d'afficher le Custom Widget StripePaymentElement
///
/// Paramètres:
/// - priceId: ID du prix Stripe (ex: "price_1234567890")
///   Vous devez créer ce prix dans votre Dashboard Stripe
/// - customerEmail: Email du client
/// - customerName: Nom du client (optionnel)
/// - metadata: Map de métadonnées additionnelles (optionnel)
///
/// Retourne:
/// - clientSecret: À passer au Custom Widget
/// - subscriptionId: ID de l'abonnement pour référence
/// - customerId: ID du client Stripe
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
  String customerEmail, {
  String? customerName,
  Map<String, String>? metadata,
}) async {
  try {
    // Préparer les données pour la Cloud Function
    final Map<String, dynamic> data = {
      'priceId': priceId,
      'customerEmail': customerEmail,
    };

    if (customerName != null && customerName.isNotEmpty) {
      data['customerName'] = customerName;
    }

    if (metadata != null && metadata.isNotEmpty) {
      data['metadata'] = metadata;
    }

    // Appeler la Firebase Function
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('createSubscription');

    final response = await callable.call(data);

    // Vérifier la réponse
    if (response.data['success'] == true) {
      return {
        'success': true,
        'clientSecret': response.data['clientSecret'],
        'subscriptionId': response.data['subscriptionId'],
        'customerId': response.data['customerId'],
      };
    } else {
      return {
        'success': false,
        'error': response.data['error'] ?? 'Erreur inconnue',
      };
    }
  } catch (e) {
    print('Erreur lors de la création de l\'abonnement: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
