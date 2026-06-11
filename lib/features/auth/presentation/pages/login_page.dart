// Página de login
// Interface limpa que captura input, mostra estado de carregamento e erros
// Reage ao estado do AuthController

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    // Navegar quando autenticado
    if (authController.state.status == AuthStatus.authenticated) {
      // Navegar para a próxima tela após autenticação
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Aqui você pode navegar para a tela principal do seu app
        // Navigator.of(context).pushReplacementNamed('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso!')),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email TextField
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'seu.email@exemplo.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabled: authController.state.status != AuthStatus.loading,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),

            // Password TextField
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Digite sua senha',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabled: authController.state.status != AuthStatus.loading,
              ),
            ),
            const SizedBox(height: 24.0),

            // Loading Indicator
            if (authController.state.status == AuthStatus.loading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),

            // Error Message
            if (authController.state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        authController.state.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24.0),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authController.state.status == AuthStatus.loading
                    ? null
                    : () {
                        context.read<AuthController>().login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

