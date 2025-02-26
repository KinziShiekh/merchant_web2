import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/Pages/auth/login.dart';
import 'package:merchandiser_web/Pages/dashboard.dart';
// Replace with your HomePage class
import 'package:merchandiser_web/constant/colors.dart';
import 'package:merchandiser_web/constant/images.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Check authentication state and navigate accordingly
    _navigateBasedOnAuthState();
  }

  void _navigateBasedOnAuthState() async {
    await Future.delayed(const Duration(seconds: 3)); // Delay for 3 seconds

    User? user = _auth.currentUser;

    if (user != null) {
      // User is signed in, navigate to HomePage
      Get.offAll(
          () => const DashboardScreen()); // Replace with your home screen class
    } else {
      // No user signed in, navigate to LoginScreen
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.MainColor,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.applogo, // Replace with your logo path
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'Merchandiser',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
