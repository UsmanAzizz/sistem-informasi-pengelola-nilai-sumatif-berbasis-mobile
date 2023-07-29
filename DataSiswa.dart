// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DataSiswa extends StatefulWidget {
  const DataSiswa({Key? key}) : super(key: key);

  @override
  _DataSiswaState createState() => _DataSiswaState();
}

class _DataSiswaState extends State<DataSiswa> with TickerProviderStateMixin {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedKelas;
  bool showAddKelasDialog = false;
  bool showSuccessDialog = false;
  bool showAddSiswaDialog = false;
  bool isGeneratingUid = false;
  bool _passwordVisible = false;
  // ignore: non_constant_identifier_names
  TextEditingController UIDController = TextEditingController();
  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  TextEditingController tokenUIDController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKelasDropdown(),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              showAddKelasDialog = true;
                              showAddSiswaDialog = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            primary: Colors.blue, // Change button text color
                            side: const BorderSide(
                                color: Colors.blue), // Add border
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Add rounded corners
                            ),
                          ),
                          child: const Text('+ Kelas'),
                        ),
                        const SizedBox(width: 16),
                        if (selectedKelas != null)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                showAddSiswaDialog = true;
                                showAddKelasDialog = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              primary: Colors.green, // Change button text color
                              side: const BorderSide(
                                  color: Colors.green), // Add border
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    8), // Add rounded corners
                              ),
                            ),
                            child: const Text('+ Siswa'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    AnimatedSize(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                      child: showAddKelasDialog ? null : const SizedBox(),
                    ),
                    AnimatedSize(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                      child: showAddSiswaDialog ? null : const SizedBox(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 450,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildSiswaList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showAddKelasDialog)
          Container(
            color: Colors.black54,
            child: Center(child: _buildAddKelasDialog()),
          ),
        if (showAddSiswaDialog)
          Container(
            color: Colors.black54,
            child: Center(child: _buildAddSiswaDialog()),
          ),
      ],
    );
  }

  Widget _buildKelasDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
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
                return const CircularProgressIndicator(
                  color: Colors.white,
                );
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
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddKelasDialog() {
    TextEditingController kelasController = TextEditingController();

    void showAlertDialog(String message) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Peringatan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    return AlertDialog(
      title: const Text('Tambah Kelas'),
      content: TextField(
        controller: kelasController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.home, color: Colors.grey, size: 24),
          labelText: 'Nama Kelas',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 1.0,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (kelasController.text.trim().isEmpty) {
              showAlertDialog('Nama kelas tidak boleh kosong!');
            } else {
              String docId = '';
              await _addKelasToFirestore(kelasController.text, docId);
              setState(() {
                showSuccessDialog = true;
                showAddKelasDialog = false;
              });
            }
          },
          child: const Text('Simpan +'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              showAddKelasDialog = false;
            });
          },
          child: const Text(
            'Batal',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  TextEditingController siswaController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Widget _buildAddSiswaDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: const Text('Tambah Siswa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: siswaController,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Nama Siswa',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: 20,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.grey[300] ?? Colors.grey, width: 1.0),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(
                  Icons.email,
                  color: Colors.grey[600],
                  size: 20,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.grey[300] ?? Colors.grey, width: 1.0),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              keyboardType: TextInputType.number,
              controller: passwordController,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(
                  Icons.lock,
                  color: Colors.grey[600],
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  child: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.grey[300] ?? Colors.grey, width: 1.0),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              obscureText: !_passwordVisible,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String email = emailController.text;
              String password = passwordController.text;

              if (email.isEmpty) {
                _showErrorDialog('Email tidak boleh kosong.');
                return;
              }
              if (!isEmailValid(email)) {
                Fluttertoast.showToast(
                  msg: 'Email tidak valid, silahkan gunakan email yang valid.',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                );
                return;
              }
              if (password.isEmpty) {
                _showErrorDialog('Password tidak boleh kosong.');
                return;
              }

              if (password.length < 6) {
                _showErrorDialog(
                    'Password minimal harus terdiri dari 6 karakter.');
                return;
              }

              try {
                List<String> signInMethods = await FirebaseAuth.instance
                    .fetchSignInMethodsForEmail(email);

                setState(() {
                  isGeneratingUid = true;
                });

                if (signInMethods.isNotEmpty) {
                  Fluttertoast.showToast(
                    msg: 'Email sudah terdaftar, silahkan gunakan email lain.',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                  );
                } else {
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  if (userCredential.user != null) {
                    String uid = userCredential.user!.uid;
                    UIDController.text = uid; // Set UID to UIDController
                    tokenUIDController.text =
                        uid; // Set UID to tokenUIDController

                    setState(() {
                      showSuccessDialog = true;
                    });
                  }
                }

                setState(() {
                  isGeneratingUid = false;
                });
              } catch (e) {
                print('Error checking email existence: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isGeneratingUid)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                if (!isGeneratingUid)
                  const Text(
                    'Generate UID',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: UIDController,
              readOnly: true,
              style: const TextStyle(color: Colors.black, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Token UID',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: Colors.grey[600],
                  size: 20,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                hintStyle: TextStyle(color: Colors.grey[600]),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            String email = emailController.text;
            String password = passwordController.text;
            String namaSiswa = siswaController.text;
            String tokenUID = tokenUIDController.text;

            if (namaSiswa.isEmpty) {
              _showErrorDialog('Nama Siswa tidak boleh kosong.');
              return;
            }

            if (email.isEmpty) {
              _showErrorDialog('Email tidak boleh kosong.');
              return;
            }
            if (!isEmailValid(email)) {
              Fluttertoast.showToast(
                msg: 'Email tidak valid, silahkan gunakan email yang valid.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
              return;
            }

            if (password.isEmpty) {
              _showErrorDialog('Password tidak boleh kosong.');
              return;
            }
            if (tokenUID.isEmpty) {
              _showErrorDialog('Token UID tidak boleh kosong.');
              return;
            }

            String docId = siswaController.text;
            await _addSiswaToFirestore(
              docId,
              emailController.text,
              passwordController.text,
            );
            // ignore: use_build_context_synchronously
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Sukses!'),
                  content:
                      Text('Berhasil menambahkan $docId pada $selectedKelas'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        siswaController.text = '';
                        emailController.text = '';
                        passwordController.text = '';
                        UIDController.text = '';

                        setState(() {
                          showSuccessDialog = false;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text('Simpan+'),
        ),
        TextButton(
          onPressed: () {
            // Reset the form fields inside the dialog

            emailController.text = '';
            passwordController.text = '';
            UIDController.text = '';
            tokenUIDController.text = '';
            setState(() {
              showSuccessDialog = false;
            });
          },
          child: const Text('Reset Form'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              showAddSiswaDialog = false;
            });
          },
          child: const Text(
            'Batal',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSiswaToFirestore(
    String docId,
    String email,
    String password,
  ) async {
    if (selectedKelas == null || docId.isEmpty) {
      return;
    }

    String uid = UIDController.text;

    await firestore
        .collection('client')
        .doc(selectedKelas!)
        .collection('siswa')
        .doc(docId)
        .set({
      'email': email,
      'password': password,
      'UID': uid,
    });
  }

  Widget _buildSiswaList() {
    if (selectedKelas == null) {
      return const Center(child: Text('Pilih kelas dulu'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('client')
          .doc(selectedKelas!)
          .collection('siswa')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            color: Colors.white,
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Data tidak ditemukan.'));
        }

        final siswaDocs = snapshot.data!.docs;
        if (siswaDocs.isEmpty) {
          return const Center(
              child: Text('Belum ada data siswa untuk kelas ini.'));
        }
        return ListView.separated(
          separatorBuilder: (context, index) => const Divider(),
          itemCount: siswaDocs.length,
          itemBuilder: (context, index) {
            final docId = siswaDocs[index].id;
            final data = siswaDocs[index].data() as Map<String, dynamic>;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                title: Text(
                  docId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Email : ${data['email']}',
                      style: const TextStyle(color: Colors.black45),
                    ),
                    Text(
                      'Pass  : ${data['password']}',
                      style: const TextStyle(color: Colors.black45),
                    ),
                    Text(
                      'uid: ${data['UID']}',
                      style: const TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(docId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addKelasToFirestore(String kelas, String docId) async {
    await firestore.collection('client').doc(kelas).set({
      'nama_kelas': kelas,
    });

    await firestore
        .collection('client')
        .doc(kelas)
        .collection('siswa')
        .doc(docId)
        .set({});
    await firestore.collection('client').doc(kelas).collection('mapel').add({});
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus siswa ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteSiswa(docId);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSiswa(String docId) async {
    if (selectedKelas == null) {
      return;
    }

    await firestore
        .collection('client')
        .doc(selectedKelas!)
        .collection('siswa')
        .doc(docId)
        .delete();
  }
}
