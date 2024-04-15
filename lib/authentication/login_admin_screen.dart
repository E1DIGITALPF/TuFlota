// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../mainScreens/admin_main_screen.dart';
import '../widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authentication/signup_admin_screen.dart';

class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({Key? key}) : super(key: key);

  @override
  State<LoginAdminScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginAdminScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateForm() {
    if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "❌ El correo no es válido");
    } else if (passwordTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "❌ La contraseña no puede estar vacía");
    } else {
      loginAdminNow();
    }
  }

  loginAdminNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return const ProgressDialog(message: "Procesando. Espera...");
      },
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance.collection("admins")
            .doc(firebaseUser.uid)
            .get();

        if (adminSnapshot.exists) {
          bool isAdmin = adminSnapshot.get("isAdmin");

          if (isAdmin) {
            Fluttertoast.showToast(msg: "🥳 ¡Iniciaste sesión con éxito!");
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isAdminLoggedIn', true);
            await prefs.setBool('isOperatorLoggedIn', false);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainScreen()),
                  (Route<dynamic> route) => false,
            );
          } else {
            await FirebaseAuth.instance.signOut();
            Navigator.pop(context);
            Fluttertoast.showToast(msg: "❌ No puedes iniciar sesión como operador.");
          }
        } else {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "❌ No hay registro de administrador con este correo.");
        }
      } else {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "😥 Ha ocurrido un error. Intenta de nuevo.");
      }
    } catch (error) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "😥 Ha ocurrido un error. Intenta de nuevo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/TuFlota.png"),
              ),
              const SizedBox(height: 10),
              const Text(
                "Inicia sesión como administrador",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "¿Cuál es tu correo electrónico?",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              TextField(
                controller: passwordTextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  hintText: "Ingresa tu contraseña",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  validateForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  "Iniciar sesión",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                child: const Text(
                  "¿No tienes una cuenta? Crea una aquí 👈",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
