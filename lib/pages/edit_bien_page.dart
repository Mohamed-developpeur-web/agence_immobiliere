import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'dart:typed_data';

import '../widgets/app_footer.dart';

class EditBienPage extends StatefulWidget {
  const EditBienPage({super.key});

  @override
  State<EditBienPage> createState() => _EditBienPageState();
}

class _EditBienPageState extends State<EditBienPage> {
  final titreController = TextEditingController();
  final descriptionController = TextEditingController();
  final villeController = TextEditingController();
  final prixController = TextEditingController();
  final imageUrlController = TextEditingController();

  bool disponible = true;
  bool isLoading = false;
  String? bienId;
  Uint8List? imagePreviewData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments;
    if (id != null && id is String) {
      bienId = id;
      FirebaseFirestore.instance.collection('biens').doc(id).get().then((doc) {
        if (!doc.exists) return;

        final data = doc.data()!;
        titreController.text = data['titre'] ?? '';
        descriptionController.text = data['description'] ?? '';
        villeController.text = data['ville'] ?? '';
        prixController.text = (data['prix'] ?? '').toString();
        imageUrlController.text = data['imageUrl'] ?? '';
        disponible = data['disponible'] ?? true;
        setState(() {});
      });
    }
  }

  Future<void> choisirImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final fileName = p.basename(picked.path);
      final ref = FirebaseStorage.instance.ref('biens_images/$fileName');

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 600,
          minHeight: 600,
          quality: 60,
        );
        imagePreviewData = Uint8List.fromList(compressed);
        await ref.putData(imagePreviewData!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(picked.path);
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.path,
          '${file.parent.path}/compressed_$fileName',
          quality: 60,
        );
        imagePreviewData = await compressedFile!.readAsBytes();
        await ref.putFile(File(compressedFile.path)); // ✅ Correction ici
      }

      final url = await ref.getDownloadURL();
      setState(() => imageUrlController.text = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur image : $e")),
      );
    }
  }

  Future<void> modifierBien() async {
    if (bienId == null) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('biens').doc(bienId).update({
        'titre': titreController.text.trim(),
        'description': descriptionController.text.trim(),
        'ville': villeController.text.trim(),
        'prix': int.tryParse(prixController.text.trim()) ?? 0,
        'imageUrl': imageUrlController.text.trim(),
        'disponible': disponible,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bien modifié avec succès")),
      );
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
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Modifier un bien"),
      centerTitle: true,
      backgroundColor: Colors.blueGrey,
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
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
                            ElevatedButton.icon(
                              icon: const Icon(Icons.photo_camera),
                              label: const Text("Changer l'image"),
                              onPressed: choisirImage,
                            ),
                            const SizedBox(height: 12),
                            if (imagePreviewData != null)
                              Image.memory(imagePreviewData!, height: 160, fit: BoxFit.cover)
                            else if (imageUrlController.text.isNotEmpty)
                              Image.network(imageUrlController.text, height: 160, fit: BoxFit.cover),
                            const SizedBox(height: 16),
                            champ("Image URL", imageUrlController),
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
                            const SizedBox(height: 24),
                            isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: const Text("Enregistrer"),
                                    onPressed: modifierBien,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(child: AppFooter()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}