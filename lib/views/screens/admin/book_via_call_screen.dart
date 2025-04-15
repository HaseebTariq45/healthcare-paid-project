import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class BookViaCallScreen extends StatefulWidget {
  const BookViaCallScreen({Key? key}) : super(key: key);

  @override
  State<BookViaCallScreen> createState() => _BookViaCallScreenState();
}

class _BookViaCallScreenState extends State<BookViaCallScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _cnicController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isBooking = false;
  bool _isLoadingHospitals = false;
  bool _isLoadingTimeSlots = false;
  
  // Patient data
  Map<String, dynamic>? _patientData;
  String? _errorMessage;
  
  // Doctors data
  List<Map<String, dynamic>> _availableDoctors = [];
  Map<String, dynamic>? _selectedDoctor;
  
  // Hospital data
  List<Map<String, dynamic>> _doctorHospitals = [];
  Map<String, dynamic>? _selectedHospitalData;
  
  // Appointment data
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  List<String> _availableTimeSlots = [];
  String? _selectedTimeSlot;
  final TextEditingController _reasonController = TextEditingController();
  
  @override
  void dispose() {
    _cnicController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
  
  // Search for patient by CNIC
  Future<void> _searchPatient() async {
    final cnic = _cnicController.text.trim();
    
    if (cnic.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a CNIC number';
      });
      return;
    }
    
    // Format validation for CNIC
    RegExp cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(cnic)) {
      setState(() {
        _errorMessage = 'CNIC should follow the pattern xxxxx-xxxxxxx-x';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _patientData = null;
    });
    
    try {
      // Query Firestore for the patient with the given CNIC
      final QuerySnapshot snapshot = await _firestore
          .collection('patients')
          .where('cnic', isEqualTo: cnic)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No patient found with this CNIC';
          _isSearching = false;
        });
        return;
      }
      
      // Get patient data from the first snapshot
      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      setState(() {
        _patientData = {
          'id': data['id'] ?? doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'email': data['email'] ?? 'N/A',
          'phone': data['phoneNumber'] ?? 'N/A',
          'gender': data['gender'] ?? 'Not specified',
          'age': data['age'] ?? 'N/A',
          'profileImageUrl': data['profileImageUrl'],
        };
        _isSearching = false;
      });
      
      // After finding the patient, load available doctors
      _loadDoctors();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching for patient: ${e.toString()}';
        _isSearching = false;
      });
    }
  }
  
  // Calculate age from date of birth
  String _calculateAge(dynamic dob) {
    if (dob is Timestamp) {
      final DateTime birthDate = dob.toDate();
      final DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    }
    return 'N/A';
  }
  
  // Load available doctors
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _availableDoctors = [];
      _selectedDoctor = null;
      _doctorHospitals = [];
      _selectedHospitalData = null;
      _availableTimeSlots = [];
      _selectedTimeSlot = null;
    });
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('doctors')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Process doctors data
      List<Map<String, dynamic>> doctors = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        doctors.add({
          'id': data['id'] ?? doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'specialty': data['specialty'] ?? 'General',
          'fee': data['fee'] ?? 0,
          'profileImageUrl': data['profileImageUrl'],
        });
      }
      
      setState(() {
        _availableDoctors = doctors;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading doctors: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  // Load hospitals for a specific doctor
  Future<void> _loadDoctorHospitals(String doctorId) async {
    setState(() {
      _isLoadingHospitals = true;
      _doctorHospitals = [];
      _selectedHospitalData = null;
      _availableTimeSlots = [];
      _selectedTimeSlot = null;
    });
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      // Process hospital data
      List<Map<String, dynamic>> hospitals = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        hospitals.add({
          'hospitalId': data['hospitalId'],
          'hospitalName': data['hospitalName'],
          'city': data['city'],
        });
      }
      
      setState(() {
        _doctorHospitals = hospitals;
        _isLoadingHospitals = false;
        
        if (hospitals.isNotEmpty) {
          _selectedHospitalData = hospitals.first;
          // Load time slots for the first hospital
          _loadAvailableTimeSlots(doctorId, _selectedHospitalData!['hospitalId'], _selectedDate);
        }
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading hospitals: ${e.toString()}';
        _isLoadingHospitals = false;
      });
    }
  }
  
  // Load available time slots for a specific doctor, hospital, and date
  Future<void> _loadAvailableTimeSlots(String doctorId, String hospitalId, DateTime date) async {
    setState(() {
      _isLoadingTimeSlots = true;
      _availableTimeSlots = [];
      _selectedTimeSlot = null;
    });
    
    try {
      // Format date to YYYY-MM-DD
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final QuerySnapshot snapshot = await _firestore
          .collection('doctor_availability')
          .where('doctorId', isEqualTo: doctorId)
          .where('hospitalId', isEqualTo: hospitalId)
          .where('date', isEqualTo: formattedDate)
          .limit(1)
          .get();
      
      List<String> timeSlots = [];
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        
        if (data['timeSlots'] != null && data['timeSlots'] is List) {
          timeSlots = List<String>.from(data['timeSlots']);
        }
      }
      
      setState(() {
        _availableTimeSlots = timeSlots;
        _isLoadingTimeSlots = false;
        
        if (timeSlots.isNotEmpty) {
          _selectedTimeSlot = timeSlots.first;
        }
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading time slots: ${e.toString()}';
        _isLoadingTimeSlots = false;
      });
    }
  }
  
  // Create appointment
  Future<void> _createAppointment() async {
    // Validate input
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    
    if (_selectedHospitalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a hospital')),
      );
      return;
    }
    
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an available time slot')),
      );
      return;
    }
    
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a reason for appointment')),
      );
      return;
    }
    
    setState(() {
      _isBooking = true;
    });
    
    try {
      // Generate a unique ID for the appointment
      final String appointmentId = Uuid().v4();
      
      // Parse the time slot
      final TimeOfDay timeOfDay = _parseTimeSlot(_selectedTimeSlot!);
      
      // Format date and time
      final DateTime appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      
      final String formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);
      
      // Create appointment data
      final Map<String, dynamic> appointmentData = {
        'id': appointmentId,
        'doctorId': _selectedDoctor!['id'],
        'patientId': _patientData!['id'],
        'status': 'Confirmed', // Set as confirmed since admin is booking
        'date': formattedDate,
        'time': _selectedTimeSlot,
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'created': Timestamp.now(),
        'reason': _reasonController.text.trim(),
        'fee': _selectedDoctor!['fee'],
        'hospital': _selectedHospitalData!['hospitalName'],
        'hospitalId': _selectedHospitalData!['hospitalId'],
        'hospitalName': _selectedHospitalData!['hospitalName'],
        'hospitalLocation': _selectedHospitalData!['city'] ?? '',
        'specialty': _selectedDoctor!['specialty'],
        'type': 'In-person',
        'bookedBy': 'admin',
        'paymentStatus': 'Pending', // Set payment status as pending
        'notes': 'Booked via customer service call',
      };
      
      // Save to Firestore
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .set(appointmentData);
      
      // Reset the form
      setState(() {
        _isBooking = false;
        _patientData = null;
        _selectedDoctor = null;
        _doctorHospitals = [];
        _selectedHospitalData = null;
        _availableTimeSlots = [];
        _selectedTimeSlot = null;
        _cnicController.clear();
        _reasonController.clear();
        _selectedDate = DateTime.now().add(Duration(days: 1));
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      setState(() {
        _isBooking = false;
        _errorMessage = 'Error booking appointment: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Parse time slot string (e.g., "08:00 PM") to TimeOfDay
  TimeOfDay _parseTimeSlot(String timeSlot) {
    final time = DateFormat('hh:mm a').parse(timeSlot);
    return TimeOfDay(hour: time.hour, minute: time.minute);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book via Call',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3366CC), Color(0xFF5588EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3366CC).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_in_talk, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Book via Phone Call',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Enter the patient\'s CNIC to start booking an appointment for them. Select a doctor, hospital, and available time slot for the consultation.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Patient Search Form
              Text(
                'Search Patient by CNIC',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cnicController,
                            decoration: InputDecoration(
                              hintText: 'Format: xxxxx-xxxxxxx-x',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.badge, color: Color(0xFF3366CC)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Color(0xFF3366CC), width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                              _CNICInputFormatter(),
                            ],
                            style: GoogleFonts.poppins(
                              color: Color(0xFF333333),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSearching ? null : _searchPatient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3366CC),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                            shadowColor: Color(0xFF3366CC).withOpacity(0.5),
                          ),
                          child: _isSearching
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Search',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    
                    if (_errorMessage != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Patient Details
              if (_patientData != null) ...[
                SizedBox(height: 36),
                Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF3366CC)),
                    SizedBox(width: 8),
                    Text(
                      'Patient Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFF3366CC), width: 2),
                              color: Colors.white,
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: _patientData!['profileImageUrl'] != null
                                  ? NetworkImage(_patientData!['profileImageUrl'])
                                  : null,
                              child: _patientData!['profileImageUrl'] == null
                                  ? Text(
                                      _patientData!['name'].toString().substring(0, 1),
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3366CC),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),
                      // Patient info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _patientData!['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              _patientData!['email'],
                              Colors.blue.shade700,
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.phone,
                              'Phone',
                              _patientData!['phone'],
                              Colors.green.shade700,
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.person,
                              'Gender',
                              _patientData!['gender'],
                              Colors.purple.shade700,
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.cake,
                              'Age',
                              _patientData!['age'],
                              Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Appointment Booking Form
                SizedBox(height: 36),
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: Color(0xFF3366CC)),
                    SizedBox(width: 8),
                    Text(
                      'Appointment Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Selection
                      Text(
                        'Select Doctor',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF444444),
                        ),
                      ),
                      SizedBox(height: 10),
                      
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3366CC),
                          ),
                        )
                      else if (_availableDoctors.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'No doctors available',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              isExpanded: true,
                              hint: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Select a doctor',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              value: _selectedDoctor,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              borderRadius: BorderRadius.circular(10),
                              icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF3366CC)),
                              items: _availableDoctors.map((doctor) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: doctor,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blue.shade100,
                                        backgroundImage: doctor['profileImageUrl'] != null
                                            ? NetworkImage(doctor['profileImageUrl'])
                                            : null,
                                        child: doctor['profileImageUrl'] == null
                                            ? Text(
                                                doctor['name'].toString().substring(0, 1),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3366CC),
                                                ),
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              doctor['name'],
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              '${doctor['specialty']} - Rs. ${doctor['fee']}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDoctor = value;
                                  });
                                  // Load hospitals for this doctor
                                  _loadDoctorHospitals(value['id']);
                                }
                              },
                            ),
                          ),
                        ),
                      
                      SizedBox(height: 20),
                      
                      // Hospital Selection
                      if (_selectedDoctor != null) ...[
                        Text(
                          'Select Hospital',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        if (_isLoadingHospitals)
                          Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3366CC),
                            ),
                          )
                        else if (_doctorHospitals.isEmpty)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No hospitals available for this doctor',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                isExpanded: true,
                                value: _selectedHospitalData,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                borderRadius: BorderRadius.circular(10),
                                icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF3366CC)),
                                items: _doctorHospitals.map((hospital) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: hospital,
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_hospital, color: Color(0xFF3366CC)),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            hospital['hospitalName'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedHospitalData = value;
                                    });
                                    // Load time slots for this hospital and date
                                    _loadAvailableTimeSlots(_selectedDoctor!['id'], value['hospitalId'], _selectedDate);
                                  }
                                },
                              ),
                            ),
                          ),
                        
                        SizedBox(height: 20),
                      ],
                      
                      // Date Selection
                      if (_selectedHospitalData != null) ...[
                        Text(
                          'Select Date',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                        SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 90)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Color(0xFF3366CC),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            
                            if (picked != null && picked != _selectedDate) {
                              setState(() {
                                _selectedDate = picked;
                              });
                              // Load time slots for this new date
                              _loadAvailableTimeSlots(_selectedDoctor!['id'], _selectedHospitalData!['hospitalId'], picked);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Color(0xFF3366CC), size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.keyboard_arrow_down, color: Color(0xFF3366CC)),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                      ],
                      
                      // Time Slot Selection
                      if (_selectedHospitalData != null) ...[
                        Text(
                          'Select Time Slot',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        if (_isLoadingTimeSlots)
                          Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3366CC),
                            ),
                          )
                        else if (_availableTimeSlots.isEmpty)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.orange.shade800),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No time slots available for this date. Please select another date.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableTimeSlots.length,
                              itemBuilder: (context, index) {
                                final timeSlot = _availableTimeSlots[index];
                                final isSelected = timeSlot == _selectedTimeSlot;
                                
                                return Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedTimeSlot = timeSlot;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? Color(0xFF3366CC) : Colors.grey.shade50,
                                        border: Border.all(
                                          color: isSelected ? Color(0xFF3366CC) : Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Center(
                                        child: Text(
                                          timeSlot,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                            color: isSelected ? Colors.white : Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        SizedBox(height: 20),
                      ],
                      
                      // Reason for Appointment
                      if (_selectedHospitalData != null) ...[
                        Text(
                          'Reason for Appointment',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _reasonController,
                            decoration: InputDecoration(
                              hintText: 'Enter reason for appointment',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.edit, color: Color(0xFF3366CC)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF333333),
                            ),
                            maxLines: 3,
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Book Appointment Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isBooking ? null : _createAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3366CC),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                              shadowColor: Color(0xFF3366CC).withOpacity(0.5),
                              disabledBackgroundColor: Color(0xFF3366CC).withOpacity(0.6),
                            ),
                            child: _isBooking
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Booking...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle),
                                      SizedBox(width: 12),
                                      Text(
                                        'Book Appointment',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom input formatter for CNIC
class _CNICInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove any existing hyphens
    String text = newValue.text.replaceAll('-', '');
    
    // Build formatted text
    final StringBuffer newText = StringBuffer();
    
    // Add first group (5 digits)
    if (text.length >= 5) {
      newText.write(text.substring(0, 5) + '-');
    } else {
      newText.write(text);
      return TextEditingValue(
        text: newText.toString(),
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    
    // Add second group (7 digits)
    if (text.length >= 12) {
      newText.write(text.substring(5, 12) + '-');
    } else if (text.length > 5) {
      newText.write(text.substring(5));
      return TextEditingValue(
        text: newText.toString(),
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    
    // Add third group (1 digit)
    if (text.length >= 13) {
      newText.write(text.substring(12, 13));
    } else if (text.length > 12) {
      newText.write(text.substring(12));
    }
    
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
} 