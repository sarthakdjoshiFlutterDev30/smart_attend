import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
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
      appBar: AppBar(
        title: const Text("Add Student"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                try {
                  XFile? pickedImage = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedImage != null) {
                    int imageSize = await pickedImage.length();
                    if (imageSize > 50 * 1024) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Image must be below 50 KB"),
                        ),
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
                  }
                } catch (e) {
                  print("Image Picker Error: $e");
                }
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: kIsWeb
                    ? (selectedImage != null
                          ? NetworkImage(selectedImage!.path)
                          : null)
                    : (profilepic != null ? FileImage(profilepic!) : null)
                          as ImageProvider<Object>?,
                child: selectedImage == null && profilepic == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(name, "Name", Icons.person),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Course",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
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
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Semester",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
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
            const SizedBox(height: 10),

            _buildTextField(
              enrollment,
              "Enrollment No.",
              Icons.confirmation_num,
            ),
            const SizedBox(height: 10),

            _buildTextField(email, "Email", Icons.email),
            const SizedBox(height: 10),

            TextField(
              controller: password,
              obscureText: _isshow,
              obscuringCharacter: "*",
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: TextButton(
                  onPressed: () {
                    setState(() {
                      _isshow = !_isshow;
                    });
                  },
                  child: Text(_isshow ? "Show" : "Hide"),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 20),

            _isloading
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _addStudent();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        "Add Student",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Future<void> _addStudent() async {
    if (name.text.trim().isEmpty ||
        enrollment.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        selectedCourse == null ||
        selectedSemester == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All Fields are Required")));
      return;
    }

    setState(() {
      _isloading = false;
    });

    try {
      String photoUrl = "";

      if (kIsWeb && selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        if (bytes.length > 50 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image must be below 50 KB")),
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
            const SnackBar(content: Text("Image must be below 50 KB")),
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

      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

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
            "photourl": photoUrl,
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Student Added")));

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add student")));
      setState(() {
        _isloading = true;
      });
    }
  }
}
