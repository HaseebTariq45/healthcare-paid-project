import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletedAppointmentsScreen extends StatefulWidget {
  const CompletedAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<CompletedAppointmentsScreen> createState() => _CompletedAppointmentsScreenState();
}

class _CompletedAppointmentsScreenState extends State<CompletedAppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Appointments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: _auth.currentUser?.uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('appointmentDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No completed appointments found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final appointment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final appointmentDate = (appointment['appointmentDate'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Dr. ${appointment['doctorName'] ?? 'Unknown Doctor'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${appointmentDate.toString().split('.')[0]}'),
                      Text('Specialization: ${appointment['specialization'] ?? 'N/A'}'),
                      Text('Fee: Rs.${appointment['fee'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 