import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> patients = const [
    {
      "name": "Ali",
      "age": "29 Years",
      "location": "Bhalwal",
      "image": "assets/images/patient_1.png",
      "lastVisit": "2 days ago",
      "condition": "Hypertension",
      "appointment": {
        "date": "15 Oct 2023",
        "time": "09:00 AM",
        "hospital": "Aga Khan Hospital, Karachi",
        "reason": "Follow-up Visit",
        "status": "Completed"
      }
    },
    {
      "name": "Fehmida",
      "age": "30 Years",
      "location": "Rahim Yar Khan",
      "image": "assets/images/patient_2.png",
      "lastVisit": "1 week ago",
      "condition": "Diabetes",
      "appointment": {
        "date": "20 Oct 2023",
        "time": "11:00 AM",
        "hospital": "Shaukat Khanum Hospital, Lahore",
        "reason": "Regular Checkup",
        "status": "Upcoming"
      }
    },
    {
      "name": "Asma",
      "age": "24 Years",
      "location": "Lahore",
      "image": "assets/images/patient_3.png",
      "lastVisit": "Yesterday",
      "condition": "Pregnancy",
      "appointment": {
        "date": "14 Oct 2023",
        "time": "02:00 PM",
        "hospital": "Jinnah Hospital, Karachi",
        "reason": "Prescription Refill",
        "status": "Completed"
      }
    },
    {
      "name": "Sher Bano",
      "age": "33 Years",
      "location": "Risalpur",
      "image": "assets/images/patient_4.png",
      "lastVisit": "3 days ago",
      "condition": "Asthma",
      "appointment": {
        "date": "22 Oct 2023",
        "time": "10:00 AM",
        "hospital": "Liaquat National Hospital, Karachi",
        "reason": "New Symptoms",
        "status": "Upcoming"
      }
    },
    {
      "name": "Naheed",
      "age": "30 Years",
      "location": "Soon Valley, Sakesar",
      "image": "assets/images/patient_5.png",
      "lastVisit": "2 weeks ago",
      "condition": "Arthritis",
      "appointment": {
        "date": "25 Oct 2023",
        "time": "04:00 PM",
        "hospital": "Aga Khan Hospital, Karachi",
        "reason": "Test Results Review",
        "status": "Upcoming"
      }
    },
  ];

  List<String> selectedFilters = [];
  int _selectedSortIndex = 0;
  final List<String> _sortOptions = ["All", "Upcoming", "Completed"];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredPatients {
    List<Map<String, dynamic>> result = patients.where((patient) {
      final matchesSearch = patient["name"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          patient["location"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          patient["appointment"]["hospital"].toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (selectedFilters.isEmpty) {
        return matchesSearch;
      }
      
      bool matchesFilters = true;
      
      // Filter by location
      if (selectedFilters.contains("Karachi")) {
        matchesFilters = matchesFilters && 
                         patient["appointment"]["hospital"].toString().contains("Karachi");
      }
      
      // Filter by appointment status
      if (selectedFilters.contains("Upcoming")) {
        matchesFilters = matchesFilters && 
                         patient["appointment"]["status"] == "Upcoming";
      }
      
      if (selectedFilters.contains("Completed")) {
        matchesFilters = matchesFilters && 
                         patient["appointment"]["status"] == "Completed";
      }
                              
      return matchesSearch && matchesFilters;
    }).toList();
    
    // Sort based on selected option
    if (_selectedSortIndex == 1) { // Upcoming Appointments
      result = result.where((p) => p["appointment"]["status"] == "Upcoming").toList();
    } else if (_selectedSortIndex == 2) { // Completed Appointments
      result = result.where((p) => p["appointment"]["status"] == "Completed").toList();
    }
    
    return result;
  }

  void toggleFilter(String filter) {
    setState(() {
      if (selectedFilters.contains(filter)) {
        selectedFilters.remove(filter);
      } else {
        selectedFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: 220,
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
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom app bar with gradient background
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Text(
                        "Patient Appointments",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.bell,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "156",
                          "Total Patients",
                          Icons.group_outlined,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          "28",
                          "Upcoming Appointments",
                          Icons.calendar_month_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Search and filters section
                Expanded(
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
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          children: [
            _buildSearchBar(),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    "Filter by: ",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ],
                              ),
                              SizedBox(height: 8),
                              _buildSortOptions(),
                              SizedBox(height: 10),
            _buildFilters(),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: filteredPatients.isEmpty
                                ? _buildNoResultsFound()
                                : _buildPatientsList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new patient functionality
        },
        backgroundColor: Color.fromRGBO(64, 124, 226, 1),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Color.fromRGBO(64, 124, 226, 1),
              size: 22,
            ),
          ),
          SizedBox(width: 12),
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      height: 44,
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        children: List.generate(
          _sortOptions.length,
          (index) {
            bool isSelected = _selectedSortIndex == index;
            bool isFirst = index == 0;
            bool isLast = index == _sortOptions.length - 1;
            
            return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSortIndex = index;
                });
              },
              child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: isSelected
                      ? Color.fromRGBO(64, 124, 226, 1)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Color.fromRGBO(64, 124, 226, 0.3),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      )
                    ] : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _sortOptions[index],
                  style: GoogleFonts.poppins(
                        color: isSelected
                        ? Colors.white
                        : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/empty.png",
            height: 120,
            width: 120,
            // If this asset doesn't exist, replace with:
            // Icon(
            //   Icons.search_off_rounded,
            //   size: 80,
            //   color: Colors.grey.shade300,
            // ),
          ),
          const SizedBox(height: 16),
          Text(
            "No patients found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                selectedFilters.clear();
              });
            },
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text("Reset Filters"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(64, 124, 226, 1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        final delay = index * 0.1;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Interval(0.3 + delay, 0.8 + delay > 0.95 ? 0.95 : 0.8 + delay, curve: Curves.easeOut),
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: Interval(0.3 + delay, 0.8 + delay > 0.95 ? 0.95 : 0.8 + delay, curve: Curves.easeOut),
            )),
            child: _buildPatientCard(
              patient["name"]!,
              patient["age"]!,
              patient["location"]!,
              patient["image"]!,
              patient["lastVisit"]!,
              patient["condition"]!,
              patient["appointment"],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search patients by name or location",
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
          _buildFilterButton(
            Icons.filter_list_rounded,
            "Filters",
            false,
            () {},
          ),
          _buildFilterButton(
            Icons.location_on_rounded,
            "Karachi",
            selectedFilters.contains("Karachi"),
            () => toggleFilter("Karachi"),
          ),
          _buildFilterButton(
            Icons.check_circle_outline,
            "Upcoming",
            selectedFilters.contains("Upcoming"),
            () => toggleFilter("Upcoming"),
          ),
          _buildFilterButton(
            Icons.history_rounded,
            "Completed",
            selectedFilters.contains("Completed"),
            () => toggleFilter("Completed"),
          ),
          _buildFilterButton(
            Icons.calendar_today_rounded,
            "This Month",
            selectedFilters.contains("This Month"),
            () => toggleFilter("This Month"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color.fromRGBO(64, 124, 226, 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color.fromRGBO(64, 124, 226, 0.8) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color.fromRGBO(64, 124, 226, 0.15),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Color.fromRGBO(64, 124, 226, 1)
                  : (label == "Filters" ? Colors.grey.shade700 : Colors.grey.shade500),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? Color.fromRGBO(64, 124, 226, 1)
                    : (label == "Filters" ? Colors.grey.shade700 : Colors.grey.shade500),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    String name,
    String age,
    String location,
    String image,
    String lastVisit,
    String condition,
    Map<String, dynamic> appointment,
  ) {
    final bool isUpcoming = appointment["status"] == "Upcoming";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
      color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to patient details
          },
      child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
          children: [
                    Hero(
                      tag: "patient_$name",
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                Text(
                                lastVisit,
                  style: GoogleFonts.poppins(
                                  fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                Row(
                  children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color.fromRGBO(64, 124, 226, 1),
                              ),
                    const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                      location,
                      style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(64, 124, 226, 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color.fromRGBO(64, 124, 226, 1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Appointment status indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isUpcoming ? Color(0xFFE8F5FE) : Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUpcoming ? Color(0xFF2B8FEB) : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isUpcoming ? Color(0xFF2B8FEB).withOpacity(0.1) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUpcoming ? Icons.event : Icons.check_circle,
                          size: 16,
                          color: isUpcoming ? Color(0xFF2B8FEB) : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        isUpcoming ? "Upcoming Appointment" : "Completed Appointment",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isUpcoming ? Color(0xFF2B8FEB) : Colors.grey.shade700,
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Appointment details
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildAppointmentDetailRow(
                        Icons.calendar_today,
                        "Date:",
                        appointment["date"],
                      ),
                      SizedBox(height: 8),
                      _buildAppointmentDetailRow(
                        Icons.access_time,
                        "Time:",
                        appointment["time"],
                      ),
                      SizedBox(height: 8),
                      _buildAppointmentDetailRow(
                        Icons.business,
                        "Hospital:",
                        appointment["hospital"],
                      ),
                      SizedBox(height: 8),
                      _buildAppointmentDetailRow(
                        Icons.description,
                        "Reason:",
                        appointment["reason"],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_information_outlined,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Condition:",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        condition,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color.fromRGBO(64, 124, 226, 1),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Medical Info Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3366CC),
                        Color(0xFF5E8EF7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3366CC).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Navigate to medical profile
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailProfileScreen(
                              name: name,
                              age: age,
                              bloodGroup: "B+", // This would be dynamically set in a real app
                              phoneNumber: "+92 300 1234567", // This would be dynamically set in a real app
                              allergies: ["Pollen", "Dust"], // This would be dynamically set in a real app
                              diseases: [condition], // Using the condition as a disease for demonstration
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "View Complete Medical Profile",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Blood group, allergies, medical history",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
  
  Widget _buildAppointmentDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
