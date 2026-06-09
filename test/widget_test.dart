import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_k/app/app.dart';
import 'package:bridge_k/app/router/app_router.dart';
import 'package:bridge_k/core/auth/auth_session.dart';
import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/core/services/device_block_controller.dart';
import 'package:bridge_k/features/child_home/presentation/pages/child_home_page.dart';
import 'package:bridge_k/features/mission/presentation/pages/mission_info_page.dart';
import 'package:bridge_k/features/my_page/presentation/pages/my_page.dart';
import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';
import 'package:bridge_k/features/time_setup/data/repositories/time_setup_repository.dart';
import 'package:bridge_k/features/time_setup/presentation/pages/time_setup_root_page.dart';
import 'package:dio/dio.dart';
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

  testWidgets('child home keeps today time when reward pool load fails', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.path == '/api/v1/schedules/daily') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'targetDate': '2026-06-09',
                  'baseMinutes': 60,
                  'extendedMinutes': 0,
                  'totalAvailableMinutes': 60,
                },
              ),
            );
            return;
          }
          if (options.path == '/api/v1/children/22/policies') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 500,
                  data: <String, dynamic>{
                    'code': 'COMMON500',
                    'message': '서버 내부 오류가 발생했습니다.',
                  },
                ),
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'unexpected ${options.method} ${options.path}',
            ),
          );
        },
      ),
    );
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('남은시간'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('보너스시간'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('child home shows monthly reward pool as bonus time', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.path == '/api/v1/schedules/daily') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'isSuccess': true,
                  'data': <String, dynamic>{
                    'targetDate': '2026-06-09',
                    'baseMinutes': 60,
                    'extendedMinutes': 15,
                    'totalAvailableMinutes': 75,
                  },
                },
              ),
            );
            return;
          }
          if (options.path == '/api/v1/children/22/policies') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'isSuccess': true,
                  'data': <String, dynamic>{'accumulatedRewardTime': 30},
                },
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'unexpected ${options.method} ${options.path}',
            ),
          );
        },
      ),
    );
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('남은시간'), findsOneWidget);
    expect(find.text('01:15'), findsOneWidget);
    expect(find.text('보너스시간'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
  });

  testWidgets('child home configures native ledger with child date key', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');
    DeviceBlockController.debugIsSupportedOverride = true;
    const MethodChannel channel = MethodChannel(
      'com.gdg.bridge_k/device_block',
    );
    final List<MethodCall> channelCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          channelCalls.add(call);
          return switch (call.method) {
            'configureScreenTime' => true,
            'remainingScreenTimeSeconds' => 75 * 60,
            'hasPermission' => true,
            'setBlocked' => true,
            _ => null,
          };
        });
    addTearDown(() {
      DeviceBlockController.debugIsSupportedOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.path == '/api/v1/schedules/daily') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'isSuccess': true,
                  'data': <String, dynamic>{
                    'targetDate': '2026-06-09',
                    'baseMinutes': 60,
                    'extendedMinutes': 15,
                    'totalAvailableMinutes': 75,
                  },
                },
              ),
            );
            return;
          }
          if (options.path == '/api/v1/children/22/policies') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'isSuccess': true,
                  'data': <String, dynamic>{'accumulatedRewardTime': 30},
                },
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'unexpected ${options.method} ${options.path}',
            ),
          );
        },
      ),
    );
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    final MethodCall configureCall = channelCalls.firstWhere(
      (MethodCall call) => call.method == 'configureScreenTime',
    );
    final Map<Object?, Object?> arguments =
        configureCall.arguments as Map<Object?, Object?>;
    final DateTime today = DateTime.now();
    final String dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    expect(arguments['key'], '22:$dateKey:today-screen-time');
    expect(arguments['allocatedSeconds'], 75 * 60);
    expect(find.text('01:15'), findsOneWidget);
  });

  testWidgets('child home keeps zero-minute daily schedule as spent time', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.path == '/api/v1/schedules/daily') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'isSuccess': true,
                  'data': <String, dynamic>{
                    'targetDate': '2026-06-09',
                    'baseMinutes': 0,
                    'extendedMinutes': 0,
                    'totalAvailableMinutes': 0,
                  },
                },
              ),
            );
            return;
          }
          if (options.path == '/api/v1/children/22/policies') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'isSuccess': true,
                  'data': <String, dynamic>{'accumulatedRewardTime': 0},
                },
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'unexpected ${options.method} ${options.path}',
            ),
          );
        },
      ),
    );
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('남은시간'), findsOneWidget);
    expect(find.text('보너스시간'), findsOneWidget);
    expect(find.text('00:00'), findsNWidgets(2));
    expect(find.text('아직 등록된 시간 계획이 없어요.'), findsNothing);
  });

  testWidgets(
    'child home applies blocker after permission grant at zero time',
    (WidgetTester tester) async {
      await AuthSession.saveLogin(username: 'child', memberId: '22');
      DeviceBlockController.debugIsSupportedOverride = true;
      const MethodChannel channel = MethodChannel(
        'com.gdg.bridge_k/device_block',
      );
      final List<MethodCall> channelCalls = <MethodCall>[];
      bool hasPermission = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            channelCalls.add(call);
            return switch (call.method) {
              'hasPermission' => hasPermission,
              'requestPermission' => null,
              'setBlocked' => true,
              'configureScreenTime' => true,
              'remainingScreenTimeSeconds' => 0,
              _ => null,
            };
          });
      addTearDown(() {
        DeviceBlockController.debugIsSupportedOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                if (options.path == '/api/v1/schedules/daily') {
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'targetDate': '2026-06-09',
                        'baseMinutes': 0,
                        'extendedMinutes': 0,
                        'totalAvailableMinutes': 0,
                      },
                    ),
                  );
                  return;
                }
                if (options.path == '/api/v1/children/22/policies') {
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{'accumulatedRewardTime': 0},
                    ),
                  );
                  return;
                }
                handler.reject(
                  DioException(
                    requestOptions: options,
                    message: 'unexpected ${options.method} ${options.path}',
                  ),
                );
              },
        ),
      );
      addTearDown(() => dio.close(force: true));

      await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('화면 시간 차감을 위해 접근성 권한을 켜주세요.'), findsOneWidget);
      expect(
        channelCalls.any(
          (MethodCall call) =>
              call.method == 'setBlocked' &&
              (call.arguments as Map<Object?, Object?>?)?['blocked'] == true,
        ),
        isFalse,
      );

      hasPermission = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        channelCalls.any(
          (MethodCall call) =>
              call.method == 'setBlocked' &&
              (call.arguments as Map<Object?, Object?>?)?['blocked'] == true,
        ),
        isTrue,
      );
    },
  );

  testWidgets('child home settles backend usage when screen time is spent', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');
    DeviceBlockController.debugIsSupportedOverride = true;
    const MethodChannel channel = MethodChannel(
      'com.gdg.bridge_k/device_block',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          return switch (call.method) {
            'configureScreenTime' => true,
            'remainingScreenTimeSeconds' => 0,
            'hasPermission' => true,
            'setBlocked' => true,
            _ => null,
          };
        });
    addTearDown(() {
      DeviceBlockController.debugIsSupportedOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final List<RequestOptions> requests = <RequestOptions>[];
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          requests.add(options);
          if (options.path == '/api/v1/schedules/daily') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'targetDate': '2026-06-09',
                  'baseMinutes': 60,
                  'extendedMinutes': 15,
                  'totalAvailableMinutes': 75,
                },
              ),
            );
            return;
          }
          if (options.path == '/api/v1/children/22/policies') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'accumulatedRewardTime': 0},
              ),
            );
            return;
          }
          if (options.path == '/api/v1/schedules/settle') {
            handler.resolve(
              Response<dynamic>(requestOptions: options, statusCode: 200),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'unexpected ${options.method} ${options.path}',
            ),
          );
        },
      ),
    );
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final RequestOptions settle = requests.firstWhere(
      (RequestOptions options) => options.path == '/api/v1/schedules/settle',
    );
    expect(settle.method, 'POST');
    expect(settle.queryParameters['actualUsed'], 75);
    expect(settle.queryParameters['date'], isA<String>());
  });

  testWidgets(
    'child home does not fall back to monthly policy when daily schedule is missing',
    (WidgetTester tester) async {
      await AuthSession.saveLogin(username: 'child', memberId: '22');
      DeviceBlockController.debugIsSupportedOverride = true;
      const MethodChannel channel = MethodChannel(
        'com.gdg.bridge_k/device_block',
      );
      final List<MethodCall> channelCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            channelCalls.add(call);
            return switch (call.method) {
              'clearScreenTime' => true,
              _ => null,
            };
          });
      addTearDown(() {
        DeviceBlockController.debugIsSupportedOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                if (options.path == '/api/v1/schedules/daily') {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      response: Response<dynamic>(
                        requestOptions: options,
                        statusCode: 404,
                        data: <String, dynamic>{
                          'code': 'SCHEDULE404',
                          'message': '오늘 배정 시간이 없습니다.',
                        },
                      ),
                    ),
                  );
                  return;
                }
                handler.reject(
                  DioException(
                    requestOptions: options,
                    message: 'unexpected ${options.method} ${options.path}',
                  ),
                );
              },
        ),
      );
      addTearDown(() => dio.close(force: true));

      await tester.pumpWidget(MaterialApp(home: ChildHomePage(dio: dio)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('아직 등록된 시간 계획이 없어요.'), findsOneWidget);
      expect(find.text('남은시간'), findsNothing);
      expect(find.text('10:00'), findsNothing);
      expect(
        channelCalls.any((MethodCall call) => call.method == 'clearScreenTime'),
        isTrue,
      );
    },
  );

  testWidgets('time confirm route opens without initState context assertion', (
    WidgetTester tester,
  ) async {
    appRouter.go('/child-home/time-setup/confirm?variant=empty');

    await tester.pumpWidget(const BridgeKApp());
    await tester.pumpAndSettle();

    expect(find.text('시간설정'), findsOneWidget);
    expect(find.text('이번달 시간규칙이 설정되지 않았습니다.'), findsOneWidget);
  });

  testWidgets('time setup blocks when parent monthly policy is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TimeSetupRootPage(
          repository: _MissingPolicyTimeSetupRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('부모님이 아직 이번 달 시간을 설정하지 않았어요.'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
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

class _MissingPolicyTimeSetupRepository implements TimeSetupRepository {
  @override
  Future<Result<TimeSchedule?>> fetchCurrentSchedule() async {
    return Result<TimeSchedule?>.failure('부모님이 아직 이번 달 시간을 설정하지 않았어요.');
  }

  @override
  Future<Result<TimeSchedule>> fetchPreviousWeekSchedule() async {
    return Result<TimeSchedule>.failure('부모님이 아직 이번 달 시간을 설정하지 않았어요.');
  }

  @override
  Future<Result<void>> saveSchedule(TimeSchedule schedule) async {
    return Result<void>.failure('부모님이 아직 이번 달 시간을 설정하지 않았어요.');
  }
}
