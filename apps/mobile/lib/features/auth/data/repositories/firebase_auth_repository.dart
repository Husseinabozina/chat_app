import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/failures/app_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _auth = auth,
       _firestore = firestore,
       _storage = storage;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> watchAuthState() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String profileImagePath,
  }) async {
    User? createdUser;
    Reference? imageReference;
    var imageUploaded = false;

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = result.user;
      if (createdUser == null) {
        throw const AppFailure(
          kind: FailureKind.unknown,
          debugMessage: 'Firebase returned no user after registration.',
        );
      }

      imageReference = _storage
          .ref()
          .child('User_Image')
          .child('${createdUser.uid}.jpg');

      await imageReference.putFile(File(profileImagePath));
      imageUploaded = true;

      final imageUrl = await imageReference.getDownloadURL();

      await _firestore.collection('users').doc(createdUser.uid).set({
        'username': username,
        'email': email,
        'imageUrl': imageUrl,
      });
    } on AppFailure {
      rethrow;
    } on FirebaseException catch (error) {
      await _rollbackRegistration(
        user: createdUser,
        imageReference: imageUploaded ? imageReference : null,
      );
      throw _mapFirebaseFailure(error);
    } catch (error) {
      await _rollbackRegistration(
        user: createdUser,
        imageReference: imageUploaded ? imageReference : null,
      );
      throw AppFailure(
        kind: FailureKind.unknown,
        debugMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseException catch (error) {
      throw _mapFirebaseFailure(error);
    } catch (error) {
      throw AppFailure(
        kind: FailureKind.unknown,
        debugMessage: error.toString(),
      );
    }
  }

  Future<void> _rollbackRegistration({
    required User? user,
    required Reference? imageReference,
  }) async {
    if (imageReference != null) {
      try {
        await imageReference.delete();
      } catch (_) {}
    }

    if (user != null) {
      try {
        await user.delete();
      } catch (_) {}
    }
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(id: user.uid, email: user.email);
  }

  AppFailure _mapFirebaseFailure(FirebaseException error) {
    final kind = switch (error.code) {
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' ||
      'user-disabled' => FailureKind.unauthorized,
      'invalid-email' ||
      'weak-password' ||
      'operation-not-allowed' => FailureKind.validation,
      'email-already-in-use' => FailureKind.conflict,
      'network-request-failed' ||
      'unavailable' ||
      'retry-limit-exceeded' => FailureKind.network,
      _ => FailureKind.unknown,
    };

    return AppFailure(kind: kind, debugMessage: error.code);
  }
}
