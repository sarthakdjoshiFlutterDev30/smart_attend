import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final String enrollmentNo;
  const AttendanceSummaryScreen({super.key, required this.enrollmentNo});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  Map<String, int> totalLectures = {};
  Map<String, int> attendedLectures = {};
  bool _isLoading = true;
  double overallPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final sessionSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .get();

      Map<String, Set<String>> uniqueLectures = {};
      Map<String, int> tempAttended = {};

      for (var session in sessionSnapshot.docs) {
        final data = session.data();
        String subject = (data['lecName'] ?? 'Unknown').toString().trim();
        String lecNo = (data['lecNo'] ?? session.id).toString();

        uniqueLectures.putIfAbsent(subject, () => {});
        uniqueLectures[subject]!.add(lecNo);
        final attendeeSnapshot = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(session.id)
            .collection('attendees')
            .where('enrollmentNo', isEqualTo: widget.enrollmentNo)
            .get();

        if (attendeeSnapshot.docs.isNotEmpty) {
          tempAttended[subject] = (tempAttended[subject] ?? 0) + 1;
        }
      }

      Map<String, int> tempTotal = {};
      uniqueLectures.forEach((subject, lecSet) {
        tempTotal[subject] = lecSet.length;
      });

      int totalAllLectures = tempTotal.values.fold(0, (sum, val) => sum + val);
      int totalAttended = tempAttended.values.fold(0, (sum, val) => sum + val);
      double overall = totalAllLectures == 0
          ? 0
          : (totalAttended / totalAllLectures) * 100;

      setState(() {
        totalLectures = tempTotal;
        attendedLectures = tempAttended;
        overallPercentage = overall;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching attendance: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Summary"),
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : totalLectures.isEmpty
                      ? const Center(
                          child: Text(
                            "No attendance data available",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Column(
                          children: [
                            // Header card with overall percentage and student id
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Circular indicator
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: CircularProgressIndicator(
                                            value: (overallPercentage.clamp(0, 100)) / 100,
                                            strokeWidth: 8,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              overallPercentage >= 75 ? Colors.green : Colors.red,
                                            ),
                                            backgroundColor: scheme.surfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          "${overallPercentage.toStringAsFixed(0)}%",
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Enrollment: ${widget.enrollmentNo}",
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _legendDot(color: Colors.green),
                                              const SizedBox(width: 6),
                                              const Text(">= 75% Good"),
                                              const SizedBox(width: 16),
                                              _legendDot(color: Colors.red),
                                              const SizedBox(width: 6),
                                              const Text("< 75% Low"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Subject-wise Attendance",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView(
                                children: totalLectures.keys.map((subject) {
                                  final total = totalLectures[subject] ?? 0;
                                  final attended = attendedLectures[subject] ?? 0;
                                  final percentage = total == 0 ? 0.0 : (attended / total) * 100.0;
                                  final isGood = percentage >= 75.0;
                                  return Card(
                                    elevation: 1.5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: isGood ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  isGood ? Icons.check_circle : Icons.menu_book,
                                                  size: 20,
                                                  color: isGood ? Colors.green : Colors.red,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  subject,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                "${percentage.toStringAsFixed(1)}%",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isGood ? Colors.green : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Attended: $attended"),
                                              Text("Total: $total"),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: total == 0 ? 0 : attended / total,
                                              minHeight: 10,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isGood ? Colors.green : Colors.red,
                                              ),
                                              backgroundColor: scheme.surfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
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

  Widget _legendDot({required Color color}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
