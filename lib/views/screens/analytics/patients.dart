import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/utils/navigation_helper.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Patient data state
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;

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
    
    // Fetch data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPatientData();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Fetch patient data from Firestore
  Future<void> _fetchPatientData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get the current user ID (should be a doctor)
      final String? doctorId = _auth.currentUser?.uid;
      
      if (doctorId == null) {
        throw Exception('User not authenticated');
      }
      
      // Debug: Print doctor ID
      debugPrint('Fetching patients for doctor: $doctorId');
      
      // Get all appointments for this doctor
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          // Use createdAt instead of appointmentDate for ordering (matches what appointment_booking_flow.dart uses)
          .orderBy('createdAt', descending: true)
          .get();
      
      debugPrint('Found ${appointmentsSnapshot.docs.length} appointments');
          
      if (appointmentsSnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _patients = [];
          _isLoading = false;
        });
        return;
      }
      
      // Create a list to store processed patient data
      List<Map<String, dynamic>> patientsData = [];
      
      // Process each appointment
      for (var appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        debugPrint('Processing appointment: ${appointmentDoc.id}');
        
        final patientId = appointmentData['patientId'] as String?;
        
        if (patientId != null) {
          // Get patient data
          final patientSnapshot = await _firestore
              .collection('users')
              .doc(patientId)
              .get();
              
          if (patientSnapshot.exists) {
            final patientData = patientSnapshot.data()!;
            
            // Get hospital data
            String hospitalName = appointmentData['hospitalName'] ?? 'Unknown Hospital';
            String hospitalLocation = 'Unknown Location';
            
            if (appointmentData.containsKey('hospitalId')) {
              final hospitalSnapshot = await _firestore
                  .collection('hospitals')
                  .doc(appointmentData['hospitalId'])
                  .get();
                  
              if (hospitalSnapshot.exists) {
                final hospitalData = hospitalSnapshot.data()!;
                hospitalName = hospitalData['name'] ?? hospitalName;
                hospitalLocation = hospitalData['city'] ?? hospitalLocation;
              }
            }
            
            // Format date from appointment
            String formattedDate = 'Unknown Date';
            if (appointmentData.containsKey('date') && appointmentData['date'] is String) {
              // Handle string date format in DD/MM/YYYY format from appointment_booking_flow.dart
              formattedDate = appointmentData['date'];
            } else if (appointmentData.containsKey('createdAt') && appointmentData['createdAt'] is Timestamp) {
              // Fallback to created timestamp
              final timestamp = appointmentData['createdAt'] as Timestamp;
              final date = timestamp.toDate();
              formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
            }
            
            // Calculate last visit
            String lastVisit = 'N/A';
            DateTime? appointmentDateTime;
            
            // Try to parse the date string from the appointment
            if (appointmentData.containsKey('date') && appointmentData['date'] is String) {
              try {
                // Parse date like "15/4/2023"
                List<String> parts = appointmentData['date'].toString().split('/');
                if (parts.length == 3) {
                  appointmentDateTime = DateTime(
                    int.parse(parts[2]), // year
                    int.parse(parts[1]), // month
                    int.parse(parts[0]), // day
                  );
                }
              } catch (e) {
                debugPrint('Error parsing date: $e');
              }
            }
            
            // If parsing failed, use createdAt as fallback
            if (appointmentDateTime == null && appointmentData.containsKey('createdAt')) {
              if (appointmentData['createdAt'] is Timestamp) {
                appointmentDateTime = (appointmentData['createdAt'] as Timestamp).toDate();
              }
            }
            
            if (appointmentDateTime != null) {
              final now = DateTime.now();
              final difference = now.difference(appointmentDateTime);
              
              if (difference.inDays == 0) {
                lastVisit = 'Today';
              } else if (difference.inDays == 1) {
                lastVisit = 'Yesterday';
              } else if (difference.inDays < 7) {
                lastVisit = '${difference.inDays} days ago';
              } else if (difference.inDays < 30) {
                lastVisit = '${(difference.inDays / 7).floor()} weeks ago';
              } else {
                lastVisit = '${(difference.inDays / 30).floor()} months ago';
              }
            }
            
            // Format data
            patientsData.add({
              "patientId": patientId,
              "name": patientData['fullName'] ?? patientData['name'] ?? 'Unknown',
              "age": patientData['age'] != null ? '${patientData['age']} Years' : 'Unknown',
              "location": patientData['city'] ?? patientData['address'] ?? 'Unknown',
              "image": patientData['profileImageUrl'] ?? '',
              "lastVisit": lastVisit,
              "condition": appointmentData['reason'] ?? appointmentData['diagnosis'] ?? 'General Checkup',
              "appointment": {
                "id": appointmentDoc.id,
                "date": formattedDate,
                "time": appointmentData['time'] ?? appointmentData['timeSlot'] ?? 'Unknown Time',
                "hospital": "$hospitalName, $hospitalLocation",
                "reason": appointmentData['reason'] ?? 'Consultation',
                "status": appointmentData['status'] ?? 'Pending'
              }
            });
          }
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _patients = patientsData;
        _isLoading = false;
      });
      
      debugPrint('Loaded ${_patients.length} patients');
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error fetching patient data: ${e.toString()}');
      setState(() {
        _errorMessage = 'Failed to load patients: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  // Helper method to get month name
  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  List<Map<String, dynamic>> get filteredPatients {
    List<Map<String, dynamic>> result = _patients.where((patient) {
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
                         patient["appointment"]["hospital"].toString().toLowerCase().contains("karachi");
      }
      
      // Fix the parentheses issue in this condition
      // Filter by appointment status - use lowercase for comparison
      if (selectedFilters.contains("Upcoming")) {
        matchesFilters = matchesFilters && (
                         patient["appointment"]["status"].toString().toLowerCase() == "upcoming" || 
                         patient["appointment"]["status"].toString().toLowerCase() == "confirmed" ||
                         patient["appointment"]["status"].toString().toLowerCase() == "pending"
                         );
      }
      
      if (selectedFilters.contains("Completed")) {
        matchesFilters = matchesFilters && 
                         patient["appointment"]["status"].toString().toLowerCase() == "completed";
      }
                              
      return matchesSearch && matchesFilters;
    }).toList();
    
    // Sort based on selected option - fix the same parentheses issue
    if (_selectedSortIndex == 1) { // Upcoming Appointments
      result = result.where((p) => (
        p["appointment"]["status"].toString().toLowerCase() == "upcoming" || 
        p["appointment"]["status"].toString().toLowerCase() == "confirmed" ||
        p["appointment"]["status"].toString().toLowerCase() == "pending"
      )).toList();
    } else if (_selectedSortIndex == 2) { // Completed Appointments
      result = result.where((p) => p["appointment"]["status"].toString().toLowerCase() == "completed").toList();
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
      body: RefreshIndicator(
        onRefresh: _fetchPatientData,
        child: Stack(
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
                
                  // Search bar - elevated above main content
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _controller,
                      curve: Interval(0.2, 0.7, curve: Curves.easeOut),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
                      )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                LucideIcons.search,
                                color: Colors.grey.shade600,
                              ),
                              hintText: "Search patients or hospitals",
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Main content - scrollable area
                Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF3366CC),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Loading patients...",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                          )
                        : _errorMessage != null
                            ? Center(
                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 48,
                                    ),
                              SizedBox(height: 16),
                                  Text(
                                      "Error Loading Data",
                                    style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                              ),
                              SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                      child: Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _fetchPatientData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF3366CC),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text("Try Again"),
                ),
              ],
            ),
                              )
                            : _patients.isEmpty
                                ? _buildEmptyState()
                                : CustomScrollView(
                                    slivers: [
                                      SliverPadding(
                                        padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                                        sliver: SliverToBoxAdapter(
                                          child: _buildFiltersSection(),
                                        ),
                                      ),
                                      SliverPadding(
                                        padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
                                        sliver: filteredPatients.isEmpty
                                            ? SliverToBoxAdapter(
                                                child: _buildNoResultsFound(),
                                              )
                                            : SliverList(
                                                delegate: SliverChildBuilderDelegate(
                                                  (context, index) {
                                                    final patient = filteredPatients[index];
                                                    return _buildPatientCard(patient);
                                                  },
                                                  childCount: filteredPatients.length,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
            child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Icon(
            Icons.person_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
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

  Widget _buildFiltersSection() {
    return Column(
      children: [
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

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final bool isUpcoming = patient["appointment"]["status"] == "Upcoming" ||
                          patient["appointment"]["status"] == "Confirmed" ||
                          patient["appointment"]["status"] == "Pending";
    
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailProfileScreen(
                  userId: patient["patientId"],
                ),
              ),
            );
          },
      child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
          children: [
                    Hero(
                      tag: "patient_${patient["name"]}",
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
                          child: patient["image"] != null && patient["image"].toString().isNotEmpty
                              ? Image.network(
                                  patient["image"],
                fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.person,
                                        size: 35,
                                        color: Colors.grey.shade500,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF3366CC),
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.grey.shade500,
                                  ),
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
                  patient["name"],
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
                                patient["lastVisit"],
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
                      patient["location"],
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
                        patient["appointment"]["date"],
                      ),
                      SizedBox(height: 8),
                      _buildAppointmentDetailRow(
                        Icons.access_time,
                        "Time:",
                        patient["appointment"]["time"],
                      ),
                      SizedBox(height: 8),
                      _buildAppointmentDetailRow(
                        Icons.business,
                        "Hospital:",
                        patient["appointment"]["hospital"],
                      ),
                      SizedBox(height: 8),
                      _buildAppointmentDetailRow(
                        Icons.description,
                        "Reason:",
                        patient["appointment"]["reason"],
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
                        patient["condition"],
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
                        // Navigate to medical profile with patient ID
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailProfileScreen(
                              userId: patient["patientId"],
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
}
