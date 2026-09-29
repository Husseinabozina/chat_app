import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'messageBubble.dart';

class Message extends StatelessWidget {
  Message({super.key});
  final auth = FirebaseAuth.instance.currentUser;
  final userDocs = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.value(FirebaseAuth.instance.currentUser),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('chat')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              final chatdocs = chatSnapshot.data!.docs;
              return ListView.builder(
                  reverse: true,
                  itemCount: chatdocs.length,
                  itemBuilder: (context, index) => MessageBubble(
                        key: ValueKey(chatdocs[index].id),
                        imageurl: chatdocs[index]['userImage'],
                        message: chatdocs[index]['text'],
                        isme: snapshot.data!.uid == chatdocs[index]['userid'],
                        username: chatdocs[index]['username'],
                      ));
            },
          );
        });
  }
}
