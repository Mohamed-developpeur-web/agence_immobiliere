import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_footer.dart';
import '../providers/user_provider.dart';

class AgentDashboard extends StatelessWidget {
  const AgentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dashboard_customize),
            const SizedBox(width: 8),
            Text('Agent — ${user?.pseudo ?? "Bienvenue"}'),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),
          Text(
            'Bienvenue ${user?.pseudo ?? "utilisateur"} 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: isWideScreen ? 3 : 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _card(context, Icons.list_alt, 'Voir les biens', '/biens', Colors.teal),
                  _card(context, Icons.add_home, 'Ajouter un bien', '/addBien', Colors.indigo),
                  _card(context, Icons.people, 'Clients', '/clients', Colors.brown),
                  _card(context, Icons.description, 'Contrats', '/contrats', Colors.deepOrange),
                  _card(context, Icons.person, 'Mon Profil', '/profile', Colors.blueGrey),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String label, String route, Color color) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
