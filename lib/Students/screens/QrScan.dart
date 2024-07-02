import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QrCodeScreenS extends StatefulWidget {
  @override
  _QrCodeScreenSState createState() => _QrCodeScreenSState();
}

class _QrCodeScreenSState extends State<QrCodeScreenS> {
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Set<String> scannedQRs = Set<String>();

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    // Implement permission request logic here if needed
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      String? scannedData = scanData.code;
      if (scannedData != null && scannedData.isNotEmpty && !scannedQRs.contains(scannedData)) {
        bool marked = await markAttendance(scannedData);
        if (marked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attendance marked successfully')),
          );
          setState(() {
            scannedQRs.add(scannedData);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to mark attendance')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid QR code data or already processed')),
          );
        }
      }
    });
  }

  Future<bool> markAttendance(String scannedData) async {
    try {
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      String userId = scannedData;
      print('Scanned Data: $scannedData');
      print('Current User ID: ${user!.uid}');

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: _today())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot attendanceDoc = querySnapshot.docs.first;
        await attendanceDoc.reference.update({
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('attendance').add({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'date': _today(),
        });
      }

      print('Attendance marked successfully');
      return true;
    } catch (error, stackTrace) {
      print('Error marking attendance: $error');
      print(stackTrace);
      return false;
    }
  }

  DateTime _today() {
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.width - 40,
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  markAttendance(user!.uid);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Color(0xFF2D5F9E),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Mark Attendance Manually'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: QrCodeScreenS(),
  ));
}
