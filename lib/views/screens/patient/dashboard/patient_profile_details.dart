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

// Document type enum for upload functionality
enum DocumentType { identification, medical }

class PatientDetailProfileScreen extends StatefulWidget {
  final String name;
  final String age;
  final String bloodGroup;
  final String phoneNumber;
  final List<String> allergies;
  final List<String> diseases;
  final String? disability;
  final double? height;
  final double? weight;
  final File? profileImage;
  final File? cnicFront;
  final File? cnicBack;
  final File? medicalReport1;
  final File? medicalReport2;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  const PatientDetailProfileScreen({
    super.key,
    this.name = "Amna Khan",
    this.age = "28",
    this.bloodGroup = "B+",
    this.phoneNumber = "+92 300 1234567",
    this.allergies = const ["Peanuts", "Penicillin", "Dust Mites"],
    this.diseases = const ["Asthma", "Migraine"],
    this.disability,
    this.height = 165,
    this.weight = 65,
    this.profileImage,
    this.cnicFront,
    this.cnicBack,
    this.medicalReport1,
    this.medicalReport2,
    this.email,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
  });

  @override
  State<PatientDetailProfileScreen> createState() => _PatientDetailProfileScreenState();
}

class _PatientDetailProfileScreenState extends State<PatientDetailProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';

  // Categorized diseases for detailed view
  final Map<String, List<String>> diseasesMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize diseases map from the list
    _categorizeDiseases();
  }

  void _categorizeDiseases() {
    // This would normally map diseases to categories, but for now we'll put all in one category
    diseasesMap["Current Conditions"] = widget.diseases;
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
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSummaryTab(),
                  _buildMedicalHistoryTab(),
                  _buildDocumentsTab(),
                ],
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
                        backgroundImage: const AssetImage("assets/images/User.png"),
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
                      widget.name,
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
                      "${widget.age} years",
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
                            color: _getBloodGroupColor(widget.bloodGroup),
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
                            widget.bloodGroup,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vital statistics card
          _buildSectionTitle("Vital Statistics"),
          _buildVitalStatisticsCard(),
          
          const SizedBox(height: 20),
          
          // Contact information card
          _buildSectionTitle("Contact Information"),
          _buildContactInformationCard(),
          
          const SizedBox(height: 20),
          
          // Allergies card
          _buildSectionTitle("Allergies"),
          _buildAllergiesCard(),
          
          const SizedBox(height: 20),
          
          // Current conditions card
          _buildSectionTitle("Current Conditions"),
          _buildCurrentConditionsCard(),
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
          if (widget.email != null) 
            _buildContactItem(
              icon: LucideIcons.mail,
              title: "Email",
              value: widget.email!,
              iconColor: Colors.blue.shade600,
            ),
          if (widget.phoneNumber.isNotEmpty) ...[
            if (widget.email != null) const Divider(height: 1),
            _buildContactItem(
              icon: LucideIcons.phone,
              title: "Phone",
              value: widget.phoneNumber,
              iconColor: Colors.green.shade600,
            ),
          ],
          if (widget.address != null) ...[
            const Divider(height: 1),
            _buildContactItem(
              icon: LucideIcons.building,
              title: "Address",
              value: widget.address!,
              iconColor: Colors.orange.shade700,
            ),
          ],
          if (widget.city != null && widget.country != null) ...[
            const Divider(height: 1),
            _buildContactItem(
              icon: LucideIcons.mapPin,
              title: "Location",
              value: "${widget.city}, ${widget.state ?? ''} ${widget.zipCode ?? ''}\n${widget.country}",
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
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
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
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search medical history...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
        
        // Expandable list of diseases by category
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: diseasesMap.length,
            itemBuilder: (context, index) {
              final category = diseasesMap.keys.elementAt(index);
              final diseases = diseasesMap[category]!;
              
              // Filter by search query if present
              final filteredDiseases = searchQuery.isEmpty
                  ? diseases
                  : diseases.where((disease) => 
                      disease.toLowerCase().contains(searchQuery.toLowerCase())).toList();
              
              if (filteredDiseases.isEmpty) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    childrenPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3366CC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: const Color(0xFF3366CC),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      "${filteredDiseases.length} condition${filteredDiseases.length != 1 ? 's' : ''}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    children: filteredDiseases.map((disease) => _buildDiseaseItem(disease)).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _uploadDocument(DocumentType.identification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.idCard, size: 18),
                  label: Text(
                    "Upload ID",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _uploadDocument(DocumentType.medical),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.fileText, size: 18),
                  label: Text(
                    "Upload Medical",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Identification Documents
          _buildSectionTitle("Identification Documents"),
          const SizedBox(height: 10),
          _buildDocumentGrid([
            if (widget.cnicFront != null)
              _buildDocumentCard(
                title: "CNIC Front",
                icon: LucideIcons.idCard,
                color: Colors.blue.shade700,
                file: widget.cnicFront!,
                onTap: () => _viewDocument(widget.cnicFront!),
              ),
            if (widget.cnicBack != null)
              _buildDocumentCard(
                title: "CNIC Back",
                icon: LucideIcons.idCard,
                color: Colors.blue.shade700,
                file: widget.cnicBack!,
                onTap: () => _viewDocument(widget.cnicBack!),
              ),
          ]),

          const SizedBox(height: 30),

          // Medical Reports
          _buildSectionTitle("Medical Reports"),
          const SizedBox(height: 10),
          _buildDocumentGrid([
            if (widget.medicalReport1 != null)
              _buildDocumentCard(
                title: "Medical Report 1",
                icon: LucideIcons.clipboardList,
                color: Colors.green.shade700,
                file: widget.medicalReport1!,
                onTap: () => _viewDocument(widget.medicalReport1!),
              ),
            if (widget.medicalReport2 != null)
              _buildDocumentCard(
                title: "Medical Report 2",
                icon: LucideIcons.clipboardList,
                color: Colors.green.shade700,
                file: widget.medicalReport2!,
                onTap: () => _viewDocument(widget.medicalReport2!),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDocumentGrid(List<Widget> documents) {
    if (documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                LucideIcons.fileX,
                size: 50,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "No documents available",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tap the upload button above to add documents",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: documents,
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required Color color,
    required File file,
    required VoidCallback onTap,
  }) {
    final bool isImage = _isImageFile(file.path);
    final bool isPdf = _isPdfFile(file.path);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                width: double.infinity,
                child: isImage 
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                LucideIcons.imageOff,
                                color: color,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      )
                    : isPdf
                        ? Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  LucideIcons.fileText,
                                  color: color,
                                  size: 42,
                                ),
                                Positioned(
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "PDF",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 32,
                              ),
                            ),
                          ),
              ),
            ),
            
            // Info section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFileSize(file),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getFileExtension(file.path).toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDocument(File file) {
    if (_isImageFile(file.path)) {
      _showImageViewer(file);
    } else if (_isPdfFile(file.path)) {
      _showPdfViewer(file);
    } else {
      // For other file types, just show info for now
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Viewing file: ${path.basename(file.path)}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showImageViewer(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              path.basename(imageFile.path),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2),
                onPressed: () {
                  // Implement share functionality
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.download),
                onPressed: () {
                  // Implement download functionality
                },
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: FileImage(imageFile),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event?.expectedTotalBytes != null
                    ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPdfViewer(File pdfFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              path.basename(pdfFile.path),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2),
                onPressed: () {
                  // Implement share functionality
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.download),
                onPressed: () {
                  // Implement download functionality
                },
              ),
            ],
          ),
          body: PDFView(
            filePath: pdfFile.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (_pages) {
              // PDF rendered
            },
            onError: (error) {
              // Handle error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error loading PDF: $error"),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            onPageError: (page, error) {
              // Handle page error
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // PDF view created
            },
          ),
        ),
      ),
    );
  }

  // Helper methods for document handling
  bool _isImageFile(String filePath) {
    final ext = _getFileExtension(filePath).toLowerCase();
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif';
  }
  
  bool _isPdfFile(String filePath) {
    return _getFileExtension(filePath).toLowerCase() == 'pdf';
  }
  
  String _getFileExtension(String filePath) {
    return path.extension(filePath).replaceAll('.', '');
  }
  
  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return "$bytes B";
      } else if (bytes < 1024 * 1024) {
        return "${(bytes / 1024).toStringAsFixed(1)} KB";
      } else {
        return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }
    } catch (e) {
      return "Unknown";
    }
  }

  // Document upload functionality
  Future<void> _uploadDocument(DocumentType type) async {
    final source = await _showDocumentSourceDialog();
    if (source == null) return;
    
    File? pickedFile;
    
    if (source == 'camera') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1000,
      );
      
      if (image != null) {
        pickedFile = File(image.path);
      }
    } else if (source == 'gallery') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );
      
      if (image != null) {
        pickedFile = File(image.path);
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
        pickedFile = File(result.path);
      }
    }
    
    if (pickedFile == null) return;
    
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
            value: widget.bloodGroup,
            iconColor: _getBloodGroupColor(widget.bloodGroup),
            showGradient: true,
          ),
          const Divider(height: 1),
          _buildVitalStatItem(
            icon: LucideIcons.ruler,
            title: "Height",
            value: "${widget.height} cm",
            iconColor: Colors.blue,
            showGradient: false,
          ),
          const Divider(height: 1),
          _buildVitalStatItem(
            icon: LucideIcons.weight,
            title: "Weight",
            value: "${widget.weight} kg",
            iconColor: Colors.amber.shade700,
            showGradient: false,
          ),
          if (widget.disability != null) ...[
            const Divider(height: 1),
            _buildVitalStatItem(
              icon: LucideIcons.userCog,
              title: "Disability",
              value: widget.disability!,
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
    if (widget.allergies.isEmpty) {
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
            children: widget.allergies.map((allergy) {
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
    if (widget.diseases.isEmpty) {
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
        children: widget.diseases.map((disease) {
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
} 