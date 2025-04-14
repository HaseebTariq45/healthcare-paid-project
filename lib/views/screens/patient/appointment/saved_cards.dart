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
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFECF0FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        color: Color(0xFF2754C3),
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Payment Successful",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                content: Container(
                  constraints: BoxConstraints(minWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your payment has been processed successfully.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF555555),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.creditCard,
                              size: 20,
                              color: Color(0xFF2754C3),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount Paid",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                  Text(
                                    "${widget.appointmentDetails?['displayFee'] ?? widget.appointmentDetails?['fee'] ?? 'Rs. 2,000'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      PatientNavigationHelper.navigateToHome(context);
                      Future.delayed(Duration(milliseconds: 100), () {
                        PatientNavigationHelper.navigateToTab(context, 2);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2754C3),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    child: Text("View Payment History"),
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Payment Method",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : savedCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.creditCard,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No payment methods added yet",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
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
                        child: Text("Add Payment Method"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: savedCards.length,
                        itemBuilder: (context, index) {
                          final card = savedCards[index];
                          final isSelected = index == _selectedCardIndex;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCardIndex = index;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? Color(0xFF3366FF) : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(card['color'])),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(isSelected ? 14 : 16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          card['type'] == 'Card'
                                              ? LucideIcons.creditCard
                                              : LucideIcons.wallet,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                card['name'],
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                card['number'],
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (card['isDefault'] == true)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Default",
                                              style: GoogleFonts.poppins(
                                                color: Color(int.parse(card['color'])),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.check,
                                            color: Color(0xFF3366FF),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Selected for payment",
                                            style: GoogleFonts.poppins(
                                              color: Color(0xFF3366FF),
                                              fontWeight: FontWeight.w500,
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
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3366FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                          SizedBox(height: 12),
                          TextButton(
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
                            child: Text("Add New Card"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 