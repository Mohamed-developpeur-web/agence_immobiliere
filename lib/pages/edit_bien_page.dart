import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditBienPage extends StatefulWidget {
  const EditBienPage({super.key});

  @override
  State<EditBienPage> createState() => _EditBienPageState();
}

class _EditBienPageState extends State<EditBienPage> {
  late TextEditingController titreController;
  late TextEditingController villeController;
  late TextEditingController prixController;
  late TextEditingController descriptionController;
  late TextEditingController imageUrlController;

  late String bienId;
  File? imageFile;
  bool isUploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    bienId = args['id'];
    titreController = TextEditingController(text: args['titre'] ?? '');
    villeController = TextEditingController(text: args['ville'] ?? '');
    prixController = TextEditingController(text: args['prix']?.toString() ?? '');
    descriptionController = TextEditingController(text: args['description'] ?? '');
    imageUrlController = TextEditingController(text: args['imageUrl'] ?? '');
  }

  @override
  void dispose() {
    titreController.dispose();
    villeController.dispose();
    prixController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> pickImageAndUpload() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('biens/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(File(image.path));
      final url = await uploadTask.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          imageUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Image envoyée avec succès")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur lors de l’upload : ${e.toString()}")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> enregistrerModifications() async {
    final titre = titreController.text.trim();
    final ville = villeController.text.trim();
    final prixText = prixController.text.trim();
    final description = descriptionController.text.trim();
    final imageUrl = imageUrlController.text.trim();

    if (titre.isEmpty || ville.isEmpty || prixText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Remplis tous les champs obligatoires.")),
      );
      return;
    }

    final prix = int.tryParse(prixText);
    if (prix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Prix invalide.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('biens').doc(bienId).update({
        'titre': titre,
        'ville': ville,
        'prix': prix,
        'description': description,
        'imageUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Bien mis à jour avec succès")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur lors de la mise à jour : ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le bien"),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: titreController,
              decoration: const InputDecoration(labelText: "Titre *"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: villeController,
              decoration: const InputDecoration(labelText: "Ville *"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prixController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Prix (FCFA) *"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),

            // 🔗 Champ URL image + bouton upload
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: "URL de l'image"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isUploading ? null : pickImageAndUpload,
                  icon: isUploading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.upload_file),
                ),
              ],
            ),

            // 🖼️ Prévisualisation
            if (imageUrlController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrlController.text,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Text("❌ L'image ne peut pas être chargée"),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: enregistrerModifications,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
