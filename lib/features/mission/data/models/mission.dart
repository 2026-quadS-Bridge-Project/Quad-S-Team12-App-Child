enum MissionStatus {
  pendingCheck, // 아직 안 한 미션
  reviewing, // 제출 완료, 부모/AI 확인 대기
  completed, // 승인 완료, 보너스 지급됨
  rejected, // 반려됨
}

/// Mission confirmation method — drives the submit-flow branching in
/// [MissionController.submit]:
/// - [aiAuto]         → reviewing → auto-approve after a short delay
/// - [childSelf]      → completes immediately on submit
/// - [parentApproval] → reviewing until the parent approves
enum ConfirmationMethod {
  aiAuto,
  childSelf,
  parentApproval;

  /// Korean display label used by the chip rows on Figma 746-11392.
  String get label {
    switch (this) {
      case ConfirmationMethod.aiAuto:
        return 'AI 자동확인';
      case ConfirmationMethod.childSelf:
        return '자녀 확인';
      case ConfirmationMethod.parentApproval:
        return '부모 확인';
    }
  }

  /// Backward-compat lookup for legacy callers that still hand around the
  /// Korean string. Returns null when no enum matches.
  static ConfirmationMethod? fromLabel(String label) {
    for (final ConfirmationMethod m in ConfirmationMethod.values) {
      if (m.label == label) return m;
    }
    return null;
  }
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.rewardHours,
    required this.rewardMinutes,
    required this.status,
    this.description,
    this.assignedBy = 'parent', // 'parent' or 'ai'
    this.photoUrls = const [],
    this.deadline,
    this.category = '루틴',
    this.categoryOptions = const <String>['루틴', '학습', '운동', '청소', '심부름'],
    this.resetCycle = '매일',
    this.resetCycleOptions = const <String>['매일', '일주일', '한 달'],
    this.confirmationMethod = ConfirmationMethod.childSelf,
    this.confirmationMethodOptions = const <ConfirmationMethod>[
      ConfirmationMethod.aiAuto,
      ConfirmationMethod.childSelf,
      ConfirmationMethod.parentApproval,
    ],
    this.payoutTime,
    this.captureInstruction = '깨끗해진 방을 찍어서 올려주세요!',
  });

  final String id;
  final String title;
  final int rewardHours;
  final int rewardMinutes;
  final MissionStatus status;
  final String? description;
  final String assignedBy;
  final List<String> photoUrls;
  final DateTime? deadline;

  /// Mission info section fields (frame 746-11392 — 5 chip rows).
  /// Each `*Options` list drives the horizontal selectable-chip row;
  /// the singular field (e.g. [category]) marks the selected option.
  final String category;
  final List<String> categoryOptions;
  final String resetCycle;
  final List<String> resetCycleOptions;
  final ConfirmationMethod confirmationMethod;
  final List<ConfirmationMethod> confirmationMethodOptions;
  final String? payoutTime;

  /// Mission-specific copy shown above the camera CTA on frames
  /// 426-18960 / 426-19035 / 426-18995 / 426-18974. Defaults to the
  /// Figma verbatim string for the `방청소 하기` mission.
  final String captureInstruction;

  /// Display string for the "지급시간" row. Falls back to a derived label
  /// when no explicit time is set.
  String get payoutTimeLabel => payoutTime ?? '수행 즉시';

  String get rewardLabel {
    if (rewardHours > 0 && rewardMinutes > 0) {
      return '$rewardHours시간 $rewardMinutes분 지급';
    }
    if (rewardHours > 0) return '$rewardHours시간 지급';
    return '$rewardMinutes분 지급';
  }

  Mission copyWith({MissionStatus? status, List<String>? photoUrls}) => Mission(
    id: id,
    title: title,
    rewardHours: rewardHours,
    rewardMinutes: rewardMinutes,
    status: status ?? this.status,
    description: description,
    assignedBy: assignedBy,
    photoUrls: photoUrls ?? this.photoUrls,
    deadline: deadline,
    category: category,
    categoryOptions: categoryOptions,
    resetCycle: resetCycle,
    resetCycleOptions: resetCycleOptions,
    confirmationMethod: confirmationMethod,
    confirmationMethodOptions: confirmationMethodOptions,
    payoutTime: payoutTime,
    captureInstruction: captureInstruction,
  );
}
