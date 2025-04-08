import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';

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
                  // Navigate to complete profile flow
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompleteProfilePatient1Screen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.pencil,
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
    // Check if any documents exist
    final bool hasIdentityDocs = widget.cnicFront != null || widget.cnicBack != null;
    final bool hasMedicalDocs = widget.medicalReport1 != null || widget.medicalReport2 != null;
    final bool hasAnyDocs = hasIdentityDocs || hasMedicalDocs;

    if (!hasAnyDocs) {
      // If no documents, show the empty state
      return Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 5),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3366CC).withOpacity(0.2),
                      const Color(0xFF3366CC).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.fileText,
                  size: 50,
                  color: const Color(0xFF3366CC).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No medical documents yet",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Upload your medical reports, prescriptions, and other important documents",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Upload document action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.upload),
                  label: Text(
                    "Upload Documents",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If has documents, show the document sections
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Upload document action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3366CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.upload, size: 18),
                  label: Text(
                    "Upload",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Organize documents action
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3366CC),
                    side: const BorderSide(color: Color(0xFF3366CC)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(LucideIcons.folder, size: 18),
                  label: Text(
                    "Organize",
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
          
          // Identity Documents Section
          if (hasIdentityDocs) ...[
            _buildSectionTitle("Identity Documents"),
            const SizedBox(height: 8),
            _buildDocumentsGrid([
              if (widget.cnicFront != null)
                DocumentItem(
                  file: widget.cnicFront!,
                  title: "CNIC Front",
                  date: "Jun 10, 2023",
                  icon: LucideIcons.creditCard,
                ),
              if (widget.cnicBack != null)
                DocumentItem(
                  file: widget.cnicBack!,
                  title: "CNIC Back",
                  date: "Jun 10, 2023",
                  icon: LucideIcons.creditCard,
                ),
            ]),
            const SizedBox(height: 24),
          ],
          
          // Medical Reports Section
          if (hasMedicalDocs) ...[
            _buildSectionTitle("Medical Reports"),
            const SizedBox(height: 8),
            _buildDocumentsGrid([
              if (widget.medicalReport1 != null)
                DocumentItem(
                  file: widget.medicalReport1!,
                  title: "Medical Report 1",
                  date: "Jul 15, 2023",
                  icon: LucideIcons.fileText,
                ),
              if (widget.medicalReport2 != null)
                DocumentItem(
                  file: widget.medicalReport2!,
                  title: "Medical Report 2",
                  date: "Aug 22, 2023",
                  icon: LucideIcons.fileText,
                ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(List<DocumentItem> documents) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  Widget _buildDocumentCard(DocumentItem document) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document preview
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: FileImage(document.file),
                  fit: BoxFit.cover,
                ),
              ),
              width: double.infinity,
              child: Stack(
                children: [
                  // Overlay to ensure text visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0, 0.3, 0.7, 1],
                      ),
                    ),
                  ),
                  // File type indicator (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getFileExtension(document.file.path).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Action buttons (bottom-right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildActionButton(
                          onPressed: () {
                            // View document action
                          },
                          icon: LucideIcons.eye,
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          onPressed: () {
                            // Share document action
                          },
                          icon: LucideIcons.share,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Document info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3366CC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        document.icon,
                        color: const Color(0xFF3366CC),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Uploaded: ${document.date}",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: const Color(0xFF3366CC),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  String _getFileExtension(String path) {
    return path.split('.').last;
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
}

class DocumentItem {
  final File file;
  final String title;
  final String date;
  final IconData icon;

  DocumentItem({
    required this.file,
    required this.title,
    required this.date,
    required this.icon,
  });
} 