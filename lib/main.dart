// Este arquivo é o ponto de entrada principal do aplicativo.
// Ele inicializa o Firebase e define a tela inicial do aplicativo.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infoeco3/features/auth/presentation/pages/login_page.dart';
import 'package:infoeco3/features/auth/presentation/pages/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:infoeco3/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:infoeco3/features/auth/presentation/controllers/auth_controller.dart';
import 'package:infoeco3/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:infoeco3/features/auth/domain/usecases/register_use_case.dart';
import 'package:infoeco3/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:infoeco3/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:infoeco3/features/auth/data/datasources/auth_firebase_datasource.dart';
import 'package:infoeco3/core/storage/token_storage.dart';
import 'package:infoeco3/core/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No Linux, o Firebase pode não estar configurado.
  // Envolvemos em um try-catch para permitir que o app inicie mesmo sem Firebase,
  // já que agora usamos a API customizada para autenticação.
  try {
    // Inicialização do Firebase com tratamento de erro
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Aviso: Firebase não inicializado: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String baseUrl = ApiConfig.baseUrl;

    return MultiProvider(
      providers: [
        Provider(create: (_) => TokenStorage()),
        Provider(create: (_) => AuthApiDatasource(baseUrl)),
        Provider(create: (_) => AuthFirebaseDatasource()),
        ProxyProvider2<AuthApiDatasource, AuthFirebaseDatasource,
            AuthRepositoryImpl>(
          update: (_, apiDatasource, firebaseDatasource, __) =>
              AuthRepositoryImpl(apiDatasource, firebaseDatasource),
        ),
        ProxyProvider<AuthRepositoryImpl, SignInUseCase>(
          update: (_, repository, __) => SignInUseCase(repository),
        ),
        ProxyProvider<AuthRepositoryImpl, RegisterUseCase>(
          update: (_, repository, __) => RegisterUseCase(repository),
        ),
        ChangeNotifierProxyProvider3<SignInUseCase, RegisterUseCase,
            TokenStorage, AuthController>(
          create: (context) => AuthController(
            context.read<SignInUseCase>(),
            context.read<RegisterUseCase>(),
            context.read<TokenStorage>(),
          ),
          update: (context, signInUseCase, registerUseCase, tokenStorage,
                  previous) =>
              previous ??
              AuthController(signInUseCase, registerUseCase, tokenStorage),
        ),
      ],
      child: MaterialApp(
        title: 'InfoEco',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green, // Cor primária
          // Define um tema global para todos os ElevatedButtons no aplicativo.
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
            ),
          ),
        ),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        home: const MyHomePage(title: 'InfoEco'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool confirmExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar Saída'),
                content: const Text(
                    'Você tem certeza que deseja sair do aplicativo?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirmExit) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: const AssetImage(
                  'assets/img/LogoNome.png',
                ),
                width: 250,
                height: 250,
              ),
              const Padding(padding: EdgeInsets.all(10)),
              const Padding(padding: EdgeInsets.only(bottom: 70)),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(300, 75),
                ),
                child: const Text('INICIAR SESSÃO',
                    style: TextStyle(color: Colors.white)),
              ),
              const Padding(padding: EdgeInsets.all(10)),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(300,
                      75), // Re-apply specific size if needed, or remove for full responsiveness
                ),
                child: const Text('CRIAR CONTA',
                    style: TextStyle(color: Colors.white)),
              ),
              const Padding(padding: EdgeInsets.all(10)),
            ],
          ),
        ),
      ),
    );
  }
}
