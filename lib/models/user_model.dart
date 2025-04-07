class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String contactNumber;
  final String specialty;
  final String profileImageUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.contactNumber,
    required this.specialty,
    this.profileImageUrl = '',
  });

  // Create a user model from a Firebase document
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      specialty: map['specialty'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
    );
  }

  // Convert user model to a map for storing in Firebase
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'contactNumber': contactNumber,
      'specialty': specialty,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Get full name
  String get fullName => '$firstName $lastName';

  // Create a copy of the user model with updated fields
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? contactNumber,
    String? specialty,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      specialty: specialty ?? this.specialty,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
} 