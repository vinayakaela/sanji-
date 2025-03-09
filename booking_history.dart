import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  String? userId;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchUserRole();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => userId = null);
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        userId = user.uid;
        userRole = userDoc['role'];
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      String bookingId = response.orderId ?? "N/A";
      if (bookingId == "N/A") return;

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Completed',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful! Booking Completed.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating booking: $e")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Used: ${response.walletName}")),
    );
  }

  void _openPaymentPortal(Map<String, dynamic> bookingData, String bookingId) {
    var options = {
      'key': 'rzp_test_LXZO1v4DgjDFKy',
      'amount': (bookingData['amount'] * 100).toInt(),
      'currency': 'INR',
      'name': 'Technician Service',
      'description': 'Booking Payment',
      'prefill': {
        'email': FirebaseAuth.instance.currentUser?.email,
        'contact': bookingData['phone'],
      },
      'notes': {'bookingId': bookingId},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where(userRole == 'technician' ? 'technicianId' : 'userId', isEqualTo: userId)
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
            return const Center(child: Text("No booking history found"));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              bool showPayButton =
                  userRole != 'technician' &&
                      data['status'] == 'Accepted';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    title: Text("Booking on ${data['day']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text("Status: ${data['status']}",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _getStatusColor(data['status']))),
                        const SizedBox(height: 4),
                        Text("User: ${data['userEmail'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                        Text("Address: ${data['address'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                        Text("Phone: ${data['phone'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                        if (userRole == 'technician')
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text("Assigned to You ✅", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                      ],
                    ),
                    trailing: showPayButton
                        ? ElevatedButton(
                      onPressed: () => _openPaymentPortal(data, doc.id),
                      child: const Text('Pay Now'),
                    )
                        : null,
                    onTap: () {
                      // Navigate to booking details screen
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
