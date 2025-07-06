import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// 🔧 Configuration Firebase
import 'firebase_options.dart';

// 🔄 Gestion utilisateur
import 'providers/user_provider.dart';

// 🔐 Constantes de rôles
import 'constants/roles.dart';

// 🛡️ Sécurisation par rôle
import 'widgets/role_guard.dart';

// 📃 Pages générales
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';

// 🏘 Pages gestion des biens
import 'pages/biens_list_page.dart';
import 'pages/bien_details_page.dart';
import 'pages/add_bien_page.dart';
import 'pages/edit_bien_page.dart';

// 🧑‍💼 Dashboards personnalisés
import 'pages/admin_dashboard.dart';
import 'pages/agent_dashboard.dart';
import 'pages/client_dashboard.dart';

// 👥 Utilisateurs et clients
import 'pages/manage_users_page.dart';
import 'pages/clients_page.dart';

// 📅 Visites, contrats, demandes, rapports
import 'pages/visites_page.dart';
import 'pages/contrats_page.dart';
import 'pages/demandes_page.dart';
import 'pages/rapports_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = FirebaseAuth.instance.currentUser;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MonApp(isLoggedIn: user != null),
    ),
  );
}

class MonApp extends StatelessWidget {
  final bool isLoggedIn;
  const MonApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agence Immobilière',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      routes: {
        // 🔐 Auth & accueil
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),

        // 🎯 Dashboards selon rôle
        '/adminDashboard': (context) => const RoleGuard(
              allowedRoles: [Roles.admin],
              page: AdminDashboard(),
            ),
        '/agentDashboard': (context) => const RoleGuard(
              allowedRoles: [Roles.agent],
              page: AgentDashboard(),
            ),
        '/clientDashboard': (context) => const RoleGuard(
              allowedRoles: [Roles.client],
              page: ClientDashboard(),
            ),

        // 🏠 Biens
        '/biens': (context) => const BiensListPage(),
        '/bienDetails': (context) => const BienDetailsPage(),
        '/addBien': (context) => const RoleGuard(
              allowedRoles: [Roles.agent, Roles.admin],
              page: AddBienPage(),
            ),
        '/editBien': (context) => const RoleGuard(
              allowedRoles: [Roles.agent, Roles.admin], // ✅ MAJ ici
              page: EditBienPage(),
            ),

        // 👤 Profil
        '/profile': (context) => const ProfilePage(),

        // 👥 Utilisateurs / Clients
        '/manageUsers': (context) => const RoleGuard(
              allowedRoles: [Roles.admin],
              page: ManageUsersPage(),
            ),
        '/clients': (context) => const RoleGuard(
              allowedRoles: [Roles.agent, Roles.admin],
              page: ClientsPage(),
            ),

        // 📄 Contrats / rapports / visites / demandes
        '/contrats': (context) => const RoleGuard(
              allowedRoles: [Roles.agent, Roles.admin],
              page: ContratsPage(),
            ),
        '/rapports': (context) => const RoleGuard(
              allowedRoles: [Roles.admin],
              page: RapportsPage(),
            ),
        '/visites': (context) => const VisitesPage(),
        '/demandes': (context) => const RoleGuard(
              allowedRoles: [Roles.client],
              page: DemandesPage(),
            ),
      },
    );
  }
}
