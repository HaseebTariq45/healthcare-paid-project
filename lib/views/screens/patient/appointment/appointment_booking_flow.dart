import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:healthcare/views/screens/patient/appointment/patient_payment_screen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:healthcare/views/screens/patient/appointment/completed_appointments_screen.dart';

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
  String? _selectedHospitalId;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedDoctor;
  String? _selectedReason;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Firestore and Auth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Doctor data
  late Map<String, dynamic> _doctorData;
  
  // Available locations (hospitals) for the selected doctor
  List<Map<String, dynamic>> _doctorHospitals = [];
  
  // Available time slots for the selected date and hospital
  List<String> _availableTimesForSelectedDate = [];
  bool _loadingTimeSlots = false;
  
  // Map to store available time slots for each date
  Map<String, List<String>> _dateTimeSlots = {};
  
  final Map<String, GlobalKey> _stepKeys = {
    'location': GlobalKey(),
    'date': GlobalKey(),
    'time': GlobalKey(),
    'doctor': GlobalKey(),
    'details': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize doctor data
    _doctorData = widget.preSelectedDoctor ?? {};
    
    if (widget.preSelectedDoctor != null) {
      _selectedDoctor = widget.preSelectedDoctor!['name'];
      _currentStep = 0; // Start with hospital selection when doctor is pre-selected
      
      // Extract the doctor's hospitals from the data
      if (widget.preSelectedDoctor!.containsKey('hospitals')) {
        _doctorHospitals = List<Map<String, dynamic>>.from(widget.preSelectedDoctor!['hospitals']);
      } else {
        // Fetch hospitals if not included in the doctor data
        _fetchDoctorHospitals(widget.preSelectedDoctor!['id']);
      }
    } else {
      // If no doctor is pre-selected, fetch all available doctors from Firestore
      _fetchAllDoctors();
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
  
  // Fetch doctor's hospitals from Firestore
  Future<void> _fetchDoctorHospitals(String doctorId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final hospitalsQuery = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      final List<Map<String, dynamic>> hospitalsList = [];
      
      for (var hospitalDoc in hospitalsQuery.docs) {
        final hospitalData = hospitalDoc.data();
        final hospitalId = hospitalData['hospitalId'];
        final hospitalName = hospitalData['hospitalName'] ?? 'Unknown Hospital';
        final address = hospitalData['address'] ?? '';
        
        hospitalsList.add({
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'address': address,
        });
      }
      
      if (mounted) {
        setState(() {
          // Update the doctor's data with the hospitals
          if (_doctorData.containsKey('id') && _doctorData['id'] == doctorId) {
            _doctorData['hospitals'] = hospitalsList;
          }
          
          // If we're in the hospital selection step (not doctor selection step)
          if (_selectedDoctor != null || widget.preSelectedDoctor != null) {
            _doctorHospitals = hospitalsList;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading hospital information: $e';
          _isLoading = false;
        });
      }
      debugPrint('Error fetching doctor hospitals: $e');
    }
  }
  
  // Fetch time slots for a specific date and hospital
  Future<void> _fetchTimeSlotsForDate(String hospitalId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Check if we already have this data cached
    if (_dateTimeSlots.containsKey('$hospitalId-$dateStr')) {
      setState(() {
        _availableTimesForSelectedDate = _dateTimeSlots['$hospitalId-$dateStr'] ?? [];
      });
      return;
    }
    
    setState(() {
      _loadingTimeSlots = true;
    });
    
    try {
      final doctorId = _doctorData['id'];
      
      // Query Firestore for availability
      final availabilityQuery = await _firestore
          .collection('doctor_availability')
          .where('doctorId', isEqualTo: doctorId)
          .where('hospitalId', isEqualTo: hospitalId)
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();
      
      List<String> timeSlots = [];
      if (availabilityQuery.docs.isNotEmpty) {
        final availabilityData = availabilityQuery.docs.first.data();
        timeSlots = List<String>.from(availabilityData['timeSlots'] ?? []);
      }
      
      // Cache the result
      _dateTimeSlots['$hospitalId-$dateStr'] = timeSlots;
      
      if (mounted) {
        setState(() {
          _availableTimesForSelectedDate = timeSlots;
          _loadingTimeSlots = false;
          
          // Clear selected time if it's not available for this date
          if (_selectedTime != null && !timeSlots.contains(_selectedTime)) {
            _selectedTime = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading time slots: $e';
          _loadingTimeSlots = false;
        });
      }
      debugPrint('Error fetching time slots: $e');
    }
  }

  final List<String> _appointmentReasons = [
    "Regular Checkup",
    "Follow-up Visit",
    "New Symptoms",
    "Prescription Refill",
    "Test Results Review",
    "Emergency Consultation",
  ];

  List<Step> _buildSteps() {
    // When doctor is pre-selected (coming from specialty)
    if (widget.preSelectedDoctor != null) {
      List<Step> steps = [
        Step(
          title: Text(
            'Select Hospital',
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
        Step(
          title: Text(
            'Appointment Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: _selectedReason != null
              ? Text(
                  _selectedReason!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                )
              : null,
          content: _buildDetailsStep(),
          isActive: _currentStep >= 3,
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        ),
      ];
      return steps;
    } 
    // Normal flow when no doctor is pre-selected
    else {
      List<Step> steps = [
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
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: Text(
            'Select Hospital',
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
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
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
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
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
          isActive: _currentStep >= 3,
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: Text(
            'Appointment Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: _buildDetailsStep(),
          isActive: _currentStep >= 4,
          state: _currentStep > 4 ? StepState.complete : StepState.indexed,
        ),
      ];
      return steps;
    }
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
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
                    onStepTapped: (step) {
                      // Add animation when tapping on step
                      setState(() {
                        _currentStep = step;
                      });
                    },
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
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.9, end: 1.0),
                                  duration: Duration(milliseconds: 200),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
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
                                    );
                                  },
                                ),
                              ),
                            if (details.currentStep > 0)
                              SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.9, end: 1.0),
                                duration: Duration(milliseconds: 200),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
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
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_errorMessage != null)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
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
                              Icons.error_outline,
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
                              Icons.close,
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
        // Check if doctor is pre-selected to determine the final step
        int maxStep = widget.preSelectedDoctor == null ? 4 : 3;
        if (_currentStep < maxStep) {
          _currentStep += 1;
        } else {
          _processPayment();
        }
      });
    } else {
      setState(() {
        _errorMessage = _getValidationMessage();
      });
      
      // Shake animation for validation error
      final key = _getCurrentStepKey();
      if (key.currentContext != null) {
        _shakeError(key.currentContext!);
      }
    }
  }

  GlobalKey _getCurrentStepKey() {
    if (widget.preSelectedDoctor != null) {
      // Adjust step keys when doctor is pre-selected
      switch (_currentStep) {
        case 0:
          return _stepKeys['location']!;
        case 1:
          return _stepKeys['date']!;
        case 2:
          return _stepKeys['time']!;
        case 3:
          return _stepKeys['details']!;
        default:
          return _stepKeys['date']!;
      }
    } else {
      // Normal flow without pre-selected doctor
      switch (_currentStep) {
        case 0:
          return _stepKeys['doctor']!;
        case 1:
          return _stepKeys['location']!;
        case 2:
          return _stepKeys['date']!;
        case 3:
          return _stepKeys['time']!;
        case 4:
          return _stepKeys['details']!;
        default:
          return _stepKeys['doctor']!;
      }
    }
  }

  void _shakeError(BuildContext context) {
    const double shakeDelta = 10.0;
    const double shakeCount = 3;
    final duration = Duration(milliseconds: 500);
    
    // This is an approximation of a shake animation without using AnimationController
    Future.delayed(Duration(milliseconds: 0), () {
      if (mounted) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        
        // Shake logic would go here - for a real implementation, you would use
        // an AnimationController with a sequence of translations
      }
    });
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
      _errorMessage = null;
    });

    try {
      // First check if the slot is still available
      final String dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '';
      final String slotAvailabilityId = '${_selectedHospitalId}_${dateStr}_${_selectedTime}';
      
      // Check slot availability in a transaction to prevent race conditions
      bool isSlotAvailable = await _firestore.runTransaction<bool>((transaction) async {
        final slotDoc = await transaction.get(_firestore
            .collection('appointment_slots')
            .doc(slotAvailabilityId));
            
        if (slotDoc.exists) {
          final slotData = slotDoc.data() as Map<String, dynamic>;
          return !(slotData['isBooked'] ?? false);
        }
        return true; // Slot document doesn't exist means it's available
      });

      if (!isSlotAvailable) {
        setState(() {
          _errorMessage = 'Sorry, this slot has just been booked by someone else. Please select another time slot.';
          _isLoading = false;
        });
        return;
      }

      // Collect appointment details
      Map<String, dynamic> appointmentDetails = {
        'doctorId': widget.preSelectedDoctor != null ? widget.preSelectedDoctor!['id'] : _doctorData['id'],
        'doctorName': _selectedDoctor ?? '',
        'doctorSpecialty': widget.preSelectedDoctor != null ? widget.preSelectedDoctor!['specialty'] : _doctorData['specialty'] ?? '',
        'hospitalId': _selectedHospitalId ?? '',
        'hospitalName': _selectedLocation ?? '',
        'date': dateStr,
        'time': _selectedTime ?? '',
        'reason': _selectedReason ?? '',
        'fee': _parseFeeAmount(widget.preSelectedDoctor != null ? widget.preSelectedDoctor!['fee'] : _doctorData['fee'] ?? 'Rs. 2000'),
        'displayFee': widget.preSelectedDoctor != null ? widget.preSelectedDoctor!['fee'] : _doctorData['fee'] ?? 'Rs. 2000',
        'patientId': _auth.currentUser?.uid ?? '',
        'status': 'pending_payment',
        'slotId': slotAvailabilityId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Place a temporary hold on the slot
      await _firestore.collection('appointment_slots').doc(slotAvailabilityId).set({
        'isBooked': false,
        'tempHoldUntil': FieldValue.serverTimestamp(),
        'tempHoldBy': _auth.currentUser?.uid,
        'appointmentDetails': appointmentDetails,
      }, SetOptions(merge: true));

      // Navigate to payment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientPaymentScreen(
            appointmentDetails: appointmentDetails,
          ),
        ),
      );

      // Check payment result
      if (result == 'payment_successful') {
        try {
          // Update both the appointment and slot status in a single transaction
          await _firestore.runTransaction((transaction) async {
            // Create a new appointment document
            final appointmentRef = _firestore.collection('appointments').doc();
            
            // Update appointment details with confirmed status
            appointmentDetails['status'] = 'confirmed';
            appointmentDetails['paymentStatus'] = 'completed';
            appointmentDetails['paymentDate'] = FieldValue.serverTimestamp();
            transaction.set(appointmentRef, appointmentDetails);

            // Update slot status
            final slotRef = _firestore.collection('appointment_slots').doc(slotAvailabilityId);
            transaction.set(slotRef, {
              'isBooked': true,
              'tempHoldUntil': null,
              'tempHoldBy': null,
              'bookedBy': _auth.currentUser?.uid,
              'bookedAt': FieldValue.serverTimestamp(),
              'appointmentId': appointmentRef.id,
              'appointmentDetails': appointmentDetails,
            }, SetOptions(merge: true));
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment booked successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to completed appointments screen, replacing the entire stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => CompletedAppointmentsScreen(),
            ),
            (route) => false, // This will remove all previous routes
          );
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to save appointment. Please contact support.';
          });
          debugPrint('Error saving appointment after payment: $e');
        }
      } else {
        // Payment failed or cancelled, release the hold on the slot
        await _firestore.collection('appointment_slots').doc(slotAvailabilityId).delete();
        
        setState(() {
          _errorMessage = 'Payment was not completed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process payment. Please try again.';
      });
      debugPrint('Error in _processPayment: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a periodic cleanup function for temporary holds
  void _cleanupExpiredHolds() async {
    try {
      final now = DateTime.now();
      final expiryThreshold = now.subtract(Duration(minutes: 15));
      
      final expiredHolds = await _firestore
          .collection('appointment_slots')
          .where('tempHoldUntil', isLessThan: expiryThreshold)
          .where('isBooked', isEqualTo: false)
          .get();
          
      for (var doc in expiredHolds.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error cleaning up expired holds: $e');
    }
  }

  String _getValidationMessage() {
    // Adjust indexes when doctor is pre-selected
    if (widget.preSelectedDoctor != null) {
      switch (_currentStep) {
        case 0:
          return 'Please select a location';
        case 1:
          return 'Please select a date';
        case 2:
          return 'Please select a time';
        case 3:
          return 'Please select a reason for visit';
        default:
          return 'Please complete this step';
      }
    } else {
      switch (_currentStep) {
        case 0:
          return 'Please select a doctor';
        case 1:
          return 'Please select a location';
        case 2:
          return 'Please select a date';
        case 3:
          return 'Please select a time';
        case 4:
          return 'Please select a reason for visit';
        default:
          return 'Please complete this step';
      }
    }
  }

  bool _isStepValid() {
    // Adjust validation based on whether a doctor is pre-selected
    if (widget.preSelectedDoctor != null) {
      switch (_currentStep) {
        case 0:
          return _selectedLocation != null;
        case 1:
          return _selectedDate != null;
        case 2:
          return _selectedTime != null;
        case 3:
          return _selectedReason != null;
        default:
          return false;
      }
    } else {
      switch (_currentStep) {
        case 0:
          return _selectedDoctor != null;
        case 1:
          return _selectedLocation != null;
        case 2:
          return _selectedDate != null;
        case 3:
          return _selectedTime != null;
        case 4:
          return _selectedReason != null;
        default:
          return false;
      }
    }
  }

  Widget _buildLocationStep() {
    // Get available hospitals for the selected doctor
    List<Map<String, dynamic>> doctorHospitals = [];
    
    if (_selectedDoctor != null && _doctorData.containsKey('hospitals')) {
      // If a doctor is selected in the first step, use their hospitals
      doctorHospitals = List<Map<String, dynamic>>.from(_doctorData['hospitals']);
    } else if (widget.preSelectedDoctor != null) {
      // If doctor was pre-selected (from specialty screen), use the fetched hospitals
      doctorHospitals = _doctorHospitals;
    }
    
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _currentStep == (widget.preSelectedDoctor != null ? 0 : 1) ? 1.0 : 0.8,
      child: Column(
        key: _stepKeys['location'],
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedDoctor != null || widget.preSelectedDoctor != null
                ? 'Choose Hospital for ${_selectedDoctor ?? widget.preSelectedDoctor!['name']}'
                : 'Choose Hospital Location',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedDoctor != null || widget.preSelectedDoctor != null
                ? 'Select the hospital where you would like to schedule your appointment with ${_selectedDoctor ?? widget.preSelectedDoctor!['name']}'
                : 'Select the hospital where you would like to schedule your appointment',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          
          if (doctorHospitals.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hospitals available for the selected doctor',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please select a different doctor or try another date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: doctorHospitals.length,
              itemBuilder: (context, index) {
                final hospital = doctorHospitals[index];
                final hospitalName = hospital['hospitalName'];
                final hospitalId = hospital['hospitalId'];
                final isSelected = hospitalId == _selectedHospitalId || hospitalName == _selectedLocation;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLocation = hospitalName;
                        _selectedHospitalId = hospitalId;
                        
                        // If date is selected, fetch time slots for this hospital and date
                        if (_selectedDate != null) {
                          _fetchTimeSlotsForDate(hospitalId, _selectedDate!);
                        }
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
                              MdiIcons.officeBuildingOutline,
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
                                  hospitalName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (hospital.containsKey('address')) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    hospital['address'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
                                Icons.check_circle,
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
        ],
      ),
    );
  }

  Widget _buildDateStep() {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _currentStep == (widget.preSelectedDoctor != null ? 1 : 2) ? 1.0 : 0.8,
      child: Column(
        key: _stepKeys['date'],
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.preSelectedDoctor != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Color(0xFFEDF7FF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(widget.preSelectedDoctor!['image']),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.preSelectedDoctor!['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.preSelectedDoctor!['specialty'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFF2B8FEB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.preSelectedDoctor!['fee'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2B8FEB),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.preSelectedDoctor!['experience'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            widget.preSelectedDoctor != null
                ? 'Choose your preferred date for the appointment with ${widget.preSelectedDoctor!['name']}'
                : 'Choose your preferred date for the appointment',
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
                  Icons.chevron_left,
                  color: Color(0xFF2B8FEB),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
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
                      Icons.calendar_today,
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
      ),
    );
  }

  Widget _buildTimeStep() {
    // Fetch available time slots for selected doctor at selected hospital
    if (_selectedHospitalId != null && _selectedDate != null && _availableTimesForSelectedDate.isEmpty && !_loadingTimeSlots) {
      _fetchTimeSlotsForDate(_selectedHospitalId!, _selectedDate!);
    }
    
    // Get day of week for selected date
    String? dayOfWeek;
    if (_selectedDate != null) {
      switch (_selectedDate!.weekday) {
        case 1: dayOfWeek = 'Monday'; break;
        case 2: dayOfWeek = 'Tuesday'; break;
        case 3: dayOfWeek = 'Wednesday'; break;
        case 4: dayOfWeek = 'Thursday'; break;
        case 5: dayOfWeek = 'Friday'; break;
        case 6: dayOfWeek = 'Saturday'; break;
        case 7: dayOfWeek = 'Sunday'; break;
      }
    }
    
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _currentStep == (widget.preSelectedDoctor != null ? 2 : 3) ? 1.0 : 0.8,
      child: Column(
        key: _stepKeys['time'],
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
            _selectedDate != null 
                ? 'Select your preferred time slot for ${dayOfWeek}, ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Select your preferred time slot',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          
          if (_availableTimesForSelectedDate.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No time slots available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please select a different date or hospital',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          ] else ...[
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
                    'Available Slots',
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
                    children: _availableTimesForSelectedDate
                        .map((time) => _buildTimeSlot(time))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          
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
                      Icons.schedule,
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
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = time == _selectedTime;
    final isPastTime = _selectedDate?.day == DateTime.now().day &&
        _parseTime(time).isBefore(DateTime.now());

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: isSelected ? scale : 1.0,
          child: InkWell(
            onTap: isPastTime
                ? null
                : () {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
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
          ),
        );
      },
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
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _currentStep == 0 ? 1.0 : 0.8,
      child: Column(
        key: _stepKeys['doctor'],
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
          
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading doctors...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading doctors',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _fetchAllDoctors,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          else if (_doctorHospitals.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No doctors available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _doctorHospitals.length,
              itemBuilder: (context, index) {
                final doctor = _doctorHospitals[index];
                final isSelected = _selectedDoctor == doctor['name'];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDoctor = doctor['name'];
                        _doctorData = doctor;
                        
                        // When selecting a doctor, also prepare their hospitals for the next step
                        if (doctor['hospitals'] != null && (doctor['hospitals'] as List).isNotEmpty) {
                          // Just store the hospitals data; don't replace _doctorHospitals
                          // as it contains the list of all doctors in this step
                        } else {
                          // If hospitals are missing, fetch them
                          _fetchDoctorHospitals(doctor['id']);
                        }
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
                                ),
                                child: doctor['image'].toString().startsWith('assets/')
                                    ? Image.asset(
                                        doctor['image'],
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        doctor['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          MdiIcons.doctor,
                                          color: Colors.blue[300],
                                          size: 40,
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
                                          Icons.star,
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
                                          MdiIcons.briefcase,
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
                                    Icons.check_circle,
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
                                  Icons.message,
                                  'Languages',
                                  doctor['languages'] != null 
                                      ? (doctor['languages'] as List).join(', ')
                                      : 'English, Urdu',
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                _buildInfoItem(
                                  Icons.school,
                                  'Qualifications',
                                  doctor['qualifications'] != null
                                      ? (doctor['qualifications'] as List).join(', ')
                                      : 'MBBS',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Consultation Fee',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      doctor['fee'] ?? 'Rs 1500',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2B8FEB),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                flex: 4,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEDF7FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        color: Color(0xFF2B8FEB),
                                        size: 14,
                                      ),
                                      SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          doctor['hospitalName'] ?? 'Multiple Hospitals',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF2B8FEB),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
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
      ),
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
          SizedBox(width: 8),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildDetailsStep() {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _currentStep == (widget.preSelectedDoctor != null ? 3 : 4) ? 1.0 : 0.8,
      child: Column(
        key: _stepKeys['details'],
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
                if (widget.preSelectedDoctor == null) ...[
                  _buildSummaryItem(
                    MdiIcons.stethoscope,
                    'Doctor',
                    _selectedDoctor ?? 'Not selected',
                    Color(0xFFE91E63),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                ] else ...[
                  _buildSummaryItem(
                    MdiIcons.stethoscope,
                    'Doctor',
                    widget.preSelectedDoctor!['name'],
                    Color(0xFFE91E63),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                ],
                _buildSummaryItem(
                  MdiIcons.hospitalBuilding,
                  'Hospital',
                  _selectedLocation ?? 'Not selected',
                  Color(0xFF2B8FEB),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                _buildSummaryItem(
                  Icons.calendar_today,
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
                  Icons.schedule,
                  'Time',
                  _selectedTime ?? 'Not selected',
                  Color(0xFFFFA000),
                ),
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
                    return _buildReasonChip(reason);
                  }).toList(),
                ),
              ],
            ),
          ),
          if (_selectedDoctor != null || widget.preSelectedDoctor != null) ...[
            SizedBox(height: 24),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
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
                      MdiIcons.walletOutline,
                      color: Color(0xFF2B8FEB),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultation Fee',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: Duration(milliseconds: 300),
                          builder: (context, scale, child) {
                            final String fee = widget.preSelectedDoctor != null 
                                ? widget.preSelectedDoctor!['fee']
                                : _doctorHospitals
                                    .firstWhere(
                                      (d) => d['hospitalId'] == _selectedHospitalId,
                                      orElse: () => {'fee': 'Not available'},
                                    )['fee']
                                    .toString();
                                
                            return Transform.scale(
                              scale: scale,
                              child: Text(
                                fee,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2B8FEB),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF2B8FEB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pay at Hospital',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2B8FEB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonChip(String reason) {
    final isSelected = reason == _selectedReason;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: isSelected ? scale : 1.0,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedReason = reason;
              });
            },
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
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
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  // Fetch all available doctors from Firestore
  Future<void> _fetchAllDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Query doctor_hospitals to get doctors with hospital associations
      final QuerySnapshot doctorHospitalsSnapshot = await _firestore
          .collection('doctor_hospitals')
          .get();
      
      // Extract unique doctor IDs from hospital associations
      final Set<String> doctorIds = {};
      for (var doc in doctorHospitalsSnapshot.docs) {
        final hospitalData = doc.data() as Map<String, dynamic>;
        if (hospitalData.containsKey('doctorId')) {
          doctorIds.add(hospitalData['doctorId']);
        }
      }
      
      if (doctorIds.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _doctorHospitals = _getDefaultDoctors();
          });
        }
        return;
      }
      
      final List<Map<String, dynamic>> doctorsList = [];
      
      // For each doctor ID, get their information from the doctors collection
      for (String doctorId in doctorIds) {
        try {
          final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
          
          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            
            // Get doctor's hospitals
            final hospitalsQuery = await _firestore
                .collection('doctor_hospitals')
                .where('doctorId', isEqualTo: doctorId)
                .get();
            
            final List<Map<String, dynamic>> hospitalsList = [];
            
            for (var hospitalDoc in hospitalsQuery.docs) {
              final hospitalData = hospitalDoc.data();
              hospitalsList.add({
                'hospitalId': hospitalData['hospitalId'],
                'hospitalName': hospitalData['hospitalName'] ?? 'Unknown Hospital',
                'address': hospitalData['address'] ?? '',
              });
            }
            
            // Create doctor entry with all relevant information
            doctorsList.add({
              'id': doctorId,
              'name': doctorData['fullName'] ?? 'Unknown Doctor',
              'specialty': doctorData['specialty'] ?? 'General Practitioner',
              'rating': doctorData['rating']?.toString() ?? "4.5",
              'experience': doctorData['experience']?.toString() ?? "5 years",
              'fee': 'Rs ${doctorData['fee']?.toString() ?? "1500"}',
              'image': doctorData['profileImageUrl'] ?? "assets/images/User.png",
              'languages': doctorData['languages'] ?? ['English', 'Urdu'],
              'qualifications': doctorData['qualifications'] ?? ['MBBS'],
              'hospitals': hospitalsList,
              'hospitalId': hospitalsList.isNotEmpty ? hospitalsList.first['hospitalId'] : null,
              'hospitalName': hospitalsList.isNotEmpty ? hospitalsList.first['hospitalName'] : 'Not Available',
            });
          }
        } catch (e) {
          debugPrint('Error fetching doctor $doctorId: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          if (doctorsList.isEmpty) {
            _doctorHospitals = _getDefaultDoctors();
          } else {
            _doctorHospitals = doctorsList;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading doctors: $e';
          _isLoading = false;
          _doctorHospitals = _getDefaultDoctors();
        });
      }
      debugPrint('Error fetching doctors: $e');
    }
  }
  
  // Default doctors to use if Firestore data is unavailable
  List<Map<String, dynamic>> _getDefaultDoctors() {
    return [
      {
        'id': 'default1',
        'hospitalId': 'hospital1',
        'hospitalName': 'Aga Khan Hospital',
        'name': 'Dr. Sarah Ahmed',
        'specialty': 'Cardiologist',
        'rating': '4.9',
        'experience': '10 years',
        'fee': 'Rs 2000',
        'image': 'assets/images/doctor_1.jpg',
        'languages': ['English', 'Urdu'],
        'qualifications': ['MBBS', 'FCPS Cardiology'],
        'hospitals': [
          {
            'hospitalId': 'hospital1',
            'hospitalName': 'Aga Khan Hospital',
          }
        ],
      },
      {
        'id': 'default2',
        'hospitalId': 'hospital2',
        'hospitalName': 'Shifa International',
        'name': 'Dr. Ali Hassan',
        'specialty': 'Neurologist',
        'rating': '4.8',
        'experience': '12 years',
        'fee': 'Rs 2500',
        'image': 'assets/images/doctor_2.jpg',
        'languages': ['English', 'Urdu', 'Punjabi'],
        'qualifications': ['MBBS', 'FCPS Neurology'],
        'hospitals': [
          {
            'hospitalId': 'hospital2',
            'hospitalName': 'Shifa International',
          }
        ],
      },
      {
        'id': 'default3',
        'hospitalId': 'hospital3',
        'hospitalName': 'CMH Rawalpindi',
        'name': 'Dr. Fatima Khan',
        'specialty': 'Gynecologist',
        'rating': '4.7',
        'experience': '8 years',
        'fee': 'Rs 1800',
        'image': 'assets/images/doctor_3.jpg',
        'languages': ['English', 'Urdu'],
        'qualifications': ['MBBS', 'FCPS Gynecology'],
        'hospitals': [
          {
            'hospitalId': 'hospital3',
            'hospitalName': 'CMH Rawalpindi',
          }
        ],
      },
    ];
  }

  // Helper method to parse fee amount
  int _parseFeeAmount(String feeString) {
    try {
      // Remove 'Rs. ' prefix and any commas, then parse to double and convert to int
      return double.parse(feeString.replaceAll('Rs. ', '').replaceAll(',', '')).toInt();
    } catch (e) {
      print('Error parsing fee amount: $e');
      return 2000; // Default to 2000 if parsing fails
    }
  }
} 

