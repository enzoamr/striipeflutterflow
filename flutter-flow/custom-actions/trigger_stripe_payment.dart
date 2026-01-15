// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:js' as js;

/// Custom Action: triggerStripePayment
///
/// Déclenche le paiement Stripe depuis un bouton externe Flutter Flow
///
/// UTILISATION:
/// 1. Modifiez votre Custom Widget pour exposer la fonction en JavaScript
/// 2. Ajoutez cette action à votre bouton Flutter Flow
/// 3. Le paiement se déclenchera comme si vous aviez cliqué sur le bouton intégré
///
/// PRÉREQUIS:
/// Le Custom Widget doit exposer la fonction JavaScript 'triggerStripePayment'
/// Voir: docs/EXTERNAL-BUTTON-GUIDE.md pour la configuration complète
///
/// Return:
/// - success: true si la fonction a été trouvée et appelée
/// - error: Message d'erreur si la fonction n'est pas disponible
Future<dynamic> triggerStripePayment() async {
  try {
    // Vérifier si la fonction JavaScript existe
    if (js.context.hasProperty('triggerStripePayment')) {
      // Appeler la fonction de paiement
      js.context.callMethod('triggerStripePayment', []);

      return {
        'success': true,
        'message': 'Paiement déclenché',
      };
    } else {
      // La fonction n'existe pas (widget pas encore initialisé ou mal configuré)
      return {
        'success': false,
        'error': 'Stripe Payment Element non initialisé. '
                 'Assurez-vous que le Custom Widget est affiché et prêt.',
      };
    }
  } catch (e) {
    print('Erreur lors du déclenchement du paiement: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
