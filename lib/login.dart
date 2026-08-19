// Este arquivo implementa a tela de login.
// Ele permite que o usuário escolha entre diferentes tipos de login: Prefeitura, Cooperativa ou Cooperado.

import 'package:flutter/material.dart';
import 'cooperado_login_selection.dart';
import 'prefeitura.dart';
import 'cooperativa.dart'; // Correctly imports CooperativaLogin
import 'cooperado.dart';

import 'package:infoeco3/features/auth/presentation/pages/login_page.dart';

// Classe principal para a tela de login (Redirecionando para a nova LoginPage unificada)
class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}
