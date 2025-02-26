import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:merchandiser_web/Pages/Merchandiser/merchandiser.dart';
import 'package:merchandiser_web/Pages/SplashScreen.dart';
import 'package:merchandiser_web/Pages/brands/brand.dart';
import 'package:merchandiser_web/Pages/dashboard.dart';
import 'package:merchandiser_web/Pages/shops/shops.dart';
import 'package:merchandiser_web/Pages/timeline/timeline.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/', // Define the initial route
      getPages: [
        GetPage(
          name: '/',
          page: () => Splashscreen(), // Splashscreen
        ),
        GetPage(
          name: '/home',
          page: () => DashboardScreen(), // Dashboard
        ),
        GetPage(
          name: '/merchandiser',
          page: () => MerchandiserScreen(), // Merchandiser Screen
        ),
        GetPage(
          name: '/brand',
          page: () => UnavailableBrandsScreen(), // Merchandiser Screen
        ),
        GetPage(
          name: '/shops',
          page: () => OutletsScreen(), // Merchandiser Screen
        ),
        GetPage(
          name: '/timeline',
          page: () => TimelineScreen(), // Merchandiser Screen
        ),
      ],
    );
  }
}
