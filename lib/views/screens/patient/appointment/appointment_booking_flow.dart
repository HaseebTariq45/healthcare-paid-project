import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppointmentBookingFlow extends StatefulWidget {
  final String? specialty;
  const AppointmentBookingFlow({super.key, this.specialty});

  @override
  _AppointmentBookingFlowState createState() => _AppointmentBookingFlowState();
}

class _AppointmentBookingFlowState extends State<AppointmentBookingFlow> {
  int _currentStep = 0;
  String? _selectedLocation;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedDoctor;

  // Sample data - Replace with actual API calls
  final List<String> _locations = [
    "Aga Khan Hospital, Karachi",
    "Shaukat Khanum Hospital, Lahore",
    "Jinnah Hospital, Karachi",
    "Liaquat National Hospital, Karachi",
  ];

  final List<String> _availableTimes = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
  ];

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Sarah Ahmed',
      'specialty': 'Cardiologist',
      'image': 'assets/images/User.png',
      'rating': 4.9,
      'experience': '15 years',
      'fee': 'Rs. 2000',
    },
    {
      'name': 'Dr. John Miller',
      'specialty': 'Neurologist',
      'image': 'assets/images/User.png',
      'rating': 4.8,
      'experience': '12 years',
      'fee': 'Rs. 2500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Appointment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            // Navigate to payment screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentMethodScreen(),
              ),
            );
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          } else {
            Navigator.pop(context);
          }
        },
        steps: [
          Step(
            title: Text(
              'Select Location',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: _buildLocationStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Select Date',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: _buildDateStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Select Time',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: _buildTimeStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Select Doctor',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: _buildDoctorStep(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isStepValid() ? details.onStepContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366CC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentStep == 3 ? 'Proceed to Payment' : 'Next'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedLocation != null;
      case 1:
        return _selectedDate != null;
      case 2:
        return _selectedTime != null;
      case 3:
        return _selectedDoctor != null;
      default:
        return false;
    }
  }

  Widget _buildLocationStep() {
    return Column(
      children: _locations.map((location) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedLocation = location;
              });
            },
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _selectedLocation == location
                    ? Color(0xFF3366CC).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedLocation == location
                      ? Color(0xFF3366CC)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    color: Color(0xFF3366CC),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_selectedLocation == location)
                    Icon(
                      LucideIcons.check,
                      color: Color(0xFF3366CC),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateStep() {
    return Column(
      children: [
        Container(
          height: 300,
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 30)),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
        ),
        if (_selectedDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFF3366CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF3366CC),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.calendar,
                    color: Color(0xFF3366CC),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Selected Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      children: _availableTimes.map((time) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTime = time;
              });
            },
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _selectedTime == time
                    ? Color(0xFF3366CC).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTime == time
                      ? Color(0xFF3366CC)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    color: Color(0xFF3366CC),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (_selectedTime == time)
                    Icon(
                      LucideIcons.check,
                      color: Color(0xFF3366CC),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoctorStep() {
    return Column(
      children: _doctors.map((doctor) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedDoctor = doctor['name'];
              });
            },
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _selectedDoctor == doctor['name']
                    ? Color(0xFF3366CC).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDoctor == doctor['name']
                      ? Color(0xFF3366CC)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(doctor['image']),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          doctor['specialty'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              doctor['rating'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 15),
                            Text(
                              doctor['fee'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Color(0xFF3366CC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_selectedDoctor == doctor['name'])
                    Icon(
                      LucideIcons.check,
                      color: Color(0xFF3366CC),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
} 