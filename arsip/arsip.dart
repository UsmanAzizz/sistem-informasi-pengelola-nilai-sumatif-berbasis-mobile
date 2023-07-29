// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class DownloadNilaiSiswa extends StatefulWidget {
  const DownloadNilaiSiswa({Key? key}) : super(key: key);

  @override
  _DownloadNilaiSiswaState createState() => _DownloadNilaiSiswaState();
}

class _DownloadNilaiSiswaState extends State<DownloadNilaiSiswa> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedKelas;
  String? selectedMapel;
  String? selectedOption;
  List<String> mapelList = [];
  List<String> daftarCollection = [];
  List<String> siswaList = [];

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
                        stream: firestore.collection('client').snapshots(),
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
                                selectedMapel =
                                    null; // Set selectedMapel to null when kelas changes
                                mapelList
                                    .clear(); // Reset mapelList when kelas changes
                                selectedOption =
                                    null; // Reset selectedOption when kelas changes
                                siswaList
                                    .clear(); // Reset siswaList when kelas changes
                              });
                              fetchMapelData(newValue);
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
                            selectedOption =
                                null; // Reset selectedOption when mapel changes
                            siswaList
                                .clear(); // Reset siswaList when mapel changes
                          });
                          fetchSiswaData(selectedKelas, newValue);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedOption,
              decoration: const InputDecoration(
                labelText: 'Pilih Siswa',
                border: InputBorder.none,
              ),
              isExpanded: true,
              items: siswaList.map((siswa) {
                return DropdownMenuItem<String>(
                  value: siswa,
                  child: Text(siswa),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedOption = newValue;
                });
              },
            ),
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
                  generatePdf(selectedMapel);
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
            'Riwayat Unduhan:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  onTap: () {},
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

  void fetchMapelData(String? kelas) {
    if (kelas != null) {
      firestore
          .collection('client')
          .doc(kelas)
          .collection('mapel')
          .get()
          .then((snapshot) {
        List<String> fetchedMapelList =
            snapshot.docs.map((doc) => doc.id).toList();
        setState(() {
          mapelList = fetchedMapelList;
        });
      });
    }
  }

  void fetchSiswaData(String? kelas, String? mapel) {
    if (kelas != null && mapel != null) {
      firestore
          .collection('siswa')
          .where('kelas', isEqualTo: kelas)
          .get()
          .then((snapshot) {
        List<String> fetchedSiswaList =
            snapshot.docs.map((doc) => doc.id).toList();
        setState(() {
          siswaList = fetchedSiswaList;
        });
      });
    }
  }

  void generatePdf(String? mapel) async {
    if (selectedKelas != null && mapel != null && selectedOption != null) {
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
                    'Generating PDF...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Retrieve subcollections from Firestore
      QuerySnapshot subCollectionSnapshot = await firestore
          .collection('client')
          .doc(selectedKelas)
          .collection('nilaimapel')
          .doc(selectedOption)
          .collection('subcollection')
          .get();

      List<QueryDocumentSnapshot> subCollections = subCollectionSnapshot.docs;

      // Prepare the formatted data for PDF
      List<List<String>> tableData = [];

      // Add table header
      tableData.add(['Nama Siswa', 'Daftar Subcollection']);

      // Iterate over the subcollections and format the data
      for (var subCollection in subCollections) {
        String namaSiswa = subCollection.id;
        List<String> rowData = [namaSiswa, subCollection.reference.path];
        tableData.add(rowData);
      }

      final pdf = pw.Document();

      // Add content to the PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Nilai Mapel $mapel Kelas $selectedKelas',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  context: context,
                  data: tableData,
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 1,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellAlignment: pw.Alignment.center,
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  cellPadding: const pw.EdgeInsets.all(5),
                  headerPadding: const pw.EdgeInsets.all(5),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                  },
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                  },
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF file
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          'Nilai Mapel $mapel Kelas $selectedKelas ${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf';
      final String path = '$dir/$fileName';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Close progress dialog
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      // Show preview and share dialog
      // ignore: use_build_context_synchronously
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

      // Update daftarCollection
      setState(() {
        daftarCollection.add(fileName);
      });
    }
  }

  void sharePdf(String fileName, String path) async {
    // Share the PDF file via WhatsApp
    await Share.shareFiles([path], text: 'Check out this file: $fileName');
  }
}
