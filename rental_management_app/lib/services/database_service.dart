import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tenant_model.dart';
import '../models/payment_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore; // Expose for use in HistoryScreen

  Future<String> addTenant(Tenant tenant) async {
    final docRef = await _firestore.collection('tenants').add(tenant.toMap());
    return docRef.id;
  }

  Future<void> updateTenant(Tenant tenant) async {
    await _firestore.collection('tenants').doc(tenant.id).update(tenant.toMap());
  }

  Future<void> deleteTenant(String tenantId) async {
    await _firestore.collection('tenants').doc(tenantId).delete();
    final payments = await _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .get();
    for (var payment in payments.docs) {
      await payment.reference.delete();
    }
  }

  Stream<(List<Tenant>, DocumentSnapshot?)> getTenants({int limit = 20, DocumentSnapshot? startAfter}) {
    Query<Map<String, dynamic>> query = _firestore.collection('tenants').orderBy('name').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.snapshots().map((snapshot) {
      final tenants = snapshot.docs.map((doc) {
        return Tenant.fromMap(doc.data(), id: doc.id).copyWith(id: doc.id);
      }).toList();
      return (tenants, snapshot.docs.isNotEmpty ? snapshot.docs.last : null);
    });
  }

  Future<String> addPayment(Payment payment) async {
    final docRef = await _firestore.collection('payments').add(payment.toMap());
    return docRef.id;
  }

  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  Stream<(List<Payment>, DocumentSnapshot?)> getPaymentsForMonth(
      String tenantId, String monthYear, {int limit = 20, DocumentSnapshot? startAfter}) {
    debugPrint('Querying payments for tenant: $tenantId, month: $monthYear');
    final yearMonth = monthYear.split('-');
    final startOfMonth = DateTime.utc(
      int.parse(yearMonth[0]),
      int.parse(yearMonth[1]),
      1,
    );
    final endOfMonth = DateTime.utc(
      startOfMonth.year,
      startOfMonth.month + 1,
      1,
    ).subtract(Duration(seconds: 1));

    Query<Map<String, dynamic>> query = _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      debugPrint('Found ${snapshot.docs.length} documents');
      for (var doc in snapshot.docs) {
        debugPrint('Doc data: ${doc.data()}');
      }
      final payments = snapshot.docs.map((doc) {
        return Payment.fromMap(doc.data()).copyWith(id: doc.id);
      }).toList();
      return (payments, snapshot.docs.isNotEmpty ? snapshot.docs.last : null);
    });
  }

  Future<double> getRentBalance(String tenantId, String monthYear) async {
    final tenantDoc = await _firestore.collection('tenants').doc(tenantId).get();
    final monthlyRent = (tenantDoc.data() as Map<String, dynamic>)['rentThreshold'] ?? 0.0;

    final paymentsResult = await getPaymentsForMonth(tenantId, monthYear).first;
    final totalPaid = paymentsResult.$1.fold(0.0, (sum, payment) => sum + payment.rentPaid);

    return monthlyRent - totalPaid;
  }

  Stream<(List<Payment>, DocumentSnapshot?)> getPayments(String tenantId, {int limit = 20, DocumentSnapshot? startAfter}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('date', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      final payments = snapshot.docs.map((doc) {
        return Payment.fromMap(doc.data()).copyWith(id: doc.id);
      }).toList();
      return (payments, snapshot.docs.isNotEmpty ? snapshot.docs.last : null);
    });
  }

  Future<Map<String, double>> getTotalPaymentsForMonth(String monthYear) async {
    final yearMonth = monthYear.split('-');
    final startOfMonth = DateTime.utc(
      int.parse(yearMonth[0]),
      int.parse(yearMonth[1]),
      1,
    );
    final endOfMonth = DateTime.utc(
      startOfMonth.year,
      startOfMonth.month + 1,
      1,
    ).subtract(Duration(seconds: 1));

    final snapshot = await _firestore
        .collection('payments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double totalRent = 0;
    double totalWater = 0;

    for (var doc in snapshot.docs) {
      final payment = Payment.fromMap(doc.data());
      totalRent += payment.rentPaid;
      totalWater += payment.waterBillPaid;
    }

    return {'rent': totalRent, 'water': totalWater};
  }
}