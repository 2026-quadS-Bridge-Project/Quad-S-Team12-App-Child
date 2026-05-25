import '../config/environment.dart';

/// Provides Korean calendar labels (`'2월'`, `'1주차'`, `'2월 1주차'`) that the
/// time-setup / time-confirm / report screens currently render.
///
/// Mock impl returns the deterministic Figma fixture (`2월 1주차`) so the
/// existing tests, screenshots, and widget snapshots stay stable. Production
/// uses [DateTime.now] so the labels refresh as the month/week rolls over.
///
/// Wired via [createCalendarService] which honors
/// `currentEnvironment.useMocks`.
abstract interface class CalendarService {
  /// Korean month label, e.g. `'2월'`.
  String currentMonthLabel();

  /// 1-based week-of-month index for the current date.
  int currentWeekIndex();

  /// Korean week label combining the above, e.g. `'2월 1주차'`.
  String currentWeekLabel();
}

CalendarService createCalendarService() {
  if (currentEnvironment.useMocks) return const MockCalendarService();
  return const DeviceCalendarService();
}

/// Deterministic fixture matching the Figma `2월 1주차` reference. Used in
/// the dev / mock environment so widget tests and screenshots stay stable.
class MockCalendarService implements CalendarService {
  const MockCalendarService();
  @override
  String currentMonthLabel() => '2월';
  @override
  int currentWeekIndex() => 1;
  @override
  String currentWeekLabel() => '2월 1주차';
}

/// Derives the label from [DateTime.now]. Week-of-month is computed as
/// `(day - 1) ~/ 7 + 1` — straightforward Sunday-first bucketing. If the
/// backend later supplies a different week rule (e.g., ISO weeks anchored
/// on a specific day) it should override this service rather than rewrite
/// every consumer.
class DeviceCalendarService implements CalendarService {
  const DeviceCalendarService();
  @override
  String currentMonthLabel() => '${DateTime.now().month}월';
  @override
  int currentWeekIndex() {
    final DateTime now = DateTime.now();
    return (now.day - 1) ~/ 7 + 1;
  }

  @override
  String currentWeekLabel() =>
      '${currentMonthLabel()} ${currentWeekIndex()}주차';
}
