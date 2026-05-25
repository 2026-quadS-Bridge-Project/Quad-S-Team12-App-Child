import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/models/mission.dart';
import '../data/mock/mission_mock.dart';

/// Flow steps for the mission detail screen.
///
/// Note: there is no separate `perform` step — the perform-empty content
/// renders as the `수행정보` tab of the [MissionFlowStep.info] view per
/// Figma 746-11380 (which is the same screen as 746-11392 with the second
/// tab active).
enum MissionFlowStep { info, cameraPrompt, photoPreview, submitted }

class MissionController extends ChangeNotifier {
  MissionController({required String missionId})
    : this._(MissionMock.byId(missionId));

  MissionController._(Mission mission)
    : _mission = mission,
      _step = _initialStepFor(mission);

  Mission _mission;
  MissionFlowStep _step;
  final List<String> _capturedPhotoPaths = [];
  Timer? _autoApproveTimer;
  bool _disposed = false;

  Mission get mission => _mission;
  MissionFlowStep get step => _step;
  List<String> get capturedPhotos => List.unmodifiable(_capturedPhotoPaths);
  bool get canSubmit => _capturedPhotoPaths.isNotEmpty;
  bool get hasMaxPhotos => _capturedPhotoPaths.length >= 4;

  void goToCameraPrompt() {
    _step = MissionFlowStep.cameraPrompt;
    notifyListeners();
  }

  void goToPhotoPreview() {
    _step = MissionFlowStep.photoPreview;
    notifyListeners();
  }

  void addPhoto(String path) {
    if (_capturedPhotoPaths.length >= 4) return;
    _capturedPhotoPaths.add(path);
    if (_step == MissionFlowStep.cameraPrompt) {
      _step = MissionFlowStep.photoPreview;
    }
    notifyListeners();
  }

  void removePhoto(int index) {
    if (index < 0 || index >= _capturedPhotoPaths.length) return;
    _capturedPhotoPaths.removeAt(index);
    notifyListeners();
  }

  /// Mock submission — self-confirm missions complete immediately; AI/parent
  /// confirmation missions enter reviewing until backend approval arrives.
  void submit({bool? aiAutoApprove}) {
    final bool completesImmediately =
        _mission.confirmationMethod == ConfirmationMethod.childSelf;
    _mission = _mission.copyWith(
      status: completesImmediately
          ? MissionStatus.completed
          : MissionStatus.reviewing,
      photoUrls: List.of(_capturedPhotoPaths),
    );
    _step = MissionFlowStep.submitted;
    notifyListeners();

    // Simulate async review for mock UX. Cancellable via [dispose] so we
    // never call notifyListeners() on a disposed ChangeNotifier.
    _autoApproveTimer?.cancel();
    final bool shouldAutoApprove =
        aiAutoApprove ??
        (_mission.confirmationMethod == ConfirmationMethod.aiAuto);
    if (!completesImmediately && shouldAutoApprove) {
      _autoApproveTimer = Timer(const Duration(seconds: 2), () {
        if (_disposed) return;
        if (_step == MissionFlowStep.submitted &&
            _mission.status == MissionStatus.reviewing) {
          _mission = _mission.copyWith(status: MissionStatus.completed);
          notifyListeners();
        }
      });
    }
  }

  void goBack() {
    switch (_step) {
      case MissionFlowStep.cameraPrompt:
        _step = MissionFlowStep.info;
      case MissionFlowStep.photoPreview:
        _step = MissionFlowStep.cameraPrompt;
      case MissionFlowStep.submitted:
        // No back from submitted — user must exit via 홈으로
        break;
      case MissionFlowStep.info:
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoApproveTimer?.cancel();
    _autoApproveTimer = null;
    super.dispose();
  }

  static MissionFlowStep _initialStepFor(Mission mission) {
    return switch (mission.status) {
      MissionStatus.reviewing ||
      MissionStatus.completed => MissionFlowStep.submitted,
      // No rejected detail node exists in Figma; keep rejected missions on the
      // information tabs until a retry/reason design is supplied.
      MissionStatus.rejected ||
      MissionStatus.pendingCheck => MissionFlowStep.info,
    };
  }
}
