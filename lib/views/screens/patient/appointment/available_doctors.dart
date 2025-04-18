import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/appointment_booking_flow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class DoctorsScreen extends StatefulWidget {
  final String? specialty;
  final List<Map<String, dynamic>> doctors;
  final String? initialGenderFilter;

  const DoctorsScreen({
    Key? key, 
    this.specialty,
    this.doctors = const [],
    this.initialGenderFilter,
  }) : super(key: key);

  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late List<Map<String, dynamic>> filteredDoctors;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Firestore and Auth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Filtering options
  int _selectedCategoryIndex = 0;
  String? selectedRating;
  String? selectedLocation;
  String? selectedGender;
  bool sortByPriceLowToHigh = false;
  bool showOnlyInMyCity = false;
  String? userCity; // Store the user's city for filtering
  Color genderColor = Colors.grey;
  
  // Available filter categories
  final List<String> _categories = ["All", "Cardiology", "Neurology", "Dermatology", "Orthopedics", "ENT", "Pediatrics", "Gynecology", "Ophthalmology", "Dentistry", "Psychiatry", "Pulmonology", "Gastrology"];

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize filters
    filteredDoctors = [];
    selectedGender = widget.initialGenderFilter; // Set initial gender filter
    
    // If a specific specialty is provided, set the category index accordingly
    if (widget.specialty != null && widget.specialty != "All") {
      // If specialty is provided directly from home screen, 
      // we'll fetch only those doctors and won't show the category tabs
      _selectedCategoryIndex = _categories.indexOf(widget.specialty!);
      if (_selectedCategoryIndex == -1) {
        // If specialty is not in our predefined list, add it
        _categories.add(widget.specialty!);
        _selectedCategoryIndex = _categories.indexOf(widget.specialty!);
      }
    }
    
    // Fetch user's city
    _fetchUserCity();
    
    // Fetch doctors from Firestore
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    
    // Debounce search to avoid too many Firestore calls
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  // Fetch the user's city from Firestore
  Future<void> _fetchUserCity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user data from patients collection
        final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
        
        if (patientDoc.exists) {
          final data = patientDoc.data();
          if (data != null && data['city'] != null) {
            setState(() {
              userCity = data['city'];
              debugPrint('User city found: $userCity');
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user city: $e');
    }
  }

  // Fetch doctors from Firestore
  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // If we already have doctors from the widget parameter and a specialty is specified,
      // just use those directly instead of fetching from Firestore
      if (widget.doctors.isNotEmpty && widget.specialty != null && widget.specialty != "All") {
        if (mounted) {
          setState(() {
            filteredDoctors = List.from(widget.doctors);
            _isLoading = false;
            _applyFilters();
          });
        }
        return;
      }
      
      final List<Map<String, dynamic>> doctorsList = [];
      
      // Query doctors collection
      Query doctorsQuery = _firestore.collection('doctors');
      
      // Apply specialty filter if specified
      if (widget.specialty != null && widget.specialty != "All") {
        doctorsQuery = doctorsQuery.where('specialty', isEqualTo: widget.specialty);
      }
      
      // Apply gender filter if specified
      if (selectedGender != null) {
        doctorsQuery = doctorsQuery.where('gender', isEqualTo: selectedGender);
      }
      
      final QuerySnapshot doctorsSnapshot = await doctorsQuery.get();
      
      // Process each doctor document
      for (var doc in doctorsSnapshot.docs) {
        final doctorData = doc.data() as Map<String, dynamic>;
        final doctorId = doc.id;
        
        // Get doctor's hospitals and availability
        final hospitalsQuery = await _firestore
            .collection('doctor_hospitals')
            .where('doctorId', isEqualTo: doctorId)
            .get();
        
        final List<Map<String, dynamic>> hospitalsList = [];
        
        // For each hospital, get today's availability
        for (var hospitalDoc in hospitalsQuery.docs) {
          final hospitalData = hospitalDoc.data();
          final hospitalId = hospitalData['hospitalId'];
          final hospitalName = hospitalData['hospitalName'] ?? 'Unknown Hospital';
          
          // Get today's date in YYYY-MM-DD format
          final today = DateTime.now();
          final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          
          // Query availability for this hospital and date
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
          
          hospitalsList.add({
            'hospitalId': hospitalId,
            'hospitalName': hospitalName,
            'availableToday': timeSlots.isNotEmpty,
            'timeSlots': timeSlots,
          });
        }
        
        // Determine overall availability
        final bool isAvailableToday = hospitalsList.any((hospital) => hospital['availableToday'] == true);
        
        // Create doctor map with all relevant information
        doctorsList.add({
          'id': doctorId,
          'name': doctorData['fullName'] ?? doctorData['name'] ?? 'Unknown Doctor',
          'specialty': doctorData['specialty'] ?? 'General Practitioner',
          'rating': doctorData['rating']?.toString() ?? "0.0",
          'experience': doctorData['experience']?.toString() ?? "0 years",
          'fee': 'Rs ${doctorData['fee']?.toString() ?? "0"}',
          'location': hospitalsList.isNotEmpty ? hospitalsList.first['hospitalName'] : 'Multiple Hospitals',
          'image': doctorData['profileImageUrl'] ?? "assets/images/User.png",
          'available': isAvailableToday,
          'hospitals': hospitalsList,
          'gender': doctorData['gender'] ?? 'Not specified',
        });
      }
      
      if (mounted) {
        setState(() {
          if (doctorsList.isEmpty && widget.doctors.isNotEmpty) {
            // If no doctors from Firestore but we have doctors from widget
            filteredDoctors = List.from(widget.doctors);
          } else {
            // Use doctors from Firestore
            filteredDoctors = doctorsList;
          }
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading doctors: $e';
          _isLoading = false;
          
          // If we have doctors from widget parameter, use those
          if (widget.doctors.isNotEmpty) {
            filteredDoctors = List.from(widget.doctors);
            _applyFilters();
          } else {
            filteredDoctors = [];
          }
        });
      }
      debugPrint('Error fetching doctors: $e');
    }
  }

  // Apply all active filters to the doctors list and reload data from Firestore
  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create a base Query
      Query doctorsQuery = _firestore.collection('doctors');
      
      // Apply specialty filter if specified from widget or selected category
      if (widget.specialty != null && widget.specialty != "All") {
        doctorsQuery = doctorsQuery.where('specialty', isEqualTo: widget.specialty);
      } else if (_selectedCategoryIndex > 0) {
        final selectedCategory = _categories[_selectedCategoryIndex];
        doctorsQuery = doctorsQuery.where('specialty', isEqualTo: selectedCategory);
      }
      
      // Apply gender filter directly in query
      if (selectedGender != null) {
        doctorsQuery = doctorsQuery.where('gender', isEqualTo: selectedGender);
      }

      // Apply city filter if enabled
      if (showOnlyInMyCity && userCity != null) {
        doctorsQuery = doctorsQuery.where('city', isEqualTo: userCity);
      }
      
      final QuerySnapshot doctorsSnapshot = await doctorsQuery.get();
      final List<Map<String, dynamic>> doctorsList = [];
      
      // Process each doctor document
      for (var doc in doctorsSnapshot.docs) {
        final doctorData = doc.data() as Map<String, dynamic>;
        final doctorId = doc.id;
        
        // Get doctor's hospitals and availability
        final hospitalsQuery = await _firestore
            .collection('doctor_hospitals')
            .where('doctorId', isEqualTo: doctorId)
            .get();
        
        final List<Map<String, dynamic>> hospitalsList = [];
        
        // For each hospital, get today's availability
        for (var hospitalDoc in hospitalsQuery.docs) {
          final hospitalData = hospitalDoc.data();
          final hospitalId = hospitalData['hospitalId'];
          final hospitalName = hospitalData['hospitalName'] ?? 'Unknown Hospital';
          
          // Get today's date in YYYY-MM-DD format
          final today = DateTime.now();
          final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          
          // Query availability for this hospital and date
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
          
          hospitalsList.add({
            'hospitalId': hospitalId,
            'hospitalName': hospitalName,
            'availableToday': timeSlots.isNotEmpty,
            'timeSlots': timeSlots,
          });
        }
        
        // Determine overall availability
        final bool isAvailableToday = hospitalsList.any((hospital) => hospital['availableToday'] == true);
        
        // Create doctor map with all relevant information
        doctorsList.add({
          'id': doctorId,
          'name': doctorData['fullName'] ?? doctorData['name'] ?? 'Unknown Doctor',
          'specialty': doctorData['specialty'] ?? 'General Practitioner',
          'rating': doctorData['rating']?.toString() ?? "0.0",
          'experience': doctorData['experience']?.toString() ?? "0 years",
          'fee': 'Rs ${doctorData['fee']?.toString() ?? "0"}',
          'location': hospitalsList.isNotEmpty ? hospitalsList.first['hospitalName'] : 'Multiple Hospitals',
          'image': doctorData['profileImageUrl'] ?? "assets/images/User.png",
          'available': isAvailableToday,
          'hospitals': hospitalsList,
          'gender': doctorData['gender'] ?? 'Not specified',
          'city': doctorData['city'] ?? '',
          'isInUserCity': doctorData['city'] == userCity,
        });
      }
      
      // Apply client-side filters
      List<Map<String, dynamic>> result = List.from(doctorsList);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((doctor) {
        return doctor['name'].toString().toLowerCase().contains(_searchQuery) ||
               doctor['specialty'].toString().toLowerCase().contains(_searchQuery) ||
                doctor['location'].toString().toLowerCase().contains(_searchQuery) ||
                doctor['city'].toString().toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Apply rating filter
    if (selectedRating != null) {
      final minRating = double.parse(selectedRating!.replaceAll('+', ''));
      result = result.where((doctor) {
        double rating;
        try {
          rating = double.parse(doctor['rating'].toString());
        } catch (e) {
          rating = 0.0;
        }
        return rating >= minRating;
      }).toList();
    }
    
    // Apply sorting
    if (sortByPriceLowToHigh) {
      result.sort((a, b) {
        // Extract fee as numeric value (remove "Rs " and parse)
        double aFee = 0.0;
        double bFee = 0.0;
        try {
          aFee = double.parse(a['fee'].toString().replaceAll('Rs ', ''));
          bFee = double.parse(b['fee'].toString().replaceAll('Rs ', ''));
        } catch (e) {
          // Handle parsing error
        }
        return aFee.compareTo(bFee);
      });
    } else {
      // Sort by rating (highest first)
      result.sort((a, b) {
        double aRating = 0.0;
        double bRating = 0.0;
        try {
          aRating = double.parse(a['rating'].toString());
          bRating = double.parse(b['rating'].toString());
        } catch (e) {
          // Handle parsing error
        }
        return bRating.compareTo(aRating);
      });
    }
    
      if (mounted) {
    setState(() {
      filteredDoctors = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error filtering doctors: $e';
          _isLoading = false;
          filteredDoctors = [];
        });
      }
      debugPrint('Error applying filters: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    // Calculate responsive paddings and sizes
    final double horizontalPadding = width * 0.04;
    final double verticalPadding = height * 0.01;
    final double iconSize = width * 0.05;
    final double borderRadius = width * 0.03;
    
    // Determine if we're viewing a specific specialty
    final bool viewingSpecificSpecialty = widget.specialty != null && widget.specialty != "All";
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                _buildHeader(context),
                _buildFilterBar(context),
                _buildSearchBar(context),
            // Only show category tabs if not viewing a specific specialty
            if (!viewingSpecificSpecialty)
                  _buildCategoryTabs(context),
            // Show loading indicator, error message, or doctor list
            _isLoading 
            ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          SizedBox(
                            width: width * 0.1,
                            height: width * 0.1,
                            child: CircularProgressIndicator(
                        color: const Color(0xFF3366CC),
                              strokeWidth: width * 0.008,
                      ),
                          ),
                          SizedBox(height: height * 0.02),
                      Text(
                        "Loading doctors...",
                        style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _errorMessage != null
              ? Expanded(
                  child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                                size: width * 0.12,
                        ),
                              SizedBox(height: height * 0.02),
                        Text(
                          "Oops! Something went wrong",
                          style: GoogleFonts.poppins(
                                  fontSize: width * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                  fontSize: width * 0.035,
                              color: Colors.grey.shade600,
                            ),
                          ),
                              SizedBox(height: height * 0.025),
                        ElevatedButton.icon(
                          onPressed: _fetchDoctors,
                                icon: Icon(Icons.refresh, size: width * 0.045),
                                label: Text(
                                  "Try Again",
                                  style: GoogleFonts.poppins(
                                    fontSize: width * 0.04,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3366CC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(borderRadius),
                            ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.05, 
                                    vertical: height * 0.012
                                  ),
                          ),
                        ),
                      ],
                          ),
                    ),
                  ),
                )
              : filteredDoctors.isEmpty
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.userX,
                            color: Colors.grey.shade400,
                                size: width * 0.12,
                          ),
                              SizedBox(height: height * 0.02),
                          Text(
                            viewingSpecificSpecialty ? 
                              "No ${widget.specialty} specialists found" : 
                              "No doctors found",
                            style: GoogleFonts.poppins(
                                  fontSize: width * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                                textAlign: TextAlign.center,
                          ),
                              SizedBox(height: height * 0.01),
                          Text(
                            "Try changing your search criteria",
                            style: GoogleFonts.poppins(
                                  fontSize: width * 0.035,
                              color: Colors.grey.shade600,
                            ),
                                textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                        child: _buildDoctorsList(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    // Create a more descriptive title based on specialty and gender
    String headerTitle = "Available Doctors";
    if (widget.specialty != null && widget.specialty != "All") {
      headerTitle = "${widget.specialty} Specialists";
      
      // Add gender information if present
      if (selectedGender != null) {
        headerTitle = "$selectedGender ${widget.specialty} Specialists";
      }
    } else if (selectedGender != null) {
      headerTitle = "$selectedGender Doctors";
    }

    // Get gender icon and color for badge - fixed nullable issues
    IconData? genderIconTemp;
    if (selectedGender == "Male") {
      genderIconTemp = Icons.male;
    } else if (selectedGender == "Female") {
      genderIconTemp = Icons.female;
    }
    
    if (selectedGender == "Male") {
      genderColor = Colors.blue;
    } else if (selectedGender == "Female") {
      genderColor = Colors.pink;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(width * 0.05, height * 0.015, width * 0.05, height * 0.015),
      decoration: BoxDecoration(
        color: const Color(0xFF3366CC),
      ),
      child: Row(
        children: [
          GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
              padding: EdgeInsets.all(width * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(width * 0.03),
                  ),
              child: Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                size: width * 0.05,
                  ),
                ),
              ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Row(
              children: [
                Flexible(
            child: Text(
              headerTitle,
            style: GoogleFonts.poppins(
                      fontSize: width * 0.045,
                fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
                    overflow: TextOverflow.ellipsis,
          ),
          ),
                if (selectedGender != null && genderIconTemp != null)
          Container(
                    margin: EdgeInsets.only(left: width * 0.02),
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.02, 
                      vertical: height * 0.004
                    ),
                    decoration: BoxDecoration(
                      color: genderColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          genderIconTemp,
                          color: Colors.white,
                          size: width * 0.035,
                        ),
                        SizedBox(width: width * 0.01),
                        Text(
                          selectedGender!,
                          style: GoogleFonts.poppins(
                            fontSize: width * 0.03,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(width * 0.02),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(width * 0.03),
            ),
            child: InkWell(
              onTap: () {
                _showFilterDialog();
              },
              child: Icon(
                Icons.filter_list,
                color: Colors.white,
                size: width * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    return Container(
      padding: EdgeInsets.fromLTRB(width * 0.05, height * 0.015, width * 0.05, height * 0.015),
      decoration: BoxDecoration(
        color: const Color(0xFF3366CC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(width * 0.075),
          bottomRight: Radius.circular(width * 0.075),
        ),
      ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.03),
                boxShadow: [
                  BoxShadow(
              color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
              offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
            hintText: "Search doctors...",
            hintStyle: GoogleFonts.poppins(
              fontSize: width * 0.035,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade600, size: width * 0.045),
            suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(LucideIcons.x, size: width * 0.045),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ) 
                    : null,
                  border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: height * 0.015),
          ),
          style: GoogleFonts.poppins(
            fontSize: width * 0.035,
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    return Container(
      height: height * 0.06,
      margin: EdgeInsets.only(top: height * 0.012),
              child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
        itemCount: _categories.length,
                itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.012),
            child: GestureDetector(
                    onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
                // Call the asynchronous filter method
                _applyFilters();
            },
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              decoration: BoxDecoration(
                  color: _selectedCategoryIndex == index
                      ? const Color(0xFF3366CC)
                      : const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(width * 0.05),
                boxShadow: _selectedCategoryIndex == index
                    ? [
                        BoxShadow(
                            color: const Color(0xFF3366CC).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: GoogleFonts.poppins(
                    fontSize: width * 0.035,
                  fontWeight: FontWeight.w500,
                  color: _selectedCategoryIndex == index
                      ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ),
                    ),
                  );
                },
      ),
    );
  }

  Widget _buildDoctorsList(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(width * 0.05, width * 0.025, width * 0.05, width * 0.05),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = filteredDoctors[index];
        return _buildDoctorCard(context, doctor);
      },
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    // Format doctor data to handle both string and numeric values for rating
    String ratingStr = doctor["rating"] is String ? 
        doctor["rating"] : doctor["rating"].toString();
        
    String experienceStr = doctor["experience"] is String ? 
        doctor["experience"] : "${doctor["experience"]} years";
    
    // Set default values for missing fields to ensure UI doesn't break
    bool isAvailable = doctor["available"] ?? true;
    String fee = doctor["fee"] ?? "Rs 2000";
    String location = doctor["location"] ?? "Not specified";
    String gender = doctor["gender"] ?? "Not specified";
    bool isInUserCity = doctor["isInUserCity"] ?? false;
    String city = doctor["city"] ?? "";
    
    // Get the appropriate gender icon
    IconData genderIcon = Icons.person;
    if (gender == "Male") {
      genderIcon = Icons.male;
    } else if (gender == "Female") {
      genderIcon = Icons.female;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isInUserCity ? Colors.blue.shade300 : Colors.grey.shade100,
          width: isInUserCity ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(width * 0.04),
      onTap: () {
            // Navigate to appointment booking
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentBookingFlow(
              preSelectedDoctor: doctor,
                  specialty: doctor["specialty"],
            ),
          ),
        );
      },
          child: Padding(
            padding: EdgeInsets.all(width * 0.04),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Container(
                  width: width * 0.2,
                  height: width * 0.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(doctor["image"]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doctor["name"],
                                style: GoogleFonts.poppins(
                                fontSize: width * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAvailable) // Check if doctor is available
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.02, 
                                vertical: height * 0.004
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(width * 0.03),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: width * 0.015,
                                    height: width * 0.015,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    "Online",
                                style: GoogleFonts.poppins(
                                      fontSize: width * 0.025,
                                  fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: height * 0.004),
                      Row(
                        children: [
                        Text(
                          doctor["specialty"],
                          style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                            color: Colors.grey.shade600,
                          ),
                        ),
                          SizedBox(width: width * 0.02),
                          // Display gender
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.015, 
                              vertical: height * 0.002
                            ),
                            decoration: BoxDecoration(
                              color: genderColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(width * 0.03),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  genderIcon,
                                  size: width * 0.03,
                                  color: genderColor,
                                ),
                                SizedBox(width: width * 0.01),
                                Text(
                                  gender,
                                  style: GoogleFonts.poppins(
                                    fontSize: width * 0.025,
                                    fontWeight: FontWeight.w500,
                                    color: genderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.008),
                        Row(
                          children: [
                          _buildRatingBar(context, ratingStr),
                          SizedBox(width: width * 0.04),
                          Icon(
                              LucideIcons.briefcase,
                            color: const Color(0xFF3366CC),
                            size: width * 0.04,
                          ),
                          SizedBox(width: width * 0.01),
                          Text(
                            experienceStr,
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                              color: Colors.grey.shade600,
                            ),
                            ),
                          ],
                        ),
                      SizedBox(height: height * 0.008),
                        Row(
                          children: [
                            Icon(
                            LucideIcons.banknote,
                            color: Colors.green.shade600,
                            size: width * 0.04,
                          ),
                          SizedBox(width: width * 0.01),
                          Text(
                            fee,
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Spacer(),
                            Icon(
                              LucideIcons.mapPin,
                            color: isInUserCity ? Colors.blue.shade600 : Colors.orange.shade600,
                            size: width * 0.04,
                          ),
                          SizedBox(width: width * 0.01),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                              child: Text(
                              location,
                                style: GoogleFonts.poppins(
                                      fontSize: width * 0.035,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInUserCity)
                                  Container(
                                    margin: EdgeInsets.only(left: width * 0.01),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.01, 
                                      vertical: height * 0.002
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(width * 0.01),
                                    ),
                                    child: Text(
                                      "Local",
                                      style: GoogleFonts.poppins(
                                        fontSize: width * 0.02,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
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
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, String ratingStr) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    
    double rating = 0.0;
    try {
      rating = double.parse(ratingStr);
    } catch (e) {
      // Handle parsing error
      rating = 0.0;
    }
    
    // Format to one decimal place for display
    String displayRating = rating.toStringAsFixed(1);
    
    return Row(
      children: [
        Text(
          displayRating,
          style: GoogleFonts.poppins(
            fontSize: width * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade800,
          ),
        ),
        SizedBox(width: width * 0.01),
        Icon(
          Icons.star,
          color: Colors.amber,
          size: width * 0.04,
        ),
      ],
    );
  }

  void _showFilterDialog() {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width * 0.05),
          topRight: Radius.circular(width * 0.05),
                ),
              ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                        "Filter Doctors",
                          style: GoogleFonts.poppins(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                    SizedBox(height: height * 0.02),
                  
                  // Rating filter
                        Text(
                    "Rating",
                          style: GoogleFonts.poppins(
                        fontSize: width * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                          ),
                        ),
                    SizedBox(height: height * 0.01),
                  Wrap(
                      spacing: width * 0.02,
                    children: [
                      _buildFilterChip(
                          context,
                        "All",
                        selectedRating == null,
                        () => setState(() {
                          selectedRating = null;
                        }),
                      ),
                      _buildFilterChip(
                          context,
                        "4+",
                        selectedRating == "4+",
                        () => setState(() {
                          selectedRating = "4+";
                        }),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    
                    // Gender filter
                    Text(
                      "Gender",
                      style: GoogleFonts.poppins(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Wrap(
                      spacing: width * 0.02,
                      runSpacing: height * 0.01,
                      children: [
                        _buildFilterChip(
                          context,
                          "All",
                          selectedGender == null,
                          () => setState(() {
                            selectedGender = null;
                          }),
                        ),
                        _buildFilterChip(
                          context,
                          "Male",
                          selectedGender == "Male",
                          () => setState(() {
                            selectedGender = "Male";
                          }),
                        ),
                        _buildFilterChip(
                          context,
                          "Female",
                          selectedGender == "Female",
                          () => setState(() {
                            selectedGender = "Female";
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    
                    // City filter
                    if (userCity != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Location",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                  Row(
                    children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: showOnlyInMyCity,
                        onChanged: (value) => setState(() {
                                    showOnlyInMyCity = value!;
                        }),
                        activeColor: const Color(0xFF3366CC),
                        shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(width * 0.01),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Doctors in my city ($userCity)",
                        style: GoogleFonts.poppins(
                                    fontSize: width * 0.035,
                          color: Colors.black87,
                                  ),
                        ),
                      ),
                    ],
                  ),
                          SizedBox(height: height * 0.02),
                        ],
                      ),
                  
                  // Sort by price
                  Row(
                    children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                        value: sortByPriceLowToHigh,
                        onChanged: (value) => setState(() {
                          sortByPriceLowToHigh = value!;
                        }),
                        activeColor: const Color(0xFF3366CC),
                        shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width * 0.01),
                        ),
                      ),
                        ),
                        Expanded(
                          child: Text(
                        "Sort by price: Low to High",
                        style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                          color: Colors.black87,
                            ),
                        ),
                      ),
                    ],
                  ),
                    SizedBox(height: height * 0.025),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                          // Call the asynchronous filter method
                        _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366CC),
                          padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * 0.03),
                      ),
                    ),
                    child: Text(
                        "Apply Filters",
                      style: GoogleFonts.poppins(
                            fontSize: width * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04, 
          vertical: height * 0.01
        ),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3366CC) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(width * 0.05),
          border: Border.all(
            color: isSelected ? const Color(0xFF3366CC) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
            style: GoogleFonts.poppins(
            fontSize: width * 0.035,
              fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // New widget for quick filter options
  Widget _buildFilterBar(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    return Container(
      padding: EdgeInsets.symmetric(vertical: height * 0.01),
      color: const Color(0xFF3366CC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            SizedBox(width: width * 0.05),
            
            // Rating filter
            _buildQuickFilterChip(
              context: context,
              icon: Icons.star,
              label: selectedRating == null ? "Rating" : "$selectedRating Rating",
              isActive: selectedRating != null,
              onTap: () {
                _showRatingFilterSheet();
              },
            ),
            
            SizedBox(width: width * 0.02),
            
            // Gender filter
            _buildQuickFilterChip(
              context: context,
              icon: selectedGender == "Male" 
                ? Icons.male 
                : selectedGender == "Female" 
                  ? Icons.female 
                  : Icons.person,
              label: selectedGender ?? "Gender",
              isActive: selectedGender != null,
              onTap: () {
                _showGenderFilterSheet();
              },
            ),
            
            SizedBox(width: width * 0.02),
            
            // City filter - only show if user's city is available
            if (userCity != null)
              _buildQuickFilterChip(
                context: context,
                icon: LucideIcons.mapPin,
                label: showOnlyInMyCity ? "In $userCity" : "City",
                isActive: showOnlyInMyCity,
                onTap: () {
                  setState(() {
                    showOnlyInMyCity = !showOnlyInMyCity;
                    _applyFilters();
                  });
                },
              ),
              
            SizedBox(width: width * 0.02),
            
            // Price sorting
            _buildQuickFilterChip(
              context: context,
              icon: sortByPriceLowToHigh ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              label: sortByPriceLowToHigh ? "Price: Low to High" : "Price: High to Low",
              isActive: true,
              onTap: () {
                setState(() {
                  sortByPriceLowToHigh = !sortByPriceLowToHigh;
                  _applyFilters();
                });
              },
            ),
            
            SizedBox(width: width * 0.02),
            
            // Clear all filters
            if (selectedRating != null || selectedGender != null || showOnlyInMyCity)
              _buildQuickFilterChip(
                context: context,
                icon: LucideIcons.x,
                label: "Clear All",
                isActive: true,
                backgroundColor: Colors.red.shade400,
                onTap: () {
                  setState(() {
                    selectedRating = null;
                    selectedGender = null;
                    showOnlyInMyCity = false;
                    _applyFilters();
                  });
                },
              ),
              
            SizedBox(width: width * 0.05),
          ],
        ),
      ),
    );
  }

  // Widget for individual filter chip in the filter bar
  Widget _buildQuickFilterChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.025,
          vertical: height * 0.007,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? (backgroundColor ?? Colors.white) 
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(width * 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: width * 0.035,
              color: isActive 
                  ? (backgroundColor != null ? Colors.white : const Color(0xFF3366CC)) 
                  : Colors.white,
            ),
            SizedBox(width: width * 0.01),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: width * 0.03,
                fontWeight: FontWeight.w500,
                color: isActive 
                    ? (backgroundColor != null ? Colors.white : const Color(0xFF3366CC)) 
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show rating filter popup
  void _showRatingFilterSheet() {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width * 0.05),
          topRight: Radius.circular(width * 0.05),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Select Rating",
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                        selectedRating = null;
                        _applyFilters();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      child: Row(
                        children: [
                          Text(
                            "All Ratings",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          if (selectedRating == null)
                            Icon(
                              Icons.check,
                              color: const Color(0xFF3366CC),
                              size: width * 0.05,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                        selectedRating = "4+";
                        _applyFilters();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              Text(
                                "4+ ",
                                style: GoogleFonts.poppins(
                                  fontSize: width * 0.035,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: width * 0.04,
                              ),
                            ],
                          ),
                          Spacer(),
                          if (selectedRating == "4+")
                            Icon(
                              Icons.check,
                              color: const Color(0xFF3366CC),
                              size: width * 0.05,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show gender filter popup
  void _showGenderFilterSheet() {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width * 0.05),
          topRight: Radius.circular(width * 0.05),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Select Gender",
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                        selectedGender = null;
                        _applyFilters();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.grey.shade700,
                            size: width * 0.05,
                          ),
                          SizedBox(width: width * 0.02),
                          Text(
                            "All",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          if (selectedGender == null)
                            Icon(
                              Icons.check,
                              color: const Color(0xFF3366CC),
                              size: width * 0.05,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                        selectedGender = "Male";
                        _applyFilters();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      child: Row(
                        children: [
                          Icon(
                            Icons.male,
                            color: Colors.blue,
                            size: width * 0.05,
                          ),
                          SizedBox(width: width * 0.02),
                          Text(
                            "Male",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          if (selectedGender == "Male")
                            Icon(
                              Icons.check,
                              color: const Color(0xFF3366CC),
                              size: width * 0.05,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                        selectedGender = "Female";
                        _applyFilters();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      child: Row(
                        children: [
                          Icon(
                            Icons.female,
                            color: Colors.pink,
                            size: width * 0.05,
                          ),
                          SizedBox(width: width * 0.02),
                          Text(
                            "Female",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          if (selectedGender == "Female")
                            Icon(
                              Icons.check,
                              color: const Color(0xFF3366CC),
                              size: width * 0.05,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// This is a placeholder. You'd need to implement this screen properly
class DoctorDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Doctor Details"),
        backgroundColor: Color(0xFF3366CC),
      ),
      body: Center(
        child: Text("Doctor details would go here"),
      ),
    );
  }
}
