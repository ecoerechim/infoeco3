import '../repositories/auth_repository.dart';
import '../../data/models/register_request.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<void> call(RegisterRequest request) async {
    return await _repository.register(request);
  }
}
