import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/failures/app_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

final class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<List<ChatMessage>> watchMessages() async* {
    try {
      await for (final snapshot in _firestore
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        yield snapshot.docs
            .map(ChatMessageModel.fromFirestore)
            .map((model) => model.toEntity())
            .toList(growable: false);
      }
    } on FirebaseException catch (error) {
      throw _mapFirebaseFailure(error);
    } catch (error) {
      throw AppFailure(
        kind: FailureKind.unknown,
        debugMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.validation,
        debugMessage: 'Message cannot be empty.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const AppFailure(
        kind: FailureKind.unauthorized,
        debugMessage: 'A signed-in user is required to send messages.',
      );
    }

    try {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      final profile = userData.data();

      await _firestore.collection('chat').add({
        'text': message,
        'createdAt': Timestamp.now(),
        'userid': user.uid,
        'username': profile?['username'] ?? 'Unknown user',
        'userImage': profile?['imageUrl'],
      });
    } on FirebaseException catch (error) {
      throw _mapFirebaseFailure(error);
    } catch (error) {
      throw AppFailure(
        kind: FailureKind.unknown,
        debugMessage: error.toString(),
      );
    }
  }

  AppFailure _mapFirebaseFailure(FirebaseException error) {
    final kind = switch (error.code) {
      'permission-denied' ||
      'unauthenticated' => FailureKind.unauthorized,
      'invalid-argument' => FailureKind.validation,
      'already-exists' => FailureKind.conflict,
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => FailureKind.network,
      _ => FailureKind.unknown,
    };

    return AppFailure(
      kind: kind,
      debugMessage: error.code,
    );
  }
}
