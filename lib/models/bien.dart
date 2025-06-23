class Bien {
  final String id;
  final String titre;
  final String description;
  final String ville;
  final int prix;
  final bool disponible;

  Bien({
    required this.id,
    required this.titre,
    required this.description,
    required this.ville,
    required this.prix,
    required this.disponible,
  });

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'ville': ville,
      'prix': prix,
      'disponible': disponible,
    };
  }

  factory Bien.fromMap(String id, Map<String, dynamic> data) {
    return Bien(
      id: id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      ville: data['ville'] ?? '',
      prix: data['prix'] ?? 0,
      disponible: data['disponible'] ?? false,
    );
  }
}
