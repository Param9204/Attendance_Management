import 'package:flutter/material.dart';

class SubjectSelectionWidget extends StatelessWidget {
  final List<String> subjects;
  final Function(String) onSubjectSelected;

  SubjectSelectionWidget({
    required this.subjects,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: subjects.first,
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.black),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onSubjectSelected(newValue);
        }
      },
      items: subjects.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
