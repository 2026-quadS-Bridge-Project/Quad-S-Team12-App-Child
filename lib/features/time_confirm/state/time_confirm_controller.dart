import 'package:flutter/foundation.dart';

import '../data/mock/time_confirm_mock.dart';
import '../data/models/time_confirm_data.dart';

class TimeConfirmController extends ChangeNotifier {
  TimeConfirmController({TimeConfirmData? initial})
    : _data = initial ?? TimeConfirmMock.filled;

  TimeConfirmData _data;
  TimeConfirmData get data => _data;

  void dismissOnboarding() {
    if (_data.showOnboarding) {
      _data = TimeConfirmData(schedule: _data.schedule);
      notifyListeners();
    }
  }

  /// Stub for the "수정요청" flow — child requests parent to modify schedule.
  /// Per domain decision, child cannot edit directly; only request.
  void requestModification() {
    // TODO: backend integration — push request to parent.
  }
}
