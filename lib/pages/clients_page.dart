import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/roles.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des clients")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: Roles.client)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final clients = snapshot.data!.docs;
          if (clients.isEmpty) return const Center(child: Text("Aucun client enregistré."));

          return ListView.separated(
            itemCount: clients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = clients[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['pseudo'] ?? ''),
                subtitle: Text(data['email'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
