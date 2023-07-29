// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({Key? key, required User user}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AbsenPageState createState() => _AbsenPageState();
}

class CardModel {
  String title;
  String status;
  int hadir;
  int izin;
  int alpha;

  CardModel({
    required this.title,
    this.status = 'Hadir',
    this.hadir = 0,
    this.izin = 0,
    this.alpha = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'status': status,
      'hadir': hadir,
      'izin': izin,
      'alpha': alpha,
    };
  }
}

class _AbsenPageState extends State<AbsenPage> {
  late List<DocumentSnapshot> documents;
  late List<CardModel> cards;
  String selectedStatus = 'Hadir';
  late int selectedClassIndex;
  String selectedClassName = '';
  String searchQuery = '';
  bool isCardGenerated = false;
  void search(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  Future<void> showDocumentListDialog(BuildContext context) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('client') // Ganti 'client' dengan nama koleksi yang sesuai
        .get();

    documents = snapshot.docs;

    bool isButtonPressed = false; // Menyimpan status tombol ditekan

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Pilih kelas')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.separated(
                shrinkWrap: true,
                itemCount: documents.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(color: Colors.grey);
                },
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Center(
                        child: Text(
                      documents[index].id,
                      style: const TextStyle(color: Colors.blue),
                    )),
                    onTap: () {
                      selectedClassIndex = index;
                      Navigator.of(context).pop();
                      showSubDocumentList(context, documents[index]);
                    },
                  );
                },
              ),
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
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(CardModel card) {
    // Menambahkan kondisi untuk memfilter kartu berdasarkan query pencarian
    if (searchQuery.isNotEmpty &&
        !card.title.toLowerCase().contains(searchQuery.toLowerCase())) {
      return const SizedBox();
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Colors.black,
          width: 0.5,
        ), // Menambahkan border
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(2, 7, 12, 2),
                  child: Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatusOption(
                          card: card,
                          status: 'Hadir',
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatusOption(
                          card: card,
                          status: 'Izin',
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatusOption(
                          card: card,
                          status: 'Alpha',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required CardModel card,
    required String status,
    required Color color,
  }) {
    int selectionCount = 0;
    if (status == 'Hadir') {
      selectionCount = card.hadir;
    } else if (status == 'Izin') {
      selectionCount = card.izin;
    } else if (status == 'Alpha') {
      selectionCount = card.alpha;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          card.status = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: card.status == status ? color.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: card.status == status ? color : Colors.black,
              ),
            ),
            Text(
              'Count: $selectionCount',
              style: TextStyle(
                fontSize: 12.0,
                color: card.status == status ? color : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showSubDocumentList(
      BuildContext context, DocumentSnapshot document) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('client')
        .doc(document.id)
        .collection('siswa')
        .get();

    final List<DocumentSnapshot> subDocuments = snapshot.docs;

    setState(() {
      cards.clear();

      for (int i = 0; i < subDocuments.length; i++) {
        String subDocumentTitle = subDocuments[i].id;
        cards.add(CardModel(title: subDocumentTitle));
      }

      selectedClassName = document.id; // Tambahkan baris ini
      isCardGenerated =
          true; // Tambahkan baris ini untuk mengubah isCardGenerated menjadi true
    });
    _fetchSelectionCount();
  }

  Future<void> _fetchSelectionCount() async {
    if (documents.isNotEmpty && selectedClassIndex >= 0) {
      final String selectedClass = documents[selectedClassIndex].id;

      final DocumentSnapshot attendanceSnapshot = await FirebaseFirestore
          .instance
          .collection('attendance')
          .doc(selectedClass)
          .get();

      if (attendanceSnapshot.exists) {
        final Map<String, dynamic> attendanceData =
            attendanceSnapshot.data() as Map<String, dynamic>;

        setState(() {
          for (CardModel card in cards) {
            final String cardTitle = card.title;

            if (attendanceData.containsKey(cardTitle)) {
              final Map<String, dynamic> cardData =
                  attendanceData[cardTitle] as Map<String, dynamic>;
              card.status = cardData['status'] as String;
              card.hadir = cardData['hadir'] as int;
              card.izin = cardData['izin'] as int;
              card.alpha = cardData['alpha'] as int;
            }
          }
        });
      }
    }
  }

  Future<void> saveStatusToFirebase() async {
    // Menyimpan status dan selectionCount siswa pada kelas yang dipilih
    if (documents.isNotEmpty) {
      final String selectedClass = documents[selectedClassIndex].id;

      // Mendapatkan referensi dokumen kelas pada koleksi 'attendance'
      final DocumentReference attendanceRef = FirebaseFirestore.instance
          .collection('attendance') // Ganti dengan nama koleksi yang sesuai
          .doc(selectedClass); // Menggunakan nama kelas yang dipilih

      // Membuat map yang akan menyimpan status siswa beserta jumlah pemilihannya
      Map<String, dynamic> statusData = {};
      for (CardModel card in cards) {
        card.status == 'Hadir'
            ? card.hadir += 1
            : card.status == 'Izin'
                ? card.izin += 1
                : card.alpha += 1;

        statusData[card.title] = card.toMap();
      }

      // Menyimpan map status ke Firebase Firestore pada dokumen kelas yang dipilih
      await attendanceRef.set(statusData, SetOptions(merge: true));
      _fetchSelectionCount(); // Ambil nilai selectionCount dari Firebase
      // Tampilkan notifikasi "Status berhasil diperbarui"
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
                    'Absen berhasil disimpan',
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

      // Perbarui teks 'Count' pada kartu setelah status diperbarui
      setState(() {});
    } else {
      // Jika tidak ada kelas yang dipilih, tampilkan pesan peringatan
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Notifikasi'),
            content: const Text('Pilih kelas terlebih dahulu'),
            actions: [
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
    }
  }

  @override
  void initState() {
    super.initState();
    cards = [];
    selectedClassIndex = -1;
  }

  void selectClass(int index) {
    selectedClassIndex = index;
    showSubDocumentList(context, documents[index]);
  }

  @override
  Widget build(BuildContext context) {
    bool isCardGenerated = cards.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.grey[200],
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(10),
            ),
            side: BorderSide(color: Colors.black, width: 0.4),
          ),
          title: Row(
            children: [
              const Text(
                'Absen Kelas',
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
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.blue; // bg biru ketika ditekan
                      }
                      return Colors.white; // bg putih
                    },
                  ),
                  foregroundColor: MaterialStateProperty.all<Color>(
                      Colors.blue), // text biru
                  side: MaterialStateProperty.all<BorderSide>(
                    const BorderSide(color: Colors.blue), // border biru
                  ),
                ),
                icon: const Icon(Icons.list, size: 20),
                label: const Text('!'),
              ),
              const SizedBox(width: 8),
              if (isCardGenerated)
                ElevatedButton.icon(
                  onPressed: () {
                    saveStatusToFirebase();
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.green;
                        }
                        return Colors.white;
                      },
                    ),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                    side: MaterialStateProperty.all<BorderSide>(
                      const BorderSide(color: Colors.green),
                    ),
                  ),
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text('Simpan'),
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
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: <Widget>[
                      const Text(
                        'Kelas:  ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedClassName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 16, 0),
                  child: Container(
                    height: 40,
                    width: 162,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 18.5, 2, 2),
                            child: TextField(
                              onChanged: (value) {
                                search(value);
                              },
                              decoration: const InputDecoration(
                                hintText: 'Cari siswa',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              color: Colors.black,
              thickness: 0.3,
            ),
            Center(
              child: Visibility(
                visible: !isCardGenerated,
                child: const Padding(
                  padding: EdgeInsets.only(top: 270),
                  child: Text(
                    'Pilih kelas dulu nggih',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
            if (isCardGenerated)
              Column(
                children: cards.map((card) => _buildCard(card)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
