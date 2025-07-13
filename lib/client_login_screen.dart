import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/patient.dart';
import 'user_state_manager.dart';
import './main_app_screen.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // Using static ApiService methods instead of instance

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _unitAssignmentController = TextEditingController();
  final _otherClassificationController = TextEditingController();

  String _selectedClassification = 'Military';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _serialNumberController.dispose();
    _unitAssignmentController.dispose();
    _otherClassificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Design with Brand Colors
          Positioned(
            top: -screenHeight * 0.1,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 1.2,
              height: screenWidth * 1.2,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [
                    const Color(0xFF0029B2).withOpacity(0.8),
                    const Color(0xFF0029B2).withOpacity(0.4),
                    const Color(0xFF0029B2).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -screenHeight * 0.05,
            right: -screenWidth * 0.25,
            child: Container(
              width: screenWidth * 0.8,
              height: screenWidth * 0.8,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.0,
                  colors: [
                    const Color(0xFF005800).withOpacity(0.6),
                    const Color(0xFF005800).withOpacity(0.3),
                    const Color(0xFF005800).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: screenHeight * 0.08),

                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFF0029B2),
                                size: 24,
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Logo and Title Section
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0029B2,
                                        ).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Image.asset(
                                      'assets/image/main_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _isLogin ? 'Welcome Back!' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000074),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLogin
                                      ? 'Sign in to access your dental care'
                                      : 'Join us for comprehensive dental care',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Toggle between Login and Register
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildToggleButton(
                                    'Login',
                                    _isLogin,
                                    () => setState(() => _isLogin = true),
                                  ),
                                ),
                                Expanded(
                                  child: _buildToggleButton(
                                    'Register',
                                    !_isLogin,
                                    () => setState(() => _isLogin = false),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Form Content
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Common fields (Email, Password)
                                _buildInputField(
                                  controller: _emailController,
                                  labelText: 'Email Address',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Email is required';
                                    }
                                    if (!value!.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                _buildInputField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF0029B2),
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Password is required';
                                    }
                                    if (!_isLogin && value!.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Registration-only fields
                                if (!_isLogin) ...[
                                  _buildInputField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirm Password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: const Color(0xFF0029B2),
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Personal Information
                                  _buildSectionTitle('Personal Information'),
                                  const SizedBox(height: 15),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInputField(
                                          controller: _firstNameController,
                                          labelText: 'First Name',
                                          prefixIcon: Icons.person_outline,
                                          validator: (value) =>
                                              value?.isEmpty ?? true
                                                  ? 'First name is required'
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildInputField(
                                          controller: _lastNameController,
                                          labelText: 'Last Name',
                                          prefixIcon: Icons.person,
                                          validator: (value) =>
                                              value?.isEmpty ?? true
                                                  ? 'Last name is required'
                                                  : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  _buildInputField(
                                    controller: _phoneController,
                                    labelText: 'Phone Number',
                                    prefixIcon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Phone number is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildDatePickerField(),
                                  const SizedBox(height: 16),

                                  _buildInputField(
                                    controller: _addressController,
                                    labelText: 'Address',
                                    prefixIcon: Icons.location_on_outlined,
                                    maxLines: 2,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Address is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  const SizedBox(height: 20),

                                  // Classification
                                  _buildSectionTitle('Classification'),
                                  const SizedBox(height: 15),

                                  _buildClassificationDropdown(),

                                  if (_selectedClassification != 'Others') ...[
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller: _serialNumberController,
                                      labelText: 'Serial Number',
                                      prefixIcon: Icons.badge_outlined,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Serial number is required'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller: _unitAssignmentController,
                                      labelText: 'Unit Assignment',
                                      prefixIcon: Icons.business_outlined,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Unit assignment is required'
                                              : null,
                                    ),
                                  ],

                                  if (_selectedClassification == 'Others') ...[
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      controller:
                                          _otherClassificationController,
                                      labelText:
                                          'Please specify your classification',
                                      prefixIcon: Icons.description_outlined,
                                      validator: (value) => value?.isEmpty ??
                                              true
                                          ? 'Please specify your classification'
                                          : null,
                                    ),
                                  ],

                                  const SizedBox(height: 30),
                                ],

                                // Submit Button
                                _buildSubmitButton(),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0029B2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
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
    required IconData prefixIcon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF0029B2)),
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedClassification,
        decoration: const InputDecoration(
          labelText: 'Classification',
          prefixIcon: Icon(Icons.category_outlined, color: Color(0xFF0029B2)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: classifications.map((classification) {
          return DropdownMenuItem<String>(
            value: classification,
            child: Text(classification),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedClassification = value ?? 'Military';
            if (_selectedClassification != 'Others') {
              _otherClassificationController.clear();
            } else {
              _serialNumberController.clear();
              _unitAssignmentController.clear();
            }
          });
        },
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0029B2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _handleSubmit,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLogin ? Icons.login : Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    bool isValid = _formKey.currentState?.validate() ?? false;

    // Additional validation for date picker when registering
    if (!_isLogin && _selectedDate == null) {
      isValid = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (isValid) {
      setState(() => _isLoading = true);

      try {
        if (_isLogin) {
          await _handleLogin();
        } else {
          await _handleRegistration();
        }
      } catch (e) {
        if (mounted) {
          // Parse error message to show user-friendly messages
          String errorMessage = _parseErrorMessage(e.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    final patientId = await ApiService.authenticatePatient(
      _emailController.text,
      _passwordController.text,
    );

    if (patientId != null) {
      // Get the patient data
      final patient = await ApiService.getPatient(patientId);
      if (patient != null) {
        UserStateManager().setCurrentPatient(patient);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainAppScreen()),
          );
        }
      } else {
        throw Exception('Failed to retrieve patient data');
      }
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> _handleRegistration() async {
    final patient = Patient(
      id: null, // Will be assigned by Firebase Authentication
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      passwordHash: '', // Will be hashed by database service
      dateOfBirth: _selectedDate!,
      address: _addressController.text,
      emergencyContact: '', // Optional field, now empty
      emergencyPhone: '', // Optional field, now empty
      serialNumber: _selectedClassification != 'Others'
          ? _serialNumberController.text
          : '',
      unitAssignment: _selectedClassification != 'Others'
          ? _unitAssignmentController.text
          : '',
      classification: _selectedClassification,
      otherClassification: _selectedClassification == 'Others'
          ? _otherClassificationController.text
          : '',
    );

    final patientId = await ApiService.registerPatient(
      patient,
      _passwordController.text,
    );

    // Get the created patient
    if (patientId != null) {
      final createdPatient = await ApiService.getPatient(patientId);
      if (createdPatient != null) {
        UserStateManager().setCurrentPatient(createdPatient);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainAppScreen()),
          );
        }
      } else {
        throw Exception('Failed to retrieve patient data after registration');
      }
    } else {
      throw Exception('Registration failed');
    }
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ??
                    DateTime.now().subtract(const Duration(days: 365 * 20)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0029B2),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF0029B2),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select your date of birth',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate != null
                                ? Colors.black
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'Date of birth is required',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  String _parseErrorMessage(String errorString) {
    // Clean up nested exception messages
    String cleanError = errorString;

    // Remove "Exception: " prefixes
    cleanError = cleanError.replaceAll(RegExp(r'Exception:\s*'), '');

    // Remove "Registration failed: " prefix
    cleanError = cleanError.replaceAll(RegExp(r'Registration failed:\s*'), '');

    // Handle specific error cases
    if (cleanError.toLowerCase().contains('email already registered')) {
      return 'This email address is already registered. Please use a different email or switch to Login mode to sign in.';
    }

    if (cleanError.toLowerCase().contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (cleanError.toLowerCase().contains('password')) {
      return 'Password must be at least 6 characters long.';
    }

    if (cleanError.toLowerCase().contains('phone')) {
      return 'Please enter a valid phone number.';
    }

    if (cleanError.toLowerCase().contains('network') ||
        cleanError.toLowerCase().contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (cleanError.toLowerCase().contains('invalid') &&
        cleanError.toLowerCase().contains('password')) {
      return 'Invalid email or password. Please check your credentials.';
    }

    // If no specific error pattern matches, return cleaned message
    return cleanError.isNotEmpty
        ? cleanError
        : 'An unexpected error occurred. Please try again.';
  }
}
