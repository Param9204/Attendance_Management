import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to get user details by name from the 'users' collection
  Future<List<Map<String, dynamic>>> getUsersByName(String name) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('users')
          .where('name', isEqualTo: name)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching users by name: $e');
      throw e;
    }
  }

  // Method to get student details by name from the 'students' collection
  Future<List<Map<String, dynamic>>> getStudentsByName(String name) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('students')
          .where('name', isEqualTo: name)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching students by name: $e');
      throw e;
    }
  }
}
