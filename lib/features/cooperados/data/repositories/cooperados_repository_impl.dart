import '../../domain/repositories/cooperados_repository.dart';
import '../datasources/cooperados_api_datasource.dart';
import '../models/cooperado_model.dart';

class CooperadosRepositoryImpl implements CooperadosRepository {
  CooperadosRepositoryImpl(this._datasource);

  final CooperadosApiDatasource _datasource;

  @override
  Future<List<CooperadoModel>> getAll() => _datasource.getAll();

  @override
  Future<CooperadoModel> create(Map<String, dynamic> payload) =>
      _datasource.create(payload);

  @override
  Future<CooperadoModel> update(String id, Map<String, dynamic> payload) =>
      _datasource.update(id, payload);

  @override
  Future<void> delete(String id) => _datasource.delete(id);
}
