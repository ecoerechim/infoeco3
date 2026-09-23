import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../user_profile_service.dart';
import '../../domain/entities/cooperative_option.dart';

class MenuFirebaseDatasource {
  MenuFirebaseDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    UserProfileService? userProfileService,
  })  : _providedAuth = auth,
        _providedFirestore = firestore,
        _userProfileService = userProfileService ?? UserProfileService();

  final FirebaseAuth? _providedAuth;
  final FirebaseFirestore? _providedFirestore;
  final UserProfileService _userProfileService;

  FirebaseAuth? get _auth {
    if (_providedAuth != null) return _providedAuth;
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Aviso: FirebaseAuth não disponível: $e');
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    if (_providedFirestore != null) return _providedFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Aviso: FirebaseFirestore não disponível: $e');
      return null;
    }
  }

  Future<UserProfileInfo> loadUserProfile() async {
    try {
      // Verifica se o Firebase está ativo antes de chamar o serviço que depende dele
      if (_auth == null) {
        throw Exception('Firebase não inicializado');
      }
      return await _userProfileService.getUserProfileInfo();
    } catch (e) {
      debugPrint('Erro ao carregar perfil via Firebase: $e');
      rethrow;
    }
  }

  Future<List<CooperativeOption>> loadCooperatives(String prefeituraUid) async {
    final db = _firestore;
    if (db == null) return [];

    try {
      final snapshot = await db
          .collection('prefeituras')
          .doc(prefeituraUid)
          .collection('cooperativas')
          .get();

      return snapshot.docs
          .map(
            (doc) => CooperativeOption(
              id: doc.id,
              name: (doc.data()['nome'] as String?) ?? doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar cooperativas via Firebase: $e');
      return [];
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Erro ao sair do Firebase: $e');
    }
  }
}
