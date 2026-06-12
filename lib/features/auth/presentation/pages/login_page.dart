class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: Column(
        children: [
          TextField(controller: emailController),
          TextField(controller: passwordController, obscureText: true),

          if (authController.state.status == AuthStatus.loading)
            const CircularProgressIndicator(),

          if (authController.state.errorMessage != null)
            Text(authController.state.errorMessage!),

          ElevatedButton(
            onPressed: () {
              context.read<AuthController>().login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }
}