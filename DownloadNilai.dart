// ignore_for_file: file_names, depend_on_referenced_packages, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:appmaster_1/DownloadNilaiSiswa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DownloadNilaiMapel.dart';

class DownloadNilaiPage extends StatefulWidget {
  const DownloadNilaiPage({Key? key, required User user}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DownloadNilaiPageState createState() => _DownloadNilaiPageState();
}

class _DownloadNilaiPageState extends State<DownloadNilaiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedDocument = '';
  String selectedFormat = '';
  List<String> documentList = [];
  List<String> formatList = ['Word', 'Excel', 'PDF'];
  Map<String, IconData> formatIcons = {
    'Word': Feather.file_text,
    'Excel': Feather.file_plus,
    'PDF': Feather.package,
  };
  bool isDownloading = false;
  Timer? _debounceTimer;
  List<String> downloadHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    fetchDocuments();
    selectedFormat = formatList[0];
    _loadDownloadHistory(); // Load download history from shared preferences
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void generatePdf(String document) async {
    if (!isDownloading) {
      setState(() {
        isDownloading = true;
      });

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 5), () {
        setState(() {
          isDownloading = false;
        });
      });

      final pdf = pw.Document();

      // Prepare the formatted data for PDF
      List<List<String>> tableData = [];

      // Add table header
      tableData.add(['Nama', 'Hadir', 'Izin', 'Alpha']);

      // Retrieve data from Firestore
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(document)
          .get();

      // Extract the data from the snapshot
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

      if (data != null) {
        // Iterate over the data and format it as needed
        data.forEach((key, value) {
          if (key != 'SelectionCount') {
            List<String> rowData = [
              key,
              value['hadir'].toString(),
              value['izin'].toString(),
              value['alpha'].toString(),
            ];
            tableData.add(rowData);
          }
        });
      }

      // Calculate column sums
      int totalHadir = 0;
      int totalIzin = 0;
      int totalAlpha = 0;

      for (int i = 1; i < tableData.length; i++) {
        totalHadir += int.parse(tableData[i][1]);
        totalIzin += int.parse(tableData[i][2]);
        totalAlpha += int.parse(tableData[i][3]);
      }

      // Calculate percentages
      double percentageHadir =
          (totalHadir / (totalHadir + totalIzin + totalAlpha)) * 100;
      double percentageIzin =
          (totalIzin / (totalHadir + totalIzin + totalAlpha)) * 100;
      double percentageAlpha =
          (totalAlpha / (totalHadir + totalIzin + totalAlpha)) * 100;

      // Add content to the PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Absensi kelas $document per ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  context: context,
                  data: tableData,
                  border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment
                      .center, // Align kolom "Hadir", "Izin", dan "Alpha" ke tengah
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  cellPadding: const pw.EdgeInsets.all(5),
                  headerPadding: const pw.EdgeInsets.all(5),
                  cellAlignments: {
                    0: pw.Alignment
                        .topLeft, // Align kolom "Nama" siswa ke kiri atas
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                  },
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  context: context,
                  data: [
                    [
                      'Rata-rata',
                      '${percentageHadir.toStringAsFixed(2)}%',
                      '${percentageIzin.toStringAsFixed(2)}%',
                      '${percentageAlpha.toStringAsFixed(2)}%',
                    ],
                  ],
                  border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                  cellAlignment: pw.Alignment.center,
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  cellPadding: const pw.EdgeInsets.all(5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF file
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String className = selectedDocument;
      final String date = DateFormat('dd_MM_yyyy').format(DateTime.now());
      final String fileName = 'Absen $date $className.pdf';
      final String path = '$dir/$fileName';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Downloading...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Delay for 2 seconds to simulate download progress
      await Future.delayed(const Duration(seconds: 2));

      // Close progress dialog
      Navigator.pop(context);

      // Show preview and share dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(child: Text('Sukses!')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 50,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fileName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(file.lengthSync() / 1024).toStringAsFixed(2)} kB',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        OpenFile.open(path); // Open the file
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 26,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        sharePdf(fileName, path);
                      },
                      icon: const Icon(
                        Icons.share,
                        size: 32,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 32,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        downloadHistory.insert(0, fileName);
      });
      _saveDownloadHistory(
          downloadHistory); // Save download history to shared preferences
    }
  }

  void fetchDocuments() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('attendance').get();
    List<String> documents =
        snapshot.docs.map((doc) => doc.id).toList(); // Mengambil ID dokumen
    setState(() {
      documentList = documents;
      selectedDocument = documents.isNotEmpty ? documents[0] : '';
    });
  }

  void sharePdf(String fileName, String path) async {
    // Share the PDF file via WhatsApp
    await Share.shareFiles([path], text: 'Check out this file: $fileName');
  }

  void _handleTabSelection() {
    setState(() {
      selectedDocument = documentList.isNotEmpty ? documentList[0] : '';
    });
  }

  void _saveDownloadHistory(List<String> history) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Reverse the order of the history list before saving
    await prefs.setStringList('downloadHistory', history.reversed.toList());
  }

  void _loadDownloadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('downloadHistory');
    if (history != null) {
      setState(() {
        downloadHistory = history.reversed.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Nilai'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Absen Kelas'),
            Tab(text: 'Nilai Mapel'),
            Tab(text: 'Nilai Individu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Konten tab "Absen Kelas"
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '  Format',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonFormField<String>(
                              value: selectedFormat,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              isExpanded: true,
                              items: formatList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(
                                        formatIcons[value],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        value,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedFormat = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '  Kelas',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonFormField<String>(
                              value: selectedDocument,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              isExpanded: true,
                              items: documentList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedDocument = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue,
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        generatePdf(selectedDocument);
                      },
                      label: const Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      icon: const Icon(
                        Icons.downloading_rounded,
                        color: Colors.white,
                      ),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  thickness: 1,
                  color: Colors.grey,
                ),
                const SizedBox(height: 2),
                const Text(
                  ' Riwayat Unduhan:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: downloadHistory.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final fileName = downloadHistory[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        leading: const Icon(
                          Icons.description,
                          size: 35,
                        ),
                        title: Text(fileName),
                        onTap: () async {
                          final path =
                              '${(await getApplicationDocumentsDirectory()).path}/$fileName';
                          OpenFile.open(path);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final path =
                                    '${(await getApplicationDocumentsDirectory()).path}/$fileName';
                                sharePdf(fileName, path);
                              },
                              icon: const Icon(Icons.share),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Konten tab "Nilai Mapel"
          // Konten tab "Nilai Mapel"
          const NilaiMapelContent(),

          // Konten tab "Nilai Individual"
          const DownloadNilaiSiswa(),
        ],
      ),
    );
  }
}
