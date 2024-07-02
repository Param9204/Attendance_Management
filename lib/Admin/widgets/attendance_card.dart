import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  final String date;

  const AttendanceCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Date: $date'),
      ),
    );
  }
}
