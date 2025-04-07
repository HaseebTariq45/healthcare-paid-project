import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/complete_profile/specialization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CompleteEducationScreen extends StatefulWidget {
  const CompleteEducationScreen({super.key});

  @override
  State<CompleteEducationScreen> createState() =>
      _CompleteEducationScreenState();
}

class _CompleteEducationScreenState extends State<CompleteEducationScreen> {
  final ImagePicker _picker = ImagePicker();

  // Store multiple education entries
  List<Map<String, dynamic>> educationEntries = [];

  @override
  void initState() {
    super.initState();
    _addEducationEntry(); // Start with one entry initially
  }

  void _addEducationEntry() {
    setState(() {
      educationEntries.add({
        "degreeController": TextEditingController(),
        "instituteController": TextEditingController(),
        "completionDateController": TextEditingController(),
        "degreeFile": null,
      });
    });
  }

  Future<void> _pickFile(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        educationEntries[index]["degreeFile"] = File(pickedFile.path);
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

  Widget _buildUploadBox(int index) {
    return GestureDetector(
      onTap: () => _pickFile(index),
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
                    "Degree",
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
              educationEntries[index]["degreeFile"] == null
                  ? Icons.cloud_upload_outlined
                  : Icons.check_circle,
              color:
                  educationEntries[index]["degreeFile"] == null
                      ? Colors.grey
                      : Colors.green,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBarOnboarding(
          isBackButtonVisible: true,
          text: "Complete Your Profile",
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Education",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
      
                // Dynamically render education fields
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: educationEntries.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          hint: "Degree",
                          icon: Icons.school_outlined,
                          controller: educationEntries[index]["degreeController"],
                        ),
                        _buildTextField(
                          hint: "Institute",
                          icon: Icons.business_outlined,
                          controller:
                              educationEntries[index]["instituteController"],
                        ),
                        _buildTextField(
                          hint: "Completion Date",
                          icon: Icons.calendar_today_outlined,
                          controller:
                              educationEntries[index]["completionDateController"],
                        ),
                        _buildUploadBox(index),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
      
                const SizedBox(height: 20),
      
                // Add Another Degree Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addEducationEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(64, 124, 226, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Upload Another Degree",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
      
                const SizedBox(height: 30),
      
                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompleteMedicalDocumentsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(64, 124, 226, 1),
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
        ),
      ),
    );
  }
}
