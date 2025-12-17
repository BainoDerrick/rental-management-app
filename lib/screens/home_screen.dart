import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:rental_management_app/models/tenant_model.dart';
import 'package:rental_management_app/screens/add_tenant_screen.dart';
import 'package:rental_management_app/screens/analytics_screen.dart';
import 'package:rental_management_app/screens/payment_screen.dart';
import 'package:rental_management_app/services/database_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  List<Tenant> _tenants = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _notificationsSent = false;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _gradientAnimation = ColorTween(
      begin: const Color(0xFF0D47A1),
      end: const Color(0xFF1E88E5),
    ).animate(_animationController);

    _animationController.forward();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreTenants();
      }
    });
    _initializeNotifications();
    _scheduleDailyCheck();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> _scheduleDailyCheck() async {
    final location = tz.getLocation('Africa/Nairobi');
    final now = tz.TZDateTime.now(location);
    final scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      9,
    ).add(const Duration(days: 1));

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Payment Reminder',
      'Check for unpaid tenants for this month.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_channel',
          'Payment Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'payment_reminder',
    );
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
      _showErrorSnackbar('Error loading tenants: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _checkForOverduePayments(List<Tenant> tenants) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    for (var tenant in tenants) {
      final payments = await _dbService.getPaymentsByTenant(tenant.id!);
      bool paidThisMonth = payments.any((payment) {
        final paymentDate = payment.createdAt.toDate();
        return paymentDate.year == currentMonth.year &&
            paymentDate.month == currentMonth.month;
      });

      if (!paidThisMonth) {
        await _showNotification(tenant.name, currentMonth);
      }
    }
  }

  Future<void> _showNotification(
    String tenantName,
    DateTime currentMonth,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'payment_channel',
          'Payment Reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      tenantName.hashCode,
      'Unpaid Rent Alert',
      '$tenantName has not paid for ${DateFormat('MMMM yyyy').format(currentMonth)}',
      platformChannelSpecifics,
      payload: 'unpaid_reminder_$tenantName',
    );
  }

  Future<void> _deleteTenant(String tenantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(),
    );

    if (confirmed == true) {
      await _dbService.deleteTenant(tenantId);
      _showSuccessSnackbar('Tenant deleted successfully');
    }
  }

  Widget _buildDeleteDialog() {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF44336).withOpacity(0.1),
                    const Color(0xFFF44336).withOpacity(0.2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFF44336),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Tenant?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will permanently delete the tenant and all associated payment records. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF1E88E5),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFFF44336),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          return AppBar(
            title: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    'Tenant Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
            backgroundColor: _gradientAnimation.value,
            elevation: 0,
            centerTitle: true,
            leading: Builder(
              builder:
                  (context) => IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
            actions: [_buildAnalyticsButton()],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const AnalyticsScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color darkBlue = Color(0xFF0D47A1);
    const Color accentYellow = Color(0xFFFFCA28);
    const Color lightYellow = Color(0xFFFFF8E1);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAnimatedAppBar(),
      drawer: _buildDrawer(primaryBlue, darkBlue),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    darkBlue.withOpacity(0.05),
                    Colors.white,
                    lightYellow.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: StreamBuilder<(List<Tenant>, DocumentSnapshot?)>(
                stream: _dbService.getTenants(startAfter: null),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading data',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _tenants.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryBlue,
                            ),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading tenants...',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  _tenants = snapshot.data?.$1 ?? [];
                  _lastDocument = snapshot.data?.$2;
                  _hasMore = _tenants.length == 20;

                  return FutureBuilder<List<double>>(
                    future: Future.wait(
                      _tenants.map(
                        (tenant) => _dbService.getRentBalance(
                          tenant.id!,
                          currentMonthYear,
                        ),
                      ),
                    ),
                    builder: (context, balanceSnapshot) {
                      if (balanceSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          _tenants.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryBlue,
                            ),
                          ),
                        );
                      }

                      final balances =
                          balanceSnapshot.data ??
                          List.filled(_tenants.length, 0.0);
                      final totalRent = _tenants.fold(
                        0.0,
                        (sum, tenant) => sum + tenant.rentThreshold,
                      );
                      final totalOverdue = balances.fold(
                        0.0,
                        (sum, balance) => sum + (balance > 0 ? balance : 0),
                      );

                      return Column(
                        children: [
                          _buildStatsCard(
                            totalRent,
                            totalOverdue,
                            primaryBlue,
                            accentYellow,
                          ),
                          _buildTenantList(balances, primaryBlue, accentYellow),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildAddTenantFAB(primaryBlue),
    );
  }

  Widget _buildDrawer(Color primaryBlue, Color darkBlue) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [darkBlue, primaryBlue],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Navigate your dashboard',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_add_rounded,
                    title: 'Add Tenant',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTenantScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment_rounded,
                    title: 'Payment',
                    onTap: () {
                      Navigator.pop(context);
                      if (_tenants.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PaymentScreen(tenant: _tenants[0]),
                          ),
                        );
                      }
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    title: 'Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 40, thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_rounded,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color:
            isSelected
                ? const Color(0xFF1E88E5).withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected ? const Color(0xFF1E88E5) : Colors.grey[700],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected ? const Color(0xFF1E88E5) : Colors.grey[700],
                  ),
                ),
                if (isSelected)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    double totalRent,
    double totalOverdue,
    Color primaryBlue,
    Color accentYellow,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Tenants',
                  value: _tenants.length.toString(),
                  color: primaryBlue,
                ),
                Container(height: 40, width: 1, color: Colors.grey[200]),
                _buildStatItem(
                  icon: Icons.monetization_on_rounded,
                  label: 'Total Rent',
                  value: '${_currencyFormat.format(totalRent)} UGX',
                  color: const Color(0xFF4CAF50),
                ),
                Container(height: 40, width: 1, color: Colors.grey[200]),
                _buildStatItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Overdue',
                  value: '${_currencyFormat.format(totalOverdue)} UGX',
                  color: accentYellow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantList(
    List<double> balances,
    Color primaryBlue,
    Color accentYellow,
  ) {
    return Expanded(
      child:
          _tenants.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tenants found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first tenant to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tenants.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _tenants.length) {
                    _loadMoreTenants();
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryBlue,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final tenant = _tenants[index];
                  final balance =
                      index < balances.length ? balances[index] : 0.0;
                  return _buildTenantCard(
                    tenant,
                    balance,
                    primaryBlue,
                    accentYellow,
                  );
                },
              ),
    );
  }

  Widget _buildTenantCard(
    Tenant tenant,
    double balance,
    Color primaryBlue,
    Color accentYellow,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        PaymentScreen(tenant: tenant),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.1),
                          primaryBlue.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                tenant.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (balance > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: accentYellow.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Due',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: accentYellow,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.home_rounded,
                              color: Colors.grey[500],
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'House ${tenant.houseNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              color: Colors.grey[500],
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_currencyFormat.format(tenant.rentThreshold)} UGX/month',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        if (balance > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentYellow.withOpacity(0.1),
                                  accentYellow.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: accentYellow,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Due: ${_currencyFormat.format(balance)} UGX',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: accentYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTenantActions(tenant, primaryBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantActions(Tenant tenant, Color primaryBlue) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
        ),
        child: Icon(Icons.more_vert_rounded, color: Colors.grey[600], size: 20),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      AddTenantScreen(tenant: tenant),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else if (value == 'delete') {
          _deleteTenant(tenant.id!);
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, color: primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildAddTenantFAB(Color primaryBlue) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    const AddTenantScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [primaryBlue, const Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

extension on DatabaseService {
  getPaymentsByTenant(String s) {}
}
