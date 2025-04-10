import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart'; // Add this import

class PaymentMethodsScreen extends StatefulWidget {
  final UserType userType;
  
  const PaymentMethodsScreen({
    super.key,
    required this.userType, // Remove the default value so it must be provided
  });

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
      "icon": Icons.credit_card,
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
      "icon": Icons.credit_card,
      "bank_logo": "assets/images/User.png", // Replace with actual logo
      "default": false,
    },
    {
      "type": "Wallet",
      "name": "JazzCash",
      "holder": "Dr. Asmara Singh",
      "number": "0300 - 1112223",
      "color": "0xFFC2554D", // Red color
      "icon": Icons.account_balance_wallet,
      "bank_logo": "assets/images/User.png", // Replace with actual logo
      "default": false,
    },
  ];

  // Doctor's banking information
  Map<String, dynamic> bankAccount = {
    "bankName": "Allied Bank Limited",
    "accountTitle": "Dr. Asmara Singh",
    "accountNumber": "1234-5678-9012-3456",
    "iban": "PK36ABPA0010001234567",
    "branchCode": "0651",
    "swiftCode": "ABPAPKKA",
    "color": "0xFF3366FF", // Blue color
  };

  int _selectedPaymentIndex = 0;
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountTitleController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  bool _bankInfoEdited = false;

  @override
  void initState() {
    super.initState();
    _initBankAccountControllers();
  }

  void _initBankAccountControllers() {
    _bankNameController.text = bankAccount["bankName"] ?? "";
    _accountTitleController.text = bankAccount["accountTitle"] ?? "";
    _accountNumberController.text = bankAccount["accountNumber"] ?? "";
    _ibanController.text = bankAccount["iban"] ?? "";
    _branchCodeController.text = bankAccount["branchCode"] ?? "";
    _swiftCodeController.text = bankAccount["swiftCode"] ?? "";
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _branchCodeController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  void _saveBankAccountInfo() {
    setState(() {
      bankAccount = {
        "bankName": _bankNameController.text,
        "accountTitle": _accountTitleController.text,
        "accountNumber": _accountNumberController.text,
        "iban": _ibanController.text,
        "branchCode": _branchCodeController.text,
        "swiftCode": _swiftCodeController.text,
        "color": bankAccount["color"],
      };
      _bankInfoEdited = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bank account information saved successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userType == UserType.doctor ? "Payment Account" : "Payment Methods",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Color(0xFF3366FF), size: 22),
            onPressed: () {
              // Show payment help dialog based on user type
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    widget.userType == UserType.doctor ? "Payment Account Help" : "Payment Help",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    widget.userType == UserType.doctor 
                        ? "Please provide your bank account details to receive payments from patients."
                        : "You can add multiple payment methods and set a default one for quicker checkout.",
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
      body: widget.userType == UserType.doctor ? _buildDoctorPaymentView() : _buildPatientPaymentView(),
      floatingActionButton: widget.userType == UserType.doctor
          ? (_bankInfoEdited ? FloatingActionButton(
              onPressed: _saveBankAccountInfo,
              backgroundColor: Color(0xFF3366FF),
              elevation: 2,
              child: Icon(Icons.save, color: Colors.white),
            ) : null)
          : FloatingActionButton(
              onPressed: () {
                // Show bottom sheet to add new payment method (for patients only)
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
                                icon: Icon(Icons.close),
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
                            Icons.credit_card,
                            Color(0xFF3366FF),
                            () {
                              Navigator.pop(context);
                              _showAddPaymentBottomSheet("Card", "Credit Card", null);
                            },
                          ),
                          SizedBox(height: 12),
                          _buildMethodOption(
                            "Debit Card",
                            Icons.account_balance,
                            Color(0xFF4CAF50),
                            () {
                              Navigator.pop(context);
                              _showAddPaymentBottomSheet("Card", "Debit Card", null);
                            },
                          ),
                          SizedBox(height: 12),
                          _buildMethodOption(
                            "Mobile Wallet",
                            Icons.smartphone,
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
              child: Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  // Build doctor payment view with bank account details
  Widget _buildDoctorPaymentView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Bank account card
          _buildBankAccountCard(),
          SizedBox(height: 30),
          
          // Bank account details form
                Text(
            "Bank Account Information",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
          SizedBox(height: 16),
          
          // Bank name
          _buildBankFormField(
            "Bank Name",
            Icons.business,
            _bankNameController,
            "Enter bank name",
            onChanged: (value) => setState(() => _bankInfoEdited = true),
                ),
                SizedBox(height: 16),
          
          // Account title
          _buildBankFormField(
            "Account Title",
            Icons.person,
            _accountTitleController,
            "Enter account title",
            onChanged: (value) => setState(() => _bankInfoEdited = true),
          ),
                  SizedBox(height: 16),
          
          // Account number
          _buildBankFormField(
            "Account Number",
            Icons.tag,
            _accountNumberController,
            "Enter account number",
            onChanged: (value) => setState(() => _bankInfoEdited = true),
          ),
          SizedBox(height: 16),
          
          // IBAN
          _buildBankFormField(
            "IBAN",
            Icons.account_balance,
            _ibanController,
            "Enter IBAN number",
            onChanged: (value) => setState(() => _bankInfoEdited = true),
          ),
          SizedBox(height: 16),
          
          // Two fields in one row: Branch Code and Swift Code
                Row(
                  children: [
                    Expanded(
                child: _buildBankFormField(
                  "Branch Code",
                  Icons.numbers,
                  _branchCodeController,
                  "Enter branch code",
                  onChanged: (value) => setState(() => _bankInfoEdited = true),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                child: _buildBankFormField(
                  "Swift Code",
                  Icons.code,
                  _swiftCodeController,
                  "Enter swift code",
                  onChanged: (value) => setState(() => _bankInfoEdited = true),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Information note
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF3366FF).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF3366FF),
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Information",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "All payments from patients will be transferred to this bank account. Payments are typically processed within 1-3 business days.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  // Build bank account card for doctors
  Widget _buildBankAccountCard() {
    return Container(
                                      width: double.infinity,
      height: 200,
                                      decoration: BoxDecoration(
        color: Color(int.parse(bankAccount["color"])),
        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
            color: Color(int.parse(bankAccount["color"])).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(bankAccount["color"])),
            Color(int.parse(bankAccount["color"])).withAlpha(220),
          ],
        ),
      ),
      child: Stack(
          children: [
          // Card decoration elements
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
                                            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
                                                      child: Container(
              width: 160,
              height: 160,
                                                        decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                                                          shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Card content
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
                          Icons.business,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Bank Account",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                                                            ),
                                                          ],
                                                        ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                                                                child: Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                
                Spacer(),
                
                // Account number
                Text(
                  _maskAccountNumber(bankAccount["accountNumber"] ?? ""),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                
                                                SizedBox(height: 16),
                
                // Bank name and account title in one row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                                Text(
                          "ACCOUNT HOLDER",
                                                  style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                                                  ),
                                                ),
                        SizedBox(height: 4),
                                                Text(
                          bankAccount["accountTitle"] ?? "",
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
                          "BANK NAME",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          bankAccount["bankName"] ?? "",
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
        ],
      ),
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.isEmpty) return "";
    
    // Keep the first 4 and last 4 digits, mask the rest
    if (accountNumber.length > 8) {
      final firstFour = accountNumber.substring(0, 4);
      final lastFour = accountNumber.substring(accountNumber.length - 4);
      final middleLength = accountNumber.length - 8;
      final masked = "•" * middleLength;
      
      // Reinsert the same formatting
      final formattedNumber = accountNumber.replaceAll(RegExp(r'\d'), '#');
      String result = "";
      int hashIndex = 0;
      
      for (int i = 0; i < formattedNumber.length; i++) {
        if (formattedNumber[i] == '#') {
          if (hashIndex < 4) {
            result += firstFour[hashIndex];
          } else if (hashIndex >= accountNumber.replaceAll(RegExp(r'[^0-9]'), '').length - 4) {
            result += lastFour[hashIndex - (accountNumber.replaceAll(RegExp(r'[^0-9]'), '').length - 4)];
          } else {
            result += "•";
          }
          hashIndex++;
        } else {
          result += formattedNumber[i];
        }
      }
      
      return result;
    }
    
    return accountNumber;
  }

  Widget _buildBankFormField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint, {
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
                                                      style: GoogleFonts.poppins(
            fontSize: 14,
                                                        fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: Color(0xFF3366FF),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                  ),
      ],
    );
  }

  // Build patient payment view with card options
  Widget _buildPatientPaymentView() {
    return Column(
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
                paymentMethods[_selectedPaymentIndex]["type"] == "Wallet" 
                    ? "Wallet Information" 
                    : "Card Information",
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
                Icons.person,
              ),
              SizedBox(height: 16),
              _buildDetailsRow(
                paymentMethods[_selectedPaymentIndex]["type"] == "Wallet" 
                    ? "Mobile Number" 
                    : "Card Number",
                paymentMethods[_selectedPaymentIndex]["number"],
                paymentMethods[_selectedPaymentIndex]["type"] == "Wallet" 
                    ? Icons.smartphone 
                    : Icons.credit_card,
              ),
              if (paymentMethods[_selectedPaymentIndex]["expiry"] != null) ...[
                    SizedBox(height: 16),
                _buildDetailsRow(
                  "Expiry Date",
                  paymentMethods[_selectedPaymentIndex]["expiry"],
                  Icons.calendar_today,
                ),
              ],
              
              SizedBox(height: 30),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      "Edit",
                      Icons.edit,
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
                      Icons.delete,
                      Colors.red,
                      () {
                        // Show confirmation dialog for removing payment method
                        _removePaymentMethod(_selectedPaymentIndex);
                      },
                    ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
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
                        payment["type"] == "Wallet" ? Icons.account_balance_wallet : Icons.credit_card,
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
                      Icons.check,
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
      'number': false,
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
                        icon: Icon(Icons.close),
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
                              payment["type"] == "Wallet" ? Icons.account_balance_wallet : Icons.credit_card,
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
                          payment["type"] == "Wallet" ? "Wallet Type" : "Card Name",
                  style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        
                        // Use dropdown for wallet types, TextField for cards
                        if (payment["type"] == "Wallet")
                          Container(
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
                            child: DropdownButtonFormField<String>(
                              value: nameController.text,
                              decoration: InputDecoration(
                                hintText: "Select wallet type",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet,
                                  color: fieldErrors['name']! 
                                      ? Colors.red 
                                      : Color(0xFF3366FF),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                              dropdownColor: Colors.white,
                              items: [
                                DropdownMenuItem(
                                  value: "EasyPaisa",
                                  child: Text("EasyPaisa"),
                                ),
                                DropdownMenuItem(
                                  value: "JazzCash",
                                  child: Text("JazzCash"),
                                ),
                              ],
                              onChanged: (String? value) {
                                if (value != null) {
                                  nameController.text = value;
                                  
                                  // Update wallet color based on selection
                                setModalState(() {
                                    if (value == "EasyPaisa") {
                                      payment["color"] = "0xFF4CAF50"; // Green for EasyPaisa
                                    } else if (value == "JazzCash") {
                                      payment["color"] = "0xFFC2554D"; // Red for JazzCash
                                    }
                                });
                              }
                            },
                            ),
                          )
                        else
                          Container(
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
                                  Icons.credit_card,
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
                        
                          SizedBox(height: 20),
                                    Text(
                          payment["type"] == "Wallet" ? "Account Holder" : "Cardholder Name",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                        Container(
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
                              hintText: payment["type"] == "Wallet" ? "Enter account holder name" : "Enter cardholder name",
                                            hintStyle: GoogleFonts.poppins(
                                              color: Colors.grey.shade400,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                Icons.person,
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
                        
                        // For wallet types, show mobile number field
                        if (payment["type"] == "Wallet") ...[
                          SizedBox(height: 20),
                                      Text(
                            "Mobile Number",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                          Container(
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
                                hintText: "03XX - XXXXXXX",
                                              hintStyle: GoogleFonts.poppins(
                                                color: Colors.grey.shade400,
                                                fontSize: 15,
                                              ),
                                              prefixIcon: Icon(
                                  Icons.smartphone,
                                  color: fieldErrors['number']! 
                                                    ? Colors.red 
                                                    : Color(0xFF3366FF),
                                                size: 20,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            ),
                              keyboardType: TextInputType.phone,
                              maxLength: 14, // 03XX - XXXXXXX
                                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                            onChanged: (value) {
                                              // Clear error state
                                if (fieldErrors['number']!) {
                                                setModalState(() {
                                    fieldErrors['number'] = false;
                                  });
                                }
                                
                                // Format phone number with a hyphen after the 4 first digits
                                if (value.length == 4 && !value.contains(" - ")) {
                                  numberController.text = value + " - ";
                                  numberController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: numberController.text.length),
                                  );
                                }
                                
                                // Update preview
                                setModalState(() {});
                              },
                            ),
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
                        // Validate required fields
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
                        
                        // Validate card-specific fields
                        if (payment["type"] == "Card") {
                          // Check card number if provided
                          if (numberController.text.isNotEmpty) {
                          final cleanNumber = numberController.text.replaceAll(" ", "");
                          if (cleanNumber.length < 16) {
                            newErrors['number'] = true;
                            hasErrors = true;
                          }
                        }
                        
                          // Check expiry date
                          if (expiryController.text.trim().isEmpty || !expiryController.text.contains("/") || expiryController.text.length < 5) {
                            newErrors['expiry'] = true;
                            hasErrors = true;
                          } else {
                            // Validate that expiry is in future
                            try {
                              final parts = expiryController.text.split('/');
                              final month = int.parse(parts[0]);
                              final year = int.parse("20${parts[1]}");
                              
                              final currentDate = DateTime.now();
                              final expiryDate = DateTime(year, month + 1, 0);
                              
                              if (expiryDate.isBefore(currentDate)) {
                          newErrors['expiry'] = true;
                          hasErrors = true;
                              }
                            } catch (e) {
                              newErrors['expiry'] = true;
                              hasErrors = true;
                            }
                        }
                        
                          // Check CVV
                          if (cvvController.text.trim().isEmpty || cvvController.text.length < 3) {
                          newErrors['cvv'] = true;
                          hasErrors = true;
                          }
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
                          
                          // Update card-specific fields
                          if (payment["type"] == "Card") {
                            if (numberController.text.isNotEmpty) {
                              // Format card number - mask all but last 4 digits
                            final cleanNumber = numberController.text.replaceAll(" ", "");
                              final lastFourDigits = cleanNumber.substring(12, 16);
                              paymentMethods[_selectedPaymentIndex]["number"] = "•••• •••• •••• " + lastFourDigits;
                          }
                          
                            if (expiryController.text.isNotEmpty) {
                            paymentMethods[_selectedPaymentIndex]["expiry"] = expiryController.text;
                          }
                          
                            if (cvvController.text.isNotEmpty) {
                            paymentMethods[_selectedPaymentIndex]["cvv"] = cvvController.text;
                            }
                          } else if (payment["type"] == "Wallet") {
                            // Update mobile wallet number if changed
                            if (numberController.text.isNotEmpty) {
                              paymentMethods[_selectedPaymentIndex]["number"] = numberController.text;
                            }
                            
                            // Update wallet icon based on name
                            if (nameController.text == "EasyPaisa") {
                              paymentMethods[_selectedPaymentIndex]["color"] = "0xFF4CAF50"; // Green for EasyPaisa
                            } else if (nameController.text == "JazzCash") {
                              paymentMethods[_selectedPaymentIndex]["color"] = "0xFFC2554D"; // Red for JazzCash
                            }
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

  // Method to remove a payment method
  void _removePaymentMethod(int index) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Remove Payment Method",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to remove this payment method?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () {
              // Close dialog
              Navigator.pop(context);
              
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
            },
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  void _showAddPaymentBottomSheet(String type, String name, String? colorCode) {
    // Implementation for adding new payment methods
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
              Icons.chevron_right,
              color: Colors.grey.shade400,
                                              size: 20,
                                    ),
                                  ],
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
}
