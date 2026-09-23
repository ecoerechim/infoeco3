import 'package:flutter/foundation.dart';

import '../../data/models/cooperado_model.dart';
import '../../domain/repositories/cooperados_repository.dart';

class CooperadosController extends ChangeNotifier {
  CooperadosController(this._repository);

  final CooperadosRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<CooperadoModel> cooperados = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      cooperados = await _repository.getAll();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(CooperadoModel model) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.create(model.toCreatePayload());
      await load();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(CooperadoModel model) async {
    if (model.id == null) {
      throw Exception('Id do cooperado não informado.');
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.update(model.id!, model.toCreatePayload());
      await load();
    } catch (e) {
      errorMessage = e.toString();
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
      await _repository.delete(id);
      await load();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
