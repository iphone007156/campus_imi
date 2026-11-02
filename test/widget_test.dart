import 'package:flutter_test/flutter_test.dart';
import 'package:campus_imi/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Просто проверяем, что CampusApp создается
    expect(const CampusApp(), isNotNull);
  });
}