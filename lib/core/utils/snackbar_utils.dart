import 'dart:ui';
import 'package:flutter/material.dart';

class SnackbarUtils {
  static void _showCustomSnackbar(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
  ) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 4),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    _showCustomSnackbar(context, message, Icons.check_circle_rounded, Colors.green);
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    _showCustomSnackbar(context, message, Icons.error_rounded, Colors.red);
  }

  static void showWarningSnackbar(BuildContext context, String message) {
    _showCustomSnackbar(context, message, Icons.warning_rounded, Colors.orange);
  }

  static void showInfoSnackbar(BuildContext context, String message) {
    _showCustomSnackbar(context, message, Icons.info_rounded, Colors.blue);
  }
}
