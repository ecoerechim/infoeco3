import '../../../../core/network/authenticated_api_client.dart';

import '../models/cooperado_model.dart';

class CooperadosApiDatasource {
  CooperadosApiDatasource(this._client);

  final AuthenticatedApiClient _client;

  Future<List<CooperadoModel>> getAll() async {
    final response = await _client.request('GET', '/api/cooperados');
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      return [];
    }
    final payload = decoded is List ? decoded : [decoded];
    return payload
        .whereType<Map>()
        .map((item) => CooperadoModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CooperadoModel> create(Map<String, dynamic> payload) async {
    final response =
        await _client.request('POST', '/api/cooperados', body: payload);
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao criar cooperado.');
    }
    return CooperadoModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<CooperadoModel> update(String id, Map<String, dynamic> payload) async {
    final response =
        await _client.request('PUT', '/api/cooperados/$id', body: payload);
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao atualizar cooperado.');
    }
    return CooperadoModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> delete(String id) async {
    await _client.request('DELETE', '/api/cooperados/$id');
  }
}
