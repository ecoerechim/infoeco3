import '../repositories/auth_repository.dart';
import '../../data/models/register_request.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<void> call(RegisterRequest request) async {
    return await _repository.register(request);
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
  }) async {
    return await _repository.verifyPhone(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
    );
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    return await _repository.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}
