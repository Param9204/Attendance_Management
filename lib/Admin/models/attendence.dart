import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String userId;
  final DateTime date;
  final int totalClasses;
  final int attendedClasses;
  final String status;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.totalClasses = 0, // Default value
    this.attendedClasses = 0, // Default value
    this.status = 'absent', // Default value for new field
  });

  // get rollNumber => null;
  //
  // get semester => null;
  //
  // get subject => null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
      'status': status, // Include status in the map
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map, String id) {
    return Attendance(
      id: id,
      userId: map['userId'],
      date: DateTime.parse(map['date']),
      totalClasses: map['totalClasses'] ?? 0,
      attendedClasses: map['attendedClasses'] ?? 0,
      status: map['status'] ?? 'absent', // Assign default value for status
    );
  }

  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
    return Attendance(
      id: doc.id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      totalClasses: map['totalClasses'] ?? 0,
      attendedClasses: map['attendedClasses'] ?? 0,
      status: map['status'] ?? 'absent', // Assign default value for status
    );
  }


}
