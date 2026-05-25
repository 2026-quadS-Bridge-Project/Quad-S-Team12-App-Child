import 'package:flutter/material.dart';

import '../../data/models/time_schedule.dart';
import '../../state/time_setup_controller.dart';
import '../../state/time_setup_scope.dart';
import 'daily_time_setup_page.dart';
import 'schedule_register_page.dart';
import 'time_setup_complete_page.dart';
import 'time_setup_intro_page.dart';
import 'time_setup_review_page.dart';
import 'weekly_time_setup_page.dart';

/// Wizard shell that owns the [TimeSetupController] and renders the current
/// step. Sub-pages read the controller via [TimeSetupScope.of].
class TimeSetupRootPage extends StatefulWidget {
  const TimeSetupRootPage({super.key, this.initial});

  final TimeSchedule? initial;

  @override
  State<TimeSetupRootPage> createState() => _TimeSetupRootPageState();
}

class _TimeSetupRootPageState extends State<TimeSetupRootPage> {
  late final TimeSetupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimeSetupController(initial: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Maps the current wizard step to the previous step for the in-wizard
  /// back gesture. Returns null when the user is already at the entry
  /// explainer (`intro`) or has finished (`complete`) — in those cases the
  /// system back gesture is allowed to pop the wizard route.
  TimeSetupStep? _previousStep(TimeSetupStep current) {
    return switch (current) {
      TimeSetupStep.intro => null,
      TimeSetupStep.scheduleRegister => TimeSetupStep.intro,
      TimeSetupStep.weeklyTotal => TimeSetupStep.scheduleRegister,
      TimeSetupStep.dailyAllocation => TimeSetupStep.weeklyTotal,
      TimeSetupStep.review => TimeSetupStep.dailyAllocation,
      TimeSetupStep.complete => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return TimeSetupScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final TimeSetupStep? previous = _previousStep(_controller.step);
          return PopScope(
            // Intercept Android system back so back gesture rewinds the
            // wizard one step instead of popping the entire route. When
            // [_previousStep] returns null (entry / completion) we let
            // the route pop normally.
            canPop: previous == null,
            onPopInvokedWithResult: (bool didPop, Object? _) {
              if (didPop) return;
              if (previous != null) {
                _controller.goToStep(previous);
              }
            },
            child: switch (_controller.step) {
              TimeSetupStep.intro => const TimeSetupIntroPage(),
              TimeSetupStep.scheduleRegister => const ScheduleRegisterPage(),
              TimeSetupStep.weeklyTotal => const WeeklyTimeSetupPage(),
              TimeSetupStep.dailyAllocation => const DailyTimeSetupPage(),
              TimeSetupStep.review => const TimeSetupReviewPage(),
              TimeSetupStep.complete => const TimeSetupCompletePage(),
            },
          );
        },
      ),
    );
  }
}
