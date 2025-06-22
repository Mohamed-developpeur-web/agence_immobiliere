import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_footer.dart';

class BiensListPage extends StatefulWidget {
  const BiensListPage({super.key});

  @override
  State<BiensListPage> createState() => _BiensListPageState();
}

class _BiensListPageState extends State<BiensListPage> {
  bool isLoadingExemples = false;
  int displayedCount = 2;
  String searchQuery = '';
  double maxPrix = 500000000;
  bool dispoSeulement = false;
  List<String> suggestions = [];
  void reinitialiserFiltres() {
  setState(() {
    searchQuery = '';
    maxPrix = 500000000;
    dispoSeulement = false;
  });
}


  Future<void> ajouterExemples() async {
    setState(() => isLoadingExemples = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-user';

    final exemples = List.generate(10, (index) {
      final imageId = 100 + (index % 5);
      return {
        'titre': 'Bien ${index + 1}',
        'description': 'Exemple de bien ${index + 1}. Confort et accessibilité.',
        'ville': ['Dakar', 'Thiès', 'Rufisque', 'Saint-Louis', 'Ziguinchor'][index % 5],
        'prix': (index + 1) * 10000000,
        'disponible': index % 2 == 0,
        'imageUrl': 'https://picsum.photos/id/$imageId/300/150',
        'uid': uid,
        'favoris': [],
      };
    });

    final collection = FirebaseFirestore.instance.collection('biens');
    for (final bien in exemples) {
      await collection.add(bien);
      if (bien['imageUrl'] != null) {
        await precacheImage(NetworkImage(bien['imageUrl'] as String), context);
      }
    }

    setState(() => isLoadingExemples = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des biens'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            tooltip: "Ajouter des exemples",
            icon: isLoadingExemples
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: isLoadingExemples ? null : ajouterExemples,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/addBien'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 280,
              margin: const EdgeInsets.fromLTRB(0, 12, 16, 0), // aligné à droite
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
               onChanged: (value) {
                 setState(() {
                   searchQuery = value.toLowerCase();
                
                    // suggestions dynamiques selon ce que l’utilisateur tape
                   
                  });
                },

              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Recherche mots-clés...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),

                ),
              ),
              Container(
                width: 280,
                margin: const EdgeInsets.only(top: 8, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Disponible seulement"),
                        Switch(
                          value: dispoSeulement,
                          onChanged: (val) => setState(() => dispoSeulement = val),
                        ),
                      ],
                    ),
                    Text("Prix max : ${maxPrix.toInt()} FCFA"),
                    Slider(
                      min: 0,
                      max: 500000000,
                      divisions: 100,
                      value: maxPrix,
                      label: "${maxPrix.toInt()}",
                      onChanged: (val) => setState(() => maxPrix = val),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('biens').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erreur de chargement"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                suggestions = allDocs
                  .map((doc) => (doc.data() as Map<String, dynamic>)['ville'].toString())
                  .where((ville) =>
                      ville.toLowerCase().startsWith(searchQuery) &&
                      searchQuery.isNotEmpty)
                  .toSet()
                  .take(3)
                  .toList();


                final filtered = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final titre = (data['titre'] ?? '').toString().toLowerCase();
                  final ville = (data['ville'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  final prix = data['prix'] ?? 0;
                  final disponible = data['disponible'] ?? true;

                  final matchTexte = [titre, ville, desc].any((field) => field.contains(searchQuery));
                  final matchPrix = prix <= maxPrix;
                  final matchDispo = !dispoSeulement || disponible;

                  return matchTexte && matchPrix && matchDispo;
                }).toList();

                final biens = filtered.take(displayedCount).toList();


                if (biens.isEmpty) {
                  return const Center(child: Text("Aucun bien trouvé"));
                }

                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GridView.builder(
                          itemCount: biens.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final bien = biens[index];
                            final data = bien.data() as Map<String, dynamic>;
                            final favoris = List<String>.from(data['favoris'] ?? []);
                            final isFavori = currentUser != null && favoris.contains(currentUser.uid);

                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/bienDetails',
                                arguments: bien.id,
                              ),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                                              ? Image.network(
                                                  data['imageUrl'],
                                                  fit: BoxFit.cover,
                                                  cacheHeight: 150,
                                                  cacheWidth: 300,
                                                  loadingBuilder: (context, child, progress) {
                                                    return progress == null
                                                        ? child
                                                        : const Center(
                                                            child: CircularProgressIndicator(strokeWidth: 1.5),
                                                          );
                                                  },
                                                  errorBuilder: (_, __, ___) =>
                                                      Image.asset('assets/no_image.png', fit: BoxFit.cover),
                                                )
                                              : Image.asset('assets/no_image.png', fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: IconButton(
                                            icon: Icon(
                                              isFavori ? Icons.favorite : Icons.favorite_border,
                                              color: isFavori ? Colors.red : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              final uid = currentUser?.uid;
                                              if (uid == null) return;

                                              final docRef = FirebaseFirestore.instance
                                                  .collection('biens')
                                                  .doc(bien.id);

                                              final snapshot = await docRef.get();
                                              final existing = List<String>.from(snapshot.data()?['favoris'] ?? []);

                                              if (existing.contains(uid)) {
                                                existing.remove(uid);
                                              } else {
                                                existing.add(uid);
                                              }

                                              await docRef.update({'favoris': existing});
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text("${data['prix'] ?? 0} FCFA", style: const TextStyle(color: Colors.green)),
                                          const SizedBox(height: 4),
                                          Text(data['ville'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (displayedCount < filtered.length)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            displayedCount = (displayedCount + 2).clamp(0, filtered.length);
                          });
                        },
                        icon: const Icon(Icons.expand_more),
                        label: const Text("Voir plus"),
                      ),
                  ],
                );
              },
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
