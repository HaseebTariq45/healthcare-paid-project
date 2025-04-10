import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Appointment data structure optimized for Firestore
  final List<Map<String, dynamic>> _completedAppointments = [];

  // Search query
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }
  
  // Load appointments from Firestore (mock implementation for now)
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // This will be replaced with actual Firestore queries
      // For demo purposes, use the sample data
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      
      setState(() {
        _completedAppointments.clear();
        _completedAppointments.addAll([
          {
            "id": "appt1",
            "patientId": "patient1",
            "doctorId": "doctor1",
            "patientName": "Ali",
            "patientAge": "29 Years",
            "patientLocation": "Bhalwal",
            "patientImage": "assets/images/patient_1.png",
            "lastVisit": "2 days ago",
            "condition": "Hypertension",
            "date": "15 Oct 2023",
            "time": "09:00 AM",
            "hospital": "Aga Khan Hospital, Karachi",
            "reason": "Follow-up Visit",
            "status": "Completed",
            "diagnosis": "Controlled hypertension",
            "prescription": "Amlodipine 5mg daily",
            "notes": "Blood pressure normal at 120/80. Continue current medication.",
            "nextVisit": "15 Jan 2024",
            "amount": 2000,
            "displayAmount": "Rs 2,000",
            "type": "In-Person Visit",
          },
          {
            "id": "appt3",
            "patientId": "patient3",
            "doctorId": "doctor1",
            "patientName": "Asma",
            "patientAge": "24 Years",
            "patientLocation": "Lahore",
            "patientImage": "assets/images/patient_3.png",
            "lastVisit": "Yesterday",
            "condition": "Pregnancy",
            "date": "14 Oct 2023",
            "time": "02:00 PM",
            "hospital": "Jinnah Hospital, Karachi",
            "reason": "Prescription Refill",
            "status": "Completed",
            "diagnosis": "Healthy pregnancy - 28 weeks",
            "prescription": "Prenatal vitamins",
            "notes": "Fetal heart rate normal. Scheduled for ultrasound next month.",
            "nextVisit": "14 Nov 2023",
            "amount": 1500,
            "displayAmount": "Rs 1,500",
            "type": "In-Person Visit",
          },
          {
            "id": "appt4",
            "patientId": "patient4",
            "doctorId": "doctor1",
            "patientName": "Robert Lee",
            "patientAge": "42 Years",
            "patientLocation": "Islamabad",
            "patientImage": "assets/images/User.png",
            "lastVisit": "5 days ago",
            "condition": "Diabetes Type 2",
            "date": "10 Oct 2023",
            "time": "11:30 AM",
            "hospital": "Shifa International Hospital, Islamabad",
            "reason": "Regular Checkup",
            "status": "Completed",
            "diagnosis": "Well-managed diabetes",
            "prescription": "Metformin 500mg twice daily",
            "notes": "HbA1c improved to 6.5%. Continue diet and exercise regimen.",
            "nextVisit": "10 Jan 2024",
            "amount": 2500,
            "displayAmount": "Rs 2,500",
            "type": "Video Consultation",
          },
          {
            "id": "appt5",
            "patientId": "patient5",
            "doctorId": "doctor1",
            "patientName": "Saima Khan",
            "patientAge": "36 Years",
            "patientLocation": "Karachi",
            "patientImage": "assets/images/User.png",
            "lastVisit": "2 weeks ago",
            "condition": "Migraine",
            "date": "5 Oct 2023",
            "time": "03:00 PM",
            "hospital": "Liaquat National Hospital, Karachi",
            "reason": "Acute Headache",
            "status": "Completed",
            "diagnosis": "Migraine with aura",
            "prescription": "Sumatriptan 50mg as needed",
            "notes": "Discussed trigger avoidance and stress management techniques.",
            "nextVisit": "As needed",
            "amount": 1800,
            "displayAmount": "Rs 1,800",
            "type": "In-Person Visit",
          },
          {
            "id": "appt6",
            "patientId": "patient6",
            "doctorId": "doctor1",
            "patientName": "Imran Ahmed",
            "patientAge": "52 Years",
            "patientLocation": "Peshawar",
            "patientImage": "assets/images/User.png",
            "lastVisit": "3 weeks ago",
            "condition": "Osteoarthritis",
            "date": "28 Sept 2023",
            "time": "10:00 AM",
            "hospital": "Khyber Teaching Hospital, Peshawar",
            "reason": "Joint Pain",
            "status": "Completed",
            "diagnosis": "Moderate osteoarthritis of knee",
            "prescription": "Acetaminophen 500mg as needed, Glucosamine supplement",
            "notes": "Recommended physiotherapy twice weekly for 1 month.",
            "nextVisit": "28 Dec 2023",
            "amount": 2000,
            "displayAmount": "Rs 2,000",
            "type": "In-Person Visit",
          },
        ]);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load appointments: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading appointments: $e');
    }
  }
  
  // Filter appointments based on search query and selected filter
  List<Map<String, dynamic>> get filteredAppointments {
    List<Map<String, dynamic>> result = _completedAppointments;
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((appointment) {
      final patientName = appointment['patientName'].toString().toLowerCase();
        final hospital = appointment['hospital'].toString().toLowerCase();
        final condition = appointment['condition'].toString().toLowerCase();
        final date = appointment['date'].toString().toLowerCase();
      
      final query = _searchQuery.toLowerCase();
      
        return patientName.contains(query) || 
               hospital.contains(query) ||
               condition.contains(query) ||
             date.contains(query);
    }).toList();
  }
  
    // Apply filter
    if (_selectedFilter != 'All') {
      result = result.where((appointment) {
        if (_selectedFilter == 'Consultation') {
          return appointment['type'] == 'Video Consultation';
        } else if (_selectedFilter == 'In-Person') {
          return appointment['type'] == 'In-Person Visit';
        } else if (_selectedFilter == 'Follow-up') {
          return appointment['reason'].toString().contains('Follow-up');
        }
        return true;
      }).toList();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Completed Appointments",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF3366FF), size: 22),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
                color: Color(0xFF3366FF),
            ),
          )
        : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : Column(
              children: [
                // Search and filter section
                _buildSearchAndFilterSection(),
                
                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        "${filteredAppointments.length} ${filteredAppointments.length == 1 ? 'result' : 'results'}",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Completed appointments",
                        style: GoogleFonts.poppins(
                        fontSize: 14,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                    ),
                  ),
                    ],
                ),
                ),
                
                // Appointment list
                Expanded(
                  child: filteredAppointments.isEmpty
                    ? _buildEmptyView()
                    : _buildAppointmentsList(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search by patient, condition, or location",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade600),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              ),
            ),
          ),
          
          SizedBox(height: 15),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                SizedBox(width: 10),
                _buildFilterChip('In-Person'),
                SizedBox(width: 10),
                _buildFilterChip('Consultation'),
                SizedBox(width: 10),
                _buildFilterChip('Follow-up'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3366FF).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF3366FF) : Colors.grey.shade300,
            ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Color(0xFF3366FF) : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
            Icons.assignment,
            size: 70,
            color: Colors.grey.shade300,
                  ),
          SizedBox(height: 20),
                  Text(
            "No completed appointments",
                    style: GoogleFonts.poppins(
              fontSize: 18,
                      fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
                    ),
                  ),
          SizedBox(height: 10),
                  Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
              _searchQuery.isNotEmpty
                ? "No results matching \"$_searchQuery\""
                : "Completed appointments will appear here",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                color: Colors.grey.shade500,
                      ),
                    ),
                  ),
          SizedBox(height: 30),
          if (_searchQuery.isNotEmpty)
                  ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
              icon: Icon(Icons.refresh, size: 18),
                    label: Text(
                "Clear filters",
                style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366FF),
                      foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
            Icons.error_outline,
            size: 70,
            color: Colors.amber,
                ),
          SizedBox(height: 20),
                Text(
            "Error Loading Appointments",
                  style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
                  ),
                ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                color: Colors.grey.shade600,
              ),
                    ),
                  ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: Icon(Icons.refresh, size: 18),
            label: Text(
              "Try Again",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentsList() {
    return ListView.builder(
              padding: EdgeInsets.all(20),
      itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return _buildAppointmentCard(appointment, index);
              },
          );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Patient info header
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFF5F7FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      appointment['patientImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                        appointment['patientName'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "${appointment['patientAge']} • ${appointment['patientLocation']}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailProfileScreen(
                          name: appointment['patientName'],
                          age: appointment['patientAge'].split(' ')[0],
                          bloodGroup: "B+", // This would be dynamically set in a real app
                          diseases: [appointment['condition']],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Color(0xFF3366CC).withOpacity(0.1),
                      shape: BoxShape.circle,
                  ),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF3366CC),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Appointment details
          Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date, time and type row
                Row(
                  children: [
                    _buildInfoTag(
                      Icons.calendar_today,
                      appointment['date'],
                      Colors.blue.shade700,
                    ),
                    SizedBox(width: 10),
                    _buildInfoTag(
                      Icons.access_time,
                      appointment['time'],
                      Colors.orange.shade700,
                    ),
                    SizedBox(width: 10),
                    _buildInfoTag(
                      appointment['type'] == 'Video Consultation' 
                          ? Icons.videocam
                          : Icons.medical_services,
                      appointment['type'],
                      appointment['type'] == 'Video Consultation'
                          ? Colors.purple.shade700
                          : Colors.green.shade700,
                    ),
                  ],
                ),
                
                SizedBox(height: 15),
                
                // Facility and reason
                _buildDetailRow(
                  "Facility",
                  appointment['hospital'],
                  Icons.business,
                ),
                SizedBox(height: 10),
                _buildDetailRow(
                  "Reason",
                  appointment['reason'],
                  Icons.assignment,
                ),
                SizedBox(height: 10),
                _buildDetailRow(
                  "Diagnosis",
                  appointment['diagnosis'],
                  Icons.medical_services,
                ),
                SizedBox(height: 10),
                _buildDetailRow(
                  "Prescription",
                  appointment['prescription'],
                  Icons.medication,
                ),
                
                SizedBox(height: 15),
                
                // Clinical notes
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(
                        "Clinical Notes",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        appointment['notes'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                          ),
                  ],
                ),
                ),
                
                SizedBox(height: 15),
                
                // Bottom row: Fee and next visit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          "Fee",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                        ),
                        Text(
                          appointment['displayAmount'],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3366CC),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Next Visit",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          appointment['nextVisit'],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
        ),
          SizedBox(width: 5),
              Text(
            text,
                style: GoogleFonts.poppins(
              fontSize: 12,
                  fontWeight: FontWeight.w500,
              color: color,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
        padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
            color: Color(0xFF3366CC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
            size: 16,
            color: Color(0xFF3366CC),
          ),
      ),
        SizedBox(width: 10),
        Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
              ),
            ),
            Text(
                value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
              ),
            ),
            ],
              ),
            ),
          ],
    );
  }
}
