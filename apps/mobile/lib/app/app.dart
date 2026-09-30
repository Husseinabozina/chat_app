import 'package:flutter/material.dart';

import '../features/auth/domain/entities/auth_user.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../injection/app_dependencies.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.orange,
      brightness: Brightness.light,
    ).copyWith(secondary: const Color.fromRGBO(212, 212, 133, 1));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat',
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: false),
      home: StreamBuilder<AuthUser?>(
        stream: dependencies.authRepository.watchAuthState(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasData) {
            return ChatPage(
              authRepository: dependencies.authRepository,
              chatRepository: dependencies.chatRepository,
            );
          }

          return AuthPage(authRepository: dependencies.authRepository);
        },
      ),
    );
  }
}
