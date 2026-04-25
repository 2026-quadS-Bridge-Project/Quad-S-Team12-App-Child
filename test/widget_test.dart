import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_k/app/app.dart';
import 'package:bridge_k/features/child_home/presentation/pages/child_home_page.dart';

void main() {
  testWidgets('child start screen renders primary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BridgeKApp());
    await tester.pumpAndSettle();

    expect(find.text('Bridge'), findsOneWidget);
    expect(find.text('자녀 회원가입'), findsOneWidget);
    expect(find.text('이미 계정이 있나요?'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('child home onboarding dismisses from any tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChildHomePage(showOnboarding: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('부모님 계정과 연결하기'), findsOneWidget);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(find.text('부모님 계정과 연결하기'), findsNothing);
    expect(find.text('오늘의 시간'), findsOneWidget);
  });
}
