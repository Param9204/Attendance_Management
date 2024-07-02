import 'package:flutter/material.dart';
import 'package:demo2/Students/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceCheckScreen extends StatefulWidget {
  final String studentName;

  AttendanceCheckScreen({required this.studentName});

  @override
  _AttendanceCheckScreenState createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends State<AttendanceCheckScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? userData;
  Map<String, dynamic>? studentData;
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      List<Map<String, dynamic>> users = await _firestoreService.getUsersByName(widget.studentName);

      if (users.isNotEmpty) {
        userData = users.first;

        List<Map<String, dynamic>> students = await _firestoreService.getStudentsByName(widget.studentName);

        if (students.isNotEmpty) {
          studentData = students.first;

          int attendedClasses = userData!['attendedClasses'];
          int totalClasses = userData!['totalClasses'];
          double attendancePercentage = _calculateAttendancePercentage(attendedClasses, totalClasses);

          if (attendancePercentage < 75) {
            await _sendLowAttendanceNotification();
          }
        } else {
          setState(() {
            hasError = true;
          });
        }
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      print('Error fetching user and student details: $e');
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateAttendancePercentage(int attendedClasses, int totalClasses) {
    if (totalClasses == 0) {
      return 0.0;
    }
    return (attendedClasses / totalClasses) * 100;
  }

  Future<void> _sendLowAttendanceNotification() async {
    try {
      int attendedClasses = userData!['attendedClasses'];
      int totalClasses = userData!['totalClasses'];
      double attendancePercentage = _calculateAttendancePercentage(attendedClasses, totalClasses);

      print('Attendance percentage: $attendancePercentage');

      if (attendancePercentage < 75) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'studentEmail': studentData!['email'],
          'title': 'Low Attendance Warning',
          'message': 'Your attendance is below 75%. Please attend classes regularly.',
          'date': Timestamp.now(),
        });
        print('Notification sent successfully');
      } else {
        print('Attendance is above 75%, no notification sent.');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0C254C), Color(0xFF2D5F9E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : hasError
              ? _buildErrorWidget()
              : userData != null && studentData != null
              ? Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDetailItem('Name', userData!['name']),
                  _buildDetailItem('Roll Number', userData!['roll number']),
                  _buildDetailItem('Semester', userData!['semester']),
                  _buildDetailItem('Subject', userData!['subject']),
                  _buildDetailItem('Attended Classes', userData!['attendedClasses'].toString()),
                  _buildDetailItem('Total Classes', userData!['totalClasses'].toString()),
                  SizedBox(height: 16),
                  _buildDetailItem('Email', studentData!['email']),
                  _buildAttendancePercentage(userData!['attendedClasses'], userData!['totalClasses']),
                ],
              ),
            ),
          )
              : Center(child: Text('Loading...')),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0C254C),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48.0,
          ),
          SizedBox(height: 16.0),
          Text(
            'Failed to load data',
            style: TextStyle(color: Colors.red, fontSize: 18.0),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePercentage(int attendedClasses, int totalClasses) {
    double attendancePercentage = _calculateAttendancePercentage(attendedClasses, totalClasses);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              'Attendance Percentage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0C254C),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${attendancePercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16,
                color: attendancePercentage < 75 ? Colors.red : Colors.black87,
                fontWeight: attendancePercentage < 75 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
