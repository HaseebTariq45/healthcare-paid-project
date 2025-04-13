import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final String? paymentMethod;

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
    this.paymentMethod,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
      ),
      appointmentId: json['appointmentId'] as String?,
      doctorName: json['doctorName'] as String?,
      hospitalName: json['hospitalName'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'appointmentId': appointmentId,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'paymentMethod': paymentMethod,
    };
  }

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
      paymentMethod: data['paymentMethod'],
    );
  }

  static TransactionStatus _getStatusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return TransactionStatus.failed;
      case 'completed':
      case 'success':
      case 'confirmed':
      case 'paid':
      default:
        return TransactionStatus.completed;
    }
  }
}

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

class FinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all financial transactions for the current user
  Future<List<FinancialTransaction>> getUserTransactions() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      // Use a map with appointmentId as key to prevent duplicates
      Map<String, FinancialTransaction> uniqueTransactions = {};
      
      // First, collect transactions from the transactions collection
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .get();
      
      // Add transactions from transactions collection first
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final transaction = FinancialTransaction.fromFirestore(doc);
        
        // If transaction has an appointmentId, use it as key
        if (data['appointmentId'] != null) {
          String key = 'appointment_${data['appointmentId']}';
          uniqueTransactions[key] = transaction;
        } else {
          // Otherwise use the transaction ID as key
          uniqueTransactions[doc.id] = transaction;
        }
      }
      
      // Now get transactions from appointments collection to fill in any gaps
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: currentUserId)
          .get();

      for (var doc in appointmentsSnapshot.docs) {
        // Skip if this appointment already has a transaction
        String appointmentKey = 'appointment_${doc.id}';
        if (uniqueTransactions.containsKey(appointmentKey)) {
          continue;
        }
        
        final appointmentData = doc.data();
        
        // Check if appointment has hasFinancialTransaction flag to avoid duplicates
        if (appointmentData['hasFinancialTransaction'] == true) {
          continue;
        }
        
        // Include appointments with any payment information
        if (appointmentData['paymentStatus'] != null || 
            appointmentData['paymentMethod'] != null ||
            appointmentData['fee'] != null) {
          
          // Get doctor information if available
          String? doctorName = appointmentData['doctorName'];
          if (appointmentData['doctorId'] != null && doctorName == null) {
            final doctorDoc = await _firestore
                .collection('doctors')
                .doc(appointmentData['doctorId'])
                .get();
                
            if (doctorDoc.exists) {
              final doctorData = doctorDoc.data() as Map<String, dynamic>;
              doctorName = doctorData['fullName'] ?? doctorData['name'];
            }
          }
          
          // Get the fee amount
          double amount = 0.0;
          if (appointmentData['fee'] != null && appointmentData['fee'] is num) {
            amount = appointmentData['fee'].toDouble();
          }
          
          // Determine transaction status
          TransactionStatus status;
          final paymentStatus = appointmentData['paymentStatus']?.toString().toLowerCase() ?? 'pending';
          
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
            doctorName: doctorName,
            hospitalName: appointmentData['hospitalName'] ?? appointmentData['location'],
            paymentMethod: appointmentData['paymentMethod'],
          );
          
          uniqueTransactions[appointmentKey] = transaction;
        }
      }
      
      // Convert map values to list
      List<FinancialTransaction> transactions = uniqueTransactions.values.toList();
      
      // Sort transactions by date (most recent first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // Get financial summary
  Future<Map<String, num>> getFinancialSummary() async {
    try {
      final transactions = await getUserTransactions();
      
      double totalPaid = 0;
      double pendingPayments = 0;
      double refunds = 0;
      
      for (var tx in transactions) {
        if (tx.type == TransactionType.payment && tx.status == TransactionStatus.completed) {
          totalPaid += tx.amount;
        } else if (tx.type == TransactionType.payment && tx.status == TransactionStatus.pending) {
          pendingPayments += tx.amount;
        } else if (tx.type == TransactionType.refund) {
          refunds += tx.amount;
        }
      }
      
      return {
        'totalPaid': totalPaid,
        'pendingPayments': pendingPayments,
        'refunds': refunds,
      };
    } catch (e) {
      print('Error calculating financial summary: $e');
      return {
        'totalPaid': 0,
        'pendingPayments': 0,
        'refunds': 0,
      };
    }
  }
  
  // Get a stream of all transactions for the current user
  Stream<List<FinancialTransaction>> getTransactions() {
    return _firestore.collection('transactions')
      .where('userId', isEqualTo: currentUserId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return FinancialTransaction.fromFirestore(doc);
        }).toList();
      });
  }
  
  // Get a stream of transactions filtered by type
  Stream<List<FinancialTransaction>> getTransactionsByType(TransactionType type) {
    return _firestore.collection('transactions')
      .where('userId', isEqualTo: currentUserId)
      .where('type', isEqualTo: type.toString().split('.').last)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return FinancialTransaction.fromFirestore(doc);
        }).toList();
      });
  }
  
  // Mock implementation for testing without Firebase
  static FinanceRepository getMockRepository() {
    return FinanceRepository();
  }
  
  // Mock data for local development and testing
  List<FinancialTransaction> getMockTransactions() {
    return [
      FinancialTransaction(
        id: '1',
        title: 'Appointment with Dr. Smith',
        description: 'Consultation fee',
        amount: 120.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.payment,
        status: TransactionStatus.completed,
      ),
      FinancialTransaction(
        id: '2',
        title: 'Appointment with Dr. Johnson',
        description: 'Follow-up consultation',
        amount: 80.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.payment,
        status: TransactionStatus.completed,
      ),
      FinancialTransaction(
        id: '3',
        title: 'Lab Test Refund',
        description: 'Refund for canceled blood test',
        amount: 45.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        type: TransactionType.refund,
        status: TransactionStatus.completed,
      ),
      FinancialTransaction(
        id: '4',
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