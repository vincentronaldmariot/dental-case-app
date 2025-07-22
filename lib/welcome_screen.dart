import 'package:flutter/material.dart';
import './unified_login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Gentle floating animation for logo
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
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
          // First circle (background) - Enhanced with better gradients
          Positioned(
            top: -screenHeight * 0.15,
            left: -screenWidth * 0.25,
            child: Container(
              width: screenWidth * 1.4,
              height: screenWidth * 1.4,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF0029B2).withOpacity(0.95),
                    const Color(0xFF0029B2).withOpacity(0.75),
                    const Color(0xFF0029B2).withOpacity(0.45),
                    const Color(0xFF0029B2).withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0029B2).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 8,
                    offset: const Offset(10, 15),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0029B2).withOpacity(0.15),
                    blurRadius: 60,
                    spreadRadius: 15,
                    offset: const Offset(20, 25),
                  ),
                ],
              ),
            ),
          ),
          // Second circle (middle) - Enhanced
          Positioned(
            top: -screenHeight * 0.1,
            left: -screenWidth * 0.1,
            child: Container(
              width: screenWidth * 1.3,
              height: screenWidth * 1.3,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    const Color(0xFF000074).withOpacity(0.9),
                    const Color(0xFF000074).withOpacity(0.65),
                    const Color(0xFF000074).withOpacity(0.35),
                    const Color(0xFF000074).withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000074).withOpacity(0.5),
                    blurRadius: 35,
                    spreadRadius: 5,
                    offset: const Offset(5, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFF000074).withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 12,
                    offset: const Offset(15, 20),
                  ),
                ],
              ),
            ),
          ),
          // Third circle (foreground) - Enhanced
          Positioned(
            top: -screenHeight * 0.05,
            right: -screenWidth * 0.3,
            child: Container(
              width: screenWidth * 1.2,
              height: screenWidth * 1.2,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.1,
                  colors: [
                    const Color(0xFF005800).withOpacity(0.95),
                    const Color(0xFF005800).withOpacity(0.7),
                    const Color(0xFF005800).withOpacity(0.4),
                    const Color(0xFF005800).withOpacity(0.08),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF005800).withOpacity(0.45),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(-5, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF005800).withOpacity(0.18),
                    blurRadius: 45,
                    spreadRadius: 10,
                    offset: const Offset(-10, 18),
                  ),
                ],
              ),
            ),
          ),

          // Floating animated logo
          Positioned(
            top: screenHeight * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0029B2).withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset(
                            'assets/image/main_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom section with enhanced styling
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Enhanced welcome text
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1a1a1a),
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Color(0xFF0029B2),
                              offset: Offset(0, 0),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Let\'s get started.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(flex: 3),

                      // Enhanced continue button
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4A148C),
                              Color(0xFF7B1FA2),
                              Color(0xFF9C27B0),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(29),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B1FA2).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(29),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UnifiedLoginScreen(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(29),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'TAP TO CONTINUE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
