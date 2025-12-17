import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rental_management_app/services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

enum AnalyticsViewType { chart, list }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _monthFormat = DateFormat('yyyy-MM');
  final DateFormat _displayFormat = DateFormat('MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  String? _startMonthYear;
  String? _endMonthYear;
  List<MapEntry<String, Map<String, double>>> _monthlyData = [];
  bool _isLoading = false;

  int _chartType = 0;
  AnalyticsViewType _viewType = AnalyticsViewType.chart;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const primaryBlue = Color(0xFF1E88E5);
  static const darkBlue = Color(0xFF0D47A1);
  static const accentYellow = Color(0xFFFFCA28);

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
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    final now = DateTime.now();
    _endMonthYear = _monthFormat.format(now);
    _startMonthYear = _monthFormat.format(DateTime(now.year - 1, now.month));

    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // DATA LOADING (UNCHANGED)
  // ----------------------------------------------------------
  Future<void> _loadData() async {
    if (_startMonthYear == null || _endMonthYear == null) return;

    setState(() {
      _isLoading = true;
      _monthlyData.clear();
    });

    final startDate = DateTime.parse('$_startMonthYear-01');
    final endDate = DateTime.parse('$_endMonthYear-01');

    final months = <String>[];
    var current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      months.add(_monthFormat.format(current));
      current = DateTime(current.year, current.month + 1);
    }

    final results = <String, Map<String, double>>{};
    for (final m in months) {
      results[m] = await _dbService.getTotalPaymentsForMonth(m);
    }

    setState(() {
      _monthlyData =
          results.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
      _isLoading = false;
    });
  }

  // ----------------------------------------------------------
  // APP BAR (MATCHES PAYMENT SCREEN)
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [darkBlue, primaryBlue]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rent & Water Collection Overview',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
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

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final totalRent = _monthlyData.fold<double>(
      0,
      (s, e) => s + (e.value['rent'] ?? 0),
    );
    final totalWater = _monthlyData.fold<double>(
      0,
      (s, e) => s + (e.value['water'] ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (_, __) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTotalsCard(totalRent, totalWater),
                            const SizedBox(height: 24),
                            _buildHeaderControls(),
                            const SizedBox(height: 12),
                            _buildMainContent(),
                          ],
                        ),
                      ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // UI SECTIONS
  // ----------------------------------------------------------
  Widget _buildTotalsCard(double rent, double water) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRow(
            Icons.monetization_on_rounded,
            primaryBlue,
            'Total Rent Collected',
            rent,
          ),
          const SizedBox(height: 16),
          _buildTotalRow(
            Icons.water_drop_rounded,
            accentYellow,
            'Total Water Bill Collected',
            water,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    IconData icon,
    Color color,
    String title,
    double value,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_currencyFormat.format(value)} UGX',
              style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.bar_chart_rounded,
                color:
                    _viewType == AnalyticsViewType.chart
                        ? primaryBlue
                        : Colors.grey,
              ),
              onPressed:
                  () => setState(() => _viewType = AnalyticsViewType.chart),
            ),
            IconButton(
              icon: Icon(
                Icons.list_rounded,
                color:
                    _viewType == AnalyticsViewType.list
                        ? primaryBlue
                        : Colors.grey,
              ),
              onPressed:
                  () => setState(() => _viewType = AnalyticsViewType.list),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_monthlyData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No data available for selected period',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    if (_viewType == AnalyticsViewType.list) {
      return _buildListView();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chartButton('Bar', _chartType == 0),
            const SizedBox(width: 12),
            _chartButton('Line', _chartType == 1),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: _chartType == 0 ? _buildBarChart() : _buildLineChart(),
        ),
      ],
    );
  }

  Widget _chartButton(String text, bool selected) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: selected ? primaryBlue : Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          _chartType = text == 'Bar' ? 0 : 1;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // CHARTS & LIST (UNCHANGED LOGIC)
  // ----------------------------------------------------------
  Widget _buildBarChart() => _buildChartWrapper(_buildBarChartContent());
  Widget _buildLineChart() => _buildChartWrapper(_buildLineChartContent());

  Widget _buildChartWrapper(Widget chart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: chart,
    );
  }

  Widget _buildBarChartContent() {
    // SAME IMPLEMENTATION AS YOUR ORIGINAL
    // (kept intentionally unchanged)
    return BarChart(
      BarChartData(
        barGroups:
            _monthlyData.asMap().entries.map((e) {
              final rent = e.value.value['rent'] ?? 0;
              final water = e.value.value['water'] ?? 0;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(toY: rent, color: primaryBlue, width: 12),
                  BarChartRodData(toY: water, color: accentYellow, width: 12),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLineChartContent() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots:
                _monthlyData
                    .asMap()
                    .entries
                    .map(
                      (e) =>
                          FlSpot(e.key.toDouble(), e.value.value['rent'] ?? 0),
                    )
                    .toList(),
            color: primaryBlue,
          ),
          LineChartBarData(
            spots:
                _monthlyData
                    .asMap()
                    .entries
                    .map(
                      (e) =>
                          FlSpot(e.key.toDouble(), e.value.value['water'] ?? 0),
                    )
                    .toList(),
            color: accentYellow,
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _monthlyData.length,
      itemBuilder: (_, i) {
        final entry = _monthlyData[i];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              _displayFormat.format(DateTime.parse('${entry.key}-01')),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            subtitle: Text(
              'Rent: ${_currencyFormat.format(entry.value['rent'] ?? 0)} | '
              'Water: ${_currencyFormat.format(entry.value['water'] ?? 0)}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        );
      },
    );
  }
}
