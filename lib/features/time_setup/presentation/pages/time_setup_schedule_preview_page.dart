import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/bridge_time_grid.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../data/models/time_schedule.dart';

/// Read-only schedule preview opened from the daily time distribution step.
///
/// The screen receives the in-progress [TimeSchedule] directly from the wizard
/// so it can show the cached schedule without reloading or mutating backend
/// schedule state.
class TimeSetupSchedulePreviewPage extends StatelessWidget {
  const TimeSetupSchedulePreviewPage({super.key, required this.schedule});

  final TimeSchedule schedule;

  static const int _visibleHourBase = 7;
  static const List<String> _visibleHourLabels = <String>[
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
    final Set<({int weekday, int hour})> selectedCells = schedule.allowedHours
        .map(
          (HourCell cell) =>
              (weekday: cell.weekday, hour: cell.hour - _visibleHourBase),
        )
        .where(
          (cell) => cell.hour >= 0 && cell.hour < _visibleHourLabels.length,
        )
        .toSet();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            BridgeAppBar(
              title: '스케줄 보기',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.pageHorizontal,
                  16,
                  AppTokens.pageHorizontal,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          '나의 스케줄',
                          style: AppTypography.heading2Bold.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(width: AppTokens.smallGap),
                        SvgPicture.asset(
                          'assets/icons/settings.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gray400,
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (_) => const Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BridgeTimeGrid(
                      selected: selectedCells,
                      hours: _visibleHourLabels,
                      startHourOfDay: _visibleHourBase,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
