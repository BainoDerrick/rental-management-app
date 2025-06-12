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

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _dateFormat = DateFormat('MMM yyyy');
  String? _selectedMonthYear;
  List<Payment> _payments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final ScrollController _scrollController = ScrollController();

  Future<void> _loadMorePayments() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final result = _selectedMonthYear == null
        ? await _dbService.getPayments(widget.tenantId, startAfter: _lastDocument).first
        : await _dbService.getPaymentsForMonth(widget.tenantId, _selectedMonthYear!, startAfter: _lastDocument).first;

    final newPayments = result.$1;
    final lastDoc = result.$2;

    setState(() {
      _payments.addAll(newPayments);
      _lastDocument = lastDoc;
      _hasMore = newPayments.length == 20;
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment History',
          style: TextStyle(
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
          _buildDateButton(
            icon: Icons.calendar_today,
            tooltip: 'Select Month',
            onPressed: _selectMonth,
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
        child: StreamBuilder<(List<Payment>, DocumentSnapshot?)>(
          stream: _selectedMonthYear == null
              ? _dbService.getPayments(widget.tenantId, startAfter: null)
              : _dbService.getPaymentsForMonth(widget.tenantId, _selectedMonthYear!, startAfter: null),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting && _payments.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              );
            }

            _payments = snapshot.data?.$1 ?? [];
            _lastDocument = snapshot.data?.$2;
            _hasMore = _payments.length == 20;

            final groupedPayments = <String, List<Payment>>{};
            for (var payment in _payments) {
              final monthYear = DateFormat('yyyy-MM').format(payment.date);
              if (!groupedPayments.containsKey(monthYear)) {
                groupedPayments[monthYear] = [];
              }
              groupedPayments[monthYear]!.add(payment);
            }
            final sortedMonths = groupedPayments.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Text(
                    _selectedMonthYear == null
                        ? 'Showing all payments'
                        : 'Showing payments for ${_dateFormat.format(DateTime.parse("$_selectedMonthYear-01"))}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Expanded(
                  child: groupedPayments.isEmpty
                      ? Center(
                          child: Text(
                            'No payments found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                                !_isLoadingMore &&
                                _hasMore) {
                              _loadMorePayments();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: sortedMonths.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == sortedMonths.length) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                  ),
                                );
                              }

                              final monthYear = sortedMonths[index];
                              final paymentsForMonth = groupedPayments[monthYear]!;
                              final monthDisplay = _dateFormat.format(DateTime.parse('$monthYear-01'));

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: primaryBlue,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          monthDisplay,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryBlue, accentYellow],
                                      ),
                                    ),
                                  ),
                                  ...paymentsForMonth.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final payment = entry.value;
                                    return Card(
                                      elevation: 4.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      margin: const EdgeInsets.only(bottom: 16.0),
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
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Payment ${idx + 1}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  Text(
                                                    _dateFormat.format(payment.createdAt),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
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
                                                            'Rent Paid',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                              fontFamily: 'Poppins',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${_currencyFormat.format(payment.rentPaid)} UGX',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.water_drop,
                                                            color: accentYellow,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            'Water Paid',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                              fontFamily: 'Poppins',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${_currencyFormat.format(payment.waterBillPaid)} UGX',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonthYear != null
          ? DateTime.parse("$_selectedMonthYear-01")
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Filter by Month',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        content: Text(
          picked != null
              ? 'Show payments for ${_dateFormat.format(picked)}?'
              : 'Show all payments?',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedMonthYear = null;
                _payments.clear();
                _lastDocument = null;
                _hasMore = true;
              });
            },
            child: const Text(
              'Show All',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF1E88E5),
              ),
            ),
          ),
          if (picked != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedMonthYear = DateFormat('yyyy-MM').format(picked);
                  _payments.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
              },
              child: const Text(
                'Filter',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF1E88E5),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFFFCA28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build date selection button
  Widget _buildDateButton({
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