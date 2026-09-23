import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_datasource.dart';
import '../datasources/auth_firebase_datasource.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiDatasource datasource;
  final AuthFirebaseDatasource firebaseDatasource;

  AuthRepositoryImpl(this.datasource, this.firebaseDatasource);

  @override
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) {
    return datasource.login(
      identifier: identifier,
      password: password,
    );
  }

  @override
  Future<void> register(RegisterRequest request) {
    return datasource.register(request);
  }

  @override
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
  }) {
    return firebaseDatasource.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
    );
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return firebaseDatasource.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}
