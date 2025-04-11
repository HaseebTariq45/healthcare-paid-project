import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/available_doctors.dart';
import 'package:table_calendar/table_calendar.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  @override
  _RescheduleAppointmentScreenState createState() => _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState extends State<RescheduleAppointmentScreen> {
   DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  bool _isPanelConsultationRequested = false;
  TextEditingController _notesController = TextEditingController();

  final List<String> availableTimes = [
    "09:00 AM", "10:00 AM", "11:00 AM",
    "01:00 PM", "02:00 PM", "03:00 PM",
    "04:00 PM", "07:00 PM", "08:00 PM"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Reschedule Appointment"),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Details
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/patient_1.png'), // Replace with network image if needed
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dr. Rizwan", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Cardiologist", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.blue, size: 16),
                          Text(" 4.7 ", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue)),
                          Icon(Icons.attach_money, color: Colors.blue, size: 16),
                          Text(" Rs 1500", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
        
              SizedBox(height: 20),
        
              // Date Picker
              Text("Preferred Time and Date", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildCalendar(),
        
              SizedBox(height: 20),
        
             _buildTimeSlots(),
        
              SizedBox(height: 20),
        
              // Request Panel Consultation Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isPanelConsultationRequested,
                    onChanged: (bool? value) {
                      setState(() {
                        _isPanelConsultationRequested = value ?? false;
                      });
                    },
                  ),
                  Text("Request Panel Consultation", style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
        
              SizedBox(height: 10),
        
              // Additional Notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Additional Notes",
                  prefixIcon: Icon(Icons.note, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
        
              SizedBox(height: 20),
        
              // Reschedule Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      width: 400,
      height: 410,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0),
      child: TableCalendar(
        focusedDay: _selectedDay,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        calendarFormat: CalendarFormat.month,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color.fromRGBO(64, 124, 226, 1),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color.fromRGBO(64, 124, 226, 1),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
          });
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 15,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children:
          availableTimes.map((time) {
            bool isSelected = time == _selectedTime;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Color.fromRGBO(64, 124, 226, 1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color.fromRGBO(64, 124, 226, 1)),
                ),
                child: Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorsScreen(), // Navigate to JazzCash screen
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Book Appointment",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
