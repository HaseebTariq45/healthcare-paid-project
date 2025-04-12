import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/card_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<Map<String, dynamic>> savedCards = [
    {
      "type": "Card",
      "name": "Visa Platinum",
      "holder": "John Doe",
      "number": "•••• •••• •••• 4444",
      "expiry": "12/27",
      "cvv": "333",
      "color": "0xFF3366FF", // Blue color
      "icon": LucideIcons.creditCard,
      "bank_logo": "assets/images/User.png",
      "default": true,
    },
    {
      "type": "Card",
      "name": "Mastercard Gold",
      "holder": "John Doe",
      "number": "•••• •••• •••• 8123",
      "expiry": "09/26",
      "cvv": "444",
      "color": "0xFF8E44AD", // Purple color
      "icon": LucideIcons.creditCard,
      "bank_logo": "assets/images/User.png",
      "default": false,
    },
  ];

  int _selectedCardIndex = 0;
  bool _isLoading = false;

  void _processPayment() {
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
    Future.delayed(Duration(seconds: 2), () async {
      // Get the current user ID
      final user = FirebaseAuth.instance.currentUser;
      final String? userId = user?.uid;
      
      if (userId != null) {
        try {
          // Get the fee amount directly as it's already a number
          int amountValue = widget.appointmentDetails?['fee'] ?? 0;
          
          // 1. Save the appointment to Firestore
          final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
            'patientId': userId,
            'doctorId': widget.appointmentDetails?['doctorId'],
            'doctorName': widget.appointmentDetails?['doctorName'],
            'date': widget.appointmentDetails?['date'],
            'time': widget.appointmentDetails?['time'],
            'location': widget.appointmentDetails?['location'],
            'fee': amountValue,
            'displayFee': widget.appointmentDetails?['displayFee'],
            'status': 'confirmed',
            'paymentStatus': 'completed',
            'paymentMethod': 'Saved Card',
            'cardType': selectedCard["name"],
            'paymentDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'notes': widget.appointmentDetails?['notes'],
            'isPanelConsultation': widget.appointmentDetails?['isPanelConsultation'] ?? false,
          });
          
          // 2. Save the transaction to Firestore
          await FirebaseFirestore.instance.collection('transactions').add({
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
            await FirebaseFirestore.instance.collection('appointment_slots').doc(slotId).update({
              'isBooked': true,
              'tempHoldUntil': null,
              'tempHoldBy': null,
              'bookedAt': FieldValue.serverTimestamp(),
              'bookedBy': userId,
              'appointmentId': appointmentRef.id,
            });
            print('Appointment slot updated successfully');
          } else {
            print('No slotId found in appointment details');
          }
          
          print('Appointment and transaction saved successfully');
          
          setState(() {
            _isLoading = false;
          });
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Payment Successful"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Your payment has been processed successfully."),
                  SizedBox(height: 10),
                  Text("Amount: ${_formatFeeDisplay(widget.appointmentDetails)}"),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to appointment details screen, replacing the entire stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientAppointmentDetailsScreen(),
                      ),
                      (route) => false, // This will remove all previous routes
                    );
                  },
                  child: Text("Continue"),
                ),
              ],
            ),
          );
        } catch (e) {
          print('Error saving appointment and transaction: $e');
          setState(() {
            _isLoading = false;
          });
          
          // Show error message
          _showError("Payment failed: ${e.toString()}");
        }
      } else {
        // User not signed in
        setState(() {
          _isLoading = false;
        });
        
        _showError("You must be signed in to book an appointment");
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(message),
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

  @override
  Widget build(BuildContext context) {
    // Get the appropriate fee from appointment details, handling both string and int types
    String fee = "";
    if (widget.appointmentDetails != null) {
      if (widget.appointmentDetails!.containsKey('displayFee')) {
        fee = widget.appointmentDetails!['displayFee'];
      } else if (widget.appointmentDetails!.containsKey('fee')) {
        var feeValue = widget.appointmentDetails!['fee'];
        if (feeValue is int) {
          fee = "Rs. ${feeValue.toString()}";
        } else if (feeValue is String) {
          fee = feeValue;
        } else {
          fee = "Rs. 2,000";
        }
      } else {
        fee = "Rs. 2,000";
      }
    } else {
      fee = "Rs. 2,000";
    }
    
    String doctor = widget.appointmentDetails != null && widget.appointmentDetails!.containsKey('doctor') 
        ? widget.appointmentDetails!['doctor'] 
        : 'Doctor';

    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Select Card"),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Information
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Summary",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 15),
                        _buildSummaryRow(
                          "Appointment",
                          "Consultation with $doctor",
                          LucideIcons.calendar,
                        ),
                        Divider(height: 20),
                        _buildSummaryRow(
                          "Amount",
                          fee,
                          LucideIcons.creditCard,
                          isAmount: true,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Saved Cards Section
                  Text(
                    "Select Card",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Cards List
                  ...savedCards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final card = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildCardWidget(card, index),
                    );
                  }).toList(),
                  
                  SizedBox(height: 20),
                  
                  // Add New Card Button
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: TextButton.icon(
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
                      icon: Icon(LucideIcons.plus, color: Color(0xFF3366FF)),
                      label: Text(
                        "Add New Card",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3366FF),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Security Message
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.shield,
                          color: Colors.green,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            "Your payment is secure. We use SSL encryption to protect your data.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Pay Now Button
                  _buildSubmitButton(),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(Map<String, dynamic> card, int index) {
    bool isSelected = index == _selectedCardIndex;
    Color cardColor = Color(int.parse(card["color"]));
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardIndex = index;
        });
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.only(
              right: isSelected ? 0 : 12,
              left: isSelected ? 0 : 4,
              top: isSelected ? 0 : 12,
              bottom: isSelected ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? cardColor.withOpacity(0.6) : cardColor.withOpacity(0.4),
                  blurRadius: isSelected ? 16 : 12,
                  offset: Offset(0, 6),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor,
                  cardColor.withAlpha(220),
                ],
              ),
              border: isSelected ? Border.all(
                color: Colors.white,
                width: 2,
              ) : null,
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              height: 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card["name"],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          card["icon"],
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Text(
                    card["number"],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card["holder"],
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        card["expiry"],
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: cardColor,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAmount ? Color(0xFFFEF8E8) : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isAmount ? Color(0xFFBA0000) : Colors.grey.shade700,
              size: 18,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isAmount ? FontWeight.w700 : FontWeight.w500,
                    color: isAmount ? Color(0xFFBA0000) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool hasSelectedCard = savedCards.isNotEmpty;
    Color buttonColor = hasSelectedCard ? Color(0xFF3366FF) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasSelectedCard)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Selected Card: ${savedCards[_selectedCardIndex]["name"]}",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: hasSelectedCard && !_isLoading ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 15),
            ),
            child: _isLoading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasSelectedCard ? "Pay Now" : "Select a Card",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasSelectedCard) ...[
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _formatFeeDisplay(Map<String, dynamic>? appointmentDetails) {
    if (appointmentDetails != null && appointmentDetails.containsKey('displayFee')) {
      return appointmentDetails['displayFee'];
    } else if (appointmentDetails != null && appointmentDetails.containsKey('fee')) {
      var feeValue = appointmentDetails['fee'];
      if (feeValue is int) {
        return "Rs. ${feeValue.toString()}";
      } else if (feeValue is String) {
        return feeValue;
      } else {
        return "Rs. 2,000";
      }
    } else {
      return "Rs. 2,000";
    }
  }
} 