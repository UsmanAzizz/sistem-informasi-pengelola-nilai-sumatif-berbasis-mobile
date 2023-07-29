import 'dart:async';
import 'package:appmaster_1/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class AppUser {
  final String name;

  AppUser({required this.name});
}

class FormInputNilai extends StatefulWidget {
  final User user;

  const FormInputNilai({Key? key, required this.user}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _FormInputNilaiState createState() => _FormInputNilaiState();
}

class _FormInputNilaiState extends State<FormInputNilai> {
  List<String> kelasList = [];
  String selectedKelas = '';
  List<String> items = [];
  List<String> filteredItems = [];
  int batchSize = 10;
  bool isLoading = false;
  bool isSaving = false;
  TextEditingController searchController = TextEditingController();
  Map<String, List<bool>?> tpEnabledMap = {};
  Map<String, List<TextEditingController>> tpControllers = {};
  Map<String, List<TextField>> tpTextFields = {};

  TextEditingController nasController = TextEditingController();
  Map<String, bool> nasEnabledMap = {};
  Map<String, Map<String, List<String>>> stateMapelValues = {};
  bool isMapelSelected = false;
  int selectedMapelIndex = 0;
  Map<String, Map<String, List<String>>> nilaiSiswa = {};

  Map<String, bool> buildItemStateMap = {};
  String selectedClassName = '';
  Map<String, String> tpValueMap = {};
  String? selectedMapel;
  Map<String, TextEditingController?> nasControllers = {};
  Timer? _debounce;
  late SharedPreferences _preferences;
  @override
  void initState() {
    super.initState();
    loadMoreItems().then((_) {
      loadSharedPreferences();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
    tpControllers.forEach((name, controllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    });
  }

  List<bool> tpStatus = List.generate(9, (_) => false);

  void onTickSquarePressed(int index) {
    setState(() {
      tpStatus[index] = !tpStatus[index];
    });
  }

  Future<void> loadSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();

    for (final name in items) {
      final isEnabled = _preferences.getBool('tpEnabledMap_$name') ?? false;
      tpEnabledMap[name] = List.generate(9, (_) => isEnabled);

      final tpControllersList = tpControllers[name];
      if (tpControllersList != null) {
        for (int i = 0; i < tpControllersList.length; i++) {
          final tpValue = _preferences.getString('tpValueMap_$name$i') ?? '';
          tpControllersList[i].text = tpValue;
        }
      }

      final nasEnabled = _preferences.getBool('nasEnabledMap_$name') ?? false;
      nasEnabledMap[name] = nasEnabled;

      final nasValue = _preferences.getString('nasValueMap_$name') ?? '';
      nasControllers[name]?.text = nasValue;

      final mapelValues = _preferences.getStringList('mapelValues_$name');
      if (mapelValues != null) {
        stateMapelValues[name] = {
          'mapel': mapelValues,
        };
      }

      setState(() {});
    }
  }

  void updateBuildItemState(String name, bool isExpanded) {
    setState(() {
      buildItemStateMap[name] = isExpanded;
    });
  }

  Future<void> showKelasSelectionDialog() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final String userId = user.uid;

    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('client').get();

    final List<QueryDocumentSnapshot> documents = querySnapshot.docs
        .where((doc) =>
            doc.data() is Map<String, dynamic> &&
            (doc.data() as Map<String, dynamic>).containsKey(userId))
        .toList();

    // Build the list of class options
    final List<Widget> classOptions = documents
        .map((document) => CupertinoDialogAction(
              child: Text(
                document.id,
                style: const TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final selectedClassDocumentRef = FirebaseFirestore.instance
                    .collection('client')
                    .doc(document.id)
                    .collection('mapel');

                final QuerySnapshot selectedClassQuerySnapshot =
                    await selectedClassDocumentRef.get();

                final List<QueryDocumentSnapshot> mapelDocuments =
                    selectedClassQuerySnapshot.docs
                        .where((doc) =>
                            doc.data() is Map<String, dynamic> &&
                            (doc.data() as Map<String, dynamic>)
                                .containsKey(userId))
                        .toList();
                setState(() {
                  selectedClassName = document.id;
                });
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                loadMoreItems();
                // ignore: use_build_context_synchronously
                showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoAlertDialog(
                      title: const Text(
                        'Pilih Mapel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: mapelDocuments.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (BuildContext context, int index) {
                            final mapelDocument = mapelDocuments[index];
                            return CupertinoDialogAction(
                              child: Text(
                                mapelDocument.id,
                                style: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedClassName = document.id;
                                  Navigator.pop(context);
                                  selectedMapelIndex = index;
                                  selectedMapel = mapelDocument.id;
                                  isMapelSelected = true;
                                  selectedMapelIndex =
                                      mapelDocuments.indexOf(mapelDocument);
                                  // selectedMapelIndex = mapelDocuments.indexOf(
                                  //     mapelDocument);
                                  loadMoreItems();
                                });
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: CupertinoColors.systemRed),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ))
        .toList();

    // ignore: use_build_context_synchronously
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Pilih Kelas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            height: 200,
            child: ListView.separated(
              itemCount: classOptions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (BuildContext context, int index) {
                return classOptions[index];
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Cancel',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> loadMoreItems() async {
    setState(() {
      isLoading = true;
    });

    if (selectedClassName.isNotEmpty) {
      final QuerySnapshot querySnapshot = await firestore
          .collection('client')
          .doc(selectedClassName)
          .collection('siswa')
          .get();

      final List<QueryDocumentSnapshot> documents = querySnapshot.docs;

      List<String> studentNames = documents.map((doc) => doc.id).toList();

      setState(() {
        nilaiSiswa = {};
        items = studentNames;
        filteredItems = items;
        isLoading = false;

        for (final name in items) {
          tpControllers[name] = List.generate(
            8,
            (index) => TextEditingController(),
          );

          final bool isEnabled =
              (_preferences.getBool('tpEnabledMap_$name') ?? false);
          tpEnabledMap[name] = List.generate(9, (_) => isEnabled);

          updateNASValue(name);
        }
      });

      loadSharedPreferences();
      for (final name in items) {
        final mapelValues = _preferences.getStringList('mapelValues_$name');
        if (mapelValues != null) {
          nilaiSiswa[name]!['mapel'] = mapelValues;
        }
      }
    } else {
      setState(() {
        items = [];
        filteredItems = [];
        isLoading = false;
      });
    }
  }

  void updateNASValue(String cardName) {
    final tpControllersList = tpControllers[cardName];
    if (tpControllersList != null && mounted) {
      int tpCount = 0;
      int tpSum = 0;
      List<String> mapelValues = [];

      for (final tpController in tpControllersList) {
        if (tpController.text.isNotEmpty) {
          final tpValue = tpController.text;
          tpCount++;
          tpSum += int.tryParse(tpValue) ?? 0;
          mapelValues.add(tpValue);
        }
      }

      final nasValue = tpCount > 0 ? (tpSum / tpCount).toStringAsFixed(0) : '';

      if (mounted) {
        setState(() {
          stateMapelValues[cardName] = {'mapel': mapelValues};
          nilaiSiswa[cardName] =
              Map<String, List<String>>.from(stateMapelValues[cardName]!);

          nasControllers[cardName]?.text = nasValue;
          stateMapelValues[cardName] = {'mapel': mapelValues};
          nilaiSiswa[cardName] = stateMapelValues[cardName]!;
          tpEnabledMap[cardName] = tpStatus;
        });
      }
    }
  }

  void searchItems(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 0), () {
      final List<String> matchedItems = items
          .where(
              (name) => name.toLowerCase().contains(query.toLowerCase().trim()))
          .toList();

      setState(() {
        filteredItems = matchedItems;
      });
    });
  }

  bool isTextFieldEnabled(String name, int index) {
    if (index == 0) {
      return true;
    } else if (index == 8) {
      return nasEnabledMap[name] ?? false;
    } else {
      final previousIndex = index - 1;
      final previousValue = tpControllers[name]![previousIndex].text;
      if (previousValue.isNotEmpty) {
        for (final entry in tpEnabledMap.entries) {
          entry.value![index] = true;
        }
        return true;
      } else {
        final isAnyPreviousFilled = tpControllers.entries
            .any((entry) => entry.value[previousIndex].text.isNotEmpty);
        return isAnyPreviousFilled ||
            tpControllers[name]![index].text.isNotEmpty;
      }
    }
  }

  void _updateMapelValues(String name) {
    final updatedMapelValues =
        tpControllers[name]!.map((controller) => controller.text).toList();
    stateMapelValues[name]!['mapel'] = updatedMapelValues;

    final mapelValues = stateMapelValues[name]!['mapel'];
    if (mapelValues != null) {
      for (final entry in tpValueMap.entries) {
        // ignore: unnecessary_string_interpolations
        if (entry.key.startsWith('$name')) {
          final index = int.parse(entry.key.split('_')[1]);
          tpValueMap[entry.key] = mapelValues[index];
        }
      }
    }
  }

  void updateTpEnabled(String name, int index, bool enabled) async {
    setState(() {
      tpEnabledMap[name]![index] = enabled;
      if (index == 8) {
        nasEnabledMap[name] = enabled;
        if (enabled) {
          updateNASValue(name);
        } else {
          nasControllers[name]?.clear();
        }
      } else {
        updateNASValue(name);
      }
      _updateMapelValues(name);

      tpStatus = tpEnabledMap[name]!;
    });

    await saveSharedPreferences();
    updateNASValue(name);
  }

  Future<void> saveSharedPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    for (final name in items) {
      await preferences.setBool('tpEnabledMap_$name', tpEnabledMap[name]![0]);

      final tpControllersList = tpControllers[name];
      if (tpControllersList != null) {
        for (int i = 0; i < tpControllersList.length; i++) {
          final tpValue = tpControllersList[i].text;
          await preferences.setString('tpValueMap_$name$i', tpValue);
          await preferences.setString('tpValueMap_$name$i', tpValue);
          await preferences.setStringList(
              'mapelValues_$name', nilaiSiswa[name]!['mapel']!);
        }
      }
      _updateMapelValues(name);

      final mapelValues = stateMapelValues[name]!['mapel'];
      if (mapelValues != null) {
        await preferences.setStringList('mapelValues_$name', mapelValues);
      }
    }
  }

  void updateHintText(String name, int index, String hintText) {
    setState(() {
      tpTextFields.putIfAbsent(
          name, () => List.generate(9, (_) => const TextField()));
      final textFieldList = tpTextFields[name];
      final tpController = tpControllers[name]![index];

      final updatedDecoration = InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: tpStatus[index] ? Colors.grey[200] : Colors.grey[100],
        ),
      );

      final newTextField = TextField(
        controller: tpController,
        decoration: updatedDecoration,
        onChanged: (value) {
          tpController.text = value;
          updateTpEnabled(name, index, value.isNotEmpty);
          updateMapelValue(name, index, value); // Add this line
        },
      );

      textFieldList![index] = newTextField;
    });
  }

