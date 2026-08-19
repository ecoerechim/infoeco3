import '../../data/models/login_response.dart';
import '../../data/models/register_request.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  });

  Future<void> register(RegisterRequest request);
}
