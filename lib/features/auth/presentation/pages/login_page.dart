import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infoeco3/menu.dart';
import 'package:infoeco3/form_fields.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final authController = context.read<AuthController>();
      await authController.login(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (authController.state.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login realizado com sucesso!')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Menu()),
          );
        } else if (authController.state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authController.state.errorMessage ?? 'Erro ao entrar')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthController>().state.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person,
                  size: 100,
                  color: Color.fromARGB(255, 29, 145, 64),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Campo Identificador (Email, CPF ou Telefone)
                CustomTextFormField(
                  label: 'E-mail, CPF ou Telefone',
                  controller: _identifierController,
                  validator: (value) => value == null || value.isEmpty ? 'Informe seu acesso' : null,
                ),
                const SizedBox(height: 20),

                // Campo Senha
                CustomTextFormField(
                  label: 'Senha',
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Informe sua senha' : null,
                ),
                const SizedBox(height: 40),

                // Botão Entrar
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: authStatus == AuthStatus.loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: authStatus == AuthStatus.loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ENTRAR',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // TODO: Implementar recuperação de senha unificada se necessário
                  },
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
