// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DataAdmin extends StatefulWidget {
  const DataAdmin({Key? key}) : super(key: key);

  @override
  _DataAdminState createState() => _DataAdminState();
}

class _DataAdminState extends State<DataAdmin> with TickerProviderStateMixin {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedKelas;
  bool showAddKelasDialog = false;
  bool showSuccessDialog = false;
  bool showAddAdminDialog = false;
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
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
            child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(
                              18.0), // Customize the padding as per your requirement
                          child: Text(
                            'Daftar Admin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(28, 8, 8, 8),
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                showAddAdminDialog = true;
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
                            child: const Text('+ Admin'),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      vsync: this,
                      duration: const Duration(milliseconds: 300),
                      child: showAddAdminDialog ? null : const SizedBox(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 500,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildAdminList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (showAddAdminDialog) // Add the "Tambah Admin" dialog as an overlay
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showAddAdminDialog = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    alignment: Alignment.center,
                    child: _buildAddAdminDialog(),
                  ),
                ),
              ),
          ],
        )));
  }

  TextEditingController AdminController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Widget _buildAddAdminDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: const Text('Tambah Admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: AdminController,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Nama Admin',
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

                    UIDController.text = uid;

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
            String namaAdmin = AdminController.text;
            String tokenUID = tokenUIDController.text;

            if (namaAdmin.isEmpty) {
              _showErrorDialog('Nama Admin tidak boleh kosong.');
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

            String docId = AdminController.text;
            await _addAdminToFirestore(
              docId,
              emailController.text,
              passwordController.text,
            );
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Sukses!'),
                  content: Text('Berhasil menambahkan $docId'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        AdminController.text = '';
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
            AdminController.text = '';
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
              showAddAdminDialog = false;
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

  Future<void> _addAdminToFirestore(
    String docId,
    String email,
    String password,
  ) async {
    String uid = UIDController.text;

    await firestore.collection('admin').doc(uid).set({
      'email': email,
      'password': password,
      'nama': docId,
    });
  }

  Widget _buildAdminList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('admin').snapshots(),
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

        final adminDocs = snapshot.data!.docs;
        if (adminDocs.isEmpty) {
          return const Center(child: Text('Belum ada data Admin'));
        }
        return ListView.separated(
          separatorBuilder: (context, index) => const Divider(),
          itemCount: adminDocs.length,
          itemBuilder: (context, index) {
            final docId = adminDocs[index].id;
            final data = adminDocs[index].data() as Map<String, dynamic>;
            String? namaAdmin = data['nama'] as String?;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ExpansionTile(
                title: Text(
                  namaAdmin ?? 'Nama Admin Tidak Diketahui',
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
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Pass  : ${data['password']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'uid     : $docId ',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                children: [
                  ListTile(
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black54),
                      onPressed: () => _showDeleteConfirmationDialog(docId),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus Admin ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _deleteAdmin(docId);
                  print('Admin deleted successfully');
                } catch (e) {
                  print('Error deleting admin: $e');
                }
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAdmin(String docId) async {
    await firestore.collection('admin').doc(docId).delete();
  }
}
