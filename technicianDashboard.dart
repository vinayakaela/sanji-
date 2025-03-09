import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_managment.dart'; // Import the new screen
import 'technician_profile.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _technicianId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getTechnicianId();
  }

  Future<void> _getTechnicianId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _technicianId = user.uid;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking status updated to $status")),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Technician Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TechnicianProfileManagement()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Button to navigate to the booking management screen
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TechnicianBookingManagementScreen(),
                        ),
                      );
                    },
                    child: const Text("Manage Bookings"),
                  ),
                ),
                // Existing booking list (if needed)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('bookings')
                        .where('technicianId', isEqualTo: _technicianId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final bookings = snapshot.data?.docs ?? [];
                      if (bookings.isEmpty) {
                        return const Center(
                            child: Text("No bookings available"));
                      }
                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final bookingData =
                              booking.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              title: Text(
                                "Booking for ${bookingData['serviceType']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Date: ${bookingData['date']}"),
                                  Text("Status: ${bookingData['status']}"),
                                ],
                              ),
                              trailing: DropdownButton<String>(
                                value: bookingData['status'],
                                items: [
                                  'pending',
                                  'accepted',
                                  'completed',
                                  'rejected'
                                ].map((String status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    _updateBookingStatus(booking.id, newStatus);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
