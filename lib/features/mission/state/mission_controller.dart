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
    : _mission = MissionMock.byId(missionId);

  Mission _mission;
  MissionFlowStep _step = MissionFlowStep.info;
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

  /// Mock submission — transitions to reviewing then (in real backend) eventually approved/rejected.
  void submit({bool aiAutoApprove = true}) {
    _mission = _mission.copyWith(
      status: MissionStatus.reviewing,
      photoUrls: List.of(_capturedPhotoPaths),
    );
    _step = MissionFlowStep.submitted;
    notifyListeners();

    // Simulate async review for mock UX. Cancellable via [dispose] so we
    // never call notifyListeners() on a disposed ChangeNotifier.
    _autoApproveTimer?.cancel();
    if (aiAutoApprove) {
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
}
