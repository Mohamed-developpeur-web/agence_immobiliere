import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_footer.dart';

class BiensListPage extends StatelessWidget {
  const BiensListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des biens'),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            // 🔄 Écoute en temps réel de la collection `biens`
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('biens').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement des biens ❌'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("Aucun bien trouvé pour l’instant."));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: isWide ? 3 : 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final titre = data['titre'] ?? 'Bien sans titre';
                      final ville = data['ville'] ?? 'Ville inconnue';
                      final prix = data['prix'] ?? 0;

                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/bienDetails',
                            arguments: {
                              'id': doc.id,
                              'titre': titre,
                              'ville': ville,
                              'prix': prix,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.indigo.shade200,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.house, size: 40, color: Colors.white),
                                const SizedBox(height: 12),
                                Text(titre,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('📍 $ville', style: const TextStyle(color: Colors.white70)),
                                Text('💰 $prix FCFA', style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const AppFooter(),
        ],
      ),

      // 🧪 Bouton pour injecter quelques biens d’exemple
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Ajouter exemples"),
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          await addMockBiens(context);
        },
      ),
    );
  }

  /// 🔧 Fonction pour ajouter quelques biens fictifs
  Future<void> addMockBiens(BuildContext context) async {
    try {
      final biens = [
        {'titre': 'Appartement F3', 'ville': 'Dakar', 'prix': 15000000},
        {'titre': 'Villa avec piscine', 'ville': 'Saly', 'prix': 43000000},
        {'titre': 'Studio Meublé', 'ville': 'Dakar Plateau', 'prix': 9500000},
      ];

      final collection = FirebaseFirestore.instance.collection('biens');

      for (var bien in biens) {
        await collection.add(bien);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 3 biens d'exemple ajoutés à Firestore")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : ${e.toString()}")),
      );
    }
  }
}
