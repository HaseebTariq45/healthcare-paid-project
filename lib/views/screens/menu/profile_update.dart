import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _image;
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = await _userService.getCurrentUser();
    
    if (user != null) {
      setState(() {
        _currentUser = user;
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _contactController.text = user.contactNumber;
        _emailController.text = user.email;
        _specialtyController.text = user.specialty;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      
      // Show error if user data couldn't be loaded
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data'),
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
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    // Upload image if selected
    String? profileImageUrl = _currentUser!.profileImageUrl;
    if (_image != null) {
      final uploadedUrl = await _userService.uploadProfileImage(_image!);
      if (uploadedUrl != null) {
        profileImageUrl = uploadedUrl;
      }
    }
    
    // Update user model with form data
    final updatedUser = _currentUser!.copyWith(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      contactNumber: _contactController.text,
      specialty: _specialtyController.text,
      profileImageUrl: profileImageUrl,
    );
    
    // Save to Firebase
    final success = await _userService.updateUserProfile(updatedUser);
    
    setState(() {
      _isSaving = false;
    });
    
    if (success) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF3366FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
        
        Navigator.pop(context);
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile'),
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
  }

  Future<void> _pickImage() async {
    final pickedFile = await _userService.pickImageFromGallery();
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final success = await _userService.deleteUserAccount();
    
    if (success) {
      // Redirect to login or home screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account'),
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
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3366FF)),
                    ),
                  )
                : Text(
                    "Save",
                    style: GoogleFonts.poppins(
                      color: Color(0xFF3366FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image section with blue background
                  Container(
                    width: double.infinity,
                    color: Color(0xFF3366FF).withOpacity(0.05),
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        // Profile image with edit button
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Hero(
                              tag: 'profileImage',
                              child: Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: _image != null
                                        ? FileImage(_image!) as ImageProvider
                                        : _currentUser?.profileImageUrl != null && 
                                          _currentUser!.profileImageUrl.isNotEmpty
                                            ? NetworkImage(_currentUser!.profileImageUrl) as ImageProvider
                                            : AssetImage("assets/images/User.png"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Color(0xFF3366FF),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(LucideIcons.camera, size: 18, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_currentUser != null)
                          Text(
                            "Dr. ${_currentUser!.firstName} ${_currentUser!.lastName}",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        if (_currentUser != null)
                          Text(
                            _currentUser!.specialty,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
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
                        SizedBox(height: 20),
                        
                        // Form fields
                        _buildInputField(
                          "First Name", 
                          _firstNameController,
                          LucideIcons.user,
                        ),
                        SizedBox(height: 16),
                        
                        _buildInputField(
                          "Last Name", 
                          _lastNameController,
                          LucideIcons.userCog,
                        ),
                        SizedBox(height: 16),
                        
                        _buildInputField(
                          "Email Address", 
                          _emailController,
                          LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),
                        
                        _buildInputField(
                          "Contact Number", 
                          _contactController,
                          LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 16),
                        
                        _buildInputField(
                          "Specialty", 
                          _specialtyController,
                          LucideIcons.stethoscope,
                        ),
                        SizedBox(height: 40),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3366FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Save Changes",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Delete Account Button
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      "Delete Account",
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                    content: Text(
                                      "Are you sure you want to delete your account? This action cannot be undone.",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.poppins(color: Colors.grey),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteAccount();
                                        },
                                        child: Text(
                                          "Delete",
                                          style: GoogleFonts.poppins(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  );
                                },
                              );
                            },
                            icon: Icon(LucideIcons.trash2, color: Colors.red.shade400, size: 18),
                            label: Text(
                              "Delete Account",
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w500,
                              ),
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
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF3366FF), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
