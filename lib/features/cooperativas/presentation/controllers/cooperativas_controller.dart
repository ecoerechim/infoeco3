import 'package:flutter/foundation.dart';

import '../../data/models/cooperativa_model.dart';
import '../../domain/repositories/cooperativas_repository.dart';

class CooperativasController extends ChangeNotifier {
  CooperativasController(this._repository);

  final CooperativasRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<CooperativaModel> cooperativas = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      cooperativas = await _repository.getAll();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(CooperativaModel model) async {
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

  Future<void> update(CooperativaModel model) async {
    if (model.id == null) {
      throw Exception('Id da cooperativa não informado.');
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
