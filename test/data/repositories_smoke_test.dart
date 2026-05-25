import 'package:bridge_k/features/auth/data/models/auth_token.dart';
import 'package:bridge_k/features/auth/data/repositories/auth_repository.dart';
import 'package:bridge_k/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:bridge_k/features/mission/data/models/mission.dart';
import 'package:bridge_k/features/mission/data/repositories/mission_repository.dart';
import 'package:bridge_k/features/mission/data/repositories/mock_mission_repository.dart';
import 'package:bridge_k/features/my_page/data/models/user_profile.dart';
import 'package:bridge_k/features/my_page/data/repositories/mock_my_page_repository.dart';
import 'package:bridge_k/features/my_page/data/repositories/my_page_repository.dart';
import 'package:bridge_k/features/notifications/data/models/notification_item.dart';
import 'package:bridge_k/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:bridge_k/features/notifications/data/repositories/notification_repository.dart';
import 'package:bridge_k/features/report/data/models/usage_report.dart';
import 'package:bridge_k/features/report/data/repositories/mock_usage_report_repository.dart';
import 'package:bridge_k/features/report/data/repositories/usage_report_repository.dart';
import 'package:bridge_k/features/time_confirm/data/models/time_confirm_data.dart';
import 'package:bridge_k/features/time_confirm/data/repositories/mock_time_confirm_repository.dart';
import 'package:bridge_k/features/time_confirm/data/repositories/time_confirm_repository.dart';
import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';
import 'package:bridge_k/features/time_setup/data/repositories/mock_time_setup_repository.dart';
import 'package:bridge_k/features/time_setup/data/repositories/time_setup_repository.dart';
import 'package:bridge_k/core/models/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mission repository', () {
    test('createMissionRepository returns Mock in dev', () {
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

    test('submitMission returns Success and attaches photo paths', () async {
      final MissionRepository repo = MockMissionRepository();
      final Result<Mission> result = await repo.submitMission(
        id: '1',
        photoPaths: const <String>['/tmp/photo1.jpg'],
      );
      switch (result) {
        case Success<Mission>(:final Mission data):
          expect(data.photoUrls, <String>['/tmp/photo1.jpg']);
        case Failure<Mission>():
          fail('submitMission should succeed in mock mode');
      }
    });
  });

  group('time setup repository', () {
    test('createTimeSetupRepository returns Mock in dev', () {
      expect(createTimeSetupRepository(), isA<MockTimeSetupRepository>());
    });

    test('fetchPreviousWeekSchedule returns Success', () async {
      final TimeSetupRepository repo = MockTimeSetupRepository();
      final Result<TimeSchedule> result = await repo.fetchPreviousWeekSchedule();
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
  });

  group('time confirm repository', () {
    test('createTimeConfirmRepository returns Mock in dev', () {
      expect(createTimeConfirmRepository(), isA<MockTimeConfirmRepository>());
    });

    test('fetchCurrentSchedule returns Success', () async {
      final TimeConfirmRepository repo = MockTimeConfirmRepository();
      final Result<TimeConfirmData> result = await repo.fetchCurrentSchedule();
      expect(result, isA<Success<TimeConfirmData>>());
    });

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
    test('createNotificationRepository returns Mock in dev', () {
      expect(createNotificationRepository(), isA<MockNotificationRepository>());
    });

    test('listNotifications returns Success with non-empty list', () async {
      final NotificationRepository repo = MockNotificationRepository();
      final Result<List<NotificationItem>> result =
          await repo.listNotifications();
      switch (result) {
        case Success<List<NotificationItem>>(:final List<NotificationItem> data):
          expect(data, isNotEmpty);
        case Failure<List<NotificationItem>>():
          fail('listNotifications should not fail in mock mode');
      }
    });

    test('deleteNotification returns Success', () async {
      final NotificationRepository repo = MockNotificationRepository();
      expect(await repo.deleteNotification('weekly-report'),
          isA<Success<void>>());
    });

    test('markAsRead returns Success', () async {
      final NotificationRepository repo = MockNotificationRepository();
      expect(await repo.markAsRead('weekly-report'), isA<Success<void>>());
    });
  });

  group('usage report repository', () {
    test('createUsageReportRepository returns Mock in dev', () {
      expect(createUsageReportRepository(), isA<MockUsageReportRepository>());
    });

    test('fetchCurrentWeekReport returns Success', () async {
      final UsageReportRepository repo = MockUsageReportRepository();
      final Result<UsageReport> result = await repo.fetchCurrentWeekReport();
      expect(result, isA<Success<UsageReport>>());
    });
  });

  group('my page repository', () {
    setUp(() {
      // AuthSession reads username from SharedPreferences inside fetchProfile.
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('createMyPageRepository returns Mock in dev', () {
      expect(createMyPageRepository(), isA<MockMyPageRepository>());
    });

    test('fetchProfile returns Success', () async {
      final MyPageRepository repo = MockMyPageRepository();
      final Result<UserProfile> result = await repo.fetchProfile();
      expect(result, isA<Success<UserProfile>>());
    });

    test('changePassword with correct current password returns Success',
        () async {
      final MyPageRepository repo = MockMyPageRepository();
      final Result<void> result = await repo.changePassword(
        currentPassword: 'Gdg123456789!',
        newPassword: 'NewPass123!',
      );
      expect(result, isA<Success<void>>());
    });

    test('changePassword with wrong current password returns Failure',
        () async {
      final MyPageRepository repo = MockMyPageRepository();
      final Result<void> result = await repo.changePassword(
        currentPassword: 'wrong-password',
        newPassword: 'NewPass123!',
      );
      expect(result, isA<Failure<void>>());
    });

    test('deleteAccount returns Success', () async {
      final MyPageRepository repo = MockMyPageRepository();
      expect(await repo.deleteAccount(), isA<Success<void>>());
    });
  });

  group('auth repository', () {
    test('createAuthRepository returns Mock in dev', () {
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

    test('signup with new username returns Success', () async {
      final AuthRepository repo = MockAuthRepository();
      final Result<AuthToken> result = await repo.signup(
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
