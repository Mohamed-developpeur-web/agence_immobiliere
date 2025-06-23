import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io';

import '../widgets/app_footer.dart';

class AddBienPage extends StatefulWidget {
  const AddBienPage({super.key});

  @override
  State<AddBienPage> createState() => _AddBienPageState();
}

class _AddBienPageState extends State<AddBienPage> {
  final titreController = TextEditingController();
  final descriptionController = TextEditingController();
  final villeController = TextEditingController();
  final prixController = TextEditingController();

  bool disponible = true;
  bool isLoading = false;
  String imageUrl = '';
  File? imageFile;
  Uint8List? imagePreviewData;
  String errorMessage = '';

  final picker = ImagePicker();

  Future<void> choisirImage() async {
    try {
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Téléversement de l'image...")),
      );

      final fileName = p.basename(picked.path);
      final ref = FirebaseStorage.instance.ref('biens_images/$fileName');

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        imagePreviewData = bytes;
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(picked.path);
        imageFile = file;
        imagePreviewData = await file.readAsBytes();
        await ref.putFile(file);
      }

      final url = await ref.getDownloadURL();
      setState(() => imageUrl = url);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image ajoutée ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur image : $e")),
      );
    }
  }

  Future<void> enregistrerBien() async {
    if (titreController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('biens').add({
        'titre': titreController.text.trim(),
        'description': descriptionController.text.trim(),
        'ville': villeController.text.trim(),
        'prix': int.tryParse(prixController.text.trim()) ?? 0,
        'disponible': disponible,
        'imageUrl': imageUrl,
        'uid': uid,
      });

      if (!mounted) return;
      Navigator.pushNamed(context, '/biens');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bien ajouté avec succès")),
      );
    } catch (e) {
      setState(() => errorMessage = "Erreur Firestore : $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget champ(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  void dispose() {
    titreController.dispose();
    descriptionController.dispose();
    villeController.dispose();
    prixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un bien"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    champ("Titre", titreController),
                    const SizedBox(height: 16),
                    champ("Description", descriptionController),
                    const SizedBox(height: 16),
                    champ("Ville", villeController),
                    const SizedBox(height: 16),
                    champ("Prix (FCFA)", prixController, type: TextInputType.number),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Disponible ?"),
                        Switch(
                          value: disponible,
                          onChanged: (val) => setState(() => disponible = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text("Choisir une image"),
                      onPressed: choisirImage,
                    ),
                    const SizedBox(height: 12),
                    if (imagePreviewData != null)
                      Image.memory(imagePreviewData!, height: 160, fit: BoxFit.cover),
                    const SizedBox(height: 24),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Enregistrer"),
                            onPressed: enregistrerBien,
                          ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
