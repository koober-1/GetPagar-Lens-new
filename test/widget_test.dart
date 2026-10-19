import 'package:flutter_test/flutter_test.dart';
import 'package:getpagar_lens/app/app.dart';
import 'package:getpagar_lens/core/config/env_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EnvConfig.load();
  });

  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Account Login'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
