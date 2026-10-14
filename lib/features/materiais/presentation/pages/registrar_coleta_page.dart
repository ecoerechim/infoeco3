import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../user_profile_service.dart';
import '../../data/datasources/materiais_api_datasource.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/materiais_repository_impl.dart';
import '../controllers/materiais_controller.dart';
import 'materiais_coletados_page.dart';

class RegistrarColetaPage extends StatelessWidget {
  const RegistrarColetaPage({
    super.key,
    this.viewOnly = false,
  });

  final bool viewOnly;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MateriaisController(
        MateriaisRepositoryImpl(
          MateriaisApiDatasource(
            AuthenticatedApiClient(context.read<TokenStorage>()),
          ),
        ),
      )..load(status: MaterialStatus.ativo),
      child: _RegistrarColetaPageView(viewOnly: viewOnly),
    );
  }
}

class _RegistrarColetaPageView extends StatefulWidget {
  const _RegistrarColetaPageView({required this.viewOnly});

  final bool viewOnly;

  @override
  State<_RegistrarColetaPageView> createState() => _RegistrarColetaPageViewState();
}

class _RegistrarColetaPageViewState extends State<_RegistrarColetaPageView> {
  final UserProfileService _userProfileService = UserProfileService();
  final Map<String, double> _quantidades = {};
  List<MaterialModel> _fallbackMateriais = [];
  bool _isLoadingFallback = true;
  String? _selectedMaterialId;

  @override
  void initState() {
    super.initState();
    _carregarFallbackMateriais();
  }

