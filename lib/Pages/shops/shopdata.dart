import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:merchandiser_web/constant/colors.dart';

class ShopDetailsScreen extends StatelessWidget {
  final String shopName;

  ShopDetailsScreen({required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.download))],
        title: Text(
          "Shop Details",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(color: AppColors.MainColor),
        ),
      ),
      body: FutureBuilder(
        future:
            FirebaseFirestore.instance.collection('Shops').doc(shopName).get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return Center(
                child: Text("No shop data found!",
                    style: TextStyle(fontSize: 18, color: Colors.red)));
          }

          var shopData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<dynamic> unavailableBrands = shopData['unavailableBrand'] ?? [];

          // Get Banner Image URL
          var bannerImage = shopData['BannerImage'];

          // Handle Banner Image
          if (bannerImage is List && bannerImage.isNotEmpty) {
            bannerImage =
                bannerImage[0]; // Use the first image if it's a list of URLs
          }

          // Check if the BannerImage is a valid string (URL)
          if (bannerImage is! String) {
            bannerImage = null; // If it's not a string, set it to null
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Banner Image
                if (bannerImage != null && bannerImage.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        bannerImage,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child; // Image is fully loaded
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          }
                        },
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          // Handle image loading error (e.g., network issues)
                          return Center(
                            child: Image.asset(
                              'assets/placeholder_image.png', // Your placeholder image
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  // If the bannerImage is null, show a placeholder
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/placeholder_image.png', // Placeholder image when no URL is available
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: 20),

                // Shop Name Card
                _buildInfoCard(
                  icon: Icons.store,
                  title: "Shop Name",
                  values: [shopData['name'] ?? 'N/A'],
                  color: AppColors.MainColor,
                ),
                SizedBox(height: 16),

                // Visit Status with a Custom Badge
                _buildInfoCard(
                  icon: Icons.check_circle,
                  title: "Visit Status",
                  values: [
                    shopData['visited'] == true ? 'Visited' : 'Not Visited'
                  ],
                  color:
                      shopData['visited'] == true ? Colors.green : Colors.red,
                  badge: true,
                ),
                SizedBox(height: 16),

                // Visit Timing
                _buildInfoCard(
                  icon: Icons.access_time,
                  title: "Visit Timing",
                  values: [shopData['visitTiming'] ?? 'Not Available'],
                  color: Colors.orange,
                ),
                SizedBox(height: 16),

                // Unavailable Brands Table
                if (unavailableBrands.isNotEmpty) ...[
                  const Text(
                    "Unavailable Brands:",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  _buildUnavailableBrandsTable(unavailableBrands),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> values,
    required Color color,
    bool badge = false,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  badge
                      ? Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            values.isNotEmpty ? values[0] : 'N/A',
                            style: TextStyle(
                                fontSize: 14,
                                color: color,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : Text(
                          values.isNotEmpty ? values[0] : 'N/A',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableBrandsTable(List<dynamic> unavailableBrands) {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 1),
      children: [
        // Table Header
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "Brand",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "Price",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
        // Table Data
        ...unavailableBrands.map<TableRow>((brand) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  brand['Brand'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  brand['Price'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
