import 'package:cloud_firestore/cloud_firestore.dart';

class Tenant {
  String? id;
  final String name;
  final String phone;
  final String houseNumber;
  final double rentThreshold; // Renamed from monthlyRent
  final DateTime? moveInDate;
  final String status;

  Tenant({
    this.id,
    required this.name,
    required this.phone,
    required this.houseNumber,
    required this.rentThreshold,
    this.moveInDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'houseNumber': houseNumber,
      'rentThreshold': rentThreshold,
      'moveInDate': moveInDate != null ? Timestamp.fromDate(moveInDate!) : null, // Store as Timestamp
      'status': status,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map, {String? id}) {
    return Tenant(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      rentThreshold: (map['rentThreshold'] as num?)?.toDouble() ?? 0.0,
      moveInDate: map['moveInDate'] != null
          ? (map['moveInDate'] is Timestamp
              ? (map['moveInDate'] as Timestamp).toDate()
              : DateTime.parse(map['moveInDate']))
          : null,
      status: map['status'] ?? 'active',
    );
  }

  Tenant copyWith({String? id, String? status}) {
    return Tenant(
      id: id ?? this.id,
      name: name,
      phone: phone,
      houseNumber: houseNumber,
      rentThreshold: rentThreshold,
      moveInDate: moveInDate,
      status: status ?? this.status,
    );
  }
}