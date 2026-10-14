import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:infoeco3/core/network/authenticated_api_client.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infoeco3/core/storage/token_storage.dart';
import 'package:infoeco3/features/materiais/data/datasources/materiais_api_datasource.dart';
import 'package:infoeco3/features/materiais/data/models/material_model.dart';
import 'package:infoeco3/features/materiais/data/repositories/materiais_repository_impl.dart';
import 'package:infoeco3/features/materiais/presentation/controllers/materiais_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String createValidJwt() {
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': '123',
      'role': 'COOPERATIVA',
      'exp': exp,
    })));
    return '$header.$payload.sig';
  }

  group('MaterialModel tests', () {
    test('fromJson & toJson serialization', () {
      final json = {
        'id': '101',
        'nome': 'Plástico PET',
        'preco': 2.50,
        'partilha': 'Individual',
        'status': 'ATIVO',
      };

      final model = MaterialModel.fromJson(json);
      expect(model.id, '101');
      expect(model.nome, 'Plástico PET');
      expect(model.preco, 2.50);
      expect(model.partilha, 'Individual');
      expect(model.status, MaterialStatus.ativo);

      final serialized = model.toJson();
      expect(serialized['id'], '101');
      expect(serialized['nome'], 'Plástico PET');
      expect(serialized['preco'], 2.50);
      expect(serialized['partilha'], 'Individual');
      expect(serialized['status'], 'ATIVO');
    });

    test('toCreatePayload excludes id and enforces ATIVO status', () {
      final model = MaterialModel(
        id: '999',
        nome: 'Papelão',
        preco: 1.20,
        partilha: 'Geral',
        status: MaterialStatus.inativo,
      );

      final payload = model.toCreatePayload();
      expect(payload.containsKey('id'), isFalse);
      expect(payload['nome'], 'Papelão');
      expect(payload['preco'], 1.20);
      expect(payload['partilha'], 'Geral');
      expect(payload['status'], 'ATIVO');
    });
  });

  group('MateriaisApiDatasource tests', () {
    late TokenStorage tokenStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tokenStorage = TokenStorage();
      await tokenStorage.saveToken(createValidJwt());
    });

    test('getAll returns list of materials', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/materiais');
        return http.Response(
          jsonEncode([
            {
              'id': '1',
              'nome': 'Vidro',
              'preco': 0.80,
              'partilha': 'Geral',
              'status': 'ATIVO'
            }
          ]),
          200,
        );
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );
      final datasource = MateriaisApiDatasource(apiClient);

      final materials = await datasource.getAll();
      expect(materials.length, 1);
      expect(materials.first.nome, 'Vidro');
      expect(materials.first.preco, 0.80);
    });

    test('getByStatus calls status endpoint correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/materiais/status/ATIVO');
        return http.Response(
          jsonEncode([
            {
              'id': '2',
              'nome': 'Alumínio',
              'preco': 5.00,
              'partilha': 'Individual',
              'status': 'ATIVO'
            }
          ]),
          200,
        );
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );
      final datasource = MateriaisApiDatasource(apiClient);

      final materials = await datasource.getByStatus('ATIVO');
      expect(materials.length, 1);
      expect(materials.first.nome, 'Alumínio');
    });

    test('create sends POST request with payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/materiais');
        final body = jsonDecode(request.body);
        expect(body['nome'], 'Ferro');
        return http.Response(
          jsonEncode({
            'id': '3',
            'nome': 'Ferro',
            'preco': 1.50,
            'partilha': 'Geral',
            'status': 'ATIVO'
          }),
          200,
        );
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );
      final datasource = MateriaisApiDatasource(apiClient);

      final created = await datasource.create({
        'nome': 'Ferro',
        'preco': 1.50,
        'partilha': 'Geral',
        'status': 'ATIVO',
      });

      expect(created.id, '3');
      expect(created.nome, 'Ferro');
    });
  });

  group('MateriaisController tests', () {
    late TokenStorage tokenStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tokenStorage = TokenStorage();
      await tokenStorage.saveToken(createValidJwt());
    });

    test('load populates materiais and updates state', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': '10',
              'nome': 'Cobre',
              'preco': 25.00,
              'partilha': 'Individual',
              'status': 'ATIVO'
            }
          ]),
          200,
        );
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );
      final datasource = MateriaisApiDatasource(apiClient);
      final repository = MateriaisRepositoryImpl(datasource);
      final controller = MateriaisController(repository);

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.materiais.length, 1);
      expect(controller.materiais.first.nome, 'Cobre');
    });
  });
}
