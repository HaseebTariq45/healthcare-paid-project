import '../models/transaction_model.dart';
import 'dart:async';

/// Mock FinancialRepository class for handling financial data operations without Firebase
class FinancialRepository {
  final String _userId;
  final List<FinancialTransaction> _transactions = [];

  /// Constructor with mock user ID
  FinancialRepository({String? userId}) : _userId = userId ?? 'mock-user-id' {
    // Initialize with mock data
    _initMockTransactions();
  }

  /// Initialize mock transactions
  void _initMockTransactions() {
    _transactions.addAll([
      FinancialTransaction(
        id: '1',
        userId: _userId,
        title: 'Appointment with Dr. Smith',
        description: 'Consultation fee',
        amount: 120.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.payment,
        status: TransactionStatus.completed,
      ),
      FinancialTransaction(
        id: '2',
        userId: _userId,
        title: 'Appointment with Dr. Johnson',
        description: 'Follow-up consultation',
        amount: 80.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.payment,
        status: TransactionStatus.completed,
      ),
      FinancialTransaction(
        id: '3',
        userId: _userId,
        title: 'Lab Test Refund',
        description: 'Refund for canceled blood test',
        amount: 45.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        type: TransactionType.refund,
        status: TransactionStatus.completed,
      ),
      FinancialTransaction(
        id: '4',
        userId: _userId,
        title: 'Upcoming Payment',
        description: 'Scheduled appointment with Dr. Chen',
        amount: 150.00,
        date: DateTime.now().add(const Duration(days: 2)),
        type: TransactionType.payment,
        status: TransactionStatus.pending,
      ),
    ]);
  }

  /// Get the current user ID
  String _getCurrentUserId() {
    return _userId;
  }

  /// Get all transactions for the current user
  Stream<List<FinancialTransaction>> getTransactions({
    TransactionType? type,
    int limit = 50,
    bool descending = true,
  }) {
    try {
      final userId = _getCurrentUserId();
      
      var filteredTransactions = _transactions
          .where((transaction) => transaction.userId == userId)
          .toList();
      
      if (type != null) {
        filteredTransactions = filteredTransactions
            .where((transaction) => transaction.type == type)
            .toList();
      }
      
      filteredTransactions.sort((a, b) => 
          descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
      
      if (filteredTransactions.length > limit) {
        filteredTransactions = filteredTransactions.sublist(0, limit);
      }
      
      return Stream.value(filteredTransactions);
    } catch (e) {
      // Return empty stream in case of error
      return Stream.value([]);
    }
  }

  /// Get financial summary for the current user
  Future<Map<String, num>> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _getCurrentUserId();
      
      var filteredTransactions = _transactions
          .where((transaction) => transaction.userId == userId)
          .toList();
      
      // Apply date range filters if provided
      if (startDate != null) {
        filteredTransactions = filteredTransactions
            .where((transaction) => transaction.date.isAfter(startDate))
            .toList();
      }
      
      if (endDate != null) {
        filteredTransactions = filteredTransactions
            .where((transaction) => transaction.date.isBefore(endDate))
            .toList();
      }
      
      num totalIncome = 0;
      num totalExpense = 0;
      
      for (var transaction in filteredTransactions) {
        if (transaction.type == TransactionType.income || 
            transaction.type == TransactionType.payment) {
          totalIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          totalExpense += transaction.amount;
        } else if (transaction.type == TransactionType.refund) {
          // Refunds are typically a credit (positive) to the user
          totalIncome += transaction.amount;
        }
      }
      
      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      return {
        'income': 0,
        'expense': 0,
        'balance': 0,
      };
    }
  }

  /// Get monthly financial summary for the current year
  Future<List<Map<String, dynamic>>> getMonthlyFinancialSummary({
    int? year,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final currentYear = year ?? DateTime.now().year;
      
      final startDate = DateTime(currentYear, 1, 1);
      final endDate = DateTime(currentYear, 12, 31, 23, 59, 59);
      
      var filteredTransactions = _transactions
          .where((transaction) => transaction.userId == userId)
          .where((transaction) => transaction.date.isAfter(startDate) && 
                                  transaction.date.isBefore(endDate))
          .toList();
      
      // Initialize monthly totals
      List<Map<String, dynamic>> monthlyTotals = List.generate(12, (index) {
        return {
          'month': index + 1,
          'income': 0,
          'expense': 0,
        };
      });
      
      // Aggregate data by month
      for (var transaction in filteredTransactions) {
        final month = transaction.date.month - 1; // 0-indexed
        
        if (transaction.type == TransactionType.income || 
            transaction.type == TransactionType.payment) {
          monthlyTotals[month]['income'] += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          monthlyTotals[month]['expense'] += transaction.amount;
        } else if (transaction.type == TransactionType.refund) {
          monthlyTotals[month]['income'] += transaction.amount;
        }
      }
      
      return monthlyTotals;
    } catch (e) {
      // Return empty data in case of error
      return List.generate(12, (index) {
        return {
          'month': index + 1,
          'income': 0,
          'expense': 0,
        };
      });
    }
  }

  /// Add a new financial transaction
  Future<String?> addTransaction(FinancialTransaction transaction) async {
    try {
      // Generate a random ID
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newTransaction = transaction.copyWith(id: id);
      
      _transactions.add(newTransaction);
      return id;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing financial transaction
  Future<bool> updateTransaction(FinancialTransaction transaction) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      
      if (index == -1) {
        throw Exception('Transaction ID is required for update');
      }
      
      _transactions[index] = transaction;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a financial transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      _transactions.removeWhere((t) => t.id == transactionId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get pending transactions for the current user
  Stream<List<FinancialTransaction>> getPendingTransactions() {
    try {
      final userId = _getCurrentUserId();
      
      final pendingTransactions = _transactions
          .where((transaction) => transaction.userId == userId)
          .where((transaction) => transaction.status == TransactionStatus.pending)
          .toList();
      
      pendingTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      return Stream.value(pendingTransactions);
    } catch (e) {
      return Stream.value([]);
    }
  }
} 