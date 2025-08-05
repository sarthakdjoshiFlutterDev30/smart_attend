import 'package:flutter/material.dart';
import 'package:smart_attend/Controller/ApiService.dart';
import 'package:smart_attend/View/Add_Student.dart';
import 'package:smart_attend/View/Show%20All%20Student.dart';
import 'package:smart_attend/View/Show_Profile.dart';

import 'attendance_list_screen.dart';
import 'create_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final api = ApiService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_DashboardItem> items = [
      _DashboardItem(
        icon: Icons.add_box_rounded,
        label: "Create New Session",
        onTap: () => _navigateTo(context, const CreateSessionScreen()),
      ),
      _DashboardItem(
        icon: Icons.fact_check,
        label: "View Attendance",
        onTap: () => _navigateTo(context, const AttendanceListScreen()),
      ),
      _DashboardItem(
        icon: Icons.person_add_alt_1,
        label: "Add Student",
        onTap: () => _navigateTo(context, const Add_Student()),
      ),
      _DashboardItem(
        icon: Icons.people,
        label: "Show Students",
        onTap: () => _navigateTo(context, const ShowAllStudent()),
      ),
      _DashboardItem(
        icon: Icons.notifications_active,
        label: "Send Notification",
        onTap: _showNotificationDialog,
      ),
      _DashboardItem(
        icon: Icons.assignment_ind,
        label: "Student Report",
        onTap: () => _navigateTo(context, const StudentProfileScreen()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Container(
          key: ValueKey(isDark),
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0F7FA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  return _buildAnimatedCard(items[index], isDark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(_DashboardItem item, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
        ],
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 36, color: Colors.deepPurple),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Send Notification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: "Body"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.clear();
              bodyController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All fields are required")),
                );
                return;
              }
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              await api.sendNotification(title, body);
              titleController.clear();
              bodyController.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notification sent")),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _DashboardItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
