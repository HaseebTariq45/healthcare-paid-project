import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, String> doctor;

  const BookAppointmentScreen({required this.doctor, Key? key}) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  String selectedTime = "02:00 PM";
  bool isPanelConsultation = false;
  TextEditingController notesController = TextEditingController();

  final List<String> availableTimes = [
    "09:00 AM", "10:00 AM", "11:00 AM", "01:00 PM",
    "02:00 PM", "03:00 PM", "04:00 PM", "07:00 PM", "08:00 PM"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Book Appointment"),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(widget.doctor["image"]!, width: 70, height: 70, fit: BoxFit.cover),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.doctor["name"]!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(widget.doctor["specialty"]!, style: TextStyle(color: Colors.grey)),
                    Row(
                      children: [
                        _iconText(LucideIcons.star, widget.doctor["rating"]!, Colors.blue),
                        SizedBox(width: 10),
                        _iconText(LucideIcons.dollarSign, widget.doctor["fee"]!, Colors.blue),
                      ],
                    ),
                    _iconText(LucideIcons.mapPin, widget.doctor["location"]!, Colors.grey),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // About Section
            Text("About", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 5),
            Text(
              "Lorem ipsum dolor sit amet, consectetur adipi elit, sed do eiusmod tempor incididunt ut laore et dolore magna aliqua. Ut enim ad minim veniam... ",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Read more",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Calendar Picker
            _buildCalendar(),
            SizedBox(height: 16),

            // Time Slots
            _buildTimeSlots(),
            const SizedBox(height: 20),

            // Request Panel Consultation
            Row(
              children: [
                Checkbox(
                  value: isPanelConsultation,
                  onChanged: (bool? value) {
                    setState(() {
                      isPanelConsultation = value!;
                    });
                  },
                ),
                Text("Request Panel Consultation"),
              ],
            ),
            SizedBox(height: 16),

            // Additional Notes
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Additional Notes",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(LucideIcons.fileText),
              ),
            ),
            SizedBox(height: 16),

            // Book Appointment Button
            _buildSubmitButton(),
          ],
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

  // Widget for Time Slots
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

  // Icon with text widget
  Widget _iconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
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
              builder: (context) => PaymentMethodScreen(), // Navigate to JazzCash screen
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
