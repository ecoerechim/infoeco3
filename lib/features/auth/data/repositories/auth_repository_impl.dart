import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_datasource.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiDatasource datasource;

  AuthRepositoryImpl(this.datasource);

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
}
