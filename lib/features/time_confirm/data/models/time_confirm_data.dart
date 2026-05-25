import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';

class TimeConfirmData {
  const TimeConfirmData({required this.schedule});
  final TimeSchedule? schedule; // null = empty/no plan set by parent
  bool get isEmpty => schedule == null;
}
