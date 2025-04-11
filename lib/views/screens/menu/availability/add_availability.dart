import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddAvailabilityScreen extends StatefulWidget {
  const AddAvailabilityScreen({super.key});

  @override
  State<AddAvailabilityScreen> createState() => _AddAvailabilityScreenState();
}

class _AddAvailabilityScreenState extends State<AddAvailabilityScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  bool _isLoading = false;
  late AnimationController _animationController;

  final List<String> _timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
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
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Date",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Choose the day you want to add availability for appointments",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildCalendar(),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    SlideTransition(
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
                              "Select Time Slot",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Choose available time slots for the selected day",
          style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildTimeSlots(),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    SlideTransition(
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
                        child: _buildSubmitButton(),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(64, 124, 226, 1),
            Color.fromRGBO(84, 144, 246, 1),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(64, 124, 226, 0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: SafeArea(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
            children: [
                IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                Text(
                  "Add Availability",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar(
        focusedDay: _selectedDay,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
        calendarFormat: CalendarFormat.month,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
                color: Color.fromRGBO(64, 124, 226, 0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color.fromRGBO(64, 124, 226, 1),
            shape: BoxShape.circle,
          ),
              weekendTextStyle: GoogleFonts.poppins(color: Colors.red.shade300),
              defaultTextStyle: GoogleFonts.poppins(),
              outsideTextStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
              markersMaxCount: 3,
              canMarkersOverflow: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
              leftChevronIcon: Icon(
                LucideIcons.chevronLeft,
                color: Color.fromRGBO(64, 124, 226, 1),
                size: 20,
              ),
              rightChevronIcon: Icon(
                LucideIcons.chevronRight,
                color: Color.fromRGBO(64, 124, 226, 1),
                size: 20,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              weekendStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.red.shade300,
          ),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
          });
        },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(64, 124, 226, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.calendar,
                  color: Color.fromRGBO(64, 124, 226, 1),
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Selected date: ",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
      spacing: 12,
      runSpacing: 12,
            children: _timeSlots.map((time) {
            bool isSelected = time == _selectedTime;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(
                    color: isSelected
                          ? Color.fromRGBO(64, 124, 226, 1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Color.fromRGBO(64, 124, 226, 1)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color.fromRGBO(64, 124, 226, 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [],
                ),
                child: Text(
                  time,
                  style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Color(0xFF666666),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
          ),
          if (_selectedTime != null) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(64, 124, 226, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.clock,
                    color: Color.fromRGBO(64, 124, 226, 1),
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Selected time: ",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _selectedTime!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool isEnabled = _selectedTime != null;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? _addAvailability : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? Color.fromRGBO(64, 124, 226, 1)
              : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: isEnabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendarPlus, size: 20),
                  SizedBox(width: 10),
                  Text(
          "Add New Availability",
          style: GoogleFonts.poppins(
            fontSize: 16,
                      fontWeight: FontWeight.w600,
          ),
                  ),
                ],
        ),
      ),
    );
  }
  
  Future<void> _addAvailability() async {
    if (_selectedTime == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1000));
      
      // This is where Firebase Firestore integration would happen
      // Example Firebase code (commented out):
      /*
      // Format the date to string
      final String dateStr = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
      
      await FirebaseFirestore.instance.collection('availability').add({
        'doctorId': FirebaseAuth.instance.currentUser!.uid,
        'date': dateStr,
        'time': _selectedTime,
        'timestamp': Timestamp.fromDate(_selectedDay),
        'isBooked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      */
      
      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Availability added successfully for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year} at $_selectedTime',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      
      // Reset the selected time
      setState(() {
        _selectedTime = null;
      });
      
    } catch (e) {
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add availability: ${e.toString()}',
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

