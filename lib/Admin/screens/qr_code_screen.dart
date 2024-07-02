import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QrCodeScreen extends StatefulWidget {
  @override
  _QrCodeScreenState createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String qrData = '';
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

      return true;
    } catch (error, stackTrace) {
      print('Error marking attendance: $error');
      print(stackTrace);
      return false;
    }
  }

  Future<void> _shareQRCode() async {
    try {
      final directory = (await getApplicationDocumentsDirectory()).path;
      final qrCodeFile = File('$directory/qr_code.png');

      final painter = QrPainter(
        data: qrData.isNotEmpty ? qrData : user!.uid,
        version: QrVersions.auto,
        gapless: false,
        color: Color(0xFF000000),
        emptyColor: Color(0xFFFFFFFF),
      );

      final picData = await painter.toImageData(200);
      final buffer = picData!.buffer.asUint8List();
      await qrCodeFile.writeAsBytes(buffer);

      await Share.shareXFiles(
        [XFile(qrCodeFile.path)],
        text: 'Scan this QR code!',
      );
    } catch (error) {
      print(error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share QR code')),
        );
      }
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    qrData = '';
                  });
                  await _shareQRCode();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Color(0xFF0C254C),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Generate and Share QR Code'),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: QrImageView(
                  data: user!.uid,
                  size: 200,
                ),
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
    home: QrCodeScreen(),
  ));
}
