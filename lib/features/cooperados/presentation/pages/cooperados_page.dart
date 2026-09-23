import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/cooperados_api_datasource.dart';
import '../../data/models/cooperado_model.dart';
import '../../data/repositories/cooperados_repository_impl.dart';
import '../controllers/cooperados_controller.dart';

class CooperadosPage extends StatelessWidget {
  const CooperadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CooperadosController(
        CooperadosRepositoryImpl(
          CooperadosApiDatasource(
            AuthenticatedApiClient(context.read<TokenStorage>()),
          ),
        ),
      )..load(),
      child: const _CooperadosPageView(),
    );
  }
}

class _CooperadosPageView extends StatefulWidget {
  const _CooperadosPageView();

  @override
  State<_CooperadosPageView> createState() => _CooperadosPageViewState();
}

class _CooperadosPageViewState extends State<_CooperadosPageView> {
  final TextEditingController _searchController = TextEditingController();
  CooperadoStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
    }
    return cpf;
  }

  String _formatTelefone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7, 11)}';
    } else if (clean.length == 10) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6, 10)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CooperadosController>();
    final query = _searchController.text.trim().toLowerCase();

    final visible = controller.cooperados.where((item) {
      if (_selectedStatusFilter != null && item.status != _selectedStatusFilter) {
        return false;
      }
      final searchable =
          [item.nome, item.cpf, item.email].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Cooperados'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: Colors.green,
        label: const Text('Cadastrar cooperado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por nome, CPF ou e-mail',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedStatusFilter == null,
                    onSelected: (_) => setState(() => _selectedStatusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...CooperadoStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: _selectedStatusFilter == status,
                        onSelected: (_) =>
                            setState(() => _selectedStatusFilter = status),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (controller.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (visible.isEmpty)
              const Expanded(
                child: Center(child: Text('Nenhum cooperado encontrado.')),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 650) {
                      return _buildCardsList(context, visible);
                    }
                    return _buildDataTable(context, visible);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(BuildContext context, List<CooperadoModel> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusChip(item.status),
                  ],
                ),
                const Divider(height: 20),
                Text('CPF: ${_formatCpf(item.cpf)}'),
                const SizedBox(height: 4),
                Text('E-mail: ${item.email}'),
                if (item.telefone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Telefone: ${_formatTelefone(item.telefone)}'),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Editar',
                      onPressed: () => _openForm(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Desativar',
                      onPressed: () => _confirmDelete(context, item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(BuildContext context, List<CooperadoModel> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('CPF')),
            DataColumn(label: Text('Telefone')),
            DataColumn(label: Text('E-mail')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.nome)),
              DataCell(Text(_formatCpf(item.cpf))),
              DataCell(Text(_formatTelefone(item.telefone))),
              DataCell(Text(item.email)),
              DataCell(_statusChip(item.status)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Editar',
                      onPressed: () => _openForm(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Desativar',
                      onPressed: () => _confirmDelete(context, item),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusChip(CooperadoStatus status) {
    Color color;
    switch (status) {
      case CooperadoStatus.ativo:
        color = Colors.green;
        break;
      case CooperadoStatus.inativo:
        color = Colors.grey;
        break;
      case CooperadoStatus.pendente:
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _openForm(BuildContext context, CooperadoModel? model) async {
    final controller = context.read<CooperadosController>();
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: model?.nome ?? '');
    final cpfController =
        TextEditingController(text: model != null ? _formatCpf(model.cpf) : '');
    final telefoneController = TextEditingController(
        text: model != null ? _formatTelefone(model.telefone) : '');
    final emailController = TextEditingController(text: model?.email ?? '');
    CooperadoStatus status = model?.status ?? CooperadoStatus.pendente;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              Text(model == null ? 'Cadastrar cooperado' : 'Editar cooperado'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o nome'
                              : null,
                    ),
                    TextFormField(
                      controller: cpfController,
                      decoration: const InputDecoration(labelText: 'CPF'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o CPF'
                              : null,
                    ),
                    TextFormField(
                      controller: telefoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o e-mail'
                              : null,
                    ),
                    if (model != null) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CooperadoStatus>(
                        initialValue: status,
                        items: CooperadoStatus.values.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          );
                        }).toList(),
                        onChanged: (value) => status = value ?? status,
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final payload = CooperadoModel(
                  id: model?.id,
                  nome: nomeController.text.trim(),
                  cpf: cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  telefone:
                      telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  email: emailController.text.trim(),
                  status: status,
                );

                try {
                  if (model == null) {
                    await controller.create(payload);
                  } else {
                    await controller.update(payload);
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Operação realizada com sucesso.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await controller.load();
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, CooperadoModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar desativação'),
        content: Text('Deseja desativar o cooperado ${model.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed == true && model.id != null && context.mounted) {
      try {
        await context.read<CooperadosController>().delete(model.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cooperado desativado com sucesso.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${e.toString()}')),
          );
        }
      }
    }
  }
}
