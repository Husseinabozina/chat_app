import 'package:chat_app3/widgets/chat/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/chat/new_message.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat'),
        actions: [
          DropdownButton(
              items: [
                DropdownMenuItem(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Icon(Icons.exit_to_app), Text('logout')],
                  ),
                  value: 'log out',
                ),
              ],
              onChanged: (ItemIdentifier) {
                if (ItemIdentifier == 'log out') {
                  FirebaseAuth.instance.signOut();
                }
              })
        ],
      ),
      body: Container(
        child: Column(
          children: [Expanded(child: Message()), NewMessage()],
        ),
      ),
    );
  }
}
