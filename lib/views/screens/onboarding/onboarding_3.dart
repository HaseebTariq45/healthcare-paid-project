import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/common/signin.dart';
import 'package:healthcare/views/screens/onboarding/signupoptions.dart';
import 'dart:math' as math;

class Onboarding3 extends StatefulWidget {
  const Onboarding3({super.key});

  @override
  State<Onboarding3> createState() => _Onboarding3State();
}

class _Onboarding3State extends State<Onboarding3> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation1;
  late Animation<double> _fadeAnimation2;
  late Animation<double> _fadeAnimation3;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Create sequenced animations with different curve intervals instead of delays
    _fadeAnimation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    _fadeAnimation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );
    
    _fadeAnimation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE1EDFF),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          // Animated decoration elements
          ..._buildAnimatedDecoration(),
          
          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top spacer
                SizedBox(height: size.height * 0.02),
                
                // Hero logo with shine effect
                _buildAnimatedLogo(),
                
                // Middle spacer
                SizedBox(height: size.height * 0.02),
                
                // Content container with welcome text and buttons
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: EdgeInsets.only(top: 15),
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Welcome title with animation
                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutQuart,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        "Welcome to HealthCare",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF223A6A),
                                          height: 1.3,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        "Your comprehensive healthcare solution for appointments, consultations, and medical needs",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: 50),
                                
                                // Sign In button with animation - primary button
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation1.value,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - _fadeAnimation1.value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildPrimaryButton(
                                    text: "Sign In",
                                    onPressed: () => _navigateTo(context, SignIN()),
                                  ),
                                ),
                                
                                SizedBox(height: 16),
                                
                                // Sign Up button with animation - secondary button
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation2.value,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - _fadeAnimation2.value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildSecondaryButton(
                                    text: "Create Account",
                                    onPressed: () => _navigateTo(context, SignUpOptions()),
                                  ),
                                ),
                                
                                SizedBox(height: 40),
                                
                                // Terms & Privacy text
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation3.value,
                                      child: child,
                                    );
                                  },
                                  child: Text(
                                    "By continuing, you agree to our Terms of Service & Privacy Policy",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }
  
  // Animated floating decorative elements
  List<Widget> _buildAnimatedDecoration() {
    return [
      // Top right blob
      Positioned(
        top: -50,
        right: -30,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animationController.value * 2 * math.pi,
              child: child,
            );
          },
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0x303366CC),
                  Color(0x103366CC),
                ],
                radius: 0.8,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
      
      // Middle left blob
      Positioned(
        top: MediaQuery.of(context).size.height * 0.2,
        left: -70,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                10 * math.sin(_animationController.value * 2 * math.pi), 
                10 * math.cos(_animationController.value * 2 * math.pi)
              ),
              child: child,
            );
          },
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0x304F80E1),
                  Color(0x104F80E1),
                ],
                radius: 0.8,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
      
      // Bottom right blob
      Positioned(
        right: -30,
        bottom: MediaQuery.of(context).size.height * 0.45,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + 0.1 * math.sin(_animationController.value * 2 * math.pi),
              child: child,
            );
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0x20223A6A),
                  Color(0x05223A6A),
                ],
                radius: 0.8,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
      
      // Small medical-themed icons scattered around
      ..._buildFloatingIcons(),
    ];
  }
  
  // Floating medical-themed icons with animation
  List<Widget> _buildFloatingIcons() {
    final List<Map<String, dynamic>> icons = [
      {
        'icon': 'assets/images/capsules.png',
        'top': 100.0,
        'left': 40.0,
        'size': 30.0,
        'phase': 0.0,
      },
      {
        'icon': 'assets/images/sethoscope.png',
        'top': 200.0,
        'right': 40.0,
        'size': 34.0,
        'phase': 0.3,
      },
      {
        'icon': 'assets/images/tablets.png',
        'bottom': 320.0,
        'left': 50.0,
        'size': 28.0,
        'phase': 0.6,
      },
      {
        'icon': 'assets/images/bandage.png',
        'bottom': 350.0,
        'right': 30.0,
        'size': 32.0,
        'phase': 0.9,
      },
    ];
    
    return icons.map((icon) {
      return Positioned(
        top: icon['top'],
        left: icon['left'],
        right: icon['right'],
        bottom: icon['bottom'],
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final double offset = 10.0;
            final double phase = icon['phase'];
            
            return Transform.translate(
              offset: Offset(
                offset * math.sin((_animationController.value + phase) * 2 * math.pi),
                offset * math.cos((_animationController.value + phase) * 2 * math.pi),
              ),
              child: Opacity(
                opacity: 0.7,
                child: child,
              ),
            );
          },
          child: Image.asset(
            icon['icon'],
            width: icon['size'],
            height: icon['size'],
          ),
        ),
      );
    }).toList();
  }
  
  // Animated logo with shine effect
  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Logo container
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x304F80E1),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Image.asset(
              "assets/images/logo.png",
              height: 80,
            ),
          ),
          
          // Animated shine effect
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned.fill(
                child: Transform.rotate(
                  angle: _animationController.value * 2 * math.pi,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: [0.0, 0.1, 0.3],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Primary button style
  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3366CC), Color(0xFF4F80E1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3366CC).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
  
  // Secondary button style
  Widget _buildSecondaryButton({required String text, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      splashColor: Color(0xFF3366CC).withOpacity(0.1),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Color(0xFF3366CC).withOpacity(0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Color(0xFF3366CC),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method for navigation
  void _navigateTo(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => destination,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }
}
