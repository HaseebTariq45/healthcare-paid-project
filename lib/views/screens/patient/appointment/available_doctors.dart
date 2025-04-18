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
        // Try to get user data from patients collection
        var patientDoc = await _firestore.collection('patients').doc(user.uid).get();
        
        // If not found in patients, try users collection
        if (!patientDoc.exists) {
          patientDoc = await _firestore.collection('users').doc(user.uid).get();
        }
        
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
      
      // City filter needs to be applied post-query as it's based on hospital data
      // We cannot directly filter by city in the doctors collection
      
      // Apply rating filter - this needs to be handled post-query
      // since Firestore doesn't support range queries on different fields
      
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
        bool isInUserCity = false;
        
        // For each hospital, get today's availability
        for (var hospitalDoc in hospitalsQuery.docs) {
          final hospitalData = hospitalDoc.data();
          final hospitalId = hospitalData['hospitalId'];
          final hospitalName = hospitalData['hospitalName'] ?? 'Unknown Hospital';
          final hospitalCity = hospitalData['city'] ?? '';
          
          // Check if hospital is in user's city
          if (userCity != null && hospitalCity.toLowerCase() == userCity!.toLowerCase()) {
            isInUserCity = true;
          }
          
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
            'city': hospitalCity,
            'availableToday': timeSlots.isNotEmpty,
            'timeSlots': timeSlots,
          });
        }
        
        // Skip this doctor if we're filtering by city and they're not in the user's city
        if (showOnlyInMyCity && !isInUserCity) {
          continue;
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
          'city': hospitalsList.isNotEmpty ? hospitalsList.first['city'] : '',
          'image': doctorData['profileImageUrl'] ?? "assets/images/User.png",
          'available': isAvailableToday,
          'hospitals': hospitalsList,
          'gender': doctorData['gender'] ?? 'Not specified',
          'isInUserCity': isInUserCity,
        });
      }
      
      // Apply client-side filters
      List<Map<String, dynamic>> result = List.from(doctorsList);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((doctor) {
        return doctor['name'].toString().toLowerCase().contains(_searchQuery) ||
               doctor['specialty'].toString().toLowerCase().contains(_searchQuery) ||
               doctor['location'].toString().toLowerCase().contains(_searchQuery);
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
    
    // Apply location filter
    if (selectedLocation != null) {
      result = result.where((doctor) {
        // Check hospitals list for location match
        if (doctor.containsKey('hospitals')) {
          return doctor['hospitals'].any((hospital) => 
            hospital['hospitalName'].toString().contains(selectedLocation!));
        }
        return doctor['location'].toString().contains(selectedLocation!);
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
            _buildHeader(),
            _buildSearchBar(),
            // Only show category tabs if not viewing a specific specialty
            if (!viewingSpecificSpecialty)
              _buildCategoryTabs(),
            // Show loading indicator, error message, or doctor list
            _isLoading 
            ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFF3366CC),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Loading doctors...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
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
                          "Oops! Something went wrong",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchDoctors,
                          icon: Icon(Icons.refresh),
                          label: Text("Try Again"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3366CC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
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
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            viewingSpecificSpecialty ? 
                              "No ${widget.specialty} specialists found" : 
                              "No doctors found",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Try changing your search criteria",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: _buildDoctorsList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF3366CC),
      ),
      child: Row(
        children: [
          GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
              padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
              child: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              children: [
                Flexible(
            child: Text(
              headerTitle,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
                  ),
                ),
                if (selectedGender != null && genderIconTemp != null)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: genderColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          genderIconTemp,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          selectedGender!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                _showFilterDialog();
              },
              child: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF3366CC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade600),
            suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ) 
                    : null,
                  border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10),
              child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categories.length,
                itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
                    onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
              // Call the asynchronous filter method
              _applyFilters();
            },
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: _selectedCategoryIndex == index
                      ? const Color(0xFF3366CC)
                      : const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(20),
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
                  fontSize: 14,
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

  Widget _buildDoctorsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = filteredDoctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(doctor["image"]),
                      ),
                const SizedBox(width: 16),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isAvailable) // Check if doctor is available
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Online",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              doctor["specialty"],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Display gender
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: genderColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    genderIcon,
                                    size: 12,
                                    color: genderColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    gender,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: genderColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                        Row(
                          children: [
                          _buildRatingBar(ratingStr),
                          const SizedBox(width: 16),
                          Icon(
                              LucideIcons.briefcase,
                            color: const Color(0xFF3366CC),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            experienceStr,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                            LucideIcons.banknote,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fee,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                        ),
                        Spacer(),
                            Icon(
                            LucideIcons.mapPin,
                            color: isInUserCity ? Colors.blue.shade600 : Colors.orange.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    location,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInUserCity)
                                  Container(
                                    margin: EdgeInsets.only(left: 4),
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Local",
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
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

  Widget _buildRatingBar(String ratingStr) {
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade800,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
                ),
              ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                        "Filter Doctors",
                          style: GoogleFonts.poppins(
                          fontSize: 18,
                            fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                          ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Rating filter
                        Text(
                    "Rating",
                          style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                          ),
                        ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildFilterChip(
                        "All",
                        selectedRating == null,
                        () => setState(() {
                          selectedRating = null;
                        }),
                      ),
                      _buildFilterChip(
                        "4+",
                        selectedRating == "4+",
                        () => setState(() {
                          selectedRating = "4+";
                        }),
                        ),
                      ],
                    ),
                  const SizedBox(height: 15),
                  
                  // Gender filter
                  Text(
                    "Gender",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildFilterChip(
                        "All",
                        selectedGender == null,
                        () => setState(() {
                          selectedGender = null;
                        }),
                      ),
                      _buildFilterChip(
                        "Male",
                        selectedGender == "Male",
                        () => setState(() {
                          selectedGender = "Male";
                        }),
                      ),
                      _buildFilterChip(
                        "Female",
                        selectedGender == "Female",
                        () => setState(() {
                          selectedGender = "Female";
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // City filter
                  if (userCity != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Location",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: showOnlyInMyCity,
                              onChanged: (value) => setState(() {
                                showOnlyInMyCity = value!;
                              }),
                              activeColor: const Color(0xFF3366CC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Doctors in my city ($userCity)",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  
                  // Sort by price
                  Row(
                    children: [
                      Checkbox(
                        value: sortByPriceLowToHigh,
                        onChanged: (value) => setState(() {
                          sortByPriceLowToHigh = value!;
                        }),
                        activeColor: const Color(0xFF3366CC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        "Sort by price: Low to High",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                        "Apply Filters",
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
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3366CC) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3366CC) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
            style: GoogleFonts.poppins(
            fontSize: 14,
              fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
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
