enum MissionStatus {
  pendingCheck, // 아직 안 한 미션
  reviewing, // 제출 완료, 부모/AI 확인 대기
  completed, // 승인 완료, 보너스 지급됨
  rejected, // 반려됨
}

class MissionSubmissionResult {
  const MissionSubmissionResult({this.isAccepted, this.reason});

  final bool? isAccepted;
  final String? reason;

  factory MissionSubmissionResult.fromJson(Map<String, dynamic> json) {
    return MissionSubmissionResult(
      isAccepted: json['isAccepted'] as bool?,
      reason: json['reason'] as String?,
    );
  }

  MissionStatus statusFor(ConfirmationMethod confirmationMethod) {
    switch (confirmationMethod) {
      case ConfirmationMethod.childSelf:
        return MissionStatus.completed;
      case ConfirmationMethod.parentApproval:
        return MissionStatus.reviewing;
      case ConfirmationMethod.aiAuto:
        return switch (isAccepted) {
          true => MissionStatus.completed,
          false => MissionStatus.rejected,
          null => MissionStatus.reviewing,
        };
    }
  }
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

  /// Resolve the enum from its [name] (e.g. `'aiAuto'`). Returns
  /// [ConfirmationMethod.childSelf] when [name] is null/unknown so
  /// JSON payloads with missing fields land on the safe default.
  static ConfirmationMethod fromName(String? name) {
    if (name == null) return ConfirmationMethod.childSelf;
    for (final ConfirmationMethod m in ConfirmationMethod.values) {
      if (m.name == name) return m;
    }
    return ConfirmationMethod.childSelf;
  }
}

/// JSON name lookup for [MissionStatus]; defaults to
/// [MissionStatus.pendingCheck] when [name] is null or unknown.
MissionStatus _missionStatusFromName(String? name) {
  if (name == null) return MissionStatus.pendingCheck;
  for (final MissionStatus s in MissionStatus.values) {
    if (s.name == name) return s;
  }
  return MissionStatus.pendingCheck;
}

/// Backend mission category enum (`CLEANING`/`STUDY`/…) → the Korean label the
/// child app stores in [Mission.category]. Lookup is case-insensitive. Values
/// already in Korean (mock fixtures, contract shape) pass through unchanged.
String _categoryFromWire(Object? raw) {
  if (raw == null) return '루틴';
  const Map<String, String> map = <String, String>{
    'CLEANING': '청소',
    'STUDY': '학습',
    'EXERCISE': '운동',
    'ERRAND': '심부름',
    'ROUTINE': '루틴',
  };
  final String value = raw.toString();
  return map[value.toUpperCase()] ?? value;
}

/// Backend reset-cycle enum (`DAILY`/`WEEKLY`/`MONTHLY`) → Korean label.
/// Case-insensitive; Korean/contract values pass through unchanged.
String _resetCycleFromWire(Object? raw) {
  if (raw == null) return '매일';
  const Map<String, String> map = <String, String>{
    'DAILY': '매일',
    'WEEKLY': '일주일',
    'MONTHLY': '한 달',
  };
  final String value = raw.toString();
  return map[value.toUpperCase()] ?? value;
}

