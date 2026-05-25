import 'package:bridge_k/features/time_setup/data/models/time_schedule.dart';

class TimeConfirmData {
  const TimeConfirmData({required this.schedule});
  final TimeSchedule? schedule; // null = empty/no plan set by parent
  bool get isEmpty => schedule == null;

  factory TimeConfirmData.fromJson(Map<String, dynamic> json) {
    final Object? rawSchedule = json['schedule'];
    return TimeConfirmData(
      schedule: rawSchedule is Map<String, dynamic>
          ? TimeSchedule.fromJson(rawSchedule)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schedule': schedule?.toJson(),
    };
  }
}
