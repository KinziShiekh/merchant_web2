import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/constant/colors.dart';

class Unavailablebrand2 extends StatelessWidget {
  final List<Map<String, dynamic>> shops;

  const Unavailablebrand2({super.key, required this.shops});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Details"),
        backgroundColor: AppColors.MainColor,
        elevation: 0,
      ),
      body: shops.isEmpty
          ? const Center(
              child: Text(
                "No shop data available",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                final List unavailableBrands =
                    shop['unavailableBrand'] ?? []; // Extract unavailableBrand

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Image
                        Hero(
                          tag: shop['name'] ?? 'shop-image-$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              shop['Bannerimage'] ?? '',
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Shop Name
                        Text(
                          shop['name'] ?? 'Unknown Shop',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shop['area'] ?? 'Unknown Area',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Lat/Lon
                        Row(
                          children: [
                            const Icon(Icons.map, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              "Lat: ${shop['latitude']} / Lon: ${shop['longitude']}",
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Merchandiser
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Merchandiser: ${shop['assignedMerchandisers'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ** Unavailable Brands Table **
                        if (unavailableBrands.isNotEmpty) ...[
                          const Text(
                            "Unavailable Brands:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Table(
                            border:
                                TableBorder.all(color: Colors.black, width: 1),
                            children: [
                              // Table Header
                              const TableRow(
                                decoration: BoxDecoration(color: Colors.grey),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Brand",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "Price",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              // Table Data
                              ...unavailableBrands.map((brand) {
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        brand['Brand'] ?? 'N/A',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        brand['Price'] ?? 'N/A',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Download Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // Future functionality (edit, delete, or view full details)
                            },
                            child: const Text("Download Report"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
