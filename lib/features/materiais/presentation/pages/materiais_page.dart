import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../xlsx_exporter.dart';
import '../../data/datasources/materiais_api_datasource.dart';
import '../../data/models/material_model.dart';
import '../../data/repositories/materiais_repository_impl.dart';
import '../controllers/materiais_controller.dart';
import '../widgets/material_form_dialog.dart';

class MateriaisPage extends StatelessWidget {
  const MateriaisPage({
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
      )..load(),
      child: _MateriaisPageView(viewOnly: viewOnly),
    );
  }
}

class _MateriaisPageView extends StatefulWidget {
  const _MateriaisPageView({required this.viewOnly});

  final bool viewOnly;

  @override
  State<_MateriaisPageView> createState() => _MateriaisPageViewState();
}

class _MateriaisPageViewState extends State<_MateriaisPageView> {
  final TextEditingController _searchController = TextEditingController();
  MaterialStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportMateriaisXlsx(List<MaterialModel> items) async {
    final headers = ['Material', 'Valor/kg (R\$)', 'Tipo de Partilha', 'Status'];
    final rows = items.map((m) {
      return [
        m.nome,
        m.preco.toStringAsFixed(2),
        m.partilha,
        m.status.label,
      ];
    }).toList();

    await XlsxExporter.exportData(
      context,
      headers: headers,
      rows: rows,
      fileName: 'materiais_cooperativa',
    );
  }

  Future<void> _openForm(BuildContext context, [MaterialModel? material]) async {
    final controller = context.read<MateriaisController>();
    final result = await showDialog<MaterialModel>(
      context: context,
      builder: (dialogContext) => MaterialFormDialog(material: material),
    );

    if (result != null && context.mounted) {
      try {
        if (material == null) {
          await controller.create(result);
        } else {
          await controller.update(result);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operação realizada com sucesso.')),
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

  Future<void> _confirmDelete(BuildContext context, MaterialModel model) async {
    final controller = context.read<MateriaisController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar desativação'),
        content: Text('Deseja desativar o material "${model.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed == true && model.id != null && context.mounted) {
      try {
        await controller.delete(model.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material desativado com sucesso.')),
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

  Widget _statusChip(MaterialStatus status) {
    final isAtivo = status == MaterialStatus.ativo;
    final color = isAtivo ? Colors.green : Colors.grey;
    return Chip(
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MateriaisController>();
    final query = _searchController.text.trim().toLowerCase();

    final visible = controller.materiais.where((item) {
      if (_statusFilter != null && item.status != _statusFilter) {
        return false;
      }
      return item.nome.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Materiais'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Relatório',
            onPressed: visible.isEmpty ? null : () => _exportMateriaisXlsx(visible),
          ),
        ],
      ),
      floatingActionButton: widget.viewOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add),
              label: const Text('Novo Material'),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar material por nome',
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
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Ativos'),
                    selected: _statusFilter == MaterialStatus.ativo,
                    onSelected: (_) => setState(() => _statusFilter = MaterialStatus.ativo),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Inativos'),
                    selected: _statusFilter == MaterialStatus.inativo,
                    onSelected: (_) => setState(() => _statusFilter = MaterialStatus.inativo),
                  ),
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
                child: Center(child: Text('Nenhum material encontrado.')),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
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

  Widget _buildCardsList(BuildContext context, List<MaterialModel> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.nome,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    _statusChip(item.status),
                  ],
                ),
                const Divider(height: 16),
                Text('Preço / kg: R\$ ${item.preco.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('Tipo de Partilha: ${item.partilha}'),
                if (!widget.viewOnly) ...[
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(BuildContext context, List<MaterialModel> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Material', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Valor/kg', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Tipo de Partilha', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            if (!widget.viewOnly)
              const DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.nome)),
              DataCell(Text('R\$ ${item.preco.toStringAsFixed(2)}')),
              DataCell(Text(item.partilha)),
              DataCell(_statusChip(item.status)),
              if (!widget.viewOnly)
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
}
