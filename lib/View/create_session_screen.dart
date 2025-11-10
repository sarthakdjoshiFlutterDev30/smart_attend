import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_saver/file_saver.dart';

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
  Future<void> downloadSample() async {
    try {
      final byteData = await rootBundle.load('Book1.xlsx');
      final bytes = byteData.buffer.asUint8List();
      const fileName = 'Sample_Attendance.xlsx';
      const mime =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      if (kIsWeb) {
        final blob = html.Blob([bytes], mime);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)..download = fileName;
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } else {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.microsoftExcel,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download sample file")),
      );
    }
  }
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
        'lecName': record['lecName'].toString().toUpperCase(),
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
    int secondsLeft = 10;
    Timer? timer;

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
            title: const Text("QR Code"),
            content: SizedBox(
              width: 250,
              height: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(data: docId, size: 200),
                  const SizedBox(height: 20),
                  Text(
                    "Expires in $secondsLeft s",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      ),
    ).then((_) => timer?.cancel()); // Cancel timer if dialog is manually closed
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Create Session"),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.06),
              colorScheme.secondary.withOpacity(0.06),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.upload_file, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Upload Excel",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: downloadSample,
                                    icon: const Icon(Icons.download),
                                    label: const Text("Download Sample"),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: pickAndReadExcelWeb,
                                    icon: const Icon(Icons.folder_open),
                                    label: const Text("Pick File"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: fileName.isEmpty
                                    ? Text(
                                        "No file selected",
                                        key: const ValueKey("no-file"),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Chip(
                                            key: const ValueKey("file-chip"),
                                            avatar: const Icon(Icons.insert_drive_file, size: 18),
                                            label: Text(fileName),
                                            backgroundColor: colorScheme.primary.withOpacity(0.08),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isUploading ? null : uploadToFirestore,
                                  icon: isUploading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              colorScheme.onPrimary,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.cloud_upload),
                                  label: Text(isUploading ? "Uploading..." : "Upload to Firestore"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Today • $todayDate",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.history, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Today's Sessions",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 8,
                              ),
                              SizedBox(
                                height: 300,
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
                                    final filtered = docs.where((d) {
                                      final data = d.data() as Map<String, dynamic>;
                                      return data['lecDate'] == todayDate;
                                    }).toList();
                                    if (filtered.isEmpty) {
                                      return const Center(child: Text("No sessions for today"));
                                    }
                                    return ListView.separated(
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final doc = filtered[index];
                                        final data = doc.data() as Map<String, dynamic>;
                                        final docId = doc.id;
                                        return Material(
                                          color: colorScheme.surface,
                                          elevation: 1,
                                          borderRadius: BorderRadius.circular(12),
                                          child: ListTile(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            title: Text(
                                              data['lecName'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            subtitle: Row(
                                              children: [
                                                const Icon(Icons.confirmation_number, size: 16),
                                                const SizedBox(width: 6),
                                                Text("Lec No: ${data['lecNo']}"),
                                              ],
                                            ),
                                            trailing: FilledButton.icon(
                                              onPressed: () {
                                                FirebaseFirestore.instance
                                                    .collection("sessions")
                                                    .doc(docId)
                                                    .update({
                                                      'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
                                                    })
                                                    .then((_) {
                                                      showQRCode(docId);
                                                    });
                                              },
                                              icon: const Icon(Icons.qr_code),
                                              label: const Text("QR"),
                                            ),
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
                      ),
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
}
