import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_day_row.dart';
import '../../../../core/widgets/layout/bridge_total_time_card.dart';
import '../../data/mock/time_confirm_mock.dart';
import '../../data/models/time_confirm_data.dart';
import '../../state/time_confirm_controller.dart';

/// Read-only review of the parent-set time schedule.
///
/// Two visual variants are driven by [TimeConfirmController.data]:
///   * empty   — no schedule set by parent → centered text-only empty state
///   * filled  — weekly total + per-day allocation rows
///
/// The variant is initialised once in [initState] from the optional
/// `?variant=empty|filled` query param on `/child-home/time-setup/confirm`.
/// Default is `filled`.
///
/// Spec: docs/figma-specs/10-time-confirm.md
class TimeConfirmPage extends StatefulWidget {
  const TimeConfirmPage({super.key, this.variant});

  /// Optional explicit override of the initial variant. When null, the page
  /// reads `?variant=...` from the current route. Useful for tests.
  final String? variant;

  @override
  State<TimeConfirmPage> createState() => _TimeConfirmPageState();
}

class _TimeConfirmPageState extends State<TimeConfirmPage> {
  late final TimeConfirmController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimeConfirmController(initial: _resolveInitialData());
  }

  TimeConfirmData _resolveInitialData() {
    final String? raw =
        widget.variant ??
        GoRouterState.of(context).uri.queryParameters['variant'];
    switch (raw) {
      case 'empty':
        return TimeConfirmMock.empty;
      case 'filled':
      default:
        return TimeConfirmMock.filled;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showRequestSnack() async {
    // Fire-and-display: mock repo resolves immediately with Success, so the
    // SnackBar copy stays unchanged. When the real backend lands, update the
    // copy to reflect actual request status (e.g. "수정 요청을 보냈어요.").
    await _controller.requestModification();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('수정 요청 기능은 곧 연결될 예정이에요.')));
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
      appBar: const BridgeAppBar(title: '시간설정'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final TimeConfirmData data = _controller.data;
            if (data.isEmpty) {
              return _EmptyVariant(onClose: _handleConfirm);
            }
            return _FilledVariant(
              data: data,
              onConfirm: _handleConfirm,
              onRequestEdit: _showRequestSnack,
            );
          },
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
  final VoidCallback onRequestEdit;

  @override
  Widget build(BuildContext context) {
    // schedule is non-null here — `isEmpty` short-circuits in the parent.
    final schedule = data.schedule!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BridgeTotalTimeCard(
            variant: BridgeTotalTimeCardVariant.compact,
            title: '2월 1주 사용 시간',
            hours: schedule.weeklyHoursAt(0),
            minutes: schedule.weeklyMinutesAt(0),
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

class _RequestEditPill extends StatelessWidget {
  const _RequestEditPill({required this.onPressed});

  final VoidCallback onPressed;

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
