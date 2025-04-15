import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppointmentModel>> getAppointmentHistory(String userId) async {
    try {
      final QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return Future.wait(appointmentsSnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        
        // Fetch patient details to get the name
        final patientDoc = await _firestore
            .collection('patients')
            .doc(data['patientId'] as String)
            .get();
        
        final patientData = patientDoc.data() ?? {};
        
        return AppointmentModel.fromJson({
          'id': doc.id,
          'doctorName': patientData['fullName'] ?? patientData['name'] ?? 'Unknown Patient',
          'specialty': data['type'] ?? 'Consultation',
          'hospital': data['hospital'] ?? data['location'] ?? 'Not specified',
          'date': data['date'],
          'status': data['status'] ?? 'pending',
          'diagnosis': data['diagnosis'],
          'prescription': data['prescription'],
          'notes': data['notes'],
          'fee': data['fee'],
        });
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