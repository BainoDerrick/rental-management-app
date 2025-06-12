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

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _rentThresholdController = TextEditingController();
  bool _isSaving = false;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      _nameController.text = widget.tenant!.name;
      _phoneController.text = widget.tenant!.phone;
      _houseNumberController.text = widget.tenant!.houseNumber;
      _rentThresholdController.text = widget.tenant!.rentThreshold.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define theme colors
    const primaryBlue = Color(0xFF1E88E5); // A modern blue
    const accentYellow = Color(0xFFFFCA28); // A vibrant yellow

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tenant == null ? 'Add Tenant' : 'Edit Tenant',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Wrap form fields in a Card for a modern look
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
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: primaryBlue,
                                width: 2.0,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: primaryBlue,
                                width: 2.0,
                              ),
                            ),
                            errorStyle: TextStyle(
                              color: accentYellow,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            try {
                              FlutterLibphonenumber().parsePhoneNumber(value!, 'UG');
                              return null;
                            } catch (e) {
                              return 'Invalid phone number';
                            }
                          },
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),

                        // House Number Field
                        TextFormField(
                          controller: _houseNumberController,
                          decoration: InputDecoration(
                            labelText: 'House Number',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.home,
                              color: primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: primaryBlue,
                                width: 2.0,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Rent Threshold Field
                        TextFormField(
                          controller: _rentThresholdController,
                          decoration: InputDecoration(
                            labelText: 'Rent Threshold (UGX)',
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.money,
                              color: primaryBlue,
                            ),
                            hintText: 'e.g. 500000 or 500,000',
                            hintStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                color: primaryBlue,
                                width: 2.0,
                              ),
                            ),
                            errorStyle: TextStyle(
                              color: accentYellow,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            final rawValue =
                                value!.replaceAll(RegExp(r'[^0-9.]'), '');
                            final amount = double.tryParse(rawValue);
                            if (amount == null || amount <= 0) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel Button
                    _buildAnimatedButton(
                      label: 'Cancel',
                      color: accentYellow,
                      textColor: Colors.black87,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 20),
                    // Save Button
                    _isSaving
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                          )
                        : _buildAnimatedButton(
                            label: 'Save',
                            color: primaryBlue,
                            textColor: Colors.white,
                            onPressed: _saveTenant,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final rawRent = _rentThresholdController.text.replaceAll(RegExp(r'[^0-9.]'), '');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tenant saved successfully!',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFF1E88E5), // primaryBlue
          duration: const Duration(seconds: 2),
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: const Color(0xFFFFCA28), // accentYellow
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Helper method to build animated buttons
  Widget _buildAnimatedButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onPressed,
          child: Container(
            width: 150,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseNumberController.dispose();
    _rentThresholdController.dispose();
    super.dispose();
  }
}

class FlutterLibphonenumber {
  void parsePhoneNumber(String s, String t) {}

  init() {}
}