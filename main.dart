import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'admindashboard.dart';
import 'homepage.dart';
import 'login.dart';
import 'register.dart';
import 'technician_home.dart';
import 'technician_profile.dart';
import 'admin_ui.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(),
      routes: {
        'register': (context) => const MyRegister(),
        'login': (context) => const MyLogin(),
        'homepage': (context) => const HomePage(),
        'technician_dashboard': (context) => const TechnicianHomePage(),
        'technician_profile': (context) => const TechnicianProfileManagement(),
        'admin_dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Future<String?> _getUserRole(User user) async {
    for (int i = 0; i < 3; i++) { // 🔄 Retry 3 times
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return doc['role'];
        }
        await Future.delayed(const Duration(seconds: 2)); // ⏳ Wait before retrying
      } catch (e) {
        debugPrint("Error fetching user role: $e");
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            return FutureBuilder<String?>(
              future: _getUserRole(user),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.done) {
                  if (roleSnapshot.hasData && roleSnapshot.data != null) {
                    final role = roleSnapshot.data!;
                    if (role == 'admin') {
                      return const AdminDashboard();
                    } else if (role == 'technician') {
                      return const TechnicianHomePage();
                    } else {
                      return const HomePage();
                    }
                  } else {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Role not found. Please log in again."),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyLogin()),
                                );
                              },
                              child: const Text("Sign Out & Retry"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
          return const MyLogin();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

