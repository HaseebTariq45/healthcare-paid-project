import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:healthcare/views/screens/patient/appointment/patient_payment_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppointmentBookingFlow extends StatefulWidget {
  final String? specialty;
  final Map<String, dynamic>? preSelectedDoctor;
  const AppointmentBookingFlow({
    super.key, 
    this.specialty,
    this.preSelectedDoctor,
  });

  @override
  _AppointmentBookingFlowState createState() => _AppointmentBookingFlowState();
}

class _AppointmentBookingFlowState extends State<AppointmentBookingFlow> {
  int _currentStep = 0;
  String? _selectedLocation;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedDoctor;
  String? _selectedReason;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedDoctor != null) {
      _selectedDoctor = widget.preSelectedDoctor!['name'];
      _currentStep = 1; // Skip doctor selection step
    }
  }

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

  final List<String> _appointmentReasons = [
    "Regular Checkup",
    "Follow-up Visit",
    "New Symptoms",
    "Prescription Refill",
    "Test Results Review",
    "Emergency Consultation",
  ];

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Sarah Ahmed',
      'specialty': 'Cardiologist',
      'image': 'assets/images/User.png',
      'rating': 4.9,
      'experience': '15 years',
      'fee': 'Rs. 2000',
      'availability': ['09:00 AM', '10:00 AM', '11:00 AM'],
      'languages': ['English', 'Urdu'],
      'qualifications': ['MBBS', 'FCPS', 'MRCP'],
    },
    {
      'name': 'Dr. John Miller',
      'specialty': 'Neurologist',
      'image': 'assets/images/User.png',
      'rating': 4.8,
      'experience': '12 years',
      'fee': 'Rs. 2500',
      'availability': ['02:00 PM', '03:00 PM', '04:00 PM'],
      'languages': ['English'],
      'qualifications': ['MBBS', 'MD', 'DM'],
    },
  ];

  List<Step> _buildSteps() {
    List<Step> steps = [
      Step(
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: _selectedLocation != null
            ? Text(
                _selectedLocation!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
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
        subtitle: _selectedDate != null
            ? Text(
                '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
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
        subtitle: _selectedTime != null
            ? Text(
                _selectedTime!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        content: _buildTimeStep(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];

    if (widget.preSelectedDoctor == null) {
      steps.add(
        Step(
          title: Text(
            'Select Doctor',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: _selectedDoctor != null
              ? Text(
                  _selectedDoctor!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                )
              : null,
          content: _buildDoctorStep(),
          isActive: _currentStep >= 3,
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        ),
      );
    }

    steps.add(
      Step(
        title: Text(
          'Appointment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: _buildAppointmentDetailsStep(),
        isActive: _currentStep >= (widget.preSelectedDoctor == null ? 4 : 3),
        state: _currentStep > (widget.preSelectedDoctor == null ? 4 : 3) 
            ? StepState.complete 
            : StepState.indexed,
      ),
    );

    return steps;
  }

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
      body: Stack(
        children: [
          Stepper(
            currentStep: _currentStep,
            onStepContinue: _proceedToNextStep,
            onStepCancel: _goToPreviousStep,
            steps: _buildSteps(),
          ),
          if (_errorMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3366CC)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _proceedToNextStep() {
    if (_isStepValid()) {
      setState(() {
        _errorMessage = null;
        if (_currentStep < 4) {
          _currentStep += 1;
        } else {
          _processPayment();
        }
      });
    } else {
      setState(() {
        _errorMessage = _getValidationMessage();
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
        _errorMessage = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Collect appointment details
      Map<String, dynamic> appointmentDetails = {
        'doctor': _selectedDoctor ?? '',
        'date': _selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : '',
        'time': _selectedTime ?? '',
        'location': _selectedLocation ?? '',
        'reason': _selectedReason ?? '',
        'fee': widget.preSelectedDoctor != null ? widget.preSelectedDoctor!['fee'] : 'Rs. 2000', // Default fee
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientPaymentScreen(
            appointmentDetails: appointmentDetails,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process payment. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getValidationMessage() {
    switch (_currentStep) {
      case 0:
        return 'Please select a location';
      case 1:
        return 'Please select a date';
      case 2:
        return 'Please select a time';
      case 3:
        return 'Please select a doctor';
      case 4:
        return 'Please provide appointment details';
      default:
        return 'Please complete this step';
    }
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
      case 4:
        return _selectedReason != null;
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
                _errorMessage = null;
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
                _errorMessage = null;
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
                _errorMessage = null;
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
                _errorMessage = null;
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
              child: Column(
                children: [
                  Row(
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
                  if (_selectedDoctor == doctor['name'])
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qualifications:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: doctor['qualifications'].map<Widget>((qual) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF3366CC).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  qual,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Color(0xFF3366CC),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Languages:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: doctor['languages'].map<Widget>((lang) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  lang,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAppointmentDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Summary',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 20),
        _buildSummaryItem(
          LucideIcons.mapPin,
          'Location',
          _selectedLocation ?? 'Not selected',
        ),
        _buildSummaryItem(
          LucideIcons.calendar,
          'Date',
          _selectedDate != null
              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
              : 'Not selected',
        ),
        _buildSummaryItem(
          LucideIcons.clock,
          'Time',
          _selectedTime ?? 'Not selected',
        ),
        _buildSummaryItem(
          LucideIcons.user,
          'Doctor',
          _selectedDoctor ?? 'Not selected',
        ),
        SizedBox(height: 20),
        Text(
          'Appointment Reason',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _appointmentReasons.map((reason) {
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedReason = reason;
                  _errorMessage = null;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedReason == reason
                      ? Color(0xFF3366CC).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedReason == reason
                        ? Color(0xFF3366CC)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _selectedReason == reason
                        ? Color(0xFF3366CC)
                        : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(
            icon,
            color: Color(0xFF3366CC),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 