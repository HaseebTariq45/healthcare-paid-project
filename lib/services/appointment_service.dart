import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppointmentModel>> getAppointmentHistory(String userId) async {
    try {
      print("Fetching appointment history for user: $userId");
      final QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      print("Found ${appointmentsSnapshot.docs.length} appointments");
      
      // Log the structure of the first appointment to help debugging
      if (appointmentsSnapshot.docs.isNotEmpty) {
        final sampleData = appointmentsSnapshot.docs.first.data() as Map<String, dynamic>;
        print("Sample appointment data structure:");
        sampleData.forEach((key, value) {
          print("  $key: $value (${value?.runtimeType})");
        });
      }

      return Future.wait(appointmentsSnapshot.docs.map((doc) async {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print("Processing appointment ${doc.id}");
          
          // Fetch patient details to get the name
          final patientDoc = await _firestore
              .collection('patients')
              .doc(data['patientId'] as String)
              .get();
          
          final patientData = patientDoc.data() ?? {};
          
          // Log date and time values for debugging
          print("Appointment date: ${data['date']} (${data['date']?.runtimeType})");
          print("Appointment time: ${data['time']} (${data['time']?.runtimeType})");
          print("Hospital: ${data['hospitalName'] ?? data['hospital']} (${(data['hospitalName'] ?? data['hospital'])?.runtimeType})");
          
          return AppointmentModel.fromJson({
            'id': doc.id,
            'doctorName': patientData['fullName'] ?? patientData['name'] ?? 'Unknown Patient',
            'specialty': data['type'] ?? 'Consultation',
            'hospital': data['hospitalName'] ?? data['hospital'] ?? data['location'] ?? 'Not specified',
            'date': data['appointmentDate'] ?? data['date'],
            'time': data['time'],
            'status': data['status'] ?? 'pending',
            'diagnosis': data['diagnosis'],
            'prescription': data['prescription'],
            'notes': data['notes'],
            'fee': data['fee'],
          });
        } catch (e) {
          print("Error processing appointment ${doc.id}: $e");
          throw e;
        }
      }).toList());
    } catch (e) {
      print('Error fetching appointment history: $e');
      return [];
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating appointment status: $e');
      throw e;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(appointmentId, 'cancelled');
    } catch (e) {
      print('Error cancelling appointment: $e');
      throw e;
    }
  }
} 