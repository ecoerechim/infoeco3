import '../../data/models/cooperativa_model.dart';

abstract class CooperativasRepository {
  Future<List<CooperativaModel>> getAll();
  Future<CooperativaModel> create(Map<String, dynamic> payload);
  Future<CooperativaModel> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
}
