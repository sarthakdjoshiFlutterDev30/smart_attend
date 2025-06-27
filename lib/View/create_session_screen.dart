import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_attend/View/Home.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  String? sessionId;
  Timer? _timer;
  int _count = 10;
  String? selectedCourse;
  String? selectedSemester;
  String? selectedSubjectType;
  Map<String, String>? selectedSubject;
  String fileName = "";

  final Map<String, Map<String, List<Map<String, String>>>> courseDetails = {
    'MCA': {
      '1': [
        {
          'type': 'Regular',
          'name': 'Programming Fundamentals',
          'code': 'MCA101',
        },
        {'type': 'Regular', 'name': 'Computer Organization', 'code': 'MCA102'},
        {'type': 'Elective', 'name': 'Communication Skills', 'code': 'MCAE101'},
      ],
      '2': [
        {'type': 'Regular', 'name': 'Data Structures', 'code': 'MCA201'},
        {'type': 'Regular', 'name': 'DBMS', 'code': 'MCA202'},
        {'type': 'Elective', 'name': 'Mathematics for CS', 'code': 'MCAE201'},
      ],
    },
    'BCA': {
      '1': [
        {'type': 'Regular', 'name': 'Basics of IT', 'code': 'BCA101'},
        {'type': 'Regular', 'name': 'Mathematics I', 'code': 'BCA102'},
        {
          'type': 'Elective',
          'name': 'Environmental Science',
          'code': 'BCAE101',
        },
      ],
      '2': [
        {'type': 'Regular', 'name': 'C Programming', 'code': 'BCA201'},
        {'type': 'Regular', 'name': 'Digital Electronics', 'code': 'BCA202'},
        {'type': 'Elective', 'name': 'Soft Skills', 'code': 'BCAE201'},
      ],
    },
  };

  List<String> get semesters {
    if (selectedCourse == null) return [];
    return courseDetails[selectedCourse!]!.keys.toList();
  }

  List<String> get subjectTypes {
    if (selectedCourse == null || selectedSemester == null) return [];
    final subjects = courseDetails[selectedCourse!]![selectedSemester!]!;
    // Extract distinct types
    return subjects.map((s) => s['type']!).toSet().toList();
  }

  List<Map<String, String>> get subjectsByType {
    if (selectedCourse == null ||
        selectedSemester == null ||
        selectedSubjectType == null) {
      return [];
    }
    final subjects = courseDetails[selectedCourse!]![selectedSemester!]!;
    return subjects.where((s) => s['type'] == selectedSubjectType).toList();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count > 0) {
        setState(() {
          _count--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> createSession() async {
    if (selectedCourse == null ||
        selectedSemester == null ||
        selectedSubjectType == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select all fields")));
      return;
    }
    startCountdown();
    DocumentReference ref = await FirebaseFirestore.instance
        .collection('sessions')
        .add({
          'name': fileName,
          'createdAt': DateFormat('ddMMyyyy').format(DateTime.now()),
          'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
        });

    setState(() {
      sessionId = ref.id;
    });

    _timer = Timer(Duration(seconds: 10), () {
      setState(() {
        sessionId = null;
        selectedCourse = null;
        selectedSemester = null;
        selectedSubjectType = null;
        selectedSubject = null;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(),));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Session")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Course Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Course'),
                value: selectedCourse,
                items: courseDetails.keys
                    .map(
                      (course) =>
                          DropdownMenuItem(value: course, child: Text(course)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCourse = value;
                    selectedSemester = null;
                    selectedSubjectType = null;
                    selectedSubject = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Semester Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Semester'),
                value: selectedSemester,
                items: semesters
                    .map(
                      (sem) => DropdownMenuItem(value: sem, child: Text(sem)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSemester = value;
                    selectedSubjectType = null;
                    selectedSubject = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Subject Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Subject Type',
                ),
                value: selectedSubjectType,
                items: subjectTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubjectType = value;
                    selectedSubject = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Subject Dropdown (name + code)
              DropdownButtonFormField<Map<String, String>>(
                decoration: const InputDecoration(labelText: 'Select Subject'),
                value: selectedSubject,
                items: subjectsByType
                    .map(
                      (subj) => DropdownMenuItem(
                        value: subj,
                        child: Text('${subj['name']} (${subj['code']})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubject = value;
                    fileName =
                        "${selectedSubject!['name']}(${selectedSubject!['code']})";
                    print(fileName);
                  });
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: createSession,
                child: const Text("Generate QR Code"),
              ),
              const SizedBox(height: 30),
              if (sessionId != null)
                Column(
                  children: [
                    const Text("Scan this QR to mark attendance:"),
                    const SizedBox(height: 20),
                    QrImageView(data: sessionId!, size: 250),
                    Text(
                      '$_count',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
