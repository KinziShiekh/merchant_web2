import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Merchandiser {
  final String? merchandiserId;
  final String name;
  final String email;
  final String phone;
  final String address;
  late String? city; // Optional field
  late String? state; // Optional field
  final String distributorId; // Assigned distributor
// Changed to String
  final String createdDate; // Changed to String
  final String type; // New field
  final String password; // New field

  Merchandiser({
    this.merchandiserId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.city, // Optional field
    this.state, // Optional field
    required this.distributorId, // Assigned distributor
    // String date
    String? createdDate, // String createdDate
    this.type = 'merchandiser', // Default value for type
    required this.password, // Required password
  }) : createdDate = createdDate ??
            DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());

  // Convert a Merchandiser instance into a Map
  Map<String, dynamic> toMap() {
    return {
      'merchandiserId': merchandiserId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city, // Optional field
      'state': state, // Optional field
      'distributorId': distributorId,

      'createdDate': createdDate, // Use string createdDate
      'type': type, // Include type in map
      'password': password, // Include password in map
    };
  }

  // Create a Merchandiser instance from a Map
  factory Merchandiser.fromMap(Map<String, dynamic> map, String id) {
    return Merchandiser(
      merchandiserId: id,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      city: map['city'] as String?, // Optional field
      state: map['state'] as String?, // Optional field
      distributorId: map['distributorId'] as String,

      createdDate: map['createdDate'] as String, // String createdDate
      type: map['type'] as String? ?? 'merchandiser', // Default value for type
      password: map['password'] as String, // String password
    );
  }

  // Create a Merchandiser instance from Firestore DocumentSnapshot
  factory Merchandiser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Merchandiser.fromMap(data, doc.id);
  }

  // Factory method to create a copy with modified fields
  Merchandiser copyWith({
    String? merchandiserId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city, // Optional field
    String? state, // Optional field
    String? distributorId,
    String? date,
    String? createdDate,
    String? type, // Optional field
    String? password, // Optional field
  }) {
    return Merchandiser(
      merchandiserId: merchandiserId ?? this.merchandiserId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city, // Optional field
      state: state ?? this.state, // Optional field
      distributorId: distributorId ?? this.distributorId,

      createdDate: createdDate ?? this.createdDate,
      type: type ?? this.type, // Optional field
      password: password ?? this.password, // Optional field
    );
  }

  // Utility methods to parse and format dates

  DateTime get createdDateAsDateTime =>
      DateFormat('dd-MM-yyyy hh:mm a').parse(createdDate);

  String get formattedCreatedDate =>
      DateFormat('dd-MM-yyyy hh:mm a').format(createdDateAsDateTime);
}
