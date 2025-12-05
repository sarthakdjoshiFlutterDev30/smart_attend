import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attend/View/Add_Student.dart';
import 'package:smart_attend/View/Show%20All%20Student.dart';
import 'package:smart_attend/View/Show%20All%20Teacher.dart';
import 'package:smart_attend/View/Show_Profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'attendance_list_screen.dart';
import 'create_session_screen.dart';
import 'Login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final List<_DashboardItem> items = [
      _DashboardItem(
        icon: Icons.add_box_rounded,
        label: "Create New Session",
        onTap: () => _navigateTo(context, const CreateSessionScreen(Name: "Principal",)),
      ),
      _DashboardItem(
        icon: Icons.fact_check,
        label: "View Attendance",
        onTap: () => _navigateTo(context, const AttendanceListScreen()),
      ),
      _DashboardItem(
        icon: Icons.person_add_alt_1,
        label: "Add User",
        onTap: () => _navigateTo(context, const AddStudent()),
      ),
      _DashboardItem(
        icon: Icons.people,
        label: "Show Students",
        onTap: () => _navigateTo(context, const ShowAllStudent()),
      ),
      _DashboardItem(
        icon: Icons.school,
        label: "Show Teachers",
        onTap: () => _navigateTo(context, const ShowAllTeacher()),
      ),
      _DashboardItem(
        icon: Icons.assignment_ind,
        label: "Student Report",
        onTap: () => _navigateTo(context, const StudentProfileScreen()),
      ),
    ];

    final todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Container(
          key: ValueKey(isDark),
          child: LayoutBuilder(builder: (context, constraints) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SimpleWelcomeHeader(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        return _buildAnimatedCard(items[index], isDark, scheme, theme);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event_available, color: scheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Today’s Sessions",
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Text(
                                  todayDate,
                                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('sessions')
                                  .where('lecDate', isEqualTo: todayDate)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(),
                                  ));
                                }
                                if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      "Unable to load today’s sessions.",
                                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      "No sessions scheduled today.",
                                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                  );
                                }
                                final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                                docs.sort((a, b) {
                                  final am = a.data() as Map<String, dynamic>;
                                  final bm = b.data() as Map<String, dynamic>;
                                  final asVal = (am['lecNo'] ?? '').toString();
                                  final bsVal = (bm['lecNo'] ?? '').toString();
                                  final ai = int.tryParse(asVal);
                                  final bi = int.tryParse(bsVal);
                                  if (ai != null && bi != null) {
                                    return ai.compareTo(bi);
                                  }
                                  return asVal.compareTo(bsVal);
                                });
                                return ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) => const Divider(height: 12),
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data() as Map<String, dynamic>;
                                    final lecName = (data['lecName'] ?? '').toString();
                                    final lecNo = (data['lecNo'] ?? '').toString();
                                    return Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: scheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            lecNo.isEmpty ? "-" : lecNo,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            lecName.isEmpty ? "Unnamed session" : lecName,
                                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(_DashboardItem item, bool isDark, ColorScheme scheme, ThemeData theme) {
    return Card(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 22, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _confirmLogout() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                if (!mounted) return;
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Login()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
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

class _SimpleWelcomeHeader extends StatelessWidget {
  const _SimpleWelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            scheme.secondaryContainer.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.handshake, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Have a productive day managing Smart Attendance.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize:16,
                    color: scheme.onSurfaceVariant,
                  ),
                
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
