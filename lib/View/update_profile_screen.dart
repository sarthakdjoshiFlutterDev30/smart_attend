import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Model/student_model.dart';

class UpdateProfileScreen extends StatefulWidget {
  final StudentModel student;

  const UpdateProfileScreen({super.key, required this.student});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController enrollmentController;
  String? selectedCourse;
  String? selectedSemester;
  bool _isLoading=true;
  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student.name);
    enrollmentController = TextEditingController(
      text: widget.student.enrollment,
    );
    selectedCourse = widget.student.course;
    selectedSemester = widget.student.semester;
  }

  Future<void> updateStudent() async {
    setState(() {
      _isLoading=false;
    });
    await FirebaseFirestore.instance
        .collection("Students")
        .doc(widget.student.id)
        .update({
          'name': nameController.text.trim(),
          'enrollment': enrollmentController.text.trim(),
          'course': selectedCourse,
          'semester':selectedSemester,
        }).then((_){
          setState(() {
            _isLoading=true;
          });
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: enrollmentController,
              decoration: const InputDecoration(labelText: "Enrollment"),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Select Course"),
              value: selectedCourse,
              items: courseSemesters.keys.map((course) {
                return DropdownMenuItem(value: course, child: Text(course));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCourse = value;
                  selectedSemester = null; // reset semester when course changes
                });
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Select Semester"),
              value: selectedSemester,
              items: selectedCourse == null
                  ? []
                  : courseSemesters[selectedCourse]!.map((sem) {
                      return DropdownMenuItem(value: sem, child: Text(sem));
                    }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSemester = value;
                });
              },
            ),
            const SizedBox(height: 20),
            (_isLoading)?
            ElevatedButton.icon(
              icon: const Icon(Icons.update),
              label: const Text("Update"),
              onPressed: updateStudent,
            ):CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
