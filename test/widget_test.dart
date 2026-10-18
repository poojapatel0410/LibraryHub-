import 'package:flutter_test/flutter_test.dart';
import 'package:library_hub/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(const LibraryHubApp(), isNotNull);
  });
}
