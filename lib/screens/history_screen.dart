import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rental_management_app/models/payment_model.dart';
import 'package:rental_management_app/services/database_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final String tenantId;

  const HistoryScreen({required this.tenantId, Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _dateFormat = DateFormat('MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  String? _selectedMonthYear;
  List<Payment> _payments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // ✅ FIXED APP BAR — NO OVERFLOW
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAnimatedAppBar() {
    const primaryBlue = Color(0xFF1E88E5);

    return PreferredSize(
      // 🔑 Increased height — THIS fixes the overflow
      preferredSize: const Size.fromHeight(140),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (_, __) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), primaryBlue],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    // ❌ REMOVED mainAxisSize.min (important)
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Filter Month',
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _selectMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedMonthYear == null
                            ? 'All payments'
                            : _dateFormat.format(
                              DateTime.parse('$_selectedMonthYear-01'),
                            ),
                        style: const TextStyle(
                          fontSize: 14,
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
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAnimatedAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (_, __) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: StreamBuilder<(List<Payment>, DocumentSnapshot?)>(
                stream:
                    _selectedMonthYear == null
                        ? _dbService.getPayments(
                          widget.tenantId,
                          startAfter: null,
                        )
                        : _dbService.getPaymentsForMonth(
                          widget.tenantId,
                          _selectedMonthYear!,
                          startAfter: null,
                        ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _payments.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    );
                  }

                  _payments = snapshot.data?.$1 ?? [];
                  _lastDocument = snapshot.data?.$2;
                  _hasMore = _payments.length == 20;

                  if (_payments.isEmpty) {
                    return const Center(child: Text('No payments found'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (_, index) {
                      final payment = _payments[index];
                      return _buildPaymentCard(payment);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _amountColumn(
            Icons.monetization_on,
            primaryBlue,
            'Rent',
            payment.rentPaid,
          ),
          _amountColumn(
            Icons.water_drop,
            accentYellow,
            'Water',
            payment.waterBillPaid,
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(IconData icon, Color color, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'UGX ${_currencyFormat.format(value)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked == null) return;

    setState(() {
      _selectedMonthYear = DateFormat('yyyy-MM').format(picked);
      _payments.clear();
      _lastDocument = null;
      _hasMore = true;
    });
  }
}
