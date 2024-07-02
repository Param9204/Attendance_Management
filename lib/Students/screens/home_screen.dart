import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo2/Admin/screens/qr_code_screen.dart';
import 'package:demo2/Students/screens/QrScan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo2/Students/services/student_auth_service.dart';
import 'package:demo2/Students/screens/profile_screen.dart';
import 'package:demo2/Students/screens/attendance_check_screen.dart'; // Import the AttendanceCheckScreen
import 'package:demo2/Students/screens/notification_screen.dart'; // Import the NotificationScreen
import 'package:firebase_core/firebase_core.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final VoidCallback onLogout;

  CustomAppBar({required this.user, required this.onLogout});

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
      padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/student_image.png'), // Ensure this asset is correct
              ),
              SizedBox(height: 4),
              Text(
                'Hello ${user?.displayName ?? 'Guest'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notification_add, color: Colors.white), // Notification icon
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationScreen()),
                  );
                },
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen()),
                  );
                },
                child: Icon(Icons.menu, color: Colors.white), // Menu icon
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(120.0); // Adjust height as needed
}


class StudentHomeScreen extends StatefulWidget {
  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late User? user;
  late String userId; // Store userId locally
  String? studentName; // Declare as nullable String

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeInAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    user = FirebaseAuth.instance.currentUser;
    userId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Initialize userId here
    _refreshUser();

    // Fetch studentName asynchronously
    fetchStudentName().then((name) {
      setState(() {
        studentName = name;
      });
    }).catchError((error) {
      print('Error fetching student name: $error');
      setState(() {
        studentName = 'Student'; // Provide a default value or handle error case
      });
    });
  }

  Future<String> fetchStudentName() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('uid', isEqualTo: userId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('name');
      }
      return 'Student'; // Return default value if no document found
    } catch (e) {
      print('Error fetching student name: $e');
      throw e; // Propagate the error to the caller
    }
  }

  Future<void> _refreshUser() async {
    user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authService = Provider.of<StudentAuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        user: currentUser,
        onLogout: () async {
          await authService.signOut();
          Navigator.popUntil(context, ModalRoute.withName('/'));
        },
      ),
      body: Container(
        width: double.infinity,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C254C), Color(0xFF2D5F9E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: [
                _buildDashboardItem(
                  title: 'Attendance Report',
                  icon: Icons.calendar_today,
                  color: Colors.lightBlue,
                  onTap: () {
                    // Check if studentName is fetched before navigating
                    if (studentName != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AttendanceCheckScreen(studentName: studentName!),
                        ),
                      );
                    } else {
                      // Handle case where studentName is not fetched yet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Student name is not available yet.'),
                        ),
                      );
                    }
                  },
                ),
                _buildDashboardItem(
                  title: 'View Grades',
                  icon: Icons.grade,
                  color: Colors.green,
                  onTap: () {
                    // Implement your functionality here
                  },
                ),
                _buildDashboardItem(
                  title: 'QR Scan',
                  icon: Icons.qr_code,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QrCodeScreenS(),
                      ),
                    );
                  },
                ),

                // Add more dashboard items as needed
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
