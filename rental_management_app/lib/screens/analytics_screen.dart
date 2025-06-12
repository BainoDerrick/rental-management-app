import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rental_management_app/services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  final DateFormat _displayFormat = DateFormat('MMM yyyy');
  String? _startMonthYear;
  String? _endMonthYear;
  List<MapEntry<String, Map<String, double>>> _monthlyData = [];
  bool _isLoading = false;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endMonthYear = _monthFormat.format(now);
    _startMonthYear = _monthFormat.format(DateTime(now.year - 1, now.month));
    _loadData();
  }

  Future<void> _loadData() async {
    if (_startMonthYear == null || _endMonthYear == null) return;

    setState(() {
      _isLoading = true;
      _monthlyData.clear();
    });

    try {
      final startDate = DateTime.parse('$_startMonthYear-01');
      final endDate = DateTime.parse('$_endMonthYear-01');
      final months = <String>[];
      var currentDate = startDate;

      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        months.add(_monthFormat.format(currentDate));
        currentDate = DateTime(currentDate.year, currentDate.month + 1);
      }

      final monthlyResults = <String, Map<String, double>>{};
      for (var monthYear in months) {
        final result = await _dbService.getTotalPaymentsForMonth(monthYear);
        monthlyResults[monthYear] = result;
      }

      final sortedEntries = monthlyResults.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));

      setState(() {
        _monthlyData = sortedEntries;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading data: $e',
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFFFFCA28),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startMonthYear != null
          ? DateTime.parse('$_startMonthYear-01')
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _startMonthYear = _monthFormat.format(picked);
        _loadData();
      });
    }
  }

  Future<void> _selectEndMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endMonthYear != null
          ? DateTime.parse('$_endMonthYear-01')
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _endMonthYear = _monthFormat.format(picked);
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalRentCollected = _monthlyData.fold(
        0.0, (sum, entry) => sum + (entry.value['rent'] ?? 0.0));
    double totalWaterBillCollected = _monthlyData.fold(
        0.0, (sum, entry) => sum + (entry.value['water'] ?? 0.0));

    // Define theme colors
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
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
            icon: Icons.date_range,
            tooltip: 'Select Start Month',
            onPressed: () => _selectStartMonth(context),
          ),
          const SizedBox(width: 8),
          _buildDateButton(
            icon: Icons.date_range_outlined,
            tooltip: 'Select End Month',
            onPressed: () => _selectEndMonth(context),
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
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Totals Section
                    Card(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: primaryBlue,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Total Rent Collected',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_currencyFormat.format(totalRentCollected)} UGX',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: accentYellow,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Total Water Bill Collected',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: accentYellow,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_currencyFormat.format(totalWaterBillCollected)} UGX',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Monthly Breakdown Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          '${_startMonthYear != null ? _displayFormat.format(DateTime.parse("$_startMonthYear-01")) : "Select Start"} - ${_endMonthYear != null ? _displayFormat.format(DateTime.parse("$_endMonthYear-01")) : "Select End"}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                    Expanded(
                      child: _monthlyData.isEmpty
                          ? Center(
                              child: Text(
                                'No data available for the selected period',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _monthlyData.length,
                              itemBuilder: (context, index) {
                                final monthYear = _monthlyData[index].key;
                                final rent = _monthlyData[index].value['rent'] ?? 0.0;
                                final water = _monthlyData[index].value['water'] ?? 0.0;
                                return Card(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 6.0),
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
                                      leading: Icon(
                                        Icons.calendar_month,
                                        color: primaryBlue,
                                        size: 28,
                                      ),
                                      title: Text(
                                        _displayFormat.format(DateTime.parse('$monthYear-01')),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
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
                                                  'Rent: ${_currencyFormat.format(rent)} UGX',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
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
                                                  'Water: ${_currencyFormat.format(water)} UGX',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Helper method to build date selection buttons
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