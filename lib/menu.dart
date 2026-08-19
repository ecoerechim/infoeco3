// Este arquivo implementa o menu principal do aplicativo.
// Ele contém botões que redirecionam para diferentes telas, como perfil, documentos, histórico, materiais, etc.

import 'package:flutter/material.dart';
import 'package:infoeco3/calendario.dart';
import 'package:infoeco3/configuracoes.dart';
import 'package:infoeco3/documentos.dart';
import 'package:infoeco3/historico.dart';
import 'package:infoeco3/historico_cooperativa.dart'; // Importa a tela de histórico da cooperativa
// import 'package:infoeco/historico2.dart';
import 'package:infoeco3/materiais.dart';
import 'package:infoeco3/materiais2.dart';
import 'package:infoeco3/materiais3.dart';
import 'package:infoeco3/perfil.dart';
import 'package:infoeco3/presencas.dart';
import 'package:infoeco3/presencas_cooperativa.dart';
import 'package:infoeco3/verificarCooperados.dart';
import 'package:infoeco3/verificarCooperativas.dart';
import 'package:infoeco3/verificarDocumentos.dart';
import 'package:infoeco3/verificar_partilhas.dart';
import 'package:infoeco3/verificar_coletas.dart';
import 'package:infoeco3/widgets/large_menu_button.dart';
import 'package:infoeco3/main.dart';
import 'package:infoeco3/user_profile_service.dart';
import 'package:provider/provider.dart';
import 'package:infoeco3/features/auth/presentation/controllers/auth_controller.dart';
import 'package:infoeco3/features/auth/data/models/login_response.dart';
import 'package:infoeco3/features/menu/data/datasources/menu_firebase_datasource.dart';
import 'package:infoeco3/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:infoeco3/features/menu/presentation/controllers/menu_controller.dart'
    as menu_feature;

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late final menu_feature.MenuController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = menu_feature.MenuController(
      MenuRepositoryImpl(MenuFirebaseDatasource()),
    )..addListener(_onControllerChanged);
    _menuController.loadProfile();
  }

  @override
  void dispose() {
    _menuController
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _abrirComoCooperativa(
      BuildContext context,
      Widget Function(String cooperativaUid, String prefeituraUid)
          builder) async {
    final prefeituraUid = _menuController.state.profile?.prefeituraUid;
    if (prefeituraUid == null) return;
    final cooperativas = await _menuController.loadCooperatives(prefeituraUid);
    if (!context.mounted) return;
    if (cooperativas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma cooperativa vinculada.')),
      );
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecione uma Cooperativa'),
        children: cooperativas
            .map((cooperative) => SimpleDialogOption(
                  child: Text(cooperative.name),
                  onPressed: () => Navigator.pop(context, cooperative.id),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => builder(selected, prefeituraUid),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _menuController.state;
    final authState = context.watch<AuthController>().state;

    if (state.isLoading) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Menu'), backgroundColor: Colors.green),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    UserProfileInfo? profile = state.profile;

    // Fallback: If Firebase profile is null, try to get role from AuthController
    if (profile == null && authState.user is LoginResponse) {
      final loginUser = authState.user as LoginResponse;
      final roleString = loginUser.role.toLowerCase();
      final userRole = UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == roleString,
        orElse: () => UserRole.unknown,
      );
      profile = UserProfileInfo(role: userRole);
    }

    if (profile == null || profile.role == UserRole.unknown) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Menu'), backgroundColor: Colors.green),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.errorMessage ?? 'Erro ao carregar perfil.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _menuController.loadProfile(),
                child: const Text('Tentar Novamente'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  await _menuController.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      );
    }

    final isAdmin = profile.role == UserRole.admin;
    final isPrefeitura = profile.role == UserRole.prefeitura;
    final isCooperativa = profile.role == UserRole.cooperativa;
    final isCooperado = profile.role == UserRole.cooperado;
    final isAprovado = profile.isAprovado;

    // Cooperado não aprovado
    if (isCooperado && !isAprovado) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menu'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text(
            'Aguardando aprovacao da cooperativa',
            style: TextStyle(
                fontSize: 20,
                color: Colors.orange,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Cooperativa não aprovada
    if (isCooperativa && !isAprovado) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menu'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text(
            'Aguardando aprovacao da prefeitura',
            style: TextStyle(
                fontSize: 20,
                color: Colors.orange,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool confirmLogout = await showDialog<bool>(
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

        if (confirmLogout) {
          await _menuController.signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu'),
          backgroundColor: Colors.green,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _menuItem(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Perfil()),
                      ),
                      text: 'PERFIL',
                      color: const Color.fromARGB(255, 255, 179, 65),
                    ),
                    // Constrói o menu dinamicamente conforme a role
                    if (isAdmin)
                      ..._buildAdminButtons(context)
                    else if (isPrefeitura)
                      ..._buildPrefeituraButtons(context)
                    else if (isCooperativa)
                      ..._buildCooperativaButtons(context)
                    else if (isCooperado)
                      ..._buildCooperadoButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói os botões para o perfil de Administrador do Sistema
  List<Widget> _buildAdminButtons(BuildContext context) {
    return [
      _menuItem(
        onPressed: () {}, // TODO: Implementar Gerenciar prefeituras
        text: 'GERENCIAR PREFEITURAS',
        color: Colors.teal,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Gerenciar cooperativas
        text: 'GERENCIAR COOPERATIVAS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Gerenciar usuários
        text: 'GERENCIAR USUÁRIOS',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Redefinir senhas
        text: 'REDEFINIR SENHAS',
        color: Colors.blue,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Ativar/desativar contas
        text: 'ATIVAR/DESATIVAR CONTAS',
        color: Colors.redAccent,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Configurar parâmetros
        text: 'CONFIGURAR PARÂMETROS',
        color: Colors.blueGrey,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Consultar logs
        text: 'CONSULTAR LOGS E AUDITORIAS',
        color: Colors.indigo,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Gerenciar backups
        text: 'GERENCIAR BACKUPS',
        color: Colors.brown,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Configurar integrações
        text: 'CONFIGURAR INTEGRAÇÕES',
        color: Colors.deepOrange,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Gerenciar permissões
        text: 'GERENCIAR PERMISSÕES',
        color: Colors.purple,
      ),
    ];
  }

  // Constrói os botões para o perfil de Prefeitura
  List<Widget> _buildPrefeituraButtons(BuildContext context) {
    return [
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => VerificarCooperativas())),
        text: 'APROVAR COOPERATIVAS',
        color: Colors.teal,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Aprovar novos cooperados
        text: 'APROVAR COOPERADOS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => VerificarCooperativas())),
        text: 'VISUALIZAR COOPERATIVAS',
        color: Colors.teal,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Consultar indicadores
        text: 'INDICADORES GERAIS',
        color: Colors.blue,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Emitir relatórios
        text: 'EMITIR RELATÓRIOS',
        color: Colors.deepPurple,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Cadastrar campanhas
        text: 'CAMPANHAS AMBIENTAIS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Enviar comunicados
        text: 'ENVIAR COMUNICADOS',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Calendario())),
        text: 'AGENDAR REUNIÕES',
        color: Colors.indigo,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VerificarDocumentos())),
        text: 'CONSULTAR DOCUMENTOS',
        color: Colors.blueGrey,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VerificarDocumentos())),
        text: 'APROVAR DOCUMENTOS',
        color: Colors.blueGrey,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Registrar visitas técnicas
        text: 'REGISTRAR VISITAS TÉCNICAS',
        color: Colors.brown,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Registrar fiscalizações
        text: 'REGISTRAR FISCALIZAÇÕES',
        color: Colors.redAccent,
      ),
      _menuItem(
        onPressed: () => _abrirComoCooperativa(
            context,
            (coopUid, prefUid) => Materiais2Screen(
                cooperativaUid: coopUid, prefeituraUid: prefUid)),
        text: 'GERENCIAR TIPOS DE MATERIAIS',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () => _abrirComoCooperativa(
            context,
            (coopUid, prefUid) => HistoricoCooperativa(
                cooperativaUid: coopUid,
                prefeituraUid: prefUid,
                viewOnly: true)),
        text: 'HISTÓRICO FINANCEIRO',
        color: Colors.deepPurple,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Gerenciar convênios
        text: 'GERENCIAR CONVÊNIOS',
        color: Colors.cyan,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Acompanhar metas
        text: 'ACOMPANHAR METAS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Configuracoes())),
        text: 'CONFIGURAÇÕES',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
    ];
  }

  // Constrói os botões para o perfil de Cooperativa
  List<Widget> _buildCooperativaButtons(BuildContext context) {
    return [
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => VerificarCooperados())),
        text: 'APROVAR COOPERADOS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => VerificarCooperados())),
        text: 'EDITAR COOPERADOS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => VerificarCooperados())),
        text: 'DESATIVAR COOPERADOS',
        color: Colors.redAccent,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Alterar funções internas
        text: 'ALTERAR FUNÇÕES INTERNAS',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const VerificarColetas())),
        text: 'REGISTRAR COLETA',
        color: Colors.indigo,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => Materiais2Screen())),
        text: 'ENTRADA DE MATERIAIS',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Materiais3())),
        text: 'REGISTRAR VENDA',
        color: Colors.blue,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Materiais3())),
        text: 'REGISTRAR ESTOQUE',
        color: Colors.blue,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Materiais())),
        text: 'REGISTRAR PESAGEM',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => HistoricoCooperativa())),
        text: 'EDITAR REGISTROS',
        color: Colors.deepPurple,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Registrar despesas
        text: 'REGISTRAR DESPESAS',
        color: Colors.red,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Registrar receitas
        text: 'REGISTRAR RECEITAS',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VerificarPartilhas())),
        text: 'GERAR PARTILHAS',
        color: Colors.cyan,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VerificarPartilhas())),
        text: 'CONFIRMAR PAGAMENTOS',
        color: Colors.cyan,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => HistoricoCooperativa())),
        text: 'CONSULTAR HISTÓRICO',
        color: Colors.deepPurple,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Documentos1())),
        text: 'ENVIAR DOCUMENTOS',
        color: Colors.teal,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Documentos1())),
        text: 'ATUALIZAR DOCUMENTOS',
        color: Colors.teal,
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VerificarDocumentos())),
        text: 'CONSULTAR VENCIMENTOS',
        color: Colors.blueGrey,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Emitir relatórios
        text: 'EMITIR RELATÓRIOS',
        color: Colors.indigo,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Exportar PDF
        text: 'EXPORTAR PDF',
        color: Colors.redAccent,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Exportar Excel
        text: 'EXPORTAR EXCEL',
        color: Colors.green,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Calendario())),
        text: 'CALENDÁRIO',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => PresencasCooperativa())),
        text: 'PRESENÇAS',
        color: const Color.fromARGB(255, 255, 196, 0),
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Configuracoes())),
        text: 'CONFIGURAÇÕES',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
    ];
  }

  // Constrói os botões para o perfil de Cooperado
  List<Widget> _buildCooperadoButtons(BuildContext context) {
    return [
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Perfil())),
        text: 'VISUALIZAR MEUS DADOS',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Perfil())),
        text: 'ATUALIZAR TELEFONE/ENDEREÇO',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Presencas())),
        text: 'CONSULTAR PRESENÇA',
        color: const Color.fromARGB(255, 255, 196, 0),
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Materiais())),
        text: 'MATERIAIS EM MEU NOME',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Historico())),
        text: 'CONSULTAR PARTILHAS',
        color: const Color.fromARGB(255, 29, 145, 64),
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Historico())),
        text: 'CONSULTAR PAGAMENTOS',
        color: const Color.fromARGB(255, 29, 145, 64),
      ),
      _menuItem(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => Documentos1())),
        text: 'CONSULTAR DOCUMENTOS',
        color: Colors.teal,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Receber notificações
        text: 'RECEBER NOTIFICAÇÕES',
        color: Colors.blue,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Calendario())),
        text: 'CONFIRMAR PRESENÇA REUNIÕES',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Calendario())),
        text: 'CONSULTAR CALENDÁRIO',
        color: Colors.orange,
      ),
      _menuItem(
        onPressed: () {}, // TODO: Implementar Enviar solicitações ao gestor
        text: 'ENVIAR SOLICITAÇÕES AO GESTOR',
        color: Colors.indigo,
      ),
      _menuItem(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Configuracoes())),
        text: 'CONFIGURAÇÕES',
        color: const Color.fromARGB(255, 255, 179, 65),
      ),
    ];
  }

  // Widget auxiliar para criar botões de menu consistentes
  Widget _menuItem(
      {required VoidCallback onPressed,
      required String text,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: LargeMenuButton(
        onPressed: onPressed,
        backgroundColor: color,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
