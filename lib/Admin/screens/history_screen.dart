import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';

class HistoryScreen extends StatefulWidget {
  final String selectedSubject;
  final String selectedSemester;

  HistoryScreen({required this.selectedSubject, required this.selectedSemester});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Stream<QuerySnapshot> _attendanceStream;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _attendanceStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.0),
        child: CustomAppBar(),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0C254C), Color(0xFF2D5F9E)],
              ),
            ),
          ),
          Positioned(
            top: 10.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.black87), // Text color
                  cursorColor: Colors.black87, // Cursor color
                  decoration: InputDecoration(
                    hintText: 'Search by student name',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.7)), // Hint text color
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search, color: Colors.black87), // Search icon
                    suffixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    contentPadding: EdgeInsets.all(10.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Update the stream to filter based on the search input
                      _attendanceStream = FirebaseFirestore.instance
                          .collection('users')
                          .where('name', isGreaterThanOrEqualTo: value)
                          .where('name', isLessThanOrEqualTo: value + '\uf8ff')
                          .snapshots();
                    });
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 100.0,
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder(
              stream: _attendanceStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print("Firestore Error: ${snapshot.error}");
                  return Center(child: Text("Firestore Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No data available"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (_, index) {
                    var userDoc = snapshot.data!.docs[index];
                    var userData = userDoc.data() as Map<String, dynamic>;
                    var userName = userData['name'] ?? 'No name';
                    var userSubject = userData['subject'];
                    var userSemester = userData['semester'];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            SizedBox(height: 5),
                            Text('Subject: $userSubject'),
                            Text('Semester: $userSemester'),
                          ],
                        ),
                        children: [
                          StreamBuilder(
                            stream: userDoc.reference.collection('attendance').snapshots(),
                            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> attendanceSnapshot) {
                              if (attendanceSnapshot.hasError) {
                                print("Firestore Error: ${attendanceSnapshot.error}");
                                return Center(child: Text("Firestore Error: ${attendanceSnapshot.error}"));
                              }
                              if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              // Separate lists for present and absent entries
                              List<DocumentSnapshot> presentEntries = [];
                              List<DocumentSnapshot> absentEntries = [];

                              // Categorize attendance entries
                              attendanceSnapshot.data!.docs.forEach((attendanceDoc) {
                                var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
                                var status = attendanceData['status'] ?? 'absent';
                                if (status == 'present') {
                                  presentEntries.add(attendanceDoc);
                                } else {
                                  absentEntries.add(attendanceDoc);
                                }
                              });

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (presentEntries.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Present:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: presentEntries.length,
                                      itemBuilder: (_, presentIndex) {
                                        var attendanceDoc = presentEntries[presentIndex];
                                        var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
                                        var attendanceDate = (attendanceData['date'] as Timestamp).toDate();
                                        return ListTile(
                                          title: Text(DateFormat('dd-MM-yyyy').format(attendanceDate)),
                                          trailing: Text(
                                            'Present',
                                            style: TextStyle(color: Colors.green),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  if (absentEntries.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Absent:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: absentEntries.length,
                                      itemBuilder: (_, absentIndex) {
                                        var attendanceDoc = absentEntries[absentIndex];
                                        var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
                                        var attendanceDate = (attendanceData['date'] as Timestamp).toDate();
                                        return ListTile(
                                          title: Text(DateFormat('dd-MM-yyyy').format(attendanceDate)),
                                          trailing: Text(
                                            'Absent',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  final User? user;

  const CustomAppBar({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C254C), Color(0xFF2D5F9E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0), // Adjusted padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context); // Example of navigation to go back
            },
            icon: Icon(Icons.arrow_back, color: Colors.white), // Back button icon
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25), // Added SizedBox for spacing
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/history.png'), // Adjusted image asset
              ),
              SizedBox(height: 4), // Adjusted height for spacing
              Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
