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
    // Handle various date formats
    DateTime parseDate(dynamic dateData, dynamic timeData) {
      DateTime dateTime;
      
      // First parse the date part
      if (dateData is Timestamp) {
        dateTime = dateData.toDate();
      } else if (dateData is String) {
        try {
          dateTime = DateTime.parse(dateData);
        } catch (e) {
          // Try to handle formatted date strings
          try {
            // Handle formats like "dd/MM/yyyy"
            if (dateData.contains('/')) {
              final parts = dateData.split('/');
              if (parts.length == 3) {
                dateTime = DateTime(
                  int.parse(parts[2]),  // year
                  int.parse(parts[1]),  // month
                  int.parse(parts[0]),  // day
                );
              } else {
                throw Exception('Invalid date format');
              }
            } else if (dateData.contains('-')) {
              // Handle ISO format
              dateTime = DateTime.parse(dateData);
            } else {
              // Handle text dates like "15 Oct 2023"
              final months = {
                'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
                'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
              };
              
              final parts = dateData.split(' ');
              if (parts.length == 3) {
                final day = int.parse(parts[0]);
                final month = months[parts[1].toLowerCase().substring(0, 3)] ?? 1;
                final year = int.parse(parts[2]);
                
                dateTime = DateTime(year, month, day);
              } else {
                throw Exception('Invalid date format');
              }
            }
          } catch (e) {
            print('Error parsing formatted date: $e');
            dateTime = DateTime.now();
          }
        }
      } else {
        // Default to current date if no valid format
        dateTime = DateTime.now();
      }
      
      // Now incorporate the time data if available
      if (timeData is String && timeData.isNotEmpty) {
        try {
          // Parse formats like "08:00 PM"
          String timeStr = timeData.trim();
          bool isPM = timeStr.toLowerCase().contains('pm');
          
          // Remove AM/PM
          timeStr = timeStr.toLowerCase()
                    .replaceAll('am', '')
                    .replaceAll('pm', '')
                    .trim();
          
          // Split hours and minutes
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);
            
            // Convert to 24-hour format if needed
            if (isPM && hour < 12) {
              hour += 12;
            } else if (!isPM && hour == 12) {
              hour = 0;
            }
            
            // Create new DateTime with both date and time components
            dateTime = DateTime(
              dateTime.year,
              dateTime.month,
              dateTime.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          print('Error parsing time data: $e');
          // Keep the date part unchanged if time parsing fails
        }
      }
      
      return dateTime;
    }
    
    return AppointmentModel(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      specialty: json['specialty'] as String,
      hospital: json['hospital'] as String,
      date: parseDate(json['date'], json['time']),
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