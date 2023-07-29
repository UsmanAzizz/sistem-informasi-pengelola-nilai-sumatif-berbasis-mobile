import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class DataMapel extends StatefulWidget {
  const DataMapel({Key? key}) : super(key: key);

  @override
  _DataMapelState createState() => _DataMapelState();
}

class _DataMapelState extends State<DataMapel> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedKelas;
  String? selectedMapel;
  List<String> mapelList = [];
  List<String> daftarCollection = [];
  String newMapelName = '';
  String selectedAdminId = '';
  String selectedAdminNama = '';

  List<String> selectedAdminNames = [];
  Set<String> selectedAdminIds = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
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
                    const SizedBox(height: 12),
                    const Text(
                      '  Kelas',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 11),
                    FutureBuilder<List<String>>(
                      future: fetchKelasData(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        List<String> kelasList = snapshot.data!;
                        return DropdownButtonFormField<String>(
                          value: selectedKelas,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.red), // Border color
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16), // Adjust the padding
                          ),
                          isExpanded: true,
                          icon: Icon(Icons
                              .arrow_drop_down), // Dropdown arrow icon color
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
                              fetchMapelData(newValue);
                            });
                          },
                        );
                      },
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
                    ElevatedButton(
                      onPressed: () {
                        _showNewMapelDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white, // Background color
                        onPrimary: Colors.blue, // Text color
                        side: BorderSide(color: Colors.blue), // Border color
                        padding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20), // Button padding
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10)), // Button border radius
                      ),
                      child: Text('+ mapel baru'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showTambahMapelDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white, // Background color
                        onPrimary: Colors.blue, // Text color
                        side: BorderSide(color: Colors.blue), // Border color
                        padding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20), // Button padding
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10)), // Button border radius
                      ),
                      child: Text('+ mapel $selectedKelas'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: mapelList.isEmpty
                ? const Center(
                    child: Text('Pilih kelas untuk menampilkan mapel'),
                  )
                : ListView.builder(
                    itemCount: mapelList.length,
                    itemBuilder: (context, index) {
                      String mapelName = mapelList[index];
                      return FutureBuilder<String>(
                        future: fetchPengampuData(mapelList[index]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              leading: const Icon(
                                Icons.description,
                                size: 35,
                              ),
                              title: Text(mapelList[index]),
                              subtitle: Text("Loading..."),
                              onTap: () {},
                              trailing: IconButton(
                                icon: Icon(Icons.waving_hand),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                      context, mapelList[index]);
                                },
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              leading: const Icon(
                                Icons.description,
                                size: 35,
                              ),
                              title: Text(mapelList[index]),
                              subtitle: Text("Error loading data"),
                              onTap: () {},
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                      context, mapelList[index]);
                                },
                              ),
                            );
                          } else {
                            return ExpansionTile(
                              leading: const Icon(
                                Icons.description,
                                size: 35,
                              ),
                              title: Text(mapelList[index]),
                              subtitle: Text("Pengampu: ${snapshot.data}"),
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _showDeleteConfirmation(
                                            context, mapelList[index]);
                                      },
                                      style: TextButton.styleFrom(
                                        primary: Colors.red,
                                      ),
                                      child: Text('Hapus'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        // Close the expansion tile when "Batal" is pressed
                                        Navigator.of(context).pop();
                                      },
                                      style: TextButton.styleFrom(
                                        primary: Colors.blue,
                                      ),
                                      child: Text('Batal'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Show a confirmation dialog before deleting the item.
  void _showDeleteConfirmation(BuildContext context, String mapel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Hapus mapel ini dari $selectedKelas?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteMapel(mapel);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // Delete the item from the list and Firestore.
  void _deleteMapel(String mapel) async {
    try {
      final docRef = firestore
          .collection('client')
          .doc(selectedKelas)
          .collection('mapel')
          .doc(mapel);

      await docRef.delete();

      setState(() {
        mapelList.remove(mapel);
      });

      print('Mapel berhasil dihapus dari Firebase.');
    } catch (e) {
      print('Error saat menghapus Mapel: $e');
    }
  }

  Future<List<String>> fetchKelasData() async {
    final snapshot = await firestore.collection('client').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> fetchKoleksiMapel() async {
    final snapshot = await firestore.collection('mapel').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> fetchMapelData(String? newValue) async {
    if (selectedKelas != null) {
      try {
        final snapshot = await firestore
            .collection('client')
            .doc(selectedKelas)
            .collection('mapel')
            .get();

        List<String> fetchedMapelList =
            snapshot.docs.map((doc) => doc.id).toList();
        setState(() {
          mapelList = fetchedMapelList;
        });
      } catch (e) {
        print('Error fetching mapel data: $e');
        setState(() {
          mapelList.clear();
        });
      }
    } else {
      setState(() {
        mapelList.clear();
      });
    }
  }

  Future<String> fetchPengampuData(String mapel) async {
    try {
      final docRef = firestore
          .collection('client')
          .doc(selectedKelas)
          .collection('mapel')
          .doc(mapel);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data()!;

        if (data.containsKey('nama')) {
          String pengampu = data['nama'];
          return pengampu;
        } else {
          return 'Belum ditentukan';
        }
      } else {
        return 'Belum ditentukann';
      }
    } catch (e) {
      print('Error fetching Pengampu data: $e');
      return 'N/A';
    }
  }

  void _showTambahMapelDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pilih mapel untuk ditambahkan ke $selectedKelas'),
          content: FutureBuilder<List<String>>(
            future: fetchKoleksiMapel(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              List<String> koleksiMapelList = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: koleksiMapelList.map((mapel) {
                  return ListTile(
                    title: Text(mapel),
                    onTap: () async {
                      Map<String, dynamic> mapelFields =
                          await fetchMapelFields(mapel);
                      _showMapelFieldsDialog(mapel, mapelFields);
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> fetchMapelFields(String mapel) async {
    try {
      final docRef = firestore.collection('mapel').doc(mapel);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data()!;
        return data;
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching Mapel fields: $e');
      return {};
    }
  }

  void _showMapelFieldsDialog(String mapel, Map<String, dynamic> mapelFields) {
    List<String> fields =
        mapelFields.keys.toList(); // Extract field names as a List

    String? selectedField; // Store the selected field name

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pilih pengampu untuk mapel $mapel $selectedKelas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: fields.map((field) {
                  return RadioListTile(
                    title: Text('${mapelFields[field]}'),
                    value: field,
                    groupValue: selectedField,
                    onChanged: (value) {
                      setState(() {
                        selectedField =
                            value as String; // Update the selected field
                      });
                    },
                  );
                }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedField != null) {
                      Map<String, dynamic> selectedFieldData = {
                        selectedField!: mapelFields[selectedField]
                      };

                      await tambahMapelKeKelas(mapel, selectedFieldData);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Close the previous dialog
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> tambahMapelKeKelas(
      String mapel, Map<String, dynamic> mapelFields) async {
    if (selectedKelas != null) {
      try {
        final docRef = firestore
            .collection('client')
            .doc(selectedKelas)
            .collection('mapel')
            .doc(mapel);

        // Format the field writing as 'UID: value, nama: value'
        Map<String, dynamic> formattedMapelFields = {};
        mapelFields.forEach((field, value) {
          formattedMapelFields['UID'] = field;
          formattedMapelFields['nama'] = mapelFields[field];
        });

        await docRef.set(formattedMapelFields);

        print('Mapel berhasil disimpan ke Firebase.');
      } catch (e) {
        print('Error tambah mapel ke kelas: $e');
      }
    }
  }

  void _showNewMapelDialog(BuildContext context) async {
    CollectionReference<Map<String, dynamic>> adminCollection =
        FirebaseFirestore.instance.collection('admin');

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await adminCollection.get();

    List<String> namaList =
        querySnapshot.docs.map((doc) => doc['nama'] as String).toList();
    List<String> uidList = querySnapshot.docs.map((doc) => doc.id).toList();

    if (uidList.isNotEmpty) {
      selectedAdminId = uidList[0];
    }

    showDialog(
      context: context,
      builder: (context) {
        String errorMessage = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(child: Text('Tambah mapel baru')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      newMapelName = value;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Nama Mapel',
                      prefixIcon: Icon(
                        Icons.school, // Add the icon before the hintText
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10.0, // Adjust the vertical padding
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showAdminSelectionDialog(
                          context, uidList, namaList, setState);
                    },
                    child: Text('Pilih Pengampu untuk mapel ini'),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: selectedAdminNames
                        .map(
                          (name) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(name),
                                deleteIcon: Icon(Icons.cancel),
                                onDeleted: () {
                                  setState(() {
                                    int index =
                                        selectedAdminNames.indexOf(name);
                                    selectedAdminIds.remove(
                                      selectedAdminIds.elementAt(index),
                                    );
                                    selectedAdminNames.remove(name);
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (newMapelName.trim().isEmpty) {
                      setState(() {
                        errorMessage = 'Nama Mapel tidak boleh kosong.';
                      });
                    } else {
                      _saveMapelToFirebase(
                        newMapelName,
                        selectedAdminIds.toList(),
                        selectedAdminNames,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Simpan'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdminSelectionDialog(
    BuildContext context,
    List<String> uidList,
    List<String> namaList,
    StateSetter parentSetState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(
                child: Text('Pilih Guru Pengampu'),
              ),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uidList.length,
                  itemBuilder: (context, index) {
                    String uid = uidList[index];
                    String nama = namaList[index];

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Checkbox(
                          value: selectedAdminIds.contains(uid),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value ?? false) {
                                selectedAdminIds.add(uid);
                                selectedAdminNames.add(nama);
                              } else {
                                selectedAdminIds
                                    .remove(uid); // Safely remove uid
                                selectedAdminNames
                                    .remove(nama); // Safely remove nama
                              }
                            });
                          },
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nama,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Call the parentSetState to update the state in _showNewMapelDialog
                    parentSetState(() {
                      // Update the selectedAdminNames and selectedAdminIds directly
                      selectedAdminNames = List.from(selectedAdminNames);
                      selectedAdminIds = Set.from(selectedAdminIds);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleAdminButtonPressed(
      List<String> selectedAdminIds, List<String> selectedAdminNames) {
    // Implement the logic for the button press here
    // For example, you can do something with the selected teachers
    // when the 'OK' button is pressed.
    for (int i = 0; i < selectedAdminIds.length; i++) {
      print('Selected Admin ID: ${selectedAdminIds[i]}');
      print('Selected Admin Name: ${selectedAdminNames[i]}');
    }
  }

  void _saveMapelToFirebase(String mapelName, List<String> selectedAdminIds,
      List<String> selectedAdminNames) async {
    // Get the 'mapel' collection reference
    CollectionReference<Map<String, dynamic>> mapelCollection =
        FirebaseFirestore.instance.collection('mapel');

    try {
      Map<String, dynamic> data = {}; // Initialize the data map here

      // Add selected admins to the 'data' map
      for (int i = 0; i < selectedAdminIds.length; i++) {
        data[selectedAdminIds[i]] = selectedAdminNames[i];
      }

      await mapelCollection.doc(mapelName).set(data);

      print('Mapel berhasil disimpan ke Firebase.');
    } catch (e) {
      print('Error saat menyimpan Mapel: $e');
    }
  }
}
