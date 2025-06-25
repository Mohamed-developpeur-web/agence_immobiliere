import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  Future<void> _pickImageAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final originalFile = File(picked.path);
    final originalSize = await originalFile.length();

    // Compression si l'image dépasse 1 Mo
    if (originalSize > 1024 * 1024) {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );

      final File? compressed = compressedFile as File?;
      _imageFile = compressed ?? originalFile;

    } else {
      _imageFile = originalFile;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final fileName = path.basename(_imageFile!.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images/${user!.uid}/$fileName');

    final uploadTask = storageRef.putFile(_imageFile!);

    uploadTask.snapshotEvents.listen((event) {
      setState(() {
        _uploadProgress = event.bytesTransferred /
            event.totalBytes.clamp(1, double.infinity);
      });
    });

    try {
      await uploadTask;
      final downloadURL = await storageRef.getDownloadURL();
      await user?.updatePhotoURL(downloadURL);
      await user?.reload();

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📷 Photo compressée et téléversée ✅")),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

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

      await user?.reload();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Aucun utilisateur connecté")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎨 Bannière avec Avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: CircleAvatar(
                      key: ValueKey(user!.photoURL ?? 'default'),
                      radius: 40,
                      backgroundImage: user!.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(user!.displayName ?? "Nom",
                      style: const TextStyle(
                          fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(user!.email ?? "Email",
                      style: const TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: _pickImageAndUpload,
                    child: const Text("Changer la photo",
                        style: TextStyle(color: Colors.white)),
                  ),
                  if (_isUploading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: LinearProgressIndicator(value: _uploadProgress),
                    ),
                ],
              ),
            ),

            // 📝 Formulaire
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email requis';
                        }
                        final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$');
                        if (!regex.hasMatch(value)) {
                          return 'Format email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _updateUserProfile,
                      icon: const Icon(Icons.save),
                      label: const Text("Mettre à jour"),
                    ),
                    const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}
