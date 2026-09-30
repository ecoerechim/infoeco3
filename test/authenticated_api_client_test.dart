import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infoeco3/core/network/authenticated_api_client.dart';
import 'package:infoeco3/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String createValidJwt() {
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': '123',
      'role': 'PREFEITURA',
      'exp': exp,
    })));
    return '$header.$payload.sig';
  }

  group('AuthenticatedApiClient tests', () {
    late TokenStorage tokenStorage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tokenStorage = TokenStorage();
    });

    test('Throws 401 ApiException if token is missing and requireAuth is true', () async {
      final mockClient = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );

      await expectLater(
        apiClient.request('GET', '/api/cooperativas'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('Includes Authorization: Bearer <token> in headers when valid token exists', () async {
      final validJwt = createValidJwt();
      await tokenStorage.saveToken(validJwt);

      Map<String, String>? capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response('[{"id":"1","nome":"Coop Teste"}]', 200);
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );

      final response = await apiClient.request('GET', '/api/cooperativas');

      expect(response.statusCode, 200);
      expect(capturedHeaders, isNotNull);
      expect(capturedHeaders!['Authorization'], 'Bearer $validJwt');
    });

    test('Clears token and throws 401 ApiException when server returns 401', () async {
      final validJwt = createValidJwt();
      await tokenStorage.saveToken(validJwt);

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });

      final apiClient = AuthenticatedApiClient(
        tokenStorage,
        baseUrl: 'http://localhost:8086',
        httpClient: mockClient,
      );

      await expectLater(
        apiClient.request('POST', '/api/cooperativas', body: {'nome': 'Coop'}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Verify token was cleared from storage
      expect(await tokenStorage.getToken(), isNull);
    });
  });
}
