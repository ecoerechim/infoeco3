import 'dart:convert';

import '../../../../core/network/authenticated_api_client.dart';
import '../models/cooperativa_model.dart';

class CooperativasApiDatasource {
  CooperativasApiDatasource(this._client);

  final AuthenticatedApiClient _client;

  Future<List<CooperativaModel>> getAll() async {
    final response = await _client.request('GET', '/api/cooperativas');
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      return [];
    }

    final payload = decoded is List ? decoded : [decoded];
    return payload
        .whereType<Map>()
        .map((item) =>
            CooperativaModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CooperativaModel> create(Map<String, dynamic> payload) async {
    final response =
        await _client.request('POST', '/api/cooperativas', body: payload);
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao criar cooperativa.');
    }
    return CooperativaModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<CooperativaModel> update(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _client.request('PUT', '/api/cooperativas/$id', body: payload);
    final decoded = _client.decodeBody(response);
    if (decoded == null) {
      throw ApiException(204, 'Resposta vazia ao atualizar cooperativa.');
    }
    return CooperativaModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> delete(String id) async {
    await _client.request('DELETE', '/api/cooperativas/$id');
  }
}
