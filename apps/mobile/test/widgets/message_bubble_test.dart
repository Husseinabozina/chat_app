import 'package:chat_app/widgets/chat/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message bubble renders sender and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: 'Hello there',
            isMine: false,
            username: 'Ahmed',
          ),
        ),
      ),
    );

    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('Hello there'), findsOneWidget);
  });
}