  Future<void> _carregarFallbackMateriais() async {
    try {
      final profile = await _userProfileService.getUserProfileInfo();
      if (profile.prefeituraUid != null && profile.cooperativaUid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('prefeituras')
            .doc(profile.prefeituraUid)
            .collection('cooperativas')
            .doc(profile.cooperativaUid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('materiais')) {
            final raw = Map<String, Map<String, dynamic>>.from(data['materiais']);
            _fallbackMateriais = raw.entries.map((entry) {
              return MaterialModel(
                nome: entry.key,
                preco: (entry.value['preco'] as num?)?.toDouble() ?? 0.0,
                partilha: (entry.value['partilha'] ?? 'Individual').toString(),
                status: MaterialStatus.ativo,
              );
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar materiais do Firestore: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFallback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MateriaisController>();
    final materiaisAtivos = controller.materiais.isNotEmpty
        ? controller.materiais.where((m) => m.status == MaterialStatus.ativo).toList()
        : _fallbackMateriais;

    if (_selectedMaterialId == null && materiaisAtivos.isNotEmpty) {
      _selectedMaterialId = materiaisAtivos.first.id ?? materiaisAtivos.first.nome;
    }

    final selectedMaterial = materiaisAtivos.firstWhere(
      (m) => (m.id ?? m.nome) == _selectedMaterialId,
      orElse: () => materiaisAtivos.isNotEmpty
          ? materiaisAtivos.first
          : MaterialModel(nome: '', preco: 0.0, partilha: 'Individual'),
    );

    final quantidadeAtual = _quantidades[selectedMaterial.nome] ?? 0.0;
    final valorTotalEstimado = _calcularValorTotalEstimado(materiaisAtivos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Materiais Coletados'),
        backgroundColor: Colors.green,
      ),
      body: (controller.isLoading && _isLoadingFallback)
          ? const Center(child: CircularProgressIndicator())
          : materiaisAtivos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhum material ativo cadastrado.\n'
                      'A cooperativa precisa cadastrar tipos de materiais antes de registrar pesagens.',
                      textAlign: TextAlign.center,
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
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selecione o Material',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedMaterialId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    items: materiaisAtivos.map((m) {
                                      final idKey = m.id ?? m.nome;
                                      return DropdownMenuItem<String>(
                                        value: idKey,
                                        child: Text(
                                            '${m.nome} — R\$ ${m.preco.toStringAsFixed(2)}/kg (${m.partilha})'),
                                      );
                                    }).toList(),
                                    onChanged: widget.viewOnly
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedMaterialId = value;
                                              });
                                            }
                                          },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: quantidadeAtual == 0
                                        ? ''
                                        : quantidadeAtual.toString(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Quantidade (kg)',
                                      border: OutlineInputBorder(),
                                    ),
                                    enabled: !widget.viewOnly,
                                    onChanged: (value) {
                                      setState(() {
                                        _quantidades[selectedMaterial.nome] =
                                            double.tryParse(value) ?? 0.0;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Valor Deste Registro:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'R\$ ${(quantidadeAtual * selectedMaterial.preco).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: widget.viewOnly ||
                                            quantidadeAtual <= 0
                                        ? null
                                        : () => _confirmarEnvio(
                                              selectedMaterial,
                                              quantidadeAtual,
                                            ),
                                    icon: const Icon(Icons.send),
                                    label: const Text('Enviar Coleta'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MateriaisColetadosPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Conferir Materiais Coletados'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            color: Colors.green.shade50,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Valor Estimado da Partilha:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${valorTotalEstimado.toStringAsFixed(2)}',
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

  double _calcularValorTotalEstimado(List<MaterialModel> materiais) {
    double total = 0.0;
    for (final m in materiais) {
      final qtd = _quantidades[m.nome] ?? 0.0;
      total += qtd * m.preco;
    }
    return total;
  }

  Future<void> _confirmarEnvio(
      MaterialModel material, double quantidade) async {
    final valor = quantidade * material.preco;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Envio de Coleta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Material: ${material.nome}'),
            Text('Quantidade: ${quantidade.toStringAsFixed(2)} kg'),
            Text('Partilha: ${material.partilha}'),
            Text('Valor Estimado: R\$ ${valor.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final profile = await _userProfileService.getUserProfileInfo();
      final user = FirebaseAuth.instance.currentUser;
      final prefeituraUid = profile.prefeituraUid;
      final cooperativaUid = profile.cooperativaUid;

      if (prefeituraUid != null && cooperativaUid != null && user != null) {
        final firestore = FirebaseFirestore.instance;
        final targetUid = profile.cooperadoUid ?? user.uid;

        final cooperadoRef = firestore
            .collection('prefeituras')
            .doc(prefeituraUid)
            .collection('cooperativas')
            .doc(cooperativaUid)
            .collection('cooperados')
            .doc(targetUid);

        final cooperativaRef = firestore
            .collection('prefeituras')
            .doc(prefeituraUid)
            .collection('cooperativas')
            .doc(cooperativaUid);

        if (material.partilha == 'Individual') {
          await firestore.runTransaction((transaction) async {
            final cooperadoDoc = await transaction.get(cooperadoRef);
            final cooperativaDoc = await transaction.get(cooperativaRef);

            final matQtdCooperado = Map<String, dynamic>.from(
                cooperadoDoc.data()?['materiais_qtd'] ?? {});
            matQtdCooperado[material.nome] =
                (matQtdCooperado[material.nome] as num? ?? 0) + quantidade;

            final matQtdCooperativa = Map<String, dynamic>.from(
                cooperativaDoc.data()?['materiais_qtd'] ?? {});
            matQtdCooperativa[material.nome] =
                (matQtdCooperativa[material.nome] as num? ?? 0) + quantidade;

            transaction.update(cooperadoRef, {'materiais_qtd': matQtdCooperado});
            transaction.update(cooperativaRef, {'materiais_qtd': matQtdCooperativa});
          });
        } else if (material.partilha == 'Geral') {
          await firestore.runTransaction((transaction) async {
            final cooperativaDoc = await transaction.get(cooperativaRef);

            final matQtdGeral = Map<String, dynamic>.from(
                cooperativaDoc.data()?['materiaisG_qtd'] ?? {});
            matQtdGeral[material.nome] =
                (matQtdGeral[material.nome] as num? ?? 0) + quantidade;

            transaction.update(cooperativaRef, {'materiaisG_qtd': matQtdGeral});
          });
        }

        await cooperativaRef.collection('coletas_materiais').add({
          'user_uid': user.uid,
          'cooperado_uid': targetUid,
          'material': {
            'material_name': material.nome,
            'qtd': quantidade,
            'preco': material.preco,
            'valor': valor,
          },
          'data': FieldValue.serverTimestamp(),
          'partilha_realizada': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registro de coleta realizado com sucesso!')),
        );
        setState(() {
          _quantidades[material.nome] = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar coleta: $e')),
        );
      }
    }
  }
}
