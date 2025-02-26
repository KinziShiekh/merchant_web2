import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/Pages/Merchandiser/add_merchandiser_form.dart';
import 'package:merchandiser_web/Pages/auth/logout.dart';
import 'package:merchandiser_web/Pages/brands/UnavailableBrand.dart';
import 'package:merchandiser_web/Pages/shops/shopdata.dart';
import 'package:merchandiser_web/Widgets/action.dart';
import 'package:merchandiser_web/Widgets/searchBar.dart';
import 'package:merchandiser_web/Widgets/sidebarItem.dart';
import 'package:merchandiser_web/constant/colors.dart';
import 'package:merchandiser_web/constant/images.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;

class OutletsScreen extends StatefulWidget {
  const OutletsScreen({Key? key}) : super(key: key);

  @override
  State<OutletsScreen> createState() => _UnavailableBrandsScreenState();
}

class _UnavailableBrandsScreenState extends State<OutletsScreen> {
  List<Map<String, dynamic>> allShops = [];
  List<Map<String, dynamic>> filteredShops = [];
  String selectedDay = "Calendar";
  final TextEditingController searchController = TextEditingController();
  String distributor = 'Loading...';
  String query = "";
  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _fetchUserData();
    _filterByDay(selectedDay);
    _filterSearchResults(
        query ?? ''); // Fetch shops from Firestore root collection
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// 🔹 Fetch all shops from the Firestore **Root Collection: "Shops"**
  Future<void> _fetchShops() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('❌ Error: No authenticated user found.');
        return;
      }

      String distributorId = user.uid; // ✅ Current Distributor's UID

      // ✅ Step 1: Fetch Merchandiser Names under this Distributor
      QuerySnapshot merchandiserSnapshot = await FirebaseFirestore.instance
          .collection('distributors')
          .doc(distributorId)
          .collection('Merchandiser')
          .get();

      if (merchandiserSnapshot.docs.isEmpty) {
        debugPrint("❌ No Merchandisers found for this distributor.");
        setState(() {
          allShops = [];
          filteredShops = [];
        });
        return;
      }

      // ✅ Step 2: Get Merchandiser Names List
      List<String> merchandiserNamesList = merchandiserSnapshot.docs
          .map((doc) => doc['Name'] as String)
          .toList();

      if (merchandiserNamesList.isEmpty) {
        debugPrint("❌ No Merchandiser names found.");
        setState(() {
          allShops = [];
          filteredShops = [];
        });
        return;
      }

      // ✅ Step 3: Fetch Shops where `distributorId` matches AND `merchandiserName` is in Merchandiser Names List
      QuerySnapshot shopSnapshot = await FirebaseFirestore.instance
          .collection('Shops')
          .where('distributorId',
              isEqualTo: distributorId) // ✅ Distributor Filter
          // ✅ Merchandiser Name Filter
          .get();

      List<Map<String, dynamic>> shopList = shopSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      // ✅ Update UI
      setState(() {
        allShops = shopList;
        filteredShops = List.from(shopList);
      });

      debugPrint(
          "✅ Total Shops for Distributor ($distributorId) with matching Merchandisers: ${shopList.length}");
    } catch (e) {
      debugPrint('❌ Error fetching shops: $e');
      setState(() {
        allShops = [];
        filteredShops = [];
      });
    }
  }

  /// 🔹 Filter search results based on shop name
  void _filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredShops = List.from(allShops);
      } else {
        filteredShops = allShops.where((shop) {
          String merchandiser =
              shop['assignedMerchandisers']?.toLowerCase() ?? '';
          String shopName = shop['name']?.toLowerCase() ?? '';
          return merchandiser.contains(query.toLowerCase()) ||
              shopName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  /// 🔹 Filter shops by **selected day**
  void _filterByDay(String selectedDay) {
    setState(() {
      this.selectedDay = selectedDay;
      filteredShops = allShops.where((shop) {
        return shop['Day'] == selectedDay;
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMobile
          ? AppBar(
              iconTheme: IconThemeData(color: AppColors.MainColor),
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
                                'Outlets',
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
                                // downloadAllShopsCSV(allMerchandisers);
                              }),
                          DropdownButton<String>(
                            value: weekDays.contains(selectedDay)
                                ? selectedDay
                                : null,
                            hint: Text("Select a day",
                                style: GoogleFonts.poppins(fontSize: 16)),
                            onChanged: (newDay) {
                              if (newDay != null) {
                                setState(() {
                                  selectedDay = newDay;
                                });
                                _filterByDay(newDay);
                              }
                            },
                            items: weekDays.map((day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(day,
                                    style: GoogleFonts.poppins(fontSize: 16)),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      EnhancedSearchField(
                        controller: searchController,
                        onChanged: _filterSearchResults,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredShops.isEmpty
                            ? Center(
                                child: Text("No shops available",
                                    style: GoogleFonts.poppins(fontSize: 16)))
                            : ListView.builder(
                                itemCount: filteredShops.length,
                                itemBuilder: (context, index) {
                                  var shop = filteredShops[index];

                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ShopDetailsScreen(
                                                      shopName: shop['name'])));
                                    },
                                    child: Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.MainColor),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: ListTile(
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize
                                              .min, // Important to prevent extra spacing
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit,
                                                  color: AppColors.MainColor),
                                              onPressed: () {
                                                // Edit action
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: AppColors.MainColor),
                                              onPressed: () {
                                                // Delete action
                                              },
                                            ),
                                          ],
                                        ),
                                        leading: Image.asset(AppImages.shop2),
                                        title: Text(
                                            shop['name'] ?? 'Unknown Shop',
                                            style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.MainColor)),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "Area: ${shop['area'] ?? 'Unknown'}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.MainColor)),
                                            Text(
                                                "Merchandiser: ${shop['assignedMerchandisers'] ?? 'Unknown'}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.MainColor)),
                                            Text("Day: ${shop['Day'] ?? 'N/A'}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.MainColor)),
                                            if (shop.containsKey(
                                                    'unavailableBrand') &&
                                                shop['unavailableBrand']
                                                    is List &&
                                                shop['unavailableBrand']
                                                    .isNotEmpty)
                                              Text(
                                                  "Unavailable Brands: ${shop['unavailableBrand'].join(', ')}",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          AppColors.MainColor)),
                                          ],
                                        ),
                                      ),
                                    ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 40),
          SidebarItem(
              title: "Overview",
              image: AppImages.overview,
              onTap: () => _onSidebarItemTap(context, '/home')),
          SidebarItem(
            title: "Merchandiser",
            image: AppImages.merchandiser,
            onTap: () => _onSidebarItemTap(context, '/merchandiser'),
          ),
          SidebarItem(
            title: "Brands",
            image: AppImages.brand,
            onTap: () => _onSidebarItemTap(context, '/brand'),
          ),
          SidebarItem(
            title: "Shops",
            image: AppImages.shop,
            onTap: () => _onSidebarItemTap(context, '/shops'),
          ),
          SidebarItem(
            title: "Timeline",
            image: AppImages.timeline,
            onTap: () => _onSidebarItemTap(context, '/merchandiser'),
          ),
          SidebarItem(
            title: "Logout",
            image: AppImages.logout,
            onTap: () => AppFunctions.handleLogout(context),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Divider(color: Colors.white),
          SidebarItem(
            title: "Overview",
            image: AppImages.overview,
            onTap: () => _onSidebarItemTap(context, '/home'),
          ),
          SidebarItem(
            title: "Merchandiser",
            image: AppImages.merchandiser,
            onTap: () => _onSidebarItemTap(context, '/merchandiser'),
          ),
          SidebarItem(
            title: "Brands",
            image: AppImages.brand,
            onTap: () => _onSidebarItemTap(context, '/brand'),
          ),
          SidebarItem(
            title: "Shops",
            image: AppImages.shop,
            onTap: () => _onSidebarItemTap(context, '/shops'),
          ),
          SidebarItem(
            title: "Timeline",
            image: AppImages.timeline,
            onTap: () => _onSidebarItemTap(context, '/merchandiser'),
          ),
          SidebarItem(
            title: "Logout",
            image: AppImages.logout,
            onTap: () => AppFunctions.handleLogout(context),
          ),
        ],
      ),
    );
  }

  void _onSidebarItemTap(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
}
