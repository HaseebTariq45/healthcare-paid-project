import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CardPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;
  
  const CardPaymentScreen({
    super.key,
    this.appointmentDetails,
  });

  @override
  _CardPaymentScreenState createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  
  bool _isLoading = false;
  CardType _cardType = CardType.Invalid;
  
  // Focus nodes for form fields
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expiryDateFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_getCardTypeFrmNumber);
  }
  
  @override
  void dispose() {
    _cardNumberController.removeListener(_getCardTypeFrmNumber);
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardNumberFocus.dispose();
    _expiryDateFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }
  
  void _getCardTypeFrmNumber() {
    if (_cardNumberController.text.length <= 4) {
      String input = _cardNumberController.text.trim();
      CardType type = CardType.Invalid;
      
      if (input.startsWith(RegExp(r'[4]'))) {
        type = CardType.Visa;
      } else if (input.startsWith(RegExp(r'[5]'))) {
        type = CardType.MasterCard;
      } else if (input.startsWith(RegExp(r'[3]'))) {
        type = CardType.AmericanExpress;
      } else if (input.startsWith(RegExp(r'[6]'))) {
        type = CardType.Discover;
      }
      
      setState(() {
        _cardType = type;
      });
    }
  }

  String _getCardIcon() {
    switch (_cardType) {
      case CardType.Visa:
        return '💳 Visa';
      case CardType.MasterCard:
        return '💳 MasterCard';
      case CardType.AmericanExpress:
        return '💳 Amex';
      case CardType.Discover:
        return '💳 Discover';
      default:
        return '💳 Card';
    }
  }

  Color _getCardTypeColor() {
    switch (_cardType) {
      case CardType.Visa:
        return Color(0xFF1A1F71);
      case CardType.MasterCard:
        return Color(0xFFFF5F00);
      case CardType.AmericanExpress:
        return Color(0xFF2E77BC);
      case CardType.Discover:
        return Color(0xFFFF6000);
      default:
        return Color(0xFF3366CC);
    }
  }

  bool _validateCardNumber(String number) {
    // Remove spaces and non-digit characters
    String cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid length
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }
    
    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  bool _validateExpiryDate(String date) {
    if (date.length != 5) return false;
    
    try {
      int month = int.parse(date.substring(0, 2));
      int year = int.parse(date.substring(3));
      
      if (month < 1 || month > 12) return false;
      
      // Get current year and month
      DateTime now = DateTime.now();
      int currentYear = now.year % 100;
      int currentMonth = now.month;
      
      // Check if card is expired
      if (year < currentYear || (year == currentYear && month < currentMonth)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _validateCVV(String cvv) {
    return cvv.length >= 3 && cvv.length <= 4 && RegExp(r'^\d+$').hasMatch(cvv);
  }

  void _processPayment() {
    // Validate card number
    if (!_validateCardNumber(_cardNumberController.text)) {
      _showError("Invalid card number");
      return;
    }
    
    // Validate expiry date
    if (!_validateExpiryDate(_expiryDateController.text)) {
      _showError("Invalid or expired card");
      return;
    }
    
    // Validate CVV
    if (!_validateCVV(_cvvController.text)) {
      _showError("Invalid CVV");
      return;
    }
    
    // Validate cardholder name
    if (_cardNameController.text.isEmpty) {
      _showError("Please enter cardholder name");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
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
              Text("Amount: ${widget.appointmentDetails?['fee'] ?? 'Rs. 2,000'}"),
              SizedBox(height: 10),
              Text("Would you like to save this card for future use?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientAppointmentDetailsScreen(),
                  ),
                );
              },
              child: Text("No, thanks"),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Save card to user's payment methods
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientAppointmentDetailsScreen(),
                  ),
                );
              },
              child: Text("Save Card"),
            ),
          ],
        ),
      );
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
    // Get the appropriate fee from appointment details
    String fee = widget.appointmentDetails != null && widget.appointmentDetails!.containsKey('fee') 
        ? widget.appointmentDetails!['fee'] 
        : 'Rs. 2,000';
    
    String doctor = widget.appointmentDetails != null && widget.appointmentDetails!.containsKey('doctor') 
        ? widget.appointmentDetails!['doctor'] 
        : 'Doctor';
    
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Card Payment"),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit Card Visualization
                  _buildCreditCardWidget(),
                  
                  SizedBox(height: 30),
                  
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
                  
                  // Card Details Section
                  Text(
                    "Card Details",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),

                  // Card Name Field
                  _buildTextField(
                    controller: _cardNameController,
                    label: "Cardholder Name",
                    hint: "John Smith",
                    icon: LucideIcons.user,
                    onEditingComplete: () => _cardNumberFocus.requestFocus(),
                  ),
                  
                  // Card Number Field with formatting
                  _buildTextField(
                    controller: _cardNumberController,
                    label: "Card Number",
                    hint: "1234 5678 9012 3456",
                    icon: LucideIcons.creditCard,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      CardNumberFormatter(),
                    ],
                    focusNode: _cardNumberFocus,
                    onEditingComplete: () => _expiryDateFocus.requestFocus(),
                  ),
                  
                  // Expiry Date and CVV Row
            Row(
              children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _expiryDateController,
                          label: "Expiry Date",
                          hint: "MM/YY",
                          icon: LucideIcons.calendar,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            ExpiryDateFormatter(),
                          ],
                          focusNode: _expiryDateFocus,
                          onEditingComplete: () => _cvvFocus.requestFocus(),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                          controller: _cvvController,
                          label: "CVV",
                          hint: "123",
                          icon: LucideIcons.lock,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          focusNode: _cvvFocus,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40),
                  
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
                        Expanded(
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

                  // Process Payment Button
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
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_getCardTypeColor()),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Processing payment...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreditCardWidget() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCardTypeColor(),
            _getCardTypeColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCardTypeColor().withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCardIcon(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(
                LucideIcons.wifi,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cardNumberController.text.isEmpty 
                    ? "•••• •••• •••• ••••" 
                    : _cardNumberController.text,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CARD HOLDER",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _cardNameController.text.isEmpty 
                            ? "YOUR NAME" 
                            : _cardNameController.text.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EXPIRES",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _expiryDateController.text.isEmpty 
                            ? "MM/YY" 
                            : _expiryDateController.text,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
              inputFormatters: inputFormatters,
              onEditingComplete: onEditingComplete,
              focusNode: focusNode,
              style: GoogleFonts.poppins(
                fontSize: 15,
              ),
        decoration: InputDecoration(
          hintText: hint,
                prefixIcon: Icon(
                  icon,
                  color: _getCardTypeColor(),
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getCardTypeColor(),
                    width: 1,
                  ),
                ),
          filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
              color: isAmount ? _getCardTypeColor().withOpacity(0.1) : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isAmount ? _getCardTypeColor() : Colors.grey.shade700,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isAmount ? FontWeight.w700 : FontWeight.w500,
                    color: isAmount ? _getCardTypeColor() : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCardTypeColor(),
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
                    "Pay Now",
          style: GoogleFonts.poppins(
            fontSize: 16,
                      fontWeight: FontWeight.w600,
          ),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 18),
                ],
        ),
      ),
    );
  }
}

enum CardType {
  MasterCard,
  Visa,
  AmericanExpress,
  Discover,
  Invalid
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 16 digits
    if (value.length > 16) {
      value = value.substring(0, 16);
    }
    
    // Format with spaces
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if ((i + 1) % 4 == 0 && i != value.length - 1) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digits
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 4 digits
    if (value.length > 4) {
      value = value.substring(0, 4);
    }
    
    // Format with slash
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if (i == 1 && i != value.length - 1) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
} 
