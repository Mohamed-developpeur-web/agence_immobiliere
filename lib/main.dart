import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/biens_list_page.dart';
import 'pages/bien_details_page.dart';
import 'pages/add_bien_page.dart';
import 'pages/edit_bien_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = FirebaseAuth.instance.currentUser;
  runApp(MonApp(isLoggedIn: user != null));
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
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/biens': (context) => const BiensListPage(),
        '/bienDetails': (context) => const BienDetailsPage(),
        '/addBien': (context) => const AddBienPage(),
        '/editBien': (context) => const EditBienPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
