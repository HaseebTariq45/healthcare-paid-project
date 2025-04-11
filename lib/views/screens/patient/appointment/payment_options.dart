import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/card_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/easypaisa_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/jazzcash_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/saved_cards.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;
  
  const PaymentMethodScreen({
    super.key,
    this.appointmentDetails,
  });

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> with SingleTickerProviderStateMixin {
  String _selectedPaymentMethod = "JazzCash";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
    
    // Preload images
    precacheImage(AssetImage("assets/images/jazzcash.png"), context);
    precacheImage(AssetImage("assets/images/easypaisa.png"), context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _proceedToNextScreen() {
    switch (_selectedPaymentMethod) {
      case "JazzCash":
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => JazzCashPaymentScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
        ),
      );
        break;
      case "EasyPaisa":
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EasypaisaPaymentScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
          ),
        );
        break;
      case "Debit Card":
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SavedCardsScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
        ),
      );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the appropriate fee from appointment details
    String fee = widget.appointmentDetails != null && widget.appointmentDetails!.containsKey('fee') 
        ? widget.appointmentDetails!['fee'] 
        : 'Rs. 2,000';
    
    String doctor = widget.appointmentDetails != null && widget.appointmentDetails!.containsKey('doctor') 
        ? widget.appointmentDetails!['doctor'] 
        : 'Doctor';

    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Payment Method"),
      backgroundColor: Colors.white,
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Amount
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              key: _cardKey,
                              width: double.infinity,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2B8FEB).withOpacity(0.2),
                                    Color(0xFF2B8FEB).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF2B8FEB).withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Total Amount",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.8, end: 1.0),
                                    duration: Duration(milliseconds: 600),
                                    curve: Curves.easeOutBack,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Text(
                                          fee,
                                          style: GoogleFonts.poppins(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2B8FEB),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.stethoscope,
                                          color: Color(0xFF2B8FEB),
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            "Consultation with $doctor",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 32),
                      
                      Text(
                        "Select Payment Method",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // JazzCash Option with enhanced UI
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildPaymentOption(
                                "JazzCash",
                                "Fast and secure mobile payments",
                                Color(0xFFBA0000),
                                "assets/images/jazzcash.png",
                                "JazzCash",
                                isImage: true,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // EasyPaisa Option with enhanced UI
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildPaymentOption(
                                "EasyPaisa",
                                "Pakistan's leading payment solution",
                                Color(0xFF4CAF50),
                                "assets/images/easypaisa.png",
                                "EasyPaisa",
                                isImage: true,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Debit Card Option with enhanced UI
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildPaymentOption(
                                "Debit Card",
                                "Pay securely with your bank card",
                                Color(0xFF2B8FEB),
                                LucideIcons.creditCard,
                                "Debit Card",
                                isImage: false,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Enhanced Security Message
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.shield,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Secure Payment",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Your payment details are encrypted and protected",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 32),

                      // Enhanced Submit Button
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF2B8FEB).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.9, end: 1.0),
                                  duration: Duration(milliseconds: 200),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: ElevatedButton(
                                        onPressed: _proceedToNextScreen,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF2B8FEB),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            getPaymentMethodIcon(),
                                            SizedBox(width: 12),
                                            Text(
                                              "Pay with $_selectedPaymentMethod",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, Color color, dynamic icon, String value, {required bool isImage}) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isImage
                  ? Image.asset(
                      icon,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          value == "JazzCash" ? Icons.wallet : Icons.account_balance_wallet,
                          color: color,
                          size: 30,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 30,
                    ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getPaymentMethodIcon() {
    switch (_selectedPaymentMethod) {
      case "JazzCash":
        return Container(
          width: 24,
          height: 24,
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            "assets/images/jazzcash.png",
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.wallet,
                color: Color(0xFFBA0000),
                size: 16,
              );
            },
          ),
        );
      case "EasyPaisa":
        return Container(
          width: 24,
          height: 24,
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            "assets/images/easypaisa.png",
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF4CAF50),
                size: 16,
              );
            },
          ),
        );
      case "Debit Card":
        return Icon(
          LucideIcons.creditCard,
          color: Colors.white,
          size: 20,
        );
      default:
        return Icon(
          LucideIcons.creditCard,
          color: Colors.white,
          size: 20,
        );
    }
  }
}

