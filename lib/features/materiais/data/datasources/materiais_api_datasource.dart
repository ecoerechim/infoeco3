import '../../../../core/network/authenticated_api_client.dart';
import '../models/material_model.dart';

class MateriaisApiDatasource {
  MateriaisApiDatasource(this._client);

  final AuthenticatedApiClient _client;

  Future<List<MaterialModel>> getAll() async {
    final response = await _client.request('GET', '/api/materiais');
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      return [];
    }

    final payload = decoded is List ? decoded : [decoded];
    return payload
        .whereType<Map>()
        .map((item) => MaterialModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MaterialModel>> getByStatus(String status) async {
    final response = await _client.request('GET', '/api/materiais/status/$status');
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      return [];
    }

    final payload = decoded is List ? decoded : [decoded];
    return payload
        .whereType<Map>()
        .map((item) => MaterialModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MaterialModel> getById(String id) async {
    final response = await _client.request('GET', '/api/materiais/$id');
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao buscar material.');
    }
    return MaterialModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<MaterialModel> create(Map<String, dynamic> payload) async {
    final response =
        await _client.request('POST', '/api/materiais', body: payload);
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao criar material.');
    }
    return MaterialModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<MaterialModel> update(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _client.request('PUT', '/api/materiais/$id', body: payload);
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao atualizar material.');
    }
    return MaterialModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> delete(String id) async {
    await _client.request('DELETE', '/api/materiais/$id');
  }
}
