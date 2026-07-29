import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';
import '../../data/models/register_request.dart';

class RegisterFormWidget extends StatefulWidget {
  const RegisterFormWidget({super.key});

  @override
  State<RegisterFormWidget> createState() => _RegisterFormWidgetState();
}

class _RegisterFormWidgetState extends State<RegisterFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();

  String _selectedRole = 'cooperado'; // Default role

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String? newRole) {
    if (newRole != null) {
      setState(() {
        _selectedRole = newRole;
        _documentoController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final request = RegisterRequest(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        documento: _documentoController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        telefone: _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      final authController = context.read<AuthController>();
      await authController.register(request);

      if (mounted) {
        if (authController.state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authController.state.errorMessage ?? 'Erro ao cadastrar')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          Navigator.of(context).pop(); // Voltar após sucesso
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthController>().state.status;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Preencha seus dados para começar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Combobox de Tipo de Usuário
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Eu sou...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_pin),
            ),
            items: const [
              DropdownMenuItem(value: 'prefeitura', child: Text('Prefeitura')),
              DropdownMenuItem(value: 'cooperativa', child: Text('Cooperativa')),
              DropdownMenuItem(value: 'cooperado', child: Text('Cooperado')),
            ],
            onChanged: authStatus == AuthStatus.loading ? null : _onRoleChanged,
          ),
          const SizedBox(height: 20),

          // Nome
          TextFormField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome Completo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Informe seu nome' : null,
          ),
          const SizedBox(height: 20),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe seu email';
              if (!value.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Telefone
          TextFormField(
            controller: _telefoneController,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [_telefoneFormatter],
            validator: (value) => value == null || value.isEmpty ? 'Informe seu telefone' : null,
          ),
          const SizedBox(height: 20),

          // CPF ou CNPJ Dinâmico
          TextFormField(
            controller: _documentoController,
            decoration: InputDecoration(
              labelText: _selectedRole == 'cooperado' ? 'CPF' : 'CNPJ',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.badge),
            ),
            inputFormatters: [
              _selectedRole == 'cooperado' ? _cpfFormatter : _cnpjFormatter,
            ],
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o ${_selectedRole == 'cooperado' ? 'CPF' : 'CNPJ'}';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Senha
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Senha',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) => value != null && value.length < 4 ? 'Mínimo 4 caracteres' : null,
          ),
          const SizedBox(height: 20),

          // Confirmar Senha
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirmar Senha',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_clock),
            ),
            obscureText: true,
            validator: (value) {
              if (value != _passwordController.text) return 'As senhas não coincidem';
              return null;
            },
          ),
          const SizedBox(height: 40),

          // Botão Cadastrar
          ElevatedButton(
            onPressed: authStatus == AuthStatus.loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: authStatus == AuthStatus.loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'CADASTRAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

