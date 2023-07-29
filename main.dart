// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ),
  );
  runApp(const MaterialApp(home: LoginPage()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showClearButton = false;
  bool? _isAccountSaved = false;

  void _clearEmail() {
    setState(() {
      _emailController.clear();
      _showClearButton = false;
    });
  }

  void _onEmailChanged(String value) {
    setState(() {
      _emailController.text = value;
      _showClearButton = value.isNotEmpty;
      _isPasswordVisible = false;

      // Menetapkan posisi kursor di akhir teks
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<bool> _onBackPressed() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Apakah Anda ingin keluar dari aplikasi?'),
        actions: [
          ButtonBar(
            buttonAlignedDropdown: true,
            layoutBehavior: ButtonBarLayoutBehavior.constrained,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Keluar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    ).then((value) {
      if (value == true) {
        SystemNavigator.pop();
      }
      return value ?? false;
    });
  }

  Future<void> _saveAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);
    await prefs.setString('password', _passwordController.text);
  }

  Future<void> _loadAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');
    setState(() {
      _emailController.text = savedEmail ?? '';
      _passwordController.text = savedPassword ?? '';
      _isAccountSaved = savedEmail != null && savedPassword != null;
    });
  }

  Future<void> _loginWithEmailAndPassword() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {});
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      // ignore: duplicate_ignore
      if (user != null) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            final mainContext = context; // Store the main context in a variable

            return Center(
              child: CupertinoAlertDialog(
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseAuth.instance
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
                      return const CupertinoActivityIndicator();
                    } else {
                      if (snapshot.hasError) {
                        return const Text('Error', textAlign: TextAlign.center);
                      } else {
                        var nama = '';
                        if (snapshot.data != null && snapshot.data!.exists) {
                          var data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          nama = data != null && data.containsKey('nama')
                              ? data['nama'] ?? 'Nama tidak tersedia'
                              : 'Nama tidak tersedia';
                          '';
                        } else {
                          nama = 'Nama tidak tersedia';
                        }

                        return RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Selamat Datang, ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: '$nama!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Figtree',
                                  fontSize: 15,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                ),
                content: const Text(
                  'anda berhasil masuk',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushReplacement(
                        mainContext,
                        MaterialPageRoute(
                          builder: (context) => MyApp(user: user),
                        ),
                      );
                      _saveAccount();
                    },
                    isDefaultAction: true,
                    textStyle: const TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue,
                    ),
                    child: const Text('mulai sesi'),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // Handle error: User is null
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text('Login Gagal'),
              actions: [
                CupertinoDialogAction(
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
    } catch (e) {
      String errorMessage = '! WARNING ! [FATAL ERROR]';

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'email tidak terdaftar!';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Kesalahan password!';
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text(
              '[FAILED]',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
            content: Row(
              children: [
                const SizedBox(width: 8.0),
                Text(
                  errorMessage,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Summative Tracker ',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Copyright @ 2023 - sapibigar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 10.0,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _emailController,
                    onChanged: _onEmailChanged,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.grey[200], // Background color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(IconlyBroken.message,
                          color: Colors.grey[600]), // Custom icon color
                      suffixIcon: _emailController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: Colors.grey[600]), // Clear icon color
                              onPressed: _clearEmail,
                            )
                          : null,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                            color: Colors.red), // Error border color
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                            color:
                                Colors.red), // Error border color when focused
                      ),
                    ),
                    style: const TextStyle(fontSize: 18),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan email';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-.]+@([\w-]+.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.grey[200], // Background color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(IconlyLight.password,
                          color: Colors.grey[600]), // Custom icon color
                      suffixIcon: InkWell(
                        onTap: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey[600], // Visibility icon color
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                            color: Colors.red), // Error border color
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                            color:
                                Colors.red), // Error border color when focused
                      ),
                    ),
                    style: const TextStyle(fontSize: 18),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 0),
                  Row(
                    children: [
                      Theme(
                        data: ThemeData(
                          unselectedWidgetColor: const Color.fromARGB(
                              255, 216, 216, 217), // Set the checkbox color
                        ),
                        child: Checkbox(
                          value: _isAccountSaved ?? false,
                          onChanged: (value) {
                            setState(() {
                              _isAccountSaved = value ?? false;
                              _saveAccount(); // Simpan akun saat Checkbox diubah
                            });
                          },
                        ),
                      ),
                      const Text(
                        'Simpan akun',
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _loginWithEmailAndPassword();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isLoading)
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
