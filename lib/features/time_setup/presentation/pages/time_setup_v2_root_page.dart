import 'package:flutter/material.dart';

import '../../../../core/models/result.dart';
import '../../data/models/time_schedule.dart';
import '../../data/repositories/time_setup_repository.dart';
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
  const TimeSetupV2RootPage({super.key, this.repository});

  final TimeSetupRepository? repository;

  @override
  State<TimeSetupV2RootPage> createState() => _TimeSetupV2RootPageState();
}

class _TimeSetupV2RootPageState extends State<TimeSetupV2RootPage> {
  late final TimeSetupRepository _repository;
  TimeSetupController? _controller;
  String? _blockedMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? createTimeSetupRepository();
    _loadPreviousWeekSchedule();
  }

  Future<void> _loadPreviousWeekSchedule() async {
    final Result<TimeSchedule> result = await _repository
        .fetchPreviousWeekSchedule();
    if (!mounted) {
      return;
    }
    setState(() {
      switch (result) {
        case Success<TimeSchedule>(:final data):
          _controller = TimeSetupController.v2NextWeek(
            previousWeek: data,
            repository: _repository,
          );
        case Failure<TimeSchedule>(:final message):
          _blockedMessage = message;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

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
    final TimeSetupController? controller = _controller;
    final String? blockedMessage = _blockedMessage;
    if (blockedMessage != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    blockedMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return TimeSetupScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final TimeSetupStep? previous = _previousStep(controller.step);
          return PopScope(
            canPop: previous == null,
            onPopInvokedWithResult: (bool didPop, Object? _) {
              if (didPop) return;
              if (previous != null) {
                controller.goToStep(previous);
              }
            },
            child: switch (controller.step) {
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
