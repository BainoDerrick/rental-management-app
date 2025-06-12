import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rental_management_app/models/payment_model.dart';
import 'package:rental_management_app/models/tenant_model.dart';
import 'package:rental_management_app/screens/history_screen.dart';
import 'package:rental_management_app/screens/receipt_screen.dart';
import 'package:rental_management_app/services/database_service.dart';

class PaymentScreen extends StatefulWidget {
  final Tenant tenant;
  const PaymentScreen({required this.tenant, Key? key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rentController = TextEditingController();
  final _waterController = TextEditingController();
  final _monthYearController = TextEditingController();
  bool _isSaving = false;
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _dateFormat = DateFormat('MMM yyyy');
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _monthYearController.text = _monthFormat.format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Record Payment - ${widget.tenant.name}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          _buildIconButton(
            icon: Icons.history,
            tooltip: 'View Payment History',
            onPressed: _navigateToHistoryScreen,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryBlue,
              Colors.white,
              accentYellow,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _monthYearController,
                          decoration: InputDecoration(
                            labelText: 'Month-Year',
                            hintText: 'YYYY-MM',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey[400],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: primaryBlue,
                              ),
                              onPressed: () => _selectMonth(context),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(color: primaryBlue),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) {
                              return 'Use YYYY-MM format';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rentController,
                          decoration: InputDecoration(
                            labelText: 'Rent Paid (UGX)',
                            hintText: 'e.g. 500000 or 500,000',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.monetization_on,
                              color: primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(color: primaryBlue),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final rawValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
                            final amount = double.tryParse(rawValue);
                            if (amount == null || amount <= 0) return 'Invalid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _waterController,
                          decoration: InputDecoration(
                            labelText: 'Water Bill Paid (UGX)',
                            hintText: 'e.g. 10000 or 10,000',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black87,
                            ),
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.water_drop,
                              color: accentYellow,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(color: primaryBlue),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final rawValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
                            final amount = double.tryParse(rawValue);
                            if (amount == null || amount <= 0) return 'Invalid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _isSaving
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 4.0,
                                  ),
                                  onPressed: _recordPayment,
                                  child: const Text(
                                    'RECORD PAYMENT',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payments for ${_monthYearController.text}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, accentYellow],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<(List<Payment>, DocumentSnapshot?)>(
                key: ValueKey(_monthYearController.text),
                stream: _dbService.getPaymentsForMonth(widget.tenant.id!, _monthYearController.text),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontFamily: 'Poppins',
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                    );
                  }

                  final payments = snapshot.data?.$1 ?? [];
                  return FutureBuilder<double>(
                    future: _dbService.getRentBalance(widget.tenant.id!, _monthYearController.text),
                    builder: (context, balanceSnapshot) {
                      if (balanceSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                          ),
                        );
                      }
                      final balance = balanceSnapshot.data ?? widget.tenant.rentThreshold;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(), // Placeholder for alignment
                              Chip(
                                label: Text(
                                  balance <= 0
                                      ? 'Paid in full'
                                      : 'Balance: ${_currencyFormat.format(balance)} UGX',
                                  style: TextStyle(
                                    color: balance <= 0 ? Colors.white : Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                backgroundColor: balance <= 0
                                    ? Colors.green
                                    : accentYellow.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (payments.isEmpty)
                            Center(
                              child: Text(
                                'No payments recorded yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          else
                            ...payments.map((payment) => Card(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[100]!,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.monetization_on,
                                                color: primaryBlue,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Rent: ${_currencyFormat.format(payment.rentPaid)} UGX',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.water_drop,
                                                color: accentYellow,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Water: ${_currencyFormat.format(payment.waterBillPaid)} UGX',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _dateFormat.format(payment.createdAt),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deletePayment(payment.id!),
                                      ),
                                    ),
                                  ),
                                )),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _monthYearController.text = _monthFormat.format(picked);
      });
    }
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final yearMonth = _monthYearController.text.split('-');
      final selectedDate = DateTime.utc(
        int.parse(yearMonth[0]),
        int.parse(yearMonth[1]),
        1,
      );

      final payment = Payment(
        tenantId: widget.tenant.id!,
        date: selectedDate,
        rentPaid: double.parse(_rentController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        waterBillPaid: double.parse(_waterController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
      );

      final paymentId = await _dbService.addPayment(payment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Payment recorded successfully!',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFF1E88E5),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            payment: payment.copyWith(id: paymentId),
            tenant: widget.tenant,
          ),
        ),
      );

      _rentController.clear();
      _waterController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFFFFCA28),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePayment(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Delete Payment?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        content: const Text(
          'This action cannot be undone',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFFFCA28),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deletePayment(paymentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Payment deleted',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFF1E88E5),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(tenantId: widget.tenant.id!),
      ),
    );
  }

  @override
  void dispose() {
    _rentController.dispose();
    _waterController.dispose();
    _monthYearController.dispose();
    super.dispose();
  }

  // Helper method to build icon button
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}