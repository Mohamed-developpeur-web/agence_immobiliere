import 'dart:async'; // ✅ Nécessaire pour TimeoutException
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_footer.dart';
import '../constants/roles.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final pseudoController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = Roles.client;

  String errorMessage = '';
  bool isLoading = false;

  /// 🚀 Inscription de l'utilisateur : Auth + Firestore avec timeout et gestion d’erreurs
  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print("🔐 Création du compte Firebase en cours...");

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("✅ Auth Firebase OK : ${cred.user!.uid}");

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'email': emailController.text.trim(),
              'pseudo': pseudoController.text.trim(),
              'role': selectedRole,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 10)); // ⏱ Timeout de sécurité

        print("✅ Données Firestore enregistrées");
      } on FirebaseException catch (e) {
        print("❌ Firestore Error : ${e.code} - ${e.message}");
        setState(() => errorMessage = "Erreur Firestore : ${e.message}");
        return;
      } on TimeoutException catch (_) {
        print("⏱️ Timeout Firestore : la requête a pris trop de temps");
        setState(() => errorMessage = "Connexion à Firestore trop lente ou bloquée.");
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      String message = "Une erreur est survenue.";

      if (e.code == 'email-already-in-use') {
        message = "Cet e-mail est déjà utilisé.";
      } else if (e.code == 'invalid-email') {
        message = "Adresse e-mail invalide.";
      } else if (e.code == 'weak-password') {
        message = "Mot de passe trop faible.";
      }

      setState(() => errorMessage = message);
      print("❌ FirebaseAuthException : $message");
    } catch (e) {
      setState(() => errorMessage = "Erreur inattendue : ${e.toString()}");
      print("❌ Erreur générale : $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget champSaisi(String label, TextEditingController controller, {bool obscure = false}) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget champRole() {
    return SizedBox(
      width: 280,
      child: DropdownButtonFormField<String>(
        value: selectedRole,
        decoration: const InputDecoration(
          labelText: "Rôle",
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: Roles.client, child: Text("Client")),
          DropdownMenuItem(value: Roles.agent, child: Text("Agent immobilier")),
          DropdownMenuItem(value: Roles.admin, child: Text("Administrateur")),
        ],
        onChanged: (val) {
          if (val != null) setState(() => selectedRole = val);
        },
      ),
    );
  }

  @override
  void dispose() {
    pseudoController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte"),
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
                  children: [
                    const Text("Inscription", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    champSaisi("Pseudo", pseudoController),
                    const SizedBox(height: 16),
                    champSaisi("Email", emailController),
                    const SizedBox(height: 16),
                    champSaisi("Mot de passe", passwordController, obscure: true),
                    const SizedBox(height: 16),
                    champRole(),
                    const SizedBox(height: 24),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: registerUser,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("S'inscrire", style: TextStyle(fontSize: 16)),
                          ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text("Déjà inscrit ? Se connecter"),
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
