class WeeklyTotalPlan {
  const WeeklyTotalPlan({required this.totalHours, required this.daySets});
  final int totalHours; // e.g. 21
  final List<DaySetPlan> daySets;
}

class DaySetPlan {
  const DaySetPlan({required this.daysLabel, required this.hoursPerDay});
  final String daysLabel; // '월,수,금' etc
  final int hoursPerDay; // 7
}

class DailyUsageRow {
  const DailyUsageRow({
    required this.dayKor,
    required this.plannedMinutes,
    required this.actualMinutes,
  });
  final String dayKor; // '월'..'일'
  final int plannedMinutes;
  final int actualMinutes;

  int get deltaMinutes => actualMinutes - plannedMinutes;
}

class ComplianceBreakdown {
  const ComplianceBreakdown({
    required this.onPlanPct,
    required this.overPct,
    required this.underPct,
  });
  final double onPlanPct; // 20 — % of days exactly on plan
  final double
  overPct; // 50 — % of days where actual > plan (primary blue slice)
  final double underPct; // 30 — % of days where actual < plan

  /// Figma spec §"Card 4" / `07-report.md:82` shows the header text
  /// "계획 이행률 50%" — the 50 corresponds to the **over-plan** slice
  /// (primary blue, "계획보다 많이 사용한 날"). Audit Issue 12 confirms
  /// this drift: prior implementation returned [onPlanPct] (20%) which
  /// did not match Figma. The semantics chosen by design appear to be
  /// "이행률 = % of days where the child engaged at least as much as
  /// planned" — i.e., the dominant over-plan slice.
  double get overallCompliancePct => overPct;
}

class AiSuggestion {
  const AiSuggestion({
    required this.daysLabel,
    required this.suggestedHours,
    required this.deltaHours,
    required this.tone,
  });
  final String daysLabel;

  /// Suggested plan length for this day group, in whole hours
  /// (e.g. 7 → renders as "7시간 00분" inside the Day Group Container).
  final int suggestedHours;
  final int deltaHours; // negative or positive
  final AiSuggestionTone tone;
}

enum AiSuggestionTone { positive, neutral, destructive }

class UsageReport {
  const UsageReport({
    required this.weekLabel,
    required this.plan,
    required this.dailyRows,
    required this.compliance,
    required this.suggestions,
  });
  final String weekLabel; // '2월 1주차 사용리포트'
  final WeeklyTotalPlan plan;
  final List<DailyUsageRow> dailyRows;
  final ComplianceBreakdown compliance;
  final List<AiSuggestion> suggestions;
}
