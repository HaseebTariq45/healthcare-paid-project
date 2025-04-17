import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:healthcare/views/screens/onboarding/onboarding_3.dart";

class AppBarOnboarding extends StatelessWidget implements PreferredSizeWidget {
  final String text;
  final bool isBackButtonVisible;
  const AppBarOnboarding({
    super.key,
    this.isBackButtonVisible = false,
    this.text = '',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AppBar(
      automaticallyImplyLeading: false,
      leading:
          isBackButtonVisible
              ? Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05, 
                  top: 10, 
                  bottom: 10
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              )
              : null,
      backgroundColor: Colors.white,
      title: text.isNotEmpty
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          : null,
      centerTitle: text.isNotEmpty ? true : false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class NavSkipText extends StatelessWidget {
  const NavSkipText({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Onboarding3()),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Skip",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OboardingImage extends StatelessWidget {
  final String imagepath;

  const OboardingImage({super.key, required this.imagepath});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    
    return AspectRatio(
      aspectRatio: 1.2,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.45,
          maxWidth: screenWidth,
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagepath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class OnboardingText extends StatelessWidget {
  final String text;
  const OnboardingText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Padding(
      padding: EdgeInsets.only(top: screenHeight * 0.03),
      child: SizedBox(
        width: screenWidth * 0.9,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: GoogleFonts.poppins(
              height: 1.5,
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class NavTile extends StatelessWidget {
  final Color color;
  const NavTile({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth * 0.012,
      width: screenWidth * 0.035,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
    );
  }
}

class OnboardingNavigation extends StatelessWidget {
  final Widget destination;
  final int pageno;
  const OnboardingNavigation({
    super.key,
    required this.pageno,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Padding(
      padding: EdgeInsets.only(top: screenHeight * 0.01),
      child: SizedBox(
        width: screenWidth * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                NavTile(color: pageno == 1 ? Colors.blue : Colors.grey),
                SizedBox(width: screenWidth * 0.012),
                NavTile(color: pageno == 2 ? Colors.blue : Colors.grey),
              ],
            ),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward, 
                  color: Colors.white, 
                  size: screenWidth * 0.075
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => destination),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final String text;
  const Logo({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Column(
      children: [
        Center(
          child: Image.asset(
            "assets/images/logo.png", 
            height: screenHeight * 0.15,
            width: screenWidth * 0.3,
            fit: BoxFit.contain,
          )
        ),
        SizedBox(height: screenHeight * 0.02),
        SizedBox(
          width: screenWidth * 0.8,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthButtons extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final IconData icon;
  final bool isBordered;

  const AuthButtons({
    super.key,
    required this.text,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    required this.icon,
    this.isBordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.018,
        ),
        width: screenWidth * 0.8,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: isBordered
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.02),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthButtonsExtended extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color bgColor;
  final Color textColor;
  final bool isBordered;

  const AuthButtonsExtended({
    Key? key,
    required this.text,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    this.isBordered = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.018,
        ),
        width: screenWidth * 0.8,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: isBordered
              ? Border.all(color: Colors.blue, width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
