// Cooperado registra sua presença selecionando os turnos (Manhã / Tarde)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infoeco3/core/config/api_config.dart';
import 'package:infoeco3/menu.dart';
import 'package:infoeco3/user_profile_service.dart';
import 'package:infoeco3/widgets/table_widgets.dart';
import 'package:infoeco3/xlsx_exporter.dart';

// Tela principal para exibir presenças
class Presencas extends StatefulWidget {
  const Presencas({super.key});

  @override
  State<Presencas> createState() => _Presencas();
}

class _Presencas extends State<Presencas> {
  final GlobalKey<_WidgetTableState> _widgetTableKey = GlobalKey<_WidgetTableState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabela de Presença'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _widgetTableKey.currentState?.exportCsv();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: WidgetTable(key: _widgetTableKey),
          ),
        ),
      ),
    );
  }
}

class WidgetTable extends StatefulWidget {
  const WidgetTable({super.key});

  @override
  State<WidgetTable> createState() => _WidgetTableState();
}

class _WidgetTableState extends State<WidgetTable> {
  final UserProfileService _userProfileService = UserProfileService();
  List<Map<String, dynamic>> _docs = [];
  String? nomeCooperado;
  String? uid;
  String? cooperativaUid;
  String? prefeituraUid;
  bool isCooperado = false;
  bool loading = true;
  int _limiteHistorico = 7;

  bool _selectedManha = false;
  bool _selectedTarde = false;

  Future<List<Map<String, dynamic>>> _carregarPresencasApi() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/presencas/me'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode >= 400) {
        debugPrint('Erro ao carregar presenças da API: ${response.statusCode} ${response.body}');
        return <Map<String, dynamic>>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded == null) return <Map<String, dynamic>>[];

      final rawRows = decoded is List
          ? decoded
          : decoded is Map
              ? (decoded['content'] ?? decoded['items'] ?? decoded['data'] ?? [decoded])
              : <dynamic>[];

      if (rawRows is! List) return <Map<String, dynamic>>[];

      return rawRows
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar presenças da API: $e');
      return <Map<String, dynamic>>[];
    }
  }

  void exportCsv() {
    final headers = ['NOME', 'DATA', 'TURNO', 'APROVADO'];
    final rows = _docs.map((dataMap) {
      final nome = (dataMap['nome'] ?? '').toString();
      final data = (dataMap['data'] ?? '').toString();
      final turno = (dataMap['turno'] ?? (dataMap['entrada'] != null ? 'Registrado' : '-')).toString();
      final aprovado = dataMap['aprovadoPeloPresidente'] == true || dataMap['aprovado pelo presidente'] == true ? 'Sim' : 'Não';
      return [nome, data, turno, aprovado];
    }).toList();

    XlsxExporter.exportData(
      context,
      headers: headers,
      rows: rows,
      fileName: 'presencas',
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final profile = await _userProfileService.getUserProfileInfo();
    if (profile.role == UserRole.cooperado && profile.cooperadoUid != null) {
      nomeCooperado = profile.cooperadoUid;
      uid = profile.cooperadoUid;
      cooperativaUid = profile.cooperativaUid;
      prefeituraUid = profile.prefeituraUid;
      isCooperado = true;
      final presencas = await _carregarPresencasApi();
      if (mounted) {
        setState(() {
          _docs = presencas;
          loading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _registrarPresencaTurno() async {
    if (!_selectedManha && !_selectedTarde) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um turno (Manhã e/ou Tarde)!')),
      );
      return;
    }

    String turnoString;
    if (_selectedManha && _selectedTarde) {
      turnoString = 'Manhã e Tarde';
    } else if (_selectedManha) {
      turnoString = 'Manhã';
    } else {
      turnoString = 'Tarde';
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/presencas/confirmar'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'data': _formatarData(DateTime.now()),
              'turno': turnoString,
              'manha': _selectedManha,
              'tarde': _selectedTarde,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode >= 400) {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }

      final presencas = await _carregarPresencasApi();

      if (mounted) {
        setState(() {
          _docs = presencas;
          _selectedManha = false;
          _selectedTarde = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presença ($turnoString) registrada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar presença: $e')),
        );
      }
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Widget _tabelaHistoricoPresencas({bool semTitulo = false}) {
    final limitedDocs = _limiteHistorico == -1 ? _docs : _docs.take(_limiteHistorico).toList();
    if (limitedDocs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nenhum registro de presença encontrado.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('NOME', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TURNO', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('APROVADO', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: [
          for (final doc in limitedDocs)
            DataRow(cells: [
              DataCell(Text((doc['nome'] ?? '').toString())),
              DataCell(Text((doc['data'] ?? '').toString())),
              DataCell(Text((doc['turno'] ?? (doc['entrada'] != null ? 'Registrado' : '-')).toString())),
              DataCell(Text((doc['aprovadoPeloPresidente'] == true || doc['aprovado pelo presidente'] == true) ? 'Sim' : 'Pendente')),
            ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cooperado: ${nomeCooperado ?? 'Cooperado'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Data: ${_formatarData(DateTime.now())}'),
                const Divider(height: 20),
                const Text(
                  'Selecione o(s) turno(s) de trabalho:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('Manhã'),
                        selected: _selectedManha,
                        selectedColor: Colors.green.shade200,
                        onSelected: (val) {
                          setState(() {
                            _selectedManha = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Tarde'),
                        selected: _selectedTarde,
                        selectedColor: Colors.green.shade200,
                        onSelected: (val) {
                          setState(() {
                            _selectedTarde = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _registrarPresencaTurno,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Registrar Presença'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text('Presenças Registradas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _limiteHistorico,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7')),
                      DropdownMenuItem(value: 30, child: Text('30')),
                      DropdownMenuItem(value: 60, child: Text('60')),
                      DropdownMenuItem(value: -1, child: Text('Todas')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _limiteHistorico = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: tableContainer(
                  child: _tabelaHistoricoPresencas(semTitulo: true),
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Menu(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 48),
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text('Voltar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
