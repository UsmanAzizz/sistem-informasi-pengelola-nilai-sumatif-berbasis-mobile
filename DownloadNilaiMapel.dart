// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously, duplicate_ignore, deprecated_member_use

import 'dart:io';
import 'pdf_view_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class NilaiMapelContent extends StatefulWidget {
  const NilaiMapelContent({Key? key}) : super(key: key);

  @override
  _NilaiMapelContentState createState() => _NilaiMapelContentState();
}

class _NilaiMapelContentState extends State<NilaiMapelContent> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedKelas;
  String? selectedMapel;
  List<String> mapelList = [];
  List<String> daftarCollection = [];
  List<String> fieldNames = [];

  CollectionReference<Map<String, dynamic>> downloadHistoryCollection =
      FirebaseFirestore.instance
          .collection('downloadHistory'); // New collection

  @override
  void initState() {
    super.initState();
    // Fetch the previously downloaded file names from the downloadHistory collection
    fetchDownloadHistory();
  }

  void fetchDownloadHistory() async {
    // Fetch the downloaded file names from the downloadHistory collection
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await downloadHistoryCollection
            .orderBy('downloadedAt', descending: true)
            .get();

    List<String> downloadedFiles =
        snapshot.docs.map((doc) => doc['fileName'] as String).toList();

    setState(() {
      daftarCollection = downloadedFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      '  Kelas',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: firestore.collection('nilaimapel').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          List<String> kelasList =
                              snapshot.data!.docs.map((doc) => doc.id).toList();
                          return DropdownButtonFormField<String>(
                            value: selectedKelas,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            isExpanded: true,
                            items: kelasList.map((kelas) {
                              return DropdownMenuItem<String>(
                                value: kelas,
                                child: Text(kelas),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedKelas = newValue;
                                selectedMapel = null;
                                mapelList.clear();
                                daftarCollection.clear();
                              });

                              fetchDaftarMapel();
                            },
                          );
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
                      '  Mapel',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        value: selectedMapel,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        isExpanded: true,
                        items: mapelList.map((mapel) {
                          return DropdownMenuItem<String>(
                            value: mapel,
                            child: Text(mapel),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMapel = newValue;
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
                  if (selectedKelas != null && selectedMapel != null) {
                    fetchFieldNames(selectedKelas!, selectedMapel!);
                    generatePdf(selectedMapel);
                  } else {
                    // Show a warning dialog if kelas or mapel is not selected
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dialogBackgroundColor: Colors.white,
                            // Customize other dialog properties here if needed
                          ),
                          child: AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            title: const Text(
                              'Oalah!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            content: const Text(
                              'Pilih Kelas & Mapel dulu nggih!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  primary: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                ),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
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
          const SizedBox(height: 2),
          const Divider(
            thickness: 0.2,
            color: Colors.black,
          ),
          Expanded(
            child: ListView.separated(
              itemCount: daftarCollection.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  leading: const Icon(
                    Icons.description,
                    size: 35,
                  ),
                  title: Text(daftarCollection[index]),
                  onTap: () async {
                    String fileName = daftarCollection[index];
                    String dir =
                        (await getApplicationDocumentsDirectory()).path;
                    String path = '$dir/$fileName';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewPage(filePath: path),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          String fileName = daftarCollection[index];
                          String dir =
                              (await getApplicationDocumentsDirectory()).path;
                          String path = '$dir/$fileName';
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
    );
  }

  void fetchDaftarMapel() {
    if (selectedKelas != null) {
      firestore
          .collection('nilaimapel')
          .doc(selectedKelas!)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data()!;
          setState(() {
            if (data.isNotEmpty) {
              mapelList = data.keys.toList();
            } else {
              mapelList = [];
            }
          });
        } else {
          setState(() {
            mapelList = [];
          });
        }
      });
    }
  }

  void generatePdf(String? mapel) async {
    if (selectedKelas != null && mapel != null) {
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
                    'Generating PDF...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final pdf = pw.Document();

      String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
                // Wrap the content with a Container
                padding: const pw.EdgeInsets.only(
                    left: -10, right: -10), // Adjust padding to create margins
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        'SMK DIPONEGORO CIPARI',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Center(
                      child: pw.Text(
                        'Nilai Mapel $selectedMapel Kelas $selectedKelas',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Align(
                      alignment: pw.Alignment
                          .centerRight, // Align the content to the left
                      child: pw.Text('Dibuat pada tanggal: $formattedDate'),
                    ),
                    pw.SizedBox(height: 2),
                    for (int i = 0; i < 7; i++) pw.Center(child: pw.Text('')),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      defaultVerticalAlignment:
                          pw.TableCellVerticalAlignment.middle,
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(7),
                        2: const pw.FlexColumnWidth(9),
                        3: const pw.FlexColumnWidth(9),
                        4: const pw.FlexColumnWidth(2),
                        5: const pw.FlexColumnWidth(2),
                        6: const pw.FlexColumnWidth(1),
                        7: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Center(child: pw.Text('M')),
                            pw.Center(
                                child: pw.Text(
                              '$mapel',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            )),
                            pw.Center(child: pw.Text('Sumatif Lingkup Materi')),
                            pw.Center(child: pw.Text('Tugas')),
                            pw.Center(child: pw.Text('STS')),
                            pw.Center(child: pw.Text('SAS')),
                            pw.Center(child: pw.Text('N')),
                            pw.Center(child: pw.Text('P')),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Container(),
                            pw.Container(),
                            pw.Container(),
                            pw.Container(),
                            pw.Container(),
                            pw.Container(),
                            pw.Container(),
                            pw.Container(),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      defaultVerticalAlignment:
                          pw.TableCellVerticalAlignment.middle,
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(7),
                        2: const pw.FlexColumnWidth(1),
                        3: const pw.FlexColumnWidth(1),
                        4: const pw.FlexColumnWidth(1),
                        5: const pw.FlexColumnWidth(1),
                        6: const pw.FlexColumnWidth(1),
                        7: const pw.FlexColumnWidth(1),
                        8: const pw.FlexColumnWidth(1),
                        9: const pw.FlexColumnWidth(1),
                        10: const pw.FlexColumnWidth(1),
                        11: const pw.FlexColumnWidth(1),
                        12: const pw.FlexColumnWidth(1),
                        13: const pw.FlexColumnWidth(1),
                        14: const pw.FlexColumnWidth(1),
                        15: const pw.FlexColumnWidth(1),
                        16: const pw.FlexColumnWidth(1),
                        17: const pw.FlexColumnWidth(1),
                        18: const pw.FlexColumnWidth(1),
                        19: const pw.FlexColumnWidth(1),
                        20: const pw.FlexColumnWidth(1),
                        21: const pw.FlexColumnWidth(1),
                        22: const pw.FlexColumnWidth(1),
                        23: const pw.FlexColumnWidth(1),
                        24: const pw.FlexColumnWidth(1),
                        25: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Center(child: pw.Text('Nq')),
                            pw.Center(
                                child: pw.Text('NAMA SISWA',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Center(child: pw.Text('1')),
                            pw.Center(child: pw.Text('2')),
                            pw.Center(child: pw.Text('3')),
                            pw.Center(child: pw.Text('4')),
                            pw.Center(child: pw.Text('5')),
                            pw.Center(child: pw.Text('6')),
                            pw.Center(child: pw.Text('7')),
                            pw.Center(child: pw.Text('8')),
                            pw.Center(child: pw.Text('N')),
                            pw.Center(child: pw.Text('1')),
                            pw.Center(child: pw.Text('2')),
                            pw.Center(child: pw.Text('3')),
                            pw.Center(child: pw.Text('4')),
                            pw.Center(child: pw.Text('5')),
                            pw.Center(child: pw.Text('6')),
                            pw.Center(child: pw.Text('7')),
                            pw.Center(child: pw.Text('8')),
                            pw.Center(child: pw.Text('N')),
                            pw.Center(child: pw.Text('T')),
                            pw.Center(child: pw.Text('R')),
                            pw.Center(child: pw.Text('A')),
                            pw.Center(child: pw.Text('R')),
                            pw.Center(child: pw.Text('R')),
                            pw.Center(child: pw.Text('P')),
                          ],
                        ),
                        for (String fieldName in fieldNames)
                          pw.TableRow(
                            children: [
                              pw.Container(),
                              pw.Align(
                                alignment: pw.Alignment
                                    .centerLeft, // Align the content to the left
                                child: pw.Text(fieldName),
                              ),
                              // You can add more cells with default values if needed
                              for (int i = 0; i < 7; i++)
                                pw.Center(child: pw.Text('')),
                            ],
                          ),
                      ],
                    ),
                  ],
                ));
          },
        ),
      );

      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          'Nilai Mapel $mapel Kelas $selectedKelas ${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf';
      final String path = '$dir/$fileName';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());
      Navigator.pop(context);

      // Save the file name to the downloadHistory collection
      downloadHistoryCollection.add({
        'fileName': fileName,
        'downloadedAt': FieldValue.serverTimestamp(),
      });

      // Fetch the updated download history after saving the file
      fetchDownloadHistory();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(child: Text('PDF Generated')),
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
                      onPressed: () async {
                        final file = File(path);
                        if (await file.exists()) {
                          final String platformPath =
                              Platform.isAndroid ? path : 'file://$path';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PDFView(
                                filePath: platformPath,
                              ),
                            ),
                          );
                        } else {
                          throw 'File does not exist!';
                        }
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
    }
  }

  void fetchFieldNames(String selectedKelas, String selectedMapel) {
    if (selectedKelas != null && selectedMapel != null) {
      firestore
          .collection('nilaimapel')
          .doc(selectedKelas)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data()!;
          if (data.containsKey(selectedMapel)) {
            setState(() {
              fieldNames = data[selectedMapel].keys.toList();
            });
          } else {
            setState(() {
              fieldNames = [];
            });
          }
        } else {
          setState(() {
            fieldNames = [];
          });
        }
      });
    }
  }

  void sharePdf(String fileName, String path) async {
    await Share.shareFiles([path], text: 'Check out this file: $fileName');
  }
}
