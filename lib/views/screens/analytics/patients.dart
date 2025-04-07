import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<Map<String, String>> patients = const [
    {
      "name": "Ali",
      "age": "29 Years",
      "location": "Bhalwal",
      "image": "assets/images/patient_1.png",
    },
    {
      "name": "Fehmida",
      "age": "30 Years",
      "location": "Rahim Yar Khan",
      "image": "assets/images/patient_2.png",
    },
    {
      "name": "Asma",
      "age": "24 Years",
      "location": "Lahore",
      "image": "assets/images/patient_3.png",
    },
    {
      "name": "Sher Bano",
      "age": "33 Years",
      "location": "Risalpur",
      "image": "assets/images/patient_4.png",
    },
    {
      "name": "Naheed",
      "age": "30 Years",
      "location": "Soon Valley, Sakesar",
      "image": "assets/images/patient_5.png",
    },
  ];

  List<String> selectedFilters = [];

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

  List<Map<String, String>> get filteredPatients {
    return patients.where((patient) {
      final matchesSearch = patient["name"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          patient["location"]!.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (selectedFilters.isEmpty) {
        return matchesSearch;
      }
      
      final matchesLocation = selectedFilters.contains("Islamabad") ? 
                              patient["location"] == "Islamabad" : true;
                              
      return matchesSearch && matchesLocation;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Patients"),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            )),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              )),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new patient functionality
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.grey.shade300,
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

  Widget _buildPatientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
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
              filteredPatients[index]["name"]!,
              filteredPatients[index]["age"]!,
              filteredPatients[index]["location"]!,
              filteredPatients[index]["image"]!,
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
        borderRadius: BorderRadius.circular(12),
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
          hintText: "Search patients",
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
            Icons.star_rounded,
            "4 +",
            selectedFilters.contains("4 +"),
            () => toggleFilter("4 +"),
          ),
          _buildFilterButton(
            Icons.location_on_rounded,
            "Islamabad",
            selectedFilters.contains("Islamabad"),
            () => toggleFilter("Islamabad"),
          ),
          _buildFilterButton(
            Icons.calendar_today_rounded,
            "This Month",
            selectedFilters.contains("This Month"),
            () => toggleFilter("This Month"),
          ),
          _buildFilterButton(
            Icons.person_rounded,
            "New",
            selectedFilters.contains("New"),
            () => toggleFilter("New"),
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
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.blue.shade700
                  : (label == "Filters" ? Colors.grey.shade700 : Colors.grey.shade500),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.blue.shade700
                    : (label == "Filters" ? Colors.grey.shade700 : Colors.grey.shade500),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
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
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
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
            child: Row(
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
                      Text(
                        age,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(width: 4),
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
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
