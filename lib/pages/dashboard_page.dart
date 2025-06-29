import 'package:flutter/material.dart';
import '../widgets/app_footer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _dashboardCard(
                    icon: Icons.list_alt,
                    label: 'Voir les biens',
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(context, '/biens'),
                  ),
                  _dashboardCard(
                    icon: Icons.add_home,
                    label: 'Ajouter un bien',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/addBien'),
                  ),
                  _dashboardCard(
                    icon: Icons.person,
                    label: 'Mon Profil',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
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
