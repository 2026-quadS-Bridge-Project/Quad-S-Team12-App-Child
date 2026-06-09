import 'package:bridge_k/core/services/fcm_messaging_service.dart';
import 'package:bridge_k/features/auth/data/models/auth_token.dart';
import 'package:bridge_k/features/mission/data/mock/mission_mock.dart';
import 'package:bridge_k/features/mission/data/models/mission.dart';
import 'package:bridge_k/features/my_page/data/models/user_profile.dart';
import 'package:bridge_k/features/notifications/data/mock/notifications_mock.dart';
import 'package:bridge_k/features/notifications/data/models/notification_item.dart';
import 'package:bridge_k/features/report/data/mock/usage_report_mock.dart';
import 'package:bridge_k/features/report/data/models/usage_report.dart';
import 'package:bridge_k/features/time_confirm/data/mock/time_confirm_mock.dart';
import 'package:bridge_k/features/time_confirm/data/models/time_confirm_data.dart';
import 'package:bridge_k/features/time_setup/data/mock/time_schedule_mock.dart';
import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mission JSON round-trip', () {
    test('mock fixture round-trips through toJson/fromJson', () {
      final Mission original = MissionMock.all.first;
      final Mission decoded = Mission.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.title, original.title);
      expect(decoded.status, original.status); // discriminating enum
      expect(decoded.confirmationMethod, original.confirmationMethod);
      expect(decoded.category, original.category);
      expect(decoded.rewardHours, original.rewardHours);
      expect(decoded.rewardMinutes, original.rewardMinutes);
    });

    test('every mock mission preserves status + confirmation method', () {
      for (final Mission m in MissionMock.all) {
        final Mission decoded = Mission.fromJson(m.toJson());
        expect(decoded.status, m.status, reason: 'status drift for ${m.id}');
        expect(
          decoded.confirmationMethod,
          m.confirmationMethod,
          reason: 'confirmationMethod drift for ${m.id}',
        );
      }
    });

    test('parses backend MissionSummaryResponse wire shape', () {
      // GET /api/v1/missions → [{missionId, title, category(enum), reward(min)}]
      final Mission decoded = Mission.fromJson(<String, dynamic>{
        'missionId': 42,
        'title': '방 청소하기',
        'category': 'CLEANING',
        'reward': 90,
      });
      expect(decoded.id, '42'); // missionId → id (was silently '' before)
      expect(decoded.category, '청소'); // CLEANING → Korean label
      expect(decoded.rewardHours, 1); // reward 90 → 1h
      expect(decoded.rewardMinutes, 30); // 30m
    });

    test('parses backend MissionResponse (detail) enums', () {
      // GET /api/v1/missions/{id} → {missionId, ..., resetCycle, verificationType}
      final Mission decoded = Mission.fromJson(<String, dynamic>{
        'missionId': 7,
        'title': '영어 단어 외우기',
        'category': 'STUDY',
        'resetCycle': 'WEEKLY',
        'verificationType': 'PARENT',
        'reward': 45,
        'description': '하루 10개',
      });
      expect(decoded.id, '7');
      expect(decoded.category, '학습');
      expect(decoded.resetCycle, '일주일');
      expect(decoded.confirmationMethod, ConfirmationMethod.parentApproval);
      expect(decoded.rewardMinutes, 45);
    });

    test('submission response prefers backend performance status', () {
      final MissionSubmissionResult pending =
          MissionSubmissionResult.fromJson(<String, dynamic>{
            'isAccepted': false,
            'reason': '부모님 확인 대기중입니다.',
            'status': 'PENDING',
            'performanceId': 201,
          });

      expect(pending.performanceId, '201');
      expect(
        pending.statusFor(ConfirmationMethod.aiAuto),
        MissionStatus.reviewing,
      );

      final MissionSubmissionResult rejected = MissionSubmissionResult.fromJson(
        <String, dynamic>{
          'isAccepted': false,
          'reason': '사진이 맞지 않습니다.',
          'status': 'REJECTED',
        },
      );

      expect(
        rejected.statusFor(ConfirmationMethod.aiAuto),
        MissionStatus.rejected,
      );
    });
  });

  group('TimeSchedule JSON round-trip', () {
    test('sampleV2PreviousWeek preserves weekly + day allocations', () {
      final TimeSchedule original = TimeScheduleMock.sampleV2PreviousWeek;
      final TimeSchedule decoded = TimeSchedule.fromJson(original.toJson());

      expect(decoded.allowedHours.length, original.allowedHours.length);
      expect(decoded.weeklyTotals.length, original.weeklyTotals.length);
      expect(decoded.dayAllocations.length, original.dayAllocations.length);
      expect(decoded.weeklyTotalCapMinutes, original.weeklyTotalCapMinutes);
      expect(decoded.weeklyTotalMinutesAt(3), 15 * 60 + 30);
    });

    test('monthly budget cap round-trips separately from weekly rows', () {
      const TimeSchedule original = TimeSchedule(
        allowedHours: <HourCell>{},
        weeklyTotals: <WeeklyTotal>[
          WeeklyTotal(weekIndex: 0, hours: 2, minutes: 0),
          WeeklyTotal(weekIndex: 1, hours: 2, minutes: 0),
          WeeklyTotal(weekIndex: 2, hours: 12, minutes: 0),
          WeeklyTotal(weekIndex: 3, hours: 23, minutes: 0),
        ],
        dayAllocations: <DayAllocation>[],
        monthlyBudgetMinutes: 116 * 60,
      );

      final TimeSchedule decoded = TimeSchedule.fromJson(original.toJson());

      expect(decoded.distributedWeeklyTotalMinutes, 39 * 60);
      expect(decoded.weeklyTotalCapMinutes, 116 * 60);
      expect(decoded.monthlyBudgetMinutes, 116 * 60);
    });

    test('HourCell round-trips weekday and hour', () {
      const HourCell original = HourCell(weekday: 3, hour: 14);
      final HourCell decoded = HourCell.fromJson(original.toJson());
      expect(decoded, original);
    });

    test('DayAllocation round-trips weekdayIndices and times', () {
      const DayAllocation original = DayAllocation(
        daysLabel: '월,수,금',
        weekdayIndices: <int>[0, 2, 4],
        hours: 2,
        minutes: 30,
      );
      final DayAllocation decoded = DayAllocation.fromJson(original.toJson());
      expect(decoded.daysLabel, '월,수,금');
      expect(decoded.weekdayIndices, <int>[0, 2, 4]);
      expect(decoded.hours, 2);
      expect(decoded.minutes, 30);
    });

    test('WeeklyTotal round-trips weekIndex, hours, minutes', () {
      const WeeklyTotal original = WeeklyTotal(
        weekIndex: 2,
        hours: 15,
        minutes: 30,
      );
      final WeeklyTotal decoded = WeeklyTotal.fromJson(original.toJson());
      expect(decoded.weekIndex, 2);
      expect(decoded.hours, 15);
      expect(decoded.minutes, 30);
    });
  });

  group('TimeConfirmData JSON round-trip', () {
    test('filled fixture preserves nested TimeSchedule', () {
      final TimeConfirmData original = TimeConfirmMock.filled;
      final TimeConfirmData decoded = TimeConfirmData.fromJson(
        original.toJson(),
      );

      expect(decoded.isEmpty, isFalse);
      expect(
        decoded.schedule?.weeklyTotals.length,
        original.schedule?.weeklyTotals.length,
      );
      expect(
        decoded.schedule?.dayAllocations.length,
        original.schedule?.dayAllocations.length,
      );
    });

    test('empty fixture decodes back to null schedule', () {
      const TimeConfirmData original = TimeConfirmMock.empty;
      final TimeConfirmData decoded = TimeConfirmData.fromJson(
        original.toJson(),
      );
      expect(decoded.isEmpty, isTrue);
    });
  });

  group('NotificationItem JSON round-trip', () {
    test('mock fixture round-trips id, type, createdAt', () {
      final NotificationItem original = NotificationsMock.filled.first;
      final NotificationItem decoded = NotificationItem.fromJson(
        original.toJson(),
      );

      expect(decoded.id, original.id);
      expect(decoded.type, original.type); // discriminating enum
      expect(decoded.title, original.title);
      expect(decoded.message, original.message);
      expect(decoded.createdAt, original.createdAt); // ISO date
      expect(decoded.deeplink, original.deeplink);
    });

    test('every mock notification preserves its type enum', () {
      for (final NotificationItem item in NotificationsMock.filled) {
        final NotificationItem decoded = NotificationItem.fromJson(
          item.toJson(),
        );
        expect(decoded.type, item.type, reason: 'type drift for ${item.id}');
      }
    });

    test('parses backend targetRoute and payload deeplink fields', () {
      final NotificationItem fromTargetRoute =
          NotificationItem.fromJson(<String, dynamic>{
            'notificationId': 17,
            'notificationType': 'MISSION_APPROVED',
            'title': '미션 승인 완료',
            'content': '부모님이 미션을 승인했습니다.',
            'createdAt': '2026-06-09T12:30:00',
            'targetRoute': '/child-home/mission/21',
          });

      expect(fromTargetRoute.id, '17');
      expect(fromTargetRoute.type, NotificationType.missionCompleted);
      expect(fromTargetRoute.deeplink, '/child-home/mission/21');

      final NotificationItem fromPayload = NotificationItem.fromJson(
        <String, dynamic>{
          'notificationId': 18,
          'notificationType': 'MISSION_REJECTED',
          'title': '미션 거절',
          'content': '부모님이 미션을 거절했습니다.',
          'createdAt': '2026-06-09T12:31:00',
          'payload': <String, dynamic>{'deeplink': '/child-home/mission/22'},
        },
      );

      expect(fromPayload.type, NotificationType.missionRejected);
      expect(fromPayload.deeplink, '/child-home/mission/22');
    });
  });

  group('FcmMessage JSON payload', () {
    test('uses backend targetRoute when deeplink is absent', () {
      final FcmMessage message = FcmMessage.fromRemoteMessage(
        const RemoteMessage(
          data: <String, dynamic>{
            'notificationType': 'MISSION_CREATED',
            'notificationId': 'n-2',
            'missionId': '21',
            'targetRoute': '/child-home/mission/21',
          },
        ),
      );

      expect(message.type, 'MISSION_CREATED');
      expect(message.notificationId, 'n-2');
      expect(message.entityId, '21');
      expect(message.deeplink, '/child-home/mission/21');
    });
  });

  group('UsageReport JSON round-trip', () {
    test('currentWeek fixture preserves nested structure', () {
      final UsageReport original = UsageReportMock.currentWeek;
      final UsageReport decoded = UsageReport.fromJson(original.toJson());

      expect(decoded.weekLabel, original.weekLabel);
      expect(decoded.plan.totalHours, original.plan.totalHours);
      expect(decoded.plan.daySets.length, original.plan.daySets.length);
      expect(decoded.dailyRows.length, original.dailyRows.length);
      expect(decoded.compliance.onPlanPct, original.compliance.onPlanPct);
      expect(decoded.compliance.overPct, original.compliance.overPct);
      expect(decoded.compliance.underPct, original.compliance.underPct);
      expect(decoded.suggestions.length, original.suggestions.length);
      // AiSuggestionTone is the discriminating enum on each suggestion.
      for (int i = 0; i < original.suggestions.length; i++) {
        expect(decoded.suggestions[i].tone, original.suggestions[i].tone);
        expect(
          decoded.suggestions[i].deltaHours,
          original.suggestions[i].deltaHours,
        );
      }
    });
  });

  group('UserProfile JSON round-trip', () {
    test('preserves username + accountType + childCode', () {
      const UserProfile original = UserProfile(
        username: 'gdg12',
        accountType: '자녀회원',
        childCode: 'XY785eZ',
      );
      final UserProfile decoded = UserProfile.fromJson(original.toJson());

      expect(decoded.username, 'gdg12');
      expect(decoded.accountType, '자녀회원');
      expect(decoded.childCode, 'XY785eZ');
    });
  });

  group('AuthToken JSON round-trip', () {
    test('preserves accessToken, refreshToken, username', () {
      const AuthToken original = AuthToken(
        accessToken: 'mock_access_gdg12',
        refreshToken: 'mock_refresh_gdg12',
        username: 'gdg12',
      );
      final AuthToken decoded = AuthToken.fromJson(original.toJson());

      expect(decoded.accessToken, 'mock_access_gdg12');
      expect(decoded.refreshToken, 'mock_refresh_gdg12');
      expect(decoded.username, 'gdg12');
    });

    test('handles null refreshToken', () {
      const AuthToken original = AuthToken(
        accessToken: 'mock_access_x',
        username: 'x',
      );
      final AuthToken decoded = AuthToken.fromJson(original.toJson());
      expect(decoded.refreshToken, isNull);
      expect(decoded.username, 'x');
    });
  });
}
