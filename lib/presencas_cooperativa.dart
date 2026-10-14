// presencas_cooperativa.dart
// Tela para cooperativa/presidente visualizar, aprovar, editar e excluir presenças de todos os cooperados

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infoeco3/menu.dart';
import 'package:infoeco3/user_profile_service.dart';
import 'package:infoeco3/xlsx_exporter.dart';

class PresencasCooperativa extends StatefulWidget {
  final String? cooperativaUid;
  final String? prefeituraUid;
  final bool viewOnly;
  const PresencasCooperativa({super.key, this.cooperativaUid, this.prefeituraUid, this.viewOnly = false});

  @override
  State<PresencasCooperativa> createState() => _PresencasCooperativaState();
}

class _PresencasCooperativaState extends State<PresencasCooperativa> {
  final UserProfileService _userProfileService = UserProfileService();
  List<QueryDocumentSnapshot> _docs = [];
  String? cooperativaUid;
  String? prefeituraUid;
  bool get viewOnly => widget.viewOnly;
  bool loading = true;
  int _limiteHistorico = 30;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cooperativaUid = widget.cooperativaUid;
    prefeituraUid = widget.prefeituraUid;
    _carregarCooperativaUid();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Busca o UID da cooperativa logada
  Future<void> _carregarCooperativaUid() async {
    if (widget.cooperativaUid != null && widget.prefeituraUid != null) {
      cooperativaUid = widget.cooperativaUid;
      prefeituraUid = widget.prefeituraUid;
    } else {
      final profile = await _userProfileService.getUserProfileInfo();
      if (profile.role == UserRole.cooperativa) {
        cooperativaUid = profile.cooperativaUid;
        prefeituraUid = profile.prefeituraUid;
      }
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Presenças da Cooperativa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final headers = ['NOME', 'DATA', 'TURNO', 'APROVADO'];
              final rows = _docs.map((doc) {
                final mapData = doc.data() as Map<String, dynamic>;
                final nome = mapData['nome'] ?? '';
                final data = mapData['data'] ?? '';
                final turno = mapData['turno'] ?? (mapData['entrada'] != null ? 'Registrado' : '-');
                final aprovado = mapData['aprovado pelo presidente'] == true ? 'Sim' : 'Não';
                return [nome, data, turno, aprovado];
              }).toList();

              XlsxExporter.exportData(
                context,
                headers: headers,
                rows: rows.map((row) => row.map((e) => e.toString()).toList()).toList(),
                fileName: 'presencas_cooperativa',
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Presenças Registradas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Mostrar:'),
                      const SizedBox(width: 8),
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
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar por nome',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (cooperativaUid == null)
                    const Center(child: Text('Cooperativa não encontrada.'))
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('prefeituras')
                          .doc(prefeituraUid)
                          .collection('cooperativas')
                          .doc(cooperativaUid)
                          .collection('presencas')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        List docs = snapshot.data?.docs ?? [];
                        String search = _searchController.text.trim();
                        if (search.isNotEmpty) {
                          docs = docs.where((doc) {
                            final nome = (doc['nome'] ?? '').toString().toLowerCase();
                            return nome.contains(search.toLowerCase());
                          }).toList();
                        }
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Nenhum registro encontrado.'),
                          );
                        }

                        final limitedDocs = _limiteHistorico == -1 ? docs : docs.take(_limiteHistorico).toList();
                        _docs = List<QueryDocumentSnapshot>.from(limitedDocs);
                        return Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 700),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('NOME', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('TURNO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('APROVADO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('AÇÃO', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: [
                                  for (var doc in limitedDocs)
                                    DataRow(cells: [
                                      DataCell(Text(doc['nome'] ?? '', style: const TextStyle(fontSize: 16))),
                                      DataCell(Text(doc['data'] ?? '', style: const TextStyle(fontSize: 16))),
                                      DataCell(Text((doc.data() as Map<String, dynamic>)['turno'] ??
                                          ((doc.data() as Map<String, dynamic>)['entrada'] != null ? 'Registrado' : '-'), style: const TextStyle(fontSize: 16))),
                                      DataCell(Text((doc.data() as Map<String, dynamic>).containsKey('aprovado pelo presidente') && doc['aprovado pelo presidente'] == true ? 'Sim' : 'Não', style: const TextStyle(fontSize: 16))),
                                      DataCell(Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if ((doc.data() as Map<String, dynamic>).containsKey('aprovado pelo presidente') && doc['aprovado pelo presidente'] != true)
                                            SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: ElevatedButton(
                                                onPressed: viewOnly ? null : () async {
                                                  await FirebaseFirestore.instance
                                                      .collection('prefeituras')
                                                      .doc(prefeituraUid)
                                                      .collection('cooperativas')
                                                      .doc(cooperativaUid)
                                                      .collection('presencas')
                                                      .doc(doc.id)
                                                      .update({'aprovado pelo presidente': true});
                                                  setState(() {});
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: EdgeInsets.zero,
                                                  shape: const CircleBorder(),
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 18),
                                              ),
                                            ),
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              tooltip: 'Editar Turno',
                                              onPressed: viewOnly ? null : () async {
                                                final mapData = doc.data() as Map<String, dynamic>;
                                                String selectedTurno = mapData['turno'] ?? 'Manhã';
                                                await showDialog(
                                                  context: context,
                                                  builder: (dialogCtx) {
                                                    return StatefulBuilder(
                                                      builder: (context, setDialogState) {
                                                        return AlertDialog(
                                                          title: const Text('Editar Turno'),
                                                          content: DropdownButtonFormField<String>(
                                                            initialValue: selectedTurno,
                                                            items: const [
                                                              DropdownMenuItem(value: 'Manhã', child: Text('Manhã')),
                                                              DropdownMenuItem(value: 'Tarde', child: Text('Tarde')),
                                                              DropdownMenuItem(value: 'Manhã e Tarde', child: Text('Manhã e Tarde')),
                                                            ],
                                                            onChanged: (val) {
                                                              if (val != null) {
                                                                setDialogState(() {
                                                                  selectedTurno = val;
                                                                });
                                                              }
                                                            },
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text('Cancelar'),
                                                              onPressed: () => Navigator.of(dialogCtx).pop(),
                                                            ),
                                                            ElevatedButton(
                                                              child: const Text('Salvar'),
                                                              onPressed: () async {
                                                                await FirebaseFirestore.instance
                                                                    .collection('prefeituras')
                                                                    .doc(prefeituraUid)
                                                                    .collection('cooperativas')
                                                                    .doc(cooperativaUid)
                                                                    .collection('presencas')
                                                                    .doc(doc.id)
                                                                    .update({
                                                                  'turno': selectedTurno,
                                                                });
                                                                if (dialogCtx.mounted) {
                                                                  Navigator.of(dialogCtx).pop();
                                                                }
                                                                setState(() {});
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              tooltip: 'Excluir presença',
                                              onPressed: viewOnly ? null : () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Excluir presença'),
                                                    content: const Text('Tem certeza que deseja excluir este registro?'),
                                                    actions: [
                                                      TextButton(
                                                        child: const Text('Cancelar'),
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                      ),
                                                      ElevatedButton(
                                                        child: const Text('Excluir'),
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await FirebaseFirestore.instance
                                                      .collection('prefeituras')
                                                      .doc(prefeituraUid)
                                                      .collection('cooperativas')
                                                      .doc(cooperativaUid)
                                                      .collection('presencas')
                                                      .doc(doc.id)
                                                      .delete();
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      )),
                                    ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
              ),
            ),
          );
        },
      ),
    );
  }
}
