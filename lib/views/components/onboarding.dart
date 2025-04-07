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
    return AppBar(
      automaticallyImplyLeading: false,
      leading:
          isBackButtonVisible
              ? Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              )
              : null,
      // backgroundColor: isBackButtonVisible ? Colors.white : null,
      backgroundColor: Colors.white,
      title: text.isNotEmpty
          ? Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Onboarding3()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Skip",
              style: GoogleFonts.poppins(
                fontSize: 16,
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
    return Container(
      height: (MediaQuery.of(context).size.height / 2),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagepath),
          // fit: BoxFit.cover,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            height: 1.5,
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
    return Container(
      height: 5,
      width: 15,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                NavTile(color: pageno == 1 ? Colors.blue : Colors.grey),
                const SizedBox(width: 5),
                NavTile(color: pageno == 2 ? Colors.blue : Colors.grey),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_forward, color: Colors.white, size: 30),
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
    return Column(
      children: [
        Center(child: Image.asset("assets/images/logo.png", height: 120)),
        const SizedBox(height: 20),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(34, 58, 106, 1),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class NavButtons extends StatelessWidget {
  final Widget destination;
  final String text;
  const NavButtons({super.key, required this.text, required this.destination});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        width: 250,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 0,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
          color:
              text == "SignIn" || text == "Patient"
                  ? Color.fromRGBO(64, 124, 226, 1)
                  : Colors.white,
          border:
              text == "SignUp" ||
                      text == "Doctor" ||
                      text == "Lady Health Worker"
                  ? Border.all(color: Color.fromRGBO(64, 124, 226, 1))
                  : null,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color:
                text == "SignIn" || text == "Patient"
                    ? Colors.white
                    : Color.fromRGBO(64, 124, 226, 1),
          ),
        ),
      ),
    );
  }
}
