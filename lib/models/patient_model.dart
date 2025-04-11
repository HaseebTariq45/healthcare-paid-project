import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Enum representing the blood group types
enum BloodGroup {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

/// Extension for BloodGroup enum to convert to and from string
extension BloodGroupExtension on BloodGroup {
  String get value {
    switch (this) {
      case BloodGroup.aPositive:
        return 'A+';
      case BloodGroup.aNegative:
        return 'A-';
      case BloodGroup.bPositive:
        return 'B+';
      case BloodGroup.bNegative:
        return 'B-';
      case BloodGroup.abPositive:
        return 'AB+';
      case BloodGroup.abNegative:
        return 'AB-';
      case BloodGroup.oPositive:
        return 'O+';
      case BloodGroup.oNegative:
        return 'O-';
      default:
        return 'Unknown';
    }
  }
  
  static BloodGroup fromString(String value) {
    switch (value) {
      case 'A+':
        return BloodGroup.aPositive;
      case 'A-':
        return BloodGroup.aNegative;
      case 'B+':
        return BloodGroup.bPositive;
      case 'B-':
        return BloodGroup.bNegative;
      case 'AB+':
        return BloodGroup.abPositive;
      case 'AB-':
        return BloodGroup.abNegative;
      case 'O+':
        return BloodGroup.oPositive;
      case 'O-':
        return BloodGroup.oNegative;
      default:
        return BloodGroup.aPositive;
    }
  }
}

/// Patient model class representing a patient's complete profile
class Patient {
  /// Unique identifier for the patient
  final String id;
  
  /// Patient's full name
  final String name;
  
  /// Patient's age
  final int age;
  
  /// Patient's blood group
  final BloodGroup bloodGroup;
  
  /// Patient's phone number
  final String phoneNumber;
  
  /// Patient's email
  final String? email;
  
  /// Patient's list of allergies
  final List<String> allergies;
  
  /// Patient's list of diseases/conditions
  final List<String> diseases;
  
  /// Patient's disability if any
  final String? disability;
  
  /// Patient's height in centimeters
  final double? height;
  
  /// Patient's weight in kilograms
  final double? weight;
  
  /// Patient's profile image
  final String? profileImageUrl;
  
  /// Patient's front side of identification document
  final String? cnicFrontUrl;
  
  /// Patient's back side of identification document
  final String? cnicBackUrl;
  
  /// Patient's medical reports
  final List<String>? medicalReportUrls;
  
  /// Patient's address information
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;
  
  /// Profile completion status
  final bool isProfileComplete;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;
  
  /// Default constructor
  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodGroup,
    required this.phoneNumber,
    this.email,
    required this.allergies,
    required this.diseases,
    this.disability,
    this.height,
    this.weight,
    this.profileImageUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.medicalReportUrls,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.metadata,
    this.isProfileComplete = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
    
  /// Factory to create Patient from Firestore data
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Patient(
      id: doc.id,
      name: data['name'] ?? '',
      age: (data['age'] is String) ? int.tryParse(data['age'] ?? '0') ?? 0 : data['age'] ?? 0,
      bloodGroup: data['bloodGroup'] is String 
          ? BloodGroupExtension.fromString(data['bloodGroup']) 
          : BloodGroup.aPositive,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      allergies: List<String>.from(data['allergies'] ?? []),
      diseases: List<String>.from(data['diseases'] ?? []),
      disability: data['disability'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      profileImageUrl: data['profileImageUrl'],
      cnicFrontUrl: data['cnicFrontUrl'],
      cnicBackUrl: data['cnicBackUrl'],
      medicalReportUrls: data['medicalReportUrls'] != null 
          ? List<String>.from(data['medicalReportUrls']) 
          : null,
      address: data['address'],
      city: data['city'],
      state: data['state'],
      country: data['country'],
      zipCode: data['zipCode'],
      metadata: data['metadata'],
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  /// Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup.value,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      'allergies': allergies,
      'diseases': diseases,
      if (disability != null) 'disability': disability,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (cnicFrontUrl != null) 'cnicFrontUrl': cnicFrontUrl,
      if (cnicBackUrl != null) 'cnicBackUrl': cnicBackUrl,
      if (medicalReportUrls != null) 'medicalReportUrls': medicalReportUrls,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (zipCode != null) 'zipCode': zipCode,
      if (metadata != null) 'metadata': metadata,
      'isProfileComplete': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
  
  /// Create a copy with updated fields
  Patient copyWith({
    String? id,
    String? name,
    int? age,
    BloodGroup? bloodGroup,
    String? phoneNumber,
    String? email,
    List<String>? allergies,
    List<String>? diseases,
    String? disability,
    double? height,
    double? weight,
    String? profileImageUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    List<String>? medicalReportUrls,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    Map<String, dynamic>? metadata,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      allergies: allergies ?? this.allergies,
      diseases: diseases ?? this.diseases,
      disability: disability ?? this.disability,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      medicalReportUrls: medicalReportUrls ?? this.medicalReportUrls,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      metadata: metadata ?? this.metadata,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 