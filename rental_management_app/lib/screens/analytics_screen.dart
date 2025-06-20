import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rental_management_app/services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

enum AnalyticsViewType { chart, list }

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
  int _chartType = 0; // 0 = bar, 1 = line
  AnalyticsViewType _viewType = AnalyticsViewType.chart;

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

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        months.add(_monthFormat.format(currentDate));
        currentDate = DateTime(currentDate.year, currentDate.month + 1);
      }

      final monthlyResults = <String, Map<String, double>>{};
      for (var monthYear in months) {
        final result = await _dbService.getTotalPaymentsForMonth(monthYear);
        monthlyResults[monthYear] = result;
      }

      final sortedEntries =
          monthlyResults.entries.toList()
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
      initialDate:
          _startMonthYear != null
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
      initialDate:
          _endMonthYear != null
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
      0.0,
      (sum, entry) => sum + (entry.value['rent'] ?? 0.0),
    );
    double totalWaterBillCollected = _monthlyData.fold(
      0.0,
      (sum, entry) => sum + (entry.value['water'] ?? 0.0),
    );

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
            colors: [primaryBlue, Colors.white, accentYellow],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
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

                      // View Controls Section
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
                          Row(
                            children: [
                              Text(
                                '${_startMonthYear != null ? _displayFormat.format(DateTime.parse("$_startMonthYear-01")) : "Select Start"} - ${_endMonthYear != null ? _displayFormat.format(DateTime.parse("$_endMonthYear-01")) : "Select End"}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.bar_chart,
                                  color:
                                      _viewType == AnalyticsViewType.chart
                                          ? primaryBlue
                                          : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _viewType = AnalyticsViewType.chart;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.list,
                                  color:
                                      _viewType == AnalyticsViewType.list
                                          ? primaryBlue
                                          : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _viewType = AnalyticsViewType.list;
                                  });
                                },
                              ),
                            ],
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

                      // Chart View Options (only shown when in chart view)
                      if (_viewType == AnalyticsViewType.chart)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildChartTypeButton('Bar Chart', _chartType == 0),
                            const SizedBox(width: 16),
                            _buildChartTypeButton(
                              'Line Chart',
                              _chartType == 1,
                            ),
                          ],
                        ),
                      if (_viewType == AnalyticsViewType.chart)
                        const SizedBox(height: 12),

                      // Main Content Area
                      Expanded(
                        child:
                            _monthlyData.isEmpty
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
                                : _viewType == AnalyticsViewType.chart
                                ? (_chartType == 0
                                    ? _buildBarChart()
                                    : _buildLineChart())
                                : _buildListView(),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildChartTypeButton(String text, bool isSelected) {
    const primaryBlue = Color(0xFF1E88E5);
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? primaryBlue : Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          _chartType = text == 'Bar Chart' ? 0 : 1;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    final barGroups =
        _monthlyData.map((entry) {
          final rent = entry.value['rent'] ?? 0;
          final water = entry.value['water'] ?? 0;

          return BarChartGroupData(
            x: _monthlyData.indexOf(entry),
            barRods: [
              BarChartRodData(
                toY: rent,
                color: primaryBlue,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: water,
                color: accentYellow,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList();

    final months =
        _monthlyData.map((entry) {
          return _displayFormat.format(DateTime.parse('${entry.key}-01'));
        }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Rent & Water Bill Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor:
                          (BarChartGroupData group) => Colors.white,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final value = rod.toY;
                        final label = rodIndex == 0 ? 'Rent' : 'Water';
                        final color =
                            rodIndex == 0 ? primaryBlue : accentYellow;
                        return BarTooltipItem(
                          '$label: ${_currencyFormat.format(value)} UGX',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _currencyFormat.format(value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xffececec),
                      width: 1,
                    ),
                  ),
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(primaryBlue, 'Rent'),
                const SizedBox(width: 16),
                _buildLegendItem(accentYellow, 'Water'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    final rentSpots =
        _monthlyData.map((entry) {
          final index = _monthlyData.indexOf(entry);
          final rent = entry.value['rent'] ?? 0;
          return FlSpot(index.toDouble(), rent);
        }).toList();

    final waterSpots =
        _monthlyData.map((entry) {
          final index = _monthlyData.indexOf(entry);
          final water = entry.value['water'] ?? 0;
          return FlSpot(index.toDouble(), water);
        }).toList();

    final months =
        _monthlyData.map((entry) {
          return _displayFormat.format(DateTime.parse('${entry.key}-01'));
        }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Rent & Water Bill Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: _monthlyData.length > 0 ? _monthlyData.length - 1 : 0,
                  minY: 0,
                  maxY: _calculateMaxY(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot spot) => Colors.white,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final label = spot.barIndex == 0 ? 'Rent' : 'Water';
                          final color =
                              spot.barIndex == 0 ? primaryBlue : accentYellow;
                          return LineTooltipItem(
                            '$label: ${_currencyFormat.format(spot.y)} UGX',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _currencyFormat.format(value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Poppins',
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xffececec),
                      width: 1,
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: rentSpots,
                      isCurved: true,
                      color: primaryBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    LineChartBarData(
                      spots: waterSpots,
                      isCurved: true,
                      color: accentYellow,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accentYellow.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(primaryBlue, 'Rent'),
                const SizedBox(width: 16),
                _buildLegendItem(accentYellow, 'Water'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return ListView.builder(
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
                colors: [Colors.grey[100]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              leading: Icon(Icons.calendar_month, color: primaryBlue, size: 28),
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
                        Icon(Icons.water_drop, color: accentYellow, size: 20),
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
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
      ],
    );
  }

  double _calculateMaxY() {
    double maxValue = 0;
    for (var entry in _monthlyData) {
      final rent = entry.value['rent'] ?? 0;
      final water = entry.value['water'] ?? 0;
      if (rent > maxValue) maxValue = rent;
      if (water > maxValue) maxValue = water;
    }
    return (maxValue * 1.2).ceilToDouble();
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 500000) return 100000;
    if (maxY <= 1000000) return 200000;
    return 500000;
  }

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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
