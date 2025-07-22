import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './client_login_screen.dart';
import 'utils/phone_validator.dart';

class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: Color(0xFF005800),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ClientLoginScreen()),
        );
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Design
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
                    const Color(0xFF005800).withOpacity(0.8),
                    const Color(0xFF005800).withOpacity(0.4),
                    const Color(0xFF005800).withOpacity(0.1),
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
                    const Color(0xFF0029B2).withOpacity(0.6),
                    const Color(0xFF0029B2).withOpacity(0.3),
                    const Color(0xFF0029B2).withOpacity(0.1),
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
                          SizedBox(height: screenHeight * 0.06),

                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFF005800),
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
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF005800,
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
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF005800),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Join our dental care family',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Registration Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name Fields Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        controller: _firstNameController,
                                        labelText: 'First Name',
                                        icon: Icons.person_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInputField(
                                        controller: _lastNameController,
                                        labelText: 'Last Name',
                                        icon: Icons.person_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Email Field
                                _buildInputField(
                                  controller: _emailController,
                                  labelText: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Phone Field
                                _buildInputField(
                                  controller: _phoneController,
                                  labelText: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: PhoneValidator.validatePhoneNumber,
                                  inputFormatters:
                                      PhoneValidator.getPhoneInputFormatters(),
                                  hintText: '09XX XXX XXXX',
                                  helperText:
                                      'Must start with 09 and be 11 digits',
                                ),

                                const SizedBox(height: 20),

                                // Password Field
                                _buildInputField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isPasswordVisible: _isPasswordVisible,
                                  onTogglePassword: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Confirm Password Field
                                _buildInputField(
                                  controller: _confirmPasswordController,
                                  labelText: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isPasswordVisible: _isConfirmPasswordVisible,
                                  onTogglePassword: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Terms and Conditions
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF005800),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(text: 'I agree to the '),
                                            TextSpan(
                                              text: 'Terms and Conditions',
                                              style: TextStyle(
                                                color: Color(0xFF005800),
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: Color(0xFF005800),
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // Register Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF005800),
                                        Color(0xFF0029B2),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF005800,
                                        ).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: _isLoading
                                          ? null
                                          : _handleRegistration,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ClientLoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF005800),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: screenHeight * 0.05),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onTogglePassword,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    String? helperText,
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
        keyboardType: keyboardType,
        obscureText: isPassword && !(isPasswordVisible ?? false),
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: const Color(0xFF005800)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isPasswordVisible ?? false)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hintText,
          helperText: helperText,
        ),
        validator: validator,
      ),
    );
  }
}
