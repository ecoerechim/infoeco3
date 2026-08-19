import 'package:flutter/foundation.dart';
import '../../domain/usecases/sign_in_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../states/auth_state.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/register_request.dart';

/// Controller responsável pela lógica de autenticação na camada de apresentação.
class AuthController extends ChangeNotifier {
  AuthController(this._signInUseCase, this._registerUseCase, this._tokenStorage);

  final SignInUseCase _signInUseCase;
  final RegisterUseCase _registerUseCase;
  final TokenStorage _tokenStorage;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  /// Tenta autenticar com identificador (email, cpf ou telefone) e senha e atualiza o estado.
  Future<void> login(String identifier, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final result = await _signInUseCase(identifier, password);
      
      await _tokenStorage.saveToken(result.accessToken);

      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        user: result,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }

    notifyListeners();
  }

  /// Tenta registrar um novo usuário e atualiza o estado.
  Future<void> register(RegisterRequest request) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      await _registerUseCase(request);
      
      _state = _state.copyWith(
        status: AuthStatus.initial,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }

    notifyListeners();
  }
}
