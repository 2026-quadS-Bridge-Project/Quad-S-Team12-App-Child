# Round 3 Audit — Mission Feature

**Date**: 2026-05-18
**Mode**: Verification only — diagnose, do not fix
**Scope**: Mission feature re-audit after Round 2 overhaul
**Reference**: `_audit-layout/16-mission.md`

## Files Audited

- `lib/features/mission/data/models/mission.dart`
- `lib/features/mission/data/mock/mission_mock.dart`
- `lib/features/mission/state/mission_controller.dart`
- `lib/features/mission/presentation/pages/mission_info_page.dart`

## Verification Checklist Results

### 1. `MissionFlowStep` enum — 4 steps, NO `perform`
**PASS** — `mission_controller.dart:13`
```dart
enum MissionFlowStep { info, cameraPrompt, photoPreview, submitted }
```
No `perform` member present. Header comment (lines 7–12) explicitly explains that `수행정보` is the second tab of `info`, not a separate flow step.

### 2. Mission model fields
**PASS** — `mission.dart:20-30`
- `categoryOptions` (default 5-item list) — line 20
- `resetCycleOptions` (default 3-item list) — line 22
- `confirmationMethodOptions` (default 3-item list) — line 24
- `captureInstruction` (default Figma string) — line 30
- All five plural option lists + singular selection fields wired through `copyWith` (lines 71–89).

### 3. `_InfoView` uses `DefaultTabController` with 2 tabs
**PASS** — `mission_info_page.dart:86-117`
- `DefaultTabController(length: 2, ...)` — line 86–87
- `_InfoTabsBar` exposes Tabs `미션정보` / `수행정보` — lines 138-139
- `TabBarView` with `NeverScrollableScrollPhysics` and two children (`_MissionInfoTab`, `_MissionPerformInfoTab`) — lines 102-108

### 4. Tab 2 (수행정보) shows empty-state copy + 수행하기 CTA → goToCameraPrompt
**PASS** — `mission_info_page.dart:203-237`
- Empty-state text `미션이 아직 수행되지 않았어요.` — line 218
- Centered in `Expanded` — lines 215-225
- `BridgeButton(label: '수행하기', variant: primary, size: large, fullWidth: true)` — lines 226-232
- `onPressed: controller.goToCameraPrompt` — line 231

### 5. `_ChipRowSection` renders horizontal selectable chips per row (not single pill)
**PASS** — `mission_info_page.dart:240-274`
- Iterates `for (final String option in options)` producing one `_SelectableChip` per option (line 267-268)
- Uses `Wrap` (lines 263-270) — flows horizontally with wrap-on-overflow
- `_SelectableChip` (lines 278-306) distinguishes selected (`primary` bg + `bodyBold` white) vs unselected (`gray100` bg + `gray200` border + `bodyMedium` `gray600`)
- Note: Spec calls "horizontal selectable chip row"; implementation uses `Wrap` which is horizontal-first but will wrap to additional runs if content exceeds the container. Matches behavior for the small option counts (3-5). Acceptable.

### 6. `_CameraPromptView` and `_PhotoPreviewView` use `heading1Bold` (24)
**PASS**
- `_CameraPromptView`: `style: AppTypography.heading1Bold` — line 468
- `_PhotoPreviewView`: `style: AppTypography.heading1Bold.copyWith(color: AppColors.textPrimary)` — line 611

### 7. Both have captureInstruction subtitle + 최대 4장 hint
**PASS**
- `_CameraPromptView`: `mission.captureInstruction` subtitle (line 473), `'최대 4장까지 올릴 수 있어요'` hint (line 490)
- `_PhotoPreviewView`: `mission.captureInstruction` subtitle (line 618), `'최대 4장까지 올릴 수 있어요'` hint (line 655)
- Both use `bodyMedium` / `gray600` for instruction and `labelMedium` / `gray600` for hint — consistent styling.

### 8. Camera CTA dashed border (DottedBorder)
**PASS** — `mission_info_page.dart:519-573`
- `DottedBorder(color: AppColors.gray400, strokeWidth: 2, dashPattern: [6, 4], borderType: BorderType.RRect, ...)` — lines 536-541
- Wraps the 156-height container with camera icon + `사진을 업로드해주세요` label
- Surface uses `AppColors.surfaceMuted` per spec.

### 9. `_PhotoPreviewView` uses `GridView.count(2)` not `Wrap`
**PASS** — `mission_info_page.dart:626-652`
- `GridView.count(crossAxisCount: 2, ...)` — lines 627-628
- `mainAxisSpacing` / `crossAxisSpacing` = `AppTokens.photoGap`
- `childAspectRatio: 157/156` — line 631
- `shrinkWrap: true` + `NeverScrollableScrollPhysics` inside `SingleChildScrollView` — lines 632-633
- Children: captured `BridgePhotoTile` per photo + optional `BridgeAddPhotoTile` when `!hasMaxPhotos`.

