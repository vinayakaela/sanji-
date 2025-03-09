import 'package:cloud_firestore/cloud_firestore.dart';

class Technician {
  final String uid;
  final String name;
  final String serviceType;
  final String description;
  final double rating;
  final int experienceYears;
  final DateTime createdAt;
  final String? photoUrl;
  final bool available;
  final List<Map<String, dynamic>> availability;
  final GeoPoint? location;
  final String? phone;
  final bool approved; // ✅ Ensure this is properly parsed

  Technician({
    required this.uid,
    required this.name,
    required this.serviceType,
    required this.description,
    required this.rating,
    required this.experienceYears,
    required this.createdAt,
    required this.availability,
    required this.approved, // ✅ Ensure it's handled
    this.photoUrl,
    this.available = false,
    this.location,
    this.phone,
  });

  // ✅ Factory constructor to create a Technician instance from JSON.
  factory Technician.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> availabilityList = [];

    if (json['availability'] != null) {
      if (json['availability'] is Map<String, dynamic>) {
        availabilityList =
            (json['availability'] as Map<String, dynamic>).entries.map((entry) {
              final times = entry.value as Map<String, dynamic>;
              return {
                'day': entry.key,
                'start': times['start'],
                'end': times['end'],
              };
            }).toList();
      } else if (json['availability'] is List) {
        availabilityList = (json['availability'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    // ✅ Handle location properly
    GeoPoint? parsedLocation;
    if (json['location'] is GeoPoint) {
      parsedLocation = json['location'];
    } else if (json['location'] is Map<String, dynamic>) {
      parsedLocation = GeoPoint(
        (json['location']['latitude'] ?? 0.0).toDouble(),
        (json['location']['longitude'] ?? 0.0).toDouble(),
      );
    }

    return Technician(
      uid: json['uid'] ?? '',
      name: json['name'] ?? 'Unknown Technician',
      serviceType: json['serviceType'] ?? 'Not Specified',
      description: json['description'] ?? 'No description provided',
      rating: (json['rating'] is num) ? json['rating'].toDouble() : 0.0,
      experienceYears:
      (json['experienceYears'] is num) ? json['experienceYears'].toInt() : 0,
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      photoUrl: json['photoUrl'] as String?,
      availability: availabilityList,
      location: parsedLocation,
      available: json['available'] == true, // ✅ Ensure it's a boolean
      phone: json['phone'] as String?,
      approved: json['approved'] is bool ? json['approved'] : false, // ✅ FIXED
    );
  }

  // ✅ Convert a Technician instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'serviceType': serviceType,
      'description': description,
      'rating': rating,
      'experienceYears': experienceYears,
      'created_at': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'availability': availability,
      'location': location != null
          ? {'latitude': location!.latitude, 'longitude': location!.longitude}
          : null,
      'available': available,
      'phone': phone,
      'approved': approved, // ✅ Ensure this is stored correctly
    };
  }
}
