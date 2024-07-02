import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';

class MakePdfScreen extends StatefulWidget {
  final List<String> list;
  final String clas;
  final String subject;
  final String semester;
  final DateTime selectedDate;

  MakePdfScreen({
    required this.list,
    required this.clas,
    required this.subject,
    required this.semester,
    required this.selectedDate,
  });

  @override
  State<MakePdfScreen> createState() => _MakePdfScreenState();
}

class _MakePdfScreenState extends State<MakePdfScreen> {
  final pdf = pw.Document();
  List<Map<String, dynamic>> studentData = [];

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    // Fetch data from Firestore based on subject and semester
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('subject', isEqualTo: widget.subject)
          .where('semester', isEqualTo: widget.semester)
          .get();

      setState(() {
        studentData = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (error) {
      print("Error fetching student data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report'),
        centerTitle: true,
      ),
      body: PdfPreview(
        build: (format) => generateDocument(format),
      ),
    );
  }

  Future<Uint8List> generateDocument(PdfPageFormat format) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font1 = await PdfGoogleFonts.openSansRegular();
    final font2 = await PdfGoogleFonts.openSansBold();

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 20,
            marginLeft: 10,
            marginRight: 10,
            marginTop: 20,
          ),
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData.withFont(
            base: font1,
            bold: font2,
          ),
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: 30),
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(
                  fontSize: 25,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date:',
                    style: pw.TextStyle(fontSize: 20,fontWeight: pw.FontWeight.bold,),
                  ),
                  pw.Text(
                    DateFormat('dd-MM-yyyy').format(widget.selectedDate),
                    style: pw.TextStyle(fontSize: 20),
                  ),
                  pw.Text(
                    'Class:',
                    style: pw.TextStyle(fontSize: 20,fontWeight: pw.FontWeight.bold,),
                  ),
                  pw.Text(
                    '${widget.subject} ${widget.semester}',
                    style: pw.TextStyle(fontSize: 20),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Table(
                border: pw.TableBorder.all(),
                defaultColumnWidth: pw.FixedColumnWidth(140.0),
                children: [
                  pw.TableRow(children: [
                    pw.Text(
                      'Name',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Total Classes',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Attended Classes',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Attendance (%)',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ]),
                  for (var data in studentData)
                    pw.TableRow(children: [
                      pw.Text(
                        data['name'] ?? 'No Name',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        (data['totalClasses'] ?? 0).toString(),
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        (data['attendedClasses'] ?? 0).toString(),
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        '${((data['attendedClasses'] ?? 0) / (data['totalClasses'] ?? 1) * 100).toStringAsFixed(2)}%',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
