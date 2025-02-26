import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/Pages/auth/logout.dart';
import 'package:merchandiser_web/Widgets/sidebarItem.dart';
import 'package:merchandiser_web/constant/colors.dart';
import 'package:merchandiser_web/constant/images.dart';

class TimelineScreen extends StatefulWidget {
  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late CollectionReference merchandisers;
  List<Map<String, dynamic>> merchandisersData = [];
  String distributor = '';
  User? currentUser;
  String selectedDistributor = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadMerchandisers();
  }

  // Fetch user data (currentUser)
  Future<void> _fetchUserData() async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        setState(() {
          selectedDistributor = currentUser!.uid;
        });

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('distributors')
            .doc(selectedDistributor)
            .get();

        if (userDoc.exists) {
          setState(() {
            distributor = userDoc['distributorName'] ?? 'No distributor info';
          });
        } else {
          setState(() {
            distributor = 'Distributor not found';
          });
        }
      } else {
        setState(() {
          distributor = 'No user found';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        distributor = 'Error fetching data';
      });
    }
  }

  // Fetch merchandisers based on distributorId (current user's UID)
  Future<void> _loadMerchandisers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Merchandiser')
          .where('distributorId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      print("Query Snapshot: ${querySnapshot.docs.length} documents found");

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          merchandisersData = querySnapshot.docs.map((doc) {
            print(doc.data()); // Debugging data to verify it's correct
            return {
              'name': doc['name'],
              'phone': doc['phone'],
              'address': doc['address'],
              'city': doc['city'],
              'state': doc['state'],
              'distributorName': doc['distributorName'],
            };
          }).toList();
        });
      } else {
        setState(() {
          merchandisersData = [];
        });
        print("No merchandisers found.");
      }
    } catch (e) {
      print("Error loading merchandisers: $e");
    }
  }

  // Build the timeline widget
  Widget _buildTimeline() {
    if (merchandisersData.isEmpty) {
      return Center(child: Text("No merchandisers found."));
    }

    return ListView.builder(
      itemCount: merchandisersData.length,
      itemBuilder: (context, index) {
        var merchandiser = merchandisersData[index];
        return TimelineTile(
          title:
              'Name: ${merchandiser['name']}, City: ${merchandiser['city']}, State: ${merchandiser['state']}',
          subtitle:
              'Contact: ${merchandiser['phone']}, Address: ${merchandiser['address']}',
          onTap: () {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
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
                          'images/applogo.png',
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
                    onTap: () => _onSidebarItemTap(context, '/timeline'),
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
          return Row(
            children: [
              if (!isMobile)
                Container(
                  width: 200,
                  color: const Color(0xFFFF6B01),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              AppImages.applogo,
                            ),
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
                      const SizedBox(height: 40),
                      SidebarItem(
                        title: "Overview",
                        image: AppImages.overview,
                        onTap: () => _onSidebarItemTap(context, '/home'),
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
                        onTap: () => _onSidebarItemTap(context, '/brands'),
                      ),
                      SidebarItem(
                        title: "Shops",
                        image: AppImages.shop,
                        onTap: () => _onSidebarItemTap(context, '/shops'),
                      ),
                      SidebarItem(
                        title: "Timeline",
                        image: AppImages.timeline,
                        onTap: () => _onSidebarItemTap(context, '/timeline'),
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
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMobile ? "" : distributor,
                                style: GoogleFonts.poppins(
                                    color: AppColors.MainColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Timeline",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  color: AppColors.MainColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Timeline content
                      Expanded(child: _buildTimeline()), // Ensures scrolling
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

  void _onSidebarItemTap(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
}

class TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl; // Optional image URL for profile picture (if any)
  final VoidCallback onTap; // Callback when the tile is tapped

  TimelineTile({
    required this.title,
    required this.subtitle,
    this.imageUrl, // Profile image URL (optional)
    required this.onTap, // onTap action
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 8, // Added elevation for shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: InkWell(
        onTap: onTap, // Trigger the onTap callback when the tile is tapped
        child: ListTile(
          contentPadding: EdgeInsets.all(12), // Added padding around content
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(30), // Circular image
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.account_circle,
                    size: 50, color: Colors.grey), // Placeholder icon
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Title text color
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600], // Subtitle text color
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios,
              color: Colors.blue), // Add an icon for interaction
        ),
      ),
    );
  }
}
