import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  });

  Future<void> register(RegisterRequest request);

  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
  });

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
}
