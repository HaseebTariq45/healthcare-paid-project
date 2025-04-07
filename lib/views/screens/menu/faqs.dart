import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedCategoryIndex = 0;
  
  // Categories for FAQs
  final List<Map<String, dynamic>> _categories = [
    {
      "name": "All",
      "icon": LucideIcons.info,
      "color": 0xFF3366FF,
    },
    {
      "name": "Appointments",
      "icon": LucideIcons.calendar,
      "color": 0xFF4CAF50,
    },
    {
      "name": "Payments",
      "icon": LucideIcons.creditCard,
      "color": 0xFFFF9800,
    },
    {
      "name": "Medical",
      "icon": LucideIcons.stethoscope,
      "color": 0xFFE74C3C,
    },
  ];
  
  // Sample FAQ data
  final List<Map<String, dynamic>> _faqData = [
    {
      "category": "Appointments",
      "question": "How do I schedule an appointment?",
      "answer": "You can schedule an appointment through the app by navigating to the Appointments section, selecting your preferred doctor, and choosing an available time slot. You'll receive a confirmation once your appointment is booked."
    },
    {
      "category": "Appointments",
      "question": "How can I reschedule or cancel my appointment?",
      "answer": "To reschedule or cancel an appointment, go to the Appointments section, locate your upcoming appointment, and select the reschedule or cancel option. Please note that cancellations within 24 hours may incur a fee."
    },
    {
      "category": "Payments",
      "question": "What payment methods are accepted?",
      "answer": "We accept various payment methods including credit/debit cards, mobile wallets, and bank transfers. You can manage your payment methods in the Payment section of your profile."
    },
    {
      "category": "Payments",
      "question": "How do I add a new payment method?",
      "answer": "To add a new payment method, go to the Payment Methods section in your profile, tap the '+' button, and follow the prompts to add your card or wallet details. Your information is securely encrypted."
    },
    {
      "category": "Medical",
      "question": "How can I access my medical records?",
      "answer": "Your medical records are available in the Records section of your profile. You can view your history of consultations, prescriptions, and test results. All information is confidential and only accessible to you and your healthcare providers."
    },
    {
      "category": "Medical",
      "question": "How do I request a prescription refill?",
      "answer": "You can request a prescription refill by navigating to the Prescriptions section, selecting the medication you need refilled, and submitting a request. Your doctor will review and approve if appropriate."
    },
  ];
  
  // Track expanded state for each FAQ
  late List<bool> _expanded;
  // Animation controllers for each FAQ
  late List<AnimationController> _controllers;
  
  @override
  void initState() {
    super.initState();
    _expanded = List.generate(_faqData.length, (index) => false);
    _controllers = List.generate(
      _faqData.length, 
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      )
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get filtered FAQs based on search query and selected category
  List<Map<String, dynamic>> get filteredFAQs {
    return _faqData.where((faq) {
      // Filter by category
      final categoryMatch = _selectedCategoryIndex == 0 || faq["category"] == _categories[_selectedCategoryIndex]["name"];
      
      // Filter by search query
      final queryMatch = _searchQuery.isEmpty || 
          faq["question"].toLowerCase().contains(_searchQuery.toLowerCase()) || 
          faq["answer"].toLowerCase().contains(_searchQuery.toLowerCase());
      
      return categoryMatch && queryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Frequently Asked Questions",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Color(0xFF333333),
                ),
                decoration: InputDecoration(
                  hintText: "Search FAQs",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: Color(0xFF3366FF),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                    icon: Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = "";
                      });
                    },
                  ) : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          
          // Categories
          Container(
            height: 90,
            padding: EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(_categories[index]["color"]).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Color(_categories[index]["color"]).withOpacity(0.5)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _categories[index]["icon"],
                          color: Color(_categories[index]["color"]),
                          size: 24,
                        ),
                        SizedBox(height: 8),
                        Text(
                          _categories[index]["name"],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Color(_categories[index]["color"])
                                : Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // FAQ list header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  "FAQs",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF3366FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${filteredFAQs.length}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3366FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // FAQ list
          Expanded(
            child: filteredFAQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No FAQs found",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Try changing your search or category",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final originalIndex = _faqData.indexOf(filteredFAQs[index]);
                      return _buildFAQItem(filteredFAQs[index], originalIndex);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq, int index) {
    // Set up animations
    final Animation<double> heightAnimation = CurvedAnimation(
      parent: _controllers[index],
      curve: Curves.easeInOut,
    );
    
    final Animation<double> iconRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(heightAnimation);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _expanded[index] = !_expanded[index];
                if (_expanded[index]) {
                  _controllers[index].forward();
                } else {
                  _controllers[index].reverse();
                }
              });
            },
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category indicator
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(faq["category"]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Question
                      Expanded(
                        child: Text(
                          faq["question"],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      // Rotation animation for the expand icon
                      RotationTransition(
                        turns: iconRotationAnimation,
                        child: Icon(
                          LucideIcons.chevronDown,
                          color: Color(0xFF3366FF),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated expand
                SizeTransition(
                  sizeFactor: heightAnimation,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 32,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Divider
                        Container(
                          height: 1,
                          color: Colors.grey.shade200,
                          margin: EdgeInsets.only(bottom: 16),
                        ),
                        // Answer
                        Text(
                          faq["answer"],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final categoryData = _categories.firstWhere(
      (cat) => cat["name"] == category,
      orElse: () => _categories[0],
    );
    return Color(categoryData["color"]);
  }
}
