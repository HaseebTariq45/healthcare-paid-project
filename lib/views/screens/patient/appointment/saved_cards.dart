import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/card_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/patient/dashboard/finance.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/utils/patient_navigation_helper.dart';

class SavedCardsScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;
  
  const SavedCardsScreen({
    super.key,
    this.appointmentDetails,
  });

  @override
  _SavedCardsScreenState createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> savedCards = [];
  int _selectedCardIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    setState(() => _isLoading = true);
    
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        savedCards = snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
      });
    } catch (e) {
      _showError('Error loading payment methods: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Get card icon based on card name
  IconData _getCardIcon(String cardName) {
    cardName = cardName.toLowerCase();
    if (cardName.contains('visa')) return Icons.credit_card;
    if (cardName.contains('mastercard')) return Icons.account_balance_wallet;
    if (cardName.contains('american express') || cardName.contains('amex')) return Icons.account_balance;
    if (cardName.contains('discover')) return Icons.person;
    return Icons.credit_card;
  }

  // Generate gradient colors based on card color
  List<Color> _getGradientColors(String colorString) {
    try {
      final baseColor = Color(int.parse(colorString));
      return [
        baseColor,
        baseColor.withOpacity(0.7),
        baseColor.withOpacity(0.5),
      ];
    } catch (e) {
      return [Color(0xFF2754C3), Color(0xFF5E81F4)];
    }
  }

  Widget _buildCardItem(Map<String, dynamic> card, int index, bool isSelected) {
    final List<Color> gradientColors = _getGradientColors(card['color']);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
          border: isSelected 
            ? Border.all(color: Colors.white, width: 2) 
            : null,
        ),
        child: Stack(
          children: [
            // Card background
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            ),
            
            // Card content
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Card type icon
                        Icon(
                          _getCardIcon(card['name']),
                          color: Colors.white,
                          size: 32,
                        ),
                        
                        // Default tag if applicable
                        if (card['isDefault'] == true)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              "DEFAULT",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Card number
                    Text(
                      card['number'],
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    Spacer(),
                    
                    // Card holder info and expiry
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CARD HOLDER",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              card['holderName'] ?? "Card Holder",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "EXPIRES",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              card['expiry'] ?? "MM/YY",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: gradientColors[0],
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

  Widget _buildAddCardButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardPaymentScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Color(0xFF3366FF).withOpacity(0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF3366FF),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                "Add New Payment Method",
                style: GoogleFonts.poppins(
                  color: Color(0xFF3366FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment() async {
    if (savedCards.isEmpty) {
      _showError("No card selected");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get the selected card
    final selectedCard = savedCards[_selectedCardIndex];

    // Process the payment with Firebase
    try {
      // Get the current user ID
      final user = FirebaseAuth.instance.currentUser;
      final String? userId = user?.uid;
      
      if (userId != null) {
        try {
          // Get the fee amount directly as it's already a number
          int amountValue = widget.appointmentDetails?['fee'] ?? 0;
          
          // 1. Save the appointment to Firestore
          final appointmentRef = await _firestore.collection('appointments').add({
            'patientId': userId,
            'doctorId': widget.appointmentDetails?['doctorId'],
            'doctorName': widget.appointmentDetails?['doctorName'],
            'date': widget.appointmentDetails?['date'],
            'time': widget.appointmentDetails?['time'],
            'location': widget.appointmentDetails?['location'],
            'hospitalName': widget.appointmentDetails?['hospitalName'] ?? 'Unknown Hospital',
            'hospitalId': widget.appointmentDetails?['hospitalId'],
            'fee': amountValue,
            'displayFee': widget.appointmentDetails?['displayFee'],
            'status': 'confirmed',
            'paymentStatus': 'completed',
            'paymentMethod': 'Credit Card',
            'cardType': selectedCard["name"],
            'paymentDate': FieldValue.serverTimestamp(),
            'bookingDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'notes': widget.appointmentDetails?['notes'] ?? '',
            'isPanelConsultation': widget.appointmentDetails?['isPanelConsultation'] ?? false,
            'hasFinancialTransaction': true,
          });
          
          // 2. Save the transaction to Firestore
          await _firestore.collection('transactions').add({
            'userId': userId,
            'patientId': userId,
            'doctorId': widget.appointmentDetails?['doctorId'],
            'appointmentId': appointmentRef.id,
            'title': 'Appointment Payment',
            'description': 'Consultation with ${widget.appointmentDetails?['doctorName']}',
            'amount': amountValue,
            'date': Timestamp.now(),
            'type': 'payment',
            'status': 'completed',
            'paymentMethod': 'Saved Card',
            'doctorName': widget.appointmentDetails?['doctorName'],
            'hospitalName': widget.appointmentDetails?['location'],
            'cardType': selectedCard["name"],
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
          
          // 3. Update the appointment slot status to booked
          final String? slotId = widget.appointmentDetails?['slotId'];
          if (slotId != null) {
            await _firestore.collection('appointment_slots').doc(slotId).update({
              'isBooked': true,
              'tempHoldUntil': null,
              'tempHoldBy': null,
              'bookedAt': FieldValue.serverTimestamp(),
              'bookedBy': userId,
              'appointmentId': appointmentRef.id,
            });
          }
          
          setState(() => _isLoading = false);
          
          // Show success dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                final Size screenSize = MediaQuery.of(context).size;
                
                return Dialog(
                  insetPadding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenSize.width * 0.05),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;
                      final isSmallScreen = maxWidth < 360;
                      
                      final fontSize = {
                        'small': maxWidth * (isSmallScreen ? 0.035 : 0.04),
                        'medium': maxWidth * (isSmallScreen ? 0.04 : 0.045),
                        'large': maxWidth * (isSmallScreen ? 0.05 : 0.055),
                      };
                      
                      final padding = {
                        'small': maxWidth * 0.03,
                        'medium': maxWidth * 0.04,
                        'large': maxWidth * 0.05,
                      };
                      
                      return Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: 450,
                          maxHeight: screenSize.height * 0.8,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header with success icon
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: padding['medium']!),
                                decoration: BoxDecoration(
                                  color: Color(0xFF3366FF),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(screenSize.width * 0.05)),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(maxWidth * 0.04),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Color(0xFF3366FF),
                                        size: maxWidth * 0.08,
                                      ),
                                    ),
                                    SizedBox(height: padding['small']!),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Payment Successful",
                                        style: GoogleFonts.poppins(
                                          fontSize: fontSize['large'],
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Payment details
                              Padding(
                                padding: EdgeInsets.all(padding['large']!),
                                child: Column(
                                  children: [
                                    // Amount
                                    _buildPaymentInfoContainer(
                                      "Amount Paid",
                                      "${widget.appointmentDetails?['displayFee'] ?? widget.appointmentDetails?['fee'] ?? 'Rs. 2,000'}",
                                      Icons.attach_money,
                                      padding: padding,
                                      fontSize: fontSize,
                                    ),
                                    
                                    SizedBox(height: padding['small']!),
                                    
                                    // Doctor details
                                    _buildPaymentInfoContainer(
                                      "Doctor",
                                      "${widget.appointmentDetails?['doctorName'] ?? 'Doctor'}",
                                      Icons.medical_services,
                                      padding: padding,
                                      fontSize: fontSize,
                                    ),
                                    
                                    SizedBox(height: padding['small']!),
                                    
                                    // Payment method
                                    _buildPaymentInfoContainer(
                                      "Payment Method",
                                      selectedCard["name"],
                                      Icons.credit_card,
                                      padding: padding,
                                      fontSize: fontSize,
                                    ),
                                    
                                    SizedBox(height: padding['medium']!),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              PatientNavigationHelper.navigateToHome(context);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(vertical: maxHeight * 0.02),
                                              side: BorderSide(
                                                color: Color(0xFF3366FF),
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(maxWidth * 0.03),
                                              ),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "Go to Home",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: fontSize['medium'],
                                                  color: Color(0xFF3366FF),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: padding['small']!),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              PatientNavigationHelper.navigateToHome(context);
                                              Future.delayed(Duration(milliseconds: 100), () {
                                                PatientNavigationHelper.navigateToTab(context, 2);
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF3366FF),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: maxHeight * 0.02),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(maxWidth * 0.03),
                                              ),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "View History",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: fontSize['medium'],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
                );
              },
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);
          _showError("Payment failed: ${e.toString()}");
        }
      } else {
        setState(() => _isLoading = false);
        _showError("You must be signed in to book an appointment");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  // Helper method to build payment info containers in the success dialog
  Widget _buildPaymentInfoContainer(String title, String value, IconData icon, {required Map<String, double> padding, required Map<String, double> fontSize}) {
    return Container(
      padding: EdgeInsets.all(padding['medium']!),
      decoration: BoxDecoration(
        color: Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(padding['medium']!),
        border: Border.all(color: Color(0xFFD6E4FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding['small']!),
            decoration: BoxDecoration(
              color: Color(0xFFE5EDFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: padding['large']!,
              color: Color(0xFF3366FF),
            ),
          ),
          SizedBox(width: padding['medium']!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize['small'],
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize['medium'],
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          "Select Payment Method",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3366FF),
              ),
            )
          : savedCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFEFF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.credit_card,
                          size: 48,
                          color: Color(0xFF3366FF),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        "No payment methods added yet",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Add a card to proceed with your payment",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CardPaymentScreen(
                                appointmentDetails: widget.appointmentDetails,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.add_circle_outline),
                        label: Text("Add Payment Method"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3366FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        children: [
                          // Build list of cards
                          for (int i = 0; i < savedCards.length; i++)
                            _buildCardItem(savedCards[i], i, i == _selectedCardIndex),
                          
                          // Add card button
                          _buildAddCardButton(),
                          
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                    
                    // Bottom payment button
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: ElevatedButton(
                          onPressed: _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3366FF),
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            "Pay Now",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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