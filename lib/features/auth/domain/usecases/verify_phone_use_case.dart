import '../repositories/auth_repository.dart';

class VerifyPhoneUseCase {
  final AuthRepository _repository;

  VerifyPhoneUseCase(this._repository);

  Future<void> call({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onVerificationFailed,
  }) async {
    return await _repository.verifyPhone(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
    );
  }
}
