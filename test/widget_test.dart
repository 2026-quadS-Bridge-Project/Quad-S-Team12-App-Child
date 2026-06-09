import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_k/app/app.dart';
import 'package:bridge_k/app/router/app_router.dart';
import 'package:bridge_k/core/auth/auth_session.dart';
import 'package:bridge_k/features/mission/presentation/pages/mission_info_page.dart';
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

  testWidgets('time confirm route opens without initState context assertion', (
    WidgetTester tester,
  ) async {
    appRouter.go('/child-home/time-setup/confirm?variant=empty');

    await tester.pumpWidget(const BridgeKApp());
    await tester.pumpAndSettle();

    expect(find.text('시간설정'), findsOneWidget);
    expect(find.text('이번달 시간규칙이 설정되지 않았습니다.'), findsOneWidget);
  });

  testWidgets('rejected mission can re-enter perform flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MissionInfoPage(missionId: '2')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('수행정보'));
    await tester.pumpAndSettle();

    expect(find.text('미션이 반려되었어요.'), findsOneWidget);
    expect(find.text('다시 수행하기'), findsOneWidget);

    await tester.tap(find.text('다시 수행하기'));
    await tester.pumpAndSettle();

    expect(find.text('미션수행'), findsOneWidget);
    expect(find.text('사진을 업로드해주세요'), findsOneWidget);
  });

  testWidgets('child my page renders account details and actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.usernameKey: 'abcd00',
      AuthSession.childCodeKey: 'XY785eZ',
    });

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
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('탈퇴하기'), findsOneWidget);
  });

  testWidgets('child my page logout clears session and returns home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.loggedInKey: true,
      AuthSession.usernameKey: 'abcd00',
      AuthSession.childCodeKey: 'XY785eZ',
    });
    await AuthSession.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    appRouter.go('/mypage');

    await tester.pumpWidget(const BridgeKApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(find.text('로그아웃하시겠습니까?'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(await AuthSession.isLoggedIn(), isFalse);
    expect(await AuthSession.accessToken(), isNull);
    expect(await AuthSession.refreshToken(), isNull);
    expect(find.text('Bridge'), findsOneWidget);
  });

  // TODO(test): add 탈퇴하기 happy-path test (tap 탈퇴하기 → 확인 →
  // expect navigation to /mypage/delete-complete and AuthSession cleared).
}
