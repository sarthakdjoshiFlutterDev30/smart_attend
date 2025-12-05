import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  String? selectedSessionId;
  String? selectedSessionName;
  final todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());


  Future<void> exportToCSVWeb(List<QueryDocumentSnapshot> docs) async {
    List<List<String>> data = [
      ['Name', 'EnrollmentNo', 'Course', 'Semester', 'Date', 'Time'],
      ...docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return [
          d['name'] ?? '',
          d['enrollmentNo'] ?? '',
          d['course'] ?? '',
          d['semester'] ?? '',
          d['timestamp'] ?? '',
          d['time'] ?? '',
        ];
      }),
    ];

    final csvData = const ListToCsvConverter().convert(data);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$selectedSessionName $todayDate-attendance.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Attendance Reports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('lecDate', isEqualTo: date)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final allSessions = snapshot.data!.docs;
                final seenNames = <String>{};
                final uniqueSessions = allSessions.where((doc) {
                  final name =
                      (doc.data() as Map<String, dynamic>)['lecName']
                          ?.toString()
                          .trim()
                          .toLowerCase() ??
                          '';
                  if (seenNames.contains(name)) return false;
                  seenNames.add(name);
                  return true;
                }).toList();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade700),
                    color: Colors.grey.shade900,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: Colors.grey.shade900,
                      value: selectedSessionId,
                      hint: const Text(
                        "Select Session",
                        style: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (value) {
                        final session = uniqueSessions.firstWhere(
                              (s) => s.id == value,
                        );
                        final sessionData =
                        session.data() as Map<String, dynamic>;
                        setState(() {
                          selectedSessionId = value;
                          selectedSessionName =
                              sessionData['lecName'] ?? 'session';
                        });
                      },
                      items: uniqueSessions.map((session) {
                        return DropdownMenuItem(
                          value: session.id,
                          child: Text(
                            (session.data() as Map)['lecName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            if (selectedSessionId != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(selectedSessionId)
                      .collection('attendees')
                      .orderBy('enrollmentNo', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final attendees = snapshot.data!.docs;

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: attendees.length,
                            itemBuilder: (context, index) {
                              final data =
                              attendees[index].data() as Map<String, dynamic>;
                              return Card(
                                color: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 6,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade400,
                                    child: Text(
                                      data['name']
                                          ?.toString()
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                          '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    data['name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "EnrollmentNo: ${data['enrollmentNo'] ?? 'N/A'}\nCourse: ${data['course'] ?? 'N/A'} | Sem: ${data['semester'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Text(
                                    ('${data['timestamp']}-${data['time']}')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text("Export CSV"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: Colors.blue.shade700,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: 6,
                              shadowColor: Colors.blue.shade300,
                            ),
                            onPressed: () async {
                              await exportToCSVWeb(attendees);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
