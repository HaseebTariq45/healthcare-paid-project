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
    "Karachi",
    "Lahore",
    "Islamabad",
    "Faisalabad",
    "Rawalpindi",
    "Multan",
    "Peshawar",
    "Quetta",
    "Gujranwala",
    "Hyderabad",
    "Sialkot",
    "Bahawalpur",
    "Sargodha",
    "Sukkur",
    "Larkana",
    "Sheikhupura",
    "Rahim Yar Khan",
    "Jhang",
    "Dera Ghazi Khan",
    "Gujrat",
    "Sahiwal",
    "Wah Cantonment",
    "Mardan",
    "Kasur",
    "Okara",
    "Mingora",
    "Nawabshah",
    "Chiniot",
    "Kotri",
    "Kāmoke",
    "Hafizabad",
    "Sadiqabad",
    "Mirpur Khas",
    "Burewala",
    "Kohat",
    "Khanewal",
    "Dera Ismail Khan",
    "Abbottabad",
    "Daska",
    "Muzaffargarh",
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Select Hospitals",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSelection,
            child: Text(
              "Save",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B8FEB),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(64, 124, 226, 0.1),
                  Color.fromRGBO(84, 144, 246, 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color.fromRGBO(64, 124, 226, 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hospital Affiliations",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Select the hospitals where you practice. This will allow patients to book appointments with you at these locations.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // City and Hospital Selector Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select City",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                // City Dropdown
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      hint: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          "Select a city",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      icon: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF2B8FEB),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      items: _pakistaniCities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(
                            city,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
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
                
                SizedBox(height: 20),
                
                Text(
                  "Select Hospital",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                // Hospital Dropdown
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHospital,
                      isExpanded: true,
                      hint: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          _selectedCity == null 
                              ? "Select a city first" 
                              : "Select a hospital in ${_selectedCity!}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      icon: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF2B8FEB),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
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
                                    color: Colors.black87,
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
                
                SizedBox(height: 16),
                
                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_selectedCity == null || _selectedHospital == null) 
                        ? null 
                        : _addHospital,
                    icon: Icon(Icons.add),
                    label: Text(
                      "Add To My Hospitals",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2B8FEB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                if (_selectedHospitals.isNotEmpty) 
                  Text(
                    "Selected Hospitals",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 10),
          
          // Show selected hospitals
          Expanded(
            child: _selectedHospitals.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.building2,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No Hospitals Selected",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Select a city and hospital, then tap 'Add' to include it in your profile.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _selectedHospitals.length,
                    itemBuilder: (context, index) {
                      final hospital = _selectedHospitals[index];
                      List<String> parts = hospital.split(', ');
                      String hospitalName = parts.length > 1 
                          ? parts.sublist(0, parts.length - 1).join(', ') 
                          : hospital;
                      String cityName = parts.length > 1 ? parts.last : "";
                      
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.05 * index, 
                            0.5 + 0.05 * index, 
                            curve: Curves.easeOut
                          ),
                        )),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 8
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF2B8FEB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.building2,
                                color: Color(0xFF2B8FEB),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              hospitalName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              cityName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () => _removeHospital(hospital),
                            ),
                          ),
                        ),
                      );
                    },
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
                backgroundColor: Color(0xFF2B8FEB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
              'hospitalId': hospitalData['id'],
              'hospitalName': hospitalName, // Full name with city
              'city': hospitalData['city'],
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
      bool? shouldReturn = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Hospitals Updated',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your hospital selection has been saved successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2B8FEB),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
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
            contentPadding: EdgeInsets.all(24),
          );
        },
      );
      
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to save hospital selection. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
} 