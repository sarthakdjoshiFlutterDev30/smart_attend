import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Model/student_model.dart';
import 'update_profile_screen.dart';

class ShowAllStudent extends StatelessWidget {
  const ShowAllStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Show All Students")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(doc.name ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${doc.email ?? 'No Email'}"),
                      Text("Enrollment: ${doc.enrollment ?? 'No Enrollment'}"),
                      Text("Course: ${doc.course ?? 'No Course'}"),
                      Text("Semester: ${doc.semester ?? 'No Semester'}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Use min to avoid overflow
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpdateProfileScreen(student: doc),
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
    );
  }
}
