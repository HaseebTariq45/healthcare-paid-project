import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  // User profile data structure optimized for doctor profile
  final Map<String, dynamic> profileData = {
    "uid": "",
    "fullName": "",
    "firstName": "",
    "lastName": "",
    "email": "",
    "contact": "",
    "specialty": "",
    "address": "",
    "city": "",
    "about": "",
    "bio": "",
    "experience": "",
    "qualification": "",
    "consultationFee": 0,
    "degreeInstitution": "",
    "degreeCompletionDate": "",
    "imageUrl": "",
    "localImagePath": "assets/images/User.png",
    "medicalLicenseFrontUrl": "",
    "medicalLicenseBackUrl": "",
    "cnicFrontUrl": "",
    "cnicBackUrl": "",
    "degreeImageUrl": "",
    "createdAt": DateTime.now().millisecondsSinceEpoch,
    "updatedAt": DateTime.now().millisecondsSinceEpoch,
  };

  // Controllers for form fields
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _specialtyController; // Will be replaced with dropdown
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _qualificationController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _degreeInstitutionController;
  late TextEditingController _degreeCompletionDateController;
  
  // Dropdowns
  String? _selectedCity;
  String? _selectedSpecialization;
  
  // Lists for dropdowns
  final List<String> _pakistaniCities = [
    "Abbottabad", "Adilpur", "Ahmadpur East", "Alipur", "Arifwala", "Attock",
    "Badin", "Bahawalnagar", "Bahawalpur", "Bannu", "Battagram", "Bhakkar", "Bhalwal", "Bhera", "Bhimbar", "Bhit Shah", "Bhopalwala", "Burewala",
    "Chaman", "Charsadda", "Chichawatni", "Chiniot", "Chishtian", "Chitral", "Chunian",
    "Dadu", "Daharki", "Daska", "Dera Ghazi Khan", "Dera Ismail Khan", "Dinga", "Dipalpur", "Duki",
    "Faisalabad", "Fateh Jang", "Fazilpur", "Fort Abbas",
    "Gambat", "Ghotki", "Gilgit", "Gojra", "Gwadar",
    "Hafizabad", "Hala", "Hangu", "Haripur", "Haroonabad", "Hasilpur", "Haveli Lakha", "Hazro", "Hub", "Hyderabad",
    "Islamabad", 
    "Jacobabad", "Jahanian", "Jalalpur Jattan", "Jampur", "Jamshoro", "Jatoi", "Jauharabad", "Jhelum",
    "Kabirwala", "Kahror Pakka", "Kalat", "Kamalia", "Kamoke", "Kandhkot", "Karachi", "Karak", "Kasur", "Khairpur", "Khanewal", "Khanpur", "Kharian", "Khushab", "Kohat", "Kot Addu", "Kotri", "Kumbar", "Kunri",
    "Lahore", "Laki Marwat", "Larkana", "Layyah", "Liaquatpur", "Lodhran", "Loralai",
    "Mailsi", "Malakwal", "Mandi Bahauddin", "Mansehra", "Mardan", "Mastung", "Matiari", "Mian Channu", "Mianwali", "Mingora", "Mirpur", "Mirpur Khas", "Multan", "Muridke", "Muzaffarabad", "Muzaffargarh",
    "Narowal", "Nawabshah", "Nowshera",
    "Okara",
    "Pakpattan", "Pasrur", "Pattoki", "Peshawar", "Pir Mahal",
    "Quetta",
    "Rahimyar Khan", "Rajanpur", "Rani Pur", "Rawalpindi", "Rohri", "Risalpur",
    "Sadiqabad", "Sahiwal", "Saidu Sharif", "Sakrand", "Samundri", "Sanghar", "Sargodha", "Sheikhupura", "Shikarpur", "Sialkot", "Sibi", "Sukkur", "Swabi", "Swat",
    "Talagang", "Tandlianwala", "Tando Adam", "Tando Allahyar", "Tando Muhammad Khan", "Tank", "Taunsa", "Taxila", "Toba Tek Singh", "Turbat",
    "Vehari",
    "Wah Cantonment", "Wazirabad"
  ];
  
  // List of specialties from DoctorProfilePage2Screen
  final List<Map<String, dynamic>> _specialties = [
    {"name": "Cardiology", "nameUrdu": "امراض قلب", "icon": LucideIcons.heartPulse, "color": Color(0xFFF44336)},
    {"name": "Neurology", "nameUrdu": "امراض اعصاب", "icon": LucideIcons.brain, "color": Color(0xFF2196F3)},
    {"name": "Dermatology", "nameUrdu": "جلدی امراض", "icon": Icons.face_retouching_natural, "color": Color(0xFFFF9800)},
    {"name": "Pediatrics", "nameUrdu": "اطفال", "icon": Icons.child_care, "color": Color(0xFF4CAF50)},
    {"name": "Orthopedics", "nameUrdu": "ہڈیوں کے امراض", "icon": LucideIcons.bone, "color": Color(0xFF9C27B0)},
    {"name": "ENT", "nameUrdu": "کان ناک گلے کے امراض", "icon": LucideIcons.ear, "color": Color(0xFF00BCD4)},
    {"name": "Gynecology", "nameUrdu": "نسائی امراض", "icon": Icons.pregnant_woman, "color": Color(0xFFE91E63)},
    {"name": "Ophthalmology", "nameUrdu": "آنکھوں کے امراض", "icon": LucideIcons.eye, "color": Color(0xFF3F51B5)},
    {"name": "Dentistry", "nameUrdu": "دانتوں کے امراض", "icon": Icons.healing, "color": Color(0xFF607D8B)},
    {"name": "Psychiatry", "nameUrdu": "نفسیاتی امراض", "icon": LucideIcons.brain, "color": Color(0xFF795548)},
    {"name": "Pulmonology", "nameUrdu": "پھیپھڑوں کے امراض", "icon": Icons.air, "color": Color(0xFF009688)},
    {"name": "Gastrology", "nameUrdu": "معدے کے امراض", "icon": Icons.local_dining, "color": Color(0xFFFF5722)},
  ];
  
  // Validation errors
  final Map<String, bool> fieldErrors = {
    "fullName": false,
    "email": false,
    "contact": false,
    "specialty": false,
    "address": false,
    "city": false,
    "bio": false,
    "experience": false,
    "qualification": false,
    "consultationFee": false,
    "degreeInstitution": false,
    "degreeCompletionDate": false,
  };

  File? _selectedImage;
  File? _selectedMedicalLicenseFront;
  File? _selectedMedicalLicenseBack;
  File? _selectedCNICFront;
  File? _selectedCNICBack;
  File? _selectedDegreeImage;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Initialize controllers with current data
  void _initializeControllers() {
    _fullNameController = TextEditingController(text: profileData["fullName"]);
    _emailController = TextEditingController(text: profileData["email"]);
    _contactController = TextEditingController(text: profileData["contact"]);
    _specialtyController = TextEditingController(text: profileData["specialty"]);
    _addressController = TextEditingController(text: profileData["address"]);
    _bioController = TextEditingController(text: profileData["bio"]);
    _experienceController = TextEditingController(text: profileData["experience"]);
    _qualificationController = TextEditingController(text: profileData["qualification"]);
    _consultationFeeController = TextEditingController(
      text: profileData["consultationFee"] > 0 
        ? "Rs ${profileData["consultationFee"]}" 
        : ""
    );
    _degreeInstitutionController = TextEditingController(text: profileData["degreeInstitution"]);
    _degreeCompletionDateController = TextEditingController(text: profileData["degreeCompletionDate"]);
    
    // Initialize dropdowns
    _selectedCity = profileData["city"].isNotEmpty ? profileData["city"] : null;
    _selectedSpecialization = profileData["specialty"].isNotEmpty ? profileData["specialty"] : null;
  }
  
  // Simulate loading profile from Firebase
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }
      
      // Get user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception("User profile not found");
      }
      
      final userData = userDoc.data()!;
      profileData["uid"] = user.uid;
      profileData["email"] = userData["email"] ?? user.email ?? "";
      profileData["contact"] = userData["phoneNumber"] ?? "";
      profileData["fullName"] = userData["fullName"] ?? "";
      
      // Split fullName into firstName and lastName if needed
      if (profileData["fullName"].isNotEmpty && 
          (userData["firstName"] == null || userData["lastName"] == null)) {
        List<String> nameParts = profileData["fullName"].split(" ");
        if (nameParts.length > 1) {
          profileData["firstName"] = nameParts[0];
          profileData["lastName"] = nameParts.sublist(1).join(" ");
        } else {
          profileData["firstName"] = profileData["fullName"];
          profileData["lastName"] = "";
        }
      } else {
        profileData["firstName"] = userData["firstName"] ?? "";
        profileData["lastName"] = userData["lastName"] ?? "";
      }
      
      // Check if user is a doctor
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();
      
      if (doctorDoc.exists) {
        _isDoctor = true;
        final doctorData = doctorDoc.data()!;
        
        // Update profile data with doctor details
        profileData["email"] = doctorData["email"] ?? userData["email"] ?? user.email ?? "";
        profileData["specialty"] = doctorData["specialty"] ?? "";
        profileData["bio"] = doctorData["bio"] ?? "";
        profileData["experience"] = doctorData["experience"]?.toString() ?? "";
        profileData["qualification"] = doctorData["qualifications"]?.isNotEmpty == true 
            ? doctorData["qualifications"][0] 
            : "";
        profileData["consultationFee"] = doctorData["fee"] ?? 0;
        
        // Extract education information if available
        if (doctorData["education"] != null && doctorData["education"].isNotEmpty) {
          final education = doctorData["education"][0];
          profileData["degreeInstitution"] = education["institution"] ?? "";
          profileData["degreeCompletionDate"] = education["completionDate"] ?? "";
        }
        
        // Image URLs
        profileData["imageUrl"] = doctorData["profileImageUrl"] ?? "";
        profileData["medicalLicenseFrontUrl"] = doctorData["medicalLicenseFrontUrl"] ?? "";
        profileData["medicalLicenseBackUrl"] = doctorData["medicalLicenseBackUrl"] ?? "";
        profileData["cnicFrontUrl"] = doctorData["cnicFrontUrl"] ?? "";
        profileData["cnicBackUrl"] = doctorData["cnicBackUrl"] ?? "";
        profileData["degreeImageUrl"] = doctorData["degreeImageUrl"] ?? "";
        
        // Address information
        profileData["address"] = doctorData["address"] ?? "";
        profileData["city"] = doctorData["city"] ?? "";
      } else {
        // Regular user information
        profileData["address"] = userData["address"] ?? "";
        profileData["imageUrl"] = userData["profileImageUrl"] ?? "";
      }
      
      // Initialize controllers after data is loaded
      _initializeControllers();
    } catch (e) {
      // Handle error
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _specialtyController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _qualificationController.dispose();
    _consultationFeeController.dispose();
    _degreeInstitutionController.dispose();
    _degreeCompletionDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Profile",
            style: GoogleFonts.poppins(
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(64, 124, 226, 1),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with gradient background
              Container(
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
                padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
                child: Column(
                  children: [
                    // Profile image with edit button
                    Hero(
                      tag: 'profileImage',
                      child: Stack(
                        alignment: Alignment.bottomRight,
                    children: [
                          Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                              image: DecorationImage(
                                image: _getProfileImage(),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showImageSourceOptions,
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                LucideIcons.camera,
                                color: Color.fromRGBO(64, 124, 226, 1),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
              ),
              
              // Form fields
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      "Personal Information",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: "Full Name",
                      controller: _fullNameController,
                      icon: LucideIcons.user,
                      errorKey: "fullName",
                    ),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: "Email Address",
                      controller: _emailController,
                      icon: LucideIcons.mail,
                      errorKey: "email",
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true, // Email should be managed by Firebase Auth
                    ),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: "Contact Number",
                      controller: _contactController,
                      icon: LucideIcons.phone,
                      errorKey: "contact",
                      keyboardType: TextInputType.phone,
                    ),
                    
                    if (_isDoctor) ...[
                      SizedBox(height: 24),
                      
                      Text(
                        "Professional Information",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      _buildSpecializationDropdown(),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                        label: "Years of Experience",
                        controller: _experienceController,
                        icon: LucideIcons.calendar,
                        errorKey: "experience",
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      
                      _buildInputField(
                        label: "Highest Qualification",
                        controller: _qualificationController,
                        icon: LucideIcons.graduationCap,
                        errorKey: "qualification",
                      ),
                      SizedBox(height: 16),
                      
                      _buildInputField(
                        label: "Consultation Fee",
                        controller: _consultationFeeController,
                        icon: LucideIcons.banknote,
                        errorKey: "consultationFee",
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            // Format as currency
                            String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (cleanValue.isNotEmpty) {
                              _consultationFeeController.text = 'Rs $cleanValue';
                              _consultationFeeController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _consultationFeeController.text.length),
                              );
                            }
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      
                      _buildInputField(
                        label: "Degree Institution",
                        controller: _degreeInstitutionController,
                        icon: LucideIcons.building2,
                        errorKey: "degreeInstitution",
                      ),
                      SizedBox(height: 16),
                      
                      _buildInputField(
                        label: "Degree Completion Date",
                        controller: _degreeCompletionDateController,
                        icon: LucideIcons.calendar,
                        errorKey: "degreeCompletionDate",
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      SizedBox(height: 16),
                      
                      if (_isDoctor) ...[
                        _buildDocumentUploadSection(),
                    SizedBox(height: 24),
                      ],
                    ],
                    
                    Text(
                      "Additional Information",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: "Address",
                      controller: _addressController,
                      icon: LucideIcons.mapPin,
                      errorKey: "address",
                    ),
                    SizedBox(height: 16),
                    
                    _buildCityDropdown(),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: _isDoctor ? "Professional Bio" : "About Me",
                      controller: _bioController,
                      icon: LucideIcons.info,
                      errorKey: "bio",
                      maxLines: 4,
                    ),
                    
                    SizedBox(height: 30),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get the profile image
  ImageProvider _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (profileData["imageUrl"] != null && profileData["imageUrl"].isNotEmpty) {
      // For Firebase Storage URLs
      return NetworkImage(profileData["imageUrl"]);
    } else {
      // Default or local image
      return AssetImage(profileData["localImagePath"]);
    }
  }

  // Build document upload section for doctor profile
  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Documents",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 16),
        
        _buildDocumentUploadItem(
          title: "Medical License (Front)",
          subtitle: "Upload the front side of your medical license",
          icon: LucideIcons.fileImage,
          file: _selectedMedicalLicenseFront,
          url: profileData["medicalLicenseFrontUrl"],
          onTap: () => _pickDocument('license_front'),
        ),
        
        _buildDocumentUploadItem(
          title: "Medical License (Back)",
          subtitle: "Upload the back side of your medical license",
          icon: LucideIcons.fileImage,
          file: _selectedMedicalLicenseBack,
          url: profileData["medicalLicenseBackUrl"],
          onTap: () => _pickDocument('license_back'),
        ),
        
        _buildDocumentUploadItem(
          title: "CNIC (Front)",
          subtitle: "Upload the front side of your CNIC",
          icon: LucideIcons.idCard,
          file: _selectedCNICFront,
          url: profileData["cnicFrontUrl"],
          onTap: () => _pickDocument('cnic_front'),
        ),
        
        _buildDocumentUploadItem(
          title: "CNIC (Back)",
          subtitle: "Upload the back side of your CNIC",
          icon: LucideIcons.idCard,
          file: _selectedCNICBack,
          url: profileData["cnicBackUrl"],
          onTap: () => _pickDocument('cnic_back'),
        ),
        
        _buildDocumentUploadItem(
          title: "Degree Certificate",
          subtitle: "Upload your degree certificate",
          icon: LucideIcons.fileImage,
          file: _selectedDegreeImage,
          url: profileData["degreeImageUrl"],
          onTap: () => _pickDocument('degree'),
        ),
      ],
    );
  }
  
  // Build document upload item
  Widget _buildDocumentUploadItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    File? file,
    String? url,
  }) {
    final bool hasFile = file != null || (url != null && url.isNotEmpty);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(64, 124, 226, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Color.fromRGBO(64, 124, 226, 1),
                  size: 24,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFile)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.check,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Pick document image
  Future<void> _pickDocument(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        switch (type) {
          case 'license_front':
            _selectedMedicalLicenseFront = File(image.path);
            break;
          case 'license_back':
            _selectedMedicalLicenseBack = File(image.path);
            break;
          case 'cnic_front':
            _selectedCNICFront = File(image.path);
            break;
          case 'cnic_back':
            _selectedCNICBack = File(image.path);
            break;
          case 'degree':
            _selectedDegreeImage = File(image.path);
            break;
        }
      });
    }
  }
  
  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromRGBO(64, 124, 226, 1),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _degreeCompletionDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
  
  // Build the city dropdown
  Widget _buildCityDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(64, 124, 226, 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: fieldErrors["city"]! ? Colors.red : Colors.grey.shade200,
          width: fieldErrors["city"]! ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Text(
              "City",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              canvasColor: Colors.white,
              dividerColor: Colors.transparent,
              shadowColor: Color.fromRGBO(64, 124, 226, 0.2),
            ),
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButtonFormField<String>(
                value: _selectedCity,
                isExpanded: true,
                icon: Icon(
                  LucideIcons.chevronDown,
                  color: Color.fromRGBO(64, 124, 226, 1),
                  size: 18,
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: 350,
                itemHeight: 50,
                elevation: 8,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      LucideIcons.building2,
                      color: Color.fromRGBO(64, 124, 226, 1),
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                hint: Text(
                  "Select City",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                    if (fieldErrors["city"]!) {
                      fieldErrors["city"] = false;
                    }
                  });
                },
                items: _pakistaniCities.map<DropdownMenuItem<String>>((String city) {
                  bool isFirstWithLetter = _pakistaniCities.indexOf(city) == 0 || 
                      _pakistaniCities[_pakistaniCities.indexOf(city) - 1][0] != city[0];
                  
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Row(
                      children: [
                        if (isFirstWithLetter)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(64, 124, 226, 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              city[0],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Color.fromRGBO(64, 124, 226, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        // Checkbox indicator
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _selectedCity == city
                                ? Color.fromRGBO(64, 124, 226, 1)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedCity == city
                                  ? Color.fromRGBO(64, 124, 226, 1)
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: _selectedCity == city
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        
                        Text(
                          city,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _selectedCity == city
                                ? Color.fromRGBO(64, 124, 226, 1)
                                : Colors.black87,
                            fontWeight: _selectedCity == city
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (fieldErrors["city"]!)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12, bottom: 6),
              child: Text(
                "Please select a city",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Build the specialization dropdown
  Widget _buildSpecializationDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(64, 124, 226, 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: fieldErrors["specialty"]! ? Colors.red : Colors.grey.shade200,
          width: fieldErrors["specialty"]! ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Text(
              "Specialization",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedSpecialization,
            isExpanded: true,
            icon: Icon(
              LucideIcons.chevronDown,
              color: Color.fromRGBO(64, 124, 226, 1),
              size: 18,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  LucideIcons.stethoscope,
                  color: Color.fromRGBO(64, 124, 226, 1),
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            hint: Text(
              "Select Specialization",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSpecialization = newValue;
                if (fieldErrors["specialty"]!) {
                  fieldErrors["specialty"] = false;
                }
              });
            },
            items: _specialties.map<DropdownMenuItem<String>>((Map<String, dynamic> specialty) {
              return DropdownMenuItem<String>(
                value: specialty["name"],
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (specialty["color"] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        specialty["icon"] as IconData,
                        color: specialty["color"] as Color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      specialty["name"],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "(${specialty["nameUrdu"]})",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (fieldErrors["specialty"]!)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12, bottom: 6),
              child: Text(
                "Please select a specialization",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String errorKey,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    Function(String)? onChanged,
    Function()? onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: fieldErrors[errorKey]! ? 10.0 : 0.0),
      onEnd: () {
        if (fieldErrors[errorKey]!) {
          setState(() {
            fieldErrors[errorKey] = false;
          });
        }
      },
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * ((value.toInt() % 2 == 0) ? 1 : -1), 0),
          child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: readOnly ? Colors.grey.shade100 : Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: fieldErrors[errorKey]! ? Colors.red : Colors.grey.shade200,
                    width: fieldErrors[errorKey]! ? 1.5 : 1,
                  ),
                ),
                child: TextFormField(
                  controller: controller,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: readOnly ? Colors.grey.shade700 : Color(0xFF333333),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      icon,
                      color: fieldErrors[errorKey]! ? Colors.red : (readOnly ? Colors.grey.shade500 : Color.fromRGBO(64, 124, 226, 1)),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged ?? (value) {
                    // Clear error state
                    if (fieldErrors[errorKey]!) {
                      setState(() {
                        fieldErrors[errorKey] = false;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    
                    if (errorKey == "email" && !_isValidEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    
                    return null;
                  },
                ),
              ),
              if (fieldErrors[errorKey]!)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    errorKey == "email" ? "Please enter a valid email" : "This field is required",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose Option",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            _buildImageSourceOption(
              label: "Take a photo",
              icon: LucideIcons.camera,
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  setState(() {
                    _selectedImage = File(pickedFile.path);
                  });
                }
              },
            ),
            SizedBox(height: 16),
            _buildImageSourceOption(
              label: "Choose from gallery",
              icon: LucideIcons.image,
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (pickedFile != null) {
                  setState(() {
                    _selectedImage = File(pickedFile.path);
                  });
                }
              },
            ),
            if (_selectedImage != null || (profileData["imageUrl"] != null && profileData["imageUrl"].isNotEmpty)) ...[
              SizedBox(height: 16),
              _buildImageSourceOption(
                label: "Remove photo",
                icon: LucideIcons.trash2,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    profileData["imageUrl"] = "";
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Color(0xFFFFEBEE)
              : Color.fromRGBO(64, 124, 226, 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Color(0xFFE53935)
              : Color.fromRGBO(64, 124, 226, 1),
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Color(0xFFE53935) : Color(0xFF333333),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
  
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phone);
  }
  
  Future<void> _saveProfile() async {
    // Reset all error states
    for (var key in fieldErrors.keys) {
      fieldErrors[key] = false;
    }
    
    // Check for empty fields
    bool hasError = false;
    
    // Basic validation
    if (_fullNameController.text.isEmpty) {
      fieldErrors["fullName"] = true;
      hasError = true;
    }
    
    if (_emailController.text.isEmpty) {
      fieldErrors["email"] = true;
      hasError = true;
    } else if (!_isValidEmail(_emailController.text)) {
      fieldErrors["email"] = true;
      hasError = true;
    }
    
    if (_contactController.text.isEmpty) {
      fieldErrors["contact"] = true;
      hasError = true;
    } else if (!_isValidPhone(_contactController.text)) {
      fieldErrors["contact"] = true;
      hasError = true;
    }
    
    if (_addressController.text.isEmpty) {
      fieldErrors["address"] = true;
      hasError = true;
    }
    
    if (_selectedCity == null) {
      fieldErrors["city"] = true;
      hasError = true;
    }
    
    if (_bioController.text.isEmpty) {
      fieldErrors["bio"] = true;
      hasError = true;
    }
    
    // Doctor-specific validation
    if (_isDoctor) {
      if (_selectedSpecialization == null) {
        fieldErrors["specialty"] = true;
        hasError = true;
      }
      
      if (_experienceController.text.isEmpty) {
        fieldErrors["experience"] = true;
        hasError = true;
      }
      
      if (_qualificationController.text.isEmpty) {
        fieldErrors["qualification"] = true;
        hasError = true;
      }
      
      if (_consultationFeeController.text.isEmpty) {
        fieldErrors["consultationFee"] = true;
        hasError = true;
      }
      
      if (_degreeInstitutionController.text.isEmpty) {
        fieldErrors["degreeInstitution"] = true;
        hasError = true;
      }
      
      if (_degreeCompletionDateController.text.isEmpty) {
        fieldErrors["degreeCompletionDate"] = true;
        hasError = true;
      }
    }
    
    // If there are errors, update UI and return
    if (hasError) {
      setState(() {});
      return;
    }
    
    // Show loading state
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }
      
      final firestore = FirebaseFirestore.instance;
      final userId = user.uid;
      
      // Upload profile images if selected
      Map<String, String> imageUrls = {};
      
      try {
        // Make sure Firebase Storage is available
        final storage = FirebaseStorage.instance;
        
      if (_selectedImage != null) {
          try {
            final profileImageRef = storage.ref().child('profileImages/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await profileImageRef.putFile(_selectedImage!);
            imageUrls['profileImageUrl'] = await profileImageRef.getDownloadURL();
          } catch (e) {
            print('Error uploading profile image: $e');
            // Continue with the profile update even if image upload fails
          }
        }
        
        // Upload doctor documents if selected
        if (_isDoctor) {
          if (_selectedMedicalLicenseFront != null) {
            try {
              final ref = storage.ref().child('doctorDocuments/${userId}/medicalLicenseFront_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await ref.putFile(_selectedMedicalLicenseFront!);
              imageUrls['medicalLicenseFrontUrl'] = await ref.getDownloadURL();
            } catch (e) {
              print('Error uploading medical license front: $e');
            }
          }
          
          if (_selectedMedicalLicenseBack != null) {
            try {
              final ref = storage.ref().child('doctorDocuments/${userId}/medicalLicenseBack_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await ref.putFile(_selectedMedicalLicenseBack!);
              imageUrls['medicalLicenseBackUrl'] = await ref.getDownloadURL();
            } catch (e) {
              print('Error uploading medical license back: $e');
            }
          }
          
          if (_selectedCNICFront != null) {
            try {
              final ref = storage.ref().child('doctorDocuments/${userId}/cnicFront_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await ref.putFile(_selectedCNICFront!);
              imageUrls['cnicFrontUrl'] = await ref.getDownloadURL();
            } catch (e) {
              print('Error uploading CNIC front: $e');
            }
          }
          
          if (_selectedCNICBack != null) {
            try {
              final ref = storage.ref().child('doctorDocuments/${userId}/cnicBack_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await ref.putFile(_selectedCNICBack!);
              imageUrls['cnicBackUrl'] = await ref.getDownloadURL();
            } catch (e) {
              print('Error uploading CNIC back: $e');
            }
          }
          
          if (_selectedDegreeImage != null) {
            try {
              final ref = storage.ref().child('doctorDocuments/${userId}/degree_${DateTime.now().millisecondsSinceEpoch}.jpg');
              await ref.putFile(_selectedDegreeImage!);
              imageUrls['degreeImageUrl'] = await ref.getDownloadURL();
            } catch (e) {
              print('Error uploading degree image: $e');
            }
          }
        }
      } catch (e) {
        print('Firebase Storage error: $e');
        // Continue with profile update even if all image uploads fail
      }
      
      // Update user data
      Map<String, dynamic> userData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phoneNumber': _contactController.text,
        'address': _addressController.text,
        'city': _selectedCity,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add image URL if available
      if (imageUrls.containsKey('profileImageUrl')) {
        userData['profileImageUrl'] = imageUrls['profileImageUrl'];
      }
      
      // Update user document
      await firestore.collection('users').doc(userId).update(userData);
      
      // Update doctor data if applicable
      if (_isDoctor) {
        // Parse fee value
        int fee = 0;
        if (_consultationFeeController.text.isNotEmpty) {
          final feeString = _consultationFeeController.text.replaceAll(RegExp(r'[^0-9]'), '');
          fee = int.tryParse(feeString) ?? 0;
        }
        
        Map<String, dynamic> doctorData = {
          'fullName': _fullNameController.text,
          'specialty': _selectedSpecialization,
          'experience': _experienceController.text,
          'qualifications': [_qualificationController.text],
          'fee': fee,
          'bio': _bioController.text,
          'address': _addressController.text,
          'city': _selectedCity,
          'education': [
            {
              'degree': _qualificationController.text,
              'institution': _degreeInstitutionController.text,
              'completionDate': _degreeCompletionDateController.text,
            }
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Add image URLs if available
        imageUrls.forEach((key, value) {
          doctorData[key] = value;
        });
        
        // Update doctor document
        await firestore.collection('doctors').doc(userId).update(doctorData);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      
      // Pop back to previous screen
      Navigator.pop(context);
      
    } catch (e) {
      // Handle error
      print('Error saving profile: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add save button widget
  Widget _buildSaveButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading 
          ? CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
              "Save Changes",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
                ),
                SizedBox(width: 8),
                Icon(LucideIcons.check, size: 20),
              ],
            ),
      ),
    );
  }
}

