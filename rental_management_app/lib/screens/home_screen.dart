import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:rental_management_app/main.dart';
import 'package:rental_management_app/models/tenant_model.dart';
import 'package:rental_management_app/screens/add_tenant_screen.dart';
import 'package:rental_management_app/screens/analytics_screen.dart';
import 'package:rental_management_app/screens/payment_screen.dart';
import 'package:rental_management_app/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  List<Tenant> _tenants = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _notificationsSent = false;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreTenants();
      }
    });
  }

  Future<void> _loadMoreTenants() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final tenantStream = _dbService.getTenants(startAfter: _lastDocument);
      final result = await tenantStream.first;
      final newTenants = result.$1;
      final lastDoc = result.$2;

      setState(() {
        _tenants.addAll(newTenants);
        _lastDocument = lastDoc;
        _hasMore = newTenants.length == 20;
        _isLoadingMore = false;
      });

      if (!_notificationsSent) {
        _checkForOverduePayments(newTenants);
        _notificationsSent = true;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading tenants: $e',
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFFFFCA28),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _checkForOverduePayments(List<Tenant> tenants) async {
    final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
    for (var tenant in tenants) {
      final balance = await _dbService.getRentBalance(tenant.id!, currentMonthYear);
      if (balance > 0) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'overdue_channel',
          'Overdue Payments',
          importance: Importance.max,
          priority: Priority.high,
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
        );

        await flutterLocalNotificationsPlugin.show(
          tenant.id.hashCode,
          'Overdue Payment',
          '${tenant.name} has an overdue balance of ${_currencyFormat.format(balance)} UGX for $currentMonthYear',
          platformChannelSpecifics,
        );
      }
    }
  }

  Future<void> _deleteTenant(String tenantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Delete Tenant?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 96, 156, 209),
          ),
        ),
        content: const Text(
          'This action will also delete all associated payments and cannot be undone.',
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
      await _dbService.deleteTenant(tenantId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tenant deleted successfully',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFF1E88E5),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tenants',
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
          _buildIconButton(
            icon: Icons.analytics,
            tooltip: 'View Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen()),
              );
            },
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
        child: StreamBuilder<(List<Tenant>, DocumentSnapshot?)>(
          stream: _dbService.getTenants(startAfter: null),
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
            if (snapshot.connectionState == ConnectionState.waiting && _tenants.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              );
            }

            _tenants = snapshot.data?.$1 ?? [];
            _lastDocument = snapshot.data?.$2;
            _hasMore = _tenants.length == 20;

            return FutureBuilder<List<double>>(
              future: Future.wait(
                _tenants.map((tenant) => _dbService.getRentBalance(tenant.id!, currentMonthYear)),
              ),
              builder: (context, balanceSnapshot) {
                if (balanceSnapshot.connectionState == ConnectionState.waiting && _tenants.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                  );
                }

                final balances = balanceSnapshot.data ?? List.filled(_tenants.length, 0.0);
                final totalRent = _tenants.fold(0.0, (sum, tenant) => sum + tenant.rentThreshold);
                final totalOverdue = balances.fold(0.0, (sum, balance) => sum + (balance > 0 ? balance : 0));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Card(
                        elevation: 8.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        color: primaryBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tenants: ${_tenants.length}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                                        'Total Rent: ${_currencyFormat.format(totalRent)} UGX',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: accentYellow,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Overdue: ${_currencyFormat.format(totalOverdue)} UGX',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          color: accentYellow,
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
                    ),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue, accentYellow],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _tenants.isEmpty
                          ? Center(
                              child: Text(
                                'No tenants found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              itemCount: _tenants.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _tenants.length) {
                                  _loadMoreTenants();
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                    ),
                                  );
                                }
                                final tenant = _tenants[index];
                                final balance = index < balances.length ? balances[index] : 0.0;
                                return Card(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      leading: Icon(
                                        Icons.person,
                                        color: primaryBlue,
                                        size: 28,
                                      ),
                                      title: Text(
                                        tenant.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.home,
                                              color: Colors.grey[600],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'House: ${tenant.houseNumber}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${_currencyFormat.format(tenant.rentThreshold)} UGX',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              if (balance > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                                  margin: const EdgeInsets.only(top: 4.0),
                                                  decoration: BoxDecoration(
                                                    color: accentYellow.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  child: Text(
                                                    'Due: ${_currencyFormat.format(balance)} UGX',
                                                    style: TextStyle(
                                                      color: accentYellow,
                                                      fontSize: 12,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey[600],
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AddTenantScreen(tenant: tenant),
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                _deleteTenant(tenant.id!);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: primaryBlue,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: primaryBlue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PaymentScreen(tenant: tenant),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTenantScreen()),
          );
        },
        backgroundColor: primaryBlue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        elevation: 8.0,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
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