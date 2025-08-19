import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  String fileName = "";
  List<Map<String, dynamic>> excelData = [];
  bool isUploading = false;
  String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  void pickAndReadExcelWeb() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.xlsx';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      if (file != null) {
        fileName = file.name;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((e) {
          final result = reader.result;
          late Uint8List uint8List;

          if (result is ByteBuffer) {
            uint8List = result.asUint8List();
          } else if (result is Uint8List) {
            uint8List = result;
          } else {
            return;
          }

          final excel = Excel.decodeBytes(uint8List);
          List<Map<String, dynamic>> extracted = [];

          for (var table in excel.tables.keys) {
            final rows = excel.tables[table]!.rows;
            for (int i = 1; i < rows.length; i++) {
              var row = rows[i];
              extracted.add({
                'lecNo': row[0]?.value.toString(),
                'lecName': row[1]?.value.toString(),
                'lecDate': row[2]?.value.toString(),
              });
            }
          }

          setState(() {
            excelData = extracted;
          });
        });
      }
    });
  }

  Future<void> uploadToFirestore() async {
    if (excelData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload an Excel file first")),
      );
      return;
    }

    setState(() => isUploading = true);

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var record in excelData) {
      DocumentReference ref = FirebaseFirestore.instance
          .collection('sessions')
          .doc();
      batch.set(ref, {
        'lecNo': record['lecNo'],
        'lecName': record['lecName'],
        'lecDate': DateFormat('dd-MM-yyyy').format(
          record['lecDate'] is DateTime
              ? record['lecDate']
              : DateTime.tryParse(record['lecDate'] ?? '') ?? DateTime.now(),
        ),
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
        'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await batch.commit();

    setState(() {
      isUploading = false;
      excelData.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Data uploaded successfully")));
  }

  void showQRCode(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("QR Code"),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(data: docId, size: 250),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Excel Upload & View")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndReadExcelWeb,
              child: const Text("Pick Excel File"),
            ),
            const SizedBox(height: 10),
            if (fileName.isNotEmpty) Text("Selected File: $fileName"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isUploading ? null : uploadToFirestore,
              child: isUploading
                  ? const CircularProgressIndicator()
                  : const Text("Upload to Firestore"),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              "Previously Uploaded Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .orderBy('lecNo')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No data found"));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      var docId = docs[index].id;

                      if (data['lecDate'] != todayDate) {
                        return const SizedBox.shrink(); // skips this item entirely
                      }

                      return ListTile(
                        title: Text(data['lecName'] ?? ''),
                        subtitle: Text("Lec No: ${data['lecNo']}"),
                        trailing: ElevatedButton(
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection("sessions")
                                .doc(docId)
                                .update({
                                  'createdAtMillis':
                                      DateTime.now().millisecondsSinceEpoch,
                                })
                                .then((_) {
                                  showQRCode(docId);
                                });
                          },
                          child: const Text("QR"),
                        ),
                      );
                    },
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
