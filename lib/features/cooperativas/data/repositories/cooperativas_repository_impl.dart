import '../../domain/repositories/cooperativas_repository.dart';
import '../datasources/cooperativas_api_datasource.dart';
import '../models/cooperativa_model.dart';

class CooperativasRepositoryImpl implements CooperativasRepository {
  CooperativasRepositoryImpl(this._datasource);

  final CooperativasApiDatasource _datasource;

  @override
  Future<List<CooperativaModel>> getAll() => _datasource.getAll();

  @override
  Future<CooperativaModel> create(Map<String, dynamic> payload) =>
      _datasource.create(payload);

  @override
  Future<CooperativaModel> update(String id, Map<String, dynamic> payload) =>
      _datasource.update(id, payload);

  @override
  Future<void> delete(String id) => _datasource.delete(id);
}
