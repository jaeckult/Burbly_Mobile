// import 'package:flutter/material.dart';

// class PetNotificationService {
//   static final PetNotificationService _instance = PetNotificationService._internal();
//   factory PetNotificationService() => _instance;
//   PetNotificationService._internal();

//   // Callback to show snackbar on home screen
//   Function(String message, String type)? _showNotificationCallback;

//   // Register callback from home screen
//   void registerCallback(Function(String message, String type) callback) {
//     _showNotificationCallback = callback;
//   }

//   // Unregister callback
//   void unregisterCallback() {
//     _showNotificationCallback = null;
//   }

//   // Show pet feeding notification
//   void showPetFeedingNotification(String petName, int hungerReduced, int happinessGained) {
//     final message = '$petName enjoyed the treat! 🍽️ (Hunger -$hungerReduced, Happiness +$happinessGained)';
//     _showNotificationCallback?.call(message, 'success');
//   }

//   // Show pet attention notification
//   void showPetAttentionNotification(String petName) {
//     final message = '$petName is happy to see you! 😊';
//     _showNotificationCallback?.call(message, 'success');
//   }

//   // Show pet adoption notification
//   void showPetAdoptionNotification(String petName) {
//     final message = 'Welcome $petName! 🎉 Your new study companion is ready!';
//     _showNotificationCallback?.call(message, 'success');
//   }

//   // Show pet limit notification
//   void showPetLimitNotification() {
//     const message = 'You already have a pet! Only one pet per user is allowed.';
//     _showNotificationCallback?.call(message, 'warning');
//   }
// }
