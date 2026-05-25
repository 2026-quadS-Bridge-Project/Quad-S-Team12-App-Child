import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/models/mission.dart';
import '../data/mock/mission_mock.dart';
import '../data/repositories/mission_repository.dart';
import '../../../core/models/result.dart';
import '../../../core/services/photo_upload_service.dart';

/// Flow steps for the mission detail screen.
///
/// Note: there is no separate `perform` step — the perform-empty content
/// renders as the `수행정보` tab of the [MissionFlowStep.info] view per
/// Figma 746-11380 (which is the same screen as 746-11392 with the second
/// tab active).
enum MissionFlowStep { info, cameraPrompt, photoPreview, submitted }

class MissionController extends ChangeNotifier {
  /// Public constructor.
  ///
  /// [repository] is injectable for tests; production callers can omit it
  /// and the controller will pick the right impl via
  /// [createMissionRepository] (mock today, HTTP once the backend ships).
  /// [uploadService] is similarly injectable — defaults to
  /// [createPhotoUploadService] so production callers get the mock/api
  /// impl that matches the current environment.
  /// The initial [Mission] is seeded synchronously from [MissionMock] so
  /// the UI has data to render on first frame; [reload] can fetch fresh
  /// data afterwards.
  MissionController({
    required String missionId,
    MissionRepository? repository,
    PhotoUploadService? uploadService,
  }) : this._(
          MissionMock.byId(missionId),
          repository ?? createMissionRepository(),
          uploadService ?? createPhotoUploadService(),
        );

  MissionController._(Mission mission, this._repository, this._uploadService)
      : _mission = mission,
        _step = _initialStepFor(mission);

  final MissionRepository _repository;
  final PhotoUploadService _uploadService;
  Mission _mission;
  MissionFlowStep _step;
  final List<String> _capturedPhotoPaths = [];
  Timer? _autoApproveTimer;
  bool _disposed = false;
  bool _isLoading = false;
  String? _errorMessage;

  Mission get mission => _mission;
  MissionFlowStep get step => _step;
  List<String> get capturedPhotos => List.unmodifiable(_capturedPhotoPaths);
  bool get canSubmit => _capturedPhotoPaths.isNotEmpty && !_isLoading;
  bool get hasMaxPhotos => _capturedPhotoPaths.length >= 4;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void goToCameraPrompt() {
    _step = MissionFlowStep.cameraPrompt;
    notifyListeners();
  }

  void goToPhotoPreview() {
    _step = MissionFlowStep.photoPreview;
    notifyListeners();
  }

  /// Uploads a freshly captured photo via [_uploadService] and, on success,
  /// appends the returned URL/path to [_capturedPhotoPaths].
  ///
  /// Mock builds resolve immediately (echoing the local path), so the UI
  /// can `await` this without needing a spinner. Real backend uploads will
  /// surface failures via [errorMessage] without mutating the photo list.
  /// The 4-photo cap is enforced before the upload starts to avoid
  /// pointless network work.
  Future<void> addCapturedPhoto(String localPath) async {
    if (_capturedPhotoPaths.length >= 4) return;
    final Result<String> result = await _uploadService.uploadPhoto(localPath);
    if (_disposed) return;
    switch (result) {
      case Success<String>(data: final String remotePathOrUrl):
        _capturedPhotoPaths.add(remotePathOrUrl);
        if (_step == MissionFlowStep.cameraPrompt) {
          _step = MissionFlowStep.photoPreview;
        }
        _errorMessage = null;
        notifyListeners();
      case Failure<String>(message: final String message):
        _errorMessage = message;
        notifyListeners();
    }
  }

  void removePhoto(int index) {
    if (index < 0 || index >= _capturedPhotoPaths.length) return;
    _capturedPhotoPaths.removeAt(index);
    notifyListeners();
  }

  /// Submit the captured photos to the backend.
  ///
  /// Mock repo resolves immediately; api repo will hit the network. On
  /// success the controller applies the same self-confirm vs. AI-auto-approve
  /// transitions the pre-refactor implementation used. The auto-approve
  /// [Timer] remains mock-UX-only and is cancelled in [dispose].
  Future<void> submit({bool? aiAutoApprove}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Result<Mission> result = await _repository.submitMission(
        id: _mission.id,
        photoPaths: List.of(_capturedPhotoPaths),
      );

      switch (result) {
        case Success<Mission>():
          final bool completesImmediately =
              _mission.confirmationMethod == ConfirmationMethod.childSelf;
          _mission = _mission.copyWith(
            status: completesImmediately
                ? MissionStatus.completed
                : MissionStatus.reviewing,
            photoUrls: List.of(_capturedPhotoPaths),
          );
          _step = MissionFlowStep.submitted;

          // Simulate async review for mock UX. Cancellable via [dispose] so we
          // never call notifyListeners() on a disposed ChangeNotifier.
          _autoApproveTimer?.cancel();
          final bool shouldAutoApprove = aiAutoApprove ??
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
        case Failure<Mission>(message: final String message):
          _errorMessage = message;
      }
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Refresh the current mission from the repository, replacing [_mission]
  /// on success. Errors surface via [errorMessage] without changing the
  /// existing displayed mission.
  Future<void> reload() async {
    final Result<Mission> result = await _repository.fetchMission(_mission.id);
    switch (result) {
      case Success<Mission>(data: final Mission fresh):
        _mission = fresh;
        if (!_disposed) notifyListeners();
      case Failure<Mission>(message: final String message):
        _errorMessage = message;
        if (!_disposed) notifyListeners();
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
