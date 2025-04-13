import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../services/cache_service.dart';

// Document type enum for upload functionality
enum DocumentType { identification, medical }

class PatientDetailProfileScreen extends StatefulWidget {
  final String? userId; // Add userId parameter to fetch specific user data
  final String? name;
  final String? age;
  final String? bloodGroup;
  final String? phoneNumber;
  final List<String>? allergies;
  final List<String>? diseases;

  const PatientDetailProfileScreen({
    super.key,
    this.userId,
    this.name,
    this.age,
    this.bloodGroup,
    this.phoneNumber,
    this.allergies,
    this.diseases,
  });

  @override
  State<PatientDetailProfileScreen> createState() => _PatientDetailProfileScreenState();
}

class _PatientDetailProfileScreenState extends State<PatientDetailProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';

  // Patient data fields
  late String name;
  late String age;
  late String bloodGroup;
  late String phoneNumber;
  String cnic = "";
  List<String> allergies = [];
  List<String> diseases = [];
  String? disability;
  String? height;
  String? weight;
  String? email;
  String? address;
  String? city;
  String? state;
  String? country;
  String? zipCode;
  String? notes;
  bool profileComplete = false;
  
  // Add patientData map to store the complete patient data
  Map<String, dynamic> patientData = {};
  
  // Image URLs
  String? profileImageUrl;
  String? medicalReport1Url;
  String? medicalReport2Url;
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  static const String _patientProfileCacheKey = 'patient_profile_details_data';

  // Categorized diseases for detailed view
  final Map<String, List<String>> diseasesMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize with widget values if provided
    name = widget.name ?? "Loading...";
    age = widget.age ?? "";
    bloodGroup = widget.bloodGroup ?? "";
    phoneNumber = widget.phoneNumber ?? "";
    allergies = widget.allergies ?? [];
    diseases = widget.diseases ?? [];
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Try to load data from cache first
    await _loadCachedData();
    
    // Then fetch fresh data from Firestore
    _fetchPatientData();
  }

  Future<void> _loadCachedData() async {
    try {
      // Use a longer maxAge for patient profile data (1 day)
      final cachedData = await CacheService.getData(_patientProfileCacheKey, maxAge: CacheService.longCacheTime);
      
      if (cachedData != null) {
        setState(() {
          // Store the complete data
          patientData = cachedData;
          
          name = cachedData['fullName'] ?? cachedData['name'] ?? "No Name";
          email = cachedData['email'] ?? "";
          phoneNumber = cachedData['phoneNumber'] ?? "";
          cnic = cachedData['cnic'] ?? "";
          
          // Address Info
          address = cachedData['address'] ?? "";
          city = cachedData['city'] ?? "";
          state = cachedData['state'] ?? "";
          country = cachedData['country'] ?? "";
          zipCode = cachedData['zipCode'] ?? "";
          
          // Medical Info
          age = cachedData['age']?.toString() ?? "";
          bloodGroup = cachedData['bloodGroup'] ?? "";
          height = cachedData['height']?.toString() ?? "";
          weight = cachedData['weight']?.toString() ?? "";
          
          // Handle list data
          if (cachedData['allergies'] != null) {
            if (cachedData['allergies'] is List) {
              allergies = List<String>.from(cachedData['allergies']);
            } else if (cachedData['allergies'] is String) {
              allergies = json.decode(cachedData['allergies']).cast<String>();
            }
          }
          
          if (cachedData['diseases'] != null) {
            if (cachedData['diseases'] is List) {
              diseases = List<String>.from(cachedData['diseases']);
            } else if (cachedData['diseases'] is String) {
              diseases = json.decode(cachedData['diseases']).cast<String>();
            }
          }
          
          notes = cachedData['notes'] ?? "";
          disability = cachedData['disability'];
          
          // Image URLs
          profileImageUrl = cachedData['profileImageUrl'];
          medicalReport1Url = cachedData['medicalReport1Url'];
          medicalReport2Url = cachedData['medicalReport2Url'];
          
          // Profile completion status
          profileComplete = cachedData['profileComplete'] ?? false;
          
          // Initialize diseases map
          _categorizeDiseases();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached patient data: $e');
    }
  }

  Future<void> _fetchPatientData() async {
    try {
      setState(() {
        _isRefreshing = true;
      });

      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        // Get user data
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        // Get patient data
        DocumentSnapshot patientSnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .doc(userId)
            .get();
        
        Map<String, dynamic> newData = {};
        
        // Merge user and patient data
        if (userSnapshot.exists) {
          newData.addAll(userSnapshot.data() as Map<String, dynamic>);
        }
        
        if (patientSnapshot.exists) {
          newData.addAll(patientSnapshot.data() as Map<String, dynamic>);
        }
        
        // Save fresh data to cache with longer expiry for medical data
        await CacheService.saveData(_patientProfileCacheKey, newData, expiry: CacheService.longCacheTime);
        
        // Update UI only if data has changed
        if (!_areMapContentsEqual(patientData, newData)) {
          setState(() {
            // Update the complete patient data
            patientData = newData;
            
            name = newData['fullName'] ?? newData['name'] ?? "No Name";
            email = newData['email'] ?? "";
            phoneNumber = newData['phoneNumber'] ?? "";
            cnic = newData['cnic'] ?? "";
            
            // Address Info
            address = newData['address'] ?? "";
            city = newData['city'] ?? "";
            state = newData['state'] ?? "";
            country = newData['country'] ?? "";
            zipCode = newData['zipCode'] ?? "";
            
            // Medical Info
            age = newData['age']?.toString() ?? "";
            bloodGroup = newData['bloodGroup'] ?? "";
            height = newData['height']?.toString() ?? "";
            weight = newData['weight']?.toString() ?? "";
            allergies = List<String>.from(newData['allergies'] ?? []);
            diseases = List<String>.from(newData['diseases'] ?? []);
            notes = newData['notes'] ?? "";
            disability = newData['disability'];
            
            // Image URLs
            profileImageUrl = newData['profileImageUrl'];
            medicalReport1Url = newData['medicalReport1Url'];
            medicalReport2Url = newData['medicalReport2Url'];
            
            // Profile completion status
            profileComplete = newData['profileComplete'] ?? false;
            
            // Initialize diseases map
            _categorizeDiseases();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching patient data: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // Helper method to compare maps (deep comparison)
  bool _areMapContentsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (String key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      
      if (map1[key] is Map && map2[key] is Map) {
        if (!_areMapContentsEqual(
            Map<String, dynamic>.from(map1[key] as Map),
            Map<String, dynamic>.from(map2[key] as Map))) {
          return false;
        }
      } else if (map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }

  void _categorizeDiseases() {
    // This would normally map diseases to categories, but for now we'll put all in one category
    diseasesMap["Current Conditions"] = diseases;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Column(
                    children: [
                      _buildProfileHeader(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            RefreshIndicator(
                              onRefresh: _refreshData,
                              child: _buildSummaryTab(),
                            ),
                            RefreshIndicator(
                              onRefresh: _refreshData,
                              child: _buildMedicalHistoryTab(),
                            ),
                            RefreshIndicator(
                              onRefresh: _refreshData,
                              child: _buildDocumentsTab(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Refresh indicator at bottom
                  if (_isRefreshing)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF3366CC),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Refreshing profile data...",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3366CC),
            const Color(0xFF5E8EF7),
          ],
          stops: const [0.3, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Text(
                "Medical Profile",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Show edit options dialog instead of directly navigating to profile completion
                  _showEditOptionsDialog();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image with edit button
              Stack(
                children: [
                  Hero(
                    tag: 'profileImage',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? NetworkImage(profileImageUrl!) as ImageProvider
                            : const AssetImage("assets/images/User.png"),
                        onBackgroundImageError: (exception, stackTrace) {
                          // If network image fails to load, it will show the default image
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        color: Color(0xFF3366CC),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${age} years",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Blood group badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getBloodGroupColor(bloodGroup),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            bloodGroup,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.check, 
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Active",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF3366CC),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF3366CC),
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            icon: Icon(LucideIcons.clipboardList),
            text: "Summary",
          ),
          Tab(
            icon: Icon(LucideIcons.stethoscope),
            text: "Medical",
          ),
          Tab(
            icon: Icon(LucideIcons.fileText),
            text: "Documents",
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("Personal Information", [
            _buildInfoItem("Full Name", name),
            _buildInfoItem("Email", email ?? "Not provided"),
            _buildInfoItem("Phone", phoneNumber),
            _buildInfoItem("CNIC", cnic ?? "Not provided"),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection("Medical Information", [
            _buildInfoItem("Age", "$age years"),
            _buildInfoItem("Blood Group", bloodGroup),
            _buildInfoItem("Height", height != null ? "$height cm" : "Not provided"),
            _buildInfoItem("Weight", weight != null ? "$weight kg" : "Not provided"),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection("Address Information", [
            _buildInfoItem("Address", address ?? "Not provided"),
            _buildInfoItem("City", city ?? "Not provided"),
          ]),
          if (notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildInfoSection("Medical Notes", [
              _buildInfoItem("Notes", notes ?? ""),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInformationCard() {
    return Container(
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
      child: Column(
        children: [
          if (email != null) 
            _buildContactItem(
              icon: LucideIcons.mail,
              title: "Email",
              value: email!,
              iconColor: Colors.blue.shade600,
            ),
          if (phoneNumber.isNotEmpty) ...[
            if (email != null) const Divider(height: 1),
            _buildContactItem(
              icon: LucideIcons.phone,
              title: "Phone",
              value: phoneNumber,
              iconColor: Colors.green.shade600,
            ),
          ],
          if (address != null) ...[
            const Divider(height: 1),
            _buildContactItem(
              icon: LucideIcons.building,
              title: "Address",
              value: address!,
              iconColor: Colors.orange.shade700,
            ),
          ],
          if (city != null && country != null) ...[
            const Divider(height: 1),
            _buildContactItem(
              icon: LucideIcons.mapPin,
              title: "Location",
              value: "${city}, ${state ?? ''} ${zipCode ?? ''}\n${country}",
              iconColor: Colors.red.shade600,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("Allergies", [
            if (allergies.isEmpty)
              _buildInfoItem("Status", "No known allergies")
            else
              ...allergies.map((allergy) => _buildInfoItem("Allergy", allergy)),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection("Medical Conditions", [
            if (diseases.isEmpty)
              _buildInfoItem("Status", "No medical conditions reported")
            else
              ...diseases.map((disease) => _buildInfoItem("Condition", disease)),
          ]),
          if (notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildInfoSection("Additional Notes", [
              _buildInfoItem("Notes", notes ?? ""),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("Medical Reports", [
            if (medicalReport1Url == null && medicalReport2Url == null)
              _buildInfoItem("Status", "No medical reports uploaded")
            else ...[
              if (medicalReport1Url != null)
                _buildDocumentItem(
                  "Medical Report 1",
                  medicalReport1Url!,
                  onTap: () => _viewDocument(medicalReport1Url!),
                ),
              if (medicalReport2Url != null)
                _buildDocumentItem(
                  "Medical Report 2",
                  medicalReport2Url!,
                  onTap: () => _viewDocument(medicalReport2Url!),
                ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String label, String url, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              url.toLowerCase().endsWith('.pdf') ? LucideIcons.fileText : LucideIcons.image,
              color: const Color(0xFF3366CC),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              LucideIcons.externalLink,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _viewDocument(String url) {
    if (url.toLowerCase().endsWith('.pdf')) {
      // View PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                'Medical Report',
                style: GoogleFonts.poppins(),
              ),
            ),
            body: PDFView(
              filePath: url,
            ),
          ),
        ),
      );
    } else {
      // View Image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                'Medical Report',
                style: GoogleFonts.poppins(),
              ),
            ),
            body: PhotoViewGallery.builder(
              itemCount: 1,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }
  }

  // Document upload functionality
  Future<void> _uploadDocument(DocumentType type) async {
    final source = await _showDocumentSourceDialog();
    if (source == null) return;
    
    String? pickedUrl;
    
    if (source == 'camera') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1000,
      );
      
      if (image != null) {
        pickedUrl = image.path;
      }
    } else if (source == 'gallery') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );
      
      if (image != null) {
        pickedUrl = image.path;
      }
    } else if (source == 'file') {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      
      final XFile? result = await openFile(
        acceptedTypeGroups: [typeGroup],
      );
      
      if (result != null) {
        pickedUrl = result.path;
      }
    }
    
    if (pickedUrl == null) return;
    
    // Here we would normally upload the file to a backend server
    // For now, we'll just show a confirmation and simulate success
    
    // Show uploading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Uploading document..."),
          ],
        ),
      ),
    );
    
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Dismiss uploading dialog
    if (context.mounted) Navigator.of(context).pop();
    
    // Show success message
    final documentTypeName = type == DocumentType.identification ? "identification" : "medical";
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$documentTypeName document uploaded successfully"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // In a real app, you would update the state with the new document
    // and possibly refresh the UI to show the new document
  }
  
  Future<String?> _showDocumentSourceDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Select Document Source",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3366CC),
                  child: Icon(LucideIcons.camera, color: Colors.white, size: 20),
                ),
                title: Text(
                  "Take Photo",
                  style: GoogleFonts.poppins(),
                ),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade600,
                  child: const Icon(LucideIcons.image, color: Colors.white, size: 20),
                ),
                title: Text(
                  "Choose from Gallery",
                  style: GoogleFonts.poppins(),
                ),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade600,
                  child: const Icon(LucideIcons.fileText, color: Colors.white, size: 20),
                ),
                title: Text(
                  "Choose File (PDF)",
                  style: GoogleFonts.poppins(),
                ),
                onTap: () => Navigator.pop(context, 'file'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildVitalStatisticsCard() {
    return Container(
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
      child: Column(
        children: [
          _buildVitalStatItem(
            icon: LucideIcons.droplet,
            title: "Blood Group",
            value: bloodGroup,
            iconColor: _getBloodGroupColor(bloodGroup),
            showGradient: true,
          ),
          const Divider(height: 1),
          _buildVitalStatItem(
            icon: LucideIcons.ruler,
            title: "Height",
            value: "${height} cm",
            iconColor: Colors.blue,
            showGradient: false,
          ),
          const Divider(height: 1),
          _buildVitalStatItem(
            icon: LucideIcons.weight,
            title: "Weight",
            value: "${weight} kg",
            iconColor: Colors.amber.shade700,
            showGradient: false,
          ),
          if (disability != null) ...[
            const Divider(height: 1),
            _buildVitalStatItem(
              icon: LucideIcons.userCog,
              title: "Disability",
              value: disability!,
              iconColor: Colors.purple,
              showGradient: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required bool showGradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: showGradient ? null : iconColor.withOpacity(0.1),
              gradient: showGradient ? LinearGradient(
                colors: [
                  iconColor.withOpacity(0.1),
                  iconColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: showGradient ? [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: Colors.grey.shade300,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesCard() {
    if (allergies.isEmpty) {
      return _buildEmptyCard(
        icon: LucideIcons.info,
        title: "No Allergies",
        subtitle: "No allergies have been recorded",
      );
    }

    return Container(
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
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((allergy) {
              return Chip(
                label: Text(
                  allergy,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConditionsCard() {
    if (diseases.isEmpty) {
      return _buildEmptyCard(
        icon: LucideIcons.stethoscope,
        title: "No Conditions",
        subtitle: "No medical conditions have been recorded",
      );
    }

    return Container(
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
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: diseases.map((disease) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3366CC),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  disease,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiseaseItem(String disease) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF3366CC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Diagnosed: Jan 2023", // This would be dynamic in a real app
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.info,
            color: Colors.grey.shade400,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getBloodGroupColor(String bloodGroup) {
    switch (bloodGroup) {
      case "A+":
      case "A-":
        return Colors.red;
      case "B+":
      case "B-":
        return Colors.blue.shade700;
      case "AB+":
      case "AB-":
        return Colors.purple;
      case "O+":
      case "O-":
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Chronic Diseases":
        return LucideIcons.activity;
      case "Mental Health":
        return LucideIcons.brain;
      case "Autoimmune Disorders":
        return LucideIcons.shieldAlert;
      case "Respiratory Conditions":
        return LucideIcons.wind;
      case "Current Conditions":
        return LucideIcons.stethoscope;
      default:
        return LucideIcons.plus;
    }
  }

  // New method to show edit options dialog
  void _showEditOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Profile Options",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(LucideIcons.camera, color: Color(0xFF3366CC)),
                  title: Text(
                    "Change Profile Photo",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Add photo changing functionality here
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.fileText, color: Color(0xFF3366CC)),
                  title: Text(
                    "Manage Documents",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Set active tab to documents
                    _tabController.animateTo(2);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3366CC),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add a method to refresh data 
  Future<void> _refreshData() async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      await _fetchPatientData();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
} 