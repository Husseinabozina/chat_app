import 'package:chat_app3/widgets/chat/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class MessageBubble extends StatelessWidget {
  String? message;
  bool? isme;
  final Key? key;
  final String? username;
  String? imageurl;
  MessageBubble(
      {this.message, this.isme, this.key, this.username, this.imageurl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment:
              isme! ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              width: 150,
              decoration: BoxDecoration(
                  color: isme! ? Colors.grey : Theme.of(context).accentColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft:
                          isme! ? Radius.circular(12) : Radius.circular(0),
                      bottomRight:
                          !isme! ? Radius.circular(12) : Radius.circular(0))),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                children: [
                  Text(
                    username!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: isme! ? TextAlign.end : TextAlign.start,
                  ),
                  Text(message!),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: isme! ? -250 : null,
          top: -5,
          left: isme! ? -200 : 130,
          child: CircleAvatar(
            backgroundImage: NetworkImage(
              imageurl!,
            ),
          ),
        ),
      ],
      clipBehavior: Clip.none,
    );
  }
}
