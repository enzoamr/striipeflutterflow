// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_functions/cloud_functions.dart';

/// Custom Action: confirmPaymentStatus
///
/// Cette action vérifie le statut d'un paiement auprès de Stripe
/// Utilisez-la pour confirmer qu'un paiement a bien été traité
///
/// Paramètres:
/// - paymentIntentId: ID du Payment Intent à vérifier
///
/// Retourne:
/// - success: true si le paiement a réussi
/// - status: Statut du paiement (succeeded, processing, requires_payment_method, etc.)
/// - error: Message d'erreur si échec
///
/// Exemple d'utilisation dans Flutter Flow:
/// 1. Après que le widget de paiement a terminé
/// 2. Appelez cette action pour confirmer le statut
/// 3. En fonction du résultat, créez votre commande dans Firestore

Future<dynamic> confirmPaymentStatus(String paymentIntentId) async {
  try {
    if (paymentIntentId.isEmpty) {
      return {
        'success': false,
        'error': 'Payment Intent ID manquant',
      };
    }

    // Appeler la Firebase Function
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('confirmPayment');

    final response = await callable.call({
      'paymentIntentId': paymentIntentId,
    });

    return {
      'success': response.data['success'] ?? false,
      'status': response.data['status'] ?? 'unknown',
      'paymentIntentId': response.data['paymentIntentId'],
    };
  } catch (e) {
    print('Erreur lors de la confirmation du paiement: $e');
    return {
      'success': false,
      'error': e.toString(),
      'status': 'error',
    };
  }
}
