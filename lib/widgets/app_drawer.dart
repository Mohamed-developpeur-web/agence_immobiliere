import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.pseudo ?? ''),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40),
            ),
            decoration: const BoxDecoration(color: Colors.blueGrey),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Tableau de bord"),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profil"),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Déconnexion"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Provider.of<UserProvider>(context, listen: false).clearUser();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
