import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:smart_attend/View/AttendanceSummaryScreen.dart';

import '../Model/student_model.dart';
import 'update_profile_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<StudentModel>> fetchAllStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection("Students").get();
    return snapshot.docs.map((doc) => StudentModel.fromSnapshot(doc.id, doc.data())).toList();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Delete $name?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("Students").doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student deleted")));
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToCSVWeb(List<QueryDocumentSnapshot> docs, String fileName) async {
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
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Report"),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.05),
              Colors.purple.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: "Search by name or enrollment",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text("Export CSV"),
                                    content: const Text("Choose course to export"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      FilledButton(
                                        onPressed: () async {
                                          final docs = await FirebaseFirestore.instance.collection("Students").get().then((s) => s.docs);
                                          final filtered = docs.where((d) {
                                            final data = d.data() as Map<String, dynamic>;
                                            return (data['course'] ?? '').toString().toUpperCase() == 'BCA';
                                          }).toList();
                                          if (filtered.isEmpty) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No BCA students to export")));
                                            }
                                          } else {
                                            await exportToCSVWeb(filtered, "Students_BCA.csv");
                                          }
                                          if (mounted) Navigator.pop(context);
                                        },
                                        child: const Text("BCA"),
                                      ),
                                      FilledButton(
                                        onPressed: () async {
                                          final docs = await FirebaseFirestore.instance.collection("Students").get().then((s) => s.docs);
                                          final filtered = docs.where((d) {
                                            final data = d.data() as Map<String, dynamic>;
                                            return (data['course'] ?? '').toString().toUpperCase() == 'MCA';
                                          }).toList();
                                          if (filtered.isEmpty) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No MCA students to export")));
                                            }
                                          } else {
                                            await exportToCSVWeb(filtered, "Students_MCA.csv");
                                          }
                                          if (mounted) Navigator.pop(context);
                                        },
                                        child: const Text("MCA"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text("Export CSV"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FutureBuilder<List<StudentModel>>(
                        future: fetchAllStudents(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("No students found"));
                          }
                          List<StudentModel> students = snapshot.data!;
                          if (_searchQuery.isNotEmpty) {
                            students = students.where((s) {
                              final name = (s.name).toLowerCase();
                              final enr = (s.enrollment ?? '').toLowerCase();
                              return name.contains(_searchQuery) || enr.contains(_searchQuery);
                            }).toList();
                          }
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.people_alt, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Total: ${students.length}",
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: students.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final student = students[index];
                                    return Material(
                                      color: Theme.of(context).colorScheme.surface,
                                      elevation: 1.5,
                                      borderRadius: BorderRadius.circular(12),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        leading: CircleAvatar(
                                          radius: 26,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage: (student.photourl != null && student.photourl!.isNotEmpty)
                                              ? NetworkImage(student.photourl!)
                                              : null,
                                          child: (student.photourl == null || student.photourl!.isEmpty)
                                              ? const Icon(Icons.person, size: 24)
                                              : null,
                                        ),
                                        title: Text(
                                          student.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              Chip(
                                                avatar: const Icon(Icons.badge, size: 16),
                                                label: Text(student.enrollment ?? 'N/A'),
                                                visualDensity: VisualDensity.compact,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              Chip(
                                                avatar: const Icon(Icons.school, size: 16),
                                                label: Text(student.course),
                                                visualDensity: VisualDensity.compact,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              Chip(
                                                avatar: const Icon(Icons.calendar_month, size: 16),
                                                label: Text("Sem ${student.semester}"),
                                                visualDensity: VisualDensity.compact,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: Wrap(
                                          spacing: 4,
                                          children: [
                                            IconButton(
                                              tooltip: "Edit",
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => UpdateProfileScreen(student: student),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              tooltip: "Attendance Summary",
                                              icon: const Icon(Icons.insert_chart_outlined, color: Colors.teal),
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AttendanceSummaryScreen(
                                                      enrollmentNo: student.enrollment,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              tooltip: "Delete",
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () async {
                                                await deleteStudent(context, student.id, student.name);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
