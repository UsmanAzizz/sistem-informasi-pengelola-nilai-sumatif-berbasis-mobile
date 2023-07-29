import 'package:appmaster_1/downloadNilai.dart';
import 'package:appmaster_1/form_input_nilai.dart';
import 'package:appmaster_1/input_nilai_tugas.dart';
import 'package:appmaster_1/main.dart';
import 'package:appmaster_1/personal.dart';
import 'package:appmaster_1/superUser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

import 'PSAS.dart';
import 'PSTS.dart';
import 'Portofolio.dart';
import 'Praktek.dart';
import 'Produk.dart';
import 'absen.dart';

class MyApp extends StatelessWidget {
  final auth.User? user;

  const MyApp({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                title: FutureBuilder<DocumentSnapshot>(
                  future: auth.FirebaseAuth.instance
                      .authStateChanges()
                      .first
                      .then((user) {
                    if (user != null) {
                      return FirebaseFirestore.instance
                          .collection('admin')
                          .doc(user.uid)
                          .get();
                    } else {
                      throw ('User is not authenticated');
                    }
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else {
                      if (snapshot.hasError) {
                        return const Text('Error');
                      } else {
                        var nama = '';
                        if (snapshot.data != null && snapshot.data!.exists) {
                          var data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          nama = data != null && data.containsKey('nama')
                              ? data['nama'] ?? 'Nama tidak tersedia'
                              : 'Nama tidak tersedia';
                        } else {
                          nama = 'Nama tidak tersedia';
                        }
                        return Text(
                          nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Figtree',
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        );
                      }
                    }
                  },
                ),
                toolbarHeight: 60,
                elevation: 4,
                automaticallyImplyLeading: true,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(width: 0.4, color: Colors.black),
                ),
                iconTheme: const IconThemeData(
                  color: Colors.black,
                ),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.vpn_key_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuperUser(
                            user: user!,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              drawer: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Drawer(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            DrawerHeader(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [],
                                  ),
                                  const CircleAvatar(
                                    radius: 40,
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.only(
                                  left: 16.0, right: 20.0),
                              title: Row(
                                children: const [
                                  SizedBox(
                                    width: 24.0,
                                    child: Icon(
                                      Icons.assignment,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 10.0),
                                  Text(
                                    'Absen',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontFamily: 'Figtree',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AbsenPage(
                                      user: user!,
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                      ListTile(
                        title: Row(
                          children: const [
                            Icon(
                              Icons.exit_to_app,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return CupertinoAlertDialog(
                                title: const Text('Konfirmasi'),
                                actions: <Widget>[
                                  CupertinoDialogAction(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  CupertinoDialogAction(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Keluar',
                                      style: TextStyle(
                                        color: CupertinoColors.destructiveRed,
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          );
                        },
                        tileColor: Colors.transparent,
                      )
                    ],
                  ),
                ),
              ),
              body: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.only(top: 20, left: 7, right: 7),
                  childAspectRatio: 1.7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => AbsenPage(user: user!),
                            fullscreenDialog:
                                false, // Ubah nilai ini sesuai kebutuhan
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'Absen',
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              width: 0.05,
                              color: Colors.black,
                            ),
                          ),
                          color: Colors.white,
                          child: const ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 11),
                            title: Text(
                              'Absen',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Figtree',
                                fontSize: 19,
                              ),
                            ),
                            subtitle: Text(
                              'Absen pertemuan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Figtree',
                                fontSize: 10,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 24.0,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  IconlyBroken.timeCircle,
                                  size: 24,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => PersonalPage(user: user!),
                            fullscreenDialog:
                                false, // Ubah nilai ini sesuai kebutuhan
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'Individu',
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              width: 0.05,
                              color: Colors.black,
                            ),
                          ),
                          color: Colors.white,
                          child: const ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 11),
                            title: Text(
                              'Individu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Figtree',
                                fontSize: 19,
                              ),
                            ),
                            subtitle: Text(
                              'Set nilai individual',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Figtree',
                                fontSize: 10,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 24.0,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  IconlyBroken.profile,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => FormInputNilai(user: user!),
                            fullscreenDialog:
                                false, // Ubah nilai ini sesuai kebutuhan
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'formInputNilai',
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              width: 0.05,
                              color: Colors.black,
                            ),
                          ),
                          color: Colors.white,
                          child: const ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16.5),
                            title: Text(
                              'Lingkup Materi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Figtree',
                                fontSize: 19,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 24.0,
                              height: 40,
                              child: Center(
                                child: Icon(
                                  IconlyBroken.calendar,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Hero(
                      tag: 'inputNilaiTugas',
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              width: 0.05, color: Colors.black),
                        ),
                        color: Colors.white,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              title: const Text(
                                'Tugas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 19,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: const Text(
                                'Input nilai tugas',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              trailing: const SizedBox(
                                width: 24.0,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    IconlyBroken.chart,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        InputNilaiTugas(user: user!),
                                    fullscreenDialog:
                                        false, // Ubah nilai ini sesuai kebutuhan
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Hero(
                      tag: 'inputNilaiPSTS',
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              width: 0.05, color: Colors.black),
                        ),
                        color: Colors.white,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              title: const Text(
                                'PSTS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 19,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: const Text(
                                'Input nilai tugas',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              trailing: const SizedBox(
                                width: 24.0,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    IconlyBroken.paper,
                                    color: Colors.lightGreen,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        InputNilaiPSTS(user: user!),
                                    fullscreenDialog:
                                        false, // Ubah nilai ini sesuai kebutuhan
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Hero(
                      tag: 'inputNilaiPSAS',
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              width: 0.05, color: Colors.black),
                        ),
                        color: Colors.white,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              title: const Text(
                                'PSAS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 19,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: const Text(
                                'Input nilai PSAS',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              trailing: const SizedBox(
                                width: 24.0,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    IconlyBold.paper,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        InputNilaiPSAS(user: user!),
                                    fullscreenDialog:
                                        false, // Ubah nilai ini sesuai kebutuhan
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Hero(
                      tag: 'inputNilaiPraktek',
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              width: 0.05, color: Colors.black),
                        ),
                        color: Colors.white,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              title: const Text(
                                'Praktek',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 19,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: const Text(
                                'Input nilai Praktek',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              trailing: const SizedBox(
                                width: 24.0,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    IconlyBold.filter,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        InputNilaiPraktek(user: user!),
                                    fullscreenDialog:
                                        false, // Ubah nilai ini sesuai kebutuhan
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Hero(
                      tag: 'inputNilaiProduk',
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              width: 0.05, color: Colors.black),
                        ),
                        color: Colors.white,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              title: const Text(
                                'Produk',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 19,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: const Text(
                                'Input nilai Produk',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              trailing: const SizedBox(
                                width: 24.0,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    IconlyBold.game,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        InputNilaiProduk(user: user!),
                                    fullscreenDialog:
                                        false, // Ubah nilai ini sesuai kebutuhan
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Hero(
                      tag: 'inputNilaiPortofolio',
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                              width: 0.05, color: Colors.black),
                        ),
                        color: Colors.white,
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              title: const Text(
                                'Portofolio',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 19,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: const Text(
                                'Input nilai Portofolio',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                              trailing: const SizedBox(
                                width: 24.0,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    Icons.square_foot,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        InputNilaiPortofolio(user: user!),
                                    fullscreenDialog:
                                        false, // Ubah nilai ini sesuai kebutuhan
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) =>
                                DownloadNilaiPage(user: user!),
                            fullscreenDialog:
                                false, // Ubah nilai ini sesuai kebutuhan
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'nilaiRapot',
                        child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  width: 0.05, color: Colors.black),
                            ),
                            color: Colors.white,
                            child: Stack(children: const [
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                title: Text(
                                  'Download Data Nilai',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Figtree',
                                    fontSize: 17,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  'Download nilai',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 24.0,
                                  height: 40,
                                  child: Center(
                                    child: Icon(
                                      IconlyLight.arrowDownSquare,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ])),
                      ),
                    )
                  ]),
            )));
  }
}
