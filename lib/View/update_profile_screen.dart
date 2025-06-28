import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../Model/student_model.dart';

class UpdateProfileScreen extends StatefulWidget {
  final StudentModel student;

  const UpdateProfileScreen({super.key, required this.student});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController enrollmentController;
  String? selectedCourse;
  String? selectedSemester;
  bool _isLoading = true;
  File? profilepic;
  XFile? selectedImage;

  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student.name);
    enrollmentController = TextEditingController(
      text: widget.student.enrollment,
    );
    selectedCourse = widget.student.course;
    selectedSemester = widget.student.semester;
  }

  Future<void> updateStudent() async {
    setState(() {
      _isLoading = false;
    });

    String photourl = widget.student.photourl ?? "";

    try {
      // Upload new image if selected
      if ((kIsWeb && selectedImage != null) ||
          (!kIsWeb && profilepic != null)) {
        final String filename = const Uuid().v4();
        final ref = FirebaseStorage.instance.ref().child(
          'student_profiles/$filename',
        );

        UploadTask uploadTask;
        if (kIsWeb && selectedImage != null) {
          final bytes = await selectedImage!.readAsBytes();
          if (bytes.length > 50 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Image must be below 50 KB")),
            );
            setState(() => _isLoading = true);
            return;
          }
          uploadTask = ref.putData(bytes);
        } else {
          final fileSize = await profilepic!.length();
          if (fileSize > 50 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Image must be below 50 KB")),
            );
            setState(() => _isLoading = true);
            return;
          }
          uploadTask = ref.putFile(profilepic!);
        }

        final snapshot = await uploadTask;
        photourl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection("Students")
          .doc(widget.student.id)
          .update({
            'name': nameController.text.trim(),
            'enrollment': enrollmentController.text.trim(),
            'course': selectedCourse,
            'semester': selectedSemester,
            'photourl': photourl,
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      setState(() {
        _isLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Profile"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                try {
                  XFile? pickedImage = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
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
                          : (widget.student.photourl != null
                                ? NetworkImage(widget.student.photourl!)
                                : null))
                    : (profilepic != null
                          ? FileImage(profilepic!)
                          : (widget.student.photourl != null
                                ? NetworkImage(widget.student.photourl!)
                                      as ImageProvider
                                : null)),
                child:
                    kIsWeb && selectedImage == null ||
                        !kIsWeb && profilepic == null
                    ? Icon(Icons.add_a_photo, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: enrollmentController,
              decoration: const InputDecoration(labelText: "Enrollment"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select Course"),
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
              decoration: const InputDecoration(labelText: "Select Semester"),
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
            const SizedBox(height: 20),
            (_isLoading)
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text("Update"),
                    onPressed: updateStudent,
                  )
                : CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
