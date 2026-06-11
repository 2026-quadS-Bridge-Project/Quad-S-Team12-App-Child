import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_k/app/app.dart';
import 'package:bridge_k/app/router/app_router.dart';
import 'package:bridge_k/core/auth/auth_session.dart';
import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/core/services/device_block_controller.dart';
import 'package:bridge_k/core/services/fcm_bootstrap.dart';
import 'package:bridge_k/core/services/fcm_messaging_service.dart';
import 'package:bridge_k/core/widgets/inputs/bridge_photo_tile.dart';
import 'package:bridge_k/features/child_home/presentation/pages/child_home_page.dart';
import 'package:bridge_k/features/devices/data/repositories/device_repository.dart';
import 'package:bridge_k/features/mission/data/models/mission.dart'
    as mission_model;
import 'package:bridge_k/features/mission/data/repositories/mission_repository.dart'
    as mission_repository;
import 'package:bridge_k/features/mission/presentation/pages/mission_info_page.dart';
import 'package:bridge_k/features/my_page/presentation/pages/my_page.dart';
import 'package:bridge_k/features/notifications/data/models/notification_item.dart';
import 'package:bridge_k/features/notifications/data/repositories/notification_repository.dart';
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
    expect(find.text('월간 남은시간'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets(
    'child home shows monthly reward pool as monthly remaining time',
    (WidgetTester tester) async {
      await AuthSession.saveLogin(username: 'child', memberId: '22');
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
      expect(find.text('월간 남은시간'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    },
  );

  testWidgets(
    'child home shows notification dot after foreground FCM refresh',
    (WidgetTester tester) async {
      await FcmBootstrap.dispose();
      addTearDown(FcmBootstrap.dispose);

      final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
      await FcmBootstrap.initialize(
        messagingService: messaging,
        deviceRepository: const _NoopDeviceRepository(),
      );

      final _MutableNotificationRepository notifications =
          _MutableNotificationRepository(<NotificationItem>[]);
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

      await tester.pumpWidget(
        MaterialApp(
          home: ChildHomePage(
            dio: dio,
            notificationRepository: notifications,
            missionRepository: _MutableMissionRepository(
              <mission_model.Mission>[],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('child-home-notification-unread-dot'),
        ),
        findsNothing,
      );

      notifications.items = <NotificationItem>[
        NotificationItem(
          id: '17',
          type: NotificationType.missionCompleted,
          title: '미션 승인 완료',
          message: '부모님이 미션을 승인했습니다.',
          createdAt: DateTime(2026, 6, 10, 12, 30),
          isRead: false,
        ),
      ];
      messaging.foregroundMessages.add(
        const FcmMessage(type: 'MISSION_APPROVED', deeplink: '/child-home'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.byKey(
          const ValueKey<String>('child-home-notification-unread-dot'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('child home refreshes mission list after foreground FCM', (
    WidgetTester tester,
  ) async {
    await FcmBootstrap.dispose();
    addTearDown(FcmBootstrap.dispose);

    final _FakeFcmMessagingService messaging = _FakeFcmMessagingService();
    await FcmBootstrap.initialize(
      messagingService: messaging,
      deviceRepository: const _NoopDeviceRepository(),
    );

    final _MutableMissionRepository missions =
        _MutableMissionRepository(<mission_model.Mission>[
          const mission_model.Mission(
            id: '10',
            title: '방청소',
            rewardHours: 1,
            rewardMinutes: 0,
            status: mission_model.MissionStatus.pendingCheck,
            category: '청소',
          ),
        ]);
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.path == '/api/v1/schedules/daily') {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
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

    await tester.pumpWidget(
      MaterialApp(
        home: ChildHomePage(
          dio: dio,
          notificationRepository: _MutableNotificationRepository(
            <NotificationItem>[],
          ),
          missionRepository: missions,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('방청소'), findsOneWidget);
    expect(find.text('공부'), findsNothing);

    missions.items = <mission_model.Mission>[
      ...missions.items,
      const mission_model.Mission(
        id: '11',
        title: '공부',
        rewardHours: 1,
        rewardMinutes: 0,
        status: mission_model.MissionStatus.pendingCheck,
        category: '학습',
      ),
    ];
    messaging.foregroundMessages.add(
      const FcmMessage(type: 'MISSION_CREATED', deeplink: '/child-home'),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(missions.listCalls, greaterThanOrEqualTo(2));
    expect(find.text('공부'), findsOneWidget);
  });

  testWidgets('child home mission list scrolls with long backend titles', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<mission_model.Mission> longMissions = <mission_model.Mission>[
      for (int index = 0; index < 10; index++)
        mission_model.Mission(
          id: '${2000 + index}',
          title: 'constraint-test-${index.isEven ? 'ETC' : 'EXERCISE'}-200321',
          rewardHours: index == 0 ? 1 : 0,
          rewardMinutes: 0,
          status: index == 0
              ? mission_model.MissionStatus.completed
              : mission_model.MissionStatus.pendingCheck,
          category: index.isEven ? '기타' : '운동',
        ),
    ];
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
                  'targetDate': '2026-06-10',
                  'baseMinutes': 0,
                  'extendedMinutes': 60,
                  'totalAvailableMinutes': 60,
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
                data: <String, dynamic>{'accumulatedRewardTime': 60},
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

    await tester.pumpWidget(
      MaterialApp(
        home: ChildHomePage(
          dio: dio,
          notificationRepository: _MutableNotificationRepository(
            <NotificationItem>[],
          ),
          missionRepository: _MutableMissionRepository(longMissions),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(tester.takeException(), isNull);
    expect(find.text('10'), findsOneWidget);

    final Finder lastTitle = find.text('constraint-test-EXERCISE-200321').last;
    final double beforeDragY = tester.getTopLeft(lastTitle).dy;

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(lastTitle).dy, lessThan(beforeDragY));
  });

  testWidgets('child home pull-to-refresh reloads today time', (
    WidgetTester tester,
  ) async {
    await AuthSession.saveLogin(username: 'child', memberId: '22');

    int dailyLoadCount = 0;
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (options.path == '/api/v1/schedules/daily') {
            dailyLoadCount += 1;
            final int totalMinutes = dailyLoadCount == 1 ? 60 : 90;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'targetDate': '2026-06-09',
                  'baseMinutes': totalMinutes,
                  'extendedMinutes': 0,
                  'totalAvailableMinutes': totalMinutes,
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

    await tester.pumpWidget(
      MaterialApp(
        home: ChildHomePage(
          dio: dio,
          notificationRepository: _MutableNotificationRepository(
            <NotificationItem>[],
          ),
          missionRepository: _MutableMissionRepository(
            <mission_model.Mission>[],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('01:00'), findsOneWidget);

    final RefreshIndicator refreshIndicator = tester.widget(
      find.byType(RefreshIndicator),
    );
    unawaited(refreshIndicator.onRefresh());
    await tester.pump(const Duration(milliseconds: 100));

    expect(dailyLoadCount, greaterThanOrEqualTo(2));
    expect(find.text('01:30'), findsOneWidget);
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

      expect(find.text('화면 시간 차감을 위해 접근성 권한을 켜주세요.'), findsNothing);
      expect(
        channelCalls.any(
          (MethodCall call) => call.method == 'requestPermission',
        ),
        isTrue,
      );
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
    expect(find.text('미션을 인증할 수 있는 사진을 올려주세요!'), findsOneWidget);
    expect(find.text('사진을 업로드해주세요'), findsOneWidget);

    await tester.tap(find.text('사진을 업로드해주세요'));
    await tester.pumpAndSettle();

    expect(find.text('앨범에서 선택'), findsOneWidget);
    expect(find.text('사진 촬영'), findsOneWidget);
  });

  testWidgets('mission info category options render as one supported row', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MissionInfoPage(missionId: '5')),
    );
    await tester.pumpAndSettle();

    final Offset study = tester.getCenter(find.text('학습'));
    final Offset exercise = tester.getCenter(find.text('운동'));
    final Offset cleaning = tester.getCenter(find.text('청소'));
    final Offset etc = tester.getCenter(find.text('기타'));

    expect(find.text('루틴'), findsNothing);
    expect(find.text('심부름'), findsNothing);

    expect(exercise.dx, greaterThan(study.dx));
    expect(cleaning.dx, greaterThan(exercise.dx));
    expect(etc.dx, greaterThan(cleaning.dx));
    expect(exercise.dy, closeTo(study.dy, 1));
    expect(cleaning.dy, closeTo(study.dy, 1));
    expect(etc.dy, closeTo(study.dy, 1));

    final Offset daily = tester.getCenter(find.text('매일'));
    final Offset weekly = tester.getCenter(find.text('일주일'));
    final Offset monthly = tester.getCenter(find.text('한 달'));
    expect(weekly.dx, greaterThan(daily.dx));
    expect(monthly.dx, greaterThan(weekly.dx));
    expect(weekly.dy, closeTo(daily.dy, 1));
    expect(monthly.dy, closeTo(daily.dy, 1));

    final Offset ai = tester.getCenter(find.text('AI 자동확인'));
    final Offset child = tester.getCenter(find.text('자녀 확인'));
    final Offset parent = tester.getCenter(find.text('부모 확인'));
    expect(child.dx, greaterThan(ai.dx));
    expect(parent.dx, greaterThan(child.dx));
    expect(child.dy, closeTo(ai.dy, 1));
    expect(parent.dy, closeTo(ai.dy, 1));
  });

  testWidgets('add photo tile keeps mock upload affordance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 157,
              height: 156,
              child: BridgeAddPhotoTile(onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(BridgeAddPhotoTile)),
      const Size(157, 156),
    );
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    expect(find.text('추가 업로드'), findsOneWidget);
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

class _MutableNotificationRepository implements NotificationRepository {
  _MutableNotificationRepository(this.items);

  List<NotificationItem> items;

  @override
  Future<Result<List<NotificationItem>>> listNotifications() async {
    return Result<List<NotificationItem>>.success(
      List<NotificationItem>.from(items),
    );
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    items.removeWhere((NotificationItem item) => item.id == id);
    return Result<void>.success(null);
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    items = <NotificationItem>[
      for (final NotificationItem item in items)
        item.id == id ? item.copyWith(isRead: true) : item,
    ];
    return Result<void>.success(null);
  }
}

class _MutableMissionRepository
    implements mission_repository.MissionRepository {
  _MutableMissionRepository(this.items);

  List<mission_model.Mission> items;
  int listCalls = 0;

  @override
  Future<Result<mission_model.Mission>> fetchMission(String id) async {
    return Result<mission_model.Mission>.success(
      items.firstWhere((mission_model.Mission item) => item.id == id),
    );
  }

  @override
  Future<Result<List<mission_model.Mission>>> listMissions() async {
    listCalls += 1;
    return Result<List<mission_model.Mission>>.success(
      List<mission_model.Mission>.from(items),
    );
  }

  @override
  Future<Result<mission_model.MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    return Result<mission_model.MissionSubmissionResult>.failure(
      '미션 제출에 실패했습니다.',
    );
  }
}

class _FakeFcmMessagingService implements FcmMessagingService {
  final StreamController<FcmMessage> foregroundMessages =
      StreamController<FcmMessage>.broadcast();

  @override
  Future<FcmMessage?> getInitialMessage() async => null;

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Stream<FcmMessage> get onForegroundMessage => foregroundMessages.stream;

  @override
  Stream<FcmMessage> get onMessageOpenedApp => const Stream<FcmMessage>.empty();

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<bool> requestPermission() async => true;
}

class _NoopDeviceRepository implements DeviceRepository {
  const _NoopDeviceRepository();

  @override
  Future<Result<String>> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    return Result<String>.success('noop-device');
  }

  @override
  Future<Result<void>> unregisterDevice(String deviceId) async {
    return Result<void>.success(null);
  }
}
