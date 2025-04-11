import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppointmentManagement extends StatefulWidget {
  const AppointmentManagement({Key? key}) : super(key: key);

  @override
  State<AppointmentManagement> createState() => _AppointmentManagementState();
}

class _AppointmentManagementState extends State<AppointmentManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Filter values
  String _selectedStatusFilter = 'All';
  String _selectedDoctorFilter = 'All Doctors';
  DateTimeRange? _selectedDateRange;
  
  // Mock data - to be replaced with actual data fetching
  final List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Simulated appointment loading
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));
    
    setState(() {
      _appointments.clear();
      _appointments.addAll(_getMockAppointments());
      _isLoading = false;
    });
  }
  
  // Filtered appointments based on search and filters
  List<Map<String, dynamic>> get filteredAppointments {
    return _appointments.where((appointment) {
      // Apply status filter
      if (_selectedStatusFilter != 'All' && 
          appointment['status'] != _selectedStatusFilter) {
        return false;
      }
      
      // Apply doctor filter
      if (_selectedDoctorFilter != 'All Doctors' && 
          appointment['doctorName'] != _selectedDoctorFilter) {
        return false;
      }
      
      // Apply date range filter
      if (_selectedDateRange != null) {
        final appointmentDate = DateFormat('dd MMM yyyy').parse(appointment['date']);
        if (appointmentDate.isBefore(_selectedDateRange!.start) || 
            appointmentDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final String patientName = appointment['patientName'].toLowerCase();
        final String doctorName = appointment['doctorName'].toLowerCase();
        final String id = appointment['id'].toLowerCase();
        final String hospital = appointment['hospital'].toLowerCase();
        
        final query = _searchQuery.toLowerCase();
        
        return patientName.contains(query) || 
               doctorName.contains(query) || 
               id.contains(query) || 
               hospital.contains(query);
      }
      
      return true;
    }).toList();
  }
  
  // Get a list of all doctors for filtering
  List<String> get _doctorsList {
    final Set<String> doctors = {'All Doctors'};
    for (final appointment in _appointments) {
      doctors.add(appointment['doctorName']);
    }
    return doctors.toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search appointments...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF3366CC)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                SizedBox(height: 16),
                
                // Filters
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Filter chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Status filter
                    _buildFilterDropdown(
                      label: 'Status',
                      value: _selectedStatusFilter,
                      items: ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatusFilter = value;
                          });
                        }
                      },
                    ),
                    
                    // Doctor filter
                    _buildFilterDropdown(
                      label: 'Doctor',
                      value: _selectedDoctorFilter,
                      items: _doctorsList,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDoctorFilter = value;
                          });
                        }
                      },
                    ),
                    
                    // Date range filter
                    _buildDateRangeFilter(),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1),
          
          // Appointments list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = filteredAppointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No appointments found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Reset Filters'),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedStatusFilter = 'All';
                _selectedDoctorFilter = 'All Doctors';
                _selectedDateRange = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366CC),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          DropdownButton<String>(
            value: value,
            icon: Icon(Icons.arrow_drop_down, size: 18),
            underline: SizedBox(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateRangeFilter() {
    final String displayText = _selectedDateRange != null
        ? '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}'
        : 'Select Date Range';
    
    return InkWell(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2022),
          lastDate: DateTime.now().add(Duration(days: 365)),
          initialDateRange: _selectedDateRange ?? DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 30)),
            end: DateTime.now(),
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF3366CC),
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 18,
              color: Color(0xFF3366CC),
            ),
            SizedBox(width: 8),
            Text(
              displayText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (_selectedDateRange != null) ...[
              SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedDateRange = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    Color statusColor;
    switch (appointment['status']) {
      case 'Confirmed':
        statusColor = Color(0xFF4CAF50);
        break;
      case 'Pending':
        statusColor = Color(0xFFFFC107);
        break;
      case 'Completed':
        statusColor = Color(0xFF3366CC);
        break;
      case 'Cancelled':
        statusColor = Color(0xFFFF5722);
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${appointment['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    appointment['status'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Appointment details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor and patient info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        appointment['doctorName'].substring(0, 1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3366CC),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['doctorName'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            appointment['specialty'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    SizedBox(width: 16),
                    // Patient avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        appointment['patientName'].substring(0, 1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
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
                          Text(
                            'Patient',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Appointment date and time
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: appointment['date'],
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: appointment['time'],
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: appointment['hospital'],
                      ),
                      if (appointment['type'] != null) ...[
                        SizedBox(height: 8),
                        _buildDetailRow(
                          icon: appointment['type'] == 'Video Consultation'
                              ? Icons.videocam
                              : Icons.person,
                          label: 'Type',
                          value: appointment['type'],
                        ),
                      ],
                      SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.medical_services,
                        label: 'Reason',
                        value: appointment['reason'],
                      ),
                      if (appointment['amount'] != null) ...[
                        SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.payments,
                          label: 'Fee',
                          value: appointment['displayAmount'] ?? 'Rs ${appointment['amount']}',
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    if (appointment['status'] == 'Pending' || 
                        appointment['status'] == 'Confirmed') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.check_circle),
                          label: Text('Confirm'),
                          onPressed: () => _showConfirmationDialog(
                            appointment['id'],
                            'Are you sure you want to confirm this appointment?',
                            'Confirm',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF4CAF50),
                            side: BorderSide(color: Color(0xFF4CAF50)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    
                    if (appointment['status'] != 'Cancelled' &&
                        appointment['status'] != 'Completed') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.cancel),
                          label: Text('Cancel'),
                          onPressed: () => _showConfirmationDialog(
                            appointment['id'],
                            'Are you sure you want to cancel this appointment?',
                            'Cancel',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFFFF5722),
                            side: BorderSide(color: Color(0xFFFF5722)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('Edit'),
                        onPressed: () => _showEditDialog(appointment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF3366CC),
                          side: BorderSide(color: Color(0xFF3366CC)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 8),
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.visibility),
                        label: Text('View'),
                        onPressed: () => _showAppointmentDetails(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3366CC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
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
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  // Show confirmation dialog for actions
  void _showConfirmationDialog(String appointmentId, String message, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Appointment'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement the action logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment ${action.toLowerCase()}ed successfully'),
                  backgroundColor: action == 'Confirm' ? Color(0xFF4CAF50) : Color(0xFFFF5722),
                ),
              );
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }
  
  // Show edit dialog
  void _showEditDialog(Map<String, dynamic> appointment) {
    // This would typically open a form to edit appointment details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Appointment'),
        content: Text('Editing appointment ${appointment['id']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment updated successfully'),
                  backgroundColor: Color(0xFF3366CC),
                ),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Show appointment details
  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    // This would typically open a detailed view of the appointment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: Text('Viewing details for appointment ${appointment['id']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Mock appointment data
  List<Map<String, dynamic>> _getMockAppointments() {
    return [
      {
        "id": "APT123456",
        "patientId": "P001",
        "doctorId": "D001",
        "patientName": "Ahmed Khan",
        "doctorName": "Dr. Sara Malik",
        "specialty": "Cardiologist",
        "date": "15 Jun 2023",
        "time": "09:00 AM",
        "hospital": "Aga Khan Hospital, Karachi",
        "reason": "Chest Pain",
        "status": "Completed",
        "amount": 2500,
        "displayAmount": "Rs 2,500",
        "type": "In-Person Visit",
      },
      {
        "id": "APT123457",
        "patientId": "P002",
        "doctorId": "D002",
        "patientName": "Fatima Ali",
        "doctorName": "Dr. Usman Ahmed",
        "specialty": "Dermatologist",
        "date": "20 Jun 2023",
        "time": "02:30 PM",
        "hospital": "Shifa International Hospital, Islamabad",
        "reason": "Skin Rash",
        "status": "Confirmed",
        "amount": 2000,
        "displayAmount": "Rs 2,000",
        "type": "Video Consultation",
      },
      {
        "id": "APT123458",
        "patientId": "P003",
        "doctorId": "D003",
        "patientName": "Bilal Khan",
        "doctorName": "Dr. Ayesha Iqbal",
        "specialty": "Orthopedic",
        "date": "25 Jun 2023",
        "time": "11:00 AM",
        "hospital": "Liaquat National Hospital, Karachi",
        "reason": "Knee Pain",
        "status": "Pending",
        "amount": 3000,
        "displayAmount": "Rs 3,000",
        "type": "In-Person Visit",
      },
      {
        "id": "APT123459",
        "patientId": "P004",
        "doctorId": "D001",
        "patientName": "Sara Ahmed",
        "doctorName": "Dr. Sara Malik",
        "specialty": "Cardiologist",
        "date": "28 Jun 2023",
        "time": "04:15 PM",
        "hospital": "Aga Khan Hospital, Karachi",
        "reason": "Follow-up",
        "status": "Confirmed",
        "amount": 2500,
        "displayAmount": "Rs 2,500",
        "type": "Video Consultation",
      },
      {
        "id": "APT123460",
        "patientId": "P005",
        "doctorId": "D004",
        "patientName": "Ali Hassan",
        "doctorName": "Dr. Zainab Khan",
        "specialty": "Neurologist",
        "date": "30 Jun 2023",
        "time": "10:45 AM",
        "hospital": "CMH Hospital, Lahore",
        "reason": "Headache",
        "status": "Cancelled",
        "amount": 3500,
        "displayAmount": "Rs 3,500",
        "type": "In-Person Visit",
      },
      {
        "id": "APT123461",
        "patientId": "P006",
        "doctorId": "D005",
        "patientName": "Zainab Malik",
        "doctorName": "Dr. Fahad Ahmed",
        "specialty": "Gynecologist",
        "date": "02 Jul 2023",
        "time": "09:30 AM",
        "hospital": "Jinnah Hospital, Karachi",
        "reason": "Prenatal Checkup",
        "status": "Pending",
        "amount": 2800,
        "displayAmount": "Rs 2,800",
        "type": "In-Person Visit",
      },
      {
        "id": "APT123462",
        "patientId": "P007",
        "doctorId": "D006",
        "patientName": "Usman Ali",
        "doctorName": "Dr. Asad Khan",
        "specialty": "ENT Specialist",
        "date": "05 Jul 2023",
        "time": "01:00 PM",
        "hospital": "PIMS Hospital, Islamabad",
        "reason": "Ear Infection",
        "status": "Confirmed",
        "amount": 2200,
        "displayAmount": "Rs 2,200",
        "type": "In-Person Visit",
      },
    ];
  }
} 