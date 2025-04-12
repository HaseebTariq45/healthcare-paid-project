import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/views/screens/doctor/complete_profile/doctor_profile_page2.dart';
import 'dart:io';

class DoctorProfilePage1Screen extends StatefulWidget {
  const DoctorProfilePage1Screen({super.key});

  @override
  State<DoctorProfilePage1Screen> createState() => _DoctorProfilePage1ScreenState();
}

class _DoctorProfilePage1ScreenState extends State<DoctorProfilePage1Screen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Remove individual address fields and add selectedCity
  String? _selectedCity;
  
  // List of Pakistani cities in alphabetical order
  final List<String> _pakistaniCities = [
    "Abbottabad", "Adilpur", "Ahmadpur East", "Alipur", "Arifwala", "Attock",
    "Badin", "Bahawalnagar", "Bahawalpur", "Bannu", "Battagram", "Bhakkar", "Bhalwal", "Bhera", "Bhimbar", "Bhit Shah", "Bhopalwala", "Burewala",
    "Chaman", "Charsadda", "Chichawatni", "Chiniot", "Chishtian", "Chitral", "Chunian",
    "Dadu", "Daharki", "Daska", "Dera Ghazi Khan", "Dera Ismail Khan", "Dinga", "Dipalpur", "Duki",
    "Faisalabad", "Fateh Jang", "Fazilpur", "Fort Abbas",
    "Gambat", "Ghotki", "Gilgit", "Gojra", "Gwadar",
    "Hafizabad", "Hala", "Hangu", "Haripur", "Haroonabad", "Hasilpur", "Haveli Lakha", "Hazro", "Hub", "Hyderabad",
    "Islamabad", 
    "Jacobabad", "Jahanian", "Jalalpur Jattan", "Jampur", "Jamshoro", "Jatoi", "Jauharabad", "Jhelum",
    "Kabirwala", "Kahror Pakka", "Kalat", "Kamalia", "Kamoke", "Kandhkot", "Karachi", "Karak", "Kasur", "Khairpur", "Khanewal", "Khanpur", "Kharian", "Khushab", "Kohat", "Kot Addu", "Kotri", "Kumbar", "Kunri",
    "Lahore", "Laki Marwat", "Larkana", "Layyah", "Liaquatpur", "Lodhran", "Loralai",
    "Mailsi", "Malakwal", "Mandi Bahauddin", "Mansehra", "Mardan", "Mastung", "Matiari", "Mian Channu", "Mianwali", "Mingora", "Mirpur", "Mirpur Khas", "Multan", "Muridke", "Muzaffarabad", "Muzaffargarh",
    "Narowal", "Nawabshah", "Nowshera",
    "Okara",
    "Pakpattan", "Pasrur", "Pattoki", "Peshawar", "Pir Mahal",
    "Quetta",
    "Rahimyar Khan", "Rajanpur", "Rani Pur", "Rawalpindi", "Rohri", "Risalpur",
    "Sadiqabad", "Sahiwal", "Saidu Sharif", "Sakrand", "Samundri", "Sanghar", "Sargodha", "Sheikhupura", "Shikarpur", "Sialkot", "Sibi", "Sukkur", "Swabi", "Swat",
    "Talagang", "Tandlianwala", "Tando Adam", "Tando Allahyar", "Tando Muhammad Khan", "Tank", "Taunsa", "Taxila", "Toba Tek Singh", "Turbat",
    "Vehari",
    "Wah Cantonment", "Wazirabad"
  ];

  XFile? _profileImage;
  XFile? _medicalLicenseFront;
  XFile? _medicalLicenseBack;
  XFile? _cnicFront;
  XFile? _cnicBack;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<void> _pickDocument(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'license_front':
            _medicalLicenseFront = image;
            break;
          case 'license_back':
            _medicalLicenseBack = image;
            break;
          case 'cnic_front':
            _cnicFront = image;
            break;
          case 'cnic_back':
            _cnicBack = image;
            break;
        }
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(phone);
  }

  bool _validateFields() {
    // Commenting out validation for debugging
    /*
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedCity == null ||
        _profileImage == null ||
        _medicalLicenseFront == null ||
        _medicalLicenseBack == null ||
        _cnicFront == null ||
        _cnicBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and upload all required documents'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    */
    return true;
  }

  Widget _buildUploadBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    XFile? file,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3366CC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3366CC),
                  size: 24,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (file != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.check,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: const Color(0xFF3366CC),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // Text area widget for address
  Widget _buildTextArea({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        textAlignVertical: TextAlignVertical.top,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, top: 16),
            child: Icon(
              icon,
              color: const Color(0xFF3366CC),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        ),
      ),
    );
  }
  
  // City dropdown widget with enhanced design
  Widget _buildCityDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _selectedCity != null 
              ? const Color(0xFF3366CC)
              : Colors.grey.shade300,
          width: 1.5,
        ),
        gradient: _selectedCity != null 
            ? LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFF3366CC).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          canvasColor: Colors.white,
          dividerColor: Colors.transparent,
          shadowColor: const Color(0xFF3366CC).withOpacity(0.2),
        ),
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            value: _selectedCity,
            isExpanded: true,
            isDense: false,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedCity != null
                    ? const Color(0xFF3366CC).withOpacity(0.15)
                    : const Color(0xFF3366CC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.chevronDown,
                color: _selectedCity != null
                    ? const Color(0xFF3366CC)
                    : const Color(0xFF3366CC).withOpacity(0.7),
                size: 16,
              ),
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 350,
            itemHeight: 50,
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            decoration: InputDecoration(
              hintText: "Select City",
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_selectedCity != null)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3366CC).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Icon(
                      LucideIcons.building2,
                      color: const Color(0xFF3366CC),
                      size: 20,
                    ),
                  ],
                ),
              ),
              suffixIcon: _selectedCity != null
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCity = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 46),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.x,
                          color: Colors.grey.shade700,
                          size: 12,
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            selectedItemBuilder: (BuildContext context) {
              return _pakistaniCities.map<Widget>((String city) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    city,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList();
            },
            items: _pakistaniCities.map((String city) {
              // Group cities by first letter for better organization
              bool isFirstWithLetter = _pakistaniCities.indexOf(city) == 0 || 
                  _pakistaniCities[_pakistaniCities.indexOf(city) - 1][0] != city[0];
              
              return DropdownMenuItem<String>(
                value: city,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      // Section for the letter grouping indicator (if first letter)
                      if (isFirstWithLetter)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            city[0],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF3366CC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // Checkbox indicator
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _selectedCity == city
                              ? const Color(0xFF3366CC)
                              : Colors.transparent,
                          border: Border.all(
                            color: _selectedCity == city
                                ? const Color(0xFF3366CC)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: _selectedCity == city
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      
                      // City name
                      Expanded(
                        child: Text(
                          city,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _selectedCity == city
                                ? const Color(0xFF3366CC)
                                : Colors.black87,
                            fontWeight: _selectedCity == city
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCity = newValue;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Personal Information",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF3366CC)),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F8FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3366CC).withOpacity(0.8),
                      const Color(0xFF6699FF).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      File(_profileImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.9),
                                            Colors.white.withOpacity(0.7),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.user,
                                        size: 60,
                                        color: const Color(0xFF3366CC).withOpacity(0.7),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _profileImage == null ? LucideIcons.camera : LucideIcons.refreshCw,
                                  color: const Color(0xFF3366CC),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.imageUp,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Profile Picture",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Personal Information Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.user,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Personal Information",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      hint: "Full Name",
                      icon: LucideIcons.user,
                      controller: _nameController,
                    ),
                    _buildTextField(
                      hint: "Email",
                      icon: LucideIcons.mail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Medical License Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.fileText,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Medical License",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUploadBox(
                      title: "Front Side",
                      subtitle: "Upload the front side of your medical license",
                      icon: LucideIcons.fileImage,
                      onTap: () => _pickDocument('license_front'),
                      file: _medicalLicenseFront,
                    ),
                    _buildUploadBox(
                      title: "Back Side",
                      subtitle: "Upload the back side of your medical license",
                      icon: LucideIcons.fileImage,
                      onTap: () => _pickDocument('license_back'),
                      file: _medicalLicenseBack,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CNIC Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.idCard,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "CNIC",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUploadBox(
                      title: "Front Side",
                      subtitle: "Upload the front side of your CNIC",
                      icon: LucideIcons.fileImage,
                      onTap: () => _pickDocument('cnic_front'),
                      file: _cnicFront,
                    ),
                    _buildUploadBox(
                      title: "Back Side",
                      subtitle: "Upload the back side of your CNIC",
                      icon: LucideIcons.fileImage,
                      onTap: () => _pickDocument('cnic_back'),
                      file: _cnicBack,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Address Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366CC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            color: const Color(0xFF3366CC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Address Information",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextArea(
                      hint: "Complete Address",
                      icon: LucideIcons.building,
                      controller: _addressController,
                    ),
                    _buildCityDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366CC).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_validateFields()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorProfilePage2Screen(
                              fullName: _nameController.text,
                              email: _emailController.text,
                              address: _addressController.text,
                              city: _selectedCity ?? "",
                              profileImage: _profileImage,
                              medicalLicenseFront: _medicalLicenseFront,
                              medicalLicenseBack: _medicalLicenseBack,
                              cnicFront: _cnicFront,
                              cnicBack: _cnicBack,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366CC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Next",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}