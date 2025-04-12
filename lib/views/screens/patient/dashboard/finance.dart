import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  payment,
  refund,
}

enum TransactionStatus {
  completed,
  pending,
  failed,
}

class FinancialTransaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionStatus status;
  final String? appointmentId;
  final String? doctorName;
  final String? hospitalName;

  FinancialTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    this.appointmentId,
    this.doctorName,
    this.hospitalName,
  });

  factory FinancialTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinancialTransaction(
      id: doc.id,
      title: data['title'] ?? 'Payment',
      description: data['description'] ?? '',
      amount: (data['amount'] is int) ? data['amount'].toDouble() : (data['amount'] ?? 0.0),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] == 'refund' ? TransactionType.refund : TransactionType.payment,
      status: _getStatusFromString(data['status']),
      appointmentId: data['appointmentId'],
      doctorName: data['doctorName'],
      hospitalName: data['hospitalName'],
    );
  }

  static TransactionStatus _getStatusFromString(String? status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
        return TransactionStatus.failed;
      case 'completed':
      default:
        return TransactionStatus.completed;
    }
  }
}

class PatientFinancesScreen extends StatefulWidget {
  const PatientFinancesScreen({super.key});

  @override
  State<PatientFinancesScreen> createState() => _PatientFinancesScreenState();
}

