import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../buttons/bridge_button.dart';
import 'bridge_wheel_picker.dart';

/// Result returned by [BridgeTimeBottomSheet] when the user confirms.
@immutable
class TimeOfDayPick {
  const TimeOfDayPick({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayPick &&
          runtimeType == other.runtimeType &&
          hours == other.hours &&
          minutes == other.minutes;

  @override
  int get hashCode => Object.hash(hours, minutes);

  @override
  String toString() => 'TimeOfDayPick(hours: $hours, minutes: $minutes)';
}

/// Time-only bottom sheet used by the 주별 / 일별 시간 분배 flows.
///
/// Figma source: `docs/figma-specs/08a-time-v1-entry-weekly.md` §13485
/// (`scr/child-초기 시간설정-주별시간분배-바텀시트`).
///
/// Anatomy (top → bottom):
///   1. Drag handle — 4 × 40 `AppColors.gray200` pill, 8px from sheet top.
///   2. Header `시간 선택` — `AppTypography.headlineBold`, centered, 27px
///      from sheet top.
///   3. Two [BridgeWheelPicker] columns (hour, minute) side-by-side, centered.
///   4. Selection band overlay — 324 × 50, top & bottom 2px primary borders,
///      no fill, opacity 0.8. Anchors right-aligned `시간` / `분` labels next
///      to each wheel's selected value.
///   5. Primary CTA `확인` — 63px from sheet bottom, 24px horizontal padding.
///
/// Scrim and rounded corners are provided by the parent [showModalBottomSheet]
/// (or `ThemeData.bottomSheetTheme`); this widget renders only the sheet body.
class BridgeTimeBottomSheet extends StatefulWidget {
  const BridgeTimeBottomSheet({
    super.key,
    required this.initialHours,
    required this.initialMinutes,
    this.maxHours = 23,
    this.minuteStep = 5,
    this.title = '시간 선택',
    this.confirmLabel = '확인',
  });

  /// Hour value the wheel snaps to on first open.
  final int initialHours;

  /// Minute value the wheel snaps to on first open. Rounded down to the
  /// nearest multiple of [minuteStep] if not aligned.
  final int initialMinutes;

  /// Inclusive upper bound for the hour wheel. Defaults to 23 (single day).
  /// The weekly distribution flow may pass larger values (e.g. weekly totals).
  final int maxHours;

  /// Step between minute values. Defaults to 5 (Figma spec).
  final int minuteStep;

  /// Header text. Defaults to `시간 선택`.
  final String title;

  /// CTA label. Defaults to `확인`.
  final String confirmLabel;

  /// Opens the bottom sheet and resolves with a [TimeOfDayPick] on confirm
  /// or `null` on dismiss (scrim tap, drag down, back button).
  static Future<TimeOfDayPick?> show(
    BuildContext context, {
    required int initialHours,
    required int initialMinutes,
    int maxHours = 23,
    int minuteStep = 5,
  }) {
    return showModalBottomSheet<TimeOfDayPick>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BridgeTimeBottomSheet(
        initialHours: initialHours,
        initialMinutes: initialMinutes,
        maxHours: maxHours,
        minuteStep: minuteStep,
      ),
    );
  }

  @override
  State<BridgeTimeBottomSheet> createState() => _BridgeTimeBottomSheetState();
}

class _BridgeTimeBottomSheetState extends State<BridgeTimeBottomSheet> {
  // Wheel metrics — must stay in sync with [BridgeWheelPicker] defaults so the
  // selection band aligns exactly over the centered row.
  static const double _wheelItemWidth = 56;
  static const double _wheelItemHeight = 50;
  static const int _visibleItems = 5;
  static const double _wheelTotalHeight = _wheelItemHeight * _visibleItems;

  // Sheet layout constants (from Figma §13485).
  static const double _handleTop = 8;
  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _headerTop = 27;
  static const double _wheelsTop = 85;
  static const double _bandWidth = 324;
  static const double _bandHeight = 50;
  static const double _ctaBottom = 63;
  static const double _ctaHorizontalPadding = 24;
  static const double _wheelGap = 80; // gap between hour & minute columns

  late List<String> _hourValues;
  late List<String> _minuteValues;
  late int _hourIndex;
  late int _minuteIndex;

  @override
  void initState() {
    super.initState();
    _buildValues();
    _hourIndex = widget.initialHours.clamp(0, _hourValues.length - 1);
    final int snappedMinute =
        (widget.initialMinutes ~/ widget.minuteStep) * widget.minuteStep;
    final int minuteIdx = _minuteValues.indexOf(_format(snappedMinute));
    _minuteIndex = minuteIdx >= 0 ? minuteIdx : 0;
  }

  @override
  void didUpdateWidget(covariant BridgeTimeBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxHours != widget.maxHours ||
        oldWidget.minuteStep != widget.minuteStep) {
      setState(_buildValues);
    }
  }

  void _buildValues() {
    _hourValues = List<String>.generate(widget.maxHours + 1, (i) => _format(i));
    final int step = widget.minuteStep <= 0 ? 5 : widget.minuteStep;
    final int count = (60 / step).floor();
    _minuteValues = List<String>.generate(count, (i) => _format(i * step));
  }

  String _format(int value) => value.toString().padLeft(2, '0');

  int get _hours => _hourIndex;
  int get _minutes {
    final int step = widget.minuteStep <= 0 ? 5 : widget.minuteStep;
    return _minuteIndex * step;
  }

  void _handleConfirm() {
    Navigator.of(context).pop(TimeOfDayPick(hours: _hours, minutes: _minutes));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTokens.bottomSheetTopRadius),
      ),
      child: SizedBox(
        height: AppTokens.bottomSheetHeight,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            // (1) Drag handle.
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

            // (2) Header title.
            Positioned(
              top: _headerTop,
              left: 0,
              right: 0,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineBold,
              ),
            ),

            // (3) Wheel row — hour + minute side-by-side, centered.
            Positioned(
              top: _wheelsTop,
              left: 0,
              right: 0,
              height: _wheelTotalHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  BridgeWheelPicker(
                    values: _hourValues,
                    selectedIndex: _hourIndex,
                    itemWidth: _wheelItemWidth,
                    itemHeight: _wheelItemHeight,
                    visibleItems: _visibleItems,
                    onChanged: (int i) => setState(() => _hourIndex = i),
                  ),
                  const SizedBox(width: _wheelGap),
                  BridgeWheelPicker(
                    values: _minuteValues,
                    selectedIndex: _minuteIndex,
                    itemWidth: _wheelItemWidth,
                    itemHeight: _wheelItemHeight,
                    visibleItems: _visibleItems,
                    onChanged: (int i) => setState(() => _minuteIndex = i),
                  ),
                ],
              ),
            ),

            // (4) Selection band overlay — centered over the wheel row.
            Positioned(
              top: _wheelsTop + (_wheelTotalHeight - _bandHeight) / 2,
              left: 0,
              right: 0,
              height: _bandHeight,
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                      width: _bandWidth,
                      height: _bandHeight,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.primary, width: 2),
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      child: _BandLabels(
                        wheelItemWidth: _wheelItemWidth,
                        wheelGap: _wheelGap,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // (5) Confirm CTA — bottom-anchored.
            Positioned(
              left: _ctaHorizontalPadding,
              right: _ctaHorizontalPadding,
              bottom: _ctaBottom,
              child: BridgeButton(
                label: widget.confirmLabel,
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: _handleConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the `시간` / `분` unit labels inside the selection band, anchored
/// to the right of each wheel column.
///
/// The band itself is centered in the sheet; inside the band we lay out the
/// two wheel "slots" with the same gap as the wheel row above, then place the
/// unit text immediately to the right of each slot.
class _BandLabels extends StatelessWidget {
  const _BandLabels({required this.wheelItemWidth, required this.wheelGap});

  final double wheelItemWidth;
  final double wheelGap;

  static const double _labelGap = 4; // space between wheel value and unit text

  @override
  Widget build(BuildContext context) {
    final TextStyle unitStyle = AppTypography.heading2Medium.copyWith(
      color: AppColors.gray800,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(width: wheelItemWidth),
        const SizedBox(width: _labelGap),
        Text('시간', style: unitStyle),
        SizedBox(width: wheelGap - _labelGap),
        SizedBox(width: wheelItemWidth),
        const SizedBox(width: _labelGap),
        Text('분', style: unitStyle),
      ],
    );
  }
}
