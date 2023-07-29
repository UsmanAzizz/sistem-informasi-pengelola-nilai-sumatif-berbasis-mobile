import 'package:appmaster_1/DataAdmin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'DataMapel.dart';
import 'DataSiswa.dart';
import 'DownloadNilaiSiswa.dart';

void main() => runApp(
      MaterialApp(
        home: Scaffold(
          body: SuperUser(user: FirebaseAuth.instance.currentUser!),
        ),
      ),
    );

class SuperUser extends StatefulWidget {
  const SuperUser({Key? key, required User user}) : super(key: key);

  @override
  _SuperUserState createState() => _SuperUserState();
}

class _SuperUserState extends State<SuperUser>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isSuperAdmin = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this); // Update the length to 3 for the new tab
    checkSuperAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Waduh!'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sukses'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void checkSuperAdmin() async {
    User user = FirebaseAuth.instance.currentUser!;

    try {
      QuerySnapshot superAdminSnapshot =
          await FirebaseFirestore.instance.collection('superAdmin').get();

      print('User ID saat ini:${user.uid}');

      print('Semua dokumen pada koleksi "superAdmin":');
      superAdminSnapshot.docs.forEach((doc) {
        print('Document ID:${doc.id}');
        print('Data: ${doc.data()}');
      });

      if (superAdminSnapshot.size > 0) {
        bool isUserSuperAdmin = superAdminSnapshot.docs
            .any((doc) => doc.id.trim() == user.uid.trim());
        if (isUserSuperAdmin) {
          setState(() {
            isSuperAdmin = true;
            loading = false;
          });
        } else {
          setState(() {
            isSuperAdmin = false;
            loading = false;
          });

          _showErrorDialog('Anda bukan superadmin ;(');
        }
      } else {
        setState(() {
          isSuperAdmin = false;
          loading = false;
        });

        _showErrorDialog('Anda bukan superadmin :(');
      }
    } catch (e) {
      print('Error: $e');
    }
    print('Status isSuperAdmin: $isSuperAdmin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings),
              SizedBox(width: 8),
              Text('Super User'),
            ],
          ),
          backgroundColor: isSuperAdmin ? Colors.blue : Colors.red,
          elevation: 4,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Data Admin'),
              Tab(text: 'Data Mapel'),
              Tab(text: 'Data Siswa'),
            ],
          ),
        ),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : isSuperAdmin
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      const DataAdmin(),
                      const DataMapel(),
                      const DataSiswa(),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        const Text('Anda tidak memiliki akses ke halaman ini'),
                      ],
                    ),
                  ));
  }
}
