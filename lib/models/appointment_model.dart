import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime date;
  final String status;
  final String? diagnosis;
  final String? prescription;
  final String? notes;
  final double? fee;

  AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.status,
    this.diagnosis,
    this.prescription,
    this.notes,
    this.fee,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      specialty: json['specialty'] as String,
      hospital: json['hospital'] as String,
      date: json['date'] is Timestamp 
          ? (json['date'] as Timestamp).toDate()
          : DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      diagnosis: json['diagnosis'] as String?,
      prescription: json['prescription'] as String?,
      notes: json['notes'] as String?,
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'hospital': hospital,
      'date': date.toIso8601String(),
      'status': status,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'fee': fee,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          doctorName == other.doctorName &&
          specialty == other.specialty &&
          hospital == other.hospital &&
          date == other.date &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      doctorName.hashCode ^
      specialty.hashCode ^
      hospital.hashCode ^
      date.hashCode ^
      status.hashCode;
} 