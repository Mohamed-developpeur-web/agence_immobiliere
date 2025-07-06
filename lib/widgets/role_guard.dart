import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget page;

  const RoleGuard({super.key, required this.allowedRoles, required this.page});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.role;

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (allowedRoles.contains(role)) {
      return page;
    }

    // 🔁 Redirection douce vers le dashboard
    Future.microtask(() {
      Navigator.pushReplacementNamed(context, '/dashboard');
    });

    return const Scaffold(
      body: Center(child: Text("⛔️ Accès refusé")),
    );
  }
}