### 10. `_SubmittedView`: reviewing + completed both render primary check, NO rejected branch
**PASS** — `mission_info_page.dart:690-761`
- Branch logic: `final bool isCompleted = status == MissionStatus.completed;` (line 697)
- Only two visual states: completed vs everything-else (reviewing / rejected falls into else)
- Check icon container always `AppColors.primary` circular background (line 719) — no status-specific color
- Header comment (lines 685-689) documents this intent explicitly: "Per spec line 232 there is no rejected Figma node, so the rejected status (mock id '2') renders as the reviewing fallback."

### 11. `_SubmittedView` has `BridgeAppBar('미션수행')`
**PASS** — `mission_info_page.dart:706`
```dart
appBar: const BridgeAppBar(title: '미션수행', showBack: false),
```
`showBack: false` is consistent with controller comment (line 87 of `mission_controller.dart`): "No back from submitted — user must exit via 홈으로". Bottom CTA `홈으로` routes to `/child-home` (line 752).

### 12. MissionController has cancellable Timer with dispose
**PASS** — `mission_controller.dart:22, 67-78, 95-101`
- `Timer? _autoApproveTimer;` — line 22
- `bool _disposed = false;` — line 23
- `submit()` cancels prior timer and re-arms with `_disposed` check inside callback — lines 67-77
- `dispose()` sets `_disposed = true`, cancels and nulls the timer — lines 95-101
- Guards against `notifyListeners()` on disposed `ChangeNotifier`. Safe pattern.

## Visual Diff (Figma)
**SKIPPED** — figma MCP tools were not available in this verification environment. Per the spec doc `_audit-layout/16-mission.md`, the layout overhaul targets frames 746-11392, 746-11380, 426-18960, 426-19035, 426-18995, 426-19062, and the code structure now aligns with the Round 2 plan documented inline (file-header comments at lines 21-25 and 689-690 of `mission_info_page.dart` annotate each frame mapping). A follow-up visual sweep is still recommended.

## Summary

| # | Check | Status |
|---|------|--------|
| 1 | Enum 4 steps, no `perform` | PASS |
| 2 | Model option lists + captureInstruction | PASS |
| 3 | DefaultTabController, 2 tabs | PASS |
| 4 | 수행정보 empty-state + 수행하기 → goToCameraPrompt | PASS |
| 5 | `_ChipRowSection` horizontal selectable chips | PASS |
| 6 | heading1Bold on cameraPrompt / photoPreview | PASS |
| 7 | captureInstruction + 4-photo hint | PASS |
| 8 | DottedBorder camera CTA | PASS |
| 9 | GridView.count(2) for photo preview | PASS |
| 10 | Submitted view: no rejected branch | PASS |
| 11 | BridgeAppBar('미션수행') on submitted | PASS |
| 12 | Cancellable Timer + dispose guard | PASS |

**Overall**: 12/12 PASS (code audit). Visual Figma diff not performed in this environment.

## Per-View Roll-up

- **InfoView (tab 1: 미션정보)** — PASS
- **InfoView (tab 2: 수행정보)** — PASS
- **CameraPromptView** — PASS
- **PhotoPreviewView** — PASS
- **SubmittedView** — PASS

## Observations / Notes (non-blocking)

- `_ChipRowSection` uses `Wrap` not a single-line `ListView`. For the current option counts (max 5 short Korean labels) this renders as one row at standard widths but may wrap on narrow devices. If strict single-row scrolling is required, swap to `SingleChildScrollView(scrollDirection: Axis.horizontal)`. Not a regression — Round 2 spec did not mandate scroll behavior.
- `_CameraPromptView` shows a disabled `BridgeButton(label: '제출', onPressed: null)` (lines 501-504). In practice the controller auto-advances to `photoPreview` on first photo capture (`addPhoto`, controller lines 41-48), so users will not see an enabled submit on this view. Documented inline at lines 498-500. Intentional.
- `_SubmittedView` `홈으로` button hard-codes `'/child-home'`. Acceptable for current routing surface; consider a named route constant if the path changes.
- Mock data (`mission_mock.dart`) still includes a `rejected` entry (id `2`). Since `_SubmittedView` treats rejected as the reviewing fallback per spec, the rejected mock entry never exercises a unique UI branch. Consider whether the mock entry is still needed, or whether a future spec will add a rejected design.
