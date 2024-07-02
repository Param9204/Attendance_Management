import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> markAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final attendanceRef = _db.collection('attendance').doc(user.uid);
      final snapshot = await attendanceRef.get();
      final data = snapshot.data();

      if (data != null && data['dates'] != null) {
        List dates = data['dates'];
        dates.add(DateTime.now().toIso8601String());
        await attendanceRef.update({'dates': dates});
      } else {
        await attendanceRef.set({'dates': [DateTime.now().toIso8601String()]});
      }
    }
  }

  Future<List<DateTime>> getAttendanceHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final attendanceRef = _db.collection('attendance').doc(user.uid);
      final snapshot = await attendanceRef.get();
      final data = snapshot.data();

      if (data != null && data['dates'] != null) {
        return List<DateTime>.from(
          data['dates'].map((date) => DateTime.parse(date)).toList(),
        );
      }
    }
    return [];
  }
}
