// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class InputNilaiProduk extends StatefulWidget {
  const InputNilaiProduk({Key? key, required User user}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _InputNilaiProdukState createState() => _InputNilaiProdukState();
}

class CardModel {
  String title;
  List<int> values;
  List<TextEditingController> textEditingControllers;

  CardModel({
    required this.title,
    required this.values,
    required this.textEditingControllers,
  }) {
    assert(values.length == 8);
    assert(textEditingControllers.length == 8);
  }
}

class _InputNilaiProdukState extends State<InputNilaiProduk> {
  late List<DocumentSnapshot> documents;
  List<CardModel> cards = [];
  String selectedClass = '';
  String selectedSubject = '';
  BuildContext? _scaffoldContext;
  bool isSaveButtonVisible = false;
  TextEditingController searchController = TextEditingController();
  List<CardModel> filteredCards = [];
  bool isLoading = false;
  List<TextEditingController> textEditingControllers = [];

  Future<void> showDocumentListDialog(BuildContext context) async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('client').get();

    documents = snapshot.docs;

    bool isButtonPressed = false;

    showDialog(
      context: _scaffoldContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'Pilih kelas',
              textAlign: TextAlign.center,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: documents.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: <Widget>[
                          ListTile(
                            title: Center(
                              child: Text(
                                documents[index].id,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedClass = documents[index].id;
                                selectedSubject = '';
                                cards.clear();
                                isSaveButtonVisible = false;
                              });
                              Navigator.of(context).pop();
                              showSubDocumentList(
                                context,
                                documents[index].reference,
                              );
                            },
                          ),
                          if (index != documents.length - 1) const Divider(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        isButtonPressed = true;
                        return Colors.red;
                      }
                      return Colors.white;
                    },
                  ),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: isButtonPressed ? Colors.red : Colors.red,
                      ),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: isButtonPressed ? Colors.white : Colors.red,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(CardModel card) {
    return Card(
      key: ValueKey(card.title),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(
          color: Colors.black,
          width: 0.4,
        ),
      ),
      child: Center(
        child: SizedBox(
          height: 100, // Ubah tinggi card sesuai kebutuhan Anda
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    card.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                Row(
                  children: List.generate(
                    8,
                    (index) {
                      final bool isEditable =
                          index == 0 || card.values[index - 1] != 0;
                      final TextEditingController controller =
                          card.textEditingControllers[index];
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(1, 0, 1, 0),
                          height: 36,
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 0.43,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                            color: isEditable
                                ? Colors.white
                                : Colors.blueGrey[100],
                            boxShadow: isEditable
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.7),
                                      blurRadius: 0,
                                      offset: const Offset(0.7, 2.5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextFormField(
                            controller: controller,
                            enabled: isEditable,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.0,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(
                                  r'[1-9][0-9]*')), // Mengizinkan angka yang tidak diawali dengan 0
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                                  final int? value =
                                      int.tryParse(newValue.text);
                                  if (value != null &&
                                      value >= 0 &&
                                      value <= 100) {
                                    return newValue;
                                  }
                                  if (newValue.text.isEmpty ||
                                      newValue.text.length == 1) {
                                    return newValue;
                                  }
                                  return oldValue;
                                },
                              ),
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.fromLTRB(7.0, 5.0, 4, 18),
                            ),
                            onChanged: (value) {
                              final int intValue = int.tryParse(value) ?? 0;
                              setState(() {
                                card.values[index] = intValue;
                                isSaveButtonVisible = true;
                              });
                            },
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final numericValue = int.tryParse(value);
                                if (numericValue != null &&
                                    (numericValue < 0 || numericValue > 100)) {
                                  return 'Nilai harus di antara 0 dan 100';
                                }
                              }
                              return null;
                            },
                            cursorColor: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showSubDocumentList(
      BuildContext context, DocumentReference classReference) async {
    final QuerySnapshot snapshot =
        await classReference.collection('mapel').get();
    final CollectionReference<Map<String, dynamic>> nilaiMapelCollection =
        FirebaseFirestore.instance.collection('nilaimapel');

    final DocumentReference<Map<String, dynamic>> kelasDocument =
        nilaiMapelCollection.doc(selectedClass);

    await kelasDocument.set({}); // Membuat dokumen kelas jika belum ada

    final List<DocumentSnapshot> subDocuments = snapshot.docs;
    showDialog(
      context: _scaffoldContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'Pilih Mapel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subDocuments.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(
                      color: Colors.grey,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSubject = subDocuments[index].id;
                          });
                          Navigator.of(context).pop();
                          generateStudentList(
                              classReference, subDocuments[index].id);
                        },
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: selectedSubject == subDocuments[index].id
                                  ? Colors.red
                                  : Colors.transparent,
                            ),
                            child: ListTile(
                              title: Center(
                                child: Text(
                                  subDocuments[index].id,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      overlayColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Tutup',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void generateStudentList(
    DocumentReference classReference,
    String subjectId,
  ) async {
    setState(() {
      isLoading = true;
    });

    // Mengambil data siswa dari Firebase
    final QuerySnapshot snapshot =
        await classReference.collection('siswa').get();
    final List<QueryDocumentSnapshot> docs = snapshot.docs;

    setState(() {
      cards = docs.map((doc) {
        final textEditingControllers = List.generate(
          8,
          (_) => TextEditingController(),
        );
        return CardModel(
          title: doc.id,
          values: List<int>.filled(8, 0),
          textEditingControllers: textEditingControllers,
        );
      }).toList();

      filteredCards = List.from(cards);
      isSaveButtonVisible = true;
      _filterCards();

      isLoading = false;
    });

    // Mengambil data nilai dari Firebase
    final CollectionReference<Map<String, dynamic>> nilaiMapelCollection =
        FirebaseFirestore.instance.collection('nilaimapel');

    final DocumentReference<Map<String, dynamic>> kelasDocument =
        nilaiMapelCollection.doc(selectedClass);

    for (CardModel card in cards) {
      final CollectionReference<Map<String, dynamic>> siswaCollection =
          kelasDocument.collection(card.title);

      final DocumentSnapshot doc =
          await siswaCollection.doc(selectedSubject).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data is Map<String, dynamic>) {
          final produkData = data['produk'] as Map<String, dynamic>?;

          if (produkData != null) {
            for (int i = 0; i < 8; i++) {
              final String fieldName = '${i + 1}';
              final int fieldValue = produkData[fieldName] as int? ?? 0;
              setState(() {
                card.values[i] = fieldValue;
                card.textEditingControllers[i].text =
                    fieldValue != 0 ? fieldValue.toString() : '';
              });
            }
          } else {
            // Jika field 'produk' adalah Null, set nilai default pada card
            for (int i = 0; i < 8; i++) {
              setState(() {
                card.values[i] = 0;
                card.textEditingControllers[i].text = '';
              });
            }
          }
        }
      }
    }
  }

  void _filterCards() {
    final String searchText = searchController.text.toLowerCase();

    setState(() {
      filteredCards = cards.where((card) {
        final String lowerCaseTitle = card.title.toLowerCase();
        return lowerCaseTitle.contains(searchText);
      }).toList();
    });
  }

  void saveValues() {
    final CollectionReference<Map<String, dynamic>> nilaiMapelCollection =
        FirebaseFirestore.instance.collection('nilaimapel');

    final DocumentReference<Map<String, dynamic>> kelasDocument =
        nilaiMapelCollection.doc(selectedClass);

    Future.wait(cards.map((card) async {
      final Map<String, dynamic> nilaiSiswa = {};
      for (int i = 0; i < 8; i++) {
        final String fieldName = '${i + 1}';
        nilaiSiswa[fieldName] = card.values[i];
      }

      final CollectionReference<Map<String, dynamic>> siswaCollection =
          kelasDocument.collection(card.title);

      final DocumentSnapshot doc =
          await siswaCollection.doc(selectedSubject).get();
      if (doc.exists) {
        await doc.reference.update({'produk': nilaiSiswa});
      } else {
        // Jika dokumen siswa belum ada, buat dokumen secara otomatis
        await siswaCollection.doc(selectedSubject).set({'produk': nilaiSiswa});
      }

      return true;
    })).then((results) {
      // Memeriksa apakah semua penyimpanan berhasil
      if (results.every((result) => result == true)) {
        // Menampilkan dialog pop-up jika semua penyimpanan berhasil
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: const [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nilai berhasil disimpan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Menampilkan pesan kesalahan jika ada penyimpanan yang gagal
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Terjadi kesalahan saat menyimpan data.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Inisialisasi Firebase
    Firebase.initializeApp();
    _filterCards();
    searchController.addListener(_filterCards);
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldContext = context;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(10),
            ),
            side: BorderSide(color: Colors.black, width: 0.2),
          ),
          title: Row(
            children: [
              const Text(
                'Nilai Produk',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Figtree',
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  showDocumentListDialog(context);
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  textStyle: MaterialStateProperty.all<TextStyle>(
                    const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.black),
                  overlayColor: MaterialStateProperty.all<Color>(
                    Colors.black.withOpacity(0.8),
                  ),
                  side: MaterialStateProperty.all<BorderSide>(
                    const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                icon: const Icon(Icons.list, size: 20),
                label: const Text('!', style: TextStyle(color: Colors.black)),
              ),
              const SizedBox(width: 8),
              if (isSaveButtonVisible)
                ElevatedButton.icon(
                  onPressed: () {
                    saveValues();
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(fontSize: 12),
                    ),
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                    overlayColor: MaterialStateProperty.all<Color>(
                      Colors.green.withOpacity(0.8),
                    ),
                    side: MaterialStateProperty.all<BorderSide>(
                      const BorderSide(color: Colors.green, width: 1),
                    ),
                  ),
                  icon: const Icon(Icons.save, size: 20, color: Colors.green),
                  label: const Text('Simpan',
                      style: TextStyle(color: Colors.green)),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 18, 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Kelas     ',
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.grey,
                          ),
                          children: [
                            TextSpan(
                              text: selectedClass,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Mapel   ',
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.grey,
                          ),
                          children: [
                            TextSpan(
                              text: selectedSubject,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 120,
                  height: 35,
                  padding: const EdgeInsets.fromLTRB(22, 7.5, 8, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 0.6),
                  ),
                  child: TextFormField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari siswa',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            thickness: 0.3,
            color: Colors.black,
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredCards.isNotEmpty
                    ? ListView.builder(
                        itemCount: filteredCards.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _buildCard(filteredCards[index]);
                        },
                      )
                    : const Center(
                        child: Text('Monggo pilih kelas kalih mapel'),
                      ),
          ),
        ],
      ),
    );
  }
}
