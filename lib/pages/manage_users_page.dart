import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/roles.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String searchText = '';

  Future<void> updateUserRole(String uid, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': newRole,
    });
  }

  Future<void> toggleUserStatus(String uid, bool currentDisabled) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'disabled': !currentDisabled,
    });
  }

  Future<bool> showConfirmDialog(BuildContext context, String pseudo) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmation'),
            content: Text('Désactiver $pseudo ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
            ],
          ),
        ) ??
        false;
  }

  void _showCreateAdminDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final pseudoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Créer un nouvel admin"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pseudoController,
                decoration: const InputDecoration(labelText: "Pseudo"),
                validator: (val) => val == null || val.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (val) => val != null && val.contains('@') ? null : "Email invalide",
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Mot de passe"),
                obscureText: true,
                validator: (val) => val != null && val.length >= 6 ? null : "6 caractères min.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );
                await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                  'pseudo': pseudoController.text.trim(),
                  'email': emailController.text.trim(),
                  'role': Roles.admin,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur : ${e.toString().replaceAll('Exception: ', '')}")),
                );
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: Colors.blueGrey,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAdminDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Nouvel Admin"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => searchText = value.toLowerCase()),
              decoration: const InputDecoration(
                hintText: '🔍 Rechercher par pseudo ou email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').orderBy('pseudo').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Expanded(child: Center(child: CircularProgressIndicator()));
              final users = snapshot.data!.docs;

              final count = {
                Roles.admin: 0,
                Roles.agent: 0,
                Roles.client: 0,
                'disabled': 0,
              };

              final filtered = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final pseudo = (data['pseudo'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return pseudo.contains(searchText) || email.contains(searchText);
              }).toList();

              for (var doc in users) {
                final data = doc.data() as Map<String, dynamic>;
                final role = data['role'];
                final disabled = data['disabled'] == true;
                if (role == Roles.admin) count[Roles.admin] = count[Roles.admin]! + 1;
                if (role == Roles.agent) count[Roles.agent] = count[Roles.agent]! + 1;
                if (role == Roles.client) count[Roles.client] = count[Roles.client]! + 1;
                if (disabled) count['disabled'] = count['disabled']! + 1;
              }

              return Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 16,
                        children: [
                          _badge("Admins", count[Roles.admin]!),
                          _badge("Agents", count[Roles.agent]!),
                          _badge("Clients", count[Roles.client]!),
                          _badge("Désactivés", count['disabled']!, color: Colors.redAccent),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final uid = doc.id;
                          final data = doc.data() as Map<String, dynamic>;
                          final pseudo = data['pseudo'] ?? '';
                          final email = data['email'] ?? '';
                          final role = data['role'] ?? '';
                          final disabled = data['disabled'] == true;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: disabled ? Colors.grey : Colors.blue,
                              child: Icon(disabled ? Icons.block : Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              pseudo,
                              style: TextStyle(
                                decoration: disabled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<String>(
                                  value: role,
                                  items: const [
                                    DropdownMenuItem(value: Roles.client, child: Text('Client')),
                                    DropdownMenuItem(value: Roles.agent, child: Text('Agent')),
                                    DropdownMenuItem(value: Roles.admin, child: Text('Admin')),
                                  ],
                                  onChanged: disabled
                                      ? null
                                      : (val) {
                                          if (val != null && val != role) {
                                            updateUserRole(uid, val);
                                          }
                                        },
                                ),
                                IconButton(
                                  tooltip: disabled ? "Réactiver" : "Désactiver",
                                  icon: Icon(
                                    disabled ? Icons.replay : Icons.power_settings_new,
                                    color: disabled ? Colors.green : Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    if (disabled) {
                                      await toggleUserStatus(uid, true);
                                    } else {
                                      final confirmed = await showConfirmDialog(context, pseudo);
                                      if (confirmed) await toggleUserStatus(uid, false);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, int value, {Color color = Colors.blueGrey}) {
    return Chip(
      label: Text('$label : $value'),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600),
    );
  }
}
