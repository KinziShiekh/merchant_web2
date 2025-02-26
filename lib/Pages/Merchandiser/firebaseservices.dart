import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:merchandiser_web/Models/mercandiser.dart';

class FirebaseService {
  static final CollectionReference _salesManCollection = FirebaseFirestore
      .instance
      .collection('Merchandiser'); // Define collection reference

  static Future<void> addSalesManToFirestore(Merchandiser merchand) async {
    try {
      // Save SalesMan to Firestore using the specified user ID
      await _salesManCollection
          .doc(merchand.merchandiserId)
          .set(merchand.toMap());
    } catch (e) {
      print('Error adding SalesMan to Firestore: $e');
      rethrow; // Propagate error for handling
    }
  }
}
