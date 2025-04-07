import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your custom onboarding AppBar, if needed
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/dashboard/home.dart';

class OTPScreen extends StatefulWidget {
  final String text;
  const OTPScreen({super.key, required this.text});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  late String text;

  Timer? _timer;
  int _start = 60;

  // Create a controller for each of the 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    text = widget.text;
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final minutes = _start ~/ 60;
    final seconds = _start % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBarOnboarding(text: text, isBackButtonVisible: true),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Enter the OTP sent to your phone',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // OTP input fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: size.width * 0.12,
                    child: TextField(
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      controller: _controllers[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            _start > 0
                ? Text(
                  "Resend OTP in $formattedTime",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                )
                : TextButton(
                  onPressed: () {
                    debugPrint("Resend OTP pressed");
                    // Optionally clear OTP fields
                    setState(() {
                      for (final controller in _controllers) {
                        controller.clear();
                      }
                    });
                    // Restart the timer after resending OTP
                    startTimer();
                  },
                  child: Text(
                    "Resend OTP",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            // Confirm OTP button
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: InkWell(
                onTap: () {
                  final otp = _controllers.map((c) => c.text).join();
                  debugPrint("Entered OTP: $otp");
                  // Clear OTP fields when Confirm OTP is pressed
                  setState(() {
                    for (final controller in _controllers) {
                      controller.clear();
                    }
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        profileStatus: "in complete",
                      ),
                    ),
                  );
                  FocusScope.of(context).unfocus();
                },
                child: ProceedButton(isEnabled: true, text: "Confirm OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
