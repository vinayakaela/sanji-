import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TechnicianProfileManagement extends StatefulWidget {
  const TechnicianProfileManagement({Key? key}) : super(key: key);

  @override
  State<TechnicianProfileManagement> createState() =>
      _TechnicianProfileManagementState();
}

class _TechnicianProfileManagementState
    extends State<TechnicianProfileManagement> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _baseAmountController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  GeoPoint? _technicianLocation;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("❌ No user logged in!");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();

      if (!technicianDoc.exists) {
        debugPrint("❌ Technician profile not found in Firestore!");
        setState(() => _isLoading = false);
        return;
      }

      final data = technicianDoc.data();
      debugPrint("✅ Technician profile loaded: $data");

      String phoneNumber = (data?['phone'] as String?) ?? "";

      setState(() {
        _nameController.text = data?['name'] ?? '';
        _emailController.text = data?['email'] ?? '';
        _serviceTypeController.text = data?['serviceType'] ?? '';
        _addressController.text = data?['address'] ?? '';
        _phoneController.text = phoneNumber;
        _baseAmountController.text = data?['baseAmount']?.toString() ?? '';
        _upiIdController.text = data?['upiId'] ?? '';

        if (data?['location'] != null && data?['location'] is Map<String, dynamic>) {
          Map<String, dynamic> locationMap = data?['location'];
          _technicianLocation = GeoPoint(
            (locationMap['latitude'] as num?)?.toDouble() ?? 0.0,
            (locationMap['longitude'] as num?)?.toDouble() ?? 0.0,
          );
        }

        _isLoading = false;
      });

      debugPrint("✅ Profile data loaded successfully!");
    } catch (e) {
      debugPrint("🔥 Error loading profile: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _technicianLocation = GeoPoint(position.latitude, position.longitude);
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Location Updated: ${position.latitude}, ${position.longitude}"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('technicians').doc(user.uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'serviceType': _serviceTypeController.text,
        'address': _addressController.text,
        'phone': _phoneController.text.trim(),
        'baseAmount': double.tryParse(_baseAmountController.text) ?? 0.0,
        'upiId': _upiIdController.text.trim(),
        'location': {
          'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        },
      });
    }
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
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
        title: const Text('Technician Profile'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: _serviceTypeController, decoration: const InputDecoration(labelText: "Service Type")),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Full Address")),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
              TextField(controller: _latitudeController, decoration: const InputDecoration(labelText: "Latitude"), keyboardType: TextInputType.number),
              TextField(controller: _longitudeController, decoration: const InputDecoration(labelText: "Longitude"), keyboardType: TextInputType.number),
              TextField(controller: _baseAmountController, decoration: const InputDecoration(labelText: "Base Service Amount (₹)"), keyboardType: TextInputType.number),
              TextField(controller: _upiIdController, decoration: const InputDecoration(labelText: "UPI ID")),
              ElevatedButton(onPressed: _fetchCurrentLocation, child: const Text("Use Current Location")),
              _isSaving ? const CircularProgressIndicator() : ElevatedButton(onPressed: _updateProfile, child: const Text("Save Changes")),
            ],
          ),
        ),
      ),
    );
  }
}
