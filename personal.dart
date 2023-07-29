// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({Key? key, required User user}) : super(key: key);

  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class CardModel {
  String title;
  double disiplin;
  double kerapihan;
  double sikap;

  CardModel({
    required this.title,
    this.disiplin = 100.0,
    this.kerapihan = 100.0,
    this.sikap = 100.0,
  });
}

class _PersonalPageState extends State<PersonalPage> {
  late List<DocumentSnapshot> documents;
  late List<CardModel> cards;
  String selectedDiscipline = 'Kedisiplinan';
  String selectedNeatness = 'Kerapihan';
  String selectedAttitude = 'Sikap';
  late int selectedClassIndex;
  String selectedClassName = '';
  String searchQuery = '';
  final Duration animationDuration = const Duration(seconds: 1);

  void search(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  void initState() {
    super.initState();
    cards = [];
    selectedClassIndex = -1;
  }

  Future<void> showDocumentListDialog(BuildContext context) async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('client').get();

    documents = snapshot.docs;

    bool isButtonPressed = false; // Menyimpan status tombol ditekan

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          'Pilih Kelas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ListView.separated(
                        shrinkWrap: true,
                        itemCount: documents.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            title: Center(
                              child: Text(
                                documents[index].id,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                            onTap: () async {
                              selectedClassIndex = index;
                              selectedClassName = documents[index].id;
                              Navigator.of(context).pop();
                              showSubDocumentList(context, documents[index]);

                              await fetchStatusFromFirebase();
                            },
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            color: Colors.grey,
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
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
                                  color:
                                      isButtonPressed ? Colors.red : Colors.red,
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
                              color:
                                  isButtonPressed ? Colors.white : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ])));
      },
    );
  }

  Widget _buildCard(CardModel card) {
    return Card(
      key: ValueKey(card.title),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
            color: Colors.black, width: 0.5), // Menambahkan border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 1.0),
            Column(
              children: [
                _buildSlider(
                  card: card,
                  label: 'Disiplin     ',
                  value: card.disiplin,
                  onChanged: (value) {
                    setState(() {
                      card.disiplin = value;
                    });
                  },
                ),
                _buildSlider(
                  card: card,
                  label: 'Kerapihan',
                  value: card.kerapihan,
                  onChanged: (value) {
                    setState(() {
                      card.kerapihan = value;
                    });
                  },
                ),
                _buildSlider(
                  card: card,
                  label: 'Sikap        ',
                  value: card.sikap,
                  onChanged: (value) {
                    setState(() {
                      card.sikap = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required CardModel card,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    Color getColor(double value) {
      if (value <= 50) {
        final ratio = value / 50;
        return Color.lerp(Colors.red, Colors.yellow, ratio)!;
      } else {
        final ratio = (value - 50) / 50;
        return Color.lerp(Colors.yellow, Colors.green, ratio)!;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8.0,
                  trackShape: const RoundedRectSliderTrackShape(),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 24.0),
                  activeTrackColor: getColor(value),
                  inactiveTrackColor: getColor(value).withOpacity(0.3),
                  thumbColor: getColor(value),
                ),
                child: Slider(
                  value: value,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: onChanged,
                  label: value.toStringAsFixed(0),
                ),
              ),
            ),
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> updateFirebaseStatus(CardModel card) async {
    if (documents.isNotEmpty) {
      final String selectedClass = documents[selectedClassIndex].id;

      final DocumentReference clientRef =
          FirebaseFirestore.instance.collection('personal').doc(selectedClass);

      Map<String, dynamic> cardData = {
        'disiplin': card.disiplin,
        'kerapihan': card.kerapihan,
        'sikap': card.sikap,
      };

      await clientRef.set(
        {card.title: cardData},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> fetchStatusFromFirebase() async {
    if (documents.isNotEmpty) {
      final String selectedClass = documents[selectedClassIndex].id;

      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('personal')
          .doc(selectedClass)
          .get();

      final Map<String, dynamic>? statusData =
          snapshot.data() as Map<String, dynamic>?;

      if (statusData != null) {
        for (CardModel card in cards) {
          final Map<String, dynamic>? cardData = statusData[card.title];
          if (cardData != null) {
            setState(() {
              card.disiplin = cardData['disiplin'] ?? 0.0;
              card.kerapihan = cardData['kerapihan'] ?? 0.0;
              card.sikap = cardData['sikap'] ?? 0.0;
            });
          }
        }
      }
    }
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
    });

    await fetchStatusFromFirebase();
  }

  Future<void> saveStatusToFirebase() async {
    if (documents.isNotEmpty) {
      final String selectedClass = documents[selectedClassIndex].id;

      final DocumentReference clientRef =
          FirebaseFirestore.instance.collection('personal').doc(selectedClass);

      Map<String, dynamic> statusData = {};

      for (CardModel card in cards) {
        statusData[card.title] = {
          'disiplin': card.disiplin,
          'kerapihan': card.kerapihan,
          'sikap': card.sikap,
        };
      }

      await clientRef.set(statusData, SetOptions(merge: true));

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
                    'Nilai kepribadian berhasil diperbarui',
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

      setState(() {});
    } else {
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

  List<CardModel> getFilteredCards() {
    return cards.where((card) {
      final lowercaseTitle = card.title.toLowerCase();
      final lowercaseSearchQuery = searchQuery.toLowerCase();
      return lowercaseTitle.contains(lowercaseSearchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isCardGenerated = cards.isNotEmpty;
    List<CardModel> filteredCards = getFilteredCards();

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
                'Nilai Personal',
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
                          return Colors.green; // bg hijau ketika ditekan
                        }
                        return Colors.white; // bg putih
                      },
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.green), // text hijau
                    side: MaterialStateProperty.all<BorderSide>(
                      const BorderSide(color: Colors.green), // border hijau
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
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    const Text(
                      'Kelas:  ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Pilih kelas dulu nggih',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCards.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildCard(filteredCards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
