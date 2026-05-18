import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';

class TimeConfirmData {
  const TimeConfirmData({required this.schedule, this.showOnboarding = false});
  final TimeSchedule? schedule; // null = empty/no plan set by parent
  final bool showOnboarding; // true → render tooltip on first visit
  bool get isEmpty => schedule == null;
}