  void updateMapelValue(String name, int index, String value) {
    if (stateMapelValues.containsKey(name)) {
      final mapelValues = stateMapelValues[name];
      if (mapelValues != null) {
        mapelValues['mapel']![index] = value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildItem(BuildContext context, int index, String name,
        Function updateBuildItemState) {
      // ignore: unused_local_variable
      Color hintTextColor = Colors.grey;
      if (!isMapelSelected) {
        return const SizedBox.shrink();
      }
      if (index >= filteredItems.length) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return const SizedBox.shrink();
      }

      final name = filteredItems[index];
      final bool isSelectedItem = name == selectedClassName;

      if (isSelectedItem) {}
      Divider;
      return Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 2, 4),
        child: Stack(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(3, 17, 5, 0),
              color: Colors.white10,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
                side: const BorderSide(
                  width: 0.3,
                ),
              ),
              child: ListTile(
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(
                      9,
                      (subIndex) {
                        final controller = subIndex < 8 &&
                                tpControllers[name]!.length > subIndex
                            ? tpControllers[name]![subIndex]
                            : nasControllers[name] ??= TextEditingController();

                        final isTpField = subIndex < 8;
                        return SizedBox(
                          width: 34.8,
                          height: 28,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 0.6),
                            child: Container(
                              height: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 0.25,
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  hintColor: Colors.black54,
                                  inputDecorationTheme:
                                      const InputDecorationTheme(
                                    border: InputBorder.none,
                                  ),
                                ),
                                child: TextFormField(
                                  enabled: isTextFieldEnabled(name, subIndex),
                                  readOnly: !isTpField,
                                  controller: controller,
                                  cursorColor: Colors.black,
                                  cursorWidth: 1,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blueGrey,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.fromLTRB(0.5, 0, 0, 0),
                                    isDense: true,
                                    prefix: const SizedBox(width: 1),
                                    hintText:
                                        isTpField ? 'TP${subIndex + 1}' : 'NAS',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    counterText: '',
                                  ),
                                  maxLength: 3,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
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
                                  onChanged: (value) {
                                    updateTpEnabled(
                                        name, index, value.isNotEmpty);
                                    if (value.isNotEmpty) {
                                      final tpValue = int.tryParse(value);
                                      if (tpValue != null &&
                                          tpValue >= 0 &&
                                          tpValue <= 100) {
                                        updateTpEnabled(name, subIndex, true);
                                      } else {
                                        updateTpEnabled(name, subIndex, false);
                                      }
                                    } else {
                                      updateTpEnabled(name, subIndex, false);
                                    }

                                    tpControllers[name]![subIndex] = controller;

                                    if (subIndex < 8) {
                                      updateNASValue(name);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 7.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 0.4, color: Colors.white),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 2.5),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                      );

                      textPainter.layout();

                      return SizedBox(
                        width: null,
                        height: 24,
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(17),
            bottomRight: Radius.circular(17),
          ),
          side: BorderSide(width: 0.4, color: Colors.black),
        ),
        title: Row(
          children: const [
            Text(
              '  LINGKUP MATERI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Figtree',
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showKelasSelectionDialog();
            },
            icon: const Padding(
              padding: EdgeInsets.only(right: 0.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  IconlyBroken.arrowRightSquare,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
            splashRadius: 20,
            splashColor: Colors.red,
            highlightColor: Colors.red.withOpacity(0.5),
            tooltip: 'Pilih Kelas',
          ),
          IconButton(
            onPressed: () {
              showKelasSelectionDialog();
            },
            icon: const Padding(
              padding: EdgeInsets.only(right: 0.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  IconlyBroken.paper,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ),
            splashRadius: 20,
            highlightColor: Colors.blue.withOpacity(0.5),
            tooltip: 'Pilih Kelas',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                isSaving = true;
              });

              Future.delayed(const Duration(milliseconds: 1700), () {
                setState(() {
                  isSaving = false;
                });
              });
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: isSaving
                  ? const SizedBox(
                      key: ValueKey('progress'),
                      width: 45,
                      height: 45,
                      child: SpinKitRipple(
                        color: Colors.white,
                        size: 100,
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.only(right: 0.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          IconlyLight.tickSquare,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ),
            ),
            splashRadius: 20,
            highlightColor: Colors.green.withOpacity(0.5),
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            child: Row(
              children: [
                const Padding(padding: EdgeInsets.fromLTRB(20, 0, 2, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(padding: EdgeInsets.fromLTRB(0, 0, 2, 0)),
                      Text(
                        'Kelas: $selectedClassName',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Text(
                        'Mapel: ${selectedMapel ?? "Belum ditentukan"}',
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 35,
                  width: 160,
                  margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.black,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(padding: EdgeInsets.fromLTRB(10, 0, 0, 0)),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Cari Siswa',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.5),
                            suffixIcon: Icon(
                              Icons.search,
                              color: Colors.black54,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                          onChanged: (value) {
                            searchItems(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 0.3,
            color: Colors.grey,
          ),
          Expanded(
              child: ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (BuildContext context, int index) {
              final name = filteredItems[index];
              return buildItem(context, index, name, updateBuildItemState);
            },
          )),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return FormInputNilai(user: snapshot.data!);
        } else {
          return const LoginPage();
        }
      },
    ),
  ));
}
