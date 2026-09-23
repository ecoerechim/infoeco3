import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthFirebaseDatasource {
  final FirebaseAuth? _auth;

  AuthFirebaseDatasource({FirebaseAuth? auth})
      : _auth = auth ?? _getFirebaseAuthSafely();

  static FirebaseAuth? _getFirebaseAuthSafely() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('AuthFirebaseDatasource: Firebase Auth não disponível nesta plataforma: $e');
      return null;
    }
  }

  bool get isAvailable => _auth != null;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onVerificationFailed,
  }) async {
    // Modo de Simulação para Desenvolvimento (Linux/Web/Emuladores com erro)
    if (_auth == null || kDebugMode) {
      debugPrint('AuthFirebaseDatasource: USANDO MODO DE SIMULAÇÃO (DEBUG)');
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent('verificationId_debug_123456');
      return;
    }

    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // No Android, isso pode acontecer automaticamente em alguns casos.
          // Por enquanto, focamos no fluxo de código manual via SMS.
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
          onVerificationFailed(e.message ?? 'Erro na verificação do Firebase');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onVerificationFailed(e.toString());
    }
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    // Validação para o modo de simulação
    if ((_auth == null || kDebugMode) && verificationId == 'verificationId_debug_123456') {
      if (smsCode == '123456') {
        debugPrint('AuthFirebaseDatasource: OTP Simulado validado com sucesso!');
        return;
      } else {
        throw Exception('Código OTP simulado inválido. Use 123456');
      }
    }

    if (_auth == null) {
      throw Exception('Serviço de SMS (Firebase) não disponível nesta plataforma.');
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Tenta fazer o sign-in com a credencial para validar o código
      await _auth!.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Código OTP inválido ou expirado');
    }
  }
}
