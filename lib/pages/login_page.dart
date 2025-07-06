import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../widgets/app_footer.dart';
import '../providers/user_provider.dart';
import '../constants/roles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser(uid);
      final role = userProvider.role;

      if (role == null) {
        throw Exception("Aucun rôle défini pour cet utilisateur.");
      }

      switch (role) {
        case Roles.admin:
          Navigator.pushReplacementNamed(context, '/adminDashboard');
          break;
        case Roles.agent:
          Navigator.pushReplacementNamed(context, '/agentDashboard');
          break;
        case Roles.client:
          Navigator.pushReplacementNamed(context, '/clientDashboard');
          break;
        default:
          throw Exception("Rôle inconnu : $role");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMessage = "Aucun utilisateur trouvé avec cet e-mail.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Mot de passe incorrect.";
      } else {
        errorMessage = "Erreur Auth : ${e.message}";
      }
    } catch (e) {
      errorMessage = "Erreur : ${e.toString().replaceAll('Exception: ', '')}";
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => errorMessage = "Veuillez saisir votre e-mail pour réinitialiser.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✉️ Email de réinitialisation envoyé à $email")),
        );
      }
    } catch (e) {
      setState(() => errorMessage = "Erreur réinitialisation : ${e.toString()}");
    }
  }

  Widget champSaisi(String label, TextEditingController controller, {bool isPassword = false}) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                )
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connexion"),
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
                    const Text("Connexion", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    champSaisi("Email", emailController),
                    const SizedBox(height: 16),
                    champSaisi("Mot de passe", passwordController, isPassword: true),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: resetPassword,
                      icon: const Icon(Icons.lock_reset, size: 20),
                      label: const Text("Mot de passe oublié ?"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueGrey.shade700,
                        textStyle: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: loginUser,
                            icon: const Icon(Icons.login),
                            label: const Text("Se connecter", style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                      child: const Text("Pas encore de compte ? S'inscrire"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppFooter(),
          ),
        ],
      ),
    );
  }
}
