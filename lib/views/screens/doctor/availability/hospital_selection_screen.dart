import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  
  // Sample data - In production, this would come from a database
  final List<Map<String, dynamic>> _allHospitals = [
    {
      "name": "Aga Khan Hospital",
      "location": "Karachi",
      "address": "Stadium Road, Karachi",
      "image": "assets/images/hospital1.jpg",
    },
    {
      "name": "Shaukat Khanum Hospital",
      "location": "Lahore",
      "address": "7A Block R-3, Johar Town, Lahore",
      "image": "assets/images/hospital2.jpg",
    },
    {
      "name": "Jinnah Hospital",
      "location": "Karachi",
      "address": "Rafiqui Shaheed Road, Karachi",
      "image": "assets/images/hospital3.jpg",
    },
    {
      "name": "Liaquat National Hospital",
      "location": "Karachi",
      "address": "National Stadium Road, Karachi",
      "image": "assets/images/hospital4.jpg",
    },
    {
      "name": "Pakistan Institute of Medical Sciences",
      "location": "Islamabad",
      "address": "Islamabad",
      "image": "assets/images/hospital5.jpg",
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedHospitals = List.from(widget.selectedHospitals);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getFullHospitalName(Map<String, dynamic> hospital) {
    return "${hospital['name']}, ${hospital['location']}";
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
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _allHospitals.length,
              itemBuilder: (context, index) {
                final hospital = _allHospitals[index];
                final fullName = _getFullHospitalName(hospital);
                final isSelected = _selectedHospitals.contains(fullName);
                
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.05 * index, 0.5 + 0.05 * index, curve: Curves.easeOut),
                  )),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(0.05 * index, 0.5 + 0.05 * index, curve: Curves.easeOut),
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedHospitals.remove(fullName);
                            } else {
                              _selectedHospitals.add(fullName);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  hospital['image'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        LucideIcons.building2,
                                        color: Colors.grey.shade400,
                                        size: 30,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hospital['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      hospital['location'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.mapPin,
                                          color: Colors.grey[500],
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            hospital['address'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Color(0xFF2B8FEB) : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? Color(0xFF2B8FEB) : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
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

  void _saveSelection() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate network delay
    Future.delayed(Duration(milliseconds: 800), () {
      setState(() {
        _isLoading = false;
      });
      
      Navigator.pop(context, _selectedHospitals);
    });
  }
} 