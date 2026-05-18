import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../buttons/bridge_button.dart';
import '../inputs/bridge_weekday_selector.dart';
import 'bridge_wheel_picker.dart';

/// Internal mode of [BridgeTimeAllocBottomSheet] — the sheet swaps content
/// between picking weekdays and picking a duration without being dismissed.
///
/// See docs/figma-specs/08b-time-v1-daily.md (frames 12148 / 12742 / 13019).
enum BottomSheetMode {
  /// Weekday chips + tap-to-open time row. Header "요일 선택".
  dayPicker,

  /// Hour + minute scroll wheels with primary selection band. Header
  /// "시간 선택".
  timePicker,
}

/// Result returned by [BridgeTimeAllocBottomSheet] when the user commits.
///
/// `days` is the set of selected weekday indices (0 = 월 … 6 = 일).
@immutable
class TimeAllocPick {
  const TimeAllocPick({
    required this.days,
    required this.hours,
    required this.minutes,
  });

  final Set<int> days;
  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeAllocPick &&
        other.hours == hours &&
        other.minutes == minutes &&
        _setEquals(other.days, days);
  }

  @override
  int get hashCode =>
      Object.hash(hours, minutes, Object.hashAllUnordered(days));

  static bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}

/// Daily time-allocation bottom sheet used in the child onboarding flow
/// (step 3/3 — distributing the weekly target across the 7 days).
///
/// Two visual modes live inside a single sheet so the user can switch back
/// and forth without dismissing the scrim:
///
/// 1. [BottomSheetMode.dayPicker] — header "요일 선택", weekday chips on top
///    and an outlined "tap to set time" row below.
/// 2. [BottomSheetMode.timePicker] — header "시간 선택", two scroll wheels
///    overlaid by a primary selection band.
///
/// Flow: opens in `dayPicker` → tapping the time row switches to
/// `timePicker` → "확인" in `timePicker` commits the wheel values and
/// returns to `dayPicker` → "확인" in `dayPicker` commits the full
/// [TimeAllocPick] via `Navigator.pop`.
class BridgeTimeAllocBottomSheet extends StatefulWidget {
  const BridgeTimeAllocBottomSheet({
    super.key,
    this.initialDays = const {},
    this.initialHours = 0,
    this.initialMinutes = 0,
    this.maxHours = 23,
    this.minuteStep = 5,
  });

  /// Pre-selected weekday indices (0..6).
  final Set<int> initialDays;

  /// Pre-selected hour wheel value (0..[maxHours]).
  final int initialHours;

  /// Pre-selected minute wheel value (0..59, snapped to [minuteStep]).
  final int initialMinutes;

  /// Inclusive upper bound for the hour wheel.
  final int maxHours;

  /// Minute wheel granularity (e.g. 5 → 00, 05, 10 … 55).
  final int minuteStep;

  /// Opens the sheet as a transparent-scrim modal and resolves with the
  /// committed [TimeAllocPick] or `null` if dismissed without commit.
  static Future<TimeAllocPick?> show(
    BuildContext context, {
    Set<int> initialDays = const {},
    int initialHours = 0,
    int initialMinutes = 0,
    int maxHours = 23,
    int minuteStep = 5,
  }) {
    return showModalBottomSheet<TimeAllocPick>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: AppColors.scrim,
      builder: (_) => BridgeTimeAllocBottomSheet(
        initialDays: initialDays,
        initialHours: initialHours,
        initialMinutes: initialMinutes,
        maxHours: maxHours,
        minuteStep: minuteStep,
      ),
    );
  }

  @override
  State<BridgeTimeAllocBottomSheet> createState() =>
      _BridgeTimeAllocBottomSheetState();
}

