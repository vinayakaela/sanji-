import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'booking_managment.dart'; // For managing bookings (optional)
import 'booking_screen.dart'; // For user booking a technician
// These imports should match the locations of your files:
import 'homepage.dart';
import 'login.dart';
import 'register.dart';
import 'technicain/technicain_model.dart'; // Contains Technician class
import 'technician_home.dart'; // TechnicianHomePage
import 'technician_profile.dart'; // TechnicianProfileManagement

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
      home:
      const AuthCheck(), // Decides if user sees HomePage or TechnicianHomePage
      routes: {
        'register': (context) => const MyRegister(),
        'login': (context) => const MyLogin(),
        'homepage': (context) => const HomePage(),
        'technician_dashboard': (context) => const TechnicianHomePage(),
        'technician_profile': (context) => const TechnicianProfileManagement(),
        'technician_booking_management': (context) =>
        const TechnicianBookingManagementScreen(),
      },
      onGenerateRoute: (settings) {
        // If you need to pass a Technician object for booking
        if (settings.name == '/booking') {
          final technician = settings.arguments as Technician;
          return MaterialPageRoute(
            builder: (context) => BookingScreen(technicians: [technician]),
          );
        }
        return null;
      },
    );
  }
}

/// AuthCheck widget:
/// Listens to FirebaseAuth state, fetches user role,
/// and routes to TechnicianHomePage if role == 'technician',
/// otherwise goes to HomePage (user).
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<String?> _getUserRole(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.exists ? doc['role'] : null;
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If we're still loading auth state, show a spinner
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          // 2. If the user is logged in, fetch their role
          if (user != null) {
            return FutureBuilder<String?>(
              future: _getUserRole(user),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.done) {
                  // If we have a valid role, route accordingly
                  if (roleSnapshot.hasData && roleSnapshot.data != null) {
                    final role = roleSnapshot.data!;
                    return role == 'technician'
                        ? const TechnicianHomePage()
                        : const HomePage();
                  } else {
                    return const Center(child: Text('Role not found'));
                  }
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
          // 3. If user is not logged in, go to MyLogin
          return const MyLogin();
        }
        // 4. Loading indicator while waiting for auth state
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}