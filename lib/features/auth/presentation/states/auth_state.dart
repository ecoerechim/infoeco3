// AuthStatus representa a situação atual do login.
// Define os possíveis estados de autenticação e um objeto de estado imutável.

enum AuthStatus { initial, loading, authenticated, error, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final dynamic user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    dynamic user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }

  @override
  String toString() => 'AuthState(status: $status, errorMessage: $errorMessage, user: $user)';
}

