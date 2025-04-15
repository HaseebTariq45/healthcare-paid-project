import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

/// FinancialRepository class for handling financial data operations with Firestore
class FinancialRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final bool _doctorMode; // Flag to indicate if we're in doctor mode
  final String? _currentUserId; // Optional override for user ID

  /// Collection reference to financial transactions
  final CollectionReference _transactionsCollection;

  /// Constructor with dependency injection for easier testing
  FinancialRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    bool doctorMode = false, // Default to false for backward compatibility
    String? currentUserId,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _doctorMode = doctorMode,
    _currentUserId = currentUserId,
    _transactionsCollection = (firestore ?? FirebaseFirestore.instance).collection('transactions');

  /// Get the current user ID or throw an error if not authenticated
  String _getCurrentUserId() {
    // Use provided ID if available
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return _currentUserId!;
    }
    
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
      
      // Use doctorId or userId based on mode
      String fieldName = _doctorMode ? 'doctorId' : 'userId';
      Query query = _transactionsCollection.where(fieldName, isEqualTo: userId);
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }
      
      // Add logic to deduplicate transactions based on appointmentId
      return query
        .orderBy('date', descending: descending)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          // Use a map to deduplicate by appointmentId
          final Map<String, FinancialTransaction> uniqueTransactions = {};
          
          for (var doc in snapshot.docs) {
            final transaction = FinancialTransaction.fromFirestore(doc);
            final data = doc.data() as Map<String, dynamic>;
            
            // If this is a payment transaction with an appointmentId
            if (data.containsKey('appointmentId') && data['appointmentId'] != null) {
              final appointmentId = data['appointmentId'].toString();
              
              // Only add if we haven't seen this appointmentId before
              if (!uniqueTransactions.containsKey('appointment_$appointmentId')) {
                uniqueTransactions['appointment_$appointmentId'] = transaction;
              }
            } else {
              // For transactions without appointmentId, use their own ID as key
              uniqueTransactions[transaction.id] = transaction;
            }
          }
          
          // Return the deduplicated list
          return uniqueTransactions.values.toList();
        });
    } catch (e) {
      print('Error getting transactions: $e');
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
      
      // Use doctorId or userId based on mode
      String fieldName = _doctorMode ? 'doctorId' : 'userId';
      Query query = _transactionsCollection.where(fieldName, isEqualTo: userId);
      
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
        
        // Get the amount - check both amountValue and amount fields
        num amount = 0;
        if (data.containsKey('amountValue')) {
          amount = data['amountValue'] as num;
        } else if (data.containsKey('amount')) {
          amount = data['amount'] as num;
        }
        
        if (type == TransactionType.income.value || type == TransactionType.payment.value) {
          totalIncome += amount;
        } else if (type == TransactionType.expense.value) {
          totalExpense += amount;
        } else if (type == TransactionType.refund.value) {
          // Refunds are typically a credit (positive) to the user
          totalIncome += amount;
        }
      }
      
      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      print('Error getting financial summary: $e');
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
      
      // Use doctorId or userId based on mode
      String fieldName = _doctorMode ? 'doctorId' : 'userId';
      
      final snapshot = await _transactionsCollection
        .where(fieldName, isEqualTo: userId)
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
        
        // Get the amount - check both amountValue and amount fields
        num amount = 0;
        if (data.containsKey('amountValue')) {
          amount = data['amountValue'] as num;
        } else if (data.containsKey('amount')) {
          amount = data['amount'] as num;
        }
        
        if (type == TransactionType.income.value || type == TransactionType.payment.value) {
          monthlyTotals[month]['income'] += amount;
        } else if (type == TransactionType.expense.value) {
          monthlyTotals[month]['expense'] += amount;
        } else if (type == TransactionType.refund.value) {
          monthlyTotals[month]['income'] += amount;
        }
      }
      
      return monthlyTotals;
    } catch (e) {
      print('Error getting monthly data: $e');
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
      
      // Use doctorId or userId based on mode
      String fieldName = _doctorMode ? 'doctorId' : 'userId';
      
      return _transactionsCollection
        .where(fieldName, isEqualTo: userId)
        .where('status', isEqualTo: TransactionStatus.pending.value)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc))
            .toList();
        });
    } catch (e) {
      print('Error getting pending transactions: $e');
      return Stream.value([]);
    }
  }

  /// Get transactions of a specific type for the current user
  Stream<List<FinancialTransaction>> getTransactionsByType(TransactionType type, {int limit = 50}) {
    return getTransactions(type: type, limit: limit);
  }

  /// Check if an appointment has already been processed for financial transactions
  Future<bool> hasExistingTransactionForAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) return false;
    
    try {
      final userId = _getCurrentUserId();
      
      final querySnapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();
          
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for existing transaction: $e');
      return false;
    }
  }
} 