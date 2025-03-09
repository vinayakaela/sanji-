import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'booking_history.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'package:technician/technicain/technicain_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GeoPoint? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _userLocation = GeoPoint(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Stream<QuerySnapshot> get techniciansStream {
    Query query = FirebaseFirestore.instance
        .collection('technicians')
        .where('approved', isEqualTo: true);

    if (_searchQuery.isNotEmpty) {
      query = query.where('serviceType', isEqualTo: _searchQuery);
    }
    return query.snapshots();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  void _navigateToBookingScreen(Technician technician) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(technicians: [technician]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Technician', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              } else if (value == 'bookings') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingHistoryScreen()));
              } else if (value == 'location') {
                _fetchCurrentLocation();
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(value: 'profile', child: Text('Manage Profile')),
              const PopupMenuItem<String>(value: 'bookings', child: Text('View Booking History')),
              const PopupMenuItem<String>(value: 'location', child: Text('Update My Location')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by service type...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
                ),
                onChanged: (text) => setState(() => _searchQuery = text),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: techniciansStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final technicians = snapshot.data?.docs.map((doc) {
                    return Technician.fromJson(doc.data() as Map<String, dynamic>);
                  }).toList() ?? [];

                  if (technicians.isEmpty) {
                    return const Center(child: Text('No technicians found'));
                  }

                  return ListView.builder(
                    itemCount: technicians.length,
                    itemBuilder: (context, index) {
                      final technician = technicians[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 5,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              technician.photoUrl ?? 'https://www.w3schools.com/howto/img_avatar.png',
                            ),
                            radius: 30,
                          ),
                          title: Text(technician.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Service: ${technician.serviceType}"),
                              Text("Experience: ${technician.experienceYears} years"),
                              if (_userLocation != null && technician.location != null)
                                FutureBuilder<double?>(
                                  future: _calculateDistance(_userLocation, technician.location),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox();
                                    return Text("Distance: ${snapshot.data!.toStringAsFixed(2)} km");
                                  },
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _navigateToBookingScreen(technician),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _calculateDistance(GeoPoint? userLocation, GeoPoint? techLocation) async {
    if (userLocation == null || techLocation == null) return null;
    return Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      techLocation.latitude,
      techLocation.longitude,
    ) / 1000;
  }
}
