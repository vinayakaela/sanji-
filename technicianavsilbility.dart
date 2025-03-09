import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechnicianAvailabilityScreen extends StatefulWidget {
  const TechnicianAvailabilityScreen({super.key});

  @override
  _TechnicianAvailabilityScreenState createState() =>
      _TechnicianAvailabilityScreenState();
}

class _TechnicianAvailabilityScreenState
    extends State<TechnicianAvailabilityScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of days for which availability is set
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Maps to store the selected start and end times for each day
  final Map<String, TimeOfDay?> _startTimes = {};
  final Map<String, TimeOfDay?> _endTimes = {};

  @override
  void initState() {
    super.initState();
    // Initialize start and end times as null for each day.
    for (var day in _days) {
      _startTimes[day] = null;
      _endTimes[day] = null;
    }
  }

  /// Show a time picker and update the corresponding map.
  Future<void> _selectTime(
      BuildContext context, String day, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTimes[day] = picked;
        } else {
          _endTimes[day] = picked;
        }
      });
    }
  }

  /// Save the availability to Firestore.
  Future<void> _saveAvailability() async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    // Build a Map for availability: day -> {start: 'time', end: 'time'}
    Map<String, dynamic> availability = {};
    for (var day in _days) {
      if (_startTimes[day] != null && _endTimes[day] != null) {
        availability[day] = {
          'start': _startTimes[day]!.format(context),
          'end': _endTimes[day]!.format(context),
        };
      }
    }

    try {
      await _firestore
          .collection('technicians')
          .doc(user.uid)
          .update({'availability': availability});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Availability Updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating availability: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Your Availability")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // List of days with time pickers for start and end times
            Expanded(
              child: ListView.builder(
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  String day = _days[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(day),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display and select start time
                          Text(_startTimes[day]?.format(context) ?? 'Start Time'),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context, day, true),
                          ),
                          // Display and select end time
                          Text(_endTimes[day]?.format(context) ?? 'End Time'),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context, day, false),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Save availability button
            ElevatedButton(
              onPressed: _saveAvailability,
              child: const Text("Save Availability"),
            ),
          ],
        ),
      ),
    );
  }
}
