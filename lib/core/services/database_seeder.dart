import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseSeeder {
  static Future<void> seedData() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Clear legacy data if needed, or just stop seeding it
      debugPrint('Database: Cleaning up legacy data collections...');
      
      // Note: In a production app, we would use a more robust way to clear data
      // For this prototype, we'll just stop adding the old entries.
      
      final smartTherapy = {
        'id': 'smart_hand_1',
        'therapyName': 'Smart Hand Rehabilitation',
        'description': 'Hardware-integrated reflex and strength training.',
        'duration': 'Daily / 10 mins',
        'instructions': 'Follow the smart terminal prompts.',
      };

      await firestore.collection('therapies').doc(smartTherapy['id'] as String).set(smartTherapy);
      
      debugPrint('Database: Smart therapy seeded successfully!');
    } catch (e) {
      debugPrint('Error during database cleanup/seeding: $e');
    }
  }
}
