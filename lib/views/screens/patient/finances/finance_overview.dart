import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../models/transaction_model.dart';
import '../../../../services/mock_financial_repository.dart';
import '../../../../utils/app_constants.dart';

class FinanceOverviewScreen extends StatefulWidget {
  const FinanceOverviewScreen({Key? key}) : super(key: key);

  @override
  State<FinanceOverviewScreen> createState() => _FinanceOverviewScreenState();
}

class _FinanceOverviewScreenState extends State<FinanceOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FinancialRepository _repository;
  bool _useMockData = true; // Set to false when ready to use Firebase

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize repository with mock user ID
    _repository = FinancialRepository();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Financial Overview",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFinancialSummary(),
          const SizedBox(height: 16),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTransactions(),
                _buildTransactionsByType(TransactionType.payment),
                _buildTransactionsByType(TransactionType.refund),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return FutureBuilder<FinancialSummary>(
      future: _useMockData ? _repository.getMockFinancialSummary() : _repository.getFinancialSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summary = snapshot.data ?? FinancialSummary(
          totalBalance: 0,
          totalPayments: 0,
          totalRefunds: 0,
          pendingTransactions: 0,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    title: "Balance",
                    value: summary.totalBalance,
                    iconData: Icons.account_balance_wallet,
                    color: AppConstants.primaryColor,
                  ),
                  _buildSummaryItem(
                    title: "Payments",
                    value: summary.totalPayments,
                    iconData: Icons.payments,
                    color: Colors.green[700]!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    title: "Refunds",
                    value: summary.totalRefunds,
                    iconData: Icons.undo,
                    color: Colors.orange[700]!,
                  ),
                  _buildSummaryItem(
                    title: "Pending",
                    value: summary.pendingTransactions.toDouble(),
                    iconData: Icons.pending_actions,
                    color: Colors.blue[700]!,
                    isCount: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required double value,
    required IconData iconData,
    required Color color,
    bool isCount = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(iconData, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCount ? value.toInt().toString() : '\$${value.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppConstants.primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: "All"),
          Tab(text: "Payments"),
          Tab(text: "Refunds"),
        ],
      ),
    );
  }

  Widget _buildAllTransactions() {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: _useMockData ? _repository.getMockTransactionsStream() : _repository.getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return _buildEmptyState("No transactions found");
        }

        return _buildTransactionsList(transactions);
      },
    );
  }

  Widget _buildTransactionsByType(TransactionType type) {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: _useMockData ? _repository.getMockTransactionsByType(type) : _repository.getTransactionsByType(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return _buildEmptyState(
            "No ${type == TransactionType.payment ? 'payments' : 'refunds'} found",
          );
        }

        return _buildTransactionsList(transactions);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<FinancialTransaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(FinancialTransaction transaction) {
    final isPayment = transaction.type == TransactionType.payment;
    final isPending = transaction.status == TransactionStatus.pending;
    
    Color statusColor = Colors.grey;
    if (transaction.status == TransactionStatus.completed) {
      statusColor = isPayment ? Colors.green : Colors.orange;
    } else if (transaction.status == TransactionStatus.cancelled) {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPayment ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            isPayment ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPayment ? Colors.green[700] : Colors.orange[700],
          ),
        ),
        title: Text(
          transaction.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(transaction.status),
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${isPayment ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isPayment ? Colors.red[700] : Colors.green[700],
          ),
        ),
        onTap: () {
          _showTransactionDetails(transaction);
        },
      ),
    );
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  void _showTransactionDetails(FinancialTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Transaction ID', '#${transaction.id}'),
              _buildDetailRow('Title', transaction.title),
              _buildDetailRow('Description', transaction.description),
              _buildDetailRow('Amount', '\$${transaction.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(transaction.date)),
              _buildDetailRow('Time', DateFormat('hh:mm a').format(transaction.date)),
              _buildDetailRow('Type', transaction.type == TransactionType.payment ? 'Payment' : 'Refund'),
              _buildDetailRow('Status', _getStatusText(transaction.status)),
              if (transaction.metadata != null && transaction.metadata!.isNotEmpty)
                ...transaction.metadata!.entries.map(
                  (entry) => _buildDetailRow(entry.key, entry.value.toString()),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 