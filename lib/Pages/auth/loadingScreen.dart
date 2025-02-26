import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:merchandiser_web/constant/colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.MainColor, // Set background color
      body: Center(
        child: Lottie.asset(
          'images/loading.json', // Path to your Lottie file
          width: 150, // Adjust width
          height: 150, // Adjust height
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(
                const ['**'], // Target all elements in the animation
                value: Colors.white, // Change animation color to white
              ),
            ],
          ),
        ),
      ),
    );
  }
}
