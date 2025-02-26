import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class CustomSnackBar {
  // Show success message
  static void showSuccess({required String message}) {
    _showSnackBar(message, Colors.green);
  }

  // Show error message
  static void showError({required String message}) {
    _showSnackBar(message, Colors.red);
  }

  // Private method to display snack bars
  static void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
