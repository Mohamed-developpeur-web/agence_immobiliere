import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_footer.dart';

class BienDetailsPage extends StatelessWidget {
  const BienDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String id = ModalRoute.of(context)?.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du bien"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('biens').doc(id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Bien introuvable"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    data['imageUrl'] != null
                        ? Image.network(data['imageUrl'], height: 200, fit: BoxFit.cover)
                        : Image.asset('assets/no_image.png', height: 200),
                    const SizedBox(height: 16),
                    Text(data['titre'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("${data['prix']} FCFA", style: const TextStyle(color: Colors.green, fontSize: 18)),
                    const SizedBox(height: 12),
                    Text(data['description'] ?? ''),
                    const SizedBox(height: 8),
                    Text("Ville : ${data['ville']}"),
                    Text("Disponible : ${data['disponible'] == true ? 'Oui' : 'Non'}"),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Modifier"),
                          onPressed: () => Navigator.pushNamed(context, '/editBien', arguments: id),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text("Supprimer"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('biens').doc(id).delete();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Bien supprimé")),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const AppFooter(),
            ],
          );
        },
      ),
    );
  }
}
