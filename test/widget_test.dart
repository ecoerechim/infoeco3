import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infoeco3/features/auth/data/models/login_response.dart';
import 'package:infoeco3/widgets/large_menu_button.dart';

void main() {
  testWidgets('LargeMenuButton renders and handles taps',
      (WidgetTester tester) async {
    var wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LargeMenuButton(
            onPressed: () => wasPressed = true,
            backgroundColor: Colors.green,
            child: const Text('TESTE'),
          ),
        ),
      ),
    );

    expect(find.text('TESTE'), findsOneWidget);
    expect(find.byType(LargeMenuButton), findsOneWidget);

    await tester.tap(find.text('TESTE'));
    expect(wasPressed, isTrue);
  });

  test('LoginResponse.fromJson accepts backend token keys used by the API', () {
    final response = LoginResponse.fromJson({
      'token': 'jwt-prefeitura-123',
      'refreshToken': 'refresh-prefeitura-456',
      'nome': 'Prefeitura Teste',
      'role': 'PREFEITURA',
    });

    expect(response.accessToken, 'jwt-prefeitura-123');
    expect(response.refreshToken, 'refresh-prefeitura-456');
    expect(response.role, 'prefeitura');
  });
}
