import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/transaction_model.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/services/financial_repository.dart';
import 'package:intl/intl.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  late final FinancialRepository _financialRepository;
  
  // Financial data
  bool _isLoading = true;
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _currentMonthIncome = 0.0;
  double _pendingAmount = 0.0;
  
  // Transactions
  List<TransactionItem> _transactions = [];

  @override
  void initState() {
    super.initState();
    _financialRepository = FinancialRepository();
    _loadFinancialData();
  }
  
  // Load all financial data
  Future<void> _loadFinancialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // First try to load using FinancialRepository
      bool success = await _loadTransactionsFromRepository();
      
      // If not successful, fallback to direct Firestore loading
      if (!success) {
        // Load transactions
        await _loadTransactions(currentUser.uid);
      }
      
      // Calculate financial summaries
      _calculateFinancialSummaries();
      
    } catch (e) {
      print('Error loading financial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Attempt to load transactions using the FinancialRepository
  Future<bool> _loadTransactionsFromRepository() async {
    try {
      // Clear existing transactions
      _transactions.clear();
      
      // Get transactions stream from the repository
      final transactionsStream = _financialRepository.getTransactions(limit: 20);
      
      // Convert stream to list
      final transactionsList = await transactionsStream.first;
      
      // If no transactions, return false to use fallback
      if (transactionsList.isEmpty) {
        return false;
      }
      
      // Convert FinancialTransaction to TransactionItem
      for (var transaction in transactionsList) {
        _transactions.add(TransactionItem(
          transaction.title,
          'Rs ${transaction.amount.toStringAsFixed(0)}',
          DateFormat('dd MMM, yyyy').format(transaction.date),
          _convertTransactionType(transaction.type),
        ));
      }
      
      return true;
    } catch (e) {
      print('Error loading from repository: $e');
      return false;
    }
  }
  
  // Helper method to convert between TransactionType enums
  TransactionType _convertTransactionType(dynamic modelType) {
    if (modelType == null) return TransactionType.income;
    
    // Check if it's a string first
    if (modelType is String) {
      return modelType == 'expense' ? TransactionType.expense : TransactionType.income;
    }
    
    // Handle the case where it's the model's TransactionType enum
    try {
      final typeValue = modelType.toString().split('.').last;
      return typeValue == 'expense' ? TransactionType.expense : TransactionType.income;
    } catch (e) {
      return TransactionType.income;
    }
  }
  
  // Load transactions from Firestore
  Future<void> _loadTransactions(String userId) async {
    try {
      // Clear existing transactions
      _transactions.clear();
      
      // Fetch all transactions where the doctor is the recipient (doctorId matches userId)
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('doctorId', isEqualTo: userId)
          .where('type', isEqualTo: 'payment')
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
      
      // If no transactions found, try loading from appointments
      if (transactionsSnapshot.docs.isEmpty) {
        await _loadTransactionsFromAppointments(userId);
      } else {
        // Process transactions
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          
          // Get patient name for better description
          String patientName = "Patient";
          if (data['patientId'] != null) {
            try {
              final patientDoc = await _firestore
                  .collection('users')
                  .doc(data['patientId'])
                  .get();
              
              if (patientDoc.exists && patientDoc.data() != null) {
                patientName = patientDoc.data()!['fullName'] ?? "Patient";
              }
            } catch (e) {
              print('Error fetching patient name: $e');
            }
          }

          String title = data['title'] ?? 'Payment Received';
          String description = data['description'] ?? 'Payment from $patientName';
          double amount = data['amount'] is num ? (data['amount'] as num).toDouble() : 0.0;
          DateTime date = data['date'] is Timestamp 
              ? (data['date'] as Timestamp).toDate() 
              : DateTime.now();
          
          // For doctors, all payments received are considered income
          _transactions.add(TransactionItem(
            description,
            'Rs ${amount.toStringAsFixed(0)}',
            DateFormat('dd MMM, yyyy').format(date),
            TransactionType.income,
          ));
        }
      }
    } catch (e) {
      print('Error loading transactions: $e');
      // If there was an error, load from appointments as fallback
      await _loadTransactionsFromAppointments(userId);
    }
  }
  
  // Load transactions from appointments as an alternative source
  Future<void> _loadTransactionsFromAppointments(String userId) async {
    try {
      // Fetch completed appointments for doctor
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .where('paymentStatus', isEqualTo: 'completed')
          .orderBy('paymentDate', descending: true)
          .limit(20)
          .get();
      
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        
        // Get patient name
        String patientName = "Patient";
        if (data.containsKey('patientId')) {
          try {
            final patientDoc = await _firestore
                .collection('users')
                .doc(data['patientId'])
                .get();
            
            if (patientDoc.exists && patientDoc.data() != null) {
              patientName = patientDoc.data()!['fullName'] ?? "Patient";
            }
          } catch (e) {
            print('Error fetching patient: $e');
          }
        }
        
        // Prepare transaction data
        String title = "Payment from $patientName";
        double amount = data['fee'] is num ? (data['fee'] as num).toDouble() : 0.0;
        DateTime date = data['paymentDate'] is Timestamp 
            ? (data['paymentDate'] as Timestamp).toDate() 
            : (data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : DateTime.now());
        
        // For doctors, all appointment payments are income
        _transactions.add(TransactionItem(
          title,
          'Rs ${amount.toStringAsFixed(0)}',
          DateFormat('dd MMM, yyyy').format(date),
          TransactionType.income,
        ));
      }
    } catch (e) {
      print('Error loading transactions from appointments: $e');
    }
  }
  
  // Calculate financial summaries based on loaded transactions
  void _calculateFinancialSummaries() {
    _totalIncome = 0.0;
    _totalExpenses = 0.0;
    _currentMonthIncome = 0.0;
    _pendingAmount = 0.0;
    
    // Get current month and year
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    for (var transaction in _transactions) {
      // Extract amount (remove 'Rs ' and convert to double)
      final amountStr = transaction.amount.replaceAll('Rs ', '').replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0.0;
      
      // Calculate totals based on transaction type
      if (transaction.type == TransactionType.income) {
        _totalIncome += amount;
        
        // Check if transaction is from current month
        final transactionDate = DateFormat('dd MMM, yyyy').parse(transaction.date);
        if (transactionDate.month == currentMonth && transactionDate.year == currentYear) {
          _currentMonthIncome += amount;
        }
      } else {
        _totalExpenses += amount;
      }
    }
    
    // Calculate total balance
    _totalBalance = _totalIncome - _totalExpenses;
    
    // Set pending amount (10% of total income as an example)
    // In a real app, you would query pending transactions
    _pendingAmount = _totalIncome * 0.1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(64, 124, 226, 1),
              ),
            )
          : SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom app bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "Financial Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(64, 124, 226, 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: Color.fromRGBO(64, 124, 226, 1),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main financial summary
            Container(
              margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(64, 124, 226, 1),
                    Color.fromRGBO(84, 144, 246, 1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(64, 124, 226, 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Total Balance",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Rs ${_totalBalance.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceItem(
                        "Income",
                        "Rs ${_totalIncome.toStringAsFixed(0)}",
                        LucideIcons.arrowDown,
                        Colors.greenAccent,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildBalanceItem(
                        "Expenses",
                        "Rs ${_totalExpenses.toStringAsFixed(0)}",
                        LucideIcons.arrowUp,
                        Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Financial stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "This Month",
                      "Rs ${_currentMonthIncome.toStringAsFixed(0)}",
                      Color(0xFFE8F5E9),
                      LucideIcons.calendar,
                      Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      "Pending",
                      "Rs ${_pendingAmount.toStringAsFixed(0)}",
                      Color(0xFFFFF3E0),
                      LucideIcons.hourglass,
                      Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            ),
            
            // Recent transactions heading
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Refresh transactions
                      _loadFinancialData();
                    },
                    child: Text(
                      "Refresh",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(64, 124, 226, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions list
            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.database,
                            size: 50,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No transactions found",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _transactions.length,
                itemBuilder: (context, index) {
                        return _buildTransactionCard(_transactions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String title, String amount, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 2),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    Color bgColor,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          SizedBox(height: 12),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    final isIncome = transaction.type == TransactionType.income;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome 
                  ? Color(0xFFE8F5E9) 
                  : Color(0xFFFBE9E7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              color: isIncome ? Color(0xFF4CAF50) : Color(0xFFF44336),
              size: 22,
            ),
          ),
          SizedBox(width: 15),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  transaction.date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            transaction.amount,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isIncome ? Color(0xFF4CAF50) : Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

enum TransactionType { income, expense }

class TransactionItem {
  final String title;
  final String amount;
  final String date;
  final TransactionType type;

  TransactionItem(this.title, this.amount, this.date, this.type);
}
