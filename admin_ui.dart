import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? serviceType,
    String? description,
    int? experienceYears,
  }) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (role == "technician") {
        await _firestore.collection('technicians').doc(uid).set({
          'uid': uid,
          'name': name.trim(),
          'email': email.trim(),
          'serviceType': serviceType ?? '',
          'description': description ?? '',
          'experienceYears': experienceYears ?? 0,
          'rating': 0.0,
          'approved': false, // Set to true if admin approval is not required
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message if signup fails
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final userRole = userDoc['role'] ?? 'customer';

      // Check if technician is approved (if applicable)
      if (userRole == 'technician') {
        DocumentSnapshot technicianDoc = await _firestore
            .collection('technicians')
            .doc(userCredential.user!.uid)
            .get();
        if (!(technicianDoc['approved'] ?? false)) {
          return "Technician account not approved yet";
        }
      }

      return userRole;
    } catch (e) {
      return e.toString();
    }
  }

  // for user log out
  signOut() async {
    _auth.signOut();
  }
}