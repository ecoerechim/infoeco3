import '../../data/models/cooperado_model.dart';

abstract class CooperadosRepository {
  Future<List<CooperadoModel>> getAll();
  Future<CooperadoModel> create(Map<String, dynamic> payload);
  Future<CooperadoModel> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
}
