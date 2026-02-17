import 'package:flutter_test/flutter_test.dart';

import 'package:cx_controller/main.dart';
import 'package:cx_controller/services/settings_service.dart';

void main() {
  testWidgets('App renders dashboard with connection card',
      (WidgetTester tester) async {
    final settings = SettingsService();
    await tester.pumpWidget(CxControllerApp(settings: settings));

    expect(find.text('Drone Connection'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
  });

  testWidgets('Navigation shows all tabs', (WidgetTester tester) async {
    final settings = SettingsService();
    await tester.pumpWidget(CxControllerApp(settings: settings));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Flight'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Mission'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
