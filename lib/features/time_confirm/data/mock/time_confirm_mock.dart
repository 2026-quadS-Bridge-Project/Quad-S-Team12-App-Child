import 'package:bridge_k/features/time_setup/data/mock/time_schedule_mock.dart';
import '../models/time_confirm_data.dart';

class TimeConfirmMock {
  const TimeConfirmMock._();

  static const TimeConfirmData empty = TimeConfirmData(schedule: null);
  static TimeConfirmData get filled =>
      TimeConfirmData(schedule: TimeScheduleMock.sampleFilled);
  static TimeConfirmData get filledWithOnboarding => TimeConfirmData(
    schedule: TimeScheduleMock.sampleFilled,
    showOnboarding: true,
  );
}
