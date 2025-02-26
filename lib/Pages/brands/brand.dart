import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:merchandiser_web/Pages/brands/UnavailableBrand.dart';
import 'package:merchandiser_web/Widgets/action.dart';
import 'package:merchandiser_web/Widgets/searchBar.dart';
import 'package:merchandiser_web/Widgets/sidebarItem.dart';
import 'package:merchandiser_web/constant/colors.dart';
import 'package:merchandiser_web/constant/images.dart';

class UnavailableBrandsScreen extends StatefulWidget {
  const UnavailableBrandsScreen({Key? key}) : super(key: key);

  @override
  State<UnavailableBrandsScreen> createState() =>
      _UnavailableBrandsScreenState();
}

class _UnavailableBrandsScreenState extends State<UnavailableBrandsScreen> {
  String distributor = 'Loading...';

  List<Map<String, dynamic>> allMerchandisers = [];
  List<Map<String, dynamic>> filteredMerchandisers = [];
  String selectedBrand = 'Lays';
  double? minPrice;
  double? maxPrice;
  String selectedDay = "Calendar";
  final TextEditingController searchController = TextEditingController();
  List<String> brands = ['Lays', 'Doritos', 'Pringles']; // List of brands
  List<Map<String, dynamic>> filteredShops = [];
  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchMerchandisers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> downloadUnavailableBrandsCSV() async {
    try {
      // 1️⃣ Current logged-in distributor ID lein
      String? distributorID = FirebaseAuth.instance.currentUser?.uid;
      if (distributorID == null) {
        debugPrint("User not logged in.");
        return;
      }

      // 2️⃣ Firestore query: Shops where distributorId == logged-in user
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('Shops')
              .where('distributorId', isEqualTo: distributorID)
              .get();

      // 3️⃣ CSV ke headers define karein
      List<List<String>> csvData = [
        ['Shop Name', 'Area', 'Latitude', 'Longitude', 'Unavailable Brands'],
      ];

      for (var doc in querySnapshot.docs) {
        var shop = doc.data();

        // 4️⃣ Check karein ke `unavailableBrand` available hai ya nahi
        List unavailableBrands = shop['unavailableBrand'] ?? [];

        if (unavailableBrands.isNotEmpty) {
          // 5️⃣ CSV ke liye data prepare karein
          String brandDetails = unavailableBrands
              .map((b) => "${b['Brand']} (${b['Price']})")
              .join(', ');

          csvData.add([
            shop['name'] ?? 'Unknown Shop',
            shop['area'] ?? 'Unknown Area',
            shop['latitude']?.toString() ?? 'N/A',
            shop['longitude']?.toString() ?? 'N/A',
            brandDetails,
          ]);
        }
      }

      // 6️⃣ Agar koi data nahi mila to message show karein
      if (csvData.length == 1) {
        debugPrint(
            'No shops with unavailable brands found for the current distributor.');
        return;
      }

      // 7️⃣ CSV Convert karein aur download link generate karein
      String csv = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'unavailable_brands.csv'
        ..click();

      html.Url.revokeObjectUrl(url);

      debugPrint('CSV file downloaded successfully');
    } catch (e) {
      debugPrint('Error downloading CSV: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('distributors')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            distributor = userData['distributorName'] ?? 'Unknown Distributor';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchMerchandisers() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot distributorsSnapshot = await FirebaseFirestore.instance
            .collection('distributors')
            .where('userId', isEqualTo: user.uid)
            .get();

        List<Map<String, dynamic>> merchandisersList = [];

        for (var distributorDoc in distributorsSnapshot.docs) {
          QuerySnapshot merchandisersSnapshot = await FirebaseFirestore.instance
              .collection('distributors')
              .doc(distributorDoc.id)
              .collection('Merchandiser')
              .get();

          for (var merchandiserDoc in merchandisersSnapshot.docs) {
            QuerySnapshot shopsSnapshot = await FirebaseFirestore.instance
                .collection('distributors')
                .doc(distributorDoc.id)
                .collection('Merchandiser')
                .doc(merchandiserDoc.id)
                .collection('Shops')
                .get();

            List<Map<String, dynamic>> shopList =
                shopsSnapshot.docs.map((shopDoc) {
              return shopDoc.data() as Map<String, dynamic>;
            }).toList();

            merchandisersList.add({
              'distributerId': distributorDoc.id,
              'merchandiserId': merchandiserDoc.id,
              ...merchandiserDoc.data() as Map<String, dynamic>,
              'shops': shopList,
            });
          }
        }

        setState(() {
          allMerchandisers = merchandisersList;
          filteredMerchandisers = allMerchandisers;
        });
      }
    } catch (e) {
      debugPrint('Error fetching merchandisers and shops: $e');
    }
  }

  void _filterByDate(DateTime selectedDate) {
    setState(() {
      selectedDay = DateFormat('EEEE').format(selectedDate);
      filteredMerchandisers = allMerchandisers
          .map((merchandiser) {
            List<Map<String, dynamic>> filteredShops =
                (merchandiser['shops'] ?? []).where((shop) {
              return shop['day'] == selectedDay;
            }).toList();

            return {
              ...merchandiser,
              'shops': filteredShops,
            };
          })
          .where((merchandiser) => (merchandiser['shops'] as List).isNotEmpty)
          .toList();
    });
  }

