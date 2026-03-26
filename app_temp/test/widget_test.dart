import 'package:flutter_test/flutter_test.dart';
import 'package:face_swap/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FaceSwapApp());
    // Just verify the app builds without crash
  });
}
