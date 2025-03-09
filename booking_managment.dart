import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TechnicianBookingManagementScreen extends StatefulWidget {
  const TechnicianBookingManagementScreen({Key? key}) : super(key: key);

  @override
  _TechnicianBookingManagementScreenState createState() =>
      _TechnicianBookingManagementScreenState();
}

class _TechnicianBookingManagementScreenState
    extends State<TechnicianBookingManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String technicianId;

  @override
  void initState() {
    super.initState();
    technicianId = _auth.currentUser?.uid ?? "";
  }

  void _callUser(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $url")),
      );
    }
  }

  /// ✅ **Fetch Technician's Base Amount**
  Future<double> _fetchTechnicianBaseAmount() async {
    var doc = await _firestore.collection('technicians').doc(technicianId).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data()!['baseAmount'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0; // Default value if baseAmount is missing
  }

  /// ✅ **Update Booking Status and Assign Base Amount**
  Future<void> _updateBookingStatus(String bookingId, String status) async {
    double baseAmount = 0.0;

    // If the technician accepts the booking, fetch and update the base amount
    if (status == "Accepted") {
      baseAmount = await _fetchTechnicianBaseAmount();
    }

    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
      if (status == "Accepted") 'amount': baseAmount, // Assign base amount when accepted
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'accepted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Bookings",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('technicianId', isEqualTo: technicianId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          final bookings = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var bookingData = bookings[index].data() as Map<String, dynamic>;
              String bookingId = bookings[index].id;
              String status = bookingData['status'] ?? 'Pending';
              String userPhone = bookingData['phone'] ?? 'N/A';
              double amount = (bookingData['amount'] as num?)?.toDouble() ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Booking on ${bookingData['day']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text("Status: $status",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status))),
                      Text("User Phone: $userPhone",
                          style: const TextStyle(fontSize: 14)),
                      Text("Address: ${bookingData['address']}",
                          style: const TextStyle(fontSize: 14)),
                      Text("Amount: ₹$amount",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              if (userPhone != 'N/A') {
                                _callUser(userPhone);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text("No phone number available")),
                                );
                              }
                            },
                          ),
                          if (status == "Pending") ...[
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () =>
                                  _updateBookingStatus(bookingId, "Accepted"),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  _updateBookingStatus(bookingId, "Rejected"),
                            ),
                          ],
                          if (status == "Accepted")
                            IconButton(
                              icon: const Icon(Icons.done_all, color: Colors.blue),
                              onPressed: () =>
                                  _updateBookingStatus(bookingId, "Completed"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
