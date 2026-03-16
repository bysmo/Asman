import 'package:flutter_test/flutter_test.dart';
import 'package:asset_manager/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AssetManagerApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AssetManagerApp), findsOneWidget);
  });
}
