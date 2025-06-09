import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Add_Student extends StatefulWidget {
  const Add_Student({super.key});

  @override
  State<Add_Student> createState() => _Add_StudentState();
}

class _Add_StudentState extends State<Add_Student> {
  var email = TextEditingController();
  var password = TextEditingController();
  var name = TextEditingController();
  var enrollment = TextEditingController();

  bool _isshow = true;
  bool _isloading = true;

  String? selectedCourse;
  String? selectedSemester;

  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Student")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: "Name"),
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
                    selectedSemester =
                        null; // reset semester when course changes
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
              SizedBox(height: 10),
              TextField(
                controller: enrollment,
                decoration: InputDecoration(labelText: "Enrollment No."),
              ),
              SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: "Email"),
              ),
              SizedBox(height: 10),
              TextField(
                obscureText: _isshow,
                obscuringCharacter: "*",
                controller: password,
                decoration: InputDecoration(
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        _isshow = !_isshow;
                      });
                    },
                    child: Text((_isshow) ? "Show" : "Hide"),
                  ),
                  labelText: "Password",
                ),
              ),
              SizedBox(height: 10),
              (_isloading)
                  ? ElevatedButton(
                      onPressed: () async {
                        if (name.text.trim().isEmpty ||
                            enrollment.text.trim().isEmpty ||
                            email.text.trim().isEmpty ||
                            password.text.trim().isEmpty ||
                            selectedCourse == null ||
                            selectedSemester == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("All Fields are Required")),
                          );
                        } else {
                          setState(() {
                            _isloading = false;
                          });
                          UserCredential user = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                email: email.text.trim(),
                                password: password.text.trim(),
                              );
                          FirebaseFirestore.instance
                              .collection("Students")
                              .doc(user.user?.uid)
                              .set({
                                "name": name.text.trim(),
                                "email": email.text.trim(),
                                "password": password.text.trim(),
                                "enrollment": enrollment.text.trim(),
                                "course": selectedCourse!,
                                "semester": selectedSemester!,
                              })
                              .then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Student Added")),
                                );
                                email.clear();
                                password.clear();
                                name.clear();
                                enrollment.clear();
                                setState(() {
                                  selectedCourse = null;
                                  selectedSemester = null;
                                  _isloading = true;
                                });
                              });
                        }
                      },
                      child: Text("Add Student"),
                    )
                  : CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
