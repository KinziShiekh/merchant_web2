import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/Models/mercandiser.dart';
import 'package:merchandiser_web/constant/colors.dart';
import 'package:merchandiser_web/constant/images.dart';

class AddMerchandiserPage extends StatefulWidget {
  @override
  _AddMerchandiserPageState createState() => _AddMerchandiserPageState();
}

class _AddMerchandiserPageState extends State<AddMerchandiserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Map<String, List<Map<String, dynamic>>> weeklyShops = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
  };

  String selectedDay = 'Monday'; // Default selected day
  List<Map<String, dynamic>> uploadedShops = [];
  String distributor = 'Loading...'; // To store uploaded shops temporarily

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
            distributor = userData['userId'] ?? 'Unknown Distributor';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text('Add a Merchandiser',
            style:
                TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(AppImages.laysLogo, height: 40),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionHeader('Merchandiser Details'),
              buildTextField(usernameController, 'Username', Icons.person),
              buildTextField(passwordController, 'Password', Icons.lock,
                  obscureText: true),
              buildTextField(phoneController, 'Phone #', Icons.phone),
              buildTextField(addressController, 'Address', Icons.home),
              buildTextField(emailController, 'Email', Icons.home),
              Row(
                children: [
                  Expanded(
                      child: buildTextField(
                          cityController, 'City', Icons.location_city)),
                  SizedBox(width: 10),
                  Expanded(
                      child:
                          buildTextField(stateController, 'State', Icons.map)),
                ],
              ),
              SizedBox(height: 20),
              buildSectionHeader('Shop Management'),
              Row(
                children: [
                  Expanded(
                    child:
                        buildButton('Upload Shops', Icons.upload, uploadShops),
                  ),
                ],
              ),
              SizedBox(height: 20),
              buildShopAssignmentSection(),
              SizedBox(height: 20),
              buildShopsTable(),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.MainColor,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await addMerchandiserToFirestore(user.uid);
                    } else {
                      Get.snackbar('Error', 'User not logged in',
                          backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                  child: Text('Add',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.orange),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.orange),
          ),
        ),
      ),
    );
  }

  Widget buildButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      icon: Icon(icon, color: Colors.orange),
      label: Text(text, style: TextStyle(color: Colors.orange)),
    );
  }

  Widget buildShopAssignmentSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign Shops to Days',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedDay,
              items: weeklyShops.keys.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value!;
                });
              },
            ),
            const SizedBox(height: 10),
            if (uploadedShops.isNotEmpty)
              SizedBox(
                height: 250, // Adjust the height as needed
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uploadedShops.length,
                  itemBuilder: (context, index) {
                    final shop = uploadedShops[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          shop['name'] ?? 'Unknown Shop',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Area: ${shop['area'] ?? 'Unknown'}"),
                            Text(
                                "Longitude: ${shop['longitude'] ?? 'Unknown'}"),
                            Text("Latitude: ${shop['latitude'] ?? 'Unknown'}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              weeklyShops[selectedDay]?.add(shop);
                              uploadedShops.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "No shops uploaded yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildShopsTable() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(color: Colors.orange),
          children: weeklyShops.entries.map((entry) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(entry.key,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      entry.value.map((shop) => shop['name']).join(', '),
                      style: TextStyle(fontSize: 14)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void uploadShops() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'csv']);

    if (result != null && result.files.single.bytes != null) {
      String fileContent = String.fromCharCodes(result.files.single.bytes!);
      List<String> lines = fileContent.split('\n');

      setState(() {
        uploadedShops = lines
            .where((line) => line.trim().isNotEmpty) // Remove empty lines
            .map((line) {
              List<String> shopData = line.split(',');
              if (shopData.length == 4) {
                return {
                  'name': shopData[0].trim(),
                  'area': shopData[1].trim(),
                  'longitude': double.tryParse(shopData[2].trim()) ?? 0.0,
                  'latitude': double.tryParse(shopData[3].trim()) ?? 0.0,
                };
              } else {
                print("Invalid line format: $line");
                return null; // Skip invalid lines
              }
            })
            .whereType<Map<String, dynamic>>()
            .toList();
      });

      print("Uploaded Shops: $uploadedShops");
    } else {
      print("No file selected or invalid file content");
      Get.snackbar("Error", "File not selected or invalid format.",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> addMerchandiserToFirestore(String distributorId) async {
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // ✅ Create Merchandiser instance
      Merchandiser merchandiser = Merchandiser(
        merchandiserId: userCredential.user?.uid, // Firebase Auth ID
        name: usernameController.text,
        email: emailController.text,
        phone: phoneController.text,
        address: addressController.text,
        city: cityController.text,
        state: stateController.text,
        distributorId: distributorId,

        password: passwordController.text,
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        // Fetch distributor details
        DocumentSnapshot distributorDoc = await FirebaseFirestore.instance
            .collection('distributors')
            .doc(distributorId)
            .get();

        if (!distributorDoc.exists) {
          Get.snackbar('Error', 'Distributor not found!',
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        String distributorName = distributorDoc['distributorName'] ?? "Unknown";

        // Add the merchandiser document with auto-generated ID
        final merchandiserRef = await FirebaseFirestore.instance
            .collection('distributors')
            .doc(distributorId)
            .collection('Merchandiser')
            .add({
          'uidMerchandiser': uid,
          'distributorName': distributorName,
          'distributorId': distributorId,
          'Name': usernameController.text.trim(),
          'password': passwordController.text.trim(),
          'ContactNo': phoneController.text.trim(),
          'Address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'shops': weeklyShops
        });

        // Get the auto-generated merchandiserId
        String merchandiserId =
            merchandiserRef.id; // Firestore generates this ID

        // Update the document with the generated ID
        await merchandiserRef.update({
          'merchandiserId': merchandiserId,
        });

        // Also add to the root Merchandiser collection with the auto-generated ID
        await FirebaseFirestore.instance
            .collection('Merchandiser')
            .doc(merchandiserId)
            .set({
          'merchandiserId': merchandiserId,
          'uidMerchandiser': uid,
          'distributorName': distributorName,
          'distributorId': distributorId,
          'Name': usernameController.text.trim(),
          'password': passwordController.text.trim(),
          'ContactNo': phoneController.text.trim(),
          'Address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'shops': weeklyShops
        });

        // Add shops under the merchandiser
        for (var entry in weeklyShops.entries) {
          for (var shop in entry.value) {
            await merchandiserRef.collection('Shops').add({
              'MerchandiserName': usernameController.text.trim(),
              'uidMerchandiser': uid,
              'distributorName': distributorName,
              'day': entry.key,
              'ShopId': shop['shopId'],
              'name': shop['name'],
              'area': shop['area'],
              'longitude': shop['longitude'],
              'latitude': shop['latitude'],
              'bannerImage': '', // Initially empty
              'unavailableBrand': '',
              'beforeRack': '',
              'afterRack': '',
              'visitedTime': '',
              'visited': false, // Initially false
            });

            // Update the root Shops collection
            await FirebaseFirestore.instance
                .collection('Shops')
                .doc(shop['name'])
                .set({
              'Day': entry.key,
              'uidMerchandiser': uid,
              'name': shop['name'],
              'area': shop['area'],
              'longitude': shop['longitude'],
              'latitude': shop['latitude'],
              'ShopId': shop['shopId'],
              'distributorId': distributorId,
              'assignedMerchandisers': usernameController.text.trim(),
              'bannerImage': '',
              'unavailableBrand': '',
              'beforeRack': '',
              'afterRack': '',
              'visitedTime': '',
              'visited': false, // Initially false
            }, SetOptions(merge: true));
          }
        }

        // Now call signUpFunction to create the user with the username and password

        Get.snackbar('Success', 'Merchandiser and Shops Added Successfully!',
            backgroundColor: Colors.green, colorText: Colors.white);

        // Clear fields after success
        usernameController.clear();
        passwordController.clear();
        phoneController.clear();
        addressController.clear();
        cityController.clear();
        stateController.clear();
        setState(() {
          weeklyShops = {
            'Monday': [],
            'Tuesday': [],
            'Wednesday': [],
            'Thursday': [],
            'Friday': [],
            'Saturday': [],
          };
          uploadedShops.clear();
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add merchandiser: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
