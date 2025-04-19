import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/views/screens/admin/admin_dashboard.dart';

// Create a DoctorProfileScreen class
class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _doctorData;
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = false;
  double _overallRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try to get from doctors collection
      var docSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .get();

      // If not found, try to get from users collection
      if (!docSnapshot.exists) {
        debugPrint('Doctor not found in doctors collection, trying users collection');
        docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.doctorId)
            .get();
      }

      if (docSnapshot.exists) {
        setState(() {
          _doctorData = docSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
        
        // After loading profile, load reviews
        _loadReviews();
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor profile not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading doctor profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading doctor profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !mounted) {
        setState(() {
          _loadingReviews = false;
        });
        return;
      }
      
      debugPrint('Loading reviews for doctor ID: ${widget.doctorId}');
      
      // Direct query to Firestore for reviews
      final QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('doctor_reviews')
          .where('doctorId', isEqualTo: widget.doctorId)
          .get();
      
      debugPrint('Found ${reviewsSnapshot.docs.length} reviews');
      
      double totalRating = 0;
      int reviewCount = reviewsSnapshot.docs.length;
      final List<Map<String, dynamic>> reviews = [];
      
      for (var doc in reviewsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Extract rating
          double rating = 0.0;
          if (data.containsKey('rating')) {
            if (data['rating'] is num) {
              rating = (data['rating'] as num).toDouble();
              totalRating += rating; // Add to total for average calculation
            }
          }
          
          // Extract patient name
          String patientName = 'Anonymous Patient';
          if (data.containsKey('patientName')) {
            patientName = data['patientName'] ?? 'Anonymous Patient';
          } else if (data.containsKey('userName')) {
            patientName = data['userName'] ?? 'Anonymous Patient';
          } else if (data.containsKey('userFullName')) {
            patientName = data['userFullName'] ?? 'Anonymous Patient';
          }
          
          // Extract comment
          String comment = 'No comment provided';
          if (data.containsKey('comment')) {
            comment = data['comment'] ?? 'No comment provided';
          } else if (data.containsKey('text')) {
            comment = data['text'] ?? 'No comment provided';
          } else if (data.containsKey('review')) {
            comment = data['review'] ?? 'No comment provided';
          }
          
          // Extract date
          DateTime createdAt;
          if (data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          } else if (data.containsKey('timestamp') && data['timestamp'] is Timestamp) {
            createdAt = (data['timestamp'] as Timestamp).toDate();
          } else {
            createdAt = DateTime.now();
          }
          
          reviews.add({
            'id': doc.id,
            'rating': rating,
            'comment': comment,
            'patientName': patientName,
            'createdAt': createdAt,
          });
        } catch (e) {
          debugPrint('Error processing review: $e');
        }
      }
      
      // Calculate average rating
      double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
      
      setState(() {
        _reviews = reviews;
        _overallRating = averageRating;
        _reviewCount = reviewCount;
        _loadingReviews = false;
      });
      
      debugPrint('Processed $reviewCount reviews with average rating $averageRating');
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doctor Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctorData == null
              ? Center(
                  child: Text(
                    'Doctor profile not found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor profile header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _doctorData!['profilePicture'] != null
                                ? NetworkImage(_doctorData!['profilePicture'])
                                : _doctorData!['profileImageUrl'] != null
                                    ? NetworkImage(_doctorData!['profileImageUrl'])
                                    : null,
                            child: (_doctorData!['profilePicture'] == null && _doctorData!['profileImageUrl'] == null)
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${_doctorData!['name'] ?? _doctorData!['fullName'] ?? 'Unknown'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _doctorData!['specialization'] ?? _doctorData!['specialty'] ?? 'Specialization not specified',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _doctorData!['status'] ?? (_doctorData!['isActive'] == true ? 'Active' : 'Inactive'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _doctorData!['status'] == 'Active' || _doctorData!['isActive'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Doctor info sections
                      _buildInfoSection('Contact Information', [
                        _buildInfoItem(Icons.email, 'Email', _doctorData!['email'] ?? 'Not provided'),
                        _buildInfoItem(Icons.phone, 'Phone', _doctorData!['phoneNumber'] ?? 'Not provided'),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('Professional Details', [
                        _buildInfoItem(Icons.work, 'Experience', '${_doctorData!['experience'] ?? 'Not specified'} years'),
                        _buildInfoItem(Icons.attach_money, 'Fee', 'Rs. ${_doctorData!['fee'] ?? 'Not specified'}'),
                        _buildInfoItem(Icons.star, 'Rating', '${_overallRating.toStringAsFixed(1)}/5.0'),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('About', [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _doctorData!['bio'] ?? 'No biography provided.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // Reviews Section
                      _buildInfoSection(
                        'Patient Reviews (${_reviewCount})', 
                        [
                          if (_loadingReviews)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_reviews.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No reviews available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                // Rating summary card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _overallRating.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(64, 124, 226, 1),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index < _overallRating
                                                    ? Icons.star
                                                    : index < _overallRating + 0.5
                                                        ? Icons.star_half
                                                        : Icons.star_border,
                                                color: Colors.amber,
                                                size: 20,
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Based on $_reviewCount reviews",
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Individual reviews
                                ...(_reviews.map((review) => _buildReviewItem(review)).toList()),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewItem(Map<String, dynamic> review) {
    final double rating = review['rating'] is double 
        ? review['rating'] as double
        : (review['rating'] is int) 
            ? (review['rating'] as int).toDouble() 
            : 0.0;
            
    final DateTime createdAt = review['createdAt'] as DateTime;
    final String formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        review['patientName'].toString().substring(0, 1).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['patientName'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review['comment'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageDoctors extends StatefulWidget {
  const ManageDoctors({super.key});

  @override
  State<ManageDoctors> createState() => _ManageDoctorsState();
}

class _ManageDoctorsState extends State<ManageDoctors> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDoctors();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final doctors = await _adminService.getAllDoctors();
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors: $e')),
      );
    }
  }
  
  // Filter doctors based on status and search query
  List<Map<String, dynamic>> _getFilteredDoctors(String status) {
    // First filter by status
    final filteredByStatus = _doctors.where((doctor) {
      if (status == 'available') {
        return doctor['status'] != 'Inactive'; // All doctors that are not inactive
      } else if (status == 'blocked') {
        return doctor['status'] == 'Inactive';
      }
      return false;
    }).toList();
    
    // Then filter by search query if it exists
    if (_searchQuery.isEmpty) {
      return filteredByStatus;
    }
    
    final lowerCaseQuery = _searchQuery.toLowerCase();
    return filteredByStatus.where((doctor) {
      final name = (doctor['name'] ?? '').toLowerCase();
      final specialty = (doctor['specialty'] ?? '').toLowerCase();
      final email = (doctor['email'] ?? '').toLowerCase();
      final phone = (doctor['phoneNumber'] ?? '').toLowerCase();
      
      return name.contains(lowerCaseQuery) || 
             specialty.contains(lowerCaseQuery) ||
             email.contains(lowerCaseQuery) ||
             phone.contains(lowerCaseQuery);
    }).toList();
  }
  
  // Action handlers
  void _showActionDialog(String action, Map<String, dynamic> doctor) {
    String title = '';
    String content = '';
    Color confirmColor = Colors.red;
    
    switch (action) {
      case 'approve':
        title = 'Approve Doctor';
        content = 'Are you sure you want to approve this doctor? They will be able to accept appointments from patients.';
        confirmColor = Color(0xFF4CAF50);
        break;
      case 'reject':
        title = 'Reject Doctor';
        content = 'Are you sure you want to reject this doctor\'s application?';
        confirmColor = Color(0xFFFF5722);
        break;
      case 'block':
        title = 'Block Doctor';
        content = 'Are you sure you want to block this doctor? They will not be able to access the platform until unblocked.';
        confirmColor = Color(0xFFFF5722);
        break;
      case 'unblock':
        title = 'Unblock Doctor';
        content = 'Are you sure you want to unblock this doctor? They will regain access to the platform.';
        confirmColor = Color(0xFF4CAF50);
        break;
      case 'delete':
        title = 'Delete Doctor';
        content = 'Are you sure you want to permanently delete this doctor? This action cannot be undone.';
        confirmColor = Colors.red.shade700;
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performAction(action, doctor);
            },
            child: Text(
              action.substring(0, 1).toUpperCase() + action.substring(1),
              style: TextStyle(color: confirmColor),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performAction(String action, Map<String, dynamic> doctor) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String message = '';
      
      switch (action) {
        case 'approve':
          // Use AdminService to update verification status
          final result = await _adminService.updateDoctorVerification(doctor['id'], true);
          if (result['success']) {
            message = 'Doctor successfully approved';
          } else {
            throw Exception(result['message']);
          }
          break;
        case 'reject':
        case 'delete':
          // Use AdminService to delete doctor
          final result = await _adminService.deleteDoctor(doctor['id']);
          if (result['success']) {
            message = 'Doctor successfully ${action}ed';
          } else {
            throw Exception(result['message']);
          }
          break;
        case 'block':
          // Use AdminService to update active status
          final result = await _adminService.updateDoctorActiveStatus(doctor['id'], false);
          if (result['success']) {
            message = 'Doctor successfully blocked';
          } else {
            throw Exception(result['message']);
          }
          break;
        case 'unblock':
          // Use AdminService to update active status
          final result = await _adminService.updateDoctorActiveStatus(doctor['id'], true);
          if (result['success']) {
            message = 'Doctor successfully unblocked';
          } else {
            throw Exception(result['message']);
          }
          break;
      }
      
      // Refresh doctor list
      await _loadDoctors();
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: action == 'reject' || action == 'block' || action == 'delete' 
              ? Colors.red 
              : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showDoctorEditDialog(Map<String, dynamic> doctor) {
    final TextEditingController nameController = TextEditingController(text: doctor['name']);
    final TextEditingController specialtyController = TextEditingController(text: doctor['specialty']);
    final TextEditingController phoneController = TextEditingController(text: doctor['phoneNumber']);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Doctor Details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter doctor\'s name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: specialtyController,
                    decoration: InputDecoration(
                      labelText: 'Specialty',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter specialty';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    isSubmitting = true;
                  });
                  
                  try {
                    final result = await _adminService.updateDoctorDetails(
                      doctor['id'],
                      {
                        'fullName': nameController.text.trim(),
                        'specialty': specialtyController.text.trim(),
                        'phoneNumber': phoneController.text.trim(),
                      },
                    );
                    
                    if (result['success']) {
                      // Close dialog and refresh data
                      Navigator.pop(context);
                      await _loadDoctors();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Doctor details updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      setState(() {
                        isSubmitting = false;
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${result['message']}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setState(() {
                      isSubmitting = false;
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: isSubmitting 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _contactDoctor(Map<String, dynamic> doctor) {
    // Get doctor's email and phone
    final String email = doctor['email'] ?? '';
    final String phone = doctor['phoneNumber'] ?? '';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Dr. ${doctor['name']}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            if (email.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.email, color: Colors.blue),
                ),
                title: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(email),
                onTap: () async {
                  // Launch email client
                  final Uri emailUri = Uri.parse('mailto:$email');
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch email client')),
                    );
                  }
                },
              ),
            if (phone.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone, color: Colors.green),
                ),
                title: Text(
                  'Phone',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(phone),
                onTap: () async {
                  // Launch phone dialer
                  final Uri phoneUri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch phone dialer')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _viewDoctorProfile(Map<String, dynamic> doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfileScreen(doctorId: doctor['id']),
      ),
    );
  }
  
  void _showBlockDoctorDialog(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Block Doctor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to block Dr. ${doctor['name']}?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Reason for blocking (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockDoctor(doctor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Block',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
  
  void _blockDoctor(Map<String, dynamic> doctor) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await AdminService().updateDoctorStatus(doctor['id'], 'Inactive');
      
      // Fetch doctors again
      await _loadDoctors();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dr. ${doctor['name']} has been blocked'),
          backgroundColor: Colors.red[400],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block doctor: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _activateDoctor(Map<String, dynamic> doctor) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await AdminService().updateDoctorStatus(doctor['id'], 'Active');
      
      // Fetch doctors again
      await _loadDoctors();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dr. ${doctor['name']} has been activated'),
          backgroundColor: Colors.green[400],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate doctor: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final bool isSmallScreen = screenWidth < 360;
    final double padding = screenWidth * 0.04;
    
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to admin dashboard and select the home tab
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Doctors'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'Blocked'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(padding),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search doctors...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDoctorsList('available', screenWidth, screenHeight),
                          _buildDoctorsList('blocked', screenWidth, screenHeight),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDoctorsList(String status, double screenWidth, double screenHeight) {
    final doctors = _getFilteredDoctors(status);
    final double padding = screenWidth * 0.04;
    
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: screenWidth * 0.2,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'No doctors found',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(
                  'Try a different search query',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(doctors[index], screenWidth, screenHeight);
      },
    );
  }
  
  Widget _buildDoctorCard(Map<String, dynamic> doctor, double screenWidth, double screenHeight) {
    final String status = doctor['status'] ?? 'Unknown';
    final bool isActive = status == 'Active';
    final Color statusColor = isActive 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFFF44336);
    
    final double cardPadding = screenWidth * 0.04;
    final double iconSize = screenWidth * 0.04;
    final double avatarRadius = screenWidth * 0.08;
    final double textSpacing = screenHeight * 0.01;
    final bool isSmallScreen = screenWidth < 360;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Avatar
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: doctor['profileImageUrl'] != null && doctor['profileImageUrl'].toString().isNotEmpty
                      ? NetworkImage(doctor['profileImageUrl']) as ImageProvider
                      : null,
                  child: doctor['profileImageUrl'] == null || doctor['profileImageUrl'].toString().isEmpty
                      ? Icon(Icons.person, size: avatarRadius, color: Colors.grey[600])
                      : null,
                ),
                SizedBox(width: screenWidth * 0.04),
                
                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Name and Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              doctor['name'] ?? 'Unknown Doctor',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025, 
                              vertical: screenHeight * 0.005
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(screenWidth * 0.075),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.035,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: textSpacing),
                      
                      // Specialty
                      Text(
                        doctor['specialty'] ?? 'General',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: textSpacing),
                      
                      // Rating and Experience in a row
                      Row(
                        children: [
                          // Rating
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: iconSize,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            '${doctor['rating'] ?? '0.0'} (${doctor['reviewCount'] ?? 0})',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.03,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          
                          // Experience
                          Icon(
                            Icons.work,
                            color: Colors.blue[700],
                            size: iconSize,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            '${doctor['experience'] ?? 'N/A'} experience',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.03,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: textSpacing),
                      
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                            size: iconSize,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: Text(
                              doctor['city'] != null && doctor['city'] != 'N/A'
                                  ? '${doctor['city']}'
                                  : 'Location not specified',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.03,
                                color: Colors.grey[600],
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
              ],
            ),
          ),
          
          // Doctor Stats
          Padding(
            padding: EdgeInsets.fromLTRB(
              cardPadding, 
              0, 
              cardPadding, 
              screenHeight * 0.01
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.event, 
                  '${doctor['appointmentCount'] ?? 0}',
                  'Appointments',
                  screenWidth,
                ),
                if (doctor['fee'] != null && doctor['fee'] != 0)
                  _buildStatItem(
                    Icons.attach_money, 
                    'Rs. ${doctor['fee']}',
                    'Fee',
                    screenWidth,
                  ),
                if (doctor['profileComplete'] == true)
                  _buildStatItem(
                    Icons.check_circle, 
                    'Complete',
                    'Profile',
                    screenWidth,
                    color: Colors.green,
                  )
                else
                  _buildStatItem(
                    Icons.error, 
                    'Incomplete',
                    'Profile',
                    screenWidth,
                    color: Colors.orange,
                  ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding, 
              vertical: screenHeight * 0.015
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(screenWidth * 0.03),
                bottomRight: Radius.circular(screenWidth * 0.03),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - screenWidth * 0.04) / 3;
                final bool useIcons = isSmallScreen;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Contact Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Handle contact logic here
                          _contactDoctor(doctor);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email,
                                size: iconSize,
                              ),
                              if (!useIcons) SizedBox(width: screenWidth * 0.01),
                              if (!useIcons)
                                Text(
                                  'Contact',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    
                    // View Button (for both active and inactive doctors)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle view profile logic here
                          _viewDoctorProfile(doctor);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: iconSize,
                              ),
                              if (!useIcons) SizedBox(width: screenWidth * 0.01),
                              if (!useIcons)
                                Text(
                                  'View',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
      
                    // Toggle Active Status Button
                    Expanded(
                      child: isActive
                          ? ElevatedButton(
                              onPressed: () {
                                _showBlockDoctorDialog(doctor);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                ),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: iconSize,
                                    ),
                                    if (!useIcons) SizedBox(width: screenWidth * 0.01),
                                    if (!useIcons)
                                      Text(
                                        'Block',
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.03,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                _activateDoctor(doctor);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                ),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      size: iconSize,
                                    ),
                                    if (!useIcons) SizedBox(width: screenWidth * 0.01),
                                    if (!useIcons)
                                      Text(
                                        'Activate',
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.03,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    IconData icon, 
    String value, 
    String label, 
    double screenWidth,
    {Color color = Colors.blue}
  ) {
    final double iconSize = screenWidth * 0.035;
    final double fontSize = screenWidth * 0.035;
    final double smallFontSize = screenWidth * 0.03;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            SizedBox(width: screenWidth * 0.01),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: smallFontSize,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}