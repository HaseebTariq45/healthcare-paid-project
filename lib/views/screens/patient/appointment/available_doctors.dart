import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/appointment_booking_flow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorsScreen extends StatefulWidget {
  final String? specialty;
  final List<Map<String, dynamic>> doctors;

  const DoctorsScreen({
    Key? key, 
    this.specialty,
    this.doctors = const [],
  }) : super(key: key);

  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late List<Map<String, dynamic>> filteredDoctors;
  
  // Filtering options
  int _selectedCategoryIndex = 0;
  String? selectedRating;
  String? selectedLocation;
  bool showOnlineOnly = false;
  bool sortByPriceLowToHigh = false;
  
  // Available filter categories
  final List<String> _categories = ["All", "Cardiology", "Neurology", "Dermatology", "Orthopedics", "ENT", "Pediatrics", "Gynecology", "Ophthalmology", "Dentistry", "Psychiatry", "Pulmonology", "Gastrology"];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Apply initial filters
    filteredDoctors = widget.doctors.isNotEmpty ? 
      List.from(widget.doctors) : 
      _getDefaultDoctors();
      
    if (widget.specialty != null && !_categories.contains(widget.specialty)) {
      // Add the specialty to the categories list if it's not already there
      _categories.add(widget.specialty!);
    }
    
    if (widget.specialty != null) {
      // Find the index of the specialty in the categories list
      _selectedCategoryIndex = _categories.indexOf(widget.specialty!);
      if (_selectedCategoryIndex == -1) {
        _selectedCategoryIndex = 0; // Set to "All" if not found
      }
    }
    
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  List<Map<String, dynamic>> _getDefaultDoctors() {
    // Default list of doctors if none provided
    return [
    {
      "name": "Dr. Rizwan Ahmed",
      "specialty": "Cardiology",
      "rating": "4.7",
      "experience": "8 years",
      "fee": "Rs 1500",
      "location": "CMH Rawalpindi",
        "image": "assets/images/User.png",
      "available": true
    },
    {
      "name": "Dr. Fatima Khan",
      "specialty": "Dentist",
      "rating": "4.9",
      "experience": "12 years",
      "fee": "Rs 2000",
      "location": "PAF Hospital Unit-2",
        "image": "assets/images/User.png",
      "available": true
    },
    {
      "name": "Dr. Asmara Malik",
      "specialty": "Orthopedics",
      "rating": "4.8",
      "experience": "10 years",
      "fee": "Rs 1800",
      "location": "KRL Hospital G9, Islamabad",
        "image": "assets/images/User.png",
      "available": false
    },
    {
      "name": "Dr. Tariq Mehmood",
      "specialty": "Cardiology",
      "rating": "4.6",
      "experience": "15 years",
      "fee": "Rs 2500",
      "location": "Maaroof International Hospital",
        "image": "assets/images/User.png",
      "available": true
    }
  ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
                  _buildCategoryTabs(),
                  Expanded(
                    child: _buildDoctorsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            child: Text(
              widget.specialty != null ? "${widget.specialty} Specialists" : "Available Doctors",
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
                  _applyFilters();
              });
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
    // Show a message when no doctors match the search criteria
    if (filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No doctors found",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting your filters",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
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
          color: Colors.grey.shade100,
          width: 1,
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
                        Text(
                          doctor["specialty"],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 8),
                        Row(
                          children: [
                          Icon(
                              LucideIcons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingStr,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            ),
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
                          
                          const SizedBox(width: 16),
                            Icon(
                              LucideIcons.mapPin,
                            color: Colors.red.shade400,
                            size: 16,
                            ),
                          const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                              location,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  
                  // Online/In-person filter
                  Row(
                    children: [
                      Checkbox(
                        value: showOnlineOnly,
                        onChanged: (value) => setState(() {
                          showOnlineOnly = value!;
                        }),
                        activeColor: const Color(0xFF3366CC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        "Show online doctors only",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
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

  void _applyFilters() {
    setState(() {
      // Start with all doctors
      filteredDoctors = widget.doctors.isNotEmpty ? 
        List.from(widget.doctors) : 
        _getDefaultDoctors();
      
      // Filter by selected tab/category if a specific one is selected
      if (_selectedCategoryIndex != 0) {
        String selectedCategory = _categories[_selectedCategoryIndex];
        filteredDoctors = filteredDoctors.where((doctor) {
          return doctor["specialty"] == selectedCategory;
        }).toList();
      }
      // Or filter by specialty parameter if it was passed directly
      else if (widget.specialty != null) {
        filteredDoctors = filteredDoctors.where((doctor) {
          return doctor["specialty"] == widget.specialty;
        }).toList();
      }
      
      // Then filter by search query if needed
      if (_searchQuery.isNotEmpty) {
        filteredDoctors = filteredDoctors.where((doctor) {
          return doctor["name"].toLowerCase().contains(_searchQuery) ||
                 doctor["specialty"].toLowerCase().contains(_searchQuery) ||
                 (doctor["location"] != null && doctor["location"].toLowerCase().contains(_searchQuery));
      }).toList();
    }
    
    // Apply other filters if set
    if (selectedRating == "4+") {
        filteredDoctors = filteredDoctors.where((doctor) {
          // Handle both string and numeric rating
          var rating = doctor["rating"];
          double ratingValue;
          
          if (rating is String) {
            ratingValue = double.tryParse(rating) ?? 0.0;
          } else if (rating is num) {
            ratingValue = rating.toDouble();
          } else {
            ratingValue = 0.0;
          }
          
          return ratingValue >= 4.0;
      }).toList();
    }
    
    if (selectedLocation != null) {
        filteredDoctors = filteredDoctors.where((doctor) {
          return doctor["location"] != null && doctor["location"].contains(selectedLocation!);
      }).toList();
    }
    
    if (showOnlineOnly) {
        filteredDoctors = filteredDoctors.where((doctor) {
          return doctor["available"] == true;
      }).toList();
    }
    
    if (sortByPriceLowToHigh) {
        try {
          filteredDoctors.sort((a, b) {
            if (!a.containsKey("fee") || !b.containsKey("fee")) {
              return 0;
            }
            String feeA = a["fee"].toString();
            String feeB = b["fee"].toString();
            
            int priceA = int.parse(feeA.replaceAll(RegExp(r'[^0-9]'), ''));
            int priceB = int.parse(feeB.replaceAll(RegExp(r'[^0-9]'), ''));
        return priceA.compareTo(priceB);
      });
        } catch (e) {
          print("Error sorting by price: $e");
        }
    }
    });
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
