class WeeklyTotalPlan {
  const WeeklyTotalPlan({required this.totalHours, required this.daySets});
  final int totalHours; // e.g. 21
  final List<DaySetPlan> daySets;

  factory WeeklyTotalPlan.fromJson(Map<String, dynamic> json) {
    final dynamic rawDaySets = json['daySets'];
    final List<DaySetPlan> daySets = rawDaySets is List
        ? rawDaySets
              .whereType<Map<String, dynamic>>()
              .map(DaySetPlan.fromJson)
              .toList()
        : const <DaySetPlan>[];
    return WeeklyTotalPlan(
      totalHours: (json['totalHours'] as num?)?.toInt() ?? 0,
      daySets: daySets,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalHours': totalHours,
    'daySets': <Map<String, dynamic>>[
      for (final DaySetPlan d in daySets) d.toJson(),
    ],
  };
}

class DaySetPlan {
  const DaySetPlan({required this.daysLabel, required this.hoursPerDay});
  final String daysLabel; // '월,수,금' etc
  final int hoursPerDay; // 7

  factory DaySetPlan.fromJson(Map<String, dynamic> json) {
    return DaySetPlan(
      daysLabel: (json['daysLabel'] ?? '').toString(),
      hoursPerDay: (json['hoursPerDay'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'daysLabel': daysLabel,
    'hoursPerDay': hoursPerDay,
  };
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

  factory DailyUsageRow.fromJson(Map<String, dynamic> json) {
    return DailyUsageRow(
      dayKor: (json['dayKor'] ?? '').toString(),
      plannedMinutes: (json['plannedMinutes'] as num?)?.toInt() ?? 0,
      actualMinutes: (json['actualMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'dayKor': dayKor,
    'plannedMinutes': plannedMinutes,
    'actualMinutes': actualMinutes,
  };
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

  factory ComplianceBreakdown.fromJson(Map<String, dynamic> json) {
    return ComplianceBreakdown(
      onPlanPct: (json['onPlanPct'] as num?)?.toDouble() ?? 0,
      overPct: (json['overPct'] as num?)?.toDouble() ?? 0,
      underPct: (json['underPct'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'onPlanPct': onPlanPct,
    'overPct': overPct,
    'underPct': underPct,
  };
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

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      daysLabel: (json['daysLabel'] ?? '').toString(),
      suggestedHours: (json['suggestedHours'] as num?)?.toInt() ?? 0,
      deltaHours: (json['deltaHours'] as num?)?.toInt() ?? 0,
      tone: _aiSuggestionToneFromName(json['tone']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'daysLabel': daysLabel,
    'suggestedHours': suggestedHours,
    'deltaHours': deltaHours,
    'tone': tone.name,
  };
}

enum AiSuggestionTone { positive, neutral, destructive }

/// JSON name lookup for [AiSuggestionTone]; defaults to
/// [AiSuggestionTone.neutral] when [name] is null or unknown.
AiSuggestionTone _aiSuggestionToneFromName(String? name) {
  if (name == null) return AiSuggestionTone.neutral;
  for (final AiSuggestionTone t in AiSuggestionTone.values) {
    if (t.name == name) return t;
  }
  return AiSuggestionTone.neutral;
}

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

  factory UsageReport.fromJson(Map<String, dynamic> json) {
    final dynamic rawPlan = json['plan'];
    final WeeklyTotalPlan plan = rawPlan is Map<String, dynamic>
        ? WeeklyTotalPlan.fromJson(rawPlan)
        : const WeeklyTotalPlan(totalHours: 0, daySets: <DaySetPlan>[]);

    final dynamic rawDailyRows = json['dailyRows'];
    final List<DailyUsageRow> dailyRows = rawDailyRows is List
        ? rawDailyRows
              .whereType<Map<String, dynamic>>()
              .map(DailyUsageRow.fromJson)
              .toList()
        : const <DailyUsageRow>[];

    final dynamic rawCompliance = json['compliance'];
    final ComplianceBreakdown compliance =
        rawCompliance is Map<String, dynamic>
        ? ComplianceBreakdown.fromJson(rawCompliance)
        : const ComplianceBreakdown(onPlanPct: 0, overPct: 0, underPct: 0);

    final dynamic rawSuggestions = json['suggestions'];
    final List<AiSuggestion> suggestions = rawSuggestions is List
        ? rawSuggestions
              .whereType<Map<String, dynamic>>()
              .map(AiSuggestion.fromJson)
              .toList()
        : const <AiSuggestion>[];

    return UsageReport(
      weekLabel: (json['weekLabel'] ?? '').toString(),
      plan: plan,
      dailyRows: dailyRows,
      compliance: compliance,
      suggestions: suggestions,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weekLabel': weekLabel,
    'plan': plan.toJson(),
    'dailyRows': <Map<String, dynamic>>[
      for (final DailyUsageRow r in dailyRows) r.toJson(),
    ],
    'compliance': compliance.toJson(),
    'suggestions': <Map<String, dynamic>>[
      for (final AiSuggestion s in suggestions) s.toJson(),
    ],
  };
}
