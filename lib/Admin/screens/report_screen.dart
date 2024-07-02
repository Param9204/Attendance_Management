import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  final List<String> list;
  final String clas;

  ReportScreen({required this.list, required this.clas});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late List<Map<String, dynamic>> studentsData;
  bool _loading = true;
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    studentsData = [];
    _getUser(); // Initialize _currentUser
  }

  // Method to get current authenticated user
  void _getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        fetchStudentsData(); // Fetch data if user is authenticated
      } else {
        // Handle case where user is not authenticated (optional)
        // You can show a login screen or handle this based on your app's design
      }
    });
  }

  Future<void> fetchStudentsData() async {
    if (_currentUser == null) return; // Exit if user is not authenticated

    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('users')
          .where('subject', whereIn: widget.list) // Use whereIn for multiple subjects
          .where('semester', isEqualTo: widget.clas)
          .get();

      List<Map<String, dynamic>> data = querySnapshot.docs.map((doc) {
        int totalClasses = doc['totalClasses'] ?? 0;
        int attendedClasses = doc['attendedClasses'] ?? 0;
        String subject = doc['subject'] ?? 'N/A';
        String semester = doc['semester'] ?? 'N/A';

        double attendancePercentage =
        totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

        return {
          'name': doc['name'],
          'totalClasses': totalClasses,
          'attendedClasses': attendedClasses,
          'attendancePercentage': attendancePercentage,
          'subject': subject,
          'semester': semester,
        };
      }).toList();

      setState(() {
        studentsData = data;
        _loading = false;
      });

      // Debug print to verify fetched data
      print('Students Data: $studentsData');
    } catch (e) {
      print('Error fetching students data: $e');
      setState(() {
        _loading = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : PdfPreview(
        build: (format) => generateDocument(format),
      ),
    );
  }

  Future<Uint8List> generateDocument(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 30,
            marginLeft: 30,
            marginRight: 30,
            marginTop: 30,
          ),
          orientation: pw.PageOrientation.portrait,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(
                  fontSize: 25,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 18),
                  ),
                  pw.Text(
                    'Class: ${widget.clas}',
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Name',
                  'Subject',
                  'Semester',
                  'Total Classes',
                  'Attended Classes',
                  'Attendance %',
                ],
                data: List<List<String>>.generate(
                  studentsData.length,
                      (index) => [
                    studentsData[index]['name'].toString(),
                    studentsData[index]['subject'].toString(),
                    studentsData[index]['semester'].toString(),
                    studentsData[index]['totalClasses'].toString(),
                    studentsData[index]['attendedClasses'].toString(),
                    '${studentsData[index]['attendancePercentage'].toStringAsFixed(2)}%',
                  ],
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 1,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(fontSize: 16),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save(); // Save the PDF document and return as Uint8List
  }
}
