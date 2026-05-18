import 'package:flutter/material.dart';

import '../../data/mock/time_schedule_mock.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';
import 'daily_time_setup_page.dart';
import 'schedule_register_page.dart';
import 'time_setup_complete_page.dart';
import 'time_setup_intro_page.dart';
import 'time_setup_review_page.dart';
import 'weekly_time_setup_page.dart';

/// Wizard shell for the v2 (next-week edit) flow.
///
/// Mirrors [TimeSetupRootPage] but initializes the controller via
/// [TimeSetupController.v2NextWeek], prefilling the grid + weekly total +
/// daily allocations with the previous week's schedule. Sub-pages read the
/// controller via [TimeSetupScope.of] and are already mode-aware through
/// `controller.showPastWeekDim`.
///
/// TODO(time-setup-v2): once the v1 sub-pages are confirmed to render the
/// past-week dim treatment via `controller.showPastWeekDim`, remove this note.
/// Until then the v2 entry still delivers the prefilled edit flow correctly.
class TimeSetupV2RootPage extends StatefulWidget {
  const TimeSetupV2RootPage({super.key});

  @override
  State<TimeSetupV2RootPage> createState() => _TimeSetupV2RootPageState();
}

class _TimeSetupV2RootPageState extends State<TimeSetupV2RootPage> {
  late final TimeSetupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimeSetupController.v2NextWeek(
      previousWeek: TimeScheduleMock.sampleFilled,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TimeSetupScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return switch (_controller.step) {
            TimeSetupStep.intro => const TimeSetupIntroPage(),
            TimeSetupStep.scheduleRegister => const ScheduleRegisterPage(),
            TimeSetupStep.weeklyTotal => const WeeklyTimeSetupPage(),
            TimeSetupStep.dailyAllocation => const DailyTimeSetupPage(),
            TimeSetupStep.review => const TimeSetupReviewPage(),
            TimeSetupStep.complete => const TimeSetupCompletePage(),
          };
        },
      ),
    );
  }
}