class _BridgeTimeAllocBottomSheetState
    extends State<BridgeTimeAllocBottomSheet> {
  // Sheet chrome — derived from Figma frame 695-12148.
  static const double _sheetHeight = 397;
  static const double _sheetRadius = 24;
  static const double _handleTop = 8;
  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _headerTop = 27;
  static const double _ctaBottom = 63;
  static const double _ctaHorizontalPadding = 24;
  static const double _selectionBandWidth = 324;
  static const double _selectionBandHeight = 50;

  late BottomSheetMode _mode;
  late Set<int> _days;
  late int _hours;
  late int _minutes;
  late List<int> _minuteValues;

  @override
  void initState() {
    super.initState();
    _mode = BottomSheetMode.dayPicker;
    _days = Set<int>.from(widget.initialDays);
    _minuteValues = _buildMinuteValues(widget.minuteStep);
    _hours = widget.initialHours.clamp(0, widget.maxHours);
    _minutes = _nearestMinute(widget.initialMinutes, _minuteValues);
  }

  static List<int> _buildMinuteValues(int step) {
    final safeStep = step <= 0 ? 1 : step;
    final values = <int>[];
    for (var m = 0; m < 60; m += safeStep) {
      values.add(m);
    }
    return values;
  }

  static int _nearestMinute(int target, List<int> values) {
    if (values.isEmpty) return 0;
    int best = values.first;
    int bestDiff = (best - target).abs();
    for (final v in values) {
      final diff = (v - target).abs();
      if (diff < bestDiff) {
        best = v;
        bestDiff = diff;
      }
    }
    return best;
  }

  bool get _canConfirm {
    if (_mode == BottomSheetMode.timePicker) return true;
    return _days.isNotEmpty && (_hours + _minutes) > 0;
  }

  void _onConfirm() {
    if (_mode == BottomSheetMode.timePicker) {
      setState(() => _mode = BottomSheetMode.dayPicker);
      return;
    }
    Navigator.of(context).pop(
      TimeAllocPick(
        days: Set<int>.unmodifiable(_days),
        hours: _hours,
        minutes: _minutes,
      ),
    );
  }

  void _openTimePicker() {
    setState(() => _mode = BottomSheetMode.timePicker);
  }

  @override
  Widget build(BuildContext context) {
    final headerText = _mode == BottomSheetMode.dayPicker ? '요일 선택' : '시간 선택';

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          height: _sheetHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_sheetRadius),
              topRight: Radius.circular(_sheetRadius),
            ),
          ),
          child: Stack(
            children: [
              // Drag handle.
              Positioned(
                top: _handleTop,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: _handleWidth,
                    height: _handleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(_handleHeight / 2),
                    ),
                  ),
                ),
              ),

              // Header.
              Positioned(
                top: _headerTop,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(headerText, style: AppTypography.headlineBold),
                ),
              ),

              // Body — mode-dependent.
              Positioned.fill(
                top: _headerTop + 40,
                bottom: _ctaBottom + 54 + 16,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _mode == BottomSheetMode.dayPicker
                      ? _buildDayPickerBody()
                      : _buildTimePickerBody(),
                ),
              ),

              // CTA.
              Positioned(
                left: _ctaHorizontalPadding,
                right: _ctaHorizontalPadding,
                bottom: _ctaBottom,
                child: BridgeButton(
                  label: '확인',
                  variant: BridgeButtonVariant.primary,
                  size: BridgeButtonSize.large,
                  fullWidth: true,
                  onPressed: _canConfirm ? _onConfirm : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayPickerBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BridgeWeekdaySelector(
            selected: _days,
            onChanged: (next) => setState(() => _days = next),
          ),
        ),
        const SizedBox(height: 24),
        _TimeRow(hours: _hours, minutes: _minutes, onTap: _openTimePicker),
      ],
    );
  }

  Widget _buildTimePickerBody() {
    final hourValues = List<String>.generate(
      widget.maxHours + 1,
      (i) => i.toString().padLeft(2, '0'),
    );
    final minuteStrings = _minuteValues
        .map((m) => m.toString().padLeft(2, '0'))
        .toList(growable: false);

    final hourIndex = _hours.clamp(0, hourValues.length - 1);
    final minuteIndex = _minuteValues
        .indexOf(_minutes)
        .clamp(0, _minuteValues.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Two wheel pickers, side-by-side.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BridgeWheelPicker(
                  values: hourValues,
                  selectedIndex: hourIndex,
                  onChanged: (i) => setState(() => _hours = i),
                ),
                BridgeWheelPicker(
                  values: minuteStrings,
                  selectedIndex: minuteIndex,
                  onChanged: (i) => setState(() => _minutes = _minuteValues[i]),
                ),
              ],
            ),

            // Selection band overlay — fixed width, horizontal primary
            // borders only (top + bottom).
            IgnorePointer(
              child: SizedBox(
                width: _selectionBandWidth,
                height: _selectionBandHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 2, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 2, color: AppColors.primary),
                    ),
                    // Unit labels inside the band.
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '시간',
                                  style: AppTypography.heading2Medium.copyWith(
                                    color: AppColors.gray800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '분',
                                  style: AppTypography.heading2Medium.copyWith(
                                    color: AppColors.gray800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Outlined "tap to open time picker" row used in `dayPicker` mode.
///
/// Numbers render in [AppColors.gray300] when both are zero (placeholder
/// state) and switch to [AppColors.primary] once the user has set a value.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.hours,
    required this.minutes,
    required this.onTap,
  });

  final int hours;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = hours == 0 && minutes == 0;
    final Color numberColor = isPlaceholder
        ? AppColors.gray300
        : AppColors.primary;

    final TextStyle numberStyle = AppTypography.headlineBold.copyWith(
      color: numberColor,
    );
    final TextStyle unitStyle = AppTypography.headlineRegular.copyWith(
      color: AppColors.black,
    );

    return Semantics(
      button: true,
      label: '시간 설정',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: 0.8,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(hours.toString().padLeft(2, '0'), style: numberStyle),
                  const SizedBox(width: 6),
                  Text('시간', style: unitStyle),
                  const SizedBox(width: 12),
                  Text(minutes.toString().padLeft(2, '0'), style: numberStyle),
                  const SizedBox(width: 6),
                  Text('분', style: unitStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
