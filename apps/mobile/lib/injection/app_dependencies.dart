import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../features/auth/data/repositories/firebase_auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/chat/data/repositories/firebase_chat_repository.dart';
import '../features/chat/domain/repositories/chat_repository.dart';

final class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.chatRepository,
  });

  factory AppDependencies.firebase() {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    return AppDependencies(
      authRepository: FirebaseAuthRepository(
        auth,
        firestore,
        FirebaseStorage.instance,
      ),
      chatRepository: FirebaseChatRepository(auth, firestore),
    );
  }

  final AuthRepository authRepository;
  final ChatRepository chatRepository;
}
