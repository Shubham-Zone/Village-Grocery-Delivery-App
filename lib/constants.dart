import 'package:flutter/material.dart';

class CustomWidgets {
  // This method creates and returns the "Order Placed" dialog widget.
  static showOrderPlacedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 6), () {
          Navigator.of(context).pop(); // Close the dialog after 6 seconds
        });

        return AlertDialog(
          title: const Text('Order Placed'),
          content: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thank you for your order!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'We appreciate your business.',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog manually
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
