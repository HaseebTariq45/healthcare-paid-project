import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Transaction model class for Firebase data
class Transaction {
  final String id;
  final String amount;
  final String bank;
  final String account;
  final String date;
  final String time;
  final String status;
  
  Transaction({
    required this.id,
    required this.amount,
    required this.bank,
    required this.account,
    required this.date,
    required this.time,
    required this.status,
  });
  
  // Factory constructor to create Transaction from Firebase document
  factory Transaction.fromFirebase(Map<String, dynamic> data, String docId) {
    return Transaction(
      id: docId,
      amount: data['amount'] ?? 'Rs 0',
      bank: data['bank'] ?? 'Unknown Bank',
      account: data['account'] ?? '••••0000',
      date: data['date'] ?? '--',
      time: data['time'] ?? '--',
      status: data['status'] ?? 'pending',
    );
  }
  
  // Convert to map for easy testing/mocking
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'bank': bank,
      'account': account,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() => _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = "All";
  
  // Data loading states
  bool _isLoading = true;
  String? _error;
  
  // List to hold transactions - will be populated from Firebase
  List<Transaction> _transactions = [];
  
  // Sample data for development - will be replaced with Firebase fetch
  final List<Map<String, dynamic>> _sampleData = [
    {
      "amount": "Rs 15,000",
      "bank": "HDFC Bank",
      "account": "••••4582",
      "date": "Dec 30, 2024",
      "status": "completed",
      "id": "TXN-487523",
      "time": "10:45 AM"
    },
    {
      "amount": "Rs 8,500",
      "bank": "SBI",
      "account": "••••2290",
      "date": "Dec 18, 2024",
      "status": "completed",
      "id": "TXN-487120",
      "time": "02:30 PM"
    },
    {
      "amount": "Rs 22,000",
      "bank": "Axis Bank",
      "account": "••••8821",
      "date": "Nov 29, 2024",
      "status": "pending",
      "id": "TXN-485712",
      "time": "11:20 AM"
    },
    {
      "amount": "Rs 6,750",
      "bank": "ICICI Bank",
      "account": "••••1233",
      "date": "Nov 15, 2024",
      "status": "completed",
      "id": "TXN-482951",
      "time": "09:15 AM"
    },
    {
      "amount": "Rs 12,400",
      "bank": "HDFC Bank",
      "account": "••••4582",
      "date": "Oct 22, 2024",
      "status": "failed",
      "id": "TXN-479825",
      "time": "03:50 PM"
    },
  ];
  
