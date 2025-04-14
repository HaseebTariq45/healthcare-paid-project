import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> paymentMethods = [];
  bool _isLoading = false;
  int _selectedCardIndex = 0;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Load payment methods from Firestore
  Future<void> _loadPaymentMethods() async {
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
        paymentMethods = snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
            
        if (paymentMethods.isNotEmpty) {
          // Find default card if it exists
          int defaultIndex = paymentMethods.indexWhere((method) => method['isDefault'] == true);
          if (defaultIndex != -1) {
            _selectedCardIndex = defaultIndex;
          }
        }
      });
      
      if (paymentMethods.isEmpty && widget.userType == UserType.doctor) {
        // Create default bank account for doctors if none exists
        _createDefaultBankAccount();
      }
    } catch (e) {
      print('Error loading payment methods: ${e.toString()}');
      _showErrorSnackBar('Error loading payment methods: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Create a default bank account for doctors
  Future<void> _createDefaultBankAccount() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      // Create default bank account
      Map<String, dynamic> bankData = {
        'name': 'Primary Bank Account',
        'holder': 'Account Holder',
        'type': 'Bank',
        'number': 'Add your account number',
        'color': '0xFF3366FF',
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add(bankData);
          
      await _loadPaymentMethods();
    } catch (e) {
      _showErrorSnackBar('Error creating default account: ${e.toString()}');
    }
  }

  // Add new payment method to Firestore
  Future<void> _addPaymentMethod(Map<String, dynamic> cardData) async {
    setState(() => _isLoading = true);
    
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // If this is the first card, make it default
      if (paymentMethods.isEmpty) {
        cardData['isDefault'] = true;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add({
            ...cardData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _loadPaymentMethods();
      _showSuccessSnackBar('Payment method added successfully');
    } catch (e) {
      _showErrorSnackBar('Error adding payment method: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update existing payment method in Firestore
  Future<void> _updatePaymentMethod(String id, Map<String, dynamic> cardData) async {
    setState(() => _isLoading = true);
    
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(id)
          .update({
            ...cardData,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _loadPaymentMethods();
      _showSuccessSnackBar('Payment method updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error updating payment method: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete payment method from Firestore
  Future<void> _deletePaymentMethod(String id) async {
    setState(() => _isLoading = true);
    
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .doc(id)
          .delete();

      await _loadPaymentMethods();
      _showSuccessSnackBar('Payment method removed successfully');
    } catch (e) {
      _showErrorSnackBar('Error removing payment method: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Set a payment method as default
  Future<void> _setDefaultPaymentMethod(String id) async {
    setState(() => _isLoading = true);
    
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Start a batch write
      final batch = _firestore.batch();
      final paymentMethodsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods');

      // Set all payment methods to non-default
      for (var method in paymentMethods) {
        if (method['isDefault'] == true) {
          batch.update(paymentMethodsRef.doc(method['id']), {'isDefault': false});
        }
      }

      // Set the selected payment method as default
      batch.update(paymentMethodsRef.doc(id), {'isDefault': true});

      await batch.commit();
      await _loadPaymentMethods();
      _showSuccessSnackBar('Default payment method updated');
    } catch (e) {
      _showErrorSnackBar('Error updating default payment method: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3366FF)),
                  SizedBox(height: 20),
                  Text(
                    "Loading payment information...",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : widget.userType == UserType.doctor ? _buildDoctorPaymentView() : _buildPatientPaymentView(),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: () {
                // Show payment method options
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
                              _showAddPaymentBottomSheet("Card", "Credit Card", "0xFF3366FF");
                            },
                          ),
                          SizedBox(height: 12),
                          _buildMethodOption(
                            "Debit Card",
                            Icons.account_balance,
                            Color(0xFF4CAF50),
                            () {
                              Navigator.pop(context);
                              _showAddPaymentBottomSheet("Card", "Debit Card", "0xFF4CAF50");
                            },
                          ),
                          SizedBox(height: 12),
                          _buildMethodOption(
                            "Mobile Wallet",
                            Icons.smartphone,
                            Color(0xFFC2554D),
                            () {
                              Navigator.pop(context);
                              _showAddPaymentBottomSheet("Wallet", "Mobile Wallet", "0xFFC2554D");
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
      child: Form(
        key: _formKey,
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
            
            // Required fields note
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "Fields marked with * are required",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            
            // Bank name
            _buildBankFormField(
              "Bank Name",
              Icons.business,
              _cardNameController,
              "Enter bank name",
            ),
            SizedBox(height: 16),
            
            // Account title
            _buildBankFormField(
              "Account Title",
              Icons.person,
              _cardHolderController,
              "Enter account title",
            ),
            SizedBox(height: 16),
            
            // Account number
            _buildBankFormField(
              "Account Number",
              Icons.tag,
              _cardNumberController,
              "Enter account number",
            ),
            SizedBox(height: 16),
            
            // IBAN
            _buildBankFormField(
              "IBAN",
              Icons.account_balance,
              _cvvController,
              "Enter IBAN number",
            ),
            SizedBox(height: 16),
            
            // Two fields in one row: Branch Code and Swift Code
            Row(
              children: [
                Expanded(
                  child: _buildBankFormField(
                    "Branch Code",
                    Icons.numbers,
                    _expiryController,
                    "Enter branch code",
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildBankFormField(
                    "Swift Code",
                    Icons.code,
                    _cvvController,
                    "Enter swift code",
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save bank account details
                    _updatePaymentMethod(
                      paymentMethods[0]['id'],
                      {
                        'name': _cardNameController.text,
                        'holder': _cardHolderController.text,
                        'number': _cardNumberController.text,
                        'iban': _cvvController.text,
                        'branchCode': _expiryController.text,
                        'swiftCode': _cvvController.text,
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3366FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Save Changes",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
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
          ],
        ),
      ),
    );
  }

  // Build bank account card for doctors
  Widget _buildBankAccountCard() {
    if (paymentMethods.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "No bank account added yet",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Color(int.parse(paymentMethods[0]["color"])),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(paymentMethods[0]["color"])).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(paymentMethods[0]["color"])),
            Color(int.parse(paymentMethods[0]["color"])).withAlpha(220),
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
                  _maskAccountNumber(paymentMethods[0]["number"] ?? ""),
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
                          paymentMethods[0]["holder"] ?? "",
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
                          paymentMethods[0]["name"] ?? "",
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

  // Build a form field for bank details with validation
  Widget _buildBankFormField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hintText, {
    Function(String)? onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? "$label *" : label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: Color(0xFF3366FF), size: 20),
            fillColor: Colors.grey.shade50,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3366FF)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label is required";
            }
            return null;
          } : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  // Build patient payment view with card options
  Widget _buildPatientPaymentView() {
    // Handle empty payment methods
    if (paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.creditCard,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 24),
            Text(
              "No payment methods added yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Add a payment method to continue",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Show payment method options
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
                              _showAddPaymentBottomSheet("Card", "Credit Card", "0xFF3366FF");
                            },
                          ),
                          SizedBox(height: 12),
                          _buildMethodOption(
                            "Debit Card",
                            Icons.account_balance,
                            Color(0xFF4CAF50),
                            () {
                              Navigator.pop(context);
                              _showAddPaymentBottomSheet("Card", "Debit Card", "0xFF4CAF50");
                            },
                          ),
                          SizedBox(height: 12),
                          _buildMethodOption(
                            "Mobile Wallet",
                            Icons.smartphone,
                            Color(0xFFC2554D),
                            () {
                              Navigator.pop(context);
                              _showAddPaymentBottomSheet("Wallet", "Mobile Wallet", "0xFFC2554D");
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text("Add Payment Method"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3366FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Regular view for when payment methods exist
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
                _selectedCardIndex = index;
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
              width: index == _selectedCardIndex ? 24 : 8,
              decoration: BoxDecoration(
                color: index == _selectedCardIndex ? Color(0xFF3366FF) : Color(0xFFE0E0E0),
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
                paymentMethods[_selectedCardIndex]["type"] == "Wallet" 
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
                paymentMethods[_selectedCardIndex]["holder"],
                Icons.person,
              ),
              SizedBox(height: 16),
              _buildDetailsRow(
                paymentMethods[_selectedCardIndex]["type"] == "Wallet" 
                    ? "Mobile Number" 
                    : "Card Number",
                paymentMethods[_selectedCardIndex]["number"],
                paymentMethods[_selectedCardIndex]["type"] == "Wallet" 
                    ? Icons.smartphone 
                    : Icons.credit_card,
              ),
              if (paymentMethods[_selectedCardIndex]["expiry"] != null) ...[
                SizedBox(height: 16),
                _buildDetailsRow(
                  "Expiry Date",
                  paymentMethods[_selectedCardIndex]["expiry"],
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
                        _showEditPaymentBottomSheet(paymentMethods[_selectedCardIndex]);
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
                        _deletePaymentMethod(paymentMethods[_selectedCardIndex]["id"]);
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
    bool isSelected = index == _selectedCardIndex;
    
    // Determine correct icon based on payment type
    IconData cardIcon;
    switch(payment["type"]) {
      case "Wallet":
        cardIcon = Icons.account_balance_wallet;
        break;
      case "Bank":
        cardIcon = Icons.account_balance;
        break;
      case "Card":
      default:
        cardIcon = Icons.credit_card;
        break;
    }
    
    // Handle edge case where color might be missing
    String colorHex = payment["color"] ?? "0xFF3366FF";
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 12, left: 4, top: isSelected ? 0 : 12, bottom: isSelected ? 0 : 12),
      decoration: BoxDecoration(
        color: Color(int.parse(colorHex)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(colorHex)).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(colorHex)),
            Color(int.parse(colorHex)).withAlpha(220),
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
                          cardIcon,
                          color: Colors.white,
                          size: 26,
                        ),
                        SizedBox(width: 8),
                        Text(
                          payment["name"] ?? payment["type"] ?? "Payment Card",
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
                        cardIcon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  payment["number"] ?? "••••••••",
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
                          payment["type"] == "Bank" ? "ACCOUNT HOLDER" : "CARD HOLDER",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          payment["holder"] ?? "Card Holder",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (payment["expiry"] != null && payment["expiry"].toString().isNotEmpty)
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
          if (payment["isDefault"] == true)
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
                      color: Color(int.parse(colorHex)),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Default",
                      style: GoogleFonts.poppins(
                        color: Color(int.parse(colorHex)),
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

  Widget _buildDetailsRow(String label, String? value, IconData icon) {
    // Handle null or empty values
    final displayValue = (value == null || value.isEmpty) ? "Not provided" : value;
    
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
          Expanded(
            child: Column(
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
                  displayValue,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: (value == null || value.isEmpty) ? Colors.grey : Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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

  void _showAddPaymentBottomSheet(String type, String name, String? colorCode) {
    // Reset form fields
    _cardNameController.text = name;
    _cardHolderController.text = '';
    _cardNumberController.text = '';
    _expiryController.text = '';
    _cvvController.text = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add $name",
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
                    
                    // Card display name
                    TextFormField(
                      controller: _cardNameController,
                      decoration: InputDecoration(
                        labelText: type == "Wallet" ? "Wallet Name" : "Card Name",
                        prefixIcon: Icon(type == "Wallet" ? LucideIcons.wallet : LucideIcons.creditCard),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Holder name
                    TextFormField(
                      controller: _cardHolderController,
                      decoration: InputDecoration(
                        labelText: type == "Wallet" ? "Account Holder" : "Cardholder Name",
                        prefixIcon: Icon(LucideIcons.user),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter holder name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Card number or wallet number
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        labelText: type == "Wallet" ? "Mobile Number" : "Card Number",
                        prefixIcon: Icon(type == "Wallet" ? LucideIcons.smartphone : LucideIcons.creditCard),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (type == "Card") {
                          // Format card number with spaces
                          if (value.length > 0 && value[value.length - 1] != ' ') {
                            final trimmedValue = value.replaceAll(' ', '');
                            if (trimmedValue.length > 0 && trimmedValue.length % 4 == 0 && trimmedValue.length < 16) {
                              _cardNumberController.text = _formatCardNumber(trimmedValue);
                              _cardNumberController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _cardNumberController.text.length),
                              );
                            }
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return type == "Wallet" ? 'Please enter mobile number' : 'Please enter card number';
                        }
                        if (type == "Card" && value.replaceAll(' ', '').length != 16) {
                          return 'Please enter a valid 16-digit card number';
                        }
                        return null;
                      },
                    ),
                    
                    // Expiry date (for cards only)
                    if (type == "Card") ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _expiryController,
                        decoration: InputDecoration(
                          labelText: "Expiry Date (MM/YY)",
                          prefixIcon: Icon(LucideIcons.calendar),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter expiry date';
                          }
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                            return 'Please use MM/YY format';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.length == 2 && !value.contains('/')) {
                            _expiryController.text = '$value/';
                            _expiryController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _expiryController.text.length),
                            );
                          }
                        },
                      ),

                      // CVV (for cards only)
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: "CVV",
                          prefixIcon: Icon(LucideIcons.key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter CVV';
                          }
                          if (value.length != 3) {
                            return 'CVV must be 3 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    SizedBox(height: 24),
                    
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Get form data
                            String name = _cardNameController.text;
                            String holder = _cardHolderController.text;
                            String number = _cardNumberController.text;
                            String expiry = type == "Card" ? _expiryController.text : '';
                            String cvv = type == "Card" ? _cvvController.text : '';
                            
                            // Choose a default color if none provided
                            final defaultColor = type == "Wallet" ? "0xFFC2554D" : "0xFF3366FF";
                            
                            // Prepare card data
                            Map<String, dynamic> cardData = {
                              'name': name,
                              'holder': holder,
                              'type': type,
                              'color': colorCode ?? defaultColor,
                              'expiry': expiry,
                            };
                            
                            // Format and store card number
                            if (type == "Card") {
                              final cleanNumber = number.replaceAll(' ', '');
                              // Store last four digits for display
                              cardData['number'] = '•••• •••• •••• ${cleanNumber.substring(cleanNumber.length - 4)}';
                              // Don't store full card number for security, but you could encrypt it if needed
                            } else {
                              cardData['number'] = number;
                            }
                            
                            // Add the payment method
                            await _addPaymentMethod(cardData);
                            
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3366FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
              ),
            ),
          ),
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

  void _showEditPaymentBottomSheet(Map<String, dynamic> payment) {
    _cardNameController.text = payment['name'] ?? '';
    _cardHolderController.text = payment['holder'] ?? '';
    _cardNumberController.text = '';  // Don't show full number for security
    _expiryController.text = payment['expiry'] ?? '';
    _cvvController.text = '';  // Don't show CVV for security

    // Determine if this is a bank account, card, or wallet
    final type = payment['type'] ?? 'Card';
    final bool isBank = type == 'Bank';
    final bool isCard = type == 'Card';
    final bool isWallet = type == 'Wallet';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Edit ${isBank ? 'Bank Account' : isWallet ? 'Wallet' : 'Card'}",
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
                    
                    // Name field
                    TextFormField(
                      controller: _cardNameController,
                      decoration: InputDecoration(
                        labelText: isBank ? "Bank Name" : isWallet ? "Wallet Name" : "Card Name",
                        prefixIcon: Icon(
                          isBank ? Icons.account_balance : 
                          isWallet ? LucideIcons.wallet : 
                          LucideIcons.creditCard
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Holder name
                    TextFormField(
                      controller: _cardHolderController,
                      decoration: InputDecoration(
                        labelText: isBank ? "Account Holder" : isWallet ? "Account Holder" : "Cardholder Name",
                        prefixIcon: Icon(LucideIcons.user),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter holder name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Card/Account Number field
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        labelText: isBank ? "Account Number" : 
                                  isWallet ? "Mobile Number" : 
                                  "New Card Number",
                        prefixIcon: Icon(
                          isBank ? Icons.tag : 
                          isWallet ? LucideIcons.smartphone : 
                          LucideIcons.creditCard
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: "Leave blank to keep existing number",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (isCard && value.replaceAll(' ', '').length != 16) {
                            return 'Please enter a valid 16-digit card number';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    // Expiry Date (for cards only)
                    if (isCard) ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _expiryController,
                        decoration: InputDecoration(
                          labelText: "Expiry Date (MM/YY)",
                          prefixIcon: Icon(LucideIcons.calendar),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter expiry date';
                          }
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                            return 'Please use MM/YY format';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.length == 2 && !value.contains('/')) {
                            _expiryController.text = '$value/';
                            _expiryController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _expiryController.text.length),
                            );
                          }
                        },
                      ),
                    ],
                    
                    // CVV field (for cards only)
                    if (isCard) ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: "New CVV (optional)",
                          prefixIcon: Icon(LucideIcons.key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: "Leave blank to keep existing CVV",
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length != 3) {
                              return 'CVV must be 3 digits';
                            }
                          }
                          return null;
                        },
                      ),
                    ],

                    // Additional fields for bank accounts
                    if (isBank) ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _expiryController,
                        decoration: InputDecoration(
                          labelText: "IBAN or Branch Code",
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 24),
                    
                    // Set default checkbox
                    if (!payment['isDefault']) ...[
                      CheckboxListTile(
                        title: Text(
                          "Set as default payment method",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: payment['isDefault'] ?? false,
                        onChanged: (value) {
                          setModalState(() {
                            payment['isDefault'] = value;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Prepare update data
                            Map<String, dynamic> updateData = {
                              'name': _cardNameController.text,
                              'holder': _cardHolderController.text,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };
                            
                            // Handle card/account number update
                            if (_cardNumberController.text.isNotEmpty) {
                              if (isCard) {
                                // For card, only store last 4 digits for display
                                final cleanNumber = _cardNumberController.text.replaceAll(' ', '');
                                updateData['number'] = '•••• •••• •••• ${cleanNumber.substring(cleanNumber.length - 4)}';
                              } else {
                                // For wallet/bank, store full number
                                updateData['number'] = _cardNumberController.text;
                              }
                            }
                            
                            // Handle expiry date update for cards
                            if (isCard && _expiryController.text != payment['expiry']) {
                              updateData['expiry'] = _expiryController.text;
                            }
                            
                            // Handle IBAN/branch code for bank accounts
                            if (isBank && _expiryController.text.isNotEmpty) {
                              updateData['iban'] = _expiryController.text;
                            }
                            
                            // Set default status if changed
                            if (payment['isDefault'] == true && !payment['isDefault']) {
                              await _setDefaultPaymentMethod(payment['id']);
                            }
                            
                            // Update the payment method
                            await _updatePaymentMethod(payment['id'], updateData);
                            
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3366FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
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
            onPressed: () async {
              Navigator.pop(context);
              await _deletePaymentMethod(id);
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

  Widget _buildPaymentMethodCard(Map<String, dynamic> payment) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(int.parse(payment['color'])),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  payment['type'] == 'Card' ? LucideIcons.creditCard : LucideIcons.wallet,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        payment['number'],
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (payment['isDefault'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Default",
                      style: GoogleFonts.poppins(
                        color: Color(int.parse(payment['color'])),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditPaymentBottomSheet(payment),
                  icon: Icon(Icons.edit, size: 18),
                  label: Text("Edit"),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF3366FF),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(payment['id']),
                  icon: Icon(LucideIcons.trash2, size: 18),
                  label: Text("Remove"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
