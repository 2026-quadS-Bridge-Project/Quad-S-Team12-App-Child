import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/camera_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/inputs/bridge_photo_tile.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../core/widgets/mixins/async_error_listener.dart';
import '../../data/models/mission.dart';
import '../../state/mission_controller.dart';
import '../../state/mission_scope.dart';

enum _MissionPhotoSource { gallery, camera }

Future<void> _pickAndAttachMissionPhoto(
  BuildContext context,
  MissionController controller,
) async {
  final String? path = await _pickMissionPhoto(context);
  if (path != null) {
    await controller.addCapturedPhoto(path);
  }
}

Future<String?> _pickMissionPhoto(BuildContext context) async {
  final _MissionPhotoSource? source =
      await showModalBottomSheet<_MissionPhotoSource>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('앨범에서 선택', style: AppTypography.bodyMedium),
                  onTap: () =>
                      Navigator.of(context).pop(_MissionPhotoSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text('사진 촬영', style: AppTypography.bodyMedium),
                  onTap: () =>
                      Navigator.of(context).pop(_MissionPhotoSource.camera),
                ),
              ],
            ),
          );
        },
      );
  if (source == null) {
    return null;
  }
  return switch (source) {
    _MissionPhotoSource.gallery => CameraService.pickPhotoFromGallery(),
    _MissionPhotoSource.camera => CameraService.capturePhoto(),
  };
}

/// Root page for the mission detail / perform flow.
///
/// Owns the [MissionController] and mounts a [MissionScope] so descendant
/// sub-views can react to step changes. The body switches between four
/// sub-views based on [MissionController.step]:
///
/// - [MissionFlowStep.info]         → [_InfoView]          (frames 746-11392 / 746-11380, two tabs)
/// - [MissionFlowStep.cameraPrompt] → [_CameraPromptView]  (frame 426-18960)
/// - [MissionFlowStep.photoPreview] → [_PhotoPreviewView]  (frames 426-19035 / 426-18995 / 426-18974)
/// - [MissionFlowStep.submitted]    → [_SubmittedView]     (frames 426-19052 / 426-19062)
class MissionInfoPage extends StatefulWidget {
  const MissionInfoPage({super.key, required this.missionId});

  final String missionId;

  @override
  State<MissionInfoPage> createState() => _MissionInfoPageState();
}

