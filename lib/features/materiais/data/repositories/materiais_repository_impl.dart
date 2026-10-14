import '../../domain/repositories/materiais_repository.dart';
import '../datasources/materiais_api_datasource.dart';
import '../models/material_model.dart';

class MateriaisRepositoryImpl implements MateriaisRepository {
  MateriaisRepositoryImpl(this._datasource);

  final MateriaisApiDatasource _datasource;

  @override
  Future<List<MaterialModel>> getMateriais() {
    return _datasource.getAll();
  }

  @override
  Future<List<MaterialModel>> getMateriaisByStatus(MaterialStatus status) {
    final statusStr = status == MaterialStatus.ativo ? 'ATIVO' : 'INATIVO';
    return _datasource.getByStatus(statusStr);
  }

  @override
  Future<MaterialModel> getMaterialById(String id) {
    return _datasource.getById(id);
  }

  @override
  Future<MaterialModel> createMaterial(MaterialModel material) {
    return _datasource.create(material.toCreatePayload());
  }

  @override
  Future<MaterialModel> updateMaterial(String id, MaterialModel material) {
    return _datasource.update(id, material.toJson());
  }

  @override
  Future<void> deleteMaterial(String id) {
    return _datasource.delete(id);
  }
}
