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
      duration: const Duration(milliseconds: 2000),
    );
    
    // Create sequenced animations with different curve intervals
    _fadeAnimation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _fadeAnimation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _fadeAnimation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
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
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
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
              ..._buildAnimatedDecoration(screenWidth),
          
          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top spacer
                    SizedBox(height: screenHeight * 0.02),
                
                // Hero logo with shine effect
                    _buildAnimatedLogo(screenWidth),
                
                // Middle spacer
                    SizedBox(height: screenHeight * 0.02),
                
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
                              margin: EdgeInsets.only(top: screenHeight * 0.015),
                              width: screenWidth * 0.15,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        
                        Expanded(
                          child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
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
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                        "Welcome to HealthCare",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                                fontSize: screenWidth * 0.07,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF223A6A),
                                          height: 1.3,
                                        ),
                                      ),
                                          ),
                                          SizedBox(height: screenHeight * 0.02),
                                      Text(
                                        "Your comprehensive healthcare solution for appointments, consultations, and medical needs",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                              fontSize: screenWidth * 0.04,
                                          color: Colors.grey.shade700,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                    SizedBox(height: screenHeight * 0.05),
                                
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
                                        screenWidth: screenWidth,
                                        screenHeight: screenHeight,
                                  ),
                                ),
                                
                                    SizedBox(height: screenHeight * 0.016),
                                
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
                                        text: "Sign Up",
                                    onPressed: () => _navigateTo(context, SignUpOptions()),
                                        screenWidth: screenWidth,
                                        screenHeight: screenHeight,
                                  ),
                                ),
                                
                                    SizedBox(height: screenHeight * 0.016),
                                
                                    // Skip button with animation
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation3.value,
                                          child: Transform.translate(
                                            offset: Offset(0, 30 * (1 - _fadeAnimation3.value)),
                                      child: child,
                                          ),
                                        );
                                      },
                                      child: TextButton(
                                        onPressed: () {
                                          // Handle skip button press
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => SignIN()),
                                    );
                                  },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.05,
                                            vertical: screenHeight * 0.012,
                                          ),
                                        ),
                                  child: Text(
                                          "Skip for Now",
                                    style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.035,
                                            fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                    ),
                                    
                                    SizedBox(height: screenHeight * 0.03),
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
          );
        }
      ),
    );
  }
  
  List<Widget> _buildAnimatedDecoration(double screenWidth) {
    return [
      // Top right decoration
      Positioned(
        top: -screenWidth * 0.15,
        right: -screenWidth * 0.15,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _fadeAnimation1.value),
              child: Opacity(
                opacity: 0.7 * _fadeAnimation1.value,
              child: child,
              ),
            );
          },
          child: Container(
            width: screenWidth * 0.5,
            height: screenWidth * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9BBDF9),
                  Color(0xFF5C9DF2),
                ],
              ),
            ),
          ),
        ),
      ),
      
      // Bottom left decoration
      Positioned(
        bottom: screenWidth * 0.3,
        left: -screenWidth * 0.2,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _fadeAnimation2.value),
              child: Opacity(
                opacity: 0.5 * _fadeAnimation2.value,
              child: child,
              ),
            );
          },
          child: Container(
            width: screenWidth * 0.4,
            height: screenWidth * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA5D6FF),
                  Color(0xFF7FC2FF),
                ],
              ),
            ),
          ),
        ),
      ),
      
      // Floating elements
      ...List.generate(8, (index) {
        final size = (index % 3 + 1) * screenWidth * 0.015;
        final randomX = (index * 31 % 100) / 100.0;
        final randomY = (index * 23 % 100) / 100.0;
        final randomDelay = (index * 7 % 10) / 10.0;
        
      return Positioned(
          left: randomX * screenWidth,
          top: randomY * MediaQuery.of(context).size.height * 0.5,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
              // Calculate a floating animation
              final floatAnim = math.sin(
                (_animationController.value * 2 * math.pi) + (index * math.pi / 4)
              ) * 10;
              
              final delayedOpacity = _animationController.value < randomDelay
                  ? 0.0
                  : (_animationController.value - randomDelay) / (1 - randomDelay);
            
            return Transform.translate(
                offset: Offset(0, floatAnim),
              child: Opacity(
                  opacity: delayedOpacity.clamp(0.0, 0.7),
                child: child,
              ),
            );
          },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 2 == 0
                    ? Color(0xFF9BBDF9).withOpacity(0.7)
                    : Color(0xFFA5D6FF).withOpacity(0.7),
              ),
            ),
          ),
        );
      }),
    ];
  }
  
  Widget _buildAnimatedLogo(double screenWidth) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _fadeAnimation1.value),
          child: Opacity(
            opacity: _fadeAnimation1.value,
          child: child,
          ),
        );
            },
      child: Container(
        width: screenWidth * 0.4,
        height: screenWidth * 0.4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5C9DF2),
                  Color(0xFF3D7DDA),
                ],
              ).createShader(bounds);
            },
            child: Icon(
              Icons.medical_services_rounded,
              size: screenWidth * 0.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required double screenWidth,
    required double screenHeight,
  }) {
    return SizedBox(
        width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3D7DDA),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.018,
            ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
          elevation: 2,
        ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.042,
              fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    required double screenWidth,
    required double screenHeight,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF3D7DDA),
          side: BorderSide(color: Color(0xFF3D7DDA), width: 1.5),
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.018,
            ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.042,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(0.0, 0.1);
          var end = Offset.zero;
          var curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
            opacity: animation,
            child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 600),
      ),
    );
  }
}