class _MissionInfoPageState extends State<MissionInfoPage>
    with AsyncErrorListenerMixin<MissionInfoPage> {
  late final MissionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MissionController(missionId: widget.missionId);
    bindAsyncErrorListener(_controller);
    _controller.reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MissionScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          final Widget currentView = switch (_controller.step) {
            MissionFlowStep.info => const _InfoView(),
            MissionFlowStep.cameraPrompt => const _CameraPromptView(),
            MissionFlowStep.photoPreview => const _PhotoPreviewView(),
            MissionFlowStep.submitted => const _SubmittedView(),
          };
          return PopScope(
            canPop: !_controller.isLoading,
            child: Stack(
              children: <Widget>[
                currentView,
                if (_controller.isLoading)
                  const Positioned.fill(child: _MissionSubmitBlockingOverlay()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissionSubmitBlockingOverlay extends StatelessWidget {
  const _MissionSubmitBlockingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const <Widget>[
        ModalBarrier(dismissible: false, color: Color(0x66000000)),
        Center(child: _MissionSubmitLoadingPanel()),
      ],
    );
  }
}

class _MissionSubmitLoadingPanel extends StatelessWidget {
  const _MissionSubmitLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '업로드 중',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 118,
          height: 118,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '업로드 중',
                style: AppTypography.bodySemiBold.copyWith(
                  color: AppColors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info view — frames 746-11392 (tab 1) + 746-11380 (tab 2)
// ---------------------------------------------------------------------------

/// Two-tab info screen. Tab 1 (`미션정보`) renders the read-only chip-rows;
/// Tab 2 (`수행정보`) renders the empty-state perform prompt with sticky CTA.
///
/// Per Figma, these two frames are the SAME screen with different tab
/// selection — not separate flow steps.
class _InfoView extends StatelessWidget {
  const _InfoView();

  @override
  Widget build(BuildContext context) {
    final MissionController controller = MissionScope.of(context);
    final Mission mission = controller.mission;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: BridgeAppBar(title: mission.title),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppTokens.smallGap),
                const _InfoTabsBar(),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      _MissionInfoTab(mission: mission),
                      _MissionPerformInfoTab(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top tabs (`미션정보` / `수행정보`) for the info screen.
///
/// Lightweight wrapper around Material [TabBar] tuned to the spec's
/// 1.4px underline + token typography. Sits inside a [DefaultTabController].
class _InfoTabsBar extends StatelessWidget {
  const _InfoTabsBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 190,
        child: TabBar(
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.gray400,
          labelStyle: AppTypography.bodySemiBold,
          unselectedLabelStyle: AppTypography.bodyMedium,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: AppColors.textPrimary,
          indicatorWeight: 1.4,
          dividerColor: AppColors.border,
          tabs: const <Widget>[
            Tab(text: '미션정보'),
            Tab(text: '수행정보'),
          ],
        ),
      ),
    );
  }
}

/// "미션정보" tab — labeled rows per Figma 746-11392.
///
/// 카테고리는 부모앱 미션 등록과 같은 3-column grid, 리셋주기 / 확인방식은
/// horizontal selectable chip rows;
/// 지급시간 inlines a split-color reward chip on the right; 상세설명 is a
/// read-only textarea.
class _MissionInfoTab extends StatelessWidget {
  const _MissionInfoTab({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final String detail = (mission.description?.isNotEmpty ?? false)
        ? mission.description!
        : '상세 설명이 없어요.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.itemGap + 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _EvenChipRowSection(
            label: '카테고리',
            options: mission.categoryOptions,
            selected: mission.category,
            spacing: AppTokens.smallGap,
          ),
          const _MissionInfoSeparator(),
          _FixedChipRowSection(
            label: '리셋주기',
            options: mission.resetCycleOptions,
            selected: mission.resetCycle,
            widths: const <double>[74, 88, 74],
          ),
          const _MissionInfoSeparator(),
          _EvenChipRowSection(
            label: '확인방식',
            options: <String>[
              for (final ConfirmationMethod m
                  in mission.confirmationMethodOptions)
                m.label,
            ],
            selected: mission.confirmationMethod.label,
          ),
          const _MissionInfoSeparator(),
          _PayoutTimeSection(
            label: '지급시간',
            hours: mission.rewardHours,
            minutes: mission.rewardMinutes,
          ),
          const _MissionInfoSeparator(),
          _DescriptionSection(label: '상세설명', value: detail),
        ],
      ),
    );
  }
}

/// "수행정보" tab body — empty state + sticky `수행하기` CTA.
///
/// When `cameraPrompt` / `photoPreview` / `submitted` flow steps render in
/// separate Scaffolds (after the user taps the CTA), this tab body still
/// shows the pre-perform empty state per Figma 746-11380 because the
/// info-tab is the entry point.
class _MissionPerformInfoTab extends StatelessWidget {
  const _MissionPerformInfoTab({required this.controller});

  final MissionController controller;

  @override
  Widget build(BuildContext context) {
    final bool isRejected = controller.mission.status == MissionStatus.rejected;

    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.itemGap, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                isRejected ? '미션이 반려되었어요.' : '미션이 아직 수행되지 않았어요.',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.gray300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          BridgeButton(
            label: isRejected ? '다시 수행하기' : '수행하기',
            variant: BridgeButtonVariant.primary,
            size: BridgeButtonSize.large,
            fullWidth: true,
            // Backend accepts a new performance after REJECTED; keep the retry
            // path open and only guard against in-flight async re-entry.
            onPressed: controller.isLoading
                ? null
                : controller.goToCameraPrompt,
          ),
        ],
      ),
    );
  }
}

/// Section: fixed-width parent-app style chip row.
class _FixedChipRowSection extends StatelessWidget {
  const _FixedChipRowSection({
    required this.label,
    required this.options,
    required this.selected,
    required this.widths,
  });

  final String label;
  final List<String> options;
  final String selected;
  final List<double> widths;

