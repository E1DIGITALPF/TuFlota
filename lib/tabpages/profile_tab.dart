// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../global/global.dart';
import '../mainScreens/user_type_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _passwordController = TextEditingController();
  bool isAdmin = false;

  Future<String?> _showPasswordDialog() async {
    String? password;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirma tu identidad'),
          content: TextField(
            onChanged: (value) {
              password = value;
            },
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
            ),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                Navigator.pop(context, password);
              },
            ),
          ],
        );
      },
    );
    return password;
  }

  Future<void> _reauthenticateAndRetryUpdate() async {
    String email = fAuth.currentUser!.email!;

    String? password = await _showPasswordDialog();
    if (password == null) {
      return;
    }

    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);

    try {
      await fAuth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Contraseña incorrecta'),
        ));
        return;
      }
    }
    await _updateUserCredentials();
  }

  Future<void> _updateUserCredentials() async {
    try {
      await fAuth.currentUser!.updatePassword(_passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Datos actualizados exitosamente'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Error al actualizar los datos'),
      ));
    }
  }

  Future<void> _clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _checkUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isAdmin = prefs.getBool('isAdmin');
    if (isAdmin != null) {
      setState(() {
        this.isAdmin = isAdmin;
      });
    } else {
      String userId = fAuth.currentUser!.uid;
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        setState(() {
          this.isAdmin = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = FirebaseAuth.instance.currentUser;
    var email =
        currentUser != null ? currentUser.email : 'No hay usuario logueado';
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('👥 Perfil'),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: TextEditingController(text: email),
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Tu correo electrónico (no se puede cambiar):',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña nueva:',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _reauthenticateAndRetryUpdate,
                child: const Text('Actualizar contraseña'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar sesión'),
                onPressed: () async {
                  await _clearPreferences();
                  await fAuth.signOut();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const UserTypeSelectionScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
