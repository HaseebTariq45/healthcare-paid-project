import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // controller: inputType == TextInputType.phone
        //     ? TextEditingController(text: '+92')
        //     : null,
        // onChanged: (value) {
        //   if (inputType == TextInputType.phone && !value.startsWith('+92')) {
        //     final newValue = '+92' + value.replaceAll('+92', '');
        //     WidgetsBinding.instance.addPostFrameCallback((_) {
        //       (context as Element).markNeedsBuild();
        //     });
        //     (context as Element).markNeedsBuild();
        //   }
        // },
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
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
          fillColor: Color.fromRGBO(249, 250, 251, 1),
          hintText: hinttext,
          hintStyle: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey,
            wordSpacing: 3.0, // Optional: apply same spacing for hint text
            letterSpacing: 1.5,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 10,
            ),
            child: Icon(icon, color: Colors.grey, size: 32),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 24.0),
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
            borderSide: BorderSide(color: Color.fromRGBO(34, 31, 31, 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color.fromRGBO(34, 31, 31, 0.4)),
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
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min, // Shrink the row to its children
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align items at the top
          children: [
            IconButton(
              iconSize: 30,
              icon: Icon(
                _isselected
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
              ),
              onPressed: _toggleSelection,
              color:
                  _isselected
                      ? const Color.fromRGBO(34, 58, 106, 1)
                      : Colors.grey,
            ),
            const SizedBox(width: 10), // Optional spacing
            Flexible(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: "I agree to the healthcare "),
                      TextSpan(
                        text: "Terms of Service",
                        style: GoogleFonts.poppins(
                          color: Color.fromRGBO(34, 58, 106, 1),
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                // Handle Terms of Service tap here.
                              },
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: GoogleFonts.poppins(
                          color: Color.fromRGBO(34, 58, 106, 1),
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                // Handle Privacy Policy tap here.
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
      height: 60,
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: isEnabled ? const Color.fromRGBO(64, 124, 226, 1) : Colors.grey,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