  // 🔥 Function to Show No Shops Dialog

  void _filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMerchandisers = allMerchandisers;
      } else {
        filteredMerchandisers = allMerchandisers
            .map((merchandiser) {
              String merchandiserName =
                  merchandiser['Name']?.toLowerCase() ?? '';

              List<Map<String, dynamic>> filteredShops =
                  (merchandiser['shops'] ?? []).where((shop) {
                String shopName = shop['name']?.toLowerCase() ?? '';
                return merchandiserName.contains(query.toLowerCase()) ||
                    shopName.contains(query.toLowerCase());
              }).toList();

              return {
                ...merchandiser,
                'shops': filteredShops,
              };
            })
            .where((merchandiser) => (merchandiser['shops'] as List).isNotEmpty)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMobile
          ? AppBar(
              iconTheme: const IconThemeData(color: AppColors.MainColor),
              title: Text(
                distributor,
                style: GoogleFonts.poppins(
                    color: AppColors.MainColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
            )
          : null,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Row(
            children: [
              if (!isMobile) _buildSidebar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMobile)
                                Text(
                                  distributor,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.MainColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                'Unavailable Brands',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.MainColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomIconButton(
                              label: 'Download Report',
                              width: 200,
                              height: 40,
                              icon: Icons.file_download,
                              onPressed: () {
                                downloadUnavailableBrandsCSV();
                              }),
                          // Usage in Button

                          // Display the filtered shops

                          CustomIconButton(
                            label:
                                selectedDay, // Button text updates dynamically
                            width: 130,
                            height: 40,
                            icon: Icons.calendar_today,
                            onPressed: () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (selectedDate != null) {
                                _filterByDate(selectedDate);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      EnhancedSearchField(
                        controller: searchController,
                        onChanged: _filterSearchResults,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Shops')
                              .where('unavailableBrand', isNotEqualTo: 0)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text("Error loading shops"));
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No shops available"));
                            }

                            // Extract unique shop data
                            Set<String> uniqueShopNames = {};
                            List<Map<String, dynamic>> uniqueShops = [];

                            for (var doc in snapshot.data!.docs) {
                              Map<String, dynamic> shopData =
                                  doc.data() as Map<String, dynamic>;
                              String shopName = shopData['name'] ?? '';

                              // Avoid duplicate shop names
                              if (!uniqueShopNames.contains(shopName)) {
                                uniqueShopNames.add(shopName);
                                uniqueShops.add(shopData);
                              }
                            }

                            return ListView.builder(
                              itemCount: uniqueShops.length,
                              itemBuilder: (context, shopIndex) {
                                var shop = uniqueShops[shopIndex];

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      debugPrint('Clicked on ${shop['name']}');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Unavailablebrand2(shops: [
                                            shop
                                          ]), // Pass only one shop
                                        ),
                                      );
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              AppColors.MainColor.withOpacity(
                                                  0.1),
                                          child: Icon(Icons.store,
                                              color: AppColors.MainColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                shop['name'] ?? 'Unknown Shop',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Area: ${shop['area'] ?? 'Unknown Area'}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                              if (shop.containsKey(
                                                  'assignedMerchandisers'))
                                                Text(
                                                  'Merchandiser: ${shop['assignedMerchandisers'] ?? 'N/A'}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.black87),
                                                ),
                                              if (shop.containsKey(
                                                  'unavailableBrand'))
                                                Text(
                                                  'Unavailable Brands: ${shop['unavailableBrand'].map((b) => '${b['Brand']} ').join(", ")}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Day: ${shop['Day'] ?? 'N/A'}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.blue),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.download,
                                              color: Colors.red),
                                          onPressed: () {
                                            debugPrint(
                                                'Delete ${shop['name']}');
                                            // Handle delete action
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.MainColor,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Image.asset(AppImages.applogo, height: 60),
                const SizedBox(height: 20),
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SidebarItem(
            title: "Overview",
            image: AppImages.overview,
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          SidebarItem(
            title: "Merchandiser",
            image: AppImages.merchandiser,
            onTap: () {},
          ),
          SidebarItem(
            title: "Brands",
            image: AppImages.brand,
            onTap: () {},
          ),
          SidebarItem(
            title: "Shops",
            image: AppImages.shop,
            onTap: () {},
          ),
          SidebarItem(
            title: "Logout",
            image: AppImages.logout,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 300,
      color: AppColors.MainColor,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Image.asset(AppImages.applogo),
                const SizedBox(height: 20),
                Text(
                  "Dashboard",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SidebarItem(
            title: "Overview",
            image: AppImages.overview,
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          SidebarItem(
            title: "Merchandiser",
            image: AppImages.merchandiser,
            onTap: () {},
          ),
          SidebarItem(
            title: "Brands",
            image: AppImages.brand,
            onTap: () {},
          ),
          SidebarItem(
            title: "Shops",
            image: AppImages.shop,
            onTap: () {},
          ),
          SidebarItem(
            title: "TimeLine",
            image: AppImages.shop,
            onTap: () {
              Get.toNamed('/timeline');
            },
          ),
          SidebarItem(
            title: "Logout",
            image: AppImages.logout,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