  static const double _spacing = 14;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MissionInfoSectionLabel(label),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            for (int i = 0; i < options.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: _spacing),
              SizedBox(
                width: i < widths.length ? widths[i] : widths.last,
                child: _SelectableChip(
                  label: options[i],
                  selected: options[i] == selected,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Section: equal-width parent-app style chip row.
class _EvenChipRowSection extends StatelessWidget {
  const _EvenChipRowSection({
    required this.label,
    required this.options,
    required this.selected,
    this.spacing = 14,
  });

  final String label;
  final List<String> options;
  final String selected;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MissionInfoSectionLabel(label),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            for (int i = 0; i < options.length; i++) ...<Widget>[
              if (i > 0) SizedBox(width: spacing),
              Expanded(
                child: _SelectableChip(
                  label: options[i],
                  selected: options[i] == selected,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MissionInfoSectionLabel extends StatelessWidget {
  const _MissionInfoSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.headlineSemiBold.copyWith(color: AppColors.gray800),
    );
  }
}

/// Single chip with selected (primary bg + white text) and unselected
/// parent-app variants.
class _SelectableChip extends StatelessWidget {
  const _SelectableChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? AppColors.primary : AppColors.gray050;
    final Color textColor = selected ? AppColors.white : AppColors.gray600;

    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
          ),
          borderRadius: BorderRadius.circular(AppTokens.fieldRadius),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style:
                  (selected
                          ? AppTypography.bodySemiBold
                          : AppTypography.bodyMedium)
                      .copyWith(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionInfoSeparator extends StatelessWidget {
  const _MissionInfoSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 6,
      margin: const EdgeInsets.symmetric(vertical: 26),
      color: AppColors.gray150,
    );
  }
}

/// 지급시간 row — label left, split-color time chip right (inlined).
class _PayoutTimeSection extends StatelessWidget {
  const _PayoutTimeSection({
    required this.label,
    required this.hours,
    required this.minutes,
  });

  final String label;
  final int hours;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: _MissionInfoSectionLabel(label)),
        _RewardChip(hours: hours, minutes: minutes),
      ],
    );
  }
}

