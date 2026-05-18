import '../models/usage_report.dart';

class UsageReportMock {
  const UsageReportMock._();

  static const UsageReport currentWeek = UsageReport(
    weekLabel: '2월 1주차 사용리포트',
    plan: WeeklyTotalPlan(
      totalHours: 21,
      daySets: [
        DaySetPlan(daysLabel: '월,수,금', hoursPerDay: 7),
        DaySetPlan(daysLabel: '화,목', hoursPerDay: 7),
        DaySetPlan(daysLabel: '토,일', hoursPerDay: 7),
      ],
    ),
    dailyRows: [
      DailyUsageRow(
        dayKor: '월',
        plannedMinutes: 420,
        actualMinutes: 300,
      ), // -120
      DailyUsageRow(
        dayKor: '화',
        plannedMinutes: 420,
        actualMinutes: 540,
      ), // +120
      DailyUsageRow(dayKor: '수', plannedMinutes: 420, actualMinutes: 420), // 0
      DailyUsageRow(dayKor: '목', plannedMinutes: 420, actualMinutes: 420), // 0
      DailyUsageRow(
        dayKor: '금',
        plannedMinutes: 420,
        actualMinutes: 540,
      ), // +120
      DailyUsageRow(
        dayKor: '토',
        plannedMinutes: 420,
        actualMinutes: 600,
      ), // +180
      DailyUsageRow(dayKor: '일', plannedMinutes: 420, actualMinutes: 420), // 0
    ],
    compliance: ComplianceBreakdown(onPlanPct: 20, overPct: 50, underPct: 30),
    // Per Figma 662:11585 (Card 5) — each row mirrors the Card 3 day-group
    // container with `[days] | [H시간 MM분] | [delta chip]`. Suggested
    // hours are 7 across the board per spec mock.
    suggestions: [
      AiSuggestion(
        daysLabel: '월,금',
        suggestedHours: 7,
        deltaHours: 2,
        tone: AiSuggestionTone.positive,
      ),
      AiSuggestion(
        daysLabel: '토,일',
        suggestedHours: 7,
        deltaHours: -2,
        tone: AiSuggestionTone.destructive,
      ),
      AiSuggestion(
        daysLabel: '화,목',
        suggestedHours: 7,
        deltaHours: 0,
        tone: AiSuggestionTone.neutral,
      ),
      AiSuggestion(
        daysLabel: '수',
        suggestedHours: 7,
        deltaHours: 0,
        tone: AiSuggestionTone.neutral,
      ),
    ],
  );
}
