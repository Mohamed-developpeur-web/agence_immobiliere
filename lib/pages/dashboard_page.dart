import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../providers/user_provider.dart';
import '../models/user_app.dart';
import '../constants/roles.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Provider.of<UserProvider>(context, listen: false).clearUser();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    final cards = <Widget>[
      if (user?.role == Roles.client || user?.role == Roles.agent || user?.role == Roles.admin)
        _dashboardCard(
          icon: Icons.list_alt,
          label: 'Voir les biens',
          color: Colors.indigo,
          onTap: () => Navigator.pushNamed(context, '/biens'),
        ),
      if (user?.role == Roles.client)
        _dashboardCard(
          icon: Icons.calendar_today,
          label: 'Planifier une visite',
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/visites'),
        ),
      if (user?.role == Roles.client)
        _dashboardCard(
          icon: Icons.request_page,
          label: 'Mes demandes',
          color: Colors.deepOrange,
          onTap: () => Navigator.pushNamed(context, '/demandes'),
        ),
      _dashboardCard(
        icon: Icons.person,
        label: 'Mon Profil',
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/profile'),
      ),
      if (user?.role == Roles.agent || user?.role == Roles.admin)
        _dashboardCard(
          icon: Icons.add_home,
          label: 'Ajouter un bien',
          color: Colors.teal,
          onTap: () => Navigator.pushNamed(context, '/addBien'),
        ),
      if (user?.role == Roles.agent || user?.role == Roles.admin)
        _dashboardCard(
          icon: Icons.people,
          label: 'Clients',
          color: Colors.brown,
          onTap: () => Navigator.pushNamed(context, '/clients'),
        ),
      if (user?.role == Roles.agent || user?.role == Roles.admin)
        _dashboardCard(
          icon: Icons.description,
          label: 'Contrats',
          color: Colors.indigo.shade400,
          onTap: () => Navigator.pushNamed(context, '/contrats'),
        ),
      if (user?.role == Roles.admin)
        _dashboardCard(
          icon: Icons.manage_accounts,
          label: 'Gérer utilisateurs',
          color: Colors.deepPurple,
          onTap: () => Navigator.pushNamed(context, '/manageUsers'),
        ),
      if (user?.role == Roles.admin)
        _dashboardCard(
          icon: Icons.analytics_outlined,
          label: 'Rapports',
          color: Colors.pink.shade400,
          onTap: () => Navigator.pushNamed(context, '/rapports'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize),
            const SizedBox(width: 8),
            Expanded(child: Text('Bienvenue, ${user?.pseudo ?? 'Utilisateur'}')),
            if (user != null)
              Chip(
                label: Text(user.role),
                labelStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.blueGrey.shade700,
              ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: cards,
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
