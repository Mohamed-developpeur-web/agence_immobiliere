import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/biens');
            },
            child: const Text('Voir la liste des biens'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/addBien');
            },
            child: const Text('Ajouter un bien'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: const Text('Mon Profil'),
          ),
        ],
      ),
    );
  }
}
