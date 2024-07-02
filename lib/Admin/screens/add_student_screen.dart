import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddStudentScreen extends StatefulWidget {
  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  TextEditingController name = TextEditingController();
  TextEditingController rolln = TextEditingController();

  var subject = 'Math';
  var options = ['Math', 'Science', 'History', 'English', 'Computer Science'];
  var _currentItemSelected = "Math";
  var semester = '1';
  var options1 = ['1', '2', '3', '4', '5', '6', '7', '8'];
  var _currentItemSelected1 = "1";

  CollectionReference ref = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Add Students', style: TextStyle(color: Colors.black)),
      //   backgroundColor: Colors.white,
      //   centerTitle: true,
      //   automaticallyImplyLeading: false,
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C254C), Color(0xFF2D5F9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 50),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage('assets/addstudents.png'),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildTextField(
                    controller: name,
                    label: 'Name',
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: rolln,
                    label: 'Roll number',
                  ),
                  SizedBox(height: 20),
                  _buildDropdownButton(
                    currentValue: _currentItemSelected,
                    items: options,
                    onChanged: (newValue) {
                      setState(() {
                        _currentItemSelected = newValue!;
                        subject = _currentItemSelected;
                      });
                    },
                    label: 'Subject',
                  ),
                  SizedBox(height: 20),
                  _buildDropdownButton(
                    currentValue: _currentItemSelected1,
                    items: options1,
                    onChanged: (newValue) {
                      setState(() {
                        _currentItemSelected1 = newValue!;
                        semester = _currentItemSelected1;
                      });
                    },
                    label: 'Semester',
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (name.text.isNotEmpty && rolln.text.isNotEmpty) {
                        ref.add({
                          'name': name.text,
                          'subject': subject,
                          'semester': semester,
                          'roll number': rolln.text,
                          'totalClasses': 0,
                          'attendedClasses': 0,
                        }).then((value) {
                          Fluttertoast.showToast(
                            msg: 'Student added successfully',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                          name.clear();
                          rolln.clear();
                        }).catchError((error) {
                          Fluttertoast.showToast(
                            msg: 'Failed to add student: $error',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        });
                      } else {
                        Fluttertoast.showToast(
                          msg: 'Please fill in all fields',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF0C254C),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20), // Add bottom padding to avoid white space
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
      ),
    );
  }

  Widget _buildDropdownButton({
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.blue[900],
      value: currentValue,
      onChanged: onChanged,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 20,
            ),
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
      ),
    );
  }
}
