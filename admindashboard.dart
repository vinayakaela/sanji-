import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_technicianscreen.dart';
import 'edit_user_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// ✅ **Logout Function**
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          actions: [
            IconButton(icon: const Icon(Icons.notifications), onPressed: _viewNotifications),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Dashboard"),
              Tab(text: "Users"),
              Tab(text: "Technicians"),
              Tab(text: "Bookings"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDashboard(),
                  _buildUserList(),
                  _buildTechnicianList(),
                  _buildBookingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// 📊 **Dashboard Overview**
  Widget _buildDashboard() {
    return FutureBuilder(
      future: Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('technicians').get(),
        _firestore.collection('bookings').get(),
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        int totalUsers = snapshot.data![0].docs.length;
        int totalTechnicians = snapshot.data![1].docs.length;
        int totalBookings = snapshot.data![2].docs.length;

        return Column(
          children: [
            _buildDashboardCard("Total Users", totalUsers, Colors.blue),
            _buildDashboardCard("Total Technicians", totalTechnicians, Colors.green),
            _buildDashboardCard("Total Bookings", totalBookings, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard(String title, int count, Color color) {
    return Card(
      color: color,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }

  /// 🔍 **Search Bar**
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by name, email, or phone...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (query) {
          setState(() => _searchQuery = query.toLowerCase());
        },
      ),
    );
  }

  /// 🧑 **User Management (CRUD + Block/Unblock)**
  Widget _buildUserList() {
    return Column(
      children: [
        Expanded(
          child: _buildList('users', "No users found", (user, docId) {
            return ListTile(
              title: Text(user['name'] ?? "Unknown"),
              subtitle: Text("Email: ${user['email'] ?? "N/A"}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUserScreen(userId: docId, userData: user),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(docId),
                  ),
                ],
              ),
            );
          }),
        ),

        /// 🔘 **Floating Action Button to Create New User**
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            onPressed: _createUser,
            child: const Icon(Icons.add),
            tooltip: "Create New User",
          ),
        ),
      ],
    );
  }

  Future<void> _deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  /// 🔧 **Technician Management (CRUD + Block/Unblock)**
  Widget _buildTechnicianList() {
    return Column(
      children: [
        Expanded(
          child: _buildList('technicians', "No technicians found", (tech, docId) {
            bool isApproved = tech['approved'] ?? false;
            return ListTile(
              title: Text(tech['name'] ?? "Unknown"),
              subtitle: Text("Service: ${tech['serviceType'] ?? "N/A"}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTechnicianScreen(techId: docId, techData: tech),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(isApproved ? Icons.verified : Icons.check_circle, color: Colors.green),
                    onPressed: () => _approveTechnician(docId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTechnician(docId),
                  ),
                ],
              ),
            );
          }),
        ),

        /// 🔘 **Floating Action Button to Create New Technician**
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            onPressed: _createTechnician,
            child: const Icon(Icons.add),
            tooltip: "Create New Technician",
          ),
        ),
      ],
    );
  }



  Future<void> _approveTechnician(String techId) async {
    await _firestore.collection('technicians').doc(techId).update({'approved': true});
  }

  Future<void> _deleteTechnician(String techId) async {
    await _firestore.collection('technicians').doc(techId).delete();
  }

  /// 📅 **Booking Management (Change Status)**
  Widget _buildBookingList() {
    return _buildList('bookings', "No bookings found", (booking, docId) {
      return ListTile(
        title: Text("Booking ID: $docId"),
        subtitle: Text("Status: ${booking['status'] ?? "Pending"}"),
        trailing: DropdownButton<String>(
          value: booking['status'] ?? "Pending",
          items: ["Pending", "Accepted", "Completed", "Canceled"]
              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (newStatus) => _updateBookingStatus(docId, newStatus),
        ),
      );
    });
  }
  void _createUser() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
                  return;
                }

                await _firestore.collection('users').add({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'role': 'user',
                  'created_at': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Created Successfully!")));
                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }
  void _createTechnician() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController serviceTypeController = TextEditingController();
    final TextEditingController passwordTypeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Technician"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
              TextField(controller: serviceTypeController, decoration: const InputDecoration(labelText: "Service Type")),
              TextField(controller: passwordTypeController, decoration: const InputDecoration(labelText: "password")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty || serviceTypeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
                  return;
                }

                await _firestore.collection('technicians').add({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'serviceType': serviceTypeController.text.trim(),
                  'approved': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Technician Created Successfully!")));
                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String? newStatus) async {
    if (newStatus != null) {
      await _firestore.collection('bookings').doc(bookingId).update({'status': newStatus});
    }
  }

  /// **Helper Method to Create Stream List**
  Widget _buildList(String collection, String emptyMessage, Widget Function(Map<String, dynamic>, String) itemBuilder) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var items = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery);
        }).toList();

        if (items.isEmpty) return Center(child: Text(emptyMessage));

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index].data() as Map<String, dynamic>, items[index].id),
        );
      },
    );
  }

  void _viewNotifications() {}
}
