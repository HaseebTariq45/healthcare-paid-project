import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class FinancialSummary {
  final double totalBalance;
  final double totalPayments;
  final double totalRefunds;
  final int pendingTransactions;

  FinancialSummary({
    required this.totalBalance,
    required this.totalPayments,
    required this.totalRefunds,
    required this.pendingTransactions,
  });
}

class FinancialRepository {
  final FirebaseFirestore _firestore;
  final String _userId;
  
  // Constructor with optional Firestore instance for testing
  FinancialRepository({
    FirebaseFirestore? firestore,
    required String userId,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _userId = userId;
  
  // Collection references
  CollectionReference<Map<String, dynamic>> get _transactionsCollection => 
    _firestore.collection('transactions');
  
  // Get a stream of all transactions for the current user
  Stream<List<FinancialTransaction>> getTransactions() {
    return _transactionsCollection
      .where('userId', isEqualTo: _userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return FinancialTransaction.fromFirestore(doc, null);
        }).toList();
      });
  }
  
  // Get a stream of transactions filtered by type
  Stream<List<FinancialTransaction>> getTransactionsByType(TransactionType type) {
    return _transactionsCollection
      .where('userId', isEqualTo: _userId)
      .where('type', isEqualTo: type.toString().split('.').last)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return FinancialTransaction.fromFirestore(doc, null);
        }).toList();
      });
  }
  
  // Get a financial summary for the user
  Future<FinancialSummary> getFinancialSummary() async {
    // In a real implementation, this might be a separate document or a server-side function
    // For now, we'll calculate it from the transactions
    final transactions = await _transactionsCollection
      .where('userId', isEqualTo: _userId)
      .get();
    
    double totalPayments = 0;
    double totalRefunds = 0;
    int pendingCount = 0;
    
    for (var doc in transactions.docs) {
      final transaction = FinancialTransaction.fromFirestore(doc, null);
      
      if (transaction.type == TransactionType.payment) {
        totalPayments += transaction.amount;
      } else if (transaction.type == TransactionType.refund) {
        totalRefunds += transaction.amount;
      }
      
      if (transaction.status == TransactionStatus.pending) {
        pendingCount++;
      }
    }
    
    return FinancialSummary(
      totalBalance: totalPayments - totalRefunds,
      totalPayments: totalPayments,
      totalRefunds: totalRefunds,
      pendingTransactions: pendingCount,
    );
  }
  
  // Mock implementation for testing without Firebase
  static FinancialRepository getMockRepository() {
    return FinancialRepository(userId: 'mock-user-id');
  }
  
  // Mock data for local development and testing
  List<FinancialTransaction> getMockTransactions() {
    return [
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
    ];
  }
  
  // Get mock stream for local development
  Stream<List<FinancialTransaction>> getMockTransactionsStream() {
    return Stream.value(getMockTransactions());
  }
  
  Stream<List<FinancialTransaction>> getMockTransactionsByType(TransactionType type) {
    return Stream.value(getMockTransactions()
      .where((transaction) => transaction.type == type)
      .toList());
  }
  
  Future<FinancialSummary> getMockFinancialSummary() async {
    final transactions = getMockTransactions();
    
    double totalPayments = 0;
    double totalRefunds = 0;
    int pendingCount = 0;
    
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.payment) {
        totalPayments += transaction.amount;
      } else if (transaction.type == TransactionType.refund) {
        totalRefunds += transaction.amount;
      }
      
      if (transaction.status == TransactionStatus.pending) {
        pendingCount++;
      }
    }
    
    return FinancialSummary(
      totalBalance: totalPayments - totalRefunds,
      totalPayments: totalPayments,
      totalRefunds: totalRefunds,
      pendingTransactions: pendingCount,
    );
  }
} 