import '../../data/models/material_model.dart';

abstract class MateriaisRepository {
  Future<List<MaterialModel>> getMateriais();
  Future<List<MaterialModel>> getMateriaisByStatus(MaterialStatus status);
  Future<MaterialModel> getMaterialById(String id);
  Future<MaterialModel> createMaterial(MaterialModel material);
  Future<MaterialModel> updateMaterial(String id, MaterialModel material);
  Future<void> deleteMaterial(String id);
}
