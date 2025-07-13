import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../widgets/app_footer.dart';

/// 🏘️ Page détaillée pour afficher les informations d’un bien immobilier
class BienDetailsPage extends StatelessWidget {
  const BienDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final role = user?.role ?? '';

    // 📥 Récupération des arguments passés via Navigator
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null || args['id'] == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Aucune donnée reçue pour ce bien.",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final String bienId = args['id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du bien"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),

      // 🧱 Structure principale avec footer en bas
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('biens').doc(bienId).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text("❌ Erreur lors du chargement du bien.");
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("Aucun bien trouvé.");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final titre = data['titre'] ?? 'Bien sans titre';
                  final ville = data['ville'] ?? 'Inconnu';
                  final prix = data['prix'] ?? 0;
                  final description = data['description'] ?? 'Aucune description fournie.';
                  final imageUrl = data['imageUrl'];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🖼️ Affichage image principale
                        if (imageUrl != null && imageUrl.toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text("❌ Image non disponible"),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // 🏷️ Titre du bien
                        Text(
                          '🏠 $titre',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // 📝 Description
                        const Text(
                          '📝 Description :',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // 🏙️ Infos de localisation et prix
                        Text('📍 Ville : $ville'),
                        Text('💰 Prix : $prix FCFA'),

                        const SizedBox(height: 32),

                        const Text(
                          "📞 Contact : 77 000 00 00",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 32),

                        // 🎯 Boutons d'action réservés aux administrateurs et agents
                        if (role == 'admin' || role == 'agent')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/editBien',
                                    arguments: {
                                      'id': bienId,
                                      'titre': titre,
                                      'ville': ville,
                                      'prix': prix,
                                      'description': description,
                                      'imageUrl': imageUrl,
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Modifier"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Supprimer le bien ?"),
                                      content: const Text(
                                          "Confirmez-vous la suppression de ce bien ?"),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text("Annuler")),
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text("Supprimer")),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('biens')
                                          .doc(bienId)
                                          .delete();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text("✅ Bien supprimé avec succès")),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text("❌ Erreur : ${e.toString()}")),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text("Supprimer"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 📌 Pied de page aligné tout en bas
          const AppFooter(),
        ],
      ),
    );
  }
}
