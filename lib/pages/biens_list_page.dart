import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_footer.dart';

/// Écran principal pour afficher et filtrer la liste des biens immobiliers
class BiensListPage extends StatefulWidget {
  const BiensListPage({super.key});

  @override
  State<BiensListPage> createState() => _BiensListPageState();
}

class _BiensListPageState extends State<BiensListPage> {
  // 🔍 Contrôleurs pour les champs de recherche
  final TextEditingController searchController = TextEditingController();       // Filtre texte (titre ou ville)
  final TextEditingController prixMaxController = TextEditingController();      // Filtre numérique (prix)

  bool filterDisponible = false;  // ✅ Filtre booléen : "disponible seulement"

  @override
  void dispose() {
    // 🧼 Libère la mémoire
    searchController.dispose();
    prixMaxController.dispose();
    super.dispose();
  }

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
          const SizedBox(height: 12),

          // 🎛️ Barre des filtres en haut à droite
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  // 🔎 Filtre : mot-clé (titre ou ville)
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: "Recherche mot-clé",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // 💰 Filtre : prix maximum
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: prixMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix max",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // ✅ Case à cocher : "Disponible seulement"
                  FilterChip(
                    label: const Text("Disponible seulement"),
                    selected: filterDisponible,
                    onSelected: (value) => setState(() => filterDisponible = value),
                    selectedColor: Colors.blueGrey.shade300,
                  ),

                  // 🔄 Bouton : réinitialise tous les filtres
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        prixMaxController.clear();
                        filterDisponible = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Réinitialiser"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔁 Affichage des biens récupérés depuis Firestore avec animation
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('biens').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement ❌'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;

                // 🧠 Application des filtres (local, après récupération Firestore)
                final keyword = searchController.text.toLowerCase();
                final prixMax = int.tryParse(prixMaxController.text);

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final titre = (data['titre'] ?? '').toString().toLowerCase();
                  final ville = (data['ville'] ?? '').toString().toLowerCase();
                  final disponible = data['disponible'] == true;
                  final prix = data['prix'] is int ? data['prix'] : 0;

                  final matchKeyword = titre.contains(keyword) || ville.contains(keyword);
                  final matchDisponibilite = !filterDisponible || disponible;
                  final matchPrix = prixMax == null || prix <= prixMax;

                  return matchKeyword && matchDisponibilite && matchPrix;
                }).toList();

                // ✨ Animation lors de changements dans le filtre
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: filteredDocs.isEmpty
                      ? const Center(
                          key: ValueKey('empty'),
                          child: Text("Aucun bien trouvé avec ces critères."),
                        )
                      : Padding(
                          key: ValueKey('grid'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.count(
                            crossAxisCount: isWide ? 3 : 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            children: filteredDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final titre = data['titre'] ?? 'Bien sans titre';
                              final ville = data['ville'] ?? 'Ville inconnue';
                              final prix = data['prix'] ?? 0;

                              return InkWell(
                                onTap: () {
                                  // 📲 Navigue vers la page de détails du bien
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
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        Text('📍 $ville',
                                            style: const TextStyle(color: Colors.white70)),
                                        Text('💰 $prix FCFA',
                                            style: const TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                );
              },
            ),
          ),

          // 🧱 Pied de page réutilisable
          const AppFooter(),
        ],
      ),

      // ➕ Bouton flottant pour insérer des biens fictifs (test rapide)
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

  /// 🔧 Ajoute quelques documents Firestore pour faciliter les tests
  Future<void> addMockBiens(BuildContext context) async {
    try {
      final biens = [
        {
          'titre': 'Appartement F3',
          'ville': 'Dakar',
          'prix': 15000000,
          'disponible': true,
        },
        {
          'titre': 'Villa avec piscine',
          'ville': 'Saly',
          'prix': 43000000,
          'disponible': false,
        },
        {
          'titre': 'Studio Meublé',
          'ville': 'Dakar Plateau',
          'prix': 9500000,
          'disponible': true,
        },
      ];

      final collection = FirebaseFirestore.instance.collection('biens');

      for (var bien in biens) {
        await collection.add(bien);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 3 biens d'exemple ajoutés")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : ${e.toString()}")),
      );
    }
  }
}
