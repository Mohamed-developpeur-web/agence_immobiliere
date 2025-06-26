import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../widgets/app_footer.dart'; // ✅ Assure-toi que ce widget existe

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _imageFile;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Initialise les champs avec les infos actuelles de l’utilisateur
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  /// Réinitialise la photo de profil et supprime l’image existante dans Firebase Storage si applicable
  Future<void> _resetPhoto() async {
    try {
      final previousPhoto = user?.photoURL;
      await user?.updatePhotoURL(null);
      await user?.reload();
      setState(() {});
      if (previousPhoto != null && previousPhoto.contains('firebase')) {
        final ref = FirebaseStorage.instance.refFromURL(previousPhoto);
        await ref.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo réinitialisée ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  /// Ouvre la galerie, compresse et envoie l’image sélectionnée sur Firebase Storage
  Future<void> _pickImageAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File originalFile = File(picked.path);
    final originalSize = await originalFile.length();

    if (!kIsWeb && originalSize > 1024 * 1024) {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );
      if (compressed != null) {
        originalFile = File(compressed.path);
      }
    }

    _imageFile = originalFile;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final previousUrl = user?.photoURL;
    if (previousUrl != null && previousUrl.contains('firebase')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(previousUrl);
        await ref.delete();
      } catch (_) {}
    }

    final fileName = path.basename(_imageFile!.path);
    final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}/$fileName');
    final uploadTask = storageRef.putFile(_imageFile!);

    uploadTask.snapshotEvents.listen((event) {
      setState(() {
        _uploadProgress = event.bytesTransferred / event.totalBytes.clamp(1, double.infinity);
      });
    });

    try {
      await uploadTask;
      final downloadURL = await storageRef.getDownloadURL();
      await user?.updatePhotoURL(downloadURL);
      await user?.reload();
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'photoURL': downloadURL,
      }, SetOptions(merge: true));

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📷 Photo mise à jour ✅")),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d’upload : $e")),
      );
    }
  }

  /// Met à jour le nom et l’email de l’utilisateur dans Firebase Auth + Firestore
  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await user?.updateDisplayName(_nameController.text);
      if (_emailController.text != user?.email) {
        await user?.verifyBeforeUpdateEmail(_emailController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email mis à jour. Vérifie ta boîte mail 📧")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour ✅")),
        );
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      }, SetOptions(merge: true));

      await user?.reload();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  /// Champ stylisé comme dans ta page AddBien
  Widget champ(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return SizedBox(
      width: 280,
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label est requis';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Aucun utilisateur connecté")),
        bottomNavigationBar: AppFooter(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: user!.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _pickImageAndUpload,
                        icon: const Icon(Icons.photo),
                        label: const Text("Changer la photo"),
                      ),
                      TextButton(
                        onPressed: _resetPhoto,
                        child: const Text("Réinitialiser la photo"),
                      ),
                      if (_isUploading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(value: _uploadProgress),
                        ),
                      const SizedBox(height: 20),
                      champ("Nom", _nameController),
                      const SizedBox(height: 16),
                      champ("Email", _emailController, type: TextInputType.emailAddress),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Mettre à jour"),
                        onPressed: _updateUserProfile,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text("Se déconnecter"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(), // 🦶 Pied de page cohérent
        ],
      ),
    );
  }
}
