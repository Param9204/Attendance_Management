import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:demo2/Admin/screens/add_student_screen.dart';
import 'package:demo2/Admin/screens/attendancemain.dart';
import 'package:demo2/Admin/screens/auth/login_screen.dart';
import 'package:demo2/Admin/screens/profile_screen.dart';
import 'package:demo2/Admin/screens/attendance_screen.dart';
import 'package:demo2/Admin/screens/history_screen.dart';
import 'package:demo2/Admin/screens/report_screen.dart';
import 'package:demo2/Admin/screens/qr_code_screen.dart';
import 'package:demo2/Admin/services/auth_srevice.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late User? user;
  String selectedSubject = 'Math';
  String selectedSemester = '1';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    user = FirebaseAuth.instance.currentUser;
    _refreshUser();
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.0),
        child: CustomAppBar(user: user, refreshUser: _refreshUser),
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
            child: GridView.builder(
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemBuilder: (context, index) {
                return _buildAnimatedDashboardItem(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDashboardItem(int index) {
    final items = [
      {
        'title': 'Attendance',
        'icon': Icons.check_circle_outline_sharp,
        'color': Colors.lightBlue,
        'route': AttendanceMain()
      },
      {
        'title': 'History',
        'icon': Icons.history,
        'color': Colors.green,
        'route': HistoryScreen(selectedSubject: selectedSubject, selectedSemester: selectedSemester)
      },
      {
        'title': 'Reports',
        'icon': Icons.error_outline,
        'color': Colors.orange,
        'route': ReportScreen(list: ['Student 1', 'Student 2', 'Student 3'], clas: '1A')
      },
      {
        'title': 'QR Code',
        'icon': Icons.qr_code,
        'color': Colors.red,
        'route': QrCodeScreen()
      },
    ];

    final item = items[index];

    return ScaleTransition(
      scale: CurvedAnimation(parent: _animationController, curve: Interval(0.1 * index, 1.0, curve: Curves.elasticOut)),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['route'] as Widget),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [(item['color'] as Color).withOpacity(0.8), item['color'] as Color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, size: 48, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    item['title'] as String,
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
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  final User? user;
  final VoidCallback refreshUser;

  const CustomAppBar({
    Key? key,
    required this.user,
    required this.refreshUser,
  }) : super(key: key);

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25), // Added SizedBox for spacing
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/hello_dashboard.png'),
              ),
              SizedBox(height: 4), // Adjusted height for spacing
              Text(
                'Hello ${user?.displayName ?? 'Guest'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              refreshUser();
            },
            child: Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
