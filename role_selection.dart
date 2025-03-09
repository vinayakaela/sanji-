import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Role")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/login',
                arguments: "Technician",
              ),
              child: const Text("Login as Technician"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/login',
                arguments: "Admin",
              ),
              child: const Text("Login as Admin"),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/register',
                arguments: "Technician",
              ),
              child: const Text("Register as Technician"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/register',
                arguments: "Admin",
              ),
              child: const Text("Register as Admin"),
            ),
          ],
        ),
      ),
    );
  }
}