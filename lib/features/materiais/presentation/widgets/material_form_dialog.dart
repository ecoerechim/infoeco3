import 'package:flutter/material.dart';

import '../../data/models/material_model.dart';

class MaterialFormDialog extends StatefulWidget {
  const MaterialFormDialog({
    super.key,
    this.material,
  });

  final MaterialModel? material;

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _precoController;
  late String _partilha;
  late MaterialStatus _status;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.material?.nome ?? '');
    _precoController = TextEditingController(
      text: widget.material != null ? widget.material!.preco.toString() : '',
    );
    _partilha = widget.material?.partilha ?? 'Individual';
    _status = widget.material?.status ?? MaterialStatus.ativo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final preco = double.tryParse(_precoController.text.trim()) ?? 0.0;

    final model = MaterialModel(
      id: widget.material?.id,
      nome: _nomeController.text.trim(),
      preco: preco,
      partilha: _partilha,
      status: _status,
    );

    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.material != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Material' : 'Novo Material'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Material',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do material';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor / kg (R\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o valor por kg';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Informe um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _partilha,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Partilha',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Individual', child: Text('Individual')),
                  DropdownMenuItem(value: 'Geral', child: Text('Geral')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _partilha = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MaterialStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: MaterialStatus.ativo,
                    child: Text('Ativo'),
                  ),
                  DropdownMenuItem(
                    value: MaterialStatus.inativo,
                    child: Text('Inativo'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}
