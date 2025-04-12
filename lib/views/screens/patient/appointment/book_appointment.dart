import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:healthcare/views/screens/patient/appointment/patient_payment_screen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({required this.doctor, Key? key}) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  bool isPanelConsultation = false;
  TextEditingController notesController = TextEditingController();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> availableTimes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _fetchAvailableTimeSlots(_selectedDay);
  }
  
  // Fetch available time slots for this doctor on the selected date
  Future<void> _fetchAvailableTimeSlots(DateTime date) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final doctorId = widget.doctor['id'];
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Default available times if we can't find any
      final List<String> defaultTimes = [
        "09:00 AM", "10:00 AM", "11:00 AM", "01:00 PM",
        "02:00 PM", "03:00 PM", "04:00 PM", "07:00 PM", "08:00 PM"
      ];
      
      if (doctorId == null) {
        // If no doctor ID, use default times
        if (mounted) {
          setState(() {
            availableTimes = defaultTimes;
            _isLoading = false;
          });
        }
        return;
      }
      
      // Get doctor's hospitals
      final hospitalsQuery = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      if (hospitalsQuery.docs.isEmpty) {
        // No hospitals found, use default times
        if (mounted) {
          setState(() {
            availableTimes = defaultTimes;
            _isLoading = false;
          });
        }
        return;
      }
      
      // Check availability for each hospital
      List<String> allTimeSlots = [];
      for (var hospitalDoc in hospitalsQuery.docs) {
        final hospitalData = hospitalDoc.data();
        final hospitalId = hospitalData['hospitalId'];
        
        // Query availability for this hospital and date
        final availabilityQuery = await _firestore
            .collection('doctor_availability')
            .where('doctorId', isEqualTo: doctorId)
            .where('hospitalId', isEqualTo: hospitalId)
            .where('date', isEqualTo: dateStr)
            .limit(1)
            .get();
        
        if (availabilityQuery.docs.isNotEmpty) {
          final availabilityData = availabilityQuery.docs.first.data();
          final List<String> timeSlots = List<String>.from(availabilityData['timeSlots'] ?? []);
          allTimeSlots.addAll(timeSlots);
        }
      }
      
      // Remove duplicates from allTimeSlots
      final Set<String> uniqueTimeSlots = Set<String>.from(allTimeSlots);
      
      if (mounted) {
        setState(() {
          availableTimes = uniqueTimeSlots.isEmpty ? defaultTimes : uniqueTimeSlots.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading time slots: $e';
          _isLoading = false;
          
          // Default times as fallback
          availableTimes = [
            "09:00 AM", "10:00 AM", "11:00 AM", "01:00 PM",
            "02:00 PM", "03:00 PM", "04:00 PM", "07:00 PM", "08:00 PM"
          ];
        });
      }
      debugPrint('Error fetching time slots: $e');
    }
  }

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
                  child: widget.doctor["image"].toString().startsWith("assets/")
                      ? Image.asset(widget.doctor["image"]!, width: 70, height: 70, fit: BoxFit.cover)
                      : Image.network(widget.doctor["image"]!, width: 70, height: 70, fit: BoxFit.cover, 
                          errorBuilder: (context, error, stackTrace) => 
                            Icon(MdiIcons.accountCircle, size: 70, color: Colors.grey[400]),
                        ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.doctor["name"]!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(widget.doctor["specialty"]!, style: TextStyle(color: Colors.grey)),
                    Row(
                      children: [
                        _iconText(MdiIcons.star, widget.doctor["rating"]!, Colors.blue),
                        SizedBox(width: 10),
                        _iconText(MdiIcons.currencyUsd, widget.doctor["fee"]!, Colors.blue),
                      ],
                    ),
                    _iconText(MdiIcons.mapMarker, widget.doctor["location"]!, Colors.grey),
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
            Text("Available Time Slots", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
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
                prefixIcon: Icon(MdiIcons.fileDocument),
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
        onDaySelected: _onDaySelected,
      ),
    );
  }

  // Widget for Time Slots
  Widget _buildTimeSlots() {
    if (_isLoading) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Loading available time slots...")
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 10),
            Text("Error: $_errorMessage"),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _fetchAvailableTimeSlots(_selectedDay),
              child: Text("Retry"),
            )
          ],
        ),
      );
    }
    
    return Wrap(
      spacing: 15,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: availableTimes.map((time) {
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
              color: isSelected ? Color.fromRGBO(64, 124, 226, 1) : Colors.white,
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
  
  // Override onDaySelected to fetch new time slots when date changes
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedTime = null; // Clear selected time when date changes
    });
    
    // Fetch time slots for the new date
    _fetchAvailableTimeSlots(selectedDay);
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
          // Just collect appointment details and proceed to payment
          // Appointment will be created only after successful payment
          Map<String, dynamic> appointmentDetails = {
            'doctor': widget.doctor['name'] ?? 'Dr. Sarah Ahmed',
            'doctorId': widget.doctor['id'],
            'date': "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
            'time': _selectedTime,
            'location': widget.doctor['location'] ?? 'Aga Khan Hospital, Karachi',
            'fee': widget.doctor['fee'] ?? 'Rs. 2000',
            'isPanelConsultation': isPanelConsultation,
            'notes': notesController.text,
          };

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentOptionsScreen(
                appointmentDetails: appointmentDetails,
                onProceed: (paymentMethod) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientPaymentScreen(
                        appointmentDetails: appointmentDetails,
                        paymentMethod: paymentMethod,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          "Proceed to Payment",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

}
