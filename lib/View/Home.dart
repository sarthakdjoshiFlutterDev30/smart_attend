import 'package:flutter/material.dart';
import 'package:smart_attend/Controller/ApiService.dart';
import 'package:smart_attend/View/Add_Student.dart';
import 'package:smart_attend/View/Show%20All%20Student.dart';
import 'package:smart_attend/View/Show_Profile.dart';

import 'attendance_list_screen.dart';
import 'create_session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final api = ApiService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildButton(
                      context,
                      icon: Icons.add_box,
                      label: "Create New Session",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateSessionScreen(),
                          ),
                        );
                      },
                    ),

                    _buildButton(
                      context,
                      icon: Icons.fact_check,
                      label: "View Attendance Reports",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceListScreen(),
                          ),
                        );
                      },
                    ),

                    _buildButton(
                      context,
                      icon: Icons.person_add_alt,
                      label: "Add Student",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Add_Student(),
                          ),
                        );
                      },
                    ),

                    _buildButton(
                      context,
                      icon: Icons.people_alt,
                      label: "Show Students",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShowAllStudent(),
                          ),
                        );
                      },
                    ),

                    _buildButton(
                      context,
                      icon: Icons.notifications_active,
                      label: "Send Notification",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text("Notification Details"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: "Notification Title",
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: bodyController,
                                  decoration: const InputDecoration(
                                    labelText: "Notification Body",
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  titleController.clear();
                                  bodyController.clear();
                                },
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (titleController.text.isEmpty ||
                                      bodyController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Fields cannot be empty"),
                                      ),
                                    );
                                    return;
                                  }
                                  final title = titleController.text.trim();
                                  final body = bodyController.text.trim();
                                  titleController.clear();
                                  bodyController.clear();

                                  await api.sendNotification(title, body);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Notification Sent"),
                                    ),
                                  );
                                },
                                child: const Text("Send"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildButton(
                      context,
                      icon: Icons.credit_card,
                      label: "Show Student Report",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 4,
        ),
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: onTap,
      ),
    );
  }
}
