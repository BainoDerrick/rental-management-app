import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rental_management_app/models/tenant_model.dart';
import 'package:rental_management_app/services/database_service.dart';

class AddTenantScreen extends StatefulWidget {
  final Tenant? tenant;

  const AddTenantScreen({this.tenant, Key? key}) : super(key: key);

  @override
  _AddTenantScreenState createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _rentThresholdController = TextEditingController();
  bool _isSaving = false;
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    if (widget.tenant != null) {
      _nameController.text = widget.tenant!.name;
      _phoneController.text = widget.tenant!.phone;
      _houseNumberController.text = widget.tenant!.houseNumber;
      _rentThresholdController.text = widget.tenant!.rentThreshold.toString();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _houseNumberController.dispose();
    _rentThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final rawRent = _rentThresholdController.text.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final tenant = Tenant(
        id: widget.tenant?.id,
        name: _nameController.text,
        phone: _phoneController.text,
        houseNumber: _houseNumberController.text,
        rentThreshold: double.parse(rawRent),
        moveInDate: widget.tenant?.moveInDate ?? DateTime.now(),
      );

      if (tenant.id == null) {
        await _dbService.addTenant(tenant);
      } else {
        await _dbService.updateTenant(tenant);
      }

      _showSuccessSnackbar('Tenant saved successfully!');

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
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

  PreferredSizeWidget _buildAnimatedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF0D47A1), const Color(0xFF1E88E5)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.tenant == null
                                  ? 'Add New Tenant'
                                  : 'Edit Tenant',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.tenant == null
                                  ? 'Enter tenant details below'
                                  : 'Update existing tenant information',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 28,
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color darkBlue = Color(0xFF0D47A1);
    const Color accentYellow = Color(0xFFFFCA28);
    const Color lightYellow = Color(0xFFFFF8E1);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAnimatedAppBar(),
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
                    Colors.transparent,
                    Colors.white,
                    lightYellow.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.2, 1.0],
                ),
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        // Form Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[200]!,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                _buildFormField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  hintText: 'Enter tenant full name',
                                  icon: Icons.person_rounded,
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                  primaryBlue: primaryBlue,
                                ),
                                const SizedBox(height: 20),
                                _buildFormField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  hintText: 'Enter phone number',
                                  icon: Icons.phone_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Required';
                                    // Basic phone validation (can be enhanced with regex)
                                    if (!RegExp(
                                      r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
                                    ).hasMatch(value!)) {
                                      return 'Invalid phone number';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.phone,
                                  primaryBlue: primaryBlue,
                                ),
                                const SizedBox(height: 20),
                                _buildFormField(
                                  controller: _houseNumberController,
                                  label: 'House Number',
                                  hintText: 'Enter house/apartment number',
                                  icon: Icons.home_rounded,
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                  primaryBlue: primaryBlue,
                                ),
                                const SizedBox(height: 20),
                                _buildFormField(
                                  controller: _rentThresholdController,
                                  label: 'Monthly Rent (UGX)',
                                  hintText: 'e.g. 500,000',
                                  icon: Icons.attach_money_rounded,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Required';
                                    final rawValue = value!.replaceAll(
                                      RegExp(r'[^0-9.]'),
                                      '',
                                    );
                                    final amount = double.tryParse(rawValue);
                                    if (amount == null || amount <= 0) {
                                      return 'Invalid amount';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9,]'),
                                    ),
                                  ],
                                  prefixText: 'UGX ',
                                  primaryBlue: primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: 'Cancel',
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.grey[700]!,
                                borderColor: Colors.grey[400]!,
                                icon: Icons.close_rounded,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                label: _isSaving ? 'Saving...' : 'Save Tenant',
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                borderColor: primaryBlue,
                                icon:
                                    _isSaving
                                        ? null
                                        : Icons.check_circle_rounded,
                                isLoading: _isSaving,
                                onPressed: _isSaving ? null : _saveTenant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
    Color? primaryBlue,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey[500],
              ),
              prefixIcon: Container(
                width: 56,
                alignment: Alignment.center,
                child: Icon(icon, color: primaryBlue, size: 22),
              ),
              prefixText: prefixText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: foregroundColor, size: 20),
              if (icon != null || isLoading) const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlutterLibphonenumber {
  void parsePhoneNumber(String s, String t) {}
  init() {}
}
