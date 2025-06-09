import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Model/student_model.dart';
import 'update_profile_screen.dart';

class ShowAllStudent extends StatefulWidget {
  const ShowAllStudent({super.key});

  @override
  State<ShowAllStudent> createState() => _ShowAllStudentState();
}

class _ShowAllStudentState extends State<ShowAllStudent> {
  String? selectedCourse;
  String? selectedSemester;
  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Show All Students")),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Select Course"),
                  value: selectedCourse,
                  items: courseSemesters.keys.map((course) {
                    return DropdownMenuItem(value: course, child: Text(course));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCourse = value;
                      selectedSemester =
                          null; // reset semester when course changes
                    });
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
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
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Students')
                  .where("course", isEqualTo: selectedCourse)
                  .where("semester", isEqualTo: selectedSemester)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty ||
                    selectedCourse == null ||
                    selectedSemester == null) {
                  return const Center(child: Text("No students found."));
                }

                final studentDocs = snapshot.data!.docs;

                // Convert each doc to StudentModel
                List<StudentModel> students = studentDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return StudentModel.fromSnapshot(doc.id, data);
                }).toList();

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final doc = students[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(doc.name ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: ${doc.email ?? 'No Email'}"),
                            Text(
                              "Enrollment: ${doc.enrollment ?? 'No Enrollment'}",
                            ),
                            Text("Course: ${doc.course ?? 'No Course'}"),
                            Text("Semester: ${doc.semester ?? 'No Semester'}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          // Use min to avoid overflow
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UpdateProfileScreen(student: doc),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('Students')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ],
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
    );
  }
}
