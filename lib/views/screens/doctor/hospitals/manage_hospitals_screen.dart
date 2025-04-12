import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../services/doctor_availability_service.dart';
// We'll use the embedded class below instead
// import '../../../../utils/hospital_data.dart';

// Embedded hospital data to avoid import issues
class _HospitalData {
  // List of major cities in Pakistan
  static const List<String> pakistanCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Faisalabad',
    'Rawalpindi',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala',
    'Hyderabad',
  ];

  // Mapping of cities to hospitals
  static const Map<String, List<String>> hospitalsByCity = {
    'Karachi': [
      'Aga Khan University Hospital',
      'Jinnah Postgraduate Medical Centre',
      'Liaquat National Hospital',
      'South City Hospital',
      'National Medical Centre',
    ],
    'Lahore': [
      'Shaukat Khanum Memorial Cancer Hospital',
      'Doctors Hospital',
      'Sheikh Zayed Hospital',
      'Services Hospital',
      'Mayo Hospital',
    ],
    'Islamabad': [
      'Pakistan Institute of Medical Sciences (PIMS)',
      'Shifa International Hospital',
      'Federal Government Services Hospital',
      'Ali Medical Centre',
      'Maroof International Hospital',
    ],
    'Faisalabad': [
      'Allied Hospital',
      'DHQ Hospital',
      'Faisalabad Institute of Cardiology',
      'National Hospital',
      'Mujahid Hospital',
    ],
    'Rawalpindi': [
      'Combined Military Hospital (CMH)',
      'Holy Family Hospital',
      'Benazir Bhutto Hospital',
      'Rawalpindi General Hospital',
      'Cantonment General Hospital',
    ],
    'Multan': [
      'Nishtar Hospital',
      'Chaudhry Pervaiz Elahi Institute of Cardiology',
      'Children Complex Hospital',
      'Fatima Jinnah Hospital',
      'Combined Military Hospital Multan',
    ],
    'Peshawar': [
      'Lady Reading Hospital',
      'Khyber Teaching Hospital',
      'Hayatabad Medical Complex',
      'Northwest General Hospital',
      'Rahman Medical Institute',
    ],
    'Quetta': [
      'Civil Hospital',
      'Bolan Medical Complex',
      'Combined Military Hospital Quetta',
      'Akram Hospital',
      'Helper Hospital',
    ],
    'Sialkot': [
      'Allama Iqbal Memorial Hospital',
      'Combined Military Hospital Sialkot',
      'Sialkot Medical Complex',
      'Idrees Teaching Hospital',
    ],
    'Gujranwala': [
      'DHQ Hospital',
      'Combined Military Hospital Gujranwala',
      'Siddique Sadiq Memorial Trust Hospital',
      'City Hospital',
    ],
    'Hyderabad': [
      'Liaquat University Hospital',
      'Isra University Hospital',
      'Red Crescent Hospital',
      'Asian Hospital',
      'Civil Hospital',
    ],
  };
}

class ManageHospitalsScreen extends StatefulWidget {
  const ManageHospitalsScreen({super.key});

  @override
  State<ManageHospitalsScreen> createState() => _ManageHospitalsScreenState();
}

class _ManageHospitalsScreenState extends State<ManageHospitalsScreen> {
  final DoctorAvailabilityService _service = DoctorAvailabilityService();
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  
  List<Map<String, dynamic>> _myHospitals = [];
  List<Map<String, dynamic>> _allHospitals = [];
  List<Map<String, dynamic>> _filteredHospitals = [];

  final TextEditingController _searchController = TextEditingController();
  
  // Add new hospital controllers
  final TextEditingController _hospitalNameController = TextEditingController();
  String? _selectedCity;
  String? _selectedHospital;
  final TextEditingController _hospitalAddressController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Delay loading to allow UI to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load data in parallel to speed up the process
      final hospitalsData = await Future.wait([
        _service.getDoctorHospitals(),
        _service.getAllHospitals(),
      ]);
      
      if (!mounted) return;
      
      // Update state once with all data to prevent multiple rebuilds
      setState(() {
        _myHospitals = hospitalsData[0];
        _allHospitals = hospitalsData[1];
        
        // Filter out hospitals already assigned to the doctor
        _filteredHospitals = _filterHospitals(
          allHospitals: hospitalsData[1], 
          assignedHospitals: hospitalsData[0],
          searchQuery: _searchQuery
        );
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load hospitals: ${e.toString()}');
    }
  }
  
  // Pure function to filter hospitals - doesn't trigger setState
  List<Map<String, dynamic>> _filterHospitals({
    required List<Map<String, dynamic>> allHospitals,
    required List<Map<String, dynamic>> assignedHospitals,
    required String searchQuery,
  }) {
    // Create a set of hospital IDs that the doctor is already assigned to
    final Set<String> assignedHospitalIds = 
        assignedHospitals.map((h) => h['hospitalId'] as String).toSet();
    
    // Always filter out already assigned hospitals
    final filtered = allHospitals
        .where((h) => !assignedHospitalIds.contains(h['id']))
        .toList();
    
    // If search query is empty, return all unassigned hospitals
    if (searchQuery.isEmpty) {
      return filtered;
    }
    
    // Otherwise, filter by search query too
    final lowercaseQuery = searchQuery.toLowerCase();
    return filtered
        .where((h) => 
            h['name'].toString().toLowerCase().contains(lowercaseQuery) ||
            h['city'].toString().toLowerCase().contains(lowercaseQuery))
        .toList();
  }
  
