// ignore_for_file: file_names, use_build_context_synchronously, duplicate_ignore

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class DownloadNilaiSiswa extends StatefulWidget {
  const DownloadNilaiSiswa({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DownloadNilaiSiswaState createState() => _DownloadNilaiSiswaState();
}

class _DownloadNilaiSiswaState extends State<DownloadNilaiSiswa> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedKelas;
  String? selectedMapel;
  List<String> mapelList = [];
  List<String> daftarCollection = [];

  pw.Document? pdf; // Added pdf variable

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
                                pdf = null; // Reset pdf when kelas changes
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
                            pdf = null;
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    generatePdf(selectedMapel!);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error'),
                          content: const Text(
                            'Please select Kelas, Mapel, and Option before generating the PDF.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
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

  void generatePdf(String mapel) async {
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

    // Get the "client" document that matches selectedKelas
    DocumentSnapshot<Map<String, dynamic>> clientDocSnapshot =
        await firestore.collection('client').doc(selectedKelas).get();

    if (clientDocSnapshot.exists) {
      // Access the "siswa" subcollection for the matching "client" document
      CollectionReference<Map<String, dynamic>> siswaCollection =
          clientDocSnapshot.reference.collection('siswa');

      // Get the documents from the "siswa" subcollection
      QuerySnapshot<Map<String, dynamic>> siswaSnapshot =
          await siswaCollection.get();

      List<String> siswaDocuments =
          siswaSnapshot.docs.map((doc) => doc.id).toList();

      // Generate PDF
      pdf = pw.Document();

      pdf!.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'Daftar Dokumen Siswa Kelas $selectedKelas Mapel $mapel',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
                pw.ListView.builder(
                  itemCount: siswaDocuments.length,
                  itemBuilder: (context, index) {
                    return pw.Text(
                      siswaDocuments[index],
                      style: const pw.TextStyle(fontSize: 14),
                    );
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
          'Daftar Dokumen Siswa Kelas $selectedKelas Mapel $mapel ${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf';
      final String path = '$dir/$fileName';
      final File file = File(path);
      await file.writeAsBytes(await pdf!.save());

      // Close progress dialog
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      // Show preview and share dialog
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
    } else {
      // Close progress dialog
      Navigator.pop(context);

      // Show error dialog if the "client" document with selectedKelas is not found
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'The selectedKelas document does not exist in the "client" collection.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void sharePdf(String fileName, String path) async {
    // Share the PDF file via WhatsApp
    // ignore: deprecated_member_use
    await Share.shareFiles([path], text: 'Check out this file: $fileName');
  }
}
