import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/set_location.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorsScreen extends StatefulWidget {
  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> with SingleTickerProviderStateMixin {
  String? selectedRating;
  String? selectedLocation;
  String? selectedSpeciality;
  bool isFilterVisible = false;
  bool showOnlineOnly = false;
  bool sortByPriceLowToHigh = false;
  late TabController _tabController;
  final List<String> _categories = ["All", "Cardiologist", "Dentist", "Orthopedic", "Neurologist"];
  int _selectedCategoryIndex = 0;
  
  // Add search controller and filtered doctors list
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _filteredDoctors = [];

  final List<Map<String, dynamic>> doctors = [
    {
      "name": "Dr. Rizwan Ahmed",
      "specialty": "Cardiologist",
      "rating": "4.7",
      "experience": "8 years",
      "fee": "Rs 1500",
      "location": "CMH Rawalpindi",
      "image": "assets/images/patient_1.png",
      "available": true
    },
    {
      "name": "Dr. Fatima Khan",
      "specialty": "Dentist",
      "rating": "4.9",
      "experience": "12 years",
      "fee": "Rs 2000",
      "location": "PAF Hospital Unit-2",
      "image": "assets/images/patient_2.png",
      "available": true
    },
    {
      "name": "Dr. Asmara Malik",
      "specialty": "Orthopedic",
      "rating": "4.8",
      "experience": "10 years",
      "fee": "Rs 1800",
      "location": "KRL Hospital G9, Islamabad",
      "image": "assets/images/patient_3.png",
      "available": false
    },
    {
      "name": "Dr. Tariq Mehmood",
      "specialty": "Cardiologist",
      "rating": "4.6",
      "experience": "15 years",
      "fee": "Rs 2500",
      "location": "Maaroof International Hospital",
      "image": "assets/images/patient_4.png",
      "available": true
    },
    {
      "name": "Dr. Fahad Akram",
      "specialty": "Eye Specialist",
      "rating": "4.5",
      "experience": "6 years",
      "fee": "Rs 1200",
      "location": "LRBT Shahpur Saddar, Sargodha",
      "image": "assets/images/patient_5.png",
      "available": true
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _filteredDoctors = List.from(doctors);
    
    // Add listener to search controller
    _searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDoctors);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFilterVisibility() {
    setState(() {
      isFilterVisible = !isFilterVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchAndFilterRow(),
                  SizedBox(height: 16),
                  _buildCategoryTabs(),
                  SizedBox(height: 10),
                  if (isFilterVisible) _buildFilterOptions(),
                  Expanded(
                    child: _buildDoctorsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, 25),
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
            color: Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 40),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "Find Your Doctor",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Book appointments with the best specialists",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
            Expanded(
            child: Container(
              height: 50,
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
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Search doctors or specialties",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      LucideIcons.search,
                      color: Color(0xFF3366CC),
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ) 
                    : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  // This is redundant since we have a listener, but it provides immediate feedback
                  _filterDoctors();
                },
              ),
            ),
          ),
          SizedBox(width: 12),
          InkWell(
            onTap: _toggleFilterVisibility,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isFilterVisible ? Color(0xFF3366CC) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.filter_list,
                color: isFilterVisible ? Colors.white : Color(0xFF3366CC),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 40,
      margin: EdgeInsets.only(left: 20),
              child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
                _tabController.animateTo(index);
                _filterDoctors(); // Filter doctors when category changes
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _selectedCategoryIndex == index
                    ? Color(0xFF3366CC)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedCategoryIndex == index
                      ? Color(0xFF3366CC)
                      : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: _selectedCategoryIndex == index
                    ? [
                        BoxShadow(
                          color: Color(0xFF3366CC).withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _selectedCategoryIndex == index
                      ? Colors.white
                      : Colors.grey.shade700,
                ),
              ),
                    ),
                  );
                },
      ),
    );
  }

  Widget _buildFilterOptions() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filters",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildFilterChip("Rating 4+", selectedRating == "4+", () {
                setState(() => selectedRating = selectedRating == "4+" ? null : "4+");
              }),
              SizedBox(width: 8),
              _buildFilterChip("Online Now", false, () {}),
              SizedBox(width: 8),
              _buildFilterChip("Low to High", false, () {}),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip("Islamabad", selectedLocation == "Islamabad", () {
                setState(() => selectedLocation = selectedLocation == "Islamabad" ? null : "Islamabad");
              }),
              SizedBox(width: 8),
              _buildFilterChip("Rawalpindi", selectedLocation == "Rawalpindi", () {
                setState(() => selectedLocation = selectedLocation == "Rawalpindi" ? null : "Rawalpindi");
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3366CC).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF3366CC) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Color(0xFF3366CC) : Colors.grey.shade700,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 4),
              Icon(
                LucideIcons.check,
                size: 14,
                color: Color(0xFF3366CC),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList() {
    // Show a message when no doctors match the search criteria
    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 70,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              "No doctors found",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try adjusting your search or filters",
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
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = _filteredDoctors[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DoctorDetailsScreen(),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      Container(
                width: 80,
                height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                          image: DecorationImage(
                            image: AssetImage(doctor["image"]),
                fit: BoxFit.cover,
              ),
            ),
                      ),
                      SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    doctor["name"],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: doctor["available"] ? Color(0xFF4CAF50).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    doctor["available"] ? "Available" : "Busy",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: doctor["available"] ? Color(0xFF4CAF50) : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              doctor["specialty"],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                  Row(
                    children: [
                                _buildInfoBadge(
                                  LucideIcons.star,
                                  doctor["rating"],
                                  Color(0xFFFFC107),
                                ),
                                SizedBox(width: 8),
                                _buildInfoBadge(
                                  LucideIcons.briefcase,
                                  doctor["experience"],
                                  Color(0xFF3366CC),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                  Row(
                    children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  color: Colors.grey.shade600,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                      Expanded(
                                  child: Text(
                                    doctor["location"],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
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
          ],
        ),
      ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        doctor["fee"],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3366CC),
                        ),
                      ),
                      Text(
                        " / Session",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _showAppointmentConfirmationDialog(context, doctor);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3366CC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Book Now",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentConfirmationDialog(BuildContext context, Map<String, dynamic> doctor) {
    // Generate a random appointment date (next 7 days)
    final now = DateTime.now();
    final randomDays = 1 + (now.millisecondsSinceEpoch % 7); // Random number between 1-7
    final appointmentDate = now.add(Duration(days: randomDays));
    
    // Generate a random appointment time (9 AM to 5 PM)
    final randomHour = 9 + (now.millisecondsSinceEpoch % 8); // Random number between 9-16 (9 AM to 4 PM)
    final appointmentTime = TimeOfDay(hour: randomHour, minute: 0);
    
    // Format date and time
    final dateString = "${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}";
    final timeString = "${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')} ${appointmentTime.hour >= 12 ? 'PM' : 'AM'}";
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    color: Color(0xFF4CAF50),
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                
                // Success message
                Text(
                  "Appointment Booked!",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                
                // Doctor info card
                Container(
                  margin: EdgeInsets.symmetric(vertical: 15),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Color(0xFFE6EFFF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Doctor image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(doctor["image"]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      
                      // Doctor info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor["name"],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              doctor["specialty"],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Appointment details
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Color(0xFFD6E4FF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildAppointmentDetailRow(
                        LucideIcons.calendar,
                        "Date",
                        dateString,
                        Color(0xFF3366CC),
                      ),
                      SizedBox(height: 12),
                      _buildAppointmentDetailRow(
                        LucideIcons.clock,
                        "Time",
                        timeString,
                        Color(0xFF3366CC),
                      ),
                      SizedBox(height: 12),
                      _buildAppointmentDetailRow(
                        LucideIcons.mapPin,
                        "Location",
                        doctor["location"],
                        Color(0xFF3366CC),
                      ),
                      SizedBox(height: 12),
                      _buildAppointmentDetailRow(
                        LucideIcons.creditCard,
                        "Fee",
                        doctor["fee"],
                        Color(0xFF3366CC),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Done button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3366CC),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Done",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAppointmentDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Filter doctors based on search query and selected category
  void _filterDoctors() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      
      // Start with all doctors
      _filteredDoctors = List.from(doctors);
      
      // Filter by category if a specific one is selected
      if (_selectedCategoryIndex != 0) {
        String selectedCategory = _categories[_selectedCategoryIndex];
        _filteredDoctors = _filteredDoctors.where((doctor) {
          return doctor["specialty"] == selectedCategory;
        }).toList();
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        _filteredDoctors = _filteredDoctors.where((doctor) {
          return doctor["name"].toLowerCase().contains(_searchQuery) ||
                 doctor["specialty"].toLowerCase().contains(_searchQuery) ||
                 doctor["location"].toLowerCase().contains(_searchQuery);
        }).toList();
      }
      
      // Filter by rating
      if (selectedRating == "4+") {
        _filteredDoctors = _filteredDoctors.where((doctor) {
          return double.parse(doctor["rating"]) >= 4.0;
        }).toList();
      }
      
      // Filter by location
      if (selectedLocation != null) {
        _filteredDoctors = _filteredDoctors.where((doctor) {
          return doctor["location"].contains(selectedLocation!);
        }).toList();
      }
      
      // Filter by online availability
      if (showOnlineOnly) {
        _filteredDoctors = _filteredDoctors.where((doctor) {
          return doctor["available"];
        }).toList();
      }
      
      // Sort by price (low to high)
      if (sortByPriceLowToHigh) {
        _filteredDoctors.sort((a, b) {
          // Extract numeric value from fee strings like "Rs 1500"
          int priceA = int.parse(a["fee"].toString().replaceAll(RegExp(r'[^0-9]'), ''));
          int priceB = int.parse(b["fee"].toString().replaceAll(RegExp(r'[^0-9]'), ''));
          return priceA.compareTo(priceB);
        });
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
