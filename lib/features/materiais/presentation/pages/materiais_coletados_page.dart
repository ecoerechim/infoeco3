import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../user_profile_service.dart';
import '../../../../xlsx_exporter.dart';
import '../../data/datasources/materiais_api_datasource.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/materiais_repository_impl.dart';
import '../controllers/materiais_controller.dart';

class MateriaisColetadosPage extends StatelessWidget {
  const MateriaisColetadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MateriaisController(
        MateriaisRepositoryImpl(
          MateriaisApiDatasource(
            AuthenticatedApiClient(context.read<TokenStorage>()),
          ),
        ),
      )..load(),
      child: const _MateriaisColetadosPageView(),
    );
  }
}

class _MateriaisColetadosPageView extends StatefulWidget {
  const _MateriaisColetadosPageView();

  @override
  State<_MateriaisColetadosPageView> createState() =>
      _MateriaisColetadosPageViewState();
}

class _MateriaisColetadosPageViewState extends State<_MateriaisColetadosPageView> {
  final UserProfileService _userProfileService = UserProfileService();
  Map<String, double> materiaisIndividuaisQtd = {};
  Map<String, double> materiaisGeraisQtd = {};
  Map<String, double> materiaisPrecos = {};
  bool _isLoadingData = true;
  double _valorPartilhaEstimado = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarColetas();
  }

  Future<void> _carregarColetas() async {
    try {
      final profile = await _userProfileService.getUserProfileInfo();
      final user = FirebaseAuth.instance.currentUser;

      if (profile.prefeituraUid != null && profile.cooperativaUid != null) {
        final firestore = FirebaseFirestore.instance;
        final coopRef = firestore
            .collection('prefeituras')
            .doc(profile.prefeituraUid)
            .collection('cooperativas')
            .doc(profile.cooperativaUid);

        final coopDoc = await coopRef.get();
        if (coopDoc.exists && coopDoc.data() != null) {
          final data = coopDoc.data()!;
          if (data.containsKey('materiaisG_qtd')) {
            final rawG = Map<String, dynamic>.from(data['materiaisG_qtd']);
            materiaisGeraisQtd = rawG.map((k, v) => MapEntry(k, (v as num).toDouble()));
          }
          if (data.containsKey('materiais')) {
            final rawMat = Map<String, dynamic>.from(data['materiais']);
            rawMat.forEach((k, v) {
              if (v is Map && v.containsKey('preco')) {
                materiaisPrecos[k] = (v['preco'] as num).toDouble();
              }
            });
          }
        }

        final targetUid = profile.cooperadoUid ?? user?.uid;
        if (targetUid != null) {
          final cooperadoDoc = await coopRef.collection('cooperados').doc(targetUid).get();
          if (cooperadoDoc.exists && cooperadoDoc.data() != null) {
            final data = cooperadoDoc.data()!;
            if (data.containsKey('materiais_qtd')) {
              final rawInd = Map<String, dynamic>.from(data['materiais_qtd']);
              materiaisIndividuaisQtd = rawInd.map((k, v) => MapEntry(k, (v as num).toDouble()));
            }
            if (data.containsKey('valor_partilha')) {
              _valorPartilhaEstimado = (data['valor_partilha'] as num).toDouble();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar coletas do cooperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  double _getPreco(String materialNome, List<MaterialModel> catalog) {
    if (materiaisPrecos.containsKey(materialNome)) {
      return materiaisPrecos[materialNome]!;
    }
    final catItem = catalog.firstWhere(
      (m) => m.nome == materialNome,
      orElse: () => MaterialModel(nome: materialNome, preco: 0.0, partilha: 'Individual'),
    );
    return catItem.preco;
  }

  Future<void> _exportXlsx(List<MaterialModel> catalog) async {
    final headers = ['Tipo', 'Material', 'Quantidade (kg)', 'Preço/kg (R\$)', 'Valor Total (R\$)'];
    final rows = <List<String>>[];

    materiaisIndividuaisQtd.forEach((material, qtd) {
      final preco = _getPreco(material, catalog);
      rows.add([
        'Individual',
        material,
        qtd.toStringAsFixed(2),
        preco.toStringAsFixed(2),
        (qtd * preco).toStringAsFixed(2),
      ]);
    });

    materiaisGeraisQtd.forEach((material, qtd) {
      final preco = _getPreco(material, catalog);
      rows.add([
        'Geral',
        material,
        qtd.toStringAsFixed(2),
        preco.toStringAsFixed(2),
        (qtd * preco).toStringAsFixed(2),
      ]);
    });

    await XlsxExporter.exportData(
      context,
      headers: headers,
      rows: rows,
      fileName: 'meus_materiais_coletados',
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MateriaisController>();
    final catalog = controller.materiais;

    final hasData = materiaisIndividuaisQtd.isNotEmpty || materiaisGeraisQtd.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Materiais Coletados em Meu Nome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Relatório',
            onPressed: !hasData ? null : () => _exportXlsx(catalog),
          ),
        ],
      ),
      body: (_isLoadingData || controller.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhum material registrado em seu nome ainda.\n'
                      'Utilize a opção "REGISTRAR PESAGEM" no menu para lançar coletas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Materiais Individuais Coletados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTable(materiaisIndividuaisQtd, catalog),
                          const SizedBox(height: 24),
                          const Text(
                            'Materiais Gerais da Cooperativa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTable(materiaisGeraisQtd, catalog),
                          const SizedBox(height: 24),
                          Card(
                            color: Colors.green.shade50,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Valor Aproximado da Partilha:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${_calcularValorTotal(catalog).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  double _calcularValorTotal(List<MaterialModel> catalog) {
    if (_valorPartilhaEstimado > 0) return _valorPartilhaEstimado;
    double total = 0.0;
    materiaisIndividuaisQtd.forEach((mat, qtd) {
      total += qtd * _getPreco(mat, catalog);
    });
    return total;
  }

  Widget _buildTable(Map<String, double> items, List<MaterialModel> catalog) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Nenhum registro nesta categoria.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
              label: Text('Material',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Quantidade (kg)',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Valor/kg (R\$)',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Valor Total (R\$)',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: items.entries.map((entry) {
          final preco = _getPreco(entry.key, catalog);
          final valTotal = entry.value * preco;
          return DataRow(cells: [
            DataCell(Text(entry.key)),
            DataCell(Text('${entry.value.toStringAsFixed(2)} kg')),
            DataCell(Text('R\$ ${preco.toStringAsFixed(2)}')),
            DataCell(Text('R\$ ${valTotal.toStringAsFixed(2)}')),
          ]);
        }).toList(),
      ),
    );
  }
}
