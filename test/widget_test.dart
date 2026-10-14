import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_kuliner/main.dart';

void main() {
  testWidgets('POS Kuliner app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PosKulinerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify store title loads
    expect(find.text('Warung Kuliner Sedap'), findsOneWidget);

    // Verify navigation destination exists
    expect(find.text('Kasir'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });
}
