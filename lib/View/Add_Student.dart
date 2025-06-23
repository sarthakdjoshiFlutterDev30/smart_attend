import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

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

  File? profilepic; // for mobile
  XFile? selectedImage; // for web

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
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  try {
                    XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedImage != null) {
                      int imageSize = await pickedImage.length();
                      if (imageSize > 50 * 1024) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Image must be below 50 KB")),
                        );
                        return;
                      }

                      setState(() {
                        if (kIsWeb) {
                          selectedImage = pickedImage;
                        } else {
                          profilepic = File(pickedImage.path);
                        }
                      });
                    } else {
                      print("No Image Selected");
                    }
                  } catch (e) {
                    print("Image Picker Error: $e");
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 40,
                  backgroundImage: kIsWeb
                      ? (selectedImage != null
                      ? NetworkImage(selectedImage!.path)
                      : null)
                      : (profilepic != null
                      ? FileImage(profilepic!)
                      : null) as ImageProvider<Object>?,
                  child: kIsWeb && selectedImage == null || !kIsWeb && profilepic == null
                      ? Icon(Icons.add_a_photo, color: Colors.black)
                      : null,
                ),
              ),
              SizedBox(height: 10),

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
                    selectedSemester = null;
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
              SizedBox(height: 20),

              (_isloading)
                  ? ElevatedButton(
                  onPressed: () async {
                    if (name.text
                        .trim()
                        .isEmpty ||
                        enrollment.text
                            .trim()
                            .isEmpty ||
                        email.text
                            .trim()
                            .isEmpty ||
                        password.text
                            .trim()
                            .isEmpty ||
                        selectedCourse == null ||
                        selectedSemester == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("All Fields are Required")),
                      );
                    } else {
                      setState(() {
                        _isloading = false;
                      });

                      try {
                        String photoUrl = "";

                        // Upload image if exists
                        if (kIsWeb && selectedImage != null) {
                          final bytes = await selectedImage!.readAsBytes();
                          if (bytes.length > 50 * 1024) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Image must be below 50 KB")),
                            );
                            setState(() => _isloading = true);
                            return;
                          }

                          final ref = FirebaseStorage.instance
                              .ref()
                              .child("Stud-profilepic")
                              .child(const Uuid().v1());
                          final uploadTask = await ref.putData(bytes);
                          photoUrl = await uploadTask.ref.getDownloadURL();
                        } else if (!kIsWeb && profilepic != null) {
                          final fileSize = await profilepic!.length();
                          if (fileSize > 50 * 1024) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(
                                  "Image must be below 50 KB")),
                            );
                            setState(() => _isloading = true);
                            return;
                          }

                          final ref = FirebaseStorage.instance
                              .ref()
                              .child("Stud-profilepic")
                              .child(const Uuid().v1());
                          final uploadTask = await ref.putFile(profilepic!);
                          photoUrl = await uploadTask.ref.getDownloadURL();
                        }

                        // Firebase Auth
                        UserCredential user = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: email.text.trim(),
                          password: password.text.trim(),
                        );

                        // Firestore insert
                        await FirebaseFirestore.instance
                            .collection("Students")
                            .doc(user.user?.uid)
                            .set({
                          "name": name.text.trim(),
                          "email": email.text.trim(),
                          "password": password.text.trim(),
                          "enrollment": enrollment.text.trim(),
                          "course": selectedCourse!,
                          "semester": selectedSemester!,
                          "createdAt": Timestamp.now(),
                          "photourl": photoUrl
                        });

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
                          profilepic = null;
                          selectedImage = null;
                          _isloading = true;
                        });
                      } catch (e) {
                        print("Error adding student: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add student")),
                        );
                        setState(() {
                          _isloading = true;
                        });
                      }
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
