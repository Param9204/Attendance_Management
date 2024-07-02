import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendAttendanceNotifications(List<DocumentSnapshot> studentDocs) async {
    for (DocumentSnapshot studentDoc in studentDocs) {
      var data = studentDoc.data() as Map<String, dynamic>;
      var totalClasses = data['totalClasses'] ?? 0;
      var attendedClasses = data['attendedClasses'] ?? 0;

      if (totalClasses > 0) {
        double attendancePercentage = (attendedClasses / totalClasses) * 100;

        if (attendancePercentage < 75) {
          String studentName = data['name'] ?? 'Student';
          String studentEmail = data['email'] ?? '';

          // Create a notification document in Firestore
          await FirebaseFirestore.instance.collection('notifications').add({
            'title': 'Low Attendance Alert',
            'message': 'Dear $studentName, your attendance is below 75%. Please attend more classes to improve your attendance.',
            'studentEmail': studentEmail,
            'date': DateTime.now(),
          });
        }
      }
    }
  }
}
