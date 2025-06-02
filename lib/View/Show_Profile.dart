import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Model/student_model.dart';
import 'update_profile_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  final String studentEmail;

  const StudentProfileScreen({super.key, required this.studentEmail});

  Future<StudentModel?> fetchStudent() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("Students")
        .where("email", isEqualTo: studentEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return StudentModel.fromSnapshot(doc.id, doc.data());
    }
    return null;
  }

  Future<void> deleteStudent(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection("Students").doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student deleted")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),
      body: FutureBuilder<StudentModel?>(
        future: fetchStudent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final student = snapshot.data;

          if (student == null) {
            return const Center(child: Text("Student not found"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${student.name}", style: const TextStyle(fontSize: 18)),
                Text("Email: ${student.email}", style: const TextStyle(fontSize: 18)),
                Text("Enrollment: ${student.enrollment}", style: const TextStyle(fontSize: 18)),
                Text("Course: ${student.course}", style: const TextStyle(fontSize: 18)),
                Text("Semester: ${student.semester}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Update"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateProfileScreen(student: student),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => deleteStudent(context, student.id),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
