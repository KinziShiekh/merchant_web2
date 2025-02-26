import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';

import 'package:merchandiser_web/Pages/Merchandiser/add_merchandiser_form.dart';
import 'package:merchandiser_web/Pages/auth/logout.dart';
import 'package:merchandiser_web/Widgets/action.dart';
import 'package:merchandiser_web/Widgets/searchBar.dart';
import 'package:merchandiser_web/Widgets/sidebarItem.dart';
import 'package:merchandiser_web/constant/colors.dart';
import 'package:merchandiser_web/constant/images.dart';
import 'dart:async';

class MerchandiserScreen extends StatefulWidget {
  const MerchandiserScreen({Key? key}) : super(key: key);

  @override
  _MerchandiserScreenState createState() => _MerchandiserScreenState();
}

class _MerchandiserScreenState extends State<MerchandiserScreen> {
  String distributor = 'Loading...';
  String distributorPhone = '';
  String distributorCity = '';
  List<List<dynamic>> _csvData = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> _salesmenList = [];
  bool _isLoading = true;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchSalesmenData();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _refreshSalesmenList();
    });
    // Fetch the salesmen data when the screen is loaded
  }

  void dispose() {
    _timer?.cancel(); // ✅ Stop the timer when screen is closed
    super.dispose();
  }

  // Fetch user data from Firestore
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
      print('Error fetching user data: $e');
    }
  }

  // Fetch salesmen data from Firestore
  Future<void> _fetchSalesmenData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        CollectionReference salesmenRef = FirebaseFirestore.instance
            .collection('distributors')
            .doc(user.uid)
            .collection('Merchandiser');

        QuerySnapshot salesmenSnapshot = await salesmenRef.get();

        setState(() {
          _salesmenList = salesmenSnapshot.docs.map((doc) {
            return {
              'id': doc.id, // Add the document ID
              'Name': doc['Name'] ?? 'Unknown Name',
              'ContactNo': doc['ContactNo'] ?? 'N/A',
              'Address': doc['Address'] ?? 'N/A',
            };
          }).toList();
          _filteredSalesmenList = List.from(_salesmenList);
        });
      } catch (e) {
        print('Error fetching salesmen: $e');
      }
    }
  }

  Future<void> _refreshSalesmenList() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch fresh data from Firestore
    await _fetchSalesmenData();

    setState(() {
      _isLoading = false;
    });
  }

  // Function to pick the CSV file and parse it
  Future<void> _pickCSVFile() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.csv';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;
        final reader = html.FileReader();
        reader.readAsText(files[0]);
        reader.onLoadEnd.listen((e) {
          String result = reader.result as String;
          List<List<dynamic>> csvTable = CsvToListConverter().convert(result);
          setState(() {
            _csvData = csvTable;
          });
          _addMerchandisersFromCSV(csvTable); // Upload CSV data to Firestore
        });
      });
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final input = file.readAsStringSync();
        List<List<dynamic>> csvTable = CsvToListConverter().convert(input);
        setState(() {
          _csvData = csvTable;
        });
        _addMerchandisersFromCSV(csvTable); // Upload CSV data to Firestore
      }
    }
  }

  Future<void> _addMerchandisersFromCSV(List<List<dynamic>> csvData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user found, aborting upload.");
      return;
    }

    try {
      CollectionReference merchandiserRef = FirebaseFirestore.instance
          .collection('distributors')
          .doc(user.uid)
          .collection('Merchandiser');

      print("Starting to process CSV...");

      for (var row in csvData.skip(1)) {
        // Skip header row
        if (row.length < 7) {
          print("Skipping invalid row: $row");
          continue;
        }

        String name = row[0]?.toString().trim() ?? 'Unknown';
        String password = row[1]?.toString().trim() ?? '123456';
        String contactNo = row[2]?.toString().trim() ?? 'N/A';
        String address = row[3]?.toString().trim() ?? 'N/A';
        String city = row[4]?.toString().trim() ?? 'N/A';
        String state = row[5]?.toString().trim() ?? 'N/A';
        String shopsData = row[6]?.toString().trim() ?? '';

        print("✅ Processing Merchandiser: $name");

        // **Check if Merchandiser already exists**
        QuerySnapshot existingMerchandisers = await merchandiserRef
            .where('Name', isEqualTo: name)
            .where('ContactNo', isEqualTo: contactNo)
            .get();

        if (existingMerchandisers.docs.isNotEmpty) {
          print('⚠️ Merchandiser "$name" already exists. Skipping.');
          continue;
        }

        // **Initialize Weekly Shops Structure**
        Map<String, List<Map<String, dynamic>>> weeklyShops = {
          'Monday': [],
          'Tuesday': [],
          'Wednesday': [],
          'Thursday': [],
          'Friday': [],
          'Saturday': []
        };

        // **Parse and Add Shops (if any)**
        if (shopsData.isNotEmpty) {
          List<String> shopList = shopsData.split(';');

          for (var shopEntry in shopList) {
            List<String> shopDetails = shopEntry.split(',');
            if (shopDetails.length < 5) {
              print("⚠️ Skipping invalid shop entry: $shopEntry");
              continue;
            }

            String shopName = shopDetails[0].trim();
            String area = shopDetails[1].trim();
            double longitude = double.tryParse(shopDetails[2].trim()) ?? 0.0;
            double latitude = double.tryParse(shopDetails[3].trim()) ?? 0.0;
            String day = shopDetails[4].trim();

            print("✅ Processing Shop: $shopName on $day");

            if (weeklyShops.containsKey(day)) {
              weeklyShops[day]!.add({
                'name': shopName,
                'area': area,
                'longitude': longitude,
                'latitude': latitude
              });
            }

            // **Check if Shop exists in Root Collection**
            DocumentReference shopRef =
                FirebaseFirestore.instance.collection('Shops').doc(shopName);
            DocumentSnapshot shopSnapshot = await shopRef.get();

            // if (shopSnapshot.exists) {
            //   print("Updating existing shop: $shopName");
            //   await shopRef.update({
            //     'assignedMerchandisers': FieldValue.arrayUnion(name as List),
            //   });
            // }
            if (shopSnapshot.exists) {
              print("🔄 Updating existing shop: $shopName");
              await shopRef.update({
                'assignedMerchandisers': name,
              });
            } else {
              print("➕ Adding new shop: $shopName");
              String currentDate =
                  DateFormat('yyyy-MM-dd').format(DateTime.now());

              await shopRef.set({
                'Day': day,
                'Date': currentDate,
                'name': shopName,
                'area': area,
                'longitude': longitude,
                'latitude': latitude,
                'assignedMerchandisers': name,
              });
            }
          }
        }

        // **Add Merchandiser with Weekly Shops**
        print("Adding Merchandiser: $name");
        DocumentReference newMerchandiserRef = await merchandiserRef.add({
          'uidMerchandiser': user.uid,
          'Name': name,
          'password': password,
          'ContactNo': contactNo,
          'Address': address,
          'city': city,
          'state': state,
          'shops': weeklyShops,
        });

        // **Save Weekly Shops Under Merchandiser**
        for (var day in weeklyShops.keys) {
          for (var shop in weeklyShops[day]!) {
            String currentDate =
                DateFormat('yyyy-MM-dd').format(DateTime.now());
            print("➕ Adding shop ${shop['name']} under Merchandiser: $name");
            await newMerchandiserRef.collection('Shops').add({
              'MerchandiserName': name,
              'day': day,
              'Date': currentDate,
              'name': shop['name'],
              'area': shop['area'],
              'longitude': shop['longitude'],
              'latitude': shop['latitude'],
            });
          }
        }
      }

      print("🎉 CSV Upload Completed Successfully!");
      Get.snackbar('Success', 'CSV Merchandisers Uploaded Successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print("❌ Error uploading CSV Merchandisers: $e");
      Get.snackbar('Error', 'Failed to add CSV Merchandisers: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _deleteSalesman(String salesmanId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Reference to the salesmen collection
        CollectionReference salesmenRef = FirebaseFirestore.instance
            .collection('distributors')
            .doc(user.uid)
            .collection('Merchandiser');

        // Delete the document with the provided ID
        await salesmenRef.doc(salesmanId).delete();

        // Remove from the local list
        setState(() {
          _salesmenList.removeWhere((salesman) => salesman['id'] == salesmanId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Salesman deleted successfully!',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            backgroundColor: AppColors.MainColor,
          ),
        );
      } catch (e) {
        print('Error deleting salesman: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting salesman: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.MainColor,
              title: Text(
                'Confirm Delete',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              content: Text(
                'Are you sure you want to delete this salesman?',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _addSalesmenFromCSV(List<List<dynamic>> csvData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        CollectionReference salesmenRef = FirebaseFirestore.instance
            .collection('distributors')
            .doc(user.uid)
            .collection('Merchandiser');

        for (var row in csvData) {
          String name = row[0] ?? 'Unknown';
          String contactNo = row[1] ?? 'N/A';
          String address = row[2] ?? 'N/A';

          // Check if a salesmen with the same name and address already exists
          QuerySnapshot existingSalesmen = await salesmenRef
              .where('Name', isEqualTo: name)
              .where('ContactNo', isEqualTo: contactNo)
              .where('Address', isEqualTo: address)
              .get();

          if (existingSalesmen.docs.isEmpty) {
            // No matching salesman found, add the new one
            await salesmenRef.add({
              'Name': name,
              'ContactNo': contactNo,
              'Address': address,
              'createdAt': FieldValue.serverTimestamp(),
            });

            setState(() {
              _salesmenList.add({
                'Name': name,
                'ContactNo': contactNo,
                'Address': address,
              });
            });

            print('Salesmen added successfully');
          } else {
            print(
                'Salesmen with name "$name" and address "$address" already exists.');
          }
        }
      } catch (e) {
        print('Error adding salesmen: $e');
      }
    }
  }

  // Search function to filter CSV data
  List<List<dynamic>> _searchCSVData() {
    String query = searchController.text.toLowerCase();
    return _csvData.where((row) {
      return row[0].toString().toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _filteredSalesmenList = [];

  void _filterSalesmen(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSalesmenList = List.from(_salesmenList);
      } else {
        _filteredSalesmenList = _salesmenList
            .where((salesman) => (salesman['Name'] ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
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
              iconTheme: IconThemeData(
                color: AppColors.MainColor, // Set the color of the drawer icon
              ),
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
      drawer: isMobile
          ? Drawer(
              backgroundColor: AppColors.MainColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          AppImages.applogo,
                          height: 60,
                        ),
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
                    onTap: () => _onSidebarItemTap(context, '/Shops'),
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
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Row(
            children: [
              if (!isMobile)
                Container(
                  width: 300,
                  color: AppColors.MainColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'images/applogo.png',
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Dashboard",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                      SidebarItem(
                        title: "Overview",
                        image: AppImages.overview,
                        onTap: () {
                          () => _onSidebarItemTap(context, '/home');
                        },
                      ),
                      SidebarItem(
                        title: "Merchandiser",
                        image: AppImages.merchandiser,
                        onTap: () =>
                            _onSidebarItemTap(context, '/merchandiser'),
                      ),
                      SidebarItem(
                        title: "Brands",
                        image: AppImages.brand,
                        onTap: () => _onSidebarItemTap(context, '/brand'),
                      ),
                      SidebarItem(
                        title: "Shops",
                        image: AppImages.shop,
                        onTap: () => _onSidebarItemTap(context, '/Shops'),
                      ),
                      SidebarItem(
                        title: "Timeline",
                        image: AppImages.timeline,
                        onTap: () =>
                            _onSidebarItemTap(context, '/merchandiser'),
                      ),
                      SidebarItem(
                        title: "Logout",
                        image: AppImages.logout,
                        onTap: () => AppFunctions.handleLogout(context),
                      ),
                    ],
                  ),
                ),
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
                              isMobile
                                  ? const SizedBox
                                      .shrink() // No widget, no space
                                  : Text(
                                      distributor,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.MainColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              Text(
                                'Merchandiser',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.MainColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomIconButton(
                              label: 'Add a Merchandiser',
                              width: 200,
                              height: 40,
                              icon: Icons.safety_check,
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AddMerchandiserPage()));
                              }),
                          SizedBox(width: 8),
                          CustomIconButton(
                              label: 'Add a CSV',
                              width: 150,
                              height: 40,
                              icon: Icons.safety_check,
                              onPressed: () {
                                _pickCSVFile();
                              })
                        ],
                      ),
                      SizedBox(height: 16),
                      EnhancedSearchField(
                        controller: searchController,
                        onChanged: _filterSalesmen,
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshSalesmenList,
                          child: _filteredSalesmenList.isEmpty
                              ? Center(
                                  child: Text(
                                      "No Merchandiser Available")) // Show loading while refreshing
                              // Show when empty
                              : ListView.builder(
                                  itemCount: _filteredSalesmenList.length,
                                  itemBuilder: (context, index) {
                                    final row = _filteredSalesmenList[index];
                                    return GestureDetector(
                                      onTap: () {
                                        // Add navigation or onTap functionality here
                                      },
                                      child: Card(
                                        margin: EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                              color: Colors.orange,
                                              width: 2), // Orange border
                                        ),
                                        elevation: 3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Header: Name and Phone Number
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        row['Name'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: AppColors
                                                              .MainColor,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        row['ContactNo'],
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          color: AppColors
                                                              .MainColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    'Checkin/Checkout Time',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          AppColors.MainColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Address
                                              Text(
                                                row['Address'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: AppColors.MainColor,
                                                ),
                                              ),

                                              Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1),
                                              SizedBox(height: 6),
                                              // Performance Chips
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Chip(
                                                        avatar: Icon(Icons.star,
                                                            size: 14,
                                                            color:
                                                                Colors.white),
                                                        label: Text(
                                                          'Beat 20',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12),
                                                        ),
                                                        backgroundColor:
                                                            Colors.green[400],
                                                      ),
                                                      Chip(
                                                        avatar: Icon(
                                                            Icons.trending_up,
                                                            size: 14,
                                                            color:
                                                                Colors.white),
                                                        label: Text(
                                                          'Strike Rate 30%',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12),
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange[400],
                                                      ),
                                                      SizedBox(width: 4),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.edit,
                                                            color: Colors.blue,
                                                            size: 20),
                                                        onPressed: () {
                                                          // Edit functionality here
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete,
                                                            color: Colors.red,
                                                            size: 20),
                                                        onPressed: () async {
                                                          bool confirmed =
                                                              await _showDeleteConfirmationDialog(
                                                                  context);
                                                          if (confirmed) {
                                                            _deleteSalesman(
                                                                row['id']);
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
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

  Widget _buildSidebarItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  void _onSidebarItemTap(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
}
