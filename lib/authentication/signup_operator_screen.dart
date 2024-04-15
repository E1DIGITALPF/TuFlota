import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/authentication/login_operator_screen.dart';
import '../widgets/progress_dialog.dart';
import '../global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../mainScreens/operator_main_screen.dart';

class SignUpOperatorScreen extends StatefulWidget {
  @override
  _SignUpOperatorScreenState createState() => _SignUpOperatorScreenState();
}

class _SignUpOperatorScreenState extends State<SignUpOperatorScreen> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController idTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  validateForm() async {
    String id = idTextEditingController.text.trim();

    if (userNameTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "❌ El nombre de usuario es obligatorio");
    } else if (nameTextEditingController.text.length < 3) {
      Fluttertoast.showToast(msg: "❌ El nombre debe tener al menos tres caracteres");
    } else if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "❌ El correo no es válido");
    } else if (!RegExp(r'^[VE]\d+$').hasMatch(id)) {
      Fluttertoast.showToast(msg: "❗ La cédula de identidad debe comenzar con 'V' o 'E' seguido de números");
    } else if (phoneTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "❗ El número de teléfono es obligatorio");
    } else if (passwordTextEditingController.text.length < 6) {
      Fluttertoast.showToast(msg: "❗ La contraseña debe tener al menos 6 caracteres");
    } else {
      saveOperatorInfoNow();
    }
  }

  saveOperatorInfoNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(message: "Procesando. Espera...");
      },
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        String? token = await _firebaseMessaging.getToken();

        Map<String, dynamic> operatorMap = {
          "userId": firebaseUser.uid,
          "name": nameTextEditingController.text.trim(),
          "userName": userNameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "identity": idTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
          "userType": "operator",
          "isAdmin": false,
          "token": token,
        };

        await FirebaseFirestore.instance.collection("operators").doc(firebaseUser.uid).set(operatorMap);

        currentFirebaseUser = firebaseUser;
        Fluttertoast.showToast(msg: "✅ ¡La cuenta ha sido creada! ¡Bienvenido! 🥳");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => OperatorMainScreen()),
              (route) => false,
        );
      } else {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "😥 La cuenta no pudo ser creada. ¿Intentamos de nuevo?");
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Image.asset("images/TuFlota.png"),
              ),
              SizedBox(
                height: 10,
              ),
              const Text(
                "Regístrate como operador",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: nameTextEditingController,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Nombre",
                  hintText: "¿Cómo te llamas?",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              TextField(
                controller: userNameTextEditingController,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(
                  labelText: "Nombre de usuario",
                  hintText:
                  "Elige un nombre de usuario. Solo caracteres alfanuméricos.",
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
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "¿Cuál es tu correo electrónico?",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              TextField(
                controller: idTextEditingController,
                keyboardType: TextInputType.text,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Cédula de Identidad",
                  hintText: "Ingresa tu cédula de identidad (Ej. V14521452)",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              TextField(
                controller: phoneTextEditingController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Teléfono",
                  hintText: "Ingresa tu número móvil (Ej. 04125445454)",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              TextField(
                controller: passwordTextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  hintText:
                  "Coloca una contraseña para tu perfil (al menos seis caracteres)",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  validateForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  "Crear cuenta",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                child: Text(
                  "¿Ya tienes una cuenta? Inicia sesión aquí",
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => LoginOperatorScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}