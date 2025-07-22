import 'package:flutter/material.dart';
import './unified_login_screen.dart';

class NextScreen extends StatefulWidget {
  const NextScreen({super.key});

  @override
  State<NextScreen> createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Light grey background
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: ClipPath(
              clipper: BlobClipper(),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        PositionedBlob(
                          color: const Color(0xFFF8AFA6), // Salmon Pink
                          controller: _controller,
                          start: 0.0,
                          size: 0.6,
                          x: 0.2,
                          y: 0.1,
                        ),
                        PositionedBlob(
                          color: const Color(0xFF7A577A), // Deep Purple
                          controller: _controller,
                          start: 0.2,
                          size: 0.8,
                          x: 0.5,
                          y: 0.5,
                        ),
                        PositionedBlob(
                          color: const Color(0xFFF3D68A), // Mustard Yellow
                          controller: _controller,
                          start: 0.5,
                          size: 0.7,
                          x: 0.9,
                          y: 0.2,
                        ),
                        // Back button positioned at upper left corner
                        Positioned(
                          top: 16,
                          left: 16,
                          child: SafeArea(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Welcome text centered
                        Positioned(
                          top: 120,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background logo with opacity
                                Container(
                                  width: 200,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Opacity(
                                    opacity: 0.15,
                                    child: Image.asset(
                                      'assets/image/main_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                // Welcome text container
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Welcome',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 10,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0029B2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UnifiedLoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PositionedBlob extends StatelessWidget {
  final Color color;
  final AnimationController controller;
  final double start;
  final double size;
  final double x;
  final double y;

  const PositionedBlob({
    super.key,
    required this.color,
    required this.controller,
    required this.start,
    required this.size,
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, start + 0.5, curve: Curves.easeInOut),
    );
    return Positioned(
      top: y * screenSize.height / 3 * (1 + (animation.value - 0.5) * 0.2),
      left: x * screenSize.width / 2 * (1 + (animation.value - 0.5) * 0.2),
      child: Container(
        width: screenSize.width * size,
        height: screenSize.width * size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