  void _filterHospitalsBySearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredHospitals = _filterHospitals(
        allHospitals: _allHospitals,
        assignedHospitals: _myHospitals,
        searchQuery: query
      );
    });
  }
  
  Future<void> _addHospitalToDoctor(Map<String, dynamic> hospital) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _service.addHospitalToDoctor(
        hospitalId: hospital['id'],
        hospitalName: '${hospital['name']}, ${hospital['city']}',
      );
      
      if (result['success']) {
        // Reload data
        await _loadData();
        
        // Show success message
        _showSuccessSnackBar('Hospital added successfully');
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add hospital: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Create a new hospital
  Future<void> _createNewHospital() async {
    // No city selected
    if (_selectedCity == null) {
      _showErrorSnackBar('City is required');
      return;
    }
    
    // No hospital selected from dropdown and no custom name entered
    if (_selectedHospital == null && _hospitalNameController.text.isEmpty) {
      _showErrorSnackBar('Please select an existing hospital or enter a custom hospital name');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // If a predefined hospital is selected, use that, otherwise use the custom name
      final hospitalName = _selectedHospital ?? _hospitalNameController.text.trim();
      
      final result = await _service.createHospital(
        name: hospitalName,
        city: _selectedCity!,
        address: _hospitalAddressController.text.trim(),
      );
      
      if (result['success']) {
        // Clear form
        _hospitalNameController.clear();
        _selectedCity = null;
        _selectedHospital = null;
        _hospitalAddressController.clear();
        
        // Close dialog
        Navigator.pop(context);
        
        // Reload data
        await _loadData();
        
        // Show success message
        _showSuccessSnackBar('Hospital created and added to your profile');
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create hospital: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Helper method to build a dropdown
  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF3366CC)),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<T>>((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayText(item)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  // Show dialog to add a new hospital
  void _showAddHospitalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.add_business,
                            color: Color(0xFF3366CC),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Add New Hospital",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // City selection first
                      _buildDropdown<String>(
                        label: "City *",
                        hint: "Select a city",
                        value: _selectedCity,
                        items: _HospitalData.pakistanCities,
                        onChanged: (value) {
                          // Update both states
                          setState(() {
                            _selectedCity = value;
                            _selectedHospital = null;
                          });
                          print("Selected city: $_selectedCity");
                          print("Available hospitals: ${_HospitalData.hospitalsByCity[_selectedCity]}");
                          print("Contains key? ${_HospitalData.hospitalsByCity.containsKey(_selectedCity)}");
                          dialogSetState(() {});
                        },
                        displayText: (value) => value,
                      ),
                      SizedBox(height: 16),
                      
                      // Hospital selection (only shown when a city is selected)
                      if (_selectedCity != null) 
                        Text("DEBUG: City is selected: $_selectedCity"),
                      
                      if (_selectedCity != null && _HospitalData.hospitalsByCity.containsKey(_selectedCity)) ...[
                        Text("DEBUG: hospitalsByCity contains key $_selectedCity"),
                        // Debug list of hospitals
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("DEBUG: Available Hospitals:", style: TextStyle(fontWeight: FontWeight.bold)),
                              ...(_HospitalData.hospitalsByCity[_selectedCity] ?? []).map((hospital) => 
                                Text("- $hospital")
                              ).toList(),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Simpler dropdown implementation for hospitals
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Existing Hospital",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButton<String>(
                                value: _selectedHospital,
                                hint: Text(
                                  "Choose a hospital from the list",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                isExpanded: true,
                                underline: SizedBox(),
                                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF3366CC)),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedHospital = value;
                                    if (value != null) {
                                      _hospitalNameController.text = value;
                                    }
                                  });
                                  dialogSetState(() {});
                                },
                                items: _HospitalData.hospitalsByCity[_selectedCity]!
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Or enter a custom hospital name below",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      
                      // Hospital name (only required if no hospital is selected from dropdown)
                      Text(
                        _selectedHospital == null ? "Hospital Name *" : "Hospital Name (Optional)",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _hospitalNameController,
                        hintText: _selectedHospital == null 
                          ? "e.g. Aga Khan Hospital" 
                          : "Using selected hospital: $_selectedHospital",
                        enabled: _selectedHospital == null,
                      ),
                      SizedBox(height: 16),
                      
                      // Address
                      Text(
                        "Address",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildTextField(
                        controller: _hospitalAddressController,
                        hintText: "e.g. Stadium Road, Karachi",
                      ),
                      SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade800,
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createNewHospital,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3366CC),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Create & Add",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Manage Hospitals',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            tooltip: 'Add new hospital',
            onPressed: _showAddHospitalDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF3366CC),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading hospitals...",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHospitalDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
                _filterHospitalsBySearch(value);
              },
              decoration: InputDecoration(
                hintText: 'Search hospitals...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                          });
                          _filterHospitalsBySearch('');
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
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
        ),
        
        // My hospitals section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'My Hospitals',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        
        if (_myHospitals.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You haven\'t added any hospitals yet. Add a hospital below to get started.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final hospital = _myHospitals[index];
                return _buildHospitalCard(
                  hospital: hospital,
                  isAssigned: true,
                );
              },
              childCount: _myHospitals.length,
            ),
          ),
        
        // Available hospitals section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Available Hospitals',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(${_filteredHospitals.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddHospitalDialog,
                  icon: Icon(Icons.add, size: 18),
                  label: Text("New"),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF3366CC),
                    backgroundColor: Color(0xFFEDF7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (_filteredHospitals.isEmpty && _isSearching)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No hospitals found matching "$_searchQuery"',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddHospitalDialog,
                      icon: Icon(Icons.add),
                      label: Text("Add New Hospital"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3366CC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_filteredHospitals.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green.shade400,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'You\'ve added all available hospitals',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddHospitalDialog,
                      icon: Icon(Icons.add),
                      label: Text("Add New Hospital"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3366CC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final hospital = _filteredHospitals[index];
                return _buildHospitalCard(
                  hospital: hospital,
                  isAssigned: false,
                  onAdd: () => _addHospitalToDoctor(hospital),
                );
              },
              childCount: _filteredHospitals.length,
            ),
          ),
      ],
    );
  }

  Widget _buildHospitalCard({
    required Map<String, dynamic> hospital,
    required bool isAssigned,
    VoidCallback? onAdd,
  }) {
    final String name = isAssigned 
        ? hospital['hospitalName'] 
        : "${hospital['name']}, ${hospital['city']}";

    final String address = isAssigned
        ? hospital['hospitalName'].toString().split(', ')[1]
        : hospital['address'] ?? '';
    
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isAssigned ? null : onAdd,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isAssigned ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: isAssigned ? Colors.blue.shade700 : Colors.grey.shade700,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.split(', ')[0],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          address,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAssigned)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }
} 