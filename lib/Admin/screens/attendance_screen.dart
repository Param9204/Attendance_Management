import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'makepdf.dart';
import 'package:demo2/Admin/services/notification_service.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String subjectSemester = 'Math1';
  List<String> subjects = ['Math', 'Science', 'History', 'English', 'Computer Science'];
  String selectedSubject = 'Math';
  List<String> semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  String selectedSemester = '1';
  List<String> temp = [];

  User? currentUser;
  DateTime selectedDate = DateTime.now();
  bool isAttendanceMarked = false;

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  void checkUser() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('User is not authenticated');
    } else {
      print('User is authenticated');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isAttendanceMarked = false;
      });
    }
  }

  Future<void> markAttendance() async {
    if (temp.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No students selected for attendance',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Update totalClasses for all students in the class
    QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('subject', isEqualTo: selectedSubject)
        .where('semester', isEqualTo: selectedSemester)
        .get();

    for (DocumentSnapshot studentDoc in studentsSnapshot.docs) {
      DocumentReference studentRef = studentDoc.reference;

      batch.update(studentRef, {
        'totalClasses': FieldValue.increment(1),
      });

      // Update attendedClasses for students marked present
      if (temp.contains(studentDoc['name'])) {
        batch.update(studentRef, {
          'attendedClasses': FieldValue.increment(1),
        });

        // Add attendance record for the student
        batch.set(
          studentRef
              .collection('attendance')
              .doc(selectedDate.toIso8601String()),
          {
            'date': selectedDate,
            'status': 'present',
            'subject': selectedSubject,
            'semester': selectedSemester,
          },
        );
      }
    }

    await batch.commit().then((_) {
      Fluttertoast.showToast(
        msg: 'Attendance marked successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      setState(() {
        isAttendanceMarked = true;
      });
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: 'Failed to mark attendance: $error',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance Page'),
          backgroundColor: Colors.blueAccent, // Change app bar color here
        ),
        body: Center(child: Text('Please sign in to view attendance')),
      );
    }

    final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('subject', isEqualTo: selectedSubject)
        .where('semester', isEqualTo: selectedSemester)
        .snapshots();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Attendance'),
          backgroundColor: Colors.blueAccent, // Change app bar color here
          actions: [
            Row(
              children: [
                DropdownButton<String>(
                  dropdownColor: Colors.blue[900],
                  isDense: true,
                  iconEnabledColor: Colors.white,
                  focusColor: Colors.white,
                  items: subjects.map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(
                        dropDownStringItem,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValueSelected) {
                    setState(() {
                      selectedSubject = newValueSelected!;
                      subjectSemester = selectedSubject + selectedSemester;
                    });
                    print(subjectSemester);
                  },
                  value: selectedSubject,
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  dropdownColor: Colors.blue[900],
                  isDense: true,
                  iconEnabledColor: Colors.white,
                  focusColor: Colors.white,
                  items: semesters.map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(
                        dropDownStringItem,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValueSelected1) {
                    setState(() {
                      selectedSemester = newValueSelected1!;
                      subjectSemester = selectedSubject + selectedSemester;
                    });
                    print(subjectSemester);
                  },
                  value: selectedSemester,
                ),
                SizedBox(width: 15),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MakePdfScreen(
                  list: temp,
                  clas: selectedSubject + selectedSemester,
                  subject: selectedSubject,
                  semester: selectedSemester,
                  selectedDate: selectedDate,
                ),
              ),
            );
          },
          label: Text('Generate PDF', style: TextStyle(color: Colors.white)), // Customize text color here
          icon: Icon(Icons.picture_as_pdf, color: Colors.white), // Customize icon and color here
          backgroundColor: Colors.blue, // Customize button color here
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C254C), Color(0xFF2D5F9E)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date:',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Background color
                      ),
                      onPressed: () => _selectDate(context),
                      child: Text(
                        DateFormat('dd-MM-yyyy').format(selectedDate),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAttendanceMarked ? Colors.grey : Colors.blue, // Background color
                      ),
                      onPressed: isAttendanceMarked ? null : markAttendance,
                      child: Text(
                        'Mark Attendance',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: _usersStream,
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      print("Firestore Error: ${snapshot.error}");
                      return Center(child: Text("Firestore Error: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (_, index) {
                        var docId = snapshot.data!.docs[index].id;
                        var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        var docName = data['name'] ?? 'No name';
                        var totalClasses = data['totalClasses'] ?? 0;
                        var attendedClasses = data['attendedClasses'] ?? 0;
                        var attendancePercentage = (totalClasses == 0)
                            ? 0
                            : (attendedClasses / totalClasses) * 100;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (temp.contains(docName)) {
                                temp.remove(docName);
                              } else {
                                temp.add(docName);
                              }
                            });
                            print(temp);
                          },
                          child: Card(
                            color: Colors.white, // Card background color
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                docName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), // Apply bold font weight here
                              ),
                              subtitle: Text(
                                'Attendance: ${attendancePercentage.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: attendancePercentage < 75 ? Colors.red : Colors.black,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 40,
                                    width: 40, // Adjust width to make it a circle
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle, // Make it circular
                                      color: temp.contains(docName)
                                          ? Color.fromARGB(255, 0, 228, 8)
                                          : Color.fromARGB(255, 248, 20, 4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        temp.contains(docName) ? 'P' : 'A',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(docId)
                                          .delete()
                                          .then((_) {
                                        print("Student deleted: $docName");
                                        Fluttertoast.showToast(
                                          msg: 'Student deleted successfully',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 16.0,
                                        );
                                      }).catchError((error) {
                                        print("Failed to delete student: $error");
                                        Fluttertoast.showToast(
                                          msg: 'Failed to delete student: $error',
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white,
                                          fontSize: 16.0,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