/// 상세설명 row — label + read-only textarea field.
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MissionInfoSectionLabel(label),
        const SizedBox(height: AppTokens.smallGap),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AppTokens.mediumGap,
          ),
          decoration: BoxDecoration(
            color: AppColors.gray050,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(AppTokens.mediumGap),
          ),
          child: Text(
            value,
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Split-color reward chip: number in primary, unit in textPrimary.
/// Renders only the segments that have a non-zero value. Used inline
/// inside the 지급시간 row.
class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final TextStyle numberStyle = AppTypography.headlineSemiBold.copyWith(
      color: AppColors.primary,
    );
    final TextStyle unitStyle = AppTypography.headlineMedium.copyWith(
      color: AppColors.textPrimary,
    );

    final List<InlineSpan> spans = <InlineSpan>[];
    if (hours > 0) {
      spans.add(
        TextSpan(text: hours.toString().padLeft(2, '0'), style: numberStyle),
      );
      spans.add(TextSpan(text: ' 시간', style: unitStyle));
    }
    if (minutes > 0) {
      if (spans.isNotEmpty) {
        spans.add(const WidgetSpan(child: SizedBox(width: AppTokens.smallGap)));
      }
      spans.add(
        TextSpan(text: minutes.toString().padLeft(2, '0'), style: numberStyle),
      );
      spans.add(TextSpan(text: ' 분', style: unitStyle));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray050,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
      ),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera prompt view — frame 426-18960
// ---------------------------------------------------------------------------

/// Camera prompt view.
///
/// Shows the mission title + capture-instruction copy, the large
/// [_CameraCTA] tile, the `최대 4장까지 올릴 수 있어요` hint and a disabled
/// `제출` button. Tapping the CTA invokes [CameraService.capturePhoto];
/// on success the controller auto-transitions to [MissionFlowStep.photoPreview].
class _CameraPromptView extends StatelessWidget {
  const _CameraPromptView();

  // Figma 426:18960 places the upload section at y=304 on the 375x812
  // canvas. With the shared top bar ending at y=96 and the title block at
  // y=120, this larger gap keeps the CTA in the intended lower position.
  static const double _uploadSectionTopGap = 104;

  @override
  Widget build(BuildContext context) {
    final MissionController controller = MissionScope.of(context);
    final Mission mission = controller.mission;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BridgeAppBar(title: '미션수행', onBack: controller.goBack),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppTokens.pageTop),
              Text(
                mission.title,
                style: AppTypography.heading1SemiBold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.itemGap),
              Text(
                mission.captureInstruction,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: _uploadSectionTopGap),
              _CameraCTA(
                onTap: () async {
                  await _pickAndAttachMissionPhoto(context, controller);
                },
              ),
              const Spacer(),
              Text(
                '최대 4장까지 올릴 수 있어요',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.mediumGap),
              // Disabled until at least one photo is captured. Once
              // [addPhoto] runs, the controller auto-transitions to
              // photoPreview so this view won't typically re-render
              // with an enabled submit — that lives in _PhotoPreviewView.
              const BridgeButton(label: '제출', onPressed: null),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large camera capture call-to-action.
///
/// Full-width tappable container (h=156, padded 52V) with a camera icon +
/// label. Uses a dashed 2px `#91969E` border on a `#F5F7FA` surface per
/// Figma 426-18960.
class _CameraCTA extends StatelessWidget {
  const _CameraCTA({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '카메라로 사진 촬영',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
          child: DottedBorder(
            color: AppColors.gray400,
            strokeWidth: 2,
            dashPattern: const <double>[6, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(AppTokens.buttonRadius),
            child: Container(
              height: 156,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.ios_share,
                    size: 24,
                    color: AppColors.gray700,
                  ),
                  const SizedBox(height: AppTokens.itemGap),
                  Text(
                    '사진을 업로드해주세요',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo preview view — frames 426-19035 / 426-18995 / 426-18974
// ---------------------------------------------------------------------------

/// Photo preview & submission view.
///
/// Renders a 2-column grid of captured photos with delete handles plus a
/// dashed `추가 업로드` tile while `photos.length < 4`. The submit CTA is
/// gated on [MissionController.canSubmit] (≥1 photo captured).
class _PhotoPreviewView extends StatelessWidget {
  const _PhotoPreviewView();

  // Figma 426:19035 / 426:18995 places the preview grid at y=250. The
  // shared header stack ends near y=197 on the 375x812 canvas, so this keeps
  // the photo row lower than the generic section spacing without affecting the
  // bottom hint/submit anchors.
  static const double _photoGridTopGap = 53;

  @override
  Widget build(BuildContext context) {
    final MissionController controller = MissionScope.of(context);
    final Mission mission = controller.mission;
    final int photoCount = controller.capturedPhotos.length;
    final bool isSubmitting = controller.isLoading;
    final bool showAddTile = !controller.hasMaxPhotos && !isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BridgeAppBar(title: '미션수행', onBack: controller.goBack),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppTokens.pageTop),
              Text(
                mission.title,
                style: AppTypography.heading1SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.itemGap),
              Text(
                mission.captureInstruction,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: _photoGridTopGap),
              Expanded(
                child: SingleChildScrollView(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppTokens.photoGap,
                    crossAxisSpacing: AppTokens.photoGap,
                    childAspectRatio: 157 / 156,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      for (int i = 0; i < photoCount; i++)
                        BridgePhotoTile(
                          path: controller.capturedPhotos[i],
                          onDelete: isSubmitting
                              ? () {}
                              : () => controller.removePhoto(i),
                        ),
                      if (showAddTile)
                        BridgeAddPhotoTile(
                          onTap: () async {
                            await _pickAndAttachMissionPhoto(
                              context,
                              controller,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                '최대 4장까지 올릴 수 있어요',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.mediumGap),
              BridgeButton(
                label: '제출',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                // submit() is now async; canSubmit also gates on isLoading so
                // a double-tap can't kick off two in-flight submissions.
                onPressed: controller.canSubmit
                    ? () {
                        controller.submit();
                      }
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Submitted view — frames 426-19052 (reviewing) / 426-19062 (completed)
// ---------------------------------------------------------------------------

/// Submitted-state view.
///
/// Visual states keyed off [Mission.status]:
/// - `completed` → primary check, `미션 수행 완료!`, reward subtitle
/// - default (`reviewing` / `rejected`) → primary check, `업로드 완료!`,
///   wait subtitle. Per spec line 232 there is no rejected Figma node, so
///   the rejected status (mock id '2') renders as the reviewing fallback.
class _SubmittedView extends StatelessWidget {
  const _SubmittedView();

  // Figma 426:19052 / 426:19062 starts the completion copy block at y≈213.
  // The shared app bar consumes 96px on the 375x812 canvas, leaving this body
  // offset to anchor the text block before the 60px check icon.
  static const double _contentTopGap = 117;

  @override
  Widget build(BuildContext context) {
    final MissionController controller = MissionScope.of(context);
    final MissionStatus status = controller.mission.status;
    final bool isCompleted = status == MissionStatus.completed;

    final String title = isCompleted ? '미션 수행 완료!' : '업로드 완료!';
    final String subtitle = isCompleted
        ? '${_rewardDuration(controller.mission)}의 보너스 시간이 지급되었어요!'
        : '확인까지 조금만 기다려주세요';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BridgeAppBar(title: '미션수행', showBack: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: _contentTopGap),
              Text(
                title,
                style: AppTypography.heading1SemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.itemGap),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, color: AppColors.white, size: 20),
                  ),
                ),
              ),
              const Spacer(),
              BridgeButton(
                label: '홈으로',
                variant: BridgeButtonVariant.primary,
                size: BridgeButtonSize.large,
                fullWidth: true,
                onPressed: () => context.go('/child-home'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _rewardDuration(Mission mission) {
    if (mission.rewardHours > 0 && mission.rewardMinutes > 0) {
      return '${mission.rewardHours}시간 ${mission.rewardMinutes}분';
    }
    if (mission.rewardHours > 0) return '${mission.rewardHours}시간';
    return '${mission.rewardMinutes}분';
  }
}