  // Filter options
  final List<String> filters = ["All", "Completed", "Pending", "Failed"];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Load transactions
    _loadTransactions();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Load transactions from Firebase (currently using sample data)
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 800));
      
      // TODO: Replace with actual Firebase code:
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('withdrawals')
      //     .orderBy('timestamp', descending: true)
      //     .get();
      // 
      // final transactions = snapshot.docs.map(
      //   (doc) => Transaction.fromFirebase(doc.data(), doc.id)
      // ).toList();
      
      // For now, using sample data
      final transactions = _sampleData.map((data) {
        return Transaction.fromFirebase(data, data['id'] as String);
      }).toList();
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
      
      // Start animation after data is loaded
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _error = "Failed to load transactions: $e";
        _isLoading = false;
      });
    }
  }
  
  // Filter transactions based on selected filter
  List<Transaction> get filteredTransactions {
    if (_selectedFilter == "All") {
      return _transactions;
    }
    return _transactions.where(
      (transaction) => transaction.status.toLowerCase() == _selectedFilter.toLowerCase()
    ).toList();
  }

  // Calculate the total amount withdrawn
  String get totalAmount {
    double total = 0;
    for (var transaction in _transactions) {
      // Remove non-numeric characters and parse
      final amount = transaction.amount.replaceAll(RegExp(r'[^0-9.]'), '');
      total += double.tryParse(amount) ?? 0;
    }
    return "Rs ${total.toStringAsFixed(0)}";
  }
  
  // Get count of completed transactions
  int get completedTransactionsCount {
    return _transactions.where((t) => t.status.toLowerCase() == 'completed').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Withdrawal History",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Column(
          children: [
            // Filter section
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
        child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
          itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == filters[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filters[index];
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF3366FF) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Color(0xFF3366FF) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        filters[index],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Color(0xFF666666),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Summary card
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3366FF), Color(0xFF5B8DEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3366FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Withdrawals",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "This Month",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isLoading ? "Rs --" : totalAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatItem(
                          _isLoading ? "--" : _transactions.length.toString(),
                          "Transactions"
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                          margin: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        _buildStatItem(
                          _isLoading ? "--" : completedTransactionsCount.toString(),
                          "Completed"
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Transactions header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Withdrawals",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    _isLoading 
                        ? "Loading..." 
                        : "${filteredTransactions.length} transactions",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content - Loading, Error, Empty, or Transaction list
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_transactions.isEmpty) {
      return _buildEmptyState("No transactions found", "You don't have any withdrawal transactions yet.");
    }
    
    if (filteredTransactions.isEmpty) {
      return _buildEmptyState(
        "No ${_selectedFilter.toLowerCase()} transactions", 
        "Try changing the filter to see other transactions."
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (1 / filteredTransactions.length) * index,
              (1 / filteredTransactions.length) * (index + 1),
              curve: Curves.easeOut,
            ),
          ),
        );
        return _buildTransactionCard(filteredTransactions[index], animation);
      },
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF3366FF),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            "Loading transactions...",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.info,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            "Oops! Something went wrong",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? "Failed to load transactions",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTransactions,
            icon: Icon(LucideIcons.refreshCw, size: 16),
            label: Text("Try Again"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF3366FF),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.fileSearch,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction, Animation<double> animation) {
    final statusColor = _getStatusColor(transaction.status);
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.05, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showTransactionDetails(transaction),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Transaction icon with bank indicator
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getBankColor(transaction.bank).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.banknote,
                            color: _getBankColor(transaction.bank),
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                              "Withdrawn ${transaction.amount}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${transaction.bank} • ${transaction.account}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status indicator
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Date and transaction ID
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(LucideIcons.calendar, transaction.date),
                        _buildInfoItem(LucideIcons.clock, transaction.time),
                        _buildInfoItem(LucideIcons.hash, "ID: ${transaction.id}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Color(0xFF666666),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Color(0xFF4CAF50);
      case 'pending':
        return Color(0xFFFF9800);
      case 'failed':
        return Color(0xFFE74C3C);
      default:
        return Color(0xFF3366FF);
    }
  }
  
  Color _getBankColor(String bank) {
    switch (bank) {
      case 'HDFC Bank':
        return Color(0xFF3366FF);
      case 'SBI':
        return Color(0xFF6C757D);
      case 'Axis Bank':
        return Color(0xFF8E44AD);
      case 'ICICI Bank':
        return Color(0xFFE74C3C);
      default:
        return Color(0xFF3366FF);
    }
  }
  
  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaction Details",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                    color: Color(0xFF666666),
                  ),
                ],
              ),
            ),
            // Status indicator
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(transaction.status),
                      color: _getStatusColor(transaction.status),
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(transaction.status),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getStatusMessage(transaction.status),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Transaction details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem("Amount", transaction.amount, isAmount: true),
                    _buildDetailItem("Bank", transaction.bank),
                    _buildDetailItem("Account", transaction.account),
                    _buildDetailItem("Date", transaction.date),
                    _buildDetailItem("Time", transaction.time),
                    _buildDetailItem("Transaction ID", transaction.id),
                    SizedBox(height: 20),
                    _buildSupportSection(),
                  ],
                ),
              ),
            ),
            // Action button
            Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Receipt downloaded successfully'),
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
                    "Download Receipt",
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
    );
  }
  
  Widget _buildDetailItem(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
                Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
                Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
              color: isAmount ? Color(0xFF3366FF) : Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Need Help?",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "If you have any questions about this transaction, please contact our support team.",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
            onPressed: () {},
                  icon: Icon(LucideIcons.messageCircle, size: 16),
                  label: Text("Chat Support"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3366FF),
                    side: BorderSide(color: Color(0xFF3366FF)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return LucideIcons.check;
      case 'pending':
        return LucideIcons.loader;
      case 'failed':
        return LucideIcons.x;
      default:
        return LucideIcons.info;
    }
  }
  
  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Amount transferred successfully';
      case 'pending':
        return 'Transaction is processing';
      case 'failed':
        return 'Transaction could not be processed';
      default:
        return 'Status unknown';
    }
  }
}
