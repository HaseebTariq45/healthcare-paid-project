import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:healthcare/services/doctor_availability_service.dart';
import 'package:healthcare/utils/date_formatter.dart';
import 'package:healthcare/views/screens/doctor/hospitals/manage_hospitals_screen.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  DateTime _selectedDay = DateTime.now();
  String? _selectedHospital;
  String? _selectedHospitalId;
  Map<String, bool> _selectedTimeSlots = {};
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // For day of week selection
  final List<String> _daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  int _selectedDayIndex = DateTime.now().weekday - 1; // Default to current day of week
  
  // For hospitals and availability
  final DoctorAvailabilityService _availabilityService = DoctorAvailabilityService();
  List<Map<String, dynamic>> _hospitals = [];
  Map<String, Map<String, List<String>>> _doctorSchedule = {};

  final List<String> _timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "01:00 PM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "07:00 PM",
    "08:00 PM",
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
    
    // Delay loading to allow UI to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHospitals();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load hospitals where doctor works
  Future<void> _loadHospitals() async {
    if (!mounted) return;
    
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final hospitals = await _availabilityService.getDoctorHospitals();
      
      if (!mounted) return;
      
      if (hospitals.isNotEmpty) {
        // Set hospitals first to show some UI
        setState(() {
          _hospitals = hospitals;
          _selectedHospital = hospitals[0]['hospitalName'];
          _selectedHospitalId = hospitals[0]['hospitalId'];
          _isInitializing = false;
        });
        
        // Then load availability without blocking the UI
        _loadAvailability();
      } else {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      _showErrorMessage('Failed to load hospitals: ${e.toString()}');
      setState(() {
        _isInitializing = false;
      });
    }
  }
  
  // Load availability for selected hospital
  Future<void> _loadAvailability() async {
    if (_selectedHospitalId == null || !mounted) return;
    
    // Use a local loading indicator instead of global initializing state
    setState(() {
      _isLoading = true;
    });
    
    try {
      final availability = await _availabilityService.getDoctorAvailability(
        hospitalId: _selectedHospitalId!,
      );
      
      if (!mounted) return;
      
      setState(() {
        if (!_doctorSchedule.containsKey(_selectedHospital)) {
          _doctorSchedule[_selectedHospital!] = {};
        }
        
        // Update the schedule with fetched data
        availability.forEach((date, slots) {
          _doctorSchedule[_selectedHospital!]![date] = slots;
        });
        
        _isLoading = false;
      });
      
      // Now load time slots for selected date
      _loadTimeSlots();
    } catch (e) {
      if (!mounted) return;
      
      _showErrorMessage('Failed to load availability: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadTimeSlots() {
    if (_selectedHospital == null) return;
    
    // Reset time slots
    setState(() {
      _selectedTimeSlots = {};
    });
    
    // Convert selected day index to actual date for today's week
    DateTime now = DateTime.now();
    int todayWeekday = now.weekday; // 1-7 (Monday-Sunday)
    int daysToAdd = _selectedDayIndex - (todayWeekday - 1);
    if (daysToAdd < 0) daysToAdd += 7; // For past days, go to next week
    
    DateTime targetDate = now.add(Duration(days: daysToAdd));
    _selectedDay = targetDate; // Update selectedDay for saving later
    
    // Convert date to string format for lookup
    String dateStr = DateFormatter.toYYYYMMDD(targetDate);
    
    // Check if doctor has availability for this date at this hospital
    if (_doctorSchedule.containsKey(_selectedHospital) && 
        _doctorSchedule[_selectedHospital]!.containsKey(dateStr)) {
      // Pre-select existing time slots
      List<String> existingSlots = _doctorSchedule[_selectedHospital]![dateStr]!;
      
      setState(() {
        for (String slot in _timeSlots) {
          _selectedTimeSlots[slot] = existingSlots.contains(slot);
        }
      });
    } else {
      // No existing slots, initialize all to false
      setState(() {
        for (String slot in _timeSlots) {
          _selectedTimeSlots[slot] = false;
        }
      });
    }
  }

  // Navigate to manage hospitals screen
  void _navigateToManageHospitals() async {
    // Show loading indicator before navigation
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ManageHospitalsScreen()),
      );
      
      if (!mounted) return;
      
      // Reload hospitals when returning from manage hospitals screen
      _loadHospitals();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to navigate: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHospitals,
          child: _isInitializing 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF2B8FEB),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Loading your hospitals...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: _hospitals.isEmpty
                              ? _buildNoHospitalsView()
                              : SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Introduction
                                        _buildIntroSection(),
                                        
                                        SizedBox(height: 24),
                                        
                                        // Hospital Selection
                                        _buildHospitalSelection(),
                                        
                                        SizedBox(height: 24),
                                        
                                        // Calendar
                                        _buildCalendarSection(),
                                        
                                        SizedBox(height: 24),
                                        
                                        // Time Slots
                                        _buildTimeSlotsSection(),
                                        
                                        SizedBox(height: 30),
                                        
                                        // Save Button
                                        _buildSaveButton(),
                                        
                                        SizedBox(height: 30),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    // Overlay loading indicator when performing actions but not initializing
                    if (_isLoading && !_isInitializing)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2B8FEB),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNoHospitalsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFE6F2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business,
                color: Color(0xFF3366CC),
                size: 60,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "No Hospitals Found",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You don't have any hospitals assigned to your profile. Please add a hospital to manage your availability.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _navigateToManageHospitals,
              icon: Icon(Icons.add),
              label: Text("Add Hospitals"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3366CC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          SizedBox(width: 15),
          Text(
            "Manage Availability",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(64, 124, 226, 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_month,
              color: Color.fromRGBO(64, 124, 226, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(64, 124, 226, 0.1),
                Color.fromRGBO(84, 144, 246, 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.fromRGBO(64, 124, 226, 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set Your Availability",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Select the hospital, dates, and time slots when you'll be available for patient appointments.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalSelection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1, 0.7, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.1, 0.7, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Hospital",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                TextButton.icon(
                  onPressed: _navigateToManageHospitals,
                  icon: Icon(Icons.edit, size: 18),
                  label: Text("Manage"),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF2B8FEB),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Color(0xFFEDF7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Choose the hospital where you'll be practicing",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
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
              child: ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _hospitals.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 65,
                  endIndent: 20,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final hospital = _hospitals[index];
                  final hospitalName = hospital['hospitalName'] as String;
                  final isSelected = hospitalName == _selectedHospital;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedHospital = hospitalName;
                        _selectedHospitalId = hospital['hospitalId'];
                        _loadAvailability();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFFEDF7FF) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                              Icons.business,
                              color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              hospitalName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
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
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.2, 0.8, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Day of Week",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Choose the day when you'll be regularly available",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 16),
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
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2B8FEB).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.calendar,
                            color: Color(0xFF2B8FEB),
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Days of Week",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(_daysOfWeek.length, (index) {
                        final isSelected = index == _selectedDayIndex;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDayIndex = index;
                              _loadTimeSlots();
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 10),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFF2B8FEB) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade300,
                                width: 1,
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
                              _daysOfWeek[index],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(64, 124, 226, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.info,
                    color: Color.fromRGBO(64, 124, 226, 1),
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "This availability will be set for all ${_daysOfWeek[_selectedDayIndex]}s in the next 12 weeks",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.9, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3, 0.9, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Time Slots",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Choose the times when you'll be available at $_selectedHospital",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 16),
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
                    "Morning",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots
                        .where((slot) => slot.contains("AM"))
                        .map((time) => _buildTimeSlotChip(time))
                        .toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Afternoon & Evening",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots
                        .where((slot) => slot.contains("PM"))
                        .map((time) => _buildTimeSlotChip(time))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotChip(String time) {
    bool isSelected = _selectedTimeSlots.containsKey(time) && _selectedTimeSlots[time]!;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedTimeSlots.containsKey(time)) {
            _selectedTimeSlots[time] = !_selectedTimeSlots[time]!;
          } else {
            _selectedTimeSlots[time] = true;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2B8FEB) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade300,
            width: 1,
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
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAvailability,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2B8FEB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Color(0xFF2B8FEB).withOpacity(0.4),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Save Availability",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Save the doctor's availability
  Future<void> _saveAvailability() async {
    if (_selectedHospitalId == null || _selectedHospital == null) {
      _showErrorMessage("Please select a hospital");
      return;
    }
    
    // Get selected time slots
    List<String> selectedTimes = [];
    _selectedTimeSlots.forEach((time, isSelected) {
      if (isSelected) selectedTimes.add(time);
    });
    
    if (selectedTimes.isEmpty) {
      _showErrorMessage("Please select at least one time slot");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Calculate all dates for the selected day of week in the next 12 weeks
      List<Map<String, dynamic>> datesToSave = [];
      DateTime now = DateTime.now();
      
      // Find the next occurrence of the selected day of week
      int daysDifference = (_selectedDayIndex + 1) - now.weekday;
      if (daysDifference <= 0) daysDifference += 7; // Go to next week if it's in the past
      
      DateTime nextOccurrence = now.add(Duration(days: daysDifference));
      
      // Add 12 occurrences (12 weeks) of the selected day
      for (int i = 0; i < 12; i++) {
        DateTime dateToAdd = nextOccurrence.add(Duration(days: 7 * i));
        datesToSave.add({
          'date': dateToAdd,
          'dateStr': DateFormatter.toYYYYMMDD(dateToAdd),
        });
      }

      // Save availability for all calculated dates
      bool allSuccess = true;
      String errorMessage = '';
      
      for (var dateInfo in datesToSave) {
        final result = await _availabilityService.saveDoctorAvailability(
          hospitalId: _selectedHospitalId!,
          hospitalName: _selectedHospital!,
          date: dateInfo['date'],
          timeSlots: selectedTimes,
        );
        
        if (!result['success']) {
          allSuccess = false;
          errorMessage = result['message'];
          break;
        }
        
        // Update local cache for each date
        if (!_doctorSchedule.containsKey(_selectedHospital)) {
          _doctorSchedule[_selectedHospital!] = {};
        }
        _doctorSchedule[_selectedHospital!]![dateInfo['dateStr']] = selectedTimes;
      }
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (allSuccess) {
        // Show success dialog
        bool? shouldReturn = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Availability Updated',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your availability has been set for all ${_daysOfWeek[_selectedDayIndex]}s in the next 12 weeks.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2B8FEB),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.all(24),
            );
          },
        );
        
        // Navigate back if dialog was confirmed
        if (shouldReturn == true && mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorMessage(errorMessage.isEmpty 
            ? "Failed to save availability. Please try again." 
            : errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage("Failed to save availability. Please try again.");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }
} 