import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:html' as html; // Add this at the top (only for Web)

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  String? selectedSessionId;
  String? selectedSessionName;



  Future<void> exportToCSVWeb(List<QueryDocumentSnapshot> docs) async {
    List<List<String>> data = [
      ['Name', 'EnrollmentNo','Course','Semester',
      'Date','Time'],
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
      })
    ];

    final csvData = const ListToCsvConverter().convert(data);

    // Create a blob and simulate anchor click for download
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$selectedSessionName-attendance.csv")
      ..click();
    html.Url.revokeObjectUrl(url);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Reports")),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final allSessions = snapshot.data!.docs;

              // ✅ Remove duplicates by session name
              final seenNames = <String>{};
              final uniqueSessions = allSessions.where((doc) {
                final name = (doc.data() as Map<String, dynamic>)['name']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                    '';
                if (seenNames.contains(name)) {
                  return false;
                } else {
                  seenNames.add(name);
                  return true;
                }
              }).toList();

              return DropdownButton<String>(
                value: selectedSessionId,
                hint: const Text("Select Session"),
                onChanged: (value) {
                  final session = uniqueSessions.firstWhere((s) => s.id == value);
                  final sessionData = session.data() as Map<String, dynamic>;
                  setState(() {
                    selectedSessionId = value;
                    selectedSessionName = sessionData['name'] ?? 'session';
                  });
                },
                items: uniqueSessions.map((session) {
                  return DropdownMenuItem(
                    value: session.id,
                    child: Text((session.data() as Map)['name']),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          if (selectedSessionId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .doc(selectedSessionId)
                  .collection('attendees')
                  .orderBy('enrollmentNo', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final attendees = snapshot.data!.docs;

                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: attendees.length,
                          itemBuilder: (context, index) {
                            final data = attendees[index].data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['name'] ?? 'N/A'),
                              subtitle: Text("EnrollmentNo: ${data['enrollmentNo'] ?? 'N/A'}"),
                              trailing: Text(('${data['timestamp']}-${data['time']}')
                                     .toString()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text("Export CSV"),
                        onPressed: () async {
                          await exportToCSVWeb(attendees);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
