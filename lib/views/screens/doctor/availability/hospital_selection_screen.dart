import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HospitalSelectionScreen extends StatefulWidget {
  final List<String> selectedHospitals;
  
  const HospitalSelectionScreen({
    super.key, 
    required this.selectedHospitals,
  });

  @override
  State<HospitalSelectionScreen> createState() => _HospitalSelectionScreenState();
}

class _HospitalSelectionScreenState extends State<HospitalSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<String> _selectedHospitals;
  bool _isLoading = false;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // City and hospital selection
  String? _selectedCity;
  String? _selectedHospital;
  
  // List of Pakistani cities
  final List<String> _pakistaniCities = [
    "Abbottabad",
    "Bahawalpur",
    "Burewala",
    "Chiniot",
    "Dera Ghazi Khan",
    "Dera Ismail Khan",
    "Faisalabad",
    "Gujranwala",
    "Gujrat",
    "Hafizabad",
    "Hyderabad",
    "Islamabad",
    "Jhang",
    "Kāmoke",
    "Karachi",
    "Kasur",
    "Khanewal",
    "Kohat",
    "Kotri",
    "Lahore",
    "Larkana",
    "Mardan",
    "Mingora",
    "Mirpur Khas",
    "Multan",
    "Muzaffargarh",
    "Nawabshah",
    "Okara",
    "Peshawar",
    "Quetta",
    "Rahim Yar Khan",
    "Rawalpindi",
    "Sadiqabad",
    "Sahiwal",
    "Sargodha",
    "Sheikhupura",
    "Sialkot",
    "Sukkur",
    "Wah Cantonment",
  ];
  
  // Map of hospitals by city with IDs
  final Map<String, List<Map<String, dynamic>>> _hospitalsByCity = {
    "Karachi": [
      {"id": "9RyNeGpGPbI2uRov4dDo", "name": "Aga Khan University Hospital", "address": "Stadium Road, Karachi"},
      {"id": "LNH45tZjKMqP8s6bD7vE", "name": "Liaquat National Hospital", "address": "National Stadium Road, Karachi"},
      {"id": "SCH23rBnLpQvY9xX5gTz", "name": "South City Hospital", "address": "Clifton, Karachi"},
      {"id": "ZHA78kCfJsRdW1vV3mUy", "name": "Ziauddin Hospital", "address": "North Nazimabad, Karachi"},
      {"id": "JPM12qAeHgBtF4pZ8xNw", "name": "Jinnah Postgraduate Medical Centre", "address": "Rafiqui Shaheed Road, Karachi"},
      {"id": "OMH56aSdErFnG2cX9hTv", "name": "OMI Hospital", "address": "PECHS, Karachi"},
      {"id": "INH34bPmQzKjL7nR6wUs", "name": "Indus Hospital", "address": "Korangi, Karachi"},
    ],
    "Lahore": [
      {"id": "SKM89cVbNmKpL3qS7xZr", "name": "Shaukat Khanum Memorial Cancer Hospital", "address": "Johar Town, Lahore"},
      {"id": "MYH23eDfThJkL9pR4wBs", "name": "Mayo Hospital", "address": "Nila Gumbad, Lahore"},
      {"id": "DCH67gHjKlMnP5qR2sTu", "name": "Doctors Hospital", "address": "Canal Bank, Lahore"},
      {"id": "ITF12aZxCvBnM3pQ9dSe", "name": "Ittefaq Hospital", "address": "Bedian Road, Lahore"},
      {"id": "HLH45fGhJkLmN7pQ2rSt", "name": "Hameed Latif Hospital", "address": "Ferozepur Road, Lahore"},
      {"id": "NTH78jKlMnP5qR2sTuV", "name": "National Hospital", "address": "Defence, Lahore"},
      {"id": "SZH34aWsEdRfT6yU9iOp", "name": "Sheikh Zayed Hospital", "address": "University Avenue, Lahore"},
    ],
    "Islamabad": [
      {"id": "PIMs23aZxCvBnM4pQ9dW", "name": "Pakistan Institute of Medical Sciences", "address": "G-8/3, Islamabad"},
      {"id": "SHF56gHjKlMnP5qR2sTu", "name": "Shifa International Hospital", "address": "Sector H-8/4, Islamabad"},
      {"id": "AMC78jKlMnP5qR2sTuV", "name": "Ali Medical Centre", "address": "F-8 Markaz, Islamabad"},
      {"id": "MRF12aZxCvBnM3pQ9dSe", "name": "Maroof International Hospital", "address": "F-10 Markaz, Islamabad"},
      {"id": "KIH45fGhJkLmN7pQ2rSt", "name": "Kulsum International Hospital", "address": "Blue Area, Islamabad"},
      {"id": "FGH89jKlMnP5qR2sTuV", "name": "Federal Government Services Hospital", "address": "Sector G-6/2, Islamabad"},
    ],
    "Rawalpindi": [
      {"name": "Combined Military Hospital", "address": "Rawalpindi Cantt"},
      {"name": "Holy Family Hospital", "address": "Satellite Town, Rawalpindi"},
      {"name": "Benazir Bhutto Hospital", "address": "Murree Road, Rawalpindi"},
      {"name": "Fauji Foundation Hospital", "address": "New Lalazar, Rawalpindi"},
      {"name": "MH Rawalpindi", "address": "Abid Majeed Road, Rawalpindi"},
    ],
    "Faisalabad": [
      {"name": "Allied Hospital", "address": "Jail Road, Faisalabad"},
      {"name": "DHQ Hospital", "address": "University Road, Faisalabad"},
      {"name": "Faisalabad Institute of Cardiology", "address": "Sector C of People's Colony, Faisalabad"},
      {"name": "National Hospital", "address": "Satiana Road, Faisalabad"},
    ],
    "Multan": [
      {"name": "Nishtar Hospital", "address": "Nishtar Road, Multan"},
      {"name": "Bakhtawar Amin Memorial Hospital", "address": "Northern Bypass, Multan"},
      {"name": "Ibn-e-Sina Hospital", "address": "Abdali Road, Multan"},
      {"name": "Chaudhry Pervaiz Elahi Institute of Cardiology", "address": "Nishtar Road, Multan"},
    ],
    "Peshawar": [
      {"name": "Lady Reading Hospital", "address": "Peshawar City"},
      {"name": "Khyber Teaching Hospital", "address": "University Road, Peshawar"},
      {"name": "Rehman Medical Institute", "address": "Phase 5, Hayatabad, Peshawar"},
      {"name": "Northwest General Hospital", "address": "Phase 5, Hayatabad, Peshawar"},
    ],
    "Quetta": [
      {"name": "Bolan Medical Complex Hospital", "address": "Brewery Road, Quetta"},
      {"name": "Civil Hospital", "address": "Jinnah Road, Quetta"},
      {"name": "Combined Military Hospital", "address": "Quetta Cantt"},
      {"name": "Akram Hospital", "address": "Jinnah Road, Quetta"},
    ],
    "Hyderabad": [
      {"name": "Liaquat University Hospital", "address": "Hyderabad"},
      {"name": "Isra University Hospital", "address": "Hala Naka, Hyderabad"},
      {"name": "Red Crescent Hospital", "address": "Saddar, Hyderabad"},
      {"name": "Medicare Hospital", "address": "Latifabad, Hyderabad"},
    ],
    // Add more cities and hospitals as needed
  };
  
  // Map to track hospital objects by formatted name
  Map<String, Map<String, dynamic>> _hospitalsByFormattedName = {};
  
  // Add default hospitals for other cities
  void _initializeHospitalsByCity() {
    for (String city in _pakistaniCities) {
      if (!_hospitalsByCity.containsKey(city)) {
        _hospitalsByCity[city] = [
          {"id": "${city.substring(0, 3).toUpperCase()}GH01", "name": "$city General Hospital", "address": "Main Street, $city"},
          {"id": "${city.substring(0, 3).toUpperCase()}MC02", "name": "$city Medical Center", "address": "City Center, $city"},
          {"id": "${city.substring(0, 3).toUpperCase()}CH03", "name": "$city Central Hospital", "address": "Downtown, $city"},
        ];
      }
    }
    
    // Build hospital lookup map
    for (String city in _hospitalsByCity.keys) {
      for (Map<String, dynamic> hospital in _hospitalsByCity[city]!) {
        final formattedName = _formatHospitalName(hospital['name'], city);
        _hospitalsByFormattedName[formattedName] = {
          'id': hospital['id'],
          'name': hospital['name'],
          'city': city,
        };
      }
    }
  }
  
  @override
  void initState() {
    super.initState();
    _selectedHospitals = List.from(widget.selectedHospitals);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
    
    _initializeHospitalsByCity();
    
    // Load hospitals from Firestore
    _loadHospitalsFromFirestore();
  }
  
  // Load doctor's selected hospitals from Firestore
  Future<void> _loadHospitalsFromFirestore() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user ID
      final String? doctorId = _auth.currentUser?.uid;
      
      if (doctorId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get doctor's hospital associations from Firestore
      final associationsSnapshot = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      if (associationsSnapshot.docs.isNotEmpty) {
        // Extract hospital names from the documents
        final List<String> hospitalNames = associationsSnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['hospitalName'] as String)
            .toList();
        
        if (mounted) {
          setState(() {
            // Replace any initially passed hospitals with those from Firestore
            _selectedHospitals = hospitalNames;
            _isLoading = false;
          });
        }
      } else {
        // No hospitals found in Firestore, keep the ones passed to the widget
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading hospitals from Firestore: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Format hospital name with city
  String _formatHospitalName(String hospitalName, String city) {
    return "$hospitalName, $city";
  }

  // Add hospital to selection
  void _addHospital() {
    if (_selectedCity == null || _selectedHospital == null) return;
    
    final fullHospitalName = _formatHospitalName(_selectedHospital!, _selectedCity!);
    
    if (!_selectedHospitals.contains(fullHospitalName)) {
      setState(() {
        _selectedHospitals.add(fullHospitalName);
      });
    }
    
    // Reset selection for next addition
    setState(() {
      _selectedHospital = null;
    });
  }
  
  // Remove hospital from selection
  void _removeHospital(String hospital) {
    setState(() {
      _selectedHospitals.remove(hospital);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextButton.icon(
            onPressed: _isLoading ? null : _saveSelection,
              icon: Icon(
                LucideIcons.save,
                color: Color(0xFF1E74FD),
                size: 18,
              ),
              label: Text(
              "Save",
              style: GoogleFonts.poppins(
                  fontSize: 14,
                fontWeight: FontWeight.w600,
                  color: Color(0xFF1E74FD),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        title: Text(
          "Hospital Selection",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient and design elements
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E74FD),
                  Color(0xFF1E3A8A),
                ],
              ),
              ),
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Title and info card
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
                    child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E74FD),
                                    Color(0xFF1E3A8A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                                      child: Icon(
                                        LucideIcons.building2,
                                color: Colors.white,
                                size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                    "Hospital Affiliations",
                                      style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E3A8A),
                                      height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                    "Select where you practice",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5FE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFD1E0FF),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                LucideIcons.info,
                                color: Color(0xFF1E74FD),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                  "This will allow patients to book appointments with you at your selected locations.",
                                            style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                          ),
                                    ),
                                  ],
                                ),
                              ),
                ),
                
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Container(
                                        color: Colors.white,
                      child: _buildMainContent(),
                    ),
                  ),
                              ),
                            ],
                          ),
                        ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E74FD),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        "Saving...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E74FD),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Color(0xFF1E74FD).withOpacity(0.4),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Save Selections",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 25, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City selector
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            color: Color(0xFF1E74FD),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Select City",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFD1E0FF),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          hint: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              "Select a city",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E74FD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E74FD),
                              size: 20,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: _pakistaniCities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(
                                city,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                              _selectedHospital = null; // Reset hospital selection
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Hospital selector
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.building2,
                            color: Color(0xFF1E74FD),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Select Hospital",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFD1E0FF),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          value: _selectedHospital,
                          isExpanded: true,
                          hint: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              _selectedCity == null 
                                  ? "Select a city first" 
                                  : "Select a hospital in ${_selectedCity!}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E74FD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E74FD),
                              size: 20,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: _selectedCity == null 
                              ? null 
                              : _hospitalsByCity[_selectedCity]!.map((Map<String, dynamic> hospital) {
                                  return DropdownMenuItem<String>(
                                    value: hospital['name'],
                                    child: Text(
                                      hospital['name']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          onChanged: _selectedCity == null 
                              ? null 
                              : (String? newValue) {
                                  setState(() {
                                    _selectedHospital = newValue;
                                  });
                                },
                        ),
                      ),
                    ),
                  ),
                  
                  // Add Button
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ElevatedButton.icon(
                      onPressed: (_selectedCity == null || _selectedHospital == null) 
                          ? null 
                          : _addHospital,
                      icon: Icon(LucideIcons.plus, size: 18),
                      label: Text(
                        "Add To My Hospitals",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E74FD),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        elevation: 0,
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Color(0xFFE2E8F0),
                        disabledForegroundColor: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Selected hospitals
            if (_selectedHospitals.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.listChecks,
                      color: Color(0xFF1E74FD),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Selected Hospitals",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E74FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_selectedHospitals.length}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // List of selected hospitals
              ...List.generate(
                _selectedHospitals.length,
                (index) {
                  final hospital = _selectedHospitals[index];
                  List<String> parts = hospital.split(', ');
                  String hospitalName = parts.length > 1 
                      ? parts.sublist(0, parts.length - 1).join(', ') 
                      : hospital;
                  String cityName = parts.length > 1 ? parts.last : "";
                  
                  return AnimatedScale(
                    scale: 1.0,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
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
                        border: Border.all(
                          color: Color(0xFFEDF2F7),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E74FD).withOpacity(0.1),
                                    Color(0xFF1E3A8A).withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF1E74FD).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.building2,
                                color: Color(0xFF1E74FD),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hospitalName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.mapPin,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        cityName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => _removeHospital(hospital),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.trash2,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // Empty state
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(40),
                margin: EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFFEDF2F7),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F5FE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.building2,
                        size: 50,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "No Hospitals Selected",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Choose your city and hospital, then tap 'Add' to include it in your profile.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveSelection() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user ID
      final String? doctorId = _auth.currentUser?.uid;
      
      if (doctorId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get existing hospital associations
      final existingAssociations = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      // Create a batch for better performance
      final batch = _firestore.batch();
      
      // Keep track of which hospitals are already in the database
      final Map<String, DocumentReference> existingHospitalRefs = {};
      
      // Track hospital names that already exist
      final Set<String> existingHospitalNames = {};
      
      // First pass: identify existing hospitals
      for (var doc in existingAssociations.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final hospitalName = data['hospitalName'] as String;
        existingHospitalRefs[hospitalName] = doc.reference;
        existingHospitalNames.add(hospitalName);
      }
      
      // Second pass: remove hospitals that are no longer selected
      for (String hospitalName in existingHospitalNames) {
        if (!_selectedHospitals.contains(hospitalName)) {
          // This hospital was removed by the user, so delete it
          batch.delete(existingHospitalRefs[hospitalName]!);
        }
      }
      
      // Third pass: add new hospital associations that don't already exist
      for (String hospitalName in _selectedHospitals) {
        if (!existingHospitalNames.contains(hospitalName)) {
          // This is a new hospital selection, add it
          final hospitalData = _hospitalsByFormattedName[hospitalName];
          
          if (hospitalData != null) {
            final docRef = _firestore.collection('doctor_hospitals').doc();
            
            batch.set(docRef, {
              'doctorId': doctorId,
              'hospitalId': hospitalData['id'] ?? 'unknown',
              'hospitalName': hospitalName, // Full name with city
              'city': hospitalData['city'] ?? '',
              'created': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      
      // Commit the batch
      await batch.commit();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success dialog
      bool? shouldReturn = await _showSuccessDialog();
      
      // Return to previous screen if confirmed
      if (shouldReturn == true && mounted) {
      Navigator.pop(context, _selectedHospitals);
      }
    } catch (e) {
      print('Error saving hospital selection: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error dialog
      _showErrorDialog(e.toString());
    }
  }
  
  Future<bool?> _showSuccessDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(0xFF1E74FD),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.building2,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  'Hospitals Updated',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Your hospital selections have been saved successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E74FD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
  }
  
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_rounded,
                    color: Color(0xFFEF4444),
                    size: 40,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to save hospital selections. Please try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E74FD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
  }
} 