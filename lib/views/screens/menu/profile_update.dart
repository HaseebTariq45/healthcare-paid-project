import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  // User profile data structure optimized for Firestore
  final Map<String, dynamic> profileData = {
    "uid": "user123", // Will be set from Firebase Auth
    "firstName": "Asmara",
    "lastName": "Singh",
    "email": "dr.asmara@gmail.com",
    "contact": "+91 9876543210",
    "specialty": "General Practitioner",
    "address": "123 Medical Plaza, New Delhi",
    "about": "Experienced general practitioner with over 10 years of practice.",
    "imageUrl": "", // Will be used for Firebase Storage URL
    "localImagePath": "assets/images/User.png", // Temporary for local development
    "createdAt": DateTime.now().millisecondsSinceEpoch,
    "updatedAt": DateTime.now().millisecondsSinceEpoch,
  };

  // Controllers for form fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _specialtyController;
  late TextEditingController _addressController;
  late TextEditingController _aboutController;
  
  // Validation errors
  final Map<String, bool> fieldErrors = {
    "firstName": false,
    "lastName": false,
    "email": false,
    "contact": false,
    "specialty": false,
    "address": false,
    "about": false,
  };

  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Initialize controllers with current data
  void _initializeControllers() {
    _firstNameController = TextEditingController(text: profileData["firstName"]);
    _lastNameController = TextEditingController(text: profileData["lastName"]);
    _emailController = TextEditingController(text: profileData["email"]);
    _contactController = TextEditingController(text: profileData["contact"]);
    _specialtyController = TextEditingController(text: profileData["specialty"]);
    _addressController = TextEditingController(text: profileData["address"]);
    _aboutController = TextEditingController(text: profileData["about"]);
  }
  
  // Simulate loading profile from Firebase
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In future, this will fetch data from Firestore
      // await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      // final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
      // if (userDoc.exists) {
      //   setState(() {
      //     profileData = userDoc.data()!;
      //   });
      // }
      
      // Initialize controllers after data is loaded
      _initializeControllers();
    } catch (e) {
      // Handle error
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _specialtyController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
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
                      label: "First Name",
                      controller: _firstNameController,
                      icon: LucideIcons.user,
                      errorKey: "firstName",
                    ),
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: "Last Name",
                      controller: _lastNameController,
                      icon: LucideIcons.userCog,
                      errorKey: "lastName",
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
                    SizedBox(height: 16),
                    
                    _buildInputField(
                      label: "Specialty",
                      controller: _specialtyController,
                      icon: LucideIcons.stethoscope,
                      errorKey: "specialty",
                    ),
                    
                    SizedBox(height: 24),
                    
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
                    
                    _buildInputField(
                      label: "About Me",
                      controller: _aboutController,
                      icon: LucideIcons.info,
                      errorKey: "about",
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String errorKey,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
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
                  onChanged: (value) {
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
            if (_selectedImage != null || profileData["imageUrl"] != null && profileData["imageUrl"].isNotEmpty) ...[
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
  
  Future<void> _saveProfile() async {
    // Reset all error states
    for (var key in fieldErrors.keys) {
      fieldErrors[key] = false;
    }
    
    // Check for empty fields
    bool hasError = false;
    if (_firstNameController.text.isEmpty) {
      fieldErrors["firstName"] = true;
      hasError = true;
    }
    if (_lastNameController.text.isEmpty) {
      fieldErrors["lastName"] = true;
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
    }
    if (_specialtyController.text.isEmpty) {
      fieldErrors["specialty"] = true;
      hasError = true;
    }
    if (_addressController.text.isEmpty) {
      fieldErrors["address"] = true;
      hasError = true;
    }
    if (_aboutController.text.isEmpty) {
      fieldErrors["about"] = true;
      hasError = true;
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
      // Upload profile image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadProfileImage(_selectedImage!);
      }
      
      // Update profile data with current values
      final updatedProfile = {
        ...profileData,
        "firstName": _firstNameController.text,
        "lastName": _lastNameController.text,
        "email": _emailController.text,
        "contact": _contactController.text,
        "specialty": _specialtyController.text,
        "address": _addressController.text,
        "about": _aboutController.text,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      };
      
      if (imageUrl != null) {
        updatedProfile["imageUrl"] = imageUrl;
      }
      
      // Save to Firestore (will be implemented with Firebase)
      await _saveUserToFirestore(updatedProfile);
      
      // Update local state
      setState(() {
        profileData.clear();
        profileData.addAll(updatedProfile);
        _isLoading = false;
      });
      
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
      setState(() {
        _isLoading = false;
      });
      
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
    }
  }
  
  // Upload profile image to Firebase Storage (placeholder for now)
  Future<String?> _uploadProfileImage(File imageFile) async {
    // Simulate upload delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // This will be replaced with actual Firebase Storage code:
    /*
    final storageRef = FirebaseStorage.instance.ref();
    final profileImageRef = storageRef.child('profile_images/${profileData["uid"]}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    // Upload the file
    final uploadTask = profileImageRef.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': profileData["uid"],
          'uploadedAt': DateTime.now().toString(),
        },
      ),
    );
    
    // Get download URL
    final TaskSnapshot taskSnapshot = await uploadTask;
    final downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
    */
    
    // For now, return dummy URL
    return "https://firebasestorage.example.com/profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
  }
  
  // Save user data to Firestore (placeholder for now)
  Future<void> _saveUserToFirestore(Map<String, dynamic> userData) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // This will be replaced with actual Firestore code:
    /*
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userData["uid"])
      .set(userData, SetOptions(merge: true));
    */
    
    // For now, just print the data that would be saved
    print('User data that would be saved to Firestore: $userData');
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
          : Text(
              "Save Changes",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}
