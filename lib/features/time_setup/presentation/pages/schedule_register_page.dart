import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/icons/bridge_stepper_pills.dart';
import '../../../../core/widgets/inputs/bridge_time_grid.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/layout/bridge_step_header.dart';
import '../../data/models/time_schedule.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';

/// Step 1 of 3 in the initial time-setup wizard.
///
/// Renders the 7×17 hour-slot grid for selecting hours the phone is
/// available. Selected hours are stored on [TimeSetupController.schedule]
/// as [HourCell] entries using the literal hour-of-day (7–23). The grid
/// itself addresses cells with row indices 0..16, so the page maps between
/// the grid coordinate and the model hour by adding/subtracting the
/// [_visibleHourBase] offset.
///
/// Spec: docs/figma-specs/08a-time-v1-entry-weekly.md frames `695:8924`
/// (empty) and `695:9115` (filled).
class ScheduleRegisterPage extends StatelessWidget {
  const ScheduleRegisterPage({super.key});

  /// First hour-of-day represented by row 0 of [BridgeTimeGrid]. Cells
  /// stored on the controller use the literal hour (e.g. 7 for the first
  /// row), while the grid reports `hour` as a 0-based row index. This
  /// constant is the single source of truth for the mapping.
  static const int _visibleHourBase = 7;

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BridgeAppBar(
        title: '시간 설정',
        // Per Figma 08a 695:8924 Interactions: back chevron pops to entry
        // (`695:8850`). In v1 the controller never reaches `intro` (the
        // root page maps the intro step to this same ScheduleRegisterPage
        // as a defensive fallback), so there is no in-wizard predecessor.
        // Pop the route to exit the wizard back to the parent (child home).
        // The root-level `PopScope` mirrors this on Android system back
        // from the first real step.
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => _buildBody(context, controller),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TimeSetupController controller) {
    final selectedCells = controller.schedule.allowedHours
        .map(
          (cell) => (weekday: cell.weekday, hour: cell.hour - _visibleHourBase),
        )
        .toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: BridgeStepperPills(
              currentStep: controller.stepIndex,
              totalSteps: 3,
            ),
          ),
          const SizedBox(height: 24),
          // Title + description verbatim per Figma 08a 695:8924 nodes
          // 695:8932 (title) and 695:8935 (2-line description).
          const BridgeStepHeader(
            step: 1,
            title: '스케줄 등록',
            description: '학교, 학원처럼 휴대폰을 거의 못 쓰는 시간을 등록해서\n사용가능한 시간을 편하게 확인해요',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: BridgeTimeGrid(
                selected: selectedCells,
                onToggle: (weekday, hourIndex) => controller.toggleHour(
                  weekday,
                  hourIndex + _visibleHourBase,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: BridgeButton(
              label: '다음',
              onPressed: controller.canProceedToStep2
                  ? () => controller.goToStep(TimeSetupStep.weeklyTotal)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
