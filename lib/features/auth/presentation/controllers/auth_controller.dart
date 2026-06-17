import 'package:flutter/foundation.dart';
import '../../domain/usecases/sign_in_use_case.dart';
import '../states/auth_state.dart';

/// Controller responsável pela lógica de autenticação na camada de apresentação.
class AuthController extends ChangeNotifier {
  AuthController(this._signInUseCase);

  final SignInUseCase _signInUseCase;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  /// Tenta autenticar com email e senha e atualiza o estado.
  Future<void> login(String email, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _signInUseCase(email, password);
      if (user != null) {
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        _state = _state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Falha na autenticação: usuário retornou nulo',
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }

    notifyListeners();
  }
}