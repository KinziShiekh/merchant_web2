import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/Pages/auth/loadingScreen.dart';
import 'package:merchandiser_web/Widgets/button.dart';
import 'package:merchandiser_web/constant/images.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:merchandiser_web/constant/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? selectedDistributor;
  bool isPasswordVisible = false;
  bool _isLoading = false;
  // Map to store predefined email and password for each distributor
  final Map<String, Map<String, String>> distributorCredentials = {
    'Chaudhary & Co.': {
      'email': 'admin@example.com',
      'password': 'adminPassword',
    },
    'Goraya Traders Faisalabad': {
      'email': 'goraya@example.com',
      'password': 'gorayaPassword',
    },
    'Idreesia Enterprises': {
      'email': 'idreesia@example.com',
      'password': 'idreesiaPassword',
    },
    'Ma Traders': {
      'email': 'matrader@example.com',
      'password': 'matraderPassword',
    },
    'Ma Traders II': {
      'email': 'matrader2@example.com',
      'password': 'matrader2Password',
    },
    'Mian Co.': {
      'email': 'mian@example.com',
      'password': 'mianPassword',
    },
    'Munawar Traders': {
      'email': 'munawar@example.com',
      'password': 'munawarPassword',
    },
    'Raza Traders': {
      'email': 'raza@example.com',
      'password': 'razaPassword',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('savedEmail') ?? '';
      passwordController.text = prefs.getString('savedPassword') ?? '';
      selectedDistributor = prefs.getString('savedDistributor');

      // Automatically fill email and password based on selected distributor
      if (selectedDistributor != null &&
          distributorCredentials.containsKey(selectedDistributor)) {
        emailController.text =
            distributorCredentials[selectedDistributor]!['email']!;
        passwordController.text =
            distributorCredentials[selectedDistributor]!['password']!;
      }
    });
  }

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedEmail', emailController.text.trim());
    await prefs.setString('savedPassword', passwordController.text.trim());
    await prefs.setString('savedDistributor', selectedDistributor ?? '');
  }

  // Handle Sign Up or Sign In
  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Check if the distributor is selected
    if (selectedDistributor == null) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a distributor.",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFF16611),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
      return;
    }

    // Get the predefined credentials for the selected distributor
    final credentials = distributorCredentials[selectedDistributor!];

    if (credentials != null) {
      // Pre-fill email and password based on selected distributor
      emailController.text = credentials['email']!;
      passwordController.text = credentials['password']!;
    }

    // Validate email and password
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Email or Password Can't be empty",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFF16611),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
      return;
    }

    // Perform sign-in
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Save distributor info in Firestore
      await _saveDistributorInfo(userCredential.user!.uid);

      // Navigate to the home screen or dashboard
      Navigator.pushReplacementNamed(
          context, '/home'); // Adjust route as needed

      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.MainColor,
            title: Text("Success",
                style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(
              "Login successful!",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      // Handle errors during sign-in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error during sign-in: $e",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  // Save distributor info to Firestore
  Future<void> _saveDistributorInfo(String distributorId) async {
    try {
      // Firestore instance
      final firestore = FirebaseFirestore.instance;

      // Add distributor info to Firestore
      await firestore.collection('distributors').doc(distributorId).set({
        'distributorId': distributorId, // Add userId to the document
        'distributorName': selectedDistributor,
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'loginTime': Timestamp.now(),
      });
    } catch (e) {
      print("Error saving distributor info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // Main content of the screen
        _isLoading
            ? LoadingScreen()
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 768) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Image.asset(
                            AppImages.loginposter,
                            height: constraints.maxHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: _buildLoginForm(context, isMobile: false),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildLoginForm(context, isMobile: true),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
      ]),
    );
  }

  // Build the login form widget
  Widget _buildLoginForm(BuildContext context, {required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.center : MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.laysLogo),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "Access your account!",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.MainColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your Work, Just a Click Away, Simplify Your Journey!",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              color: AppColors.MainColor,
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: "Email",
              labelStyle: GoogleFonts.poppins(color: AppColors.MainColor),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  AppImages.emaillogo,
                  height: 24,
                  width: 24,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.MainColor, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.MainColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
                labelText: "Password",
                labelStyle: GoogleFonts.poppins(color: AppColors.MainColor),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    AppImages.passwordlogo,
                    height: 24,
                    width: 24,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.MainColor,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.MainColor, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.MainColor, width: 1.5),
                )),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            iconEnabledColor: AppColors.MainColor,
            icon: Image.asset(
              AppImages.downarrow,
              height: 24,
              width: 24,
            ),
            value: distributorCredentials.keys.contains(selectedDistributor)
                ? selectedDistributor
                : null, // Set to null if no match found
            decoration: InputDecoration(
                labelText: "Distributor",
                labelStyle: GoogleFonts.poppins(color: AppColors.MainColor),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset(
                    AppImages.distributer,
                    height: 24,
                    width: 24,
                  ),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.MainColor, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.MainColor, width: 1.5),
                )),
            items: distributorCredentials.keys.map((distributor) {
              return DropdownMenuItem(
                value: distributor,
                child: Text(distributor),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedDistributor = value;

                // Auto-fill email and clear password
                if (value != null &&
                    distributorCredentials.containsKey(value)) {
                  emailController.text =
                      distributorCredentials[value]!['email']!;
                  passwordController.clear();
                }
              });
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "Sign In",
                onPressed: () {
                  _handleSignIn();
                },
                backgroundColor: AppColors.MainColor,
                fontSize: 18,
                borderRadius: 16,
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
