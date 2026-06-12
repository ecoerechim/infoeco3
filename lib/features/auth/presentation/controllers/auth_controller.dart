class AuthController extends ChangeNotifier {
  AuthController(this._signInUseCase);

  final SignInUseCase _signInUseCase;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  Future<void> login(String email, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _signInUseCase(email, password);
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
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