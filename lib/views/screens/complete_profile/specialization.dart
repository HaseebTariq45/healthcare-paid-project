import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteMedicalDocumentsScreen extends StatefulWidget {
  const CompleteMedicalDocumentsScreen({super.key});

  @override
  State<CompleteMedicalDocumentsScreen> createState() =>
      _CompleteMedicalDocumentsScreenState();
}

class _CompleteMedicalDocumentsScreenState
    extends State<CompleteMedicalDocumentsScreen> {
  File? _specializationFile;
  File? _certificationFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _completionDateController =
      TextEditingController();

  Future<void> _pickFile(bool isSpecialization) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isSpecialization) {
          _specializationFile = File(pickedFile.path);
        } else {
          _certificationFile = File(pickedFile.path);
        }
      });
    }
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required bool isSpecialization,
  }) {
    return GestureDetector(
      onTap: () => _pickFile(isSpecialization),
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
            const Icon(Icons.school_outlined, color: Colors.grey, size: 28),
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
              (isSpecialization ? _specializationFile : _certificationFile) ==
                      null
                  ? Icons.cloud_upload_outlined
                  : Icons.check_circle,
              color:
                  (isSpecialization
                              ? _specializationFile
                              : _certificationFile) ==
                          null
                      ? Colors.grey
                      : Colors.green,
              size: 28,
            ),
            if (!isSpecialization) const SizedBox(width: 8),
            if (!isSpecialization)
              const Icon(Icons.add_box_outlined, color: Colors.grey, size: 28),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Medical Documents",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              hint: "Specialization",
              icon: Icons.school_outlined,
              controller: _specializationController,
            ),
            _buildTextField(
              hint: "Institute",
              icon: Icons.business_outlined,
              controller: _instituteController,
            ),
            _buildTextField(
              hint: "Completion Date",
              icon: Icons.calendar_today_outlined,
              controller: _completionDateController,
            ),
            _buildUploadBox(label: "Specialization", isSpecialization: true),
            _buildUploadBox(label: "Certification", isSpecialization: false),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  popUpSucess(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(64, 124, 226, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Finish Profile Set Up",
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

void popUpSucess(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible:
        false, // Prevent closing the dialog when tapping outside
    builder: (BuildContext context) {
      Timer(
        Duration(seconds: 3),
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavigationBarScreen(profileStatus: "complete"),
          ),
        ),
      );

      return Stack(
        children: [
          // Blurred background effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ), // Adjust blur intensity
            child: Container(
              color: const Color.fromARGB(
                30,
                0,
                0,
                0,
              ), // Darken background slightly
            ),
          ),
          AlertDialog(
            backgroundColor: const Color.fromRGBO(64, 124, 226, 1),
            title: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 75,
                      color: Colors.white,
                    ),
                    Text(
                      "Profile Completed Successfully",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // actions: [
            //   InkWell(
            //     onTap: () {
            //       Navigator.of(context).pop();
            //       Navigator.of(context).push(
            //         MaterialPageRoute(builder: (context) => const HomeScreen()),
            //       );
            //     },
            //     child: Center(
            //       child: Container(
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(32),
            //           color: const Color.fromRGBO(217, 217, 217, 1),
            //           boxShadow: [
            //             BoxShadow(
            //               color: const Color.fromRGBO(0, 0, 0, 0.25),
            //               blurRadius: 4,
            //               offset: const Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         width: 100,
            //         padding: EdgeInsets.symmetric(vertical: 10),
            //         child: Center(
            //           child: Text(
            //             "Proceed",
            //             style: GoogleFonts.poppins(
            //               fontSize: 16,
            //               color: Colors.black,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ),
        ],
      );
    },
  );
}