class _PatientFinancesScreenState extends State<PatientFinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  TransactionType? _selectedType;
  
  // Financial summary data
  Map<String, num> _financialSummary = {
    'totalPaid': 0,
    'pendingPayments': 0,
    'refunds': 0,
  };
  
  bool _isLoading = true;
  String? _userId;
  List<FinancialTransaction> _transactions = [];
  List<FinancialTransaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialize data
    _getUserId();
  }

  void _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _loadFinancialData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
        
        // Update selected type based on tab
        switch (_selectedTabIndex) {
          case 0: // All
            _selectedType = null;
            _filterTransactions(null);
            break;
          case 1: // Payments
            _selectedType = TransactionType.payment;
            _filterTransactions(TransactionType.payment);
            break;
          case 2: // Refunds
            _selectedType = TransactionType.refund;
            _filterTransactions(TransactionType.refund);
            break;
        }
      });
    }
  }

  void _filterTransactions(TransactionType? type) {
    if (type == null) {
      _filteredTransactions = _transactions;
    } else {
      _filteredTransactions = _transactions.where((tx) => tx.type == type).toList();
    }
  }

  // Load financial data from Firebase
  Future<void> _loadFinancialData() async {
    print('Starting to load financial data...');
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_userId == null) {
        print('Error: No user ID available');
        return;
      }
      print('Loading financial data for user: $_userId');

      final firestore = FirebaseFirestore.instance;
      List<FinancialTransaction> fetchedTransactions = [];
      
      // Load patient payments
      await _loadPatientPayments(firestore, fetchedTransactions);
      
      print('Final transaction count: ${fetchedTransactions.length}');
      print('Transactions loaded: ${fetchedTransactions.map((t) => 'ID: ${t.id}, Amount: ${t.amount}, Status: ${t.status}').join('\n')}');
      
      // Calculate financial summary
      double totalPaid = 0;
      double pendingPayments = 0;
      double refunds = 0;
      
      for (var tx in fetchedTransactions) {
        if (tx.type == TransactionType.payment && tx.status == TransactionStatus.completed) {
          totalPaid += tx.amount;
        } else if (tx.type == TransactionType.payment && tx.status == TransactionStatus.pending) {
          pendingPayments += tx.amount;
        } else if (tx.type == TransactionType.refund) {
          refunds += tx.amount;
        }
      }
      
      print('Summary - Total Paid: $totalPaid, Pending: $pendingPayments, Refunds: $refunds');
      
      setState(() {
        _transactions = fetchedTransactions;
        _filterTransactions(_selectedType); // Apply current filter
        
        _financialSummary = {
          'totalPaid': totalPaid,
          'pendingPayments': pendingPayments,
          'refunds': refunds,
        };
        
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading financial data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load patient payments
  Future<void> _loadPatientPayments(FirebaseFirestore firestore, List<FinancialTransaction> fetchedTransactions) async {
    print('\nQuerying appointments collection...');
    final appointmentsSnapshot = await firestore
        .collection('appointments')
        .where('patientId', isEqualTo: _userId)
        .get();
        
    print('Found ${appointmentsSnapshot.docs.length} appointments');
        
    for (var doc in appointmentsSnapshot.docs) {
      final appointmentData = doc.data();
      print('\nProcessing appointment: ${doc.id}');
      print('Raw appointment data: $appointmentData');
      
      // Check for payment-related fields
      print('Payment Status: ${appointmentData['paymentStatus']}');
      print('Payment Method: ${appointmentData['paymentMethod']}');
      print('Fee: ${appointmentData['fee']}');
      print('Consultation Fee: ${appointmentData['consultationFee']}');
      
      // Include appointments with any payment information
      if (appointmentData['paymentStatus'] != null || 
          appointmentData['paymentMethod'] != null ||
          appointmentData['fee'] != null ||
          appointmentData['consultationFee'] != null) {
        
        // Get doctor information if available
        String? doctorName;
        if (appointmentData['doctorId'] != null) {
          print('Fetching doctor info for ID: ${appointmentData['doctorId']}');
          final doctorDoc = await firestore
              .collection('doctors')
              .doc(appointmentData['doctorId'])
              .get();
              
          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            doctorName = doctorData['fullName'] ?? doctorData['name'] ?? appointmentData['doctorName'];
            print('Found doctor name: $doctorName');
          }
        }
        
        // Get the fee amount
        double amount = 0.0;
        if (appointmentData['fee'] != null && appointmentData['fee'] is num) {
          amount = appointmentData['fee'].toDouble();
        } else if (appointmentData['consultationFee'] != null && appointmentData['consultationFee'] is num) {
          amount = appointmentData['consultationFee'].toDouble();
        }
        print('Calculated amount: $amount');
        
        // Determine transaction status
        TransactionStatus status;
        final paymentStatus = appointmentData['paymentStatus']?.toString().toLowerCase() ?? 'pending';
        print('Payment status for processing: $paymentStatus');
        
        switch(paymentStatus) {
          case 'completed':
          case 'success':
          case 'paid':
          case 'confirmed':
            status = TransactionStatus.completed;
            break;
          case 'failed':
          case 'cancelled':
          case 'rejected':
            status = TransactionStatus.failed;
            break;
          default:
            status = TransactionStatus.pending;
        }
        print('Determined transaction status: $status');
        
        // Create and add transaction
        final transaction = FinancialTransaction(
          id: doc.id,
          title: 'Medical Appointment',
          description: '${appointmentData['paymentMethod'] ?? 'Payment'} - ${appointmentData['reason'] ?? 'Consultation'}',
          amount: amount,
          date: appointmentData['paymentDate'] != null 
              ? (appointmentData['paymentDate'] as Timestamp).toDate()
              : appointmentData['createdAt'] != null 
                  ? (appointmentData['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
          type: TransactionType.payment,
          status: status,
          appointmentId: doc.id,
          doctorName: doctorName ?? appointmentData['doctorName'],
          hospitalName: appointmentData['hospitalName'] ?? appointmentData['location'],
        );
        
        print('Adding transaction: ID=${transaction.id}, Amount=${transaction.amount}, Status=${transaction.status}');
        fetchedTransactions.add(transaction);
      }
    }
    
    print('\nChecking transactions collection...');
    final transactionsSnapshot = await firestore
        .collection('transactions')
        .where('patientId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .get();
    
    print('Found ${transactionsSnapshot.docs.length} direct transactions');
    
    // Add any additional transactions found
    for (var doc in transactionsSnapshot.docs) {
      if (!fetchedTransactions.any((t) => t.id == doc.id)) {
        final transaction = FinancialTransaction.fromFirestore(doc);
        print('Adding direct transaction: ID=${transaction.id}, Amount=${transaction.amount}, Status=${transaction.status}');
        fetchedTransactions.add(transaction);
      }
    }
    
    print('\nFinal transaction count: ${fetchedTransactions.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFinancialSummary(),
            _buildTabBar(),
            Expanded(
              child: _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment History',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Track all your medical payments',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _loadFinancialData,
            icon: Icon(LucideIcons.refreshCcw),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0167FF), Color(0xFF0157FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0167FF).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount Paid',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_financialSummary['totalPaid']}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      title: 'Pending',
                      amount: _financialSummary['pendingPayments'],
                      icon: LucideIcons.clock,
                      iconColor: Colors.orangeAccent,
                    ),
                    _buildSummaryItem(
                      title: 'Refunds',
                      amount: _financialSummary['refunds'],
                      icon: LucideIcons.arrowUp,
                      iconColor: Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required num? amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              'Rs. ${amount ?? 0}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Color(0xFF0167FF),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black87,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Payments'),
          Tab(text: 'Refunds'),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.receipt,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedType == null
                  ? 'Your payment history will appear here'
                  : 'No ${_selectedType == TransactionType.payment ? 'payment' : 'refund'} transactions found',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(FinancialTransaction transaction) {
    final isPayment = transaction.type == TransactionType.payment;
    final isCompleted = transaction.status == TransactionStatus.completed;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPayment ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.creditCard,
                  color: isPayment ? Colors.blue : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment ? '-' : '+'} Rs. ${transaction.amount}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isPayment ? Colors.red : Colors.green,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                        ? Colors.green.withOpacity(0.1) 
                        : transaction.status == TransactionStatus.pending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status.toString().split('.').last,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isCompleted 
                          ? Colors.green 
                          : transaction.status == TransactionStatus.pending
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (transaction.doctorName != null || transaction.hospitalName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 46),
              child: Text(
                [
                  if (transaction.doctorName != null) 'Dr. ${transaction.doctorName}',
                  if (transaction.hospitalName != null) transaction.hospitalName,
                ].where((item) => item != null).join(' • '),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

