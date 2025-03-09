import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:technician/technicain/technicain_model.dart';

class BookingScreen extends StatefulWidget {
  final List<Technician> technicians;

  const BookingScreen({super.key, required this.technicians});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Map<String, dynamic>> availableSlots = [];
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  Map<String, bool> selectedSlots = {};
  Position? userLocation;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _fetchAvailability();
  }

  /// ✅ **Fetch User's Current Location**
  Future<void> _fetchUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      setState(() {
        userLocation = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  /// ✅ **Fetch Technician Availability including Email**
  /// ✅ **Fetch Technician Availability including Base Amount**
  void _fetchAvailability() async {
    for (var tech in widget.technicians) {
      var doc = await FirebaseFirestore.instance.collection('technicians').doc(tech.uid).get();
      if (doc.exists && doc.data() != null) {
        var technicianData = doc.data()!;
        var availabilityData = technicianData['availability'];
        var locationData = technicianData['location'];

        String technicianPhone = technicianData['phone'] ?? "Not available";
        String technicianEmail = technicianData['email'] ?? "No email";
        double baseAmount = (technicianData['baseAmount'] ?? 0).toDouble(); // ✅ Fetch Base Amount

        GeoPoint? technicianLocation;
        if (locationData != null && locationData is Map<String, dynamic>) {
          technicianLocation = GeoPoint(locationData['latitude'], locationData['longitude']);
        }

        List<Map<String, dynamic>> slots = [];
        if (availabilityData is Map) {
          slots = availabilityData.entries.map((entry) {
            final day = entry.key;
            final times = entry.value as Map<String, dynamic>;
            return {
              'day': day,
              'start': times['start'],
              'end': times['end'],
              'technicianId': tech.uid,
              'technicianName': technicianData['name'],
              'technicianAddress': technicianData['address'] ?? 'Not available',
              'technicianPhone': technicianPhone,
              'technicianEmail': technicianEmail,
              'baseAmount': baseAmount, // ✅ Added Base Amount
              'distance': technicianLocation != null ? _calculateDistance(technicianLocation) : double.infinity,
            };
          }).toList();
        }

        setState(() {
          availableSlots.addAll(slots);
          for (var slot in slots) {
            selectedSlots[slot['technicianId']] = false;
          }
        });
      }
    }
    availableSlots.sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  /// ✅ **Book Selected Slots (Now Includes Base Amount)**
  /// ✅ **Book Selected Slots (Fetches Base Amount Dynamically)**
  Future<void> _bookSlots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated. Please log in.")),
      );
      return;
    }

    String phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number.")),
      );
      return;
    }

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your address.")),
      );
      return;
    }

    bool isSlotSelected = selectedSlots.containsValue(true);
    if (!isSlotSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one slot.")),
      );
      return;
    }

    for (var slot in availableSlots) {
      if (selectedSlots[slot['technicianId']] == true) {
        double baseAmount = slot['baseAmount']; // ✅ Fetch Base Amount from Technician

        await FirebaseFirestore.instance.collection('bookings').add({
          'technicianId': slot['technicianId'],
          'userId': user.uid,
          'userEmail': user.email,
          'day': slot['day'],
          'start': slot['start'],
          'end': slot['end'],
          'address': _addressController.text,
          'phone': phone,
          'technicianName': slot['technicianName'],
          'technicianAddress': slot['technicianAddress'],
          'technicianPhone': slot['technicianPhone'],
          'technicianEmail': slot['technicianEmail'],
          'amount': baseAmount, // ✅ Fetch from Technician Profile
          'paymentStatus': 'Pending', // ✅ Default Payment Status
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Confirmed! Check your booking history.")),
    );
    Navigator.pop(context);
  }



  /// ✅ **Calculate Distance**
  double _calculateDistance(GeoPoint techLocation) {
    if (userLocation == null) return double.infinity;
    return Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      techLocation.latitude,
      techLocation.longitude,
    ) / 1000;
  }



  /// ✅ **Function to Call Technician**
  void _callTechnician(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  /// ✅ **Updated UI with Call Feature & Email**
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Technicians")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: "Enter your address"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    hintText: "Enter your phone number",
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                var slot = availableSlots[index];
                return Card(
                  child: CheckboxListTile(
                    title: Text("${slot['day']}: ${slot['start']} - ${slot['end']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Technician: ${slot['technicianName']}"),
                        Text("Address: ${slot['technicianAddress']}"),
                        Text("Phone: ${slot['technicianPhone']}"),
                        Text("Email: ${slot['technicianEmail']}"),
                        Text("Base Amount: ₹${slot['baseAmount']}"), // ✅ Show Base Amount
                      ],
                    ),
                    value: selectedSlots[slot['technicianId']],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedSlots[slot['technicianId']] = value ?? false;
                      });
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () {
                        _callTechnician(slot['technicianPhone']);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _bookSlots,
              child: const Text("Confirm Booking"),
            ),
          ),
        ],
      ),
    );
  }
}
