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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Select Course",
                                    prefixIcon: const Icon(Icons.school),
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Select Semester",
                                    prefixIcon: const Icon(Icons.calendar_month),
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
                          TextField(
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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

                            if (_searchQuery.isNotEmpty) {
                              students = students.where((s) {
                                final name = (s.name ?? '').toLowerCase();
                                final enr = (s.enrollment ?? '').toLowerCase();
                                return name.contains(_searchQuery) || enr.contains(_searchQuery);
                              }).toList();
                            }

                            if (students.isEmpty) {
                              return const Center(child: Text("No matches for your search."));
                            }

                            return ListView.separated(
                              itemCount: students.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final doc = students[index];
                                return Material(
                                  color: Theme.of(context).colorScheme.surface,
                                  elevation: 1.5,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 16,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 26,
                                      backgroundImage: NetworkImage(doc.photourl ?? ""),
                                      backgroundColor: Colors.grey.shade200,
                                    ),
                                    title: Text(
                                      doc.name ?? 'No Name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Chip(
                                            avatar: const Icon(Icons.badge, size: 16),
                                            label: Text(doc.enrollment ?? 'N/A'),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Chip(
                                            avatar: const Icon(Icons.school, size: 16),
                                            label: Text(doc.course ?? 'N/A'),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Chip(
                                            avatar: const Icon(Icons.calendar_today, size: 16),
                                            label: Text("Sem ${doc.semester ?? 'N/A'}"),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: "Edit",
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
                                          tooltip: "Delete",
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
