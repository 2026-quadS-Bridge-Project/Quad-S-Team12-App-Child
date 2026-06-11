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

/// Wizard shell that owns the [TimeSetupController] and renders the current
/// step. Sub-pages read the controller via [TimeSetupScope.of].
class TimeSetupRootPage extends StatefulWidget {
  const TimeSetupRootPage({super.key, this.initial, this.repository});

  final TimeSchedule? initial;
  final TimeSetupRepository? repository;

  @override
  State<TimeSetupRootPage> createState() => _TimeSetupRootPageState();
}

class _TimeSetupRootPageState extends State<TimeSetupRootPage> {
  late final TimeSetupRepository _repository;
  TimeSetupController? _controller;
  String? _blockedMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? createTimeSetupRepository();
    _loadInitialSchedule();
  }

  Future<void> _loadInitialSchedule() async {
    final TimeSchedule? initial = widget.initial ?? await _fetchInitial();
    if (!mounted) {
      return;
    }
    setState(() {
      if (_blockedMessage == null) {
        _controller = TimeSetupController(
          initial: initial,
          repository: _repository,
        );
      }
    });
  }

  Future<TimeSchedule?> _fetchInitial() async {
    final Result<TimeSchedule?> result = await _repository
        .fetchCurrentSchedule();
    return switch (result) {
      Success<TimeSchedule?>(:final data) => data,
      Failure<TimeSchedule?>(:final message) => _setBlocked(message),
    };
  }

  TimeSchedule? _setBlocked(String message) {
    _blockedMessage = message;
    return null;
  }

  @override
  void dispose() {
    _controller?.dispose();
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
            // Intercept Android system back so back gesture rewinds the
            // wizard one step instead of popping the entire route. When
            // [_previousStep] returns null (entry / completion) we let
            // the route pop normally.
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
