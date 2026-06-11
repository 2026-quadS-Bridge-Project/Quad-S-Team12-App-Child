import 'package:flutter/material.dart';

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

  static const String _v1Description =
      '학교, 학원처럼 휴대폰을 거의 못 쓰는 시간을 등록해서\n사용가능한 시간을 편하게 확인해요';
  static const String _v2Description =
      '이전에 등록한 스케줄과 동일하다면 다음을 클릭하고,\n스케줄에 변동이 생겼다면 수정해요!';

  /// First hour-of-day represented by row 0 of [BridgeTimeGrid]. Cells
  /// stored on the controller use the literal hour (e.g. 7 for the first
  /// row), while the grid reports `hour` as a 0-based row index. This
  /// constant is the single source of truth for the mapping.
  static const int _visibleHourBase = 7;

  /// 12-hour display labels for model hours 7..23. Row 16 is 23:00, shown
  /// as `11` to keep the controller's 17-row mapping intact.
  static const List<String> _visibleHourLabels = [
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = TimeSetupScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            BridgeAppBar(
              title: '',
              // Per Figma 08a 695:8924 Interactions: back chevron pops to the
              // entry explainer (`695:8850`). The root-level `PopScope` mirrors
              // this on Android system back from step 1.
              onBack: () => controller.goToStep(TimeSetupStep.intro),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) => _buildBody(context, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TimeSetupController controller) {
    final String description = switch (controller.mode) {
      TimeSetupMode.v1Initial => _v1Description,
      TimeSetupMode.v2NextWeek => _v2Description,
    };

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
          // Title and mode-aware description per Figma 08a 695:8924 and
          // 09-time-v2.md §v2-2.
          BridgeStepHeader(step: 1, title: '스케줄 등록', description: description),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: BridgeTimeGrid(
                selected: selectedCells,
                hours: _visibleHourLabels,
                startHourOfDay: _visibleHourBase,
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
