import 'package:flutter/foundation.dart';
import '../../domain/usecases/sign_in_use_case.dart';
import '../states/auth_state.dart';
import '../../../../core/storage/token_storage.dart';

/// Controller responsável pela lógica de autenticação na camada de apresentação.
class AuthController extends ChangeNotifier {
  AuthController(this._signInUseCase, this._tokenStorage);

  final SignInUseCase _signInUseCase;
  final TokenStorage _tokenStorage;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  /// Tenta autenticar com email e senha e atualiza o estado.
  Future<void> login(String email, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final result = await _signInUseCase(email, password);
      
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
}
