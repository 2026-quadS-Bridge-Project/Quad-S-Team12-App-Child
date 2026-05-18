import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/buttons/bridge_pill_icon_button.dart';
import '../../../../core/widgets/feedback/bridge_empty_state.dart';
import '../../../../core/widgets/feedback/bridge_onboarding_tooltip.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_day_row.dart';
import '../../../../core/widgets/layout/bridge_total_time_card.dart';
import '../../data/mock/time_confirm_mock.dart';
import '../../data/models/time_confirm_data.dart';
import '../../state/time_confirm_controller.dart';

/// Read-only review of the parent-set time schedule.
///
/// Three visual variants are driven by [TimeConfirmController.data]:
///   * empty   — no schedule set by parent → centered [BridgeEmptyState]
///   * filled  — weekly total + per-day allocation rows
///   * onboarding — filled + onboarding tooltip anchored to 수정하기 pill
///
/// The variant is initialised once in [initState] from the optional
/// `?variant=empty|filled|onboarding` query param on `/child-home/time-setup/confirm`.
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
      case 'onboarding':
        return TimeConfirmMock.filledWithOnboarding;
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

  void _showRequestSnack() {
    _controller.requestModification();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('부모님께 수정 요청을 보냈어요.')));
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
              return _EmptyVariant(onClose: () => context.pop());
            }
            return _FilledVariant(
              data: data,
              onConfirm: () => context.pop(),
              onRequestEdit: _showRequestSnack,
              onDismissOnboarding: _controller.dismissOnboarding,
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
            child: BridgeEmptyState(
              message: '이번달 시간규칙이\n설정되지 않았습니다.',
              icon: Icons.event_busy_outlined,
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
    required this.onDismissOnboarding,
  });

  final TimeConfirmData data;
  final VoidCallback onConfirm;
  final VoidCallback onRequestEdit;
  final VoidCallback onDismissOnboarding;

  @override
  Widget build(BuildContext context) {
    // schedule is non-null here — `isEmpty` short-circuits in the parent.
    final schedule = data.schedule!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16),
          BridgeTotalTimeCard(
            title: '2월 1주 사용 시간',
            hours: schedule.weeklyTotalHours,
            minutes: schedule.weeklyTotalMinutes,
          ),
          const SizedBox(height: 16),
          Container(height: 7, color: AppColors.gray150),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                '일간 사용 계획',
                style: AppTypography.heading2Bold.copyWith(
                  color: AppColors.gray800,
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  BridgePillIconButton(
                    label: '수정하기',
                    icon: Icons.edit_outlined,
                    variant: BridgePillVariant.ghost,
                    onPressed: onRequestEdit,
                  ),
                  if (data.showOnboarding)
                    Positioned(
                      // Body sits below the pill; arrow (topCenter) points up
                      // at the pill. 36px ≈ pill bottom + spec ~8px gap, so
                      // the notch tip lands near the pill's bottom edge per
                      // Figma 662-11249 (y ≈ 323).
                      top: 36,
                      right: 0,
                      child: BridgeOnboardingTooltip(
                        title: '시간 계획 수정은 어떻게 하나요?',
                        bullets: const <TextSpan>[
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: '시간 설정은 '),
                              TextSpan(
                                text: '주 1회',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: ' 진행돼요. 이번주 시간계획이 미흡했다면 다음주에 반영해서 수정해봐요!',
                              ),
                            ],
                          ),
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: '꼭 필요한 경우에 부모님의 '),
                              TextSpan(
                                text: '시간 설정 탭',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: '에서 허락을 받아, 수정할 수 있어요.'),
                            ],
                          ),
                        ],
                        arrowAlignment: TooltipArrowAlignment.topCenter,
                        onDismiss: onDismissOnboarding,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: schedule.dayAllocations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: BridgeButton(label: '확인', onPressed: onConfirm),
          ),
        ],
      ),
    );
  }
}
