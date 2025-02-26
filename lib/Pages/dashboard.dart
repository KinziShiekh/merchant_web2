import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/Pages/auth/logout.dart';
import 'package:merchandiser_web/Widgets/action.dart';
import 'package:merchandiser_web/Widgets/sidebarItem.dart';
import 'package:merchandiser_web/constant/images.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:merchandiser_web/constant/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? currentUser;
  String distributor = '';
  String selectedDistributor = '';
  late List<_ChartData> chartData;
  int totalShops = 0;
  int totalMerchsn = 0;

  @override
  void initState() {
    super.initState();
    _fetchShopsCountForDistributor();
    _fetchMerchandisersCount();
    _fetchUserData();
    chartData = _getChartData();
  }

  void _fetchMerchandisersCount() async {
    int totalMerchandisers = 0;

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String distributorId = user.uid; // ✅ Current user ID as Distributor ID

        QuerySnapshot merchandisersSnapshot = await FirebaseFirestore.instance
            .collection('distributors')
            .doc(distributorId) // ✅ Fetch current distributor
            .collection('Merchandiser') // ✅ Get Merchandiser subcollection
            .get();

        totalMerchandisers = merchandisersSnapshot.size;
      }

      setState(() {
        totalMerchsn = totalMerchandisers;
      });

      print(
          "Total Merchandisers for Current Distributor (${user?.uid}): $totalMerchandisers");
    } catch (e) {
      print("Error fetching merchandisers count: $e");
      setState(() {
        totalMerchsn = 0; // If error, set default value to 0
      });
    }
  }

  void _fetchShopsCountForDistributor() {
    if (currentUser == null) {
      print("Error: No authenticated user found.");
      return;
    }

    String distributorId = currentUser!.uid; // ✅ Current distributor's UID

    // ✅ Fetch all shops where distributorId == current user UID
    FirebaseFirestore.instance
        .collection('Shops')
        .where('distributorId', isEqualTo: distributorId)
        .get()
        .then((shopSnapshot) {
      int totalShopCount = shopSnapshot.size; // ✅ Total count of matching shops

      setState(() {
        totalShops = totalShopCount; // ✅ Update UI with correct count
      });

      print("Total Shops for Distributor ($distributorId): $totalShopCount");
    }).catchError((error) {
      print("Error fetching shops for distributor: $error");
      setState(() {
        totalShops = 0; // ✅ Set to 0 if error occurs
      });
    });
  }

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

          _fetchShopsCountForDistributor(); // ✅ Fetch after user data is available
        } else {
          setState(() {
            distributor = 'Distributor not found';
            totalShops = 0;
            totalMerchsn = 0;
          });
        }
      } else {
        setState(() {
          distributor = 'No user found';
          totalShops = 0;
          totalMerchsn = 0;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        distributor = 'Error fetching data';
        totalShops = 0;
        totalMerchsn = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.white,
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
                    onTap: () {
                      () => _onSidebarItemTap(context, '/home');
                    },
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
                  width: 250,
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
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
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
                                  isMobile
                                      ? ''
                                      : distributor, // Show nothing on mobile, distributor on larger screens
                                  style: GoogleFonts.poppins(
                                      color: AppColors.MainColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isMobile ? "" : "Overview",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    color: AppColors.MainColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CustomIconButton(
                                    label: 'Calender',
                                    icon: Icons.calendar_month,
                                    padding: 10.0,
                                    width: 120,
                                    height: 40,
                                    onPressed: () {}),
                                const SizedBox(width: 5),
                                CustomIconButton(
                                    label: 'DownloadReport',
                                    icon: Icons.download,
                                    padding: 10.0,
                                    width: 160,
                                    height: 40,
                                    onPressed: () {}),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Metrics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetricCard(
                                "Total Merchandiser",
                                "${totalMerchsn ?? 0}",
                                "Merchandiser"), // If null, show 0

                            _buildMetricCard(
                                "Total Outlets",
                                "${totalShops ?? 0}",
                                "Outlets"), // If null, show 0

                            _buildMetricCard(
                                "Miss Achieved Target", "7", "Merchandiser"),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Strike Rate Percentage using Syncfusion Chart

                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            title: ChartTitle(text: 'Strike Rate for the Week'),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            primaryYAxis: NumericAxis(
                              labelFormat:
                                  '{value}%', // Display the value as percentage
                              minimum: 0,
                              maximum: 100,
                            ),
                            series: <CartesianSeries>[
                              ColumnSeries<_ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (_ChartData data, _) => data.day,
                                yValueMapper: (_ChartData data, _) =>
                                    data.strikeRate,
                                dataLabelSettings:
                                    const DataLabelSettings(isVisible: true),
                                pointColorMapper: (_ChartData data, _) =>
                                    Colors.blue,
                              ),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetricCard(
                                "Visited Outlets", "100", "Outlets"),
                            _buildMetricCard(
                                "Unvisited Outlets", "80", "Outlets"),
                            _buildMetricCard(
                                "Achieved Target", "10", "Merchandiser"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title outside the container
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.MainColor,
              ),
              overflow: TextOverflow.ellipsis, // Prevent overflow
            ),
          ),
          // Container holding value and subtitle
          IntrinsicWidth(
            child: Card(
              color: const Color(0xFFFF6B01),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.8, // 80% of screen width
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Value Text
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                    const SizedBox(height: 6),
                    // Subtitle Text
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onSidebarItemTap(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  List<_ChartData> _getChartData() {
    return [
      _ChartData('Mon', 20),
      _ChartData('Tue', 40),
      _ChartData('Wed', 60),
      _ChartData('Thu', 50),
      _ChartData('Fri', 30),
      _ChartData('Sat', 70),
      _ChartData('Sun', 80),
    ];
  }
}

class _ChartData {
  final String day;
  final double strikeRate;

  _ChartData(this.day, this.strikeRate);
}
