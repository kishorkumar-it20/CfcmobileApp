import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        children: [
          IntroPage(
            image: 'assets/logo.jpg',
            title: 'Welcome to CFC',
            description: 'This is the first introduction screen. Enjoy using our app!',
            isRoundedImage: true,
            isLastPage: false,
            onNext: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
          ),
          IntroPage(
            image: 'assets/Intro3.png',
            title: 'Discover Features',
            description: 'This is the second introduction screen. Discover the amazing features!',
            isRoundedImage: false,
            isLastPage: true,
            onNext: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

class IntroPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final bool isRoundedImage;
  final bool isLastPage;
  final VoidCallback onNext;

  const IntroPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.isRoundedImage,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 50),
          Text(
              title,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: Colors.white),
              )
          ),
          isRoundedImage
              ? ClipOval(
            child: Image.asset(
              image,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          )
              : Image.asset(image),
          Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
              )
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.greenAccent, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: GoogleFonts.poppins(
                  textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                )
            ),
            child: Text(isLastPage ? 'Get Started' : 'Next'),
          ),
        ],
      ),
    );
  }
}
