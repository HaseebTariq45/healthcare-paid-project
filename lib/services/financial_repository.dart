import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

/// FinancialRepository class for handling financial data operations with Firestore
class FinancialRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Collection reference to financial transactions
  final CollectionReference _transactionsCollection;

  /// Constructor with dependency injection for easier testing
  FinancialRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _transactionsCollection = (firestore ?? FirebaseFirestore.instance).collection('transactions');

  /// Get the current user ID or throw an error if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  /// Get all transactions for the current user
  /// 
  /// Optionally filter by type and limit the number of results
  Stream<List<FinancialTransaction>> getTransactions({
    TransactionType? type,
    int limit = 50,
    bool descending = true,
  }) {
    try {
      final userId = _getCurrentUserId();
      Query query = _transactionsCollection.where('userId', isEqualTo: userId);
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }
      
      return query
        .orderBy('date', descending: descending)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc))
            .toList();
        });
    } catch (e) {
      // Return empty stream in case of error
      return Stream.value([]);
    }
  }

  /// Get financial summary for the current user
  /// 
  /// Returns total income, expenses, and balance
  Future<Map<String, num>> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _getCurrentUserId();
      
      Query query = _transactionsCollection.where('userId', isEqualTo: userId);
      
      // Add date range filters if provided
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      
      num totalIncome = 0;
      num totalExpense = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] as String;
        final amountValue = data['amountValue'] as int;
        
        if (type == TransactionType.income.value || type == TransactionType.payment.value) {
          totalIncome += amountValue;
        } else if (type == TransactionType.expense.value) {
          totalExpense += amountValue;
        } else if (type == TransactionType.refund.value) {
          // Refunds are typically a credit (positive) to the user
          totalIncome += amountValue;
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
  /// 
  /// Returns monthly totals for income and expenses
  Future<List<Map<String, dynamic>>> getMonthlyFinancialSummary({
    int? year,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final currentYear = year ?? DateTime.now().year;
      
      final startDate = DateTime(currentYear, 1, 1);
      final endDate = DateTime(currentYear, 12, 31, 23, 59, 59);
      
      final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
      
      // Initialize monthly totals
      List<Map<String, dynamic>> monthlyTotals = List.generate(12, (index) {
        return {
          'month': index + 1,
          'income': 0,
          'expense': 0,
        };
      });
      
      // Aggregate data by month
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final month = date.month - 1; // 0-indexed
        final type = data['type'] as String;
        final amountValue = data['amountValue'] as int;
        
        if (type == TransactionType.income.value || type == TransactionType.payment.value) {
          monthlyTotals[month]['income'] += amountValue;
        } else if (type == TransactionType.expense.value) {
          monthlyTotals[month]['expense'] += amountValue;
        } else if (type == TransactionType.refund.value) {
          monthlyTotals[month]['income'] += amountValue;
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
      final docRef = await _transactionsCollection.add(transaction.toFirestore());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing financial transaction
  Future<bool> updateTransaction(FinancialTransaction transaction) async {
    try {
      if (transaction.id == null) {
        throw Exception('Transaction ID is required for update');
      }
      
      await _transactionsCollection.doc(transaction.id).update(transaction.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a financial transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _transactionsCollection.doc(transactionId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get pending transactions for the current user
  Stream<List<FinancialTransaction>> getPendingTransactions() {
    try {
      final userId = _getCurrentUserId();
      
      return _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TransactionStatus.pending.value)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc))
            .toList();
        });
    } catch (e) {
      return Stream.value([]);
    }
  }
} 