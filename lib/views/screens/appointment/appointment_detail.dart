import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String? appointmentId;
  final Map<String, dynamic>? appointmentDetails;
  
  const AppointmentDetailsScreen({
    super.key,
    this.appointmentId,
    this.appointmentDetails,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _appointmentData = {};
  String _doctorName = "Doctor";
  String _appointmentDate = "Upcoming";
  String _appointmentTime = "";
  String _doctorSpecialty = "";
  String _hospitalName = "";
  String _fee = "0";
  String _paymentStatus = "Pending";
  String _paymentMethod = "Not specified";
  String _appointmentType = "Regular Consultation";
  String _appointmentStatus = "Upcoming";
  String _reason = "No reason provided";
  String _appointmentId = "";
  bool _isCancelled = false;
  bool _isUpcoming = true;
  String? _cancellationReason;
  String _doctorImage = 'assets/images/User.png';

  @override
  void initState() {
    super.initState();
    if (widget.appointmentDetails != null) {
      // Use provided appointment details directly
      _processAppointmentDetails(widget.appointmentDetails!);
      setState(() {
        _isLoading = false;
      });
    } else if (widget.appointmentId != null) {
      // Fetch appointment data from Firebase
      _fetchAppointmentData();
    } else {
      // No appointment ID or details provided, show default data
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processAppointmentDetails(Map<String, dynamic> details) {
    _appointmentData = details;
    
    // Set appointment date and time
    if (details['date'] != null && details['time'] != null) {
      // Use the date and time directly from the appointment
      _appointmentDate = details['date'];
      _appointmentTime = details['time'];
    } else if (details.containsKey('appointmentDate') && details['appointmentDate'] is Timestamp) {
      // Fallback to appointmentDate if date/time not available
      final DateTime appointmentDate = (details['appointmentDate'] as Timestamp).toDate();
      _appointmentDate = DateFormat('MMM dd, yyyy').format(appointmentDate);
      _appointmentTime = DateFormat('h:mm a').format(appointmentDate);
    } else {
      // Default values if no date/time information available
      _appointmentDate = "Not specified";
      _appointmentTime = "Not specified";
    }
    
    // Set doctor info
    _doctorName = details['doctorName'] ?? "Unknown Doctor";
    _doctorSpecialty = details['specialty'] ?? details['doctorSpecialty'] ?? "General";
    _doctorImage = details['doctorImage'] ?? 'assets/images/User.png';
    
    // Set hospital name - use direct value without fallback
    _hospitalName = details['hospitalName'] ?? "Unknown Hospital";
    
    // Set payment details
    if (details.containsKey('fee') && details['fee'] is num) {
      _fee = "Rs. ${details['fee']}";
    } else if (details.containsKey('displayFee')) {
      _fee = details['displayFee'];
    } else {
      _fee = details['fee']?.toString() ?? "0";
    }
    
    _paymentStatus = details['paymentStatus'] ?? "Pending";
    _paymentMethod = details['paymentMethod'] ?? "Not specified";
    
    // Convert to title case
    _paymentStatus = _capitalize(_paymentStatus);
    _paymentMethod = _capitalize(_paymentMethod);
    
    // Set appointment details
    _appointmentType = details['type'] ?? "Regular Consultation";
    _appointmentStatus = details['status'] ?? "Upcoming";
    _appointmentStatus = _capitalize(_appointmentStatus);
    _appointmentId = details['id'] ?? "";
    
    // Set status flags
    _isCancelled = _appointmentStatus.toLowerCase() == 'cancelled';
    _isUpcoming = _appointmentStatus.toLowerCase() == 'upcoming';
    
    // Set reason
    if (details.containsKey('reason') && details['reason'] != null && details['reason'].toString().isNotEmpty) {
      _reason = details['reason'];
    } else if (details.containsKey('notes') && details['notes'] != null && details['notes'].toString().isNotEmpty) {
      _reason = details['notes'];
    }
    
    // Set cancellation reason
    if (_isCancelled && details.containsKey('cancellationReason') && details['cancellationReason'] != null) {
      _cancellationReason = details['cancellationReason'];
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

  Future<void> _fetchAppointmentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Fetch appointment data
      final appointmentDoc = await firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
      
      if (!appointmentDoc.exists || appointmentDoc.data() == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final data = appointmentDoc.data()!;
      
      // Create a structured map from the Firestore data
      Map<String, dynamic> appointmentDetails = {
        'id': appointmentDoc.id,
      };
      
      // Copy all fields from the document
      appointmentDetails.addAll(data);
      
      // Format date and time if not already handled
      if (data.containsKey('appointmentDate')) {
        appointmentDetails['appointmentDate'] = data['appointmentDate'];
      } else if (data.containsKey('date') && data['date'] is Timestamp) {
        appointmentDetails['date'] = data['date'];
      } else if (data.containsKey('date') && data['date'] is String) {
        appointmentDetails['date'] = data['date'];
      } else {
        appointmentDetails['date'] = "Unknown";
      }
      
      if (data.containsKey('time') && data['time'] is String) {
        appointmentDetails['time'] = data['time'];
      } else {
        appointmentDetails['time'] = "Unknown";
      }
      
      // Ensure hospital name is set
      if (!data.containsKey('hospitalName') || data['hospitalName'] == null || data['hospitalName'].toString().isEmpty) {
        if (data.containsKey('location') && data['location'] != null) {
          appointmentDetails['hospitalName'] = data['location'];
        } else {
          appointmentDetails['hospitalName'] = "Unknown Hospital";
        }
      }
      
      // Ensure doctor specialty is set
      if (!data.containsKey('specialty') && data.containsKey('doctorSpecialty')) {
        appointmentDetails['specialty'] = data['doctorSpecialty'];
      }
      
      // If isPanelConsultation exists, set type accordingly
      if (data.containsKey('isPanelConsultation')) {
        appointmentDetails['type'] = data['isPanelConsultation'] ? 'In-Person Visit' : 'Regular Consultation';
      }
      
      // Get doctor information if doctorId is available but name/specialty is missing
      if (data.containsKey('doctorId') && 
          (!data.containsKey('doctorName') || data['doctorName'] == null || 
           !data.containsKey('specialty') || data['specialty'] == null)) {
        
        try {
          final doctorDoc = await firestore
              .collection('doctors')
              .doc(data['doctorId'])
              .get();
          
          if (doctorDoc.exists && doctorDoc.data() != null) {
            final doctorData = doctorDoc.data() as Map<String, dynamic>;
            
            if (!data.containsKey('doctorName') || data['doctorName'] == null) {
              appointmentDetails['doctorName'] = doctorData['fullName'] ?? doctorData['name'] ?? "Unknown Doctor";
            }
            
            if (!data.containsKey('specialty') && !data.containsKey('doctorSpecialty')) {
              appointmentDetails['specialty'] = doctorData['specialty'] ?? "General";
            }
            
            appointmentDetails['doctorImage'] = doctorData['profileImageUrl'] ?? 'assets/images/User.png';
          }
        } catch (e) {
          print('Error fetching doctor information: $e');
        }
      }
      
      // Process the appointment details
      _processAppointmentDetails(appointmentDetails);
      
    } catch (e) {
      print('Error fetching appointment data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3366CC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Appointment Details",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.share2, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing functionality not implemented'),
                  backgroundColor: Color(0xFF3366CC),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3366CC),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildAppointmentTimeSection(),
                  _buildDoctorInfoSection(),
                  _buildHospitalSection(),
                  _buildPaymentSection(),
                  _buildAppointmentDetailsSection(),
                  if (_reason != "No reason provided") _buildReasonSection(),
                  if (_isCancelled && _cancellationReason != null) _buildCancellationSection(),
                  _buildActionButtons(),
                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    final Color statusColor = _isCancelled
        ? Color(0xFFF44336) // Red for cancelled
        : _isUpcoming
            ? Color(0xFF3366CC) // Blue for upcoming
            : Color(0xFF4CAF50); // Green for completed
    
    final String statusText = _appointmentStatus;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF3366CC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 15),
          Text(
            "Appointment with",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            _doctorName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          Text(
            _doctorSpecialty,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTimeSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
      transform: Matrix4.translationValues(0, -25, 0),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeInfoItem(
            LucideIcons.calendar,
            "Date",
            _appointmentDate,
            Color(0xFF3366CC),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
          _buildTimeInfoItem(
            LucideIcons.clock,
            "Time",
            _appointmentTime,
            Color(0xFF3366CC),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorInfoSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: _doctorImage.startsWith('assets/')
                  ? AssetImage(_doctorImage)
                  : NetworkImage(_doctorImage) as ImageProvider,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _doctorName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _doctorSpecialty,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF3366CC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.phone,
              color: Color(0xFF3366CC),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalSection() {
    return _buildInfoSection(
      "Hospital",
      [
        _buildInfoRow(LucideIcons.building2, "Hospital Name", _hospitalName),
        _buildInfoRow(LucideIcons.bookmark, "Appointment Type", _appointmentType),
      ],
    );
  }

  Widget _buildPaymentSection() {
    // Determine payment status color
    Color statusColor;
    if (_paymentStatus.toLowerCase() == 'paid') {
      statusColor = Colors.green;
    } else if (_paymentStatus.toLowerCase() == 'pending') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }
    
    return _buildInfoSection(
      "Payment Information",
      [
        _buildInfoRow(LucideIcons.banknote, "Fee", "Rs $_fee"),
        _buildInfoRow(
          LucideIcons.wallet, 
          "Payment Method", 
          _paymentMethod,
        ),
        Row(
          children: [
            Icon(
              LucideIcons.creditCard, 
              size: 18, 
              color: Color(0xFF3366CC),
            ),
            SizedBox(width: 10),
            Text(
              "Payment Status:",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _paymentStatus,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppointmentDetailsSection() {
    return _buildInfoSection(
      "Appointment Information",
      [
        _buildInfoRow(LucideIcons.fileText, "Appointment ID", _appointmentId),
        _buildInfoRow(LucideIcons.tag, "Status", _appointmentStatus),
      ],
    );
  }

  Widget _buildReasonSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reason for Visit",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Text(
              _reason,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded, 
            color: Colors.red,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cancellation Reason",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _cancellationReason!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isCancelled) {
      return Container(
        margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // Schedule new appointment
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule functionality not implemented'),
                backgroundColor: Color(0xFF3366CC),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3366CC),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: Color(0xFF3366CC).withOpacity(0.3),
          ),
          icon: Icon(LucideIcons.calendar, size: 18),
          label: Text(
            "Schedule New Appointment",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (_isUpcoming) {
      return Container(
        margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Cancel appointment
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cancel functionality not implemented'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(LucideIcons.x, size: 18),
                label: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Reschedule appointment
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reschedule functionality not implemented'),
                      backgroundColor: Color(0xFF3366CC),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3366CC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Color(0xFF3366CC).withOpacity(0.3),
                ),
                icon: Icon(LucideIcons.calendar, size: 18),
                label: Text(
                  "Reschedule",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Completed appointment
      return Container(
        margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // Book again
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking functionality not implemented'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: Color(0xFF4CAF50).withOpacity(0.3),
          ),
          icon: Icon(LucideIcons.repeat, size: 18),
          label: Text(
            "Book Again",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          ...children.map((child) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: child,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 18, 
          color: Color(0xFF3366CC),
        ),
        SizedBox(width: 10),
        Text(
          "$label:",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
