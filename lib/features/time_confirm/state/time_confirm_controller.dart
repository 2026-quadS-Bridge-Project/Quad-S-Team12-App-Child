import 'package:flutter/foundation.dart';

import '../../../core/models/result.dart';
import '../../../core/widgets/mixins/async_error_listener.dart';
import '../data/mock/time_confirm_mock.dart';
import '../data/models/time_confirm_data.dart';
import '../data/repositories/time_confirm_repository.dart';

/// View-model for the Time Confirm page.
///
/// Holds the currently-displayed [TimeConfirmData] plus loading/error flags,
/// and delegates side-effecting flows (request modification, acknowledge)
/// to a [TimeConfirmRepository].
class TimeConfirmController extends ChangeNotifier
    implements AsyncErrorController {
  TimeConfirmController({
    TimeConfirmData? initial,
    TimeConfirmRepository? repository,
  })  : _data = initial ?? TimeConfirmMock.filled,
        _repository = repository ?? createTimeConfirmRepository();

  final TimeConfirmRepository _repository;

  TimeConfirmData _data;
  TimeConfirmData get data => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;

  /// Clears [errorMessage] so the next failure can fire again. No-op when
  /// the controller is already in a clean state.
  @override
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetches the latest schedule from the repository and updates [data].
  ///
  /// The synchronous initializer from `initial` remains the seed shown on
  /// first paint; calling [load] refreshes it from the repo.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final Result<TimeConfirmData> result =
        await _repository.fetchCurrentSchedule();
    switch (result) {
      case Success<TimeConfirmData>(:final data):
        _data = data;
      case Failure<TimeConfirmData>(:final message):
        _errorMessage = message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Child requests parent to modify the schedule. Per domain decision,
  /// child cannot edit directly; only request.
  Future<void> requestModification() async {
    _errorMessage = null;
    final Result<void> result = await _repository.requestModification();
    if (result case Failure<void>(:final message)) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// Marks the schedule as acknowledged by the child (the 확인 CTA).
  ///
  /// Navigation stays in the page; call this before `context.pop()`.
  Future<void> acknowledge() async {
    _errorMessage = null;
    final Result<void> result = await _repository.acknowledgeSchedule();
    if (result case Failure<void>(:final message)) {
      _errorMessage = message;
      notifyListeners();
    }
  }
}
