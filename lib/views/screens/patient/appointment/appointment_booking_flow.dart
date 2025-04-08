import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:healthcare/views/screens/patient/appointment/patient_payment_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

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

class _AppointmentBookingFlowState extends State<AppointmentBookingFlow> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedLocation;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedDoctor;
  String? _selectedReason;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedDoctor != null) {
      _selectedDoctor = widget.preSelectedDoctor!['name'];
      _currentStep = 1; // Skip doctor selection step
    }
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Book Appointment',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: Stack(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Color(0xFF2B8FEB),
                      secondary: Color(0xFF2B8FEB),
                      surface: Colors.white,
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2B8FEB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _proceedToNextStep,
                    onStepCancel: _goToPreviousStep,
                    steps: _buildSteps(),
                    type: StepperType.vertical,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Row(
                          children: [
                            if (details.currentStep > 0)
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Color(0xFF2B8FEB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    'Back',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2B8FEB),
                                    ),
                                  ),
                                ),
                              ),
                            if (details.currentStep > 0)
                              SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(
                                  details.currentStep == _buildSteps().length - 1
                                      ? 'Confirm Booking'
                                      : 'Continue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.info,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: Colors.red.shade900,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Hospital Location',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select the hospital where you would like to schedule your appointment',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _locations.length,
          itemBuilder: (context, index) {
            final location = _locations[index];
            final isSelected = location == _selectedLocation;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFFEDF7FF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(0xFF2B8FEB).withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(0xFF2B8FEB).withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.building2,
                          color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.split(',')[0],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              location.split(',')[1].trim(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2B8FEB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Appointment Date',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Choose your preferred date for the appointment',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 90)),
            focusedDay: _selectedDate ?? DateTime.now(),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Color(0xFF2B8FEB),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0xFF2B8FEB).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: GoogleFonts.poppins(
                color: Color(0xFF2B8FEB),
                fontWeight: FontWeight.w600,
              ),
              defaultTextStyle: GoogleFonts.poppins(),
              weekendTextStyle: GoogleFonts.poppins(
                color: Colors.red.shade300,
              ),
              outsideTextStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              formatButtonVisible: false,
              leftChevronIcon: Icon(
                LucideIcons.chevronLeft,
                color: Color(0xFF2B8FEB),
              ),
              rightChevronIcon: Icon(
                LucideIcons.chevronRight,
                color: Color(0xFF2B8FEB),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              weekendStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.red.shade300,
              ),
            ),
          ),
        ),
        if (_selectedDate != null) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFEDF7FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF2B8FEB).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF2B8FEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.calendar,
                    color: Color(0xFF2B8FEB),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Appointment Time',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select your preferred time slot',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Morning Slots',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableTimes
                    .where((time) => time.contains('AM'))
                    .map((time) => _buildTimeSlot(time))
                    .toList(),
              ),
              SizedBox(height: 24),
              Text(
                'Afternoon Slots',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableTimes
                    .where((time) => time.contains('PM'))
                    .map((time) => _buildTimeSlot(time))
                    .toList(),
              ),
            ],
          ),
        ),
        if (_selectedTime != null) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFEDF7FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF2B8FEB).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF2B8FEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.clock,
                    color: Color(0xFF2B8FEB),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _selectedTime!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = time == _selectedTime;
    final isPastTime = _selectedDate?.day == DateTime.now().day &&
        _parseTime(time).isBefore(DateTime.now());

    return InkWell(
      onTap: isPastTime
          ? null
          : () {
              setState(() {
                _selectedTime = time;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isPastTime
              ? Colors.grey.shade100
              : isSelected
                  ? Color(0xFF2B8FEB)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPastTime
                ? Colors.grey.shade300
                : isSelected
                    ? Color(0xFF2B8FEB)
                    : Colors.grey.shade200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2B8FEB).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isPastTime
                ? Colors.grey.shade400
                : isSelected
                    ? Colors.white
                    : Colors.black87,
          ),
        ),
      ),
    );
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final time = timeStr.toUpperCase();
    final isPM = time.contains('PM');
    final timeParts = time.replaceAll(RegExp(r'[AP]M'), '').split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  Widget _buildDoctorStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Doctor',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select a doctor for your appointment',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _doctors.length,
          itemBuilder: (context, index) {
            final doctor = _doctors[index];
            final isSelected = doctor['name'] == _selectedDoctor;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedDoctor = doctor['name'];
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Color(0xFF2B8FEB).withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Color(0xFFEDF7FF),
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: AssetImage(doctor['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
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
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      doctor['rating'].toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Icon(
                                      LucideIcons.briefcase,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      doctor['experience'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF2B8FEB),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(
                              LucideIcons.languages,
                              'Languages',
                              (doctor['languages'] as List).join(', '),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _buildInfoItem(
                              LucideIcons.graduationCap,
                              'Qualifications',
                              (doctor['qualifications'] as List).join(', '),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consultation Fee',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                doctor['fee'],
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2B8FEB),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFEDF7FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  color: Color(0xFF2B8FEB),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Available Today',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2B8FEB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF2B8FEB),
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Summary',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Review your appointment details',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryItem(
                LucideIcons.building2,
                'Hospital',
                _selectedLocation ?? 'Not selected',
                Color(0xFF2B8FEB),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              _buildSummaryItem(
                LucideIcons.calendar,
                'Date',
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Not selected',
                Color(0xFF00BFA5),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              _buildSummaryItem(
                LucideIcons.clock,
                'Time',
                _selectedTime ?? 'Not selected',
                Color(0xFFFFA000),
              ),
              if (widget.preSelectedDoctor == null) ...[
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                _buildSummaryItem(
                  LucideIcons.stethoscope,
                  'Doctor',
                  _selectedDoctor ?? 'Not selected',
                  Color(0xFFE91E63),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reason for Visit',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _appointmentReasons.map((reason) {
                  final isSelected = reason == _selectedReason;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF2B8FEB) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFF2B8FEB)
                              : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(0xFF2B8FEB).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        reason,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (_selectedDoctor != null) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFEDF7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.wallet,
                    color: Color(0xFF2B8FEB),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consultation Fee',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _doctors
                            .firstWhere(
                              (d) => d['name'] == _selectedDoctor,
                              orElse: () => {'fee': 'Not available'},
                            )['fee']
                            .toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B8FEB),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF2B8FEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pay at Hospital',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B8FEB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 

