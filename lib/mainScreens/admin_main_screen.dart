import 'package:flutter/material.dart';
import '../tabpages/tools_tab.dart';
import '../tabpages/trucks_tab.dart';
import '../tabpages/profile_tab.dart';
import '../tabpages/home_tab.dart';
import '../tabpages/chat_tab.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: const DefaultTabController(
        length: 5,
        child: Scaffold(
          body: TabBarView(
            children: [
              HomeTab(isAdmin: true),
              TrucksTab(isAdmin: true),
              ToolsTab(isAdmin: true),
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
  runApp(const MaterialApp(
    home: AdminMainScreen(),
  ));
}
