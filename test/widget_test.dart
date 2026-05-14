import 'package:flutter_test/flutter_test.dart';

import 'package:rud_fits_ai/main.dart';

void main() {
  testWidgets('app abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const RudFitApp());

    expect(find.text('rud_fits_ai'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Registre-se'), findsOneWidget);
  });
}
