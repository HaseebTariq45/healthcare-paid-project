import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Enum representing medical specialties
enum Specialty {
  generalPhysician,
  cardiologist,
  dermatologist,
  neurologist,
  pediatrician,
  psychiatrist,
  orthopedist,
  gynecologist,
  ophthalmologist,
  dentist,
  other,
}

/// Extension for Specialty enum to convert to and from string
extension SpecialtyExtension on Specialty {
  String get value {
    switch (this) {
      case Specialty.generalPhysician:
        return 'General Physician';
      case Specialty.cardiologist:
        return 'Cardiologist';
      case Specialty.dermatologist:
        return 'Dermatologist';
      case Specialty.neurologist:
        return 'Neurologist';
      case Specialty.pediatrician:
        return 'Pediatrician';
      case Specialty.psychiatrist:
        return 'Psychiatrist';
      case Specialty.orthopedist:
        return 'Orthopedist';
      case Specialty.gynecologist:
        return 'Gynecologist';
      case Specialty.ophthalmologist:
        return 'Ophthalmologist';
      case Specialty.dentist:
        return 'Dentist';
      case Specialty.other:
        return 'Other';
      default:
        return 'Unknown';
    }
  }
  
  static Specialty fromString(String value) {
    switch (value) {
      case 'General Physician':
        return Specialty.generalPhysician;
      case 'Cardiologist':
        return Specialty.cardiologist;
      case 'Dermatologist':
        return Specialty.dermatologist;
      case 'Neurologist':
        return Specialty.neurologist;
      case 'Pediatrician':
        return Specialty.pediatrician;
      case 'Psychiatrist':
        return Specialty.psychiatrist;
      case 'Orthopedist':
        return Specialty.orthopedist;
      case 'Gynecologist':
        return Specialty.gynecologist;
      case 'Ophthalmologist':
        return Specialty.ophthalmologist;
      case 'Dentist':
        return Specialty.dentist;
      case 'Other':
        return Specialty.other;
      default:
        return Specialty.other;
    }
  }
}

/// Time slot class for doctor availability
class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;
  final String? patientId;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.patientId,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      isBooked: map['isBooked'] ?? false,
      patientId: map['patientId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isBooked': isBooked,
      if (patientId != null) 'patientId': patientId,
    };
  }

  TimeSlot copyWith({
    DateTime? startTime,
    DateTime? endTime,
    bool? isBooked,
    String? patientId,
  }) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBooked: isBooked ?? this.isBooked,
      patientId: patientId ?? this.patientId,
    );
  }
}

/// Doctor model class representing a doctor's complete profile
class Doctor {
  /// Unique identifier for the doctor
  final String id;
  
  /// Doctor's full name
  final String name;
  
  /// Doctor's specialty
  final Specialty specialty;
  
  /// Doctor's phone number
  final String phoneNumber;
  
  /// Doctor's email
  final String? email;
  
  /// Doctor's years of experience
  final int experience;
  
  /// Doctor's qualifications and degrees
  final List<String> qualifications;
  
  /// Doctor's average rating
  final double rating;
  
  /// Number of patients who rated the doctor
  final int ratingCount;
  
  /// Doctor's consultation fee
  final double fee;
  
  /// Doctor's profile image
  final String? profileImageUrl;
  
  /// Doctor's license/certification image
  final String? licenseUrl;
  
  /// Doctor's CNIC front image
  final String? cnicFrontUrl;
  
  /// Doctor's CNIC back image
  final String? cnicBackUrl;
  
  /// Doctor's clinic/hospital address information
  final String? clinicName;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  
  /// Doctor's availability slots
  final List<TimeSlot> availabilitySlots;
  
  /// List of services offered by the doctor
  final List<String> services;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;
  
  /// Profile completion status
  final bool isProfileComplete;
  
  /// Doctor's verification status
  final bool isVerified;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;
  
  /// Default constructor
  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phoneNumber,
    this.email,
    required this.experience,
    required this.qualifications,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.fee,
    this.profileImageUrl,
    this.licenseUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.clinicName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.availabilitySlots = const [],
    this.services = const [],
    this.metadata,
    this.isProfileComplete = false,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
    
  /// Factory to create Doctor from Firestore data
  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<TimeSlot> slots = [];
    if (data['availabilitySlots'] != null) {
      slots = List<Map<String, dynamic>>.from(data['availabilitySlots'])
          .map((map) => TimeSlot.fromMap(map))
          .toList();
    }
    
    return Doctor(
      id: doc.id,
      name: data['name'] ?? '',
      specialty: data['specialty'] is String 
          ? SpecialtyExtension.fromString(data['specialty']) 
          : Specialty.other,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      experience: (data['experience'] is String) 
          ? int.tryParse(data['experience'] ?? '0') ?? 0 
          : data['experience'] ?? 0,
      qualifications: List<String>.from(data['qualifications'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      fee: (data['fee'] ?? 0.0).toDouble(),
      profileImageUrl: data['profileImageUrl'],
      licenseUrl: data['licenseUrl'],
      cnicFrontUrl: data['cnicFrontUrl'],
      cnicBackUrl: data['cnicBackUrl'],
      clinicName: data['clinicName'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      country: data['country'],
      zipCode: data['zipCode'],
      availabilitySlots: slots,
      services: List<String>.from(data['services'] ?? []),
      metadata: data['metadata'],
      isProfileComplete: data['isProfileComplete'] ?? false,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'specialty': specialty.value,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      'experience': experience,
      'qualifications': qualifications,
      'rating': rating,
      'ratingCount': ratingCount,
      'fee': fee,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (licenseUrl != null) 'licenseUrl': licenseUrl,
      if (cnicFrontUrl != null) 'cnicFrontUrl': cnicFrontUrl,
      if (cnicBackUrl != null) 'cnicBackUrl': cnicBackUrl,
      if (clinicName != null) 'clinicName': clinicName,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (zipCode != null) 'zipCode': zipCode,
      'availabilitySlots': availabilitySlots.map((slot) => slot.toMap()).toList(),
      'services': services,
      if (metadata != null) 'metadata': metadata,
      'isProfileComplete': isProfileComplete,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
  
  /// Create a copy with updated fields
  Doctor copyWith({
    String? id,
    String? name,
    Specialty? specialty,
    String? phoneNumber,
    String? email,
    int? experience,
    List<String>? qualifications,
    double? rating,
    int? ratingCount,
    double? fee,
    String? profileImageUrl,
    String? licenseUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? clinicName,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    List<TimeSlot>? availabilitySlots,
    List<String>? services,
    Map<String, dynamic>? metadata,
    bool? isProfileComplete,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      fee: fee ?? this.fee,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      availabilitySlots: availabilitySlots ?? this.availabilitySlots,
      services: services ?? this.services,
      metadata: metadata ?? this.metadata,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 