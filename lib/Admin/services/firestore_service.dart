import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/Admin/models/attendence.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _attendanceCollection = 'attendance';

  // Add attendance record
  Future<void> addAttendance(String userId) async {
    try {
      await _db.collection(_attendanceCollection).add({
        'userId': userId,
        'date': FieldValue.serverTimestamp(),
      });
    }
    on FirebaseAuthException catch (e) {
      print('Error: $e');
      return null;
    }
    catch (e) {
      print(e.toString());
    }
  }

  // Get attendance records for a specific user
  Stream<List<Attendance>> streamUserAttendance(String userId) {
    return _db
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Stream attendance records by class name
  Stream<QuerySnapshot> streamClassAttendance(String className) {
    return _db
        .collection(_attendanceCollection)
        .where('class', isEqualTo: className)
        .snapshots();
  }
}
