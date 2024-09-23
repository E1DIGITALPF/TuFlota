// ignore_for_file: prefer_const_declarations

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'mainScreens/user_type_selection_screen.dart';
import 'authentication/login_admin_screen.dart';
import 'authentication/login_operator_screen.dart';
import 'mainScreens/operator_main_screen.dart';
import 'mainScreens/admin_main_screen.dart';
import 'tabpages/trucks_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Error initializing Firebase: $e");

    final configString = await rootBundle.loadString('web/config.json');
    final config = jsonDecode(configString);

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config['FIREBASE_API_KEY'],
        authDomain: config['FIREBASE_AUTH_DOMAIN'],
        projectId: config['FIREBASE_PROJECT_ID'],
        storageBucket: config['FIREBASE_STORAGE_BUCKET'],
        messagingSenderId: config['FIREBASE_MESSAGING_SENDER_ID'],
        appId: config['FIREBASE_APP_ID'],
      ),
    );
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MyApp({super.key});

  Future<bool> isOperatorLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isOperatorLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TuFlota',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: FutureBuilder<bool>(
        future: isOperatorLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              bool isOperatorLoggedIn = snapshot.data!;
              if (isOperatorLoggedIn) {
                return const OperatorMainScreen();
              } else {
                return const UserTypeSelectionScreen();
              }
            }
          } else {
            return const SplashScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/userTypeSelection': (context) => const UserTypeSelectionScreen(),
        '/loginAdmin': (context) => const LoginAdminScreen(),
        '/loginOperator': (context) => const LoginOperatorScreen(),
        '/operatorMainScreen': (context) => const OperatorMainScreen(),
        '/adminMainScreen': (context) => const AdminMainScreen(),
        '/trucksTab': (context) => const TrucksTab(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
