import 'package:flutter_test/flutter_test.dart';
import 'package:quad_s_team12_app/app/app.dart';

void main() {
  testWidgets('child start screen renders primary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuadSTeam12App());
    await tester.pumpAndSettle();

    expect(find.text('Bridge'), findsOneWidget);
    expect(find.text('자녀 회원가입'), findsOneWidget);
    expect(find.text('이미 계정이 있나요?'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}
