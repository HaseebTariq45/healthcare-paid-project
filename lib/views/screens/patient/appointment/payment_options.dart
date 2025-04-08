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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Amount
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3366FF).withOpacity(0.1),
                          Color(0xFF3366FF).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total Amount",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          fee,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3366FF),
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "Consultation with $doctor",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  _buildPaymentOption(
                    "JazzCash",
                    "Fast and secure mobile payments",
                    Color(0xFFBA0000),
                    "assets/images/jazzcash.png",
                    "JazzCash",
                    isImage: true,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // EasyPaisa Option with enhanced UI
                  _buildPaymentOption(
                    "EasyPaisa",
                    "Pakistan's leading payment solution",
                    Color(0xFF4CAF50),
                    "assets/images/easypaisa.png",
                    "EasyPaisa",
                    isImage: true,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Debit Card Option with enhanced UI
                  _buildPaymentOption(
                    "Debit Card",
                    "Pay securely with your bank card",
                    Color(0xFF3366CC),
                    LucideIcons.creditCard,
                    "Debit Card",
                    isImage: false,
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Enhanced Security Message
                  Container(
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
                                "Secure Payments",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Your transactions are protected with SSL encryption",
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
                  
                  SizedBox(height: 32),
                  
                  // Enhanced Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    Color color,
    dynamic icon,
    String value, {
    bool isImage = false,
  }) {
    bool isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? color.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 10 : 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isImage
                  ? Image.asset(
                      icon,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 32,
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
                      color: isSelected ? color : Colors.black87,
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
            if (isSelected)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    Color buttonColor;
    String buttonText;
    IconData buttonIcon;

    switch (_selectedPaymentMethod) {
      case "JazzCash":
        buttonColor = Color(0xFFBA0000);
        buttonText = "Pay with JazzCash";
        buttonIcon = LucideIcons.wallet;
        break;
      case "EasyPaisa":
        buttonColor = Color(0xFF4CAF50);
        buttonText = "Pay with EasyPaisa";
        buttonIcon = LucideIcons.wallet;
        break;
      case "Debit Card":
        buttonColor = Color(0xFF3366CC);
        buttonText = "Continue with Card";
        buttonIcon = LucideIcons.creditCard;
        break;
      default:
        buttonColor = Color(0xFFBA0000);
        buttonText = "Proceed to Payment";
        buttonIcon = LucideIcons.arrowRight;
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _proceedToNextScreen,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(buttonIcon, size: 20),
            SizedBox(width: 12),
            Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

