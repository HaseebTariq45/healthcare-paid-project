import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DataInputFeild extends StatelessWidget {
  final String hinttext;
  final IconData icon;
  final TextInputType inputType;
  const DataInputFeild({
    super.key,
    required this.hinttext,
    required this.icon,
    required this.inputType,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextFormField(
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        keyboardType: inputType,
        inputFormatters:
            inputType == TextInputType.phone
                ? [LengthLimitingTextInputFormatter(11)]
                : null,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hinttext';
          }
          return null;
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.blue.shade50.withOpacity(0.3),
          hintText: hinttext,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: const Color(0xFF3366CC), size: 24),
          ),
          contentPadding: const EdgeInsets.all(0),
          constraints: BoxConstraints(
            minHeight: 60,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade200.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF3366CC), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicy extends StatefulWidget {
  final bool isselected;
  final ValueChanged<bool>? onChanged; // Callback to notify parent
  const PrivacyPolicy({super.key, required this.isselected, this.onChanged});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  late bool _isselected;

  @override
  void initState() {
    super.initState();
    _isselected = widget.isselected;
  }

  void _toggleSelection() {
    setState(() {
      _isselected = !_isselected;
    });
    // Notify the parent of the new value
    if (widget.onChanged != null) {
      widget.onChanged!(_isselected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isselected ? const Color(0xFF3366CC).withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Checkbox(
              value: _isselected,
              onChanged: (value) {
                _toggleSelection();
              },
              activeColor: const Color(0xFF3366CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                children: [
                  const TextSpan(text: "I agree to the healthcare "),
                  TextSpan(
                    text: "Terms of Service",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF3366CC),
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Handle Terms of Service tap here
                      },
                  ),
                  const TextSpan(text: " and "),
                  TextSpan(
                    text: "Privacy Policy",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF3366CC),
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Handle Privacy Policy tap here
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProceedButton extends StatelessWidget {
  final String text;
  final bool isEnabled;
  const ProceedButton({super.key, required this.isEnabled, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        gradient: isEnabled 
            ? LinearGradient(
                colors: [
                  const Color(0xFF3366CC),
                  const Color(0xFF5E8EF7),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF3366CC).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          if (isEnabled)
            const Icon(
              LucideIcons.arrowRight,
              color: Colors.white,
              size: 20,
            ),
        ],
      ),
    );
  }
}
