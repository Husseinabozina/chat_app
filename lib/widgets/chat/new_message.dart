import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class NewMessage extends StatefulWidget {
  const NewMessage();

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  String _enteredMessage = '';
  TextEditingController messageController = TextEditingController();

  final store = FirebaseFirestore.instance.collection('chat');
  void _sendmessage() async {
    FocusScope.of(context).unfocus();

    final user = await FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    store.add({
      'text': _enteredMessage,
      'createdAt': Timestamp.now(),
      'userid': user!.uid,
      'username': userData['username'],
      'userImage': userData['imageUrl']
    });
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              onChanged: (value) {
                setState(() {
                  _enteredMessage = value;
                });
              },
              decoration: InputDecoration(labelText: 'send a message...'),
            ),
          ),
          IconButton(
              onPressed: _enteredMessage.trim().isEmpty ? null : _sendmessage,
              icon: Icon(Icons.send))
        ],
      ),
    );
  }
}
