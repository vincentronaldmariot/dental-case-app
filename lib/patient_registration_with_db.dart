import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'services/database_service.dart';
import 'models/patient.dart';
import 'user_state_manager.dart';
import 'main_app_screen.dart';

class PatientRegistrationWithDB extends StatefulWidget {
  final bool isLogin;

  const PatientRegistrationWithDB({super.key, this.isLogin = false});

  @override
  State<PatientRegistrationWithDB> createState() =>
      _PatientRegistrationWithDBState();
}

class _PatientRegistrationWithDBState extends State<PatientRegistrationWithDB> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _unitAssignmentController = TextEditingController();
  final _otherClassificationController = TextEditingController();

  String _selectedClassification = '';
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _dateOfBirthController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _serialNumberController.dispose();
    _unitAssignmentController.dispose();
    _otherClassificationController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password + 'dental_clinic_salt');
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // ~18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final patient = await _dbService.authenticatePatient(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (patient != null) {
        // Login successful
        UserStateManager().loginAsClient();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${patient.fullName}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainAppScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email already exists
      final existingPatient = await _dbService.getPatientByEmail(
        _emailController.text.trim(),
      );
      if (existingPatient != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email already registered. Please use a different email.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Create new patient
      final patient = Patient(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        passwordHash: _hashPassword(_passwordController.text),
        dateOfBirth: _selectedDate!,
        address: _addressController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        medicalHistory: _medicalHistoryController.text.trim(),
        allergies: _allergiesController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        unitAssignment: _unitAssignmentController.text.trim(),
        classification: _selectedClassification,
        otherClassification: _otherClassificationController.text.trim(),
      );

      // Save to database
      final patientId = await _dbService.createPatient(patient);

      // Registration successful
      UserStateManager().loginAsClient();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration successful! Welcome, ${patient.fullName}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainAppScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0029B2), Color(0xFF000074)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/image/main_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          widget.isLogin
                              ? 'PATIENT LOGIN\nDENTAL SERVICE CENTER'
                              : 'PATIENT REGISTRATION\nDENTAL SERVICE CENTER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isLogin) ...[
                        // Login Form
                        _buildLoginForm(),
                      ] else ...[
                        // Registration Form
                        _buildRegistrationForm(),
                      ],

                      const SizedBox(height: 30),

                      // Submit Button
                      _buildSubmitButton(),

                      const SizedBox(height: 20),

                      // Switch between login and registration
                      _buildSwitchButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000074),
          ),
        ),
        const SizedBox(height: 20),

        _buildInputField(
          controller: _emailController,
          labelText: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Email is required';
            if (!value!.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildPasswordField(
          controller: _passwordController,
          labelText: 'Password',
          isVisible: _passwordVisible,
          onVisibilityChanged: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Password is required' : null,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Your Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000074),
          ),
        ),
        const SizedBox(height: 20),

        // Classification
        _buildSectionTitle('Classification'),
        const SizedBox(height: 10),
        _buildClassificationDropdown(),

        if (_selectedClassification == 'Others') ...[
          const SizedBox(height: 16),
          _buildInputField(
            controller: _otherClassificationController,
            labelText: 'Please specify your classification',
            validator: (value) => value?.isEmpty ?? true
                ? 'Please specify your classification'
                : null,
          ),
        ],

        const SizedBox(height: 24),

        // Personal Information
        _buildSectionTitle('Personal Information'),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _firstNameController,
                labelText: 'First Name',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'First name is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _lastNameController,
                labelText: 'Last Name',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Last name is required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _emailController,
          labelText: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Email is required';
            if (!value!.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _phoneController,
          labelText: 'Phone Number',
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),

        // Date of Birth
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: _buildInputField(
              controller: _dateOfBirthController,
              labelText: 'Date of Birth',
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Date of birth is required' : null,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _addressController,
          labelText: 'Address',
          maxLines: 2,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Address is required' : null,
        ),
        const SizedBox(height: 16),

        // Emergency Contact
        _buildSectionTitle('Emergency Contact'),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _emergencyContactController,
          labelText: 'Emergency Contact Name',
          validator: (value) =>
              value?.isEmpty ?? true ? 'Emergency contact is required' : null,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _emergencyPhoneController,
          labelText: 'Emergency Phone Number',
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Emergency phone is required' : null,
        ),
        const SizedBox(height: 16),

        // Military Information (if applicable)
        if (_selectedClassification != 'Others') ...[
          _buildSectionTitle('Military Information'),
          const SizedBox(height: 16),

          _buildInputField(
            controller: _serialNumberController,
            labelText: 'Serial Number',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Serial number is required' : null,
          ),
          const SizedBox(height: 16),

          _buildInputField(
            controller: _unitAssignmentController,
            labelText: 'Unit Assignment',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Unit assignment is required' : null,
          ),
          const SizedBox(height: 16),
        ],

        // Medical Information
        _buildSectionTitle('Medical Information'),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _medicalHistoryController,
          labelText: 'Medical History (Optional)',
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: _allergiesController,
          labelText: 'Allergies (Optional)',
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Password
        _buildSectionTitle('Account Security'),
        const SizedBox(height: 16),

        _buildPasswordField(
          controller: _passwordController,
          labelText: 'Password',
          isVisible: _passwordVisible,
          onVisibilityChanged: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Password is required';
            if (value!.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildPasswordField(
          controller: _confirmPasswordController,
          labelText: 'Confirm Password',
          isVisible: _confirmPasswordVisible,
          onVisibilityChanged: () => setState(
            () => _confirmPasswordVisible = !_confirmPasswordVisible,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please confirm your password';
            if (value != _passwordController.text)
              return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000074),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
            ),
            onPressed: onVisibilityChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationDropdown() {
    final classifications = ['Military', 'AD/HR', 'Department', 'Others'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedClassification.isEmpty ? null : _selectedClassification,
        decoration: InputDecoration(
          labelText: 'Select Classification',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: classifications.map((classification) {
          return DropdownMenuItem<String>(
            value: classification,
            child: Text(classification),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedClassification = value ?? '';
            if (_selectedClassification != 'Others') {
              _otherClassificationController.clear();
            }
          });
        },
        validator: (value) =>
            value == null ? 'Please select classification' : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0029B2), Color(0xFF000074)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading
              ? null
              : (widget.isLogin ? _handleLogin : _handleRegistration),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.isLogin ? 'Login' : 'Register',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  PatientRegistrationWithDB(isLogin: !widget.isLogin),
            ),
          );
        },
        child: Text(
          widget.isLogin
              ? "Don't have an account? Register here"
              : "Already have an account? Login here",
          style: const TextStyle(
            color: Color(0xFF0029B2),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
