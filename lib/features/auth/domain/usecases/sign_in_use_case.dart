import '../repositories/auth_repository.dart';
import '../../data/models/login_response.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<LoginResponse> call(String email, String password) async {
    return await _repository.login(email: email, password: password);
  }
}
