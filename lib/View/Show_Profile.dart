import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import '../Model/student_model.dart';
import 'update_profile_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<List<StudentModel>> fetchAllStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("Students")
        .get();

    return snapshot.docs
        .map((doc) => StudentModel.fromSnapshot(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteStudent(
    BuildContext context,
    String docId,
    String name,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Are You Sure To delete $name"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("Students")
                    .doc(docId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student deleted")),
                );
                Navigator.pop(context);
              },
              child: Text("Sure"),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToCSVWeb(List<QueryDocumentSnapshot> docs) async {
    List<List<String>> data = [
      ['Name', 'EnrollmentNo', 'Course', 'Semester', 'Password'],
      ...docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return [
          d['name'] ?? '',
          d['enrollment'] ?? '',
          d['course'] ?? '',
          d['semester'] ?? '',
          d['password'] ?? '',
        ];
      }),
    ];

    final csvData = const ListToCsvConverter().convert(data);

    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "AllStudent.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Students"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<StudentModel>>(
              future: fetchAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No students found"));
                }

                final students = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: students.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            student.photourl != null &&
                                student.photourl!.isNotEmpty
                            ? NetworkImage(student.photourl!)
                            : null,
                        child:
                            student.photourl == null ||
                                student.photourl!.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(student.name),
                      subtitle: Text(student.email),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'Edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UpdateProfileScreen(student: student),
                              ),
                            );
                          } else if (value == 'Delete') {
                            await deleteStudent(
                              context,
                              student.id,
                              student.name,
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'Edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Delete',
                                child: Text('Delete'),
                              ),
                            ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("Export CSV"),
            onPressed: () async {
              await exportToCSVWeb(
                await FirebaseFirestore.instance
                    .collection("Students")
                    .get()
                    .then((snapshot) => snapshot.docs),
              );
            },
          ),
        ],
      ),
    );
  }
}
