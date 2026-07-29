import 'package:flutter/material.dart';
import '../widgets/register_form_widget.dart';

/// Página de Registro de Usuários
///
/// Segue a arquitetura limpa com separação clara entre camadas:
/// - Presentation: Esta página (UI)
/// - Controllers: AuthController (já existe)
/// - States: AuthState (já existe)
/// - Domain: RegisterUseCase (já existe)
/// - Data: RegisterRequest (já existe)
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: const RegisterFormWidget(),
          ),
        ),
      ),
    );
  }
}

