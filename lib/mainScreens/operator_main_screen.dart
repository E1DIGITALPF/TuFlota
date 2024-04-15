import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tabpages/tools_tab.dart';
import '../tabpages/trucks_tab.dart';
import '../tabpages/profile_tab.dart';
import '../tabpages/home_tab.dart';
import '../tabpages/chat_tab.dart';

class OperatorMainScreen extends StatefulWidget {
  @override
  _OperatorMainScreenState createState() => _OperatorMainScreenState();
}

class _OperatorMainScreenState extends State<OperatorMainScreen> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      setState(() {
        isAdmin = userDoc.data()?['isAdmin'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          body: TabBarView(
            children: [
              HomeTab(),
              TrucksTab(isAdmin: isAdmin),
              ToolsTab(isAdmin: isAdmin),
              ChatScreen(),
              ProfileTab(),
            ],
          ),
          bottomNavigationBar: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Inicio'),
              Tab(icon: Icon(Icons.fire_truck), text: 'Camiones'),
              Tab(icon: Icon(Icons.build), text: 'Varios'),
              Tab(icon: Icon(Icons.chat), text: 'Chat'),
              Tab(icon: Icon(Icons.person), text: 'Perfil'),
            ],
            unselectedLabelColor: Colors.grey,
            labelColor: Colors.blue,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: EdgeInsets.all(5.0),
            indicatorColor: Colors.blue,
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: OperatorMainScreen(),
  ));
}
