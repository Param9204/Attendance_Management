import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
        ),
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }

    final Stream<QuerySnapshot> _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('studentEmail', isEqualTo: user.email)
        .orderBy('date', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications available'));
          }

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return _buildNotificationCard(context, data, document.id);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> data, String documentId) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          // Handle tap on notification card if needed
        },
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          title: Text(
            data['title'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0C254C)),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.0),
              Text(
                data['message'],
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8.0),
              Text(
                DateFormat('dd-MM-yyyy').format(data['date'].toDate()),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmationDialog(context, documentId);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String documentId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Notification'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this notification?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteNotification(context, documentId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNotification(BuildContext context, String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete notification'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
