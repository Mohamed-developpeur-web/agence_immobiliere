import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Text(
        '© 2025 Agence Immobilière - Tous droits réservés',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
