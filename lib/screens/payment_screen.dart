import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  State<PaymentScreen> createState() => _PaymentScreenState();
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

  static const primaryBlue = Color(0xFF1E88E5);
  static const accentYellow = Color(0xFFFFCA28);

  @override
  void initState() {
    super.initState();
    _monthYearController.text = _monthFormat.format(DateTime.now());
  }

  // ------------------------------------------------------------
  // APP BAR (NO OVERFLOW)
  // ------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(130),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), primaryBlue]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _buildIconButton(
                      icon: Icons.history,
                      tooltip: 'View Payment History',
                      onPressed: _navigateToHistoryScreen,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.tenant.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormCard(),
            const SizedBox(height: 24),
            _buildPaymentsSection(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FORM CARD
  // ------------------------------------------------------------
  Widget _buildFormCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildMonthField(),
              const SizedBox(height: 16),
              _buildAmountField(
                controller: _rentController,
                label: 'Rent Paid (UGX)',
                icon: Icons.monetization_on,
                color: primaryBlue,
              ),
              const SizedBox(height: 16),
              _buildAmountField(
                controller: _waterController,
                label: 'Water Bill Paid (UGX)',
                icon: Icons.water_drop,
                color: accentYellow,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child:
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _recordPayment,
                          child: const Text(
                            'RECORD PAYMENT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthField() {
    return TextFormField(
      controller: _monthYearController,
      readOnly: true,
      decoration: _inputDecoration(
        label: 'Month',
        icon: Icons.calendar_month,
        color: primaryBlue,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      onTap: () => _selectMonth(context),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: _inputDecoration(label: label, icon: icon, color: color),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        final amount = double.tryParse(
          value.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        if (amount == null || amount < 0) return 'Invalid amount';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      ),
    );
  }

  // ------------------------------------------------------------
  // PAYMENTS SECTION
  // ------------------------------------------------------------
  Widget _buildPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payments for ${_monthYearController.text}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 60,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [primaryBlue, accentYellow]),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<(List<Payment>, DocumentSnapshot?)>(
          stream: _dbService.getPaymentsForMonth(
            widget.tenant.id!,
            _monthYearController.text,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final payments = snapshot.data?.$1 ?? [];

            if (payments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No payments recorded',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            }

            return Column(children: payments.map(_buildPaymentTile).toList());
          },
        ),
      ],
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          _dateFormat.format(payment.createdAt),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Rent: UGX ${_currencyFormat.format(payment.rentPaid)}'),
            Text('Water: UGX ${_currencyFormat.format(payment.waterBillPaid)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deletePayment(payment.id!),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOGIC (UNCHANGED)
  // ------------------------------------------------------------
  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
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
        rentPaid: double.parse(
          _rentController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ),
        waterBillPaid: double.parse(
          _waterController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ),
      );

      final paymentId = await _dbService.addPayment(payment);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ReceiptScreen(
                payment: payment.copyWith(id: paymentId),
                tenant: widget.tenant,
              ),
        ),
      );

      _rentController.clear();
      _waterController.clear();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePayment(String id) async {
    await _dbService.deletePayment(id);
    setState(() {});
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(tenantId: widget.tenant.id!),
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

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
