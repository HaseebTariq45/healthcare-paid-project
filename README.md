# Healthcare App

A Flutter-based Healthcare Platform for Patients, Doctors, and Lady Health Workers.

## Features

### Authentication
- **Phone Number Authentication**: Secure login using Firebase phone authentication
- **OTP Verification**: Two-factor authentication using SMS codes
- **User Role Management**: Support for different user types (Patient, Doctor, Lady Health Worker)
- **Profile Completion Flow**: Guided profile setup for first-time users

### Patient Features
- **Appointment Booking**: Book appointments with available doctors
- **Doctor Search**: Find doctors by specialty or name
- **Medical Records**: Store and access health records
- **Prescription Management**: View and track prescriptions
- **Telemedicine**: Video consultations with healthcare providers

### Doctor Features
- **Appointment Management**: View and manage patient appointments
- **Patient History**: Access patient medical records
- **Prescription Writing**: Create and send digital prescriptions
- **Time Slot Management**: Set availability for consultations
- **Dashboard**: Monitor patient statistics and appointment history

### Lady Health Worker Features
- **Community Care**: Track community health initiatives
- **Patient Referrals**: Refer patients to doctors
- **Health Education**: Access resources for patient education
- **Field Reporting**: Document community health status

## Technical Implementation

### Authentication Flow
1. **Sign Up**:
   - User enters phone number and basic information
   - OTP is sent via Firebase Authentication
   - User verifies OTP
   - New user account is created in Firestore

2. **Sign In**:
   - User enters phone number
   - OTP is sent via Firebase Authentication
   - User verifies OTP
   - User role is retrieved from Firestore
   - Navigation is based on role and profile completion status

3. **User Data Storage**:
   - User information is stored in Firestore's 'users' collection
   - User role and profile completion status are cached in SharedPreferences
   - Profile data includes role-specific fields for each user type

### Database Structure
- **Authentication**: Firebase Authentication
- **Data Storage**: Cloud Firestore
- **Storage**: Firebase Storage for media files
- **Collections**:
  - `users`: Core user information and role
  - `appointments`: Appointment details
  - `prescriptions`: Prescription records
  - `transactions`: Financial records
  - `medical_records`: Patient health information

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase project
- Android Studio / VS Code

### Setup
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Set up Firebase in your project:
   - Create a Firebase project
   - Add your Android/iOS app to the project
   - Download and add the google-services.json/GoogleService-Info.plist
4. Run the app with `flutter run`

## Tech Stack
- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **State Management**: Provider
- **UI Components**: Custom widgets, Material Design

## Future Enhancements
- Payment integration
- Push notifications
- Multi-language support
- Offline functionality
- Analytics for healthcare trends
