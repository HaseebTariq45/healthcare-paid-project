import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:healthcare/services/doctor_profile_service.dart';
import 'package:healthcare/views/screens/doctor/availability/hospital_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DoctorProfileService _doctorProfileService = DoctorProfileService();
  
  // Patient data state
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  // Doctor earnings data
  double _totalEarnings = 0.0;
  int _totalAppointments = 0;
  
  // Pagination variables
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final int _patientsPerPage = 3;

  // Cache key
  static const String _patientsCacheKey = 'patients_data_cache';
  static const Duration _cacheValidDuration = Duration(hours: 12);

  List<String> selectedFilters = [];
  int _selectedSortIndex = 0;
  final List<String> _sortOptions = ["All", "Upcoming", "Completed"];

  @override
  void initState() {
    super.initState();
    debugPrint('PatientsScreen initState called');
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        // Reset pagination when search query changes
        _lastDocument = null;
        _hasMoreData = true;
        _patients.clear();
      });
      _loadPatientsWithCache();
    });
    
    // Load data with caching strategy when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Post frame callback running - STARTING LOAD');
      _loadPatientsWithCache();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Main method to load patients data with caching strategy
  Future<void> _loadPatientsWithCache() async {
    if (!mounted) return;
    
    debugPrint('🚀 Started _loadPatientsWithCache');
    _debugPrintState('before-load');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // First try to load from cache
    bool hasCachedData = await _loadFromCache();
    
    // Then start background refresh regardless of cache status
    if (mounted) {
      debugPrint('🔄 Starting background refresh');
      _refreshDataInBackground();
    }
    
    // If no cached data, keep loading state until the background refresh completes
    if (!hasCachedData && mounted) {
      debugPrint('⏳ No cache, showing loading state until fresh data arrives');
      setState(() {
        _isLoading = true;
      });
    } else {
      debugPrint('📦 Using cached data while refreshing in background');
    }
    
    _debugPrintState('after-load-setup');
  }
  
  // Save data to cache
  Future<void> _saveToCache() async {
    try {
      if (_patients.isEmpty) {
        debugPrint('⚠️ CACHE: Not saving cache because patients list is empty');
        return;
      }
      
      final Map<String, dynamic> earningSummary = {
        'totalEarnings': _totalEarnings,
        'totalAppointments': _totalAppointments,
      };
      
      final Map<String, dynamic> cacheData = {
        'lastUpdated': DateTime.now().toIso8601String(),
        'earningSummary': earningSummary,
        'patients': _patients,
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_patientsCacheKey, json.encode(cacheData));
      
      debugPrint('✅ CACHE: Successfully saved ${_patients.length} patients to cache');
    } catch (e) {
      debugPrint('❌ CACHE ERROR: Error saving to cache: $e');
    }
  }
  
  // Load data from cache
  Future<bool> _loadFromCache() async {
    try {
      debugPrint('🔍 CACHE: Attempting to load data from cache...');
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_patientsCacheKey);
      
      if (cachedData != null) {
        debugPrint('📦 CACHE: Found cached data, parsing...');
        final Map<String, dynamic> cached = json.decode(cachedData);
        final DateTime lastUpdated = DateTime.parse(cached['lastUpdated']);
        
        // Check if cache is still valid (less than 12 hours old)
        if (DateTime.now().difference(lastUpdated) < _cacheValidDuration) {
          debugPrint('✅ CACHE: Cache is valid, using cached data');
          final earningSummary = cached['earningSummary'];
          final List<dynamic> patientsData = cached['patients'];
          
          if (mounted) {
            setState(() {
              // Parse earnings data
              _totalEarnings = (earningSummary['totalEarnings'] as num?)?.toDouble() ?? 0.0;
              _totalAppointments = earningSummary['totalAppointments'] as int? ?? 0;
              
              // Parse patients data
              _patients = List<Map<String, dynamic>>.from(patientsData.map(
                (p) => Map<String, dynamic>.from(p as Map)
              ));
              
              _isLoading = false;
              debugPrint('✅ CACHE: UI updated with ${_patients.length} patients from cache');
            });
          }
          
          return true;
        } else {
          debugPrint('⚠️ CACHE: Cache expired, last updated: ${lastUpdated.toIso8601String()}');
        }
      } else {
        debugPrint('⚠️ CACHE: No cached data found');
      }
    } catch (e) {
      debugPrint('❌ CACHE ERROR: Error loading from cache: $e');
    }
    
    return false;
  }
  
  // Refresh data in background
  Future<void> _refreshDataInBackground() async {
    if (!mounted) return;
    
    debugPrint('🔄 Starting data refresh in background');
    _debugPrintState('before-refresh');
    
    setState(() {
      _isRefreshing = true;
      // Reset pagination for a fresh load
      _lastDocument = null;
      _hasMoreData = true;
    });
    
    try {
      debugPrint('📊 Loading earnings data');
      await _loadDoctorEarnings();
      
      debugPrint('👥 Fetching fresh patient data');
      await _fetchPatientData(true);
      
      // Save to cache
      debugPrint('💾 Saving fresh data to cache');
      await _saveToCache();
      
      debugPrint('✅ Background refresh complete');
    } catch (e) {
      debugPrint('❌ Error refreshing data in background: $e');
    } finally {
      // Add slight delay to make refresh indicator more noticeable during testing
      await Future.delayed(Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
        _debugPrintState('after-refresh');
      }
    }
  }
  
  // Fetch initial patient data from Firestore
  Future<void> _fetchPatientData(bool isInitialLoad) async {
    if (!mounted) return;
    
    debugPrint('📥 FETCH: Starting fetch patient data (initialLoad=$isInitialLoad)');
    
    if (isInitialLoad) {
      // Keep existing patients to avoid UI flash but prepare for new data
      setState(() {
        _errorMessage = null;
      });
    }
    
    await _loadPatients(isInitialLoad);
    
    debugPrint('📥 FETCH: Completed fetching patient data');
  }
  
  // Load patients with pagination
  Future<void> _loadPatients(bool isInitialLoad) async {
    if (!mounted || (!isInitialLoad && (!_hasMoreData || _isLoadingMore))) {
      return;
    }
    
    if (!isInitialLoad) {
      setState(() {
        _isLoadingMore = true;
      });
    }
    
    try {
      // Get the current user ID (should be a doctor)
      final String? doctorId = _auth.currentUser?.uid;
      
      if (doctorId == null) {
        throw Exception('User not authenticated');
      }
      
      // Debug: Print doctor ID
      debugPrint('Fetching patients for doctor: $doctorId with pagination');
      
      // Create base query
      Query query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true);
      
      // Apply search filter if provided
      if (_searchQuery.isNotEmpty) {
        // Note: Since Firestore doesn't support direct text search like this,
        // we'll need to filter the results client-side later
        // A real solution would involve creating specific fields for search or using a service like Algolia
      }
      
      // Apply pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      // Limit the number of documents
      query = query.limit(_patientsPerPage);
      
      // Execute query
      final appointmentsSnapshot = await query.get();
      
      debugPrint('Found ${appointmentsSnapshot.docs.length} appointments for this page');
      
      // Check if there are more documents to fetch later
      _hasMoreData = appointmentsSnapshot.docs.length == _patientsPerPage;
      
      // Save the last document for pagination
      if (appointmentsSnapshot.docs.isNotEmpty) {
        _lastDocument = appointmentsSnapshot.docs.last;
      }
          
      if (appointmentsSnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          if (isInitialLoad) {
            _patients.clear();
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      // Create a list to store processed patient data
      List<Map<String, dynamic>> newPatientsData = [];
      
      // Process each appointment
      for (var appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
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
            newPatientsData.add({
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
      
      // Apply client-side filtering for search if needed
      if (_searchQuery.isNotEmpty) {
        newPatientsData = newPatientsData.where((patient) {
          return patient["name"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 patient["location"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 patient["appointment"]["hospital"].toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
      
      setState(() {
        // Replace or append new data to existing patients
        if (isInitialLoad) {
          _patients = newPatientsData;
        } else {
          _patients.addAll(newPatientsData);
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
      
      debugPrint('Total patients loaded: ${_patients.length}');
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error fetching patient data: ${e.toString()}');
      setState(() {
        _errorMessage = 'Failed to load patients: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }
  
  // Helper method to load more patients
  Future<void> _loadMorePatients() async {
    await _loadPatients(false);
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
    return _patients.where((patient) {
      // Only apply further filtering by status and location
      // Search filtering is now handled server-side in _loadPatients
      bool matchesFilters = true;
      
      // Apply filter based on selected tab index
      if (_selectedSortIndex > 0) {
        bool isUpcoming = patient["appointment"]["status"].toString().toLowerCase() == "upcoming" || 
                        patient["appointment"]["status"].toString().toLowerCase() == "confirmed" ||
                        patient["appointment"]["status"].toString().toLowerCase() == "pending";
        
        if (_selectedSortIndex == 1) { // Upcoming tab selected
          matchesFilters = matchesFilters && isUpcoming;
        } else if (_selectedSortIndex == 2) { // Completed tab selected
          matchesFilters = matchesFilters && !isUpcoming;
        }
      }
      
      // Filter by location
      if (selectedFilters.contains("Karachi")) {
        matchesFilters = matchesFilters && 
                        patient["appointment"]["hospital"].toString().toLowerCase().contains("karachi");
      }
      
      // Filter by appointment status
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
                            
      return matchesFilters;
    }).toList();
  }

  void toggleFilter(String filter) {
    setState(() {
      if (selectedFilters.contains(filter)) {
        selectedFilters.remove(filter);
      } else {
        selectedFilters.add(filter);
      }
    });
    
    // Reset pagination and fetch data again when filters change
    _lastDocument = null;
    _hasMoreData = true;
    _patients.clear();
    _fetchPatientData(true);
  }

  // Load doctor earnings data
  Future<void> _loadDoctorEarnings() async {
    if (!mounted) return;
    
    debugPrint('Loading doctor earnings data...');
    
    try {
      final String? doctorId = _auth.currentUser?.uid;
      if (doctorId == null) {
        debugPrint('Doctor ID is null, cannot load earnings');
        return;
      }
      
      debugPrint('Fetching earnings for doctor: $doctorId');
      
      // Get doctor stats which includes consistently calculated earnings
      final doctorStats = await _doctorProfileService.getDoctorStats();
      
      debugPrint('Doctor stats received: $doctorStats');
      
      if (mounted && doctorStats['success'] == true) {
        final earnings = doctorStats['totalEarnings'] ?? 0.0;
        final appointments = doctorStats['totalAppointments'] ?? 0;
        
        debugPrint('Setting state with earnings: $earnings, appointments: $appointments');
        
        setState(() {
          _totalEarnings = earnings;
          _totalAppointments = appointments;
        });
        
        debugPrint('State updated with earnings and appointments');
      } else {
        debugPrint('Doctor stats not successful or component unmounted');
      }
    } catch (e) {
      debugPrint('Error loading doctor earnings: $e');
    }
  }

  void _debugPrintState(String source) {
    debugPrint('PATIENTS STATE [$source]: '
        'isLoading=$_isLoading, '
        'isRefreshing=$_isRefreshing, '
        'hasError=${_errorMessage != null}, '
        'patientCount=${_patients.length}, '
        'hasMoreData=$_hasMoreData, '
        'isLoadingMore=$_isLoadingMore');
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered patients
    final displayedPatients = filteredPatients;
    
    // Force refresh indicator visibility for testing
    // Comment this line out for production
    // _isRefreshing = true;
    
    // Debug print current state
    _debugPrintState('build');
    
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar with home tab selected
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationBarScreen(
              profileStatus: "complete",
              initialIndex: 0, // Home tab index
            ),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshDataInBackground,
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
                      Color(0xFF3366CC),
                      Color(0xFF5E8EF7),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3366CC).withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                      spreadRadius: 2,
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
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
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
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                    
                    // Earnings summary
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF5E8EF7).withOpacity(0.9),
                            Color(0xFF3366CC).withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Doctor Performance",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildEarningsStat(
                                "Total Earnings",
                                "Rs ${_totalEarnings.toStringAsFixed(0)}",
                                LucideIcons.wallet,
                              ),
                              Container(
                                height: 40,
                                width: 1.5,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              _buildEarningsStat(
                                "Appointments",
                                _totalAppointments.toString(),
                                LucideIcons.calendar,
                              ),
                            ],
                          ),
                          // Add debug text to show actual values
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              "Earnings: $_totalEarnings, Appointments: $_totalAppointments",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                              ),
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
                                  color: Color(0xFF3366CC).withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: Offset(0, 6),
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: Color(0xFF5E8EF7).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  color: Color(0xFF3366CC),
                                  size: 22,
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
                                          color: Color(0xFF3366CC),
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
                      child: _isLoading && _patients.isEmpty
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
                                        onPressed: () => _fetchPatientData(true),
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
                                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                          sliver: displayedPatients.isEmpty
                                              ? SliverToBoxAdapter(
                                                  child: _buildNoResultsFound(),
                                                )
                                              : SliverList(
                                                  delegate: SliverChildBuilderDelegate(
                                                    (context, index) {
                                                      final patient = displayedPatients[index];
                                                      return _buildPatientCard(patient);
                                                    },
                                                    childCount: displayedPatients.length,
                                                  ),
                                                ),
                                        ),
                                        
                                        // Show loading indicator or load more button
                                        if (!_isLoading && _hasMoreData)
                                          SliverPadding(
                                            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                                            sliver: SliverToBoxAdapter(
                                              child: _buildLoadMoreButton(),
                                            ),
                                          ),
                                          
                                        // Show loading indicator when loading more data
                                        if (_isLoadingMore)
                                          SliverPadding(
                                            padding: EdgeInsets.only(bottom: 20, top: 10),
                                            sliver: SliverToBoxAdapter(
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  color: Color(0xFF3366CC),
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                        // Add bottom padding if all items are loaded
                                        if (!_hasMoreData && !_isLoadingMore)
                                          SliverPadding(
                                            padding: EdgeInsets.only(bottom: 20),
                                            sliver: SliverToBoxAdapter(
                                              child: Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "No more patients to load",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                  ),
                ],
              ),
              ),
              
              // Bottom refresh indicator - always visible for testing
              if (_isRefreshing || _isLoading) _buildBottomRefreshIndicator(),
            ],
          ),
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
        SizedBox(height: 8),
        _buildSortOptions(),
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
          Icon(
            LucideIcons.userX,
            size: 80,
            color: Color(0xFF5E8EF7).withOpacity(0.7),
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
            "Try adjusting your search",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3366CC).withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Color(0xFF5E8EF7).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF3366CC).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Color(0xFF5E8EF7).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: patient["image"] != null && patient["image"].toString().isNotEmpty
                              ? Image.network(
                                  patient["image"],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(0xFF5E8EF7).withOpacity(0.1),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.person,
                                        size: 35,
                                        color: Color(0xFF3366CC),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Color(0xFF5E8EF7).withOpacity(0.1),
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
                                  color: Color(0xFF5E8EF7).withOpacity(0.1),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Color(0xFF3366CC),
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
                              color: Color(0xFF3366CC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Color(0xFF5E8EF7),
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
                                color: Color(0xFF5E8EF7),
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
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF5E8EF7),
                            Color(0xFF3366CC),
                          ],
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
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Appointment details
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF0F7FF),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Color(0xFF5E8EF7).withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3366CC).withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildAppointmentDetailRow(
                        Icons.calendar_today,
                        "Date:",
                        patient["appointment"]["date"],
                        Color(0xFF3366CC),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Color(0xFF5E8EF7).withOpacity(0.2),
                          thickness: 1,
                        ),
                      ),
                      _buildAppointmentDetailRow(
                        Icons.access_time,
                        "Time:",
                        patient["appointment"]["time"],
                        Color(0xFF5E8EF7),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Color(0xFF5E8EF7).withOpacity(0.2),
                          thickness: 1,
                        ),
                      ),
                      _buildAppointmentDetailRow(
                        Icons.business,
                        "Hospital:",
                        patient["appointment"]["hospital"],
                        Color(0xFF3366CC),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Color(0xFF5E8EF7).withOpacity(0.2),
                          thickness: 1,
                        ),
                      ),
                      _buildAppointmentDetailRow(
                        Icons.description,
                        "Reason:",
                        patient["appointment"]["reason"],
                        Color(0xFF5E8EF7),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEDF5FF),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF5E8EF7).withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3366CC).withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFF3366CC).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.medical_information_outlined,
                              size: 16,
                              color: Color(0xFF3366CC),
                            ),
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF3366CC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF3366CC).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          patient["condition"],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Color(0xFF3366CC),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppointmentDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        SizedBox(width: 10),
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
              color: Color(0xFF3366CC),
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
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5E8EF7),
                    Color(0xFF3366CC),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Color(0xFF3366CC) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF3366CC).withOpacity(0.25),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (label == "Filters" ? Color(0xFF3366CC) : Colors.grey.shade500),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.white
                    : (label == "Filters" ? Color(0xFF3366CC) : Colors.grey.shade500),
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

  // New method to build the "Load More" button
  Widget _buildLoadMoreButton() {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5E8EF7),
            Color(0xFF3366CC),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loadMorePatients,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.plus, size: 16),
            ),
            SizedBox(width: 10),
            Text(
              "Load More Patients",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsStat(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Fix the refresh indicator at the bottom of the screen
  Widget _buildBottomRefreshIndicator() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5E8EF7),
                Color(0xFF3366CC),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3366CC).withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 14),
              Text(
                "Refreshing patient data...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
