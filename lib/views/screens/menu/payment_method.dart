import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> paymentMethods = [
    {
      "type": "Card",
      "name": "Visa Platinum",
      "holder": "Dr. Asmara Singh",
      "number": "•••• •••• •••• 4444",
      "expiry": "12/27",
      "cvv": "333",
      "color": "0xFF3366FF", // Blue color
      "icon": LucideIcons.creditCard,
      "bank_logo": "assets/images/User.png", // Replace with actual logo
      "default": true,
    },
    {
      "type": "Card",
      "name": "Mastercard Gold",
      "holder": "Dr. Asmara Singh",
      "number": "•••• •••• •••• 8123",
      "expiry": "09/26",
      "cvv": "444",
      "color": "0xFF8E44AD", // Purple color
      "icon": LucideIcons.creditCard,
      "bank_logo": "assets/images/User.png", // Replace with actual logo
      "default": false,
    },
    {
      "type": "Wallet",
      "name": "JazzCash",
      "holder": "Dr. Asmara Singh",
      "number": "0300 - 1112223",
      "color": "0xFFC2554D", // Red color
      "icon": LucideIcons.wallet,
      "bank_logo": "assets/images/User.png", // Replace with actual logo
      "default": false,
    },
  ];

  int _selectedPaymentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF333333), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment Methods",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.info, color: Color(0xFF3366FF), size: 22),
            onPressed: () {
              // Show payment help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    "Payment Help",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    "You can add multiple payment methods and set a default one for quicker checkout.",
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Got it",
                        style: GoogleFonts.poppins(color: Color(0xFF3366FF)),
                      ),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Card preview section
          Container(
            height: 220,
            padding: EdgeInsets.symmetric(vertical: 20),
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              onPageChanged: (index) {
                setState(() {
                  _selectedPaymentIndex = index;
                });
              },
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                return _buildPaymentCard(paymentMethods[index], index);
              },
            ),
          ),
          
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              paymentMethods.length,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _selectedPaymentIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _selectedPaymentIndex == index
                      ? Color(0xFF3366FF)
                      : Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 30),
          
          // Payment details section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Card Information",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 20),
                
                // Card details
                _buildDetailsRow(
                  "Card Holder",
                  paymentMethods[_selectedPaymentIndex]["holder"],
                  LucideIcons.user,
                ),
                SizedBox(height: 16),
                _buildDetailsRow(
                  "Card Number",
                  paymentMethods[_selectedPaymentIndex]["number"],
                  LucideIcons.creditCard,
                ),
                if (paymentMethods[_selectedPaymentIndex]["expiry"] != null) ...[
                  SizedBox(height: 16),
                  _buildDetailsRow(
                    "Expiry Date",
                    paymentMethods[_selectedPaymentIndex]["expiry"],
                    LucideIcons.calendar,
                  ),
                ],
                
                SizedBox(height: 30),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        "Edit",
                        LucideIcons.pencil,
                        Color(0xFF3366FF),
                        () {
                          _showEditPaymentBottomSheet(paymentMethods[_selectedPaymentIndex]);
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        "Remove",
                        LucideIcons.trash2,
                        Colors.red,
                        () {
                          // Show beautiful confirmation dialog for removing payment method
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: "Remove Payment Method",
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: Duration(milliseconds: 300),
                            pageBuilder: (context, animation1, animation2) => Container(),
                            transitionBuilder: (context, animation, secondaryAnimation, child) {
                              final curvedAnimation = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              );
                              
                              return ScaleTransition(
                                scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
                                  child: Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.zero,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Top section with illustration
                                          Container(
                                            padding: EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFFF0F0),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(24),
                                                topRight: Radius.circular(24),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                // Animated icon
                                                TweenAnimationBuilder<double>(
                                                  duration: Duration(milliseconds: 500),
                                                  tween: Tween(begin: 0.0, end: 1.0),
                                                  builder: (context, value, child) {
                                                    return Transform.scale(
                                                      scale: value,
                                                      child: Container(
                                                        width: 72,
                                                        height: 72,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Color(0xFFE74C3C).withOpacity(0.2),
                                                              blurRadius: 12,
                                                              spreadRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: TweenAnimationBuilder<double>(
                                                            duration: Duration(milliseconds: 700),
                                                            tween: Tween(begin: 0.0, end: 1.0),
                                                            curve: Curves.elasticOut,
                                                            builder: (context, value, child) {
                                                              return Transform.scale(
                                                                scale: value,
                                                                child: Icon(
                                                                  paymentMethods[_selectedPaymentIndex]["type"] == "Wallet" 
                                                                    ? LucideIcons.wallet 
                                                                    : LucideIcons.creditCard,
                                                                  color: Color(0xFFE74C3C),
                                                                  size: 34,
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                SizedBox(height: 16),
                                                // Text content
                                                Text(
                                                  "Remove Payment Method",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF333333),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "Are you sure you want to remove\n${paymentMethods[_selectedPaymentIndex]["name"]}?",
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    color: Color(0xFF666666),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Buttons section
                                          Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Row(
                                              children: [
                                                // Cancel button
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    style: ElevatedButton.styleFrom(
                                                      foregroundColor: Color(0xFF333333),
                                                      backgroundColor: Colors.white,
                                                      elevation: 0,
                                                      padding: EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        side: BorderSide(color: Colors.grey.shade300),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Cancel",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                // Remove button
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // Close dialog first
                                                      Navigator.pop(context);
                                                      
                                                      // Handle removal of the payment method
                                                      _removePaymentMethod(_selectedPaymentIndex);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      foregroundColor: Colors.white,
                                                      backgroundColor: Color(0xFFE74C3C),
                                                      elevation: 0,
                                                      padding: EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Remove",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show bottom sheet to add new payment method
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add Payment Method",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Select Method",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildMethodOption(
                      "Credit Card",
                      LucideIcons.creditCard,
                      Color(0xFF3366FF),
                      () {
                        Navigator.pop(context);
                        _showAddPaymentBottomSheet("Card", "Credit Card", null);
                      },
                    ),
                    SizedBox(height: 12),
                    _buildMethodOption(
                      "Debit Card",
                      LucideIcons.landmark,
                      Color(0xFF4CAF50),
                      () {
                        Navigator.pop(context);
                        _showAddPaymentBottomSheet("Card", "Debit Card", null);
                      },
                    ),
                    SizedBox(height: 12),
                    _buildMethodOption(
                      "Mobile Wallet",
                      LucideIcons.smartphone,
                      Color(0xFFC2554D),
                      () {
                        Navigator.pop(context);
                        _showAddPaymentBottomSheet("Wallet", "Mobile Wallet", null);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: Color(0xFF3366FF),
        elevation: 2,
        child: Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index) {
    bool isSelected = index == _selectedPaymentIndex;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 12, left: 4, top: isSelected ? 0 : 12, bottom: isSelected ? 0 : 12),
      decoration: BoxDecoration(
        color: Color(int.parse(payment["color"])),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(payment["color"])).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(payment["color"])),
            Color(int.parse(payment["color"])).withAlpha(220),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Payment card content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          payment["icon"],
                          color: Colors.white,
                          size: 26,
                        ),
                        SizedBox(width: 8),
                        Text(
                          payment["type"],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        payment["type"] == "Wallet" ? LucideIcons.wallet : LucideIcons.creditCard,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  payment["number"],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12),
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
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          payment["holder"],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (payment["expiry"] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "EXPIRES",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            payment["expiry"],
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
          
          // Default badge
          if (payment["default"] == true)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.check,
                      color: Color(int.parse(payment["color"])),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Default",
                      style: GoogleFonts.poppins(
                        color: Color(int.parse(payment["color"])),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsRow(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF3366FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF3366FF),
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildMethodOption(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            Spacer(),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentBottomSheet(Map<String, dynamic> payment) {
    // Create controllers with existing values
    final holderController = TextEditingController(text: payment["holder"]);
    final expiryController = TextEditingController(text: payment["expiry"] ?? "");
    final nameController = TextEditingController(text: payment["name"]);
    final cvvController = TextEditingController(text: payment["cvv"] ?? "");
    
    // Initialize card number controller
    final numberController = TextEditingController();
    // For wallet payment methods, we don't need to modify the number
    if (payment["type"] != "Wallet") {
      // Extract last 4 digits if they exist in the saved number
      final savedNumber = payment["number"].toString();
      if (savedNumber.contains("••••")) {
        // Card already has saved number - initialize with empty (user will enter full number)
        numberController.text = "";
      } else {
        // New card - no initial value
        numberController.text = "";
      }
    }
    
    bool isDefault = payment["default"];
    
    // Track field validation errors - initialize all as false
    Map<String, bool> fieldErrors = {
      'name': false,
      'holder': false,
      'number': false, // Changed from conditional to false
      'expiry': false,
      'cvv': false,
    };
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Payment Method",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Card preview (non-editable)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Color(int.parse(payment["color"])),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(int.parse(payment["color"])).withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(int.parse(payment["color"])),
                        Color(int.parse(payment["color"])).withAlpha(220),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nameController.text,
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
                              payment["type"] == "Wallet" ? LucideIcons.wallet : LucideIcons.creditCard,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Text(
                        payment["type"] == "Wallet" ? payment["number"] : 
                            numberController.text.isEmpty || numberController.text.length < 16
                            ? payment["number"] 
                            : _formatCardNumberForDisplay(numberController.text),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Name
                        Text(
                          "Card Name",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: fieldErrors['name']! ? 10.0 : 0.0),
                          onEnd: () {
                            if (fieldErrors['name']!) {
                              setModalState(() {
                                fieldErrors['name'] = false;
                              });
                            }
                          },
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: fieldErrors['name']! 
                                    ? Colors.red 
                                    : Colors.grey.shade200,
                                width: fieldErrors['name']! ? 1.5 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: nameController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter card nickname",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.creditCard,
                                  color: fieldErrors['name']! 
                                      ? Colors.red 
                                      : Color(0xFF3366FF),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                // Clear error state
                                if (fieldErrors['name']!) {
                                  setModalState(() {
                                    fieldErrors['name'] = false;
                                  });
                                }
                                
                                // Update preview card name in real-time
                                setModalState(() {});
                              },
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        Text(
                          "Cardholder Name",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: fieldErrors['holder']! ? 10.0 : 0.0),
                          onEnd: () {
                            if (fieldErrors['holder']!) {
                              setModalState(() {
                                fieldErrors['holder'] = false;
                              });
                            }
                          },
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: fieldErrors['holder']! 
                                    ? Colors.red 
                                    : Colors.grey.shade200,
                                width: fieldErrors['holder']! ? 1.5 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: holderController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter cardholder name",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  color: fieldErrors['holder']! 
                                      ? Colors.red 
                                      : Color(0xFF3366FF),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                // Clear error state
                                if (fieldErrors['holder']!) {
                                  setModalState(() {
                                    fieldErrors['holder'] = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        
                        // Card Number
                        if (payment["type"] != "Wallet") ...[
                          SizedBox(height: 20),
                          Text(
                            "Card Number",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                          SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 500),
                            tween: Tween(begin: 0.0, end: fieldErrors['number']! ? 10.0 : 0.0),
                            onEnd: () {
                              if (fieldErrors['number']!) {
                                setModalState(() {
                                  fieldErrors['number'] = false;
                                });
                              }
                            },
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                                child: child,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F7FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: fieldErrors['number']! 
                                      ? Colors.red 
                                      : Colors.grey.shade200,
                                  width: fieldErrors['number']! ? 1.5 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: numberController,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Color(0xFF333333),
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter 16-digit card number",
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                  ),
                                  prefixIcon: Icon(
                                    LucideIcons.creditCard,
                                    color: fieldErrors['number']! 
                                        ? Colors.red 
                                        : Color(0xFF3366FF),
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 19, // 16 digits + 3 spaces
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                onChanged: (value) {
                                  // Clear error state
                                  if (fieldErrors['number']!) {
                                    setModalState(() {
                                      fieldErrors['number'] = false;
                                    });
                                  }
                                  
                                  // Format the card number with spaces
                                  final text = value.replaceAll(" ", "");
                                  if (text.length <= 16) {
                                    final formattedText = _formatCardNumber(text);
                                    if (formattedText != value) {
                                      numberController.value = TextEditingValue(
                                        text: formattedText,
                                        selection: TextSelection.collapsed(offset: formattedText.length),
                                      );
                                    }
                                    // Update preview
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                        
                        if (payment["expiry"] != null) ...[
                          SizedBox(height: 20),
                          Row(
                            children: [
                              // Expiry Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Expiry Date",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 500),
                                      tween: Tween(begin: 0.0, end: fieldErrors['expiry']! ? 10.0 : 0.0),
                                      onEnd: () {
                                        if (fieldErrors['expiry']!) {
                                          setModalState(() {
                                            fieldErrors['expiry'] = false;
                                          });
                                        }
                                      },
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF5F7FF),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: fieldErrors['expiry']! 
                                                ? Colors.red 
                                                : Colors.grey.shade200,
                                            width: fieldErrors['expiry']! ? 1.5 : 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: expiryController,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Color(0xFF333333),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "MM/YY",
                                            hintStyle: GoogleFonts.poppins(
                                              color: Colors.grey.shade400,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                              LucideIcons.calendar,
                                              color: fieldErrors['expiry']! 
                                                  ? Colors.red 
                                                  : Color(0xFF3366FF),
                                              size: 20,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          onChanged: (value) {
                                            if (fieldErrors['expiry']!) {
                                              setModalState(() {
                                                fieldErrors['expiry'] = false;
                                              });
                                            }
                                            
                                            // Check if month section is valid (01-12)
                                            if (value.length == 2 && !value.contains('/')) {
                                              // Convert input to integer
                                              int? month = int.tryParse(value);
                                              
                                              // If month is greater than 12, set it to 12
                                              if (month != null && month > 12) {
                                                expiryController.text = '12/';
                                              } else {
                                                expiryController.text = value + '/';
                                              }
                                              
                                              // Position cursor after the slash
                                              expiryController.selection = TextSelection.fromPosition(
                                                TextPosition(offset: expiryController.text.length),
                                              );
                                            }
                                          },
                                          maxLength: 5,
                                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // CVV
                              if (payment["cvv"] != null) ...[
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CVV",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 500),
                                        tween: Tween(begin: 0.0, end: fieldErrors['cvv']! ? 10.0 : 0.0),
                                        onEnd: () {
                                          if (fieldErrors['cvv']!) {
                                            setModalState(() {
                                              fieldErrors['cvv'] = false;
                                            });
                                          }
                                        },
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF5F7FF),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: fieldErrors['cvv']! 
                                                  ? Colors.red 
                                                  : Colors.grey.shade200,
                                              width: fieldErrors['cvv']! ? 1.5 : 1,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: cvvController,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: Color(0xFF333333),
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "123",
                                              hintStyle: GoogleFonts.poppins(
                                                color: Colors.grey.shade400,
                                                fontSize: 15,
                                              ),
                                              prefixIcon: Icon(
                                                LucideIcons.shield,
                                                color: fieldErrors['cvv']! 
                                                    ? Colors.red 
                                                    : Color(0xFF3366FF),
                                                size: 20,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            ),
                                            maxLength: 3,
                                            obscureText: true,
                                            keyboardType: TextInputType.number,
                                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                            onChanged: (value) {
                                              // Clear error state
                                              if (fieldErrors['cvv']!) {
                                                setModalState(() {
                                                  fieldErrors['cvv'] = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        
                        SizedBox(height: 20),
                        Text(
                          "Card Settings",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Default switch
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Set as Default",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Use this payment method by default",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isDefault,
                                onChanged: (value) {
                                  setModalState(() {
                                    isDefault = value;
                                  });
                                },
                                activeColor: Color(0xFF3366FF),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Save button
                Padding(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate all required fields
                        bool hasErrors = false;
                        Map<String, bool> newErrors = Map.from(fieldErrors);
                        
                        // Check name
                        if (nameController.text.trim().isEmpty) {
                          newErrors['name'] = true;
                          hasErrors = true;
                        }
                        
                        // Check holder
                        if (holderController.text.trim().isEmpty) {
                          newErrors['holder'] = true;
                          hasErrors = true;
                        }
                        
                        // Check card number for card payment types
                        if (payment["type"] != "Wallet") {
                          final cleanNumber = numberController.text.replaceAll(" ", "");
                          if (cleanNumber.length < 16) {
                            newErrors['number'] = true;
                            hasErrors = true;
                          }
                        }
                        
                        // Check expiry if applicable
                        if (payment["expiry"] != null && expiryController.text.trim().isEmpty) {
                          newErrors['expiry'] = true;
                          hasErrors = true;
                        }
                        
                        // Check CVV if applicable
                        if (payment["cvv"] != null && cvvController.text.trim().isEmpty) {
                          newErrors['cvv'] = true;
                          hasErrors = true;
                        }
                        
                        // If we have errors, update UI and don't save
                        if (hasErrors) {
                          setModalState(() {
                            fieldErrors = newErrors;
                          });
                          return;
                        }
                        
                        // No errors, update the payment method details
                        setState(() {
                          // Update all payment methods default status
                          if (isDefault) {
                            for (var method in paymentMethods) {
                              method["default"] = false;
                            }
                          }
                          
                          // Update current payment method
                          paymentMethods[_selectedPaymentIndex]["name"] = nameController.text;
                          paymentMethods[_selectedPaymentIndex]["holder"] = holderController.text;
                          paymentMethods[_selectedPaymentIndex]["default"] = isDefault;
                          
                          if (payment["type"] != "Wallet" && numberController.text.isNotEmpty) {
                            // Remove spaces and format for storage, show only last 4 digits
                            final cleanNumber = numberController.text.replaceAll(" ", "");
                            if (cleanNumber.length == 16) {
                              final lastFourDigits = cleanNumber.substring(12, 16);
                              paymentMethods[_selectedPaymentIndex]["number"] = "•••• •••• •••• " + lastFourDigits;
                            }
                          }
                          
                          if (payment["expiry"] != null) {
                            paymentMethods[_selectedPaymentIndex]["expiry"] = expiryController.text;
                          }
                          
                          if (payment["cvv"] != null) {
                            paymentMethods[_selectedPaymentIndex]["cvv"] = cvvController.text;
                          }
                        });
                        
                        // Close the bottom sheet
                        Navigator.pop(context);
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment method updated successfully'),
                            backgroundColor: Color(0xFF3366FF),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.all(10),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3366FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Save Changes",
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
          ),
        ),
      ),
    );
  }

  // Helper method to format card number as user types (e.g. "1234 5678 9012 3456")
  String _formatCardNumber(String cardNumber) {
    // Add a space after every 4 characters
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < cardNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(" ");
      }
      buffer.write(cardNumber[i]);
    }
    return buffer.toString();
  }

  // Helper method to format card number for display in preview (masking all but last 4)
  String _formatCardNumberForDisplay(String cardNumber) {
    // Remove spaces
    final cleanNumber = cardNumber.replaceAll(" ", "");
    
    // Return masked version
    if (cleanNumber.length < 16) return "•••• •••• •••• ####";
    
    // Show only last 4 digits
    return "•••• •••• •••• ${cleanNumber.substring(12, 16)}";
  }

  // Add this new method to generate card colors based on card number
  String _generateCardColor(String cardNumber) {
    // Define a palette of 7 visually distinct colors suitable for cards
    final List<String> colorPalette = [
      "0xFF3366FF", // Blue
      "0xFF8E44AD", // Purple
      "0xFF16A085", // Teal
      "0xFFE74C3C", // Red
      "0xFFFF9800", // Orange
      "0xFF2C3E50", // Dark Blue
      "0xFF27AE60", // Green
    ];
    
    // If card number is empty, return a default color
    if (cardNumber.isEmpty) return colorPalette[0];
    
    // Clean the card number (remove spaces)
    final cleanNumber = cardNumber.replaceAll(" ", "");
    
    // Use the last digit of the card number to select a color
    if (cleanNumber.length >= 1) {
      // Get the last digit as an integer
      final lastDigit = int.parse(cleanNumber[cleanNumber.length - 1]);
      // Use modulo to get an index within the color palette range
      return colorPalette[lastDigit % colorPalette.length];
    }
    
    // Fallback to the first color
    return colorPalette[0];
  }

  // Method to remove a payment method
  void _removePaymentMethod(int index) {
    setState(() {
      // Check if we're removing the default method
      bool wasDefault = paymentMethods[index]["default"] == true;
      
      // Remove the payment method
      paymentMethods.removeAt(index);
      
      // If we removed the last payment method, set index to 0
      if (_selectedPaymentIndex >= paymentMethods.length) {
        _selectedPaymentIndex = paymentMethods.isNotEmpty ? paymentMethods.length - 1 : 0;
      }
      
      // If we removed the default method and there are other methods left,
      // make the first one the default
      if (wasDefault && paymentMethods.isNotEmpty) {
        paymentMethods[0]["default"] = true;
      }
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment method removed successfully'),
        backgroundColor: Color(0xFF3366FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showAddPaymentBottomSheet(String type, String name, String? colorCode) {
    // Create controllers for form fields
    final holderController = TextEditingController(text: "Dr. Asmara Singh");
    final expiryController = TextEditingController();
    final nameController = TextEditingController(text: name);
    final numberController = TextEditingController();
    final cvvController = TextEditingController();
    
    // Use a default color initially (will be updated when card number changes)
    String cardColor = colorCode ?? "0xFF3366FF";
    
    bool isDefault = paymentMethods.isEmpty; // Make default if it's the first card
    
    // Track field validation errors - initialize all as false
    Map<String, bool> fieldErrors = {
      'name': false,
      'holder': false,
      'number': false, // Changed from true to false
      'expiry': false, // Changed from conditional to false
      'cvv': false, // Changed from conditional to false
    };
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add ${type == 'Card' ? nameController.text : 'Mobile Wallet'}",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Card preview
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Color(int.parse(cardColor)),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(int.parse(cardColor)).withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(int.parse(cardColor)),
                        Color(int.parse(cardColor)).withAlpha(220),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nameController.text,
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
                              type == "Wallet" ? LucideIcons.wallet : LucideIcons.creditCard,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Text(
                        type == "Wallet" 
                            ? (numberController.text.isEmpty ? "Enter phone number" : numberController.text)
                            : (numberController.text.isEmpty || numberController.text.length < 16
                                ? "•••• •••• •••• ####" 
                                : _formatCardNumberForDisplay(numberController.text)),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card/Wallet Name
                        Text(
                          type == "Card" ? "Card Name" : "Wallet Name",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: fieldErrors['name']! ? 10.0 : 0.0),
                          onEnd: () {
                            if (fieldErrors['name']!) {
                              setModalState(() {
                                fieldErrors['name'] = false;
                              });
                            }
                          },
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: fieldErrors['name']! 
                                    ? Colors.red 
                                    : Colors.grey.shade200,
                                width: fieldErrors['name']! ? 1.5 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: nameController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: type == "Card" ? "Enter card nickname" : "Enter wallet name",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  type == "Card" ? LucideIcons.creditCard : LucideIcons.wallet,
                                  color: fieldErrors['name']! 
                                      ? Colors.red 
                                      : Color(0xFF3366FF),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                // Clear error state
                                if (fieldErrors['name']!) {
                                  setModalState(() {
                                    fieldErrors['name'] = false;
                                  });
                                }
                                
                                // Update preview name in real-time
                                setModalState(() {});
                              },
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        Text(
                          type == "Card" ? "Cardholder Name" : "Account Holder",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: fieldErrors['holder']! ? 10.0 : 0.0),
                          onEnd: () {
                            if (fieldErrors['holder']!) {
                              setModalState(() {
                                fieldErrors['holder'] = false;
                              });
                            }
                          },
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: fieldErrors['holder']! 
                                    ? Colors.red 
                                    : Colors.grey.shade200,
                                width: fieldErrors['holder']! ? 1.5 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: holderController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter name",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  color: fieldErrors['holder']! 
                                      ? Colors.red 
                                      : Color(0xFF3366FF),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) {
                                if (fieldErrors['holder']!) {
                                  setModalState(() {
                                    fieldErrors['holder'] = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        
                        // Number field
                        SizedBox(height: 20),
                        Text(
                          type == "Card" ? "Card Number" : "Phone Number",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: fieldErrors['number']! ? 10.0 : 0.0),
                          onEnd: () {
                            if (fieldErrors['number']!) {
                              setModalState(() {
                                fieldErrors['number'] = false;
                              });
                            }
                          },
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: fieldErrors['number']! 
                                    ? Colors.red 
                                    : Colors.grey.shade200,
                                width: fieldErrors['number']! ? 1.5 : 1,
                              ),
                            ),
                            child: TextField(
                              controller: numberController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: type == "Card" ? "Enter 16-digit card number" : "Enter phone number",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  type == "Card" ? LucideIcons.creditCard : LucideIcons.phone,
                                  color: fieldErrors['number']! 
                                      ? Colors.red 
                                      : Color(0xFF3366FF),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: type == "Card" ? 19 : 14, // 16 digits + 3 spaces or phone number
                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                              onChanged: (value) {
                                // Clear error state
                                if (fieldErrors['number']!) {
                                  setModalState(() {
                                    fieldErrors['number'] = false;
                                  });
                                }
                                
                                // Format card number with spaces for cards
                                if (type == "Card") {
                                  final text = value.replaceAll(" ", "");
                                  if (text.length <= 16) {
                                    final formattedText = _formatCardNumber(text);
                                    if (formattedText != value) {
                                      numberController.value = TextEditingValue(
                                        text: formattedText,
                                        selection: TextSelection.collapsed(offset: formattedText.length),
                                      );
                                    }
                                    
                                    // Update card color based on number
                                    if (text.length > 0) {
                                      cardColor = _generateCardColor(text);
                                    }
                                  }
                                }
                                
                                // Update preview
                                setModalState(() {});
                              },
                            ),
                          ),
                        ),
                        
                        // Card-specific fields
                        if (type == "Card") ...[
                          SizedBox(height: 20),
                          Row(
                            children: [
                              // Expiry Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Expiry Date",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 500),
                                      tween: Tween(begin: 0.0, end: fieldErrors['expiry']! ? 10.0 : 0.0),
                                      onEnd: () {
                                        if (fieldErrors['expiry']!) {
                                          setModalState(() {
                                            fieldErrors['expiry'] = false;
                                          });
                                        }
                                      },
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF5F7FF),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: fieldErrors['expiry']! 
                                                ? Colors.red 
                                                : Colors.grey.shade200,
                                            width: fieldErrors['expiry']! ? 1.5 : 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: expiryController,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Color(0xFF333333),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "MM/YY",
                                            hintStyle: GoogleFonts.poppins(
                                              color: Colors.grey.shade400,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                              LucideIcons.calendar,
                                              color: fieldErrors['expiry']! 
                                                  ? Colors.red 
                                                  : Color(0xFF3366FF),
                                              size: 20,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          onChanged: (value) {
                                            if (fieldErrors['expiry']!) {
                                              setModalState(() {
                                                fieldErrors['expiry'] = false;
                                              });
                                            }
                                            
                                            // Check if month section is valid (01-12)
                                            if (value.length == 2 && !value.contains('/')) {
                                              // Convert input to integer
                                              int? month = int.tryParse(value);
                                              
                                              // If month is greater than 12, set it to 12
                                              if (month != null && month > 12) {
                                                expiryController.text = '12/';
                                              } else {
                                                expiryController.text = value + '/';
                                              }
                                              
                                              // Position cursor after the slash
                                              expiryController.selection = TextSelection.fromPosition(
                                                TextPosition(offset: expiryController.text.length),
                                              );
                                            }
                                          },
                                          maxLength: 5,
                                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // CVV
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "CVV",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 500),
                                      tween: Tween(begin: 0.0, end: fieldErrors['cvv']! ? 10.0 : 0.0),
                                      onEnd: () {
                                        if (fieldErrors['cvv']!) {
                                          setModalState(() {
                                            fieldErrors['cvv'] = false;
                                          });
                                        }
                                      },
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF5F7FF),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: fieldErrors['cvv']! 
                                                ? Colors.red 
                                                : Colors.grey.shade200,
                                            width: fieldErrors['cvv']! ? 1.5 : 1,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: cvvController,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Color(0xFF333333),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "123",
                                            hintStyle: GoogleFonts.poppins(
                                              color: Colors.grey.shade400,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                              LucideIcons.shield,
                                              color: fieldErrors['cvv']! 
                                                  ? Colors.red 
                                                  : Color(0xFF3366FF),
                                              size: 20,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          maxLength: 3,
                                          obscureText: true,
                                          keyboardType: TextInputType.number,
                                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                          onChanged: (value) {
                                            if (fieldErrors['cvv']!) {
                                              setModalState(() {
                                                fieldErrors['cvv'] = false;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        SizedBox(height: 20),
                        Text(
                          "Card Settings",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Default switch
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Set as Default",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Use this payment method by default",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isDefault,
                                onChanged: (value) {
                                  setModalState(() {
                                    isDefault = value;
                                  });
                                },
                                activeColor: Color(0xFF3366FF),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Save button
                Padding(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate all required fields
                        bool hasErrors = false;
                        Map<String, bool> newErrors = Map.from(fieldErrors);
                        
                        // Check name
                        if (nameController.text.trim().isEmpty) {
                          newErrors['name'] = true;
                          hasErrors = true;
                        }
                        
                        // Check holder
                        if (holderController.text.trim().isEmpty) {
                          newErrors['holder'] = true;
                          hasErrors = true;
                        }
                        
                        // Check number
                        if (numberController.text.trim().isEmpty) {
                          newErrors['number'] = true;
                          hasErrors = true;
                        } else if (type == "Card") {
                          final cleanNumber = numberController.text.replaceAll(" ", "");
                          if (cleanNumber.length < 16) {
                            newErrors['number'] = true;
                            hasErrors = true;
                          }
                        }
                        
                        // Check expiry if applicable
                        if (type == "Card" && expiryController.text.trim().isEmpty) {
                          newErrors['expiry'] = true;
                          hasErrors = true;
                        }
                        
                        // Check CVV if applicable
                        if (type == "Card" && cvvController.text.trim().isEmpty) {
                          newErrors['cvv'] = true;
                          hasErrors = true;
                        }
                        
                        // If we have errors, update UI and don't save
                        if (hasErrors) {
                          setModalState(() {
                            fieldErrors = newErrors;
                          });
                          return;
                        }
                        
                        // No errors, create and add the new payment method
                        Map<String, dynamic> newPaymentMethod = {
                          "type": type,
                          "name": nameController.text,
                          "holder": holderController.text,
                          "color": cardColor,
                          "icon": type == "Wallet" ? LucideIcons.wallet : LucideIcons.creditCard,
                          "default": isDefault,
                        };
                        
                        // Add type-specific fields
                        if (type == "Card") {
                          // Format card number for storage
                          final cleanNumber = numberController.text.replaceAll(" ", "");
                          final lastFourDigits = cleanNumber.substring(12, 16);
                          newPaymentMethod["number"] = "•••• •••• •••• " + lastFourDigits;
                          newPaymentMethod["expiry"] = expiryController.text;
                          newPaymentMethod["cvv"] = cvvController.text;
                        } else {
                          // Use full number for wallet
                          newPaymentMethod["number"] = numberController.text;
                          // For wallets, we can use a fixed color or generate one based on phone number
                          newPaymentMethod["color"] = "0xFFC2554D"; // Fixed red color for wallets
                        }
                        
                        // Close the bottom sheet first to prevent context issues
                        Navigator.pop(context);
                        
                        // Update state with a slight delay to ensure bottom sheet is fully closed
                        Future.delayed(Duration(milliseconds: 100), () {
                          setState(() {
                            // If adding a default method, update all other cards
                            if (isDefault) {
                              for (var method in paymentMethods) {
                                method["default"] = false;
                              }
                            }
                            
                            // Add the new payment method
                            paymentMethods.add(newPaymentMethod);
                            
                            // Select the new card
                            _selectedPaymentIndex = paymentMethods.length - 1;
                          });
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment method added successfully'),
                              backgroundColor: Color(0xFF3366FF),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: EdgeInsets.all(10),
                            ),
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3366FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Add Payment Method",
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
          ),
        ),
      ),
    );
  }
}
