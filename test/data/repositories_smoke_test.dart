import 'package:bridge_k/features/auth/data/models/auth_token.dart';
import 'package:bridge_k/features/auth/data/repositories/api_auth_repository.dart';
import 'package:bridge_k/features/auth/data/repositories/auth_repository.dart';
import 'package:bridge_k/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:bridge_k/core/auth/auth_session.dart';
import 'package:bridge_k/features/devices/data/repositories/api_device_repository.dart';
import 'package:bridge_k/features/devices/data/repositories/device_repository.dart';
import 'package:bridge_k/features/mission/data/listeners/mission_approval_listener.dart';
import 'package:bridge_k/features/mission/data/listeners/mock_mission_approval_listener.dart';
import 'package:bridge_k/features/mission/data/models/mission.dart';
import 'package:bridge_k/features/mission/data/repositories/api_mission_repository.dart';
import 'package:bridge_k/features/mission/data/repositories/mission_repository.dart';
import 'package:bridge_k/features/mission/data/repositories/mock_mission_repository.dart';
import 'package:bridge_k/features/my_page/data/models/user_profile.dart';
import 'package:bridge_k/features/my_page/data/repositories/api_my_page_repository.dart';
import 'package:bridge_k/features/my_page/data/repositories/mock_my_page_repository.dart';
import 'package:bridge_k/features/my_page/data/repositories/my_page_repository.dart';
import 'package:bridge_k/features/notifications/data/models/notification_item.dart';
import 'package:bridge_k/features/notifications/data/repositories/api_notification_repository.dart';
import 'package:bridge_k/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:bridge_k/features/notifications/data/repositories/notification_repository.dart';
import 'package:bridge_k/features/report/data/models/usage_report.dart';
import 'package:bridge_k/features/report/data/repositories/mock_usage_report_repository.dart';
import 'package:bridge_k/features/report/data/repositories/api_usage_report_repository.dart';
import 'package:bridge_k/features/report/data/repositories/usage_report_repository.dart';
import 'package:bridge_k/features/time_confirm/data/models/time_confirm_data.dart';
import 'package:bridge_k/features/time_confirm/data/repositories/api_time_confirm_repository.dart';
import 'package:bridge_k/features/time_confirm/data/repositories/mock_time_confirm_repository.dart';
import 'package:bridge_k/features/time_confirm/data/repositories/time_confirm_repository.dart';
import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';
import 'package:bridge_k/features/time_setup/data/repositories/api_time_setup_repository.dart';
import 'package:bridge_k/features/time_setup/data/repositories/mock_time_setup_repository.dart';
import 'package:bridge_k/features/time_setup/data/repositories/time_setup_repository.dart';
import 'package:bridge_k/core/models/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mission repository', () {
    test('createMissionRepository returns Mock in dev mock mode', () {
      expect(createMissionRepository(), isA<MockMissionRepository>());
    });

    test('listMissions returns Success with non-empty list', () async {
      final MissionRepository repo = MockMissionRepository();
      final Result<List<Mission>> result = await repo.listMissions();
      expect(result, isA<Success<List<Mission>>>());
      switch (result) {
        case Success<List<Mission>>(:final List<Mission> data):
          expect(data, isNotEmpty);
        case Failure<List<Mission>>():
          fail('listMissions should not fail in mock mode');
      }
    });

    test('fetchMission returns Success for known id', () async {
      final MissionRepository repo = MockMissionRepository();
      final Result<Mission> result = await repo.fetchMission('1');
      expect(result, isA<Success<Mission>>());
    });

    test('submitMission returns Success in mock mode', () async {
      final MissionRepository repo = MockMissionRepository();
      final Result<MissionSubmissionResult> result = await repo.submitMission(
        id: '1',
        photoPaths: const <String>['/tmp/photo1.jpg'],
      );
      expect(result, isA<Success<MissionSubmissionResult>>());
    });

    test(
      'api listMissions parses AWS ApiResponse-wrapped mission list',
      () async {
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  if (options.path == '/api/v1/missions') {
                    handler.resolve(
                      Response<dynamic>(
                        requestOptions: options,
                        statusCode: 200,
                        data: <String, dynamic>{
                          'isSuccess': true,
                          'data': <Map<String, dynamic>>[
                            <String, dynamic>{
                              'missionId': 42,
                              'title': '방 청소하기',
                              'category': 'CLEANING',
                              'reward': 90,
                            },
                          ],
                        },
                      ),
                    );
                    return;
                  }
                  if (options.path == '/api/v1/missions/42') {
                    handler.resolve(
                      Response<dynamic>(
                        requestOptions: options,
                        statusCode: 200,
                        data: <String, dynamic>{
                          'isSuccess': true,
                          'data': <String, dynamic>{
                            'missionId': 42,
                            'title': '방 청소하기',
                            'category': 'CLEANING',
                            'resetCycle': 'WEEKLY',
                            'verificationType': 'PARENT',
                            'reward': 90,
                            'description': '방 정리 인증',
                          },
                        },
                      ),
                    );
                    return;
                  }
                  if (options.path == '/api/v1/missions/42/performance') {
                    handler.resolve(
                      Response<dynamic>(
                        requestOptions: options,
                        statusCode: 200,
                        data: <String, dynamic>{
                          'isSuccess': true,
                          'data': <String, dynamic>{
                            'performanceId': 201,
                            'status': 'PENDING',
                            'proofImageUrl': 'https://test.local/proof.jpg',
                          },
                        },
                      ),
                    );
                    return;
                  }
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      response: Response<dynamic>(
                        requestOptions: options,
                        statusCode: 404,
                      ),
                    ),
                  );
                },
          ),
        );
        final MissionRepository repo = ApiMissionRepository(dio);

        final Result<List<Mission>> result = await repo.listMissions();

        switch (result) {
          case Success<List<Mission>>(:final List<Mission> data):
            expect(data, hasLength(1));
            expect(data.single.id, '42');
            expect(data.single.category, '청소');
            expect(data.single.resetCycle, '일주일');
            expect(
              data.single.confirmationMethod,
              ConfirmationMethod.parentApproval,
            );
            expect(data.single.status, MissionStatus.reviewing);
            expect(data.single.performanceId, '201');
            expect(data.single.photoUrls, <String>[
              'https://test.local/proof.jpg',
            ]);
          case Failure<List<Mission>>(:final String message):
            fail(
              'api listMissions should parse wrapped response, got $message',
            );
        }
      },
    );

    test('createMissionApprovalListener returns Mock in dev mock mode', () {
      final MissionApprovalListener listener = createMissionApprovalListener();
      expect(listener, isA<MockMissionApprovalListener>());

      final MissionApprovalSubscription subscription = listener.subscribe(
        missionId: '1',
        confirmationMethod: ConfirmationMethod.parentApproval,
        onApproval: (_) => fail('parent-approval mock should stay silent'),
      );
      subscription.cancel();
    });
  });

  group('time setup repository', () {
    test('createTimeSetupRepository returns Mock in dev mock mode', () {
      expect(createTimeSetupRepository(), isA<MockTimeSetupRepository>());
    });

    test('fetchPreviousWeekSchedule returns Success', () async {
      final TimeSetupRepository repo = MockTimeSetupRepository();
      final Result<TimeSchedule> result = await repo
          .fetchPreviousWeekSchedule();
      expect(result, isA<Success<TimeSchedule>>());
    });

    test('fetchCurrentSchedule returns Success with null payload', () async {
      final TimeSetupRepository repo = MockTimeSetupRepository();
      final Result<TimeSchedule?> result = await repo.fetchCurrentSchedule();
      switch (result) {
        case Success<TimeSchedule?>(:final TimeSchedule? data):
          expect(data, isNull);
        case Failure<TimeSchedule?>():
          fail('fetchCurrentSchedule should succeed in mock mode');
      }
    });

    test(
      'api fetchCurrentSchedule excludes reward pool from legacy policy total',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await AuthSession.saveLogin(username: 'child', memberId: '22');

        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  if (options.path == '/api/v1/children/22/policies') {
                    handler.resolve(
                      Response<dynamic>(
                        requestOptions: options,
                        statusCode: 200,
                        data: <String, dynamic>{
                          'totalAvailableTime': 720,
                          'accumulatedRewardTime': 120,
                        },
                      ),
                    );
                    return;
                  }
                  if (options.path == '/api/v1/schedules/routines') {
                    handler.resolve(
                      Response<dynamic>(
                        requestOptions: options,
                        statusCode: 200,
                        data: <String, dynamic>{
                          'isSuccess': true,
                          'data': const <Map<String, dynamic>>[
                            <String, dynamic>{
                              'id': 1,
                              'dayOfWeek': 'MONDAY',
                              'startTime': '09:00:00',
                              'endTime': '11:00:00',
                            },
                          ],
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

        final TimeSetupRepository repo = ApiTimeSetupRepository(dio: dio);

        final Result<TimeSchedule?> result = await repo.fetchCurrentSchedule();

        switch (result) {
          case Success<TimeSchedule?>(:final TimeSchedule? data):
            expect(data, isNotNull);
            expect(data!.monthlyBudgetMinutes, 600);
            expect(data.weeklyTotalCapMinutes, 600);
            expect(
              data.allowedHours,
              containsAll(<HourCell>[
                const HourCell(weekday: 0, hour: 9),
                const HourCell(weekday: 0, hour: 10),
              ]),
            );
          case Failure<TimeSchedule?>():
            fail('fetchCurrentSchedule should parse policy fallback');
        }
      },
    );

    test('saveSchedule returns Success', () async {
      final TimeSetupRepository repo = MockTimeSetupRepository();
      final Result<void> result = await repo.saveSchedule(
        const TimeSchedule(
          allowedHours: <HourCell>{},
          weeklyTotals: <WeeklyTotal>[],
          dayAllocations: <DayAllocation>[],
        ),
      );
      expect(result, isA<Success<void>>());
    });

    test(
      'api saveSchedule posts budgets, templates, then completion',
      () async {
        final List<RequestOptions> requests = <RequestOptions>[];
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  requests.add(options);
                  final Object? data = options.path.endsWith('/routines')
                      ? <String, dynamic>{
                          'isSuccess': true,
                          'data': const <Map<String, dynamic>>[],
                        }
                      : null;
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: data,
                    ),
                  );
                },
          ),
        );
        final TimeSetupRepository repo = ApiTimeSetupRepository(dio: dio);

        final Result<void> result = await repo.saveSchedule(
          const TimeSchedule(
            allowedHours: <HourCell>{},
            weeklyTotals: <WeeklyTotal>[
              WeeklyTotal(weekIndex: 0, hours: 1, minutes: 0),
              WeeklyTotal(weekIndex: 1, hours: 2, minutes: 0),
              WeeklyTotal(weekIndex: 2, hours: 3, minutes: 0),
              WeeklyTotal(weekIndex: 3, hours: 4, minutes: 0),
            ],
            dayAllocations: <DayAllocation>[
              DayAllocation(
                daysLabel: '월',
                weekdayIndices: <int>[0],
                hours: 1,
                minutes: 0,
              ),
            ],
          ),
        );

        expect(result, isA<Success<void>>());
        expect(
          requests.map((RequestOptions options) {
            return '${options.method} ${options.path}';
          }).toList(),
          <String>[
            'POST /api/v1/schedules/weekly-budgets',
            'PUT /api/v1/schedules/templates',
            'PUT /api/v1/schedules/templates',
            'PUT /api/v1/schedules/templates',
            'PUT /api/v1/schedules/templates',
            'GET /api/v1/schedules/routines',
            'POST /api/v1/schedules/complete',
          ],
        );

        final RequestOptions budgetRequest = requests.first;
        final String yearMonth = budgetRequest.queryParameters['yearMonth']
            .toString();
        expect(yearMonth, matches(RegExp(r'^\d{4}-\d{2}$')));
        expect(budgetRequest.data, <Map<String, dynamic>>[
          <String, dynamic>{'weekNumber': 1, 'allocatedMinutes': 60},
          <String, dynamic>{'weekNumber': 2, 'allocatedMinutes': 120},
          <String, dynamic>{'weekNumber': 3, 'allocatedMinutes': 180},
          <String, dynamic>{'weekNumber': 4, 'allocatedMinutes': 240},
        ]);

        final List<RequestOptions> templateRequests = requests
            .where(
              (RequestOptions options) =>
                  options.method == 'PUT' &&
                  options.path == '/api/v1/schedules/templates',
            )
            .toList();
        expect(
          templateRequests
              .map((RequestOptions options) => options.data)
              .toList(),
          <Map<String, dynamic>>[
            <String, dynamic>{
              'yearMonth': yearMonth,
              'weekNumber': 1,
              'dayOfWeek': 'MONDAY',
              'baseMinutes': 60,
            },
            <String, dynamic>{
              'yearMonth': yearMonth,
              'weekNumber': 2,
              'dayOfWeek': 'MONDAY',
              'baseMinutes': 120,
            },
            <String, dynamic>{
              'yearMonth': yearMonth,
              'weekNumber': 3,
              'dayOfWeek': 'MONDAY',
              'baseMinutes': 180,
            },
            <String, dynamic>{
              'yearMonth': yearMonth,
              'weekNumber': 4,
              'dayOfWeek': 'MONDAY',
              'baseMinutes': 240,
            },
          ],
        );
        expect(requests.last.queryParameters['yearMonth'], yearMonth);
      },
    );
  });

  group('time confirm repository', () {
    test('createTimeConfirmRepository returns Mock in dev mock mode', () {
      expect(createTimeConfirmRepository(), isA<MockTimeConfirmRepository>());
    });

    test('fetchCurrentSchedule returns Success', () async {
      final TimeConfirmRepository repo = MockTimeConfirmRepository();
      final Result<TimeConfirmData> result = await repo.fetchCurrentSchedule();
      expect(result, isA<Success<TimeConfirmData>>());
    });

    test(
      'api fetchCurrentSchedule maps wrapped daily schedule to target week',
      () async {
        final TimeConfirmRepository repo = ApiTimeConfirmRepository(
          dio: _dioReturning(<String, dynamic>{
            'isSuccess': true,
            'data': <String, dynamic>{
              'targetDate': '2026-06-08',
              'baseMinutes': 30,
              'extendedMinutes': 0,
              'totalAvailableMinutes': 30,
            },
          }),
        );

        final Result<TimeConfirmData> result = await repo
            .fetchCurrentSchedule();

        switch (result) {
          case Success<TimeConfirmData>(:final TimeConfirmData data):
            final TimeSchedule schedule = data.schedule!;
            expect(schedule.weeklyTotalMinutesAt(1), 30);
            expect(schedule.dayAllocations.single.daysLabel, '월');
            expect(schedule.dayAllocations.single.totalMinutes, 30);
          case Failure<TimeConfirmData>(:final String message):
            fail('api fetchCurrentSchedule should succeed, got $message');
        }
      },
    );

    test('requestModification returns Success', () async {
      final TimeConfirmRepository repo = MockTimeConfirmRepository();
      expect(await repo.requestModification(), isA<Success<void>>());
    });

    test('acknowledgeSchedule returns Success', () async {
      final TimeConfirmRepository repo = MockTimeConfirmRepository();
      expect(await repo.acknowledgeSchedule(), isA<Success<void>>());
    });
  });

  group('notification repository', () {
    test('createNotificationRepository returns Mock in dev mock mode', () {
      expect(createNotificationRepository(), isA<MockNotificationRepository>());
    });

    test('listNotifications returns Success with non-empty list', () async {
      final NotificationRepository repo = MockNotificationRepository();
      final Result<List<NotificationItem>> result = await repo
          .listNotifications();
      switch (result) {
        case Success<List<NotificationItem>>(
          :final List<NotificationItem> data,
        ):
          expect(data, isNotEmpty);
        case Failure<List<NotificationItem>>():
          fail('listNotifications should not fail in mock mode');
      }
    });

    test('api listNotifications parses AWS ApiResponse-wrapped inbox', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                if (options.path == '/api/v1/notifications') {
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'isSuccess': true,
                        'data': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'notificationId': 17,
                            'notificationType': 'MISSION_APPROVED',
                            'title': '미션 승인 완료',
                            'content': '부모님이 미션을 승인했습니다.',
                            'createdAt': '2026-06-09T12:30:00',
                            'isRead': false,
                            'targetRoute': '/child-home/mission/21',
                          },
                        ],
                      },
                    ),
                  );
                  return;
                }
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 404,
                    ),
                  ),
                );
              },
        ),
      );
      final NotificationRepository repo = ApiNotificationRepository(dio: dio);

      final Result<List<NotificationItem>> result = await repo
          .listNotifications();

      switch (result) {
        case Success<List<NotificationItem>>(
          :final List<NotificationItem> data,
        ):
          expect(data, hasLength(1));
          expect(data.single.id, '17');
          expect(data.single.type, NotificationType.missionCompleted);
          expect(data.single.deeplink, '/child-home/mission/21');
          expect(data.single.isRead, isFalse);
        case Failure<List<NotificationItem>>(:final String message):
          fail(
            'api listNotifications should parse wrapped response, got $message',
          );
      }
    });

    test('deleteNotification returns Success', () async {
      final NotificationRepository repo = MockNotificationRepository();
      expect(
        await repo.deleteNotification('weekly-report'),
        isA<Success<void>>(),
      );
      final Result<List<NotificationItem>> result = await repo
          .listNotifications();
      switch (result) {
        case Success<List<NotificationItem>>(:final data):
          expect(
            data.any((NotificationItem item) => item.id == 'weekly-report'),
            isFalse,
          );
        case Failure<List<NotificationItem>>(:final message):
          fail('listNotifications should succeed after delete, got $message');
      }
    });

    test('markAsRead returns Success', () async {
      final NotificationRepository repo = MockNotificationRepository();
      expect(await repo.markAsRead('weekly-report'), isA<Success<void>>());
      final Result<List<NotificationItem>> result = await repo
          .listNotifications();
      switch (result) {
        case Success<List<NotificationItem>>(:final data):
          final NotificationItem item = data.singleWhere(
            (NotificationItem item) => item.id == 'weekly-report',
          );
          expect(item.isRead, isTrue);
        case Failure<List<NotificationItem>>(:final message):
          fail('listNotifications should succeed after read, got $message');
      }
    });
  });

  group('device repository', () {
    test('api registerDevice unwraps FCM token response data', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                if (options.path == '/api/v1/fcm/token') {
                  handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'isSuccess': true,
                        'data': 'FCM 토큰 저장 완료',
                      },
                    ),
                  );
                  return;
                }
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 404,
                    ),
                  ),
                );
              },
        ),
      );
      final DeviceRepository repo = ApiDeviceRepository(dio: dio);

      final Result<String> result = await repo.registerDevice(
        fcmToken: 'token-1',
        platform: 'android',
      );

      switch (result) {
        case Success<String>(:final String data):
          expect(data, 'FCM 토큰 저장 완료');
        case Failure<String>(:final String message):
          fail('registerDevice should parse wrapped response, got $message');
      }
    });
  });

  group('usage report repository', () {
    test('createUsageReportRepository returns Mock in dev mock mode', () {
      expect(createUsageReportRepository(), isA<MockUsageReportRepository>());
    });

    test('fetchCurrentWeekReport returns Success', () async {
      final UsageReportRepository repo = MockUsageReportRepository();
      final Result<UsageReport> result = await repo.fetchCurrentWeekReport();
      expect(result, isA<Success<UsageReport>>());
    });

    test('api fetchCurrentWeekReport unwraps daily schedule responses', () async {
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
                          'date': options.queryParameters['date'],
                          'baseMinutes': 60,
                          'extendedMinutes': 0,
                          'totalAvailableMinutes': 60,
                        },
                      },
                    ),
                  );
                  return;
                }
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 404,
                    ),
                  ),
                );
              },
        ),
      );
      final UsageReportRepository repo = ApiUsageReportRepository(dio);

      final Result<UsageReport> result = await repo.fetchCurrentWeekReport();

      switch (result) {
        case Success<UsageReport>(:final UsageReport data):
          expect(data.dailyRows, hasLength(7));
          expect(
            data.dailyRows.every((row) => row.plannedMinutes == 60),
            isTrue,
          );
          expect(data.plan.totalHours, 7);
        case Failure<UsageReport>(:final String message):
          fail(
            'api fetchCurrentWeekReport should parse wrapped daily schedules, got $message',
          );
      }
    });
  });

  group('my page repository', () {
    setUp(() {
      // AuthSession reads username from SharedPreferences inside fetchProfile.
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('createMyPageRepository returns Mock in dev mock mode', () {
      expect(createMyPageRepository(), isA<MockMyPageRepository>());
    });

    test('fetchProfile returns Success', () async {
      final MyPageRepository repo = MockMyPageRepository();
      final Result<UserProfile> result = await repo.fetchProfile();
      expect(result, isA<Success<UserProfile>>());
    });

    test('api fetchProfile does not invent a child code', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AuthSession.usernameKey: 'child01',
      });
      final MyPageRepository repo = ApiMyPageRepository();

      final Result<UserProfile> result = await repo.fetchProfile();

      switch (result) {
        case Success<UserProfile>(:final UserProfile data):
          expect(data.username, 'child01');
          expect(data.childCode, '-');
        case Failure<UserProfile>(:final String message):
          fail('api fetchProfile should derive local profile, got $message');
      }
    });

    test(
      'changePassword with correct current password returns Success',
      () async {
        final MyPageRepository repo = MockMyPageRepository();
        final Result<void> result = await repo.changePassword(
          currentPassword: 'Gdg123456789!',
          newPassword: 'NewPass123!',
        );
        expect(result, isA<Success<void>>());
      },
    );

    test(
      'changePassword with wrong current password returns Failure',
      () async {
        final MyPageRepository repo = MockMyPageRepository();
        final Result<void> result = await repo.changePassword(
          currentPassword: 'wrong-password',
          newPassword: 'NewPass123!',
        );
        expect(result, isA<Failure<void>>());
      },
    );

    test('deleteAccount returns Success', () async {
      final MyPageRepository repo = MockMyPageRepository();
      expect(await repo.deleteAccount(), isA<Success<void>>());
    });
  });

  group('auth repository', () {
    test('createAuthRepository returns Mock in dev mock mode', () {
      expect(createAuthRepository(), isA<MockAuthRepository>());
    });

    test('login with correct credentials returns Success', () async {
      final AuthRepository repo = MockAuthRepository();
      final Result<AuthToken> result = await repo.login(
        username: 'gdg12',
        password: 'Gdg123456789!',
      );
      switch (result) {
        case Success<AuthToken>(:final AuthToken data):
          expect(data.username, 'gdg12');
          expect(data.accessToken, isNotEmpty);
        case Failure<AuthToken>():
          fail('login with correct credentials should succeed');
      }
    });

    test('login with unknown username returns Failure(unknownUser)', () async {
      final AuthRepository repo = MockAuthRepository();
      final Result<AuthToken> result = await repo.login(
        username: 'no-such-user',
        password: 'Gdg123456789!',
      );
      switch (result) {
        case Success<AuthToken>():
          fail('login with unknown username should fail');
        case Failure<AuthToken>(:final String message):
          expect(message, AuthFailureMessages.unknownUser);
      }
    });

    test('login with wrong password returns Failure(wrongPassword)', () async {
      final AuthRepository repo = MockAuthRepository();
      final Result<AuthToken> result = await repo.login(
        username: 'gdg12',
        password: 'wrong-password',
      );
      switch (result) {
        case Success<AuthToken>():
          fail('login with wrong password should fail');
        case Failure<AuthToken>(:final String message):
          expect(message, AuthFailureMessages.wrongPassword);
      }
    });

    test('api login parses AWS ApiResponse-wrapped auth response', () async {
      final AuthRepository repo = ApiAuthRepository(
        dio: _dioReturning(<String, dynamic>{
          'isSuccess': true,
          'code': 'COMMON200',
          'message': 'OK',
          'data': <String, dynamic>{
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'memberId': 42,
            'name': 'Child User',
          },
        }),
      );
      final Result<AuthToken> result = await repo.login(
        username: 'child@test.com',
        password: 'Test1234567!',
      );

      switch (result) {
        case Success<AuthToken>(:final AuthToken data):
          expect(data.accessToken, 'access-token');
          expect(data.refreshToken, 'refresh-token');
          expect(data.username, 'child@test.com');
        case Failure<AuthToken>(:final String message):
          fail('wrapped auth response should parse, got $message');
      }
    });

    test('api signup tolerates tokenless success response', () async {
      final AuthRepository repo = ApiAuthRepository(
        dio: _dioReturning(<String, dynamic>{
          'isSuccess': true,
          'code': 'COMMON200',
          'message': 'OK',
          'data': null,
        }),
      );
      final Result<AuthToken> result = await repo.signup(
        name: 'Brand New',
        username: 'brand-new-user@test.com',
        password: 'Whatever123!',
      );

      switch (result) {
        case Success<AuthToken>(:final AuthToken data):
          expect(data.accessToken, isEmpty);
          expect(data.refreshToken, isNull);
          expect(data.username, 'brand-new-user@test.com');
        case Failure<AuthToken>(:final String message):
          fail('tokenless signup response should not crash, got $message');
      }
    });

    test('signup with new username returns Success', () async {
      final AuthRepository repo = MockAuthRepository();
      final Result<AuthToken> result = await repo.signup(
        name: 'Brand New',
        username: 'brand-new-user',
        password: 'Whatever123!',
      );
      switch (result) {
        case Success<AuthToken>(:final AuthToken data):
          expect(data.username, 'brand-new-user');
        case Failure<AuthToken>():
          fail('signup with a fresh username should succeed');
      }
    });

    test('signup with duplicated username returns Failure', () async {
      final AuthRepository repo = MockAuthRepository();
      final Result<AuthToken> result = await repo.signup(
        name: 'Duplicate',
        username: 'gdg12',
        password: 'Whatever123!',
      );
      switch (result) {
        case Success<AuthToken>():
          fail('signup with duplicated username should fail');
        case Failure<AuthToken>(:final String message):
          expect(message, AuthFailureMessages.duplicatedUsername);
      }
    });
  });
}

Dio _dioReturning(Map<String, dynamic> data) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );
  return dio;
}
