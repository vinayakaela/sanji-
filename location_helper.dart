import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:technician/technicain/technicain_model.dart';


class BookingHelper {
  static Future<String> createBooking(String userId, Technician technician, DateTime startTime, DateTime endTime, String address) async {
    final bookingsRef = FirebaseFirestore.instance.collection('bookings');

    final bookingData = {
      'userId': userId,
      'technicianId': technician.uid,
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
      'start': DateFormat("hh:mm a").format(startTime),
      'end': DateFormat("hh:mm a").format(endTime),
      'address': address
    };

    final docRef = await bookingsRef.add(bookingData);
    return docRef.id;
  }
}
