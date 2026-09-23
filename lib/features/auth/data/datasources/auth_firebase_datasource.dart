import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthFirebaseDatasource {
  final FirebaseAuth _auth;

  AuthFirebaseDatasource({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
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
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Tenta fazer o sign-in com a credencial para validar o código
      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Código OTP inválido ou expirado');
    }
  }
}
