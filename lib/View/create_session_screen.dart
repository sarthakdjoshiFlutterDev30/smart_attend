import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateSessionScreen extends StatefulWidget {
  final String Name;
  const CreateSessionScreen({super.key, required this.Name});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {

  String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String locationMessage = "";

  double lat = 0.0;
  double log = 0.0;

  Map<String, bool> switchStates = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocationForWeb();
  }

  // ================= GET LOCATION FOR WEB =================
  Future<void> _getCurrentLocationForWeb() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        locationMessage = "Location disabled on browser";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = "Location permanently denied";
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best
      );

      setState(() {
        lat = position.latitude;
        log = position.longitude;
        locationMessage = "Latitude: $lat , Longitude: $log";
      });

      print("Teacher Web Location => $locationMessage");

    } catch (e) {
      print("Location error: $e");

      // Fallback if browser blocks GPS
      setState(() {
        lat = 0.0 + Random().nextDouble();
        log = 0.0 + Random().nextDouble();
      });
    }
  }

  // ================= SHOW QR =================
  void showQRCode(String docId, String Name, String course, String semester) {
    int secondsLeft = 10;
    Timer? timer;

    FirebaseFirestore.instance
        .collection("notification")
        .doc(docId)
        .set({
      'docId': docId,
      'lat': lat,
      'log': log,
      'course': course,
      'semester': semester,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {

          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (secondsLeft > 1) {
              setState(() {
                secondsLeft--;
              });
            } else {
              t.cancel();
              Navigator.pop(context);
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.grey[900],
            title: Column(
              children: [
                Text(
                  "Lec Name = $Name",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Lec ID : $docId",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 260,
              height: 280,
              child: Column(
                children: [
                  QrImageView(
                    data: docId,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Expires in $secondsLeft seconds",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  timer?.cancel();

                  if (mounted) {
                    this.setState(() {
                      switchStates[docId] = false;
                    });
                  }

                  await FirebaseFirestore.instance
                      .collection("sessions")
                      .doc(docId)
                      .update({'isActive': false});

                  await FirebaseFirestore.instance
                      .collection("notification")
                      .doc(docId)
                      .delete();

                  Navigator.pop(context);
                },
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) async {

      if (mounted) {
        this.setState(() {
          switchStates[docId] = false;
        });
      }

      await FirebaseFirestore.instance
          .collection("sessions")
          .doc(docId)
          .update({'isActive': false});

      await FirebaseFirestore.instance
          .collection("notification")
          .doc(docId)
          .delete();

      timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkGrey = Colors.grey[900];
    final cardGrey = Colors.grey[850];

    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        elevation: 0,
        title: const Text("Create Session",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.white12,
      ),
      body: Column(
        children: [
          // ---------------- HEADER ----------------
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade400
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.Name} 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Today : $todayDate",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- SESSION LIST ----------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .orderBy('lecNo')
                    .snapshots(),

                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  final todaySessions = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['lecDate'] == todayDate;
                  }).toList();

                  if (todaySessions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "No Sessions For Today",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: todaySessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {

                      final doc = todaySessions[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;

                      return Container(
                        decoration: BoxDecoration(
                          color: cardGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor:
                            Colors.deepPurple.withOpacity(0.2),
                            child: const Icon(Icons.book,
                                color: Colors.deepPurple),
                          ),
                          title: Text(
                            data['lecName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            "Lecture No: ${data['lecNo']}",
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70
                            ),
                          ),

                          trailing: Switch(
                            value: switchStates[docId] ?? false,
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,

                            onChanged: (value) async {

                              setState(() {
                                switchStates[docId] = value;
                              });

                              if (value == true) {

                                await FirebaseFirestore.instance
                                    .collection("sessions")
                                    .doc(docId)
                                    .update({
                                  'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
                                  'lat': lat,
                                  'log': log,
                                  'isActive': true
                                });

                                showQRCode(
                                  docId,
                                  data['lecName'] ?? '',
                                  data['course'] ?? '',
                                  data['semester'] ?? '',
                                );

                              } else {
                                await FirebaseFirestore.instance
                                    .collection("sessions")
                                    .doc(docId)
                                    .update({'isActive': false});
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}