/// Resolve [ConfirmationMethod] from either the child app's own field
/// (`confirmationMethod`: `aiAuto`/`childSelf`/`parentApproval`) or the
/// backend mission's `verificationType` enum (`AI`/`CHILD`/`PARENT`).
ConfirmationMethod _confirmationFromWire(Map<String, dynamic> json) {
  final Object? verificationType = json['verificationType'];
  if (verificationType != null) {
    switch (verificationType.toString().toUpperCase()) {
      case 'AI':
        return ConfirmationMethod.aiAuto;
      case 'CHILD':
        return ConfirmationMethod.childSelf;
      case 'PARENT':
        return ConfirmationMethod.parentApproval;
    }
  }
  return ConfirmationMethod.fromName(json['confirmationMethod']?.toString());
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

  /// Hand-written JSON decoder used by the repository layer.
  ///
  /// Sensibly defaults missing fields so partial backend payloads still
  /// produce a renderable [Mission] for the UI:
  /// - `status` → [MissionStatus.pendingCheck]
  /// - `confirmationMethod` → [ConfirmationMethod.childSelf]
  /// - `photoUrls` → `[]`
  factory Mission.fromJson(Map<String, dynamic> json) {
    final dynamic rawPhotoUrls = json['photoUrls'];
    final List<String> photoUrls = rawPhotoUrls is List
        ? rawPhotoUrls.map((dynamic e) => e.toString()).toList()
        : const <String>[];

    final dynamic rawCategoryOptions = json['categoryOptions'];
    final List<String> categoryOptions = rawCategoryOptions is List
        ? rawCategoryOptions.map((dynamic e) => e.toString()).toList()
        : const <String>['루틴', '학습', '운동', '청소', '심부름'];

    final dynamic rawResetCycleOptions = json['resetCycleOptions'];
    final List<String> resetCycleOptions = rawResetCycleOptions is List
        ? rawResetCycleOptions.map((dynamic e) => e.toString()).toList()
        : const <String>['매일', '일주일', '한 달'];

    final dynamic rawConfirmationOptions = json['confirmationMethodOptions'];
    final List<ConfirmationMethod> confirmationOptions =
        rawConfirmationOptions is List
        ? rawConfirmationOptions
              .map((dynamic e) => ConfirmationMethod.fromName(e?.toString()))
              .toList()
        : const <ConfirmationMethod>[
            ConfirmationMethod.aiAuto,
            ConfirmationMethod.childSelf,
            ConfirmationMethod.parentApproval,
          ];

    final dynamic rawDeadline = json['deadline'];
    final DateTime? deadline = rawDeadline is String
        ? DateTime.tryParse(rawDeadline)
        : null;

    // Reward: backend mission DTOs send a single `reward` (total minutes);
    // the app's own shape splits it into rewardHours + rewardMinutes. Prefer
    // the backend field when present, else fall back to the split fields.
    final num? rawReward = json['reward'] as num?;
    final int rewardHours = rawReward != null
        ? rawReward.toInt() ~/ 60
        : (json['rewardHours'] as num?)?.toInt() ?? 0;
    final int rewardMinutes = rawReward != null
        ? rawReward.toInt() % 60
        : (json['rewardMinutes'] as num?)?.toInt() ?? 0;

    return Mission(
      // Backend summary/detail key is `missionId`; the app's own shape uses `id`.
      id: (json['missionId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      rewardHours: rewardHours,
      rewardMinutes: rewardMinutes,
      status: _missionStatusFromName(json['status']?.toString()),
      description: json['description']?.toString(),
      assignedBy: (json['assignedBy'] ?? 'parent').toString(),
      photoUrls: photoUrls,
      deadline: deadline,
      category: _categoryFromWire(json['category']),
      categoryOptions: categoryOptions,
      resetCycle: _resetCycleFromWire(json['resetCycle']),
      resetCycleOptions: resetCycleOptions,
      confirmationMethod: _confirmationFromWire(json),
      confirmationMethodOptions: confirmationOptions,
      payoutTime: json['payoutTime']?.toString(),
      captureInstruction: (json['captureInstruction'] ?? '깨끗해진 방을 찍어서 올려주세요!')
          .toString(),
    );
  }

  /// Hand-written JSON encoder. Enums are serialised via [Enum.name] so the
  /// payload matches what [Mission.fromJson] expects.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'rewardHours': rewardHours,
    'rewardMinutes': rewardMinutes,
    'status': status.name,
    'description': description,
    'assignedBy': assignedBy,
    'photoUrls': photoUrls,
    'deadline': deadline?.toIso8601String(),
    'category': category,
    'categoryOptions': categoryOptions,
    'resetCycle': resetCycle,
    'resetCycleOptions': resetCycleOptions,
    'confirmationMethod': confirmationMethod.name,
    'confirmationMethodOptions': <String>[
      for (final ConfirmationMethod m in confirmationMethodOptions) m.name,
    ],
    'payoutTime': payoutTime,
    'captureInstruction': captureInstruction,
  };
}
