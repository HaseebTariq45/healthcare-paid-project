import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page2.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteProfilePatient1Screen extends StatefulWidget {
  const CompleteProfilePatient1Screen({super.key});

  @override
  State<CompleteProfilePatient1Screen> createState() => _CompleteProfilePatient1ScreenState();
}

class _CompleteProfilePatient1ScreenState extends State<CompleteProfilePatient1Screen> {
  File? _profileImage;
  File? _cnicFront;
  File? _cnicBack;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, String type) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (type == 'profile') {
          _profileImage = File(pickedFile.path);
        } else if (type == 'cnicFront') {
          _cnicFront = File(pickedFile.path);
        } else if (type == 'cnicBack') {
          _cnicBack = File(pickedFile.path);
        }
      });
    }
  }

  Widget _buildUploadBox(String label, String type, File? file) {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery, type),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: Colors.grey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ".pdf, .png, .jpg, .jpeg (Max: 5MB)",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              file == null ? Icons.cloud_upload_outlined : Icons.check_circle,
              color: file == null ? Colors.grey : Colors.green,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(
        isBackButtonVisible: true,
        text: "Complete Your Profile",
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery, 'profile'),
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child:
                    _profileImage == null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.grey,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Profile Picture",
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                            Text(
                              ".png, .jpeg, .jpg (Max: 2MB)",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_profileImage!, fit: BoxFit.cover),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            _buildUploadBox("CNIC Front", "cnicFront", _cnicFront),
            _buildUploadBox("CNIC Back", "cnicBack", _cnicBack),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompleteProfilePatient2Screen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(64, 124, 226, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Next",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
