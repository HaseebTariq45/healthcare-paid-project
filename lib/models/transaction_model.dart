import 'package:cloud_firestore/cloud_firestore.dart';

/// TransactionType enum representing the type of financial transaction
enum TransactionType {
  income,
  expense,
  refund,
  payment,
}

/// Extension to convert TransactionType to string for Firestore storage
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.payment:
        return 'payment';
      default:
        return 'unknown';
    }
  }
  
  static TransactionType fromString(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'refund':
        return TransactionType.refund;
      case 'payment':
        return TransactionType.payment;
      default:
        return TransactionType.payment;
    }
  }
}

/// Status of the transaction
enum TransactionStatus {
  completed,
  pending,
  failed,
  processing,
  cancelled,
}

/// Extension to convert TransactionStatus to string for Firestore storage
extension TransactionStatusExtension on TransactionStatus {
  String get value {
    switch (this) {
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.processing:
        return 'processing';
      case TransactionStatus.cancelled:
        return 'cancelled';
      default:
        return 'unknown';
    }
  }
  
  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return TransactionStatus.completed;
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
        return TransactionStatus.failed;
      case 'processing':
        return TransactionStatus.processing;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }
}

/// FinancialTransaction model for representing financial transactions
class FinancialTransaction {
  /// Unique ID of the transaction (document ID in Firestore)
  final String id;
  
  /// User ID of the transaction owner
  final String userId;
  
  /// Title or description of the transaction
  final String title;
  
  /// Description of the transaction
  final String description;
  
  /// Amount of the transaction (in string format for display with currency symbol)
  final double amount;
  
  /// Date of the transaction
  final DateTime date;
  
  /// Type of transaction (income, expense, payment, refund)
  final TransactionType type;
  
  /// Status of the transaction (completed, pending, failed, processing)
  final TransactionStatus status;
  
  /// Additional metadata about the transaction
  final Map<String, dynamic>? metadata;
  
  /// Timestamp when the transaction was created
  final DateTime createdAt;
  
  /// Timestamp when the transaction was last updated
  final DateTime updatedAt;

  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Create a FinancialTransaction from a Map (can be used with Firestore or local data)
  factory FinancialTransaction.fromMap(String id, Map<String, dynamic> data) {
    // Handle date field - could be DateTime, Timestamp, or String
    DateTime parseDate(dynamic dateField) {
      if (dateField is DateTime) {
        return dateField;
      } else if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is String) {
        return DateTime.tryParse(dateField) ?? DateTime.now();
      }
      return DateTime.now();
    }
    
    return FinancialTransaction(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: parseDate(data['date']),
      type: _typeFromString(data['type'] ?? 'payment'),
      status: _statusFromString(data['status'] ?? 'pending'),
      metadata: data['metadata'],
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
  
  /// For backward compatibility with Firebase code
  factory FinancialTransaction.fromFirestore(dynamic snapshot, [dynamic options]) {
    if (snapshot is Map<String, dynamic>) {
      return FinancialTransaction.fromMap('mock-id', snapshot);
    }
    
    // Default mock implementation
    final String id = snapshot?.id ?? 'mock-id';
    final Map<String, dynamic> data = snapshot?.data?.call() ?? {};
    return FinancialTransaction.fromMap(id, data);
  }
  
  /// Convert to a map for storage
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.value,
      'status': status.value,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// Create a copy of this transaction with updated fields
  FinancialTransaction copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
    TransactionType? type,
    TransactionStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Transaction(id: $id, title: $title, amount: $amount)';

  // Helper methods for enum conversion
  static TransactionType _typeFromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.payment,
    );
  }

  static TransactionStatus _statusFromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }
} 