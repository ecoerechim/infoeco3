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

  /// Envia código de verificação via SMS
  Future<void> sendVerificationCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
  }) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      await _registerUseCase.verifyPhone(
        phoneNumber: '+55$phoneNumber', // Assumindo Brasil por padrão, ajuste se necessário
        onCodeSent: (verificationId) {
          _state = _state.copyWith(status: AuthStatus.initial);
          notifyListeners();
          onCodeSent(verificationId);
        },
        onVerificationFailed: (error) {
          _state = _state.copyWith(status: AuthStatus.error, errorMessage: error);
          notifyListeners();
          onVerificationFailed(error);
        },
      );
    } catch (e) {
      _state = _state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      notifyListeners();
      onVerificationFailed(e.toString());
    }
  }

  /// Verifica o código OTP
  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      await _registerUseCase.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _state = _state.copyWith(status: AuthStatus.initial);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
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
