// ignore_for_file: library_private_types_in_public_api, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String userId;
  String userName = '';
  bool isAdmin = false;
  bool isUserInfoLoaded = false;
  bool isNewMessage = false;
  final ScrollController _scrollController = ScrollController();
  bool _showLegend = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;

      var userDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        setState(() {
          userName = userDoc.data()!['name'];
          isAdmin = true;
          isUserInfoLoaded = true;
        });
      } else {
        var operatorDoc = await FirebaseFirestore.instance
            .collection('operators')
            .doc(userId)
            .get();
        if (operatorDoc.exists && operatorDoc.data()?['name'] != null) {
          setState(() {
            userName = operatorDoc.data()!['name'];
            isAdmin = false;
            isUserInfoLoaded = true;
          });
        }
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= 50 &&
        _scrollController.position.userScrollDirection == AxisDirection.up) {
      if (_showLegend) {
        setState(() {
          _showLegend = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        AxisDirection.down) {
      if (!_showLegend) {
        setState(() {
          _showLegend = true;
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty && userName.isNotEmpty) {
      var messageData = {
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'isAdmin': isAdmin,
      };

      await FirebaseFirestore.instance
          .collection('globalChat')
          .add(messageData);
      _messageController.clear();
    }
  }

  void _deleteMessage(String messageId) async {
    if (isAdmin) {
      await FirebaseFirestore.instance
          .collection('globalChat')
          .doc(messageId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📢 Chat global'),
        ),
        body: Column(
          children: <Widget>[
            if (_showLegend)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "🔵 Operadores  🟡 Administradores  🔴 Sistema",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('globalChat')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<DocumentSnapshot> docs = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final Timestamp? timestamp =
                          doc['timestamp'] as Timestamp?;

                      return InkWell(
                        onLongPress:
                            isAdmin ? () => _deleteMessage(doc.id) : null,
                        child: Message(
                          text: doc['text'],
                          isMe: userId == doc['userId'],
                          userName: doc['userName'],
                          isAdmin: doc['isAdmin'] ?? false,
                          isSystemMessage: (doc.data() as Map<String, dynamic>)
                                  .containsKey('isSystemMessage')
                              ? doc['isSystemMessage']
                              : false,
                          timestamp: timestamp,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 70,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: isUserInfoLoaded
                            ? "🗨 Envía un mensaje..."
                            : "⌛ Cargando...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onSubmitted:
                          isUserInfoLoaded ? (_) => _sendMessage() : null,
                      enabled: isUserInfoLoaded,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: isUserInfoLoaded ? _sendMessage : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message extends StatelessWidget {
  final String text;
  final bool isMe;
  final String userName;
  final bool isAdmin;
  final bool isSystemMessage;
  final Timestamp? timestamp;

  const Message({super.key, 
    required this.text,
    required this.isMe,
    required this.userName,
    required this.isAdmin,
    required this.isSystemMessage,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    Color bubbleColor;
    Color textColor;

    if (isSystemMessage) {
      bubbleColor = Colors.red[500]!;
      textColor = Colors.white;
    } else if (isAdmin) {
      bubbleColor = Colors.amber;
      textColor = Colors.black87;
    } else if (isMe) {
      bubbleColor = Colors.blue[800]!;
      textColor = Colors.white;
    } else {
      bubbleColor = Colors.blue[600]!;
      textColor = Colors.white;
    }

    DateTime date = timestamp?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 10, right: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isSystemMessage)
            Padding(
              padding:
                  EdgeInsets.only(left: isMe ? 0 : 10, right: isMe ? 10 : 0),
              child: Text(
                userName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ChatBubble(
            clipper: ChatBubbleClipper1(
                type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble),
            alignment: isMe ? Alignment.topRight : Alignment.topLeft,
            margin: const EdgeInsets.only(top: 4),
            backGroundColor: bubbleColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy hh:mm a').format(date),
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
