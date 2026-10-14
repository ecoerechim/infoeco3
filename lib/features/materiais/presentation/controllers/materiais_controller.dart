import 'package:flutter/foundation.dart';

import '../../../../core/network/authenticated_api_client.dart';
import '../../data/models/material_model.dart';
import '../../domain/repositories/materiais_repository.dart';

class MateriaisController extends ChangeNotifier {
  MateriaisController(this._repository);

  final MateriaisRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<MaterialModel> materiais = [];

  String _formatError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return e.toString();
  }

  Future<void> load({MaterialStatus? status}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (status != null) {
        materiais = await _repository.getMateriaisByStatus(status);
      } else {
        materiais = await _repository.getMateriais();
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = _formatError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(MaterialModel model) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.createMaterial(model);
      await load();
    } catch (e) {
      errorMessage = _formatError(e);
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(MaterialModel model) async {
    if (model.id == null) {
      throw Exception('ID do material não informado.');
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateMaterial(model.id!, model);
      await load();
    } catch (e) {
      errorMessage = _formatError(e);
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteMaterial(id);
      await load();
    } catch (e) {
      errorMessage = _formatError(e);
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
