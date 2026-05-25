import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_k/app/app.dart';
import 'package:bridge_k/app/router/app_router.dart';
import 'package:bridge_k/core/auth/auth_session.dart';
import 'package:bridge_k/features/my_page/presentation/pages/my_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    appRouter.go('/');
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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

  testWidgets('cached login opens child home dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.loggedInKey: true,
      AuthSession.usernameKey: 'abcd00',
    });

    await tester.pumpWidget(const BridgeKApp());
    await tester.pumpAndSettle();

    // Per Round 1 fix: cached login now goes to /child-home (dashboard),
    // not /child-home/onboarding. Assert always-present section headers
    // instead of the onboarding overlay copy.
    expect(find.text('오늘의 시간'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsOneWidget);
    expect(find.text('Bridge'), findsNothing);
  });

  testWidgets('child my page renders account details and actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MyPage()));
    await tester.pumpAndSettle();

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('회원유형'), findsOneWidget);
    expect(find.text('자녀회원'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('abcd00'), findsOneWidget);
    expect(find.text('자녀코드'), findsOneWidget);
    expect(find.text('XY785eZ'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('수정하기'), findsOneWidget);
    expect(find.text('탈퇴하기'), findsOneWidget);
    // 로그아웃 button intentionally absent per Figma 773:11103 (Round 2 fix).
  });

  // TODO(test): add 탈퇴하기 happy-path test (tap 탈퇴하기 → 확인 →
  // expect navigation to /mypage/delete-complete and AuthSession cleared).
  // The standalone logout test was removed because the UI no longer
  // surfaces a 로그아웃 control per Figma; logout now only happens as a
  // side effect of account deletion confirmation.
}
