import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RemoveAvailability extends StatefulWidget {
  const RemoveAvailability({super.key});

  @override
  _RemoveAvailabilityState createState() => _RemoveAvailabilityState();
}

class _RemoveAvailabilityState extends State<RemoveAvailability> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  bool _isLoading = false;
  late AnimationController _animationController;

  // Mock data for existing availability slots
  final Map<DateTime, List<String>> _availabilityMap = {
    DateTime(2023, 10, 15): ["09:00 AM", "10:00 AM", "02:00 PM"],
    DateTime(2023, 10, 16): ["11:00 AM", "01:00 PM"],
    DateTime(2023, 10, 18): ["09:00 AM", "04:00 PM", "07:00 PM"],
    DateTime(2023, 10, 20): ["02:00 PM", "03:00 PM"],
  };

  List<String> _getAvailableTimeSlots() {
    // In a real app, this would fetch from Firestore based on the selected date
    for (var date in _availabilityMap.keys) {
      if (isSameDay(date, _selectedDay)) {
        return _availabilityMap[date] ?? [];
      }
    }
    return [];
  }
  
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
    final List<String> availableTimeSlots = _getAvailableTimeSlots();
    
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
                              "Choose a day to update or remove availability",
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
                        child: availableTimeSlots.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Available Time Slots",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Select a time slot to remove or update",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildTimeSlots(availableTimeSlots),
                                ],
                              )
                            : _buildNoSlotsAvailable(),
                      ),
                    ),
                    
                    if (availableTimeSlots.isNotEmpty) ...[
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
                    ],
                    
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
                  "Update Availability",
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
    // Create a list of days that have availability
    final List<DateTime> eventDays = _availabilityMap.keys.toList();
    
    // For TableCalendar, we need a map of DateTime -> List<dynamic>
    final Map<DateTime, List<dynamic>> eventsMap = {
      for (var day in eventDays) day: ['available']
    };
    
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
            firstDay: DateTime.now().subtract(Duration(days: 365)),
            lastDay: DateTime.now().add(Duration(days: 365)),
        calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              for (var eventDay in eventDays) {
                if (isSameDay(day, eventDay)) {
                  return ['available'];
                }
              }
              return [];
            },
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
              markerDecoration: BoxDecoration(
                color: Color.fromRGBO(64, 124, 226, 1),
                shape: BoxShape.circle,
              ),
              markerSize: 5,
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
                _selectedTime = null;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected date: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    _getAvailableTimeSlots().isNotEmpty 
                        ? "${_getAvailableTimeSlots().length} time slots available"
                        : "No availability set for this day",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(List<String> timeSlots) {
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
            children: timeSlots.map((time) {
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
                        ? Colors.red.shade50
                        : Colors.white,
              borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.red.shade700 : Color(0xFF666666),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 6),
                        Icon(
                          LucideIcons.trash2,
                          color: Colors.red.shade700,
                          size: 16,
                        ),
                      ],
                    ],
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.clock,
                    color: Colors.red.shade400,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Selected to remove: ",
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
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
            child: Text(
                      "This will remove the selected time slot. Patients won't be able to book this slot anymore.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
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

  Widget _buildNoSlotsAvailable() {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendarX,
            size: 48,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            "No availability set for this day",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Please select a different day or add new availability slots",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(LucideIcons.calendarPlus),
            label: Text("Add New Availability"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color.fromRGBO(64, 124, 226, 1),
              side: BorderSide(color: Color.fromRGBO(64, 124, 226, 1)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
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
        onPressed: isEnabled ? _removeAvailability : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? Colors.red.shade600
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
                  Icon(LucideIcons.trash2, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Remove Selected Time Slot",
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
  
  Future<void> _removeAvailability() async {
    if (_selectedTime == null) return;
    
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Remove Availability",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        content: Text(
          "Are you sure you want to remove your availability for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year} at $_selectedTime?",
          style: GoogleFonts.poppins(
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        elevation: 5,
      ),
    );
    
    if (confirm != true) return;
    
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
      
      // Query for the specific availability document
      final querySnapshot = await FirebaseFirestore.instance
          .collection('availability')
          .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: _selectedTime)
          .get();
          
      // Delete the document if found
      if (querySnapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('availability')
            .doc(querySnapshot.docs.first.id)
            .delete();
      }
      */
      
      // Update the local state for demo purposes
      for (var date in _availabilityMap.keys) {
        if (isSameDay(date, _selectedDay)) {
          _availabilityMap[date]!.remove(_selectedTime);
          if (_availabilityMap[date]!.isEmpty) {
            _availabilityMap.remove(date);
          }
          break;
        }
      }
      
      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Availability removed successfully for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year} at $_selectedTime',
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
            'Failed to remove availability: ${e.toString()}',
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
