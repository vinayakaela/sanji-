import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:technician/technicain/technicain_model.dart';

class BookingService {
  Future<Technician?> findBestTechnician(String serviceType, DateTime startTime, GeoPoint userLocation) async {
    final techniciansRef = FirebaseFirestore.instance.collection('technicians');

    final techniciansSnapshot = await techniciansRef
        .where('serviceType', isEqualTo: serviceType)
        .where('approved', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> availableTechnicians = [];

    for (var doc in techniciansSnapshot.docs) {
      final data = doc.data();
      final availability = data['availability'] ?? {};
      final technicianLocation = data['location'] as GeoPoint?;

      // Check if technician is available on selected weekday
      if (availability.containsKey(startTime.weekday.toString()) && technicianLocation != null) {
        String start = availability[startTime.weekday.toString()]['start'];
        String end = availability[startTime.weekday.toString()]['end'];

        DateTime startAvailability = DateFormat("hh:mm a").parse(start);
        DateTime endAvailability = DateFormat("hh:mm a").parse(end);

        if (startTime.isAfter(startAvailability) && startTime.isBefore(endAvailability)) {
          availableTechnicians.add({
            'id': doc.id,
            'data': data,
            'distance': calculateDistance(userLocation, technicianLocation),
            'activeBookings': await getActiveBookingCount(doc.id),
            'rating': data['rating'] ?? 0.0
          });
        }
      }
    }

    // Sort technicians (less bookings, closest, best rating)
    availableTechnicians.sort((a, b) {
      if (a['activeBookings'] != b['activeBookings']) {
        return a['activeBookings'].compareTo(b['activeBookings']);
      } else if (a['distance'] != b['distance']) {
        return a['distance'].compareTo(b['distance']);
      } else {
        return b['rating'].compareTo(a['rating']);
      }
    });

    return availableTechnicians.isNotEmpty ? availableTechnicians.first['data'] as Technician? : null;
  }

  // Calculate distance between user & technician
  double calculateDistance(GeoPoint user, GeoPoint technician) {
    const double earthRadius = 6371; // Radius of Earth in km
    double lat1 = user.latitude * pi / 180;
    double lon1 = user.longitude * pi / 180;
    double lat2 = technician.latitude * pi / 180;
    double lon2 = technician.longitude * pi / 180;

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in km
  }

  // Get active bookings count for a technician

  Future<int> getActiveBookingCount(String technicianId) async {
    final bookingsRef = FirebaseFirestore.instance.collection('bookings');

    final snapshot = await bookingsRef
        .where('technicianId', isEqualTo: technicianId)
        .where('status', whereIn: ['Pending', 'Accepted'])
        .get();

    return snapshot.docs.length;
  }
}