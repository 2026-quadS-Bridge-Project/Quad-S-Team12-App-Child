import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/calendar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_day_row.dart';
import '../../../../core/widgets/layout/bridge_total_time_card.dart';
import '../../../../core/widgets/mixins/async_error_listener.dart';
import '../../../time_setup/data/models/time_schedule.dart';
import '../../data/mock/time_confirm_mock.dart';
import '../../data/models/time_confirm_data.dart';
import '../../state/time_confirm_controller.dart';

/// Read-only review of the parent-set time schedule.
///
/// Two visual variants are driven by [TimeConfirmController.data]:
///   * empty   — no schedule set by parent → centered text-only empty state
///   * filled  — weekly total + per-day allocation rows
///
/// The optional variant is initialised once in [initState] from
/// [TimeConfirmPage.variant]. When no variant is provided, the page loads the
/// active schedule from the repository.
///
/// Spec: docs/figma-specs/10-time-confirm.md
class TimeConfirmPage extends StatefulWidget {
  const TimeConfirmPage({super.key, this.variant});

  /// Optional explicit override of the initial variant. When null, the page
  /// fetches the current schedule from the repository. Useful for tests.
  final String? variant;

  @override
  State<TimeConfirmPage> createState() => _TimeConfirmPageState();
}

class _TimeConfirmPageState extends State<TimeConfirmPage>
    with AsyncErrorListenerMixin<TimeConfirmPage> {
  late final TimeConfirmController _controller;

  /// Guards the 수정하기 pill against re-entry / rapid double-tap while the
  /// repository call is in flight. The controller does not toggle `isLoading`
  /// for [TimeConfirmController.requestModification], so we track it locally.
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    final TimeConfirmData? initial = _resolveInitialData();
    _controller = TimeConfirmController(initial: initial);
    bindAsyncErrorListener(_controller);
    if (initial == null) {
      unawaited(_controller.load());
    }
  }

  TimeConfirmData? _resolveInitialData() {
    switch (widget.variant) {
      case 'empty':
        return TimeConfirmMock.empty;
      case 'filled':
        return TimeConfirmMock.filled;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showRequestSnack() async {
    // Guard against re-entry / rapid double-tap. The controller does not
    // expose an in-flight flag for [requestModification], so block locally.
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      await _controller.requestModification();
      if (!mounted) return;
      final String? error = _controller.errorMessage;
      final String copy = error ?? '부모님께 수정 요청을 보냈어요.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(copy)));
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _handleConfirm() async {
    await _controller.acknowledge();
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const BridgeAppBar(title: '시간설정'),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final TimeConfirmData data = _controller.data;
                  if (_controller.isLoading && data.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (data.isEmpty) {
                    return _EmptyVariant(onClose: _handleConfirm);
                  }
                  return _FilledVariant(
                    data: data,
                    onConfirm: _handleConfirm,
                    onRequestEdit: _isRequesting ? null : _showRequestSnack,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVariant extends StatelessWidget {
  const _EmptyVariant({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          const Expanded(
            child: Center(
              child: Text(
                '이번달 시간규칙이 설정되지 않았습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.445,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: BridgeButton(label: '확인', onPressed: onClose),
          ),
        ],
      ),
    );
  }
}

class _FilledVariant extends StatelessWidget {
  const _FilledVariant({
    required this.data,
    required this.onConfirm,
    required this.onRequestEdit,
  });

  final TimeConfirmData data;
  final VoidCallback onConfirm;
  final VoidCallback? onRequestEdit;

  @override
  Widget build(BuildContext context) {
    // schedule is non-null here — `isEmpty` short-circuits in the parent.
    final schedule = data.schedule!;
    final CalendarService calendar = createCalendarService();
    final int weekIndex = calendar.currentWeekIndex();
    final int scheduleWeekIndex = weekIndex - 1;
    final int totalMinutes = _displayTotalMinutes(schedule, scheduleWeekIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BridgeTotalTimeCard(
            variant: BridgeTotalTimeCardVariant.compact,
            title: '${calendar.currentMonthLabel()} $weekIndex주 사용 시간',
            hours: totalMinutes ~/ 60,
            minutes: totalMinutes % 60,
          ),
        ),
        const SizedBox(height: 28),
        Container(height: 7, color: AppColors.gray150),
        const SizedBox(height: 38),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                '일간 사용 계획',
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.gray800,
                ),
              ),
              _RequestEditPill(onPressed: onRequestEdit),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: schedule.dayAllocations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final alloc = schedule.dayAllocations[index];
                return BridgeDayRow(
                  daysLabel: alloc.daysLabel,
                  hours: alloc.hours,
                  minutes: alloc.minutes,
                  onEdit: null,
                  showPencil: false,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: BridgeButton(label: '확인', onPressed: onConfirm),
        ),
      ],
    );
  }
}

int _displayTotalMinutes(TimeSchedule schedule, int weekIndex) {
  final int exact = schedule.weeklyTotalMinutesAt(weekIndex);
  if (exact > 0 || schedule.weeklyTotals.length != 1) {
    return exact;
  }
  return schedule.weeklyTotals.first.totalMinutes;
}

class _RequestEditPill extends StatelessWidget {
  const _RequestEditPill({required this.onPressed});

  /// Nullable so the parent can disable the pill while a request is in flight.
  final VoidCallback? onPressed;

  static const double _height = 31;
  static const double _radius = 7;
  static const double _iconSize = 14;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(_radius);
    final TextStyle textStyle = AppTypography.labelMedium.copyWith(
      color: AppColors.gray300,
    );

    return Semantics(
      button: true,
      label: '수정하기',
      hint: '부모님께 수정 요청을 보냅니다.',
      child: Material(
        color: AppColors.gray150,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          splashColor: AppColors.gray300.withValues(alpha: 0.12),
          highlightColor: AppColors.gray300.withValues(alpha: 0.06),
          child: Container(
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.edit_outlined,
                  size: _iconSize,
                  color: AppColors.gray300,
                ),
                const SizedBox(width: 4),
                Text('수정하기', style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
