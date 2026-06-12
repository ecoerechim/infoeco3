class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<dynamic> call(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('E-mail e senha são obrigatórios');
    }

    return repository.signIn(email: email, password: password);
  }
}