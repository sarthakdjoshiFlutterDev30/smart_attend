import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:smart_attend/View/AttendanceSummaryScreen.dart';

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
          title: Text("Are You Sure To delete $name?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
              child: const Text("Sure"),
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
      appBar: AppBar(
        title: const Text("All Students"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
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
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              student.photourl != null &&
                                  student.photourl!.isNotEmpty
                              ? NetworkImage(student.photourl!)
                              : null,
                          child:
                              student.photourl == null ||
                                  student.photourl!.isEmpty
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(student.email),
                            Text("Enrollment: ${student.enrollment}"),
                            Text("Course: ${student.course}"),
                            Text("Semester: ${student.semester}"),
                          ],
                        ),
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
                            } else if (value == 'Attendance Summary') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttendanceSummaryScreen(
                                    enrollmentNo: student.enrollment,
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'Edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'Delete',
                              child: Text('Delete'),
                            ),
                            PopupMenuItem(
                              value: 'Attendance Summary',
                              child: Text('Attendance Summary'),
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Export CSV", style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  await exportToCSVWeb(
                    await FirebaseFirestore.instance
                        .collection("Students")
                        .get()
                        .then((snapshot) => snapshot.docs),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
