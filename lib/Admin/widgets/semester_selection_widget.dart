import 'package:flutter/material.dart';

class SemesterSelectionWidget extends StatelessWidget {
  final List<String> semesters;
  final Function(String) onSemesterSelected;
  final String initialSemester;

  SemesterSelectionWidget({
    required this.semesters,
    required this.onSemesterSelected,
    required this.initialSemester,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: initialSemester,
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.black),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onSemesterSelected(newValue);
        }
      },
      items: semesters.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
