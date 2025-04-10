import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagePatients extends StatefulWidget {
  const ManagePatients({Key? key}) : super(key: key);

  @override
  State<ManagePatients> createState() => _ManagePatientsState();
}

class _ManagePatientsState extends State<ManagePatients> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<String> _statusFilters = ['All', 'Active', 'Blocked'];
  String _selectedStatusFilter = 'All';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Patients',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // Clear search results
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
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                // Filter patients
              },
            ),
          ),
          
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.filter_list),
                  label: Text('Filter'),
                  onPressed: () {
                    // Show filter options
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: Icon(Icons.sort),
                  label: Text('Sort'),
                  onPressed: () {
                    // Show sort options
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Patient list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 10, // Replace with actual patient count
              itemBuilder: (context, index) {
                return _buildPatientCard(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, int index) {
    // Replace with actual patient data
    final patientName = 'Patient ${index + 1}';
    final patientEmail = 'patient${index + 1}@example.com';
    final patientPhone = '+92 300 1234${index.toString().padLeft(3, '0')}';
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    patientName.substring(0, 1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(Icons.email, patientEmail),
                      SizedBox(height: 4),
                      _buildInfoRow(Icons.phone, patientPhone),
                      SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.location_on,
                        'Karachi, Pakistan',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  label: 'View',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  onTap: () {
                    // View patient details
                  },
                ),
                _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit,
                  color: Colors.orange,
                  onTap: () {
                    // Edit patient
                  },
                ),
                _buildActionButton(
                  label: index % 3 == 0 ? 'Unblock' : 'Block',
                  icon: index % 3 == 0 ? Icons.lock_open : Icons.block,
                  color: index % 3 == 0 ? Colors.green : Colors.red,
                  onTap: () {
                    // Block/unblock patient
                  },
                ),
                _buildActionButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  color: Colors.red.shade700,
                  onTap: () {
                    // Delete patient
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}