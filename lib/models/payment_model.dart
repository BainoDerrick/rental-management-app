import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Payment {
  final String? id;
  final String tenantId;
  final DateTime date;
  final double rentPaid;
  final double waterBillPaid;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.tenantId,
    required this.date,
    required this.rentPaid,
    required this.waterBillPaid,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? date;

  String get monthYear => DateFormat('yyyy-MM').format(date);

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'date': Timestamp.fromDate(date), // Store as Timestamp
      'rentPaid': rentPaid,
      'waterBillPaid': waterBillPaid,
      'createdAt': Timestamp.fromDate(createdAt), // Store as Timestamp
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      tenantId: map['tenantId'] ?? '',
      date: (map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'])), // Handle both Timestamp and string
      rentPaid: (map['rentPaid'] as num).toDouble(),
      waterBillPaid: (map['waterBillPaid'] as num).toDouble(),
      createdAt: (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? map['date'])),
    );
  }

  Payment copyWith({String? id}) {
    return Payment(
      id: id ?? this.id,
      tenantId: tenantId,
      date: date,
      rentPaid: rentPaid,
      waterBillPaid: waterBillPaid,
      createdAt: createdAt,
    );
  }
}