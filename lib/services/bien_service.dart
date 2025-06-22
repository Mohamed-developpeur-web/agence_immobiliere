import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bien.dart';

class BienService {
  final CollectionReference _biens = FirebaseFirestore.instance.collection('biens');

  Future<String?> ajouterBien(Bien bien) async {
    try {
      await _biens.add(bien.toMap());
      return null; // ✅ Pas d'erreur
    } catch (e) {
      return 'Erreur lors de l\'ajout : $e';
    }
  }

  Stream<List<Bien>> getBiens() {
    return _biens.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bien.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<String?> supprimerBien(String id) async {
    try {
      await _biens.doc(id).delete();
      return null;
    } catch (e) {
      return 'Erreur lors de la suppression : $e';
    }
  }

  Future<String?> modifierBien(Bien bien) async {
    try {
      await _biens.doc(bien.id).update(bien.toMap());
      return null;
    } catch (e) {
      return 'Erreur lors de la modification : $e';
    }
  }
}
