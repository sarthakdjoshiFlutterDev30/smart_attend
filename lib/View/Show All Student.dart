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
      appBar: AppBar(
        title: const Text("All Students"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Select Course",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedCourse,
                    items: courseSemesters.keys.map((course) {
                      return DropdownMenuItem(
                        value: course,
                        child: Text(course),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value;
                        selectedSemester = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Select Semester",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedSemester,
                    items: selectedCourse == null
                        ? []
                        : courseSemesters[selectedCourse]!.map((sem) {
                            return DropdownMenuItem(
                              value: sem,
                              child: Text(sem),
                            );
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
            const SizedBox(height: 12),
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
                    return const Center(
                      child: Text(
                        "No students found.",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final studentDocs = snapshot.data!.docs;
                  List<StudentModel> students = studentDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return StudentModel.fromSnapshot(doc.id, data);
                  }).toList();

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final doc = students[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(doc.photourl ?? ""),
                          ),
                          title: Text(
                            doc.name ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Email: ${doc.email ?? 'N/A'}"),
                              Text("Enrollment: ${doc.enrollment ?? 'N/A'}"),
                              Text("Course: ${doc.course ?? 'N/A'}"),
                              Text("Semester: ${doc.semester ?? 'N/A'}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
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
      ),
    );
  }
}
