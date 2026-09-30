import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infoeco3/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String createMockJwt({required int expSeconds}) {
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': '1234567890',
      'name': 'Prefeitura Teste',
      'role': 'PREFEITURA',
      'exp': expSeconds,
    })));
    const signature = 'mockSignature';
    return '$header.$payload.$signature';
  }

  group('TokenStorage tests', () {
    late TokenStorage tokenStorage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tokenStorage = TokenStorage();
    });

    test('saveToken and getToken work properly', () async {
      await tokenStorage.saveToken('test_token_123');
      final token = await tokenStorage.getToken();
      expect(token, 'test_token_123');
    });

    test('clear removes access token', () async {
      await tokenStorage.saveToken('test_token_123');
      await tokenStorage.clear();
      final token = await tokenStorage.getToken();
      expect(token, isNull);
    });

    test('isTokenExpired detects expired JWTs', () {
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiredJwt = createMockJwt(expSeconds: nowInSeconds - 3600); // 1 hour ago
      final validJwt = createMockJwt(expSeconds: nowInSeconds + 3600); // 1 hour in future

      expect(TokenStorage.isTokenExpired(expiredJwt), isTrue);
      expect(TokenStorage.isTokenExpired(validJwt), isFalse);
    });

    test('getValidToken clears expired token automatically', () async {
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiredJwt = createMockJwt(expSeconds: nowInSeconds - 3600);

      await tokenStorage.saveToken(expiredJwt);
      final retrievedToken = await tokenStorage.getValidToken();

      expect(retrievedToken, isNull);
      expect(await tokenStorage.getToken(), isNull);
    });

    test('getValidToken returns valid unexpired token', () async {
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final validJwt = createMockJwt(expSeconds: nowInSeconds + 3600);

      await tokenStorage.saveToken(validJwt);
      final retrievedToken = await tokenStorage.getValidToken();

      expect(retrievedToken, validJwt);
    });
  });
}
