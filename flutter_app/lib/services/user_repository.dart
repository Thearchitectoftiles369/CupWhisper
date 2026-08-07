import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_language.dart';
import 'ai_models.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> ensureUserDocument(String uid) async {
    final ref = _firestore.collection('users').doc(uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'language': AppLanguage.english.code,
        'storyteller': null,
        'hasSeenDisclosure': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> hasSeenDisclosure(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    return data?['hasSeenDisclosure'] as bool? ?? false;
  }

  Future<void> markDisclosureSeen(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'hasSeenDisclosure': true,
    });
  }

  Future<void> updateLanguage(String uid, AppLanguage language) async {
    await _firestore.collection('users').doc(uid).update({
      'language': language.code,
    });
  }

  Future<void> updateLastStoryteller(String uid, Storyteller storyteller) async {
    await _firestore.collection('users').doc(uid).update({
      'storyteller': storyteller.id,
    });
  }

  Future<void> saveReading({
    required String uid,
    required Storyteller storyteller,
    required AppLanguage language,
    required String result,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .add({
      'storyteller': storyteller.id,
      'language': language.code,
      'result': result,
      'date': FieldValue.serverTimestamp(),
    });
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});
