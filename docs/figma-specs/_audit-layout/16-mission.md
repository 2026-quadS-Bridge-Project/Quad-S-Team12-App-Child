# Audit — Mission Info / Perform / Camera / Preview / Submitted Pages

**Target**: `lib/features/mission/presentation/pages/mission_info_page.dart`
**Sub-views audited**: `_InfoView`, `_PerformView`, `_CameraPromptView`, `_PhotoPreviewView`, `_SubmittedView`
**Figma nodes (8)**: `746-11392` (info), `746-11380` (perform-empty), `426-18960` (camera prompt), `426-19035` (1 photo), `426-18995` (3 photos), `426-18974` (4 photos), `426-19052` (reviewing), `426-19062` (completed)
**Spec ref**: `docs/figma-specs/11-mission.md`
**Supporting files inspected**:
- `lib/features/mission/state/mission_controller.dart`
- `lib/features/mission/state/mission_scope.dart`
- `lib/features/mission/data/models/mission.dart`
- `lib/features/mission/data/mock/mission_mock.dart`
- `lib/core/widgets/inputs/bridge_photo_tile.dart`
- `lib/core/widgets/buttons/bridge_button.dart`
- `lib/core/widgets/layout/bridge_app_bar.dart`
- `lib/core/services/camera_service.dart`
- `lib/core/theme/app_typography.dart`, `app_colors.dart`, `app_tokens.dart`

**Mode**: Diagnostic only — **do not fix**.

---

## Summary

| # | View | Severity | Topic | Status |
|---|------|----------|-------|--------|
| 1 | _InfoView | HIGH | Tab structure conflicts with spec — `수행정보` tab should be a separate Figma node (746-11380), not an in-page tab body | Mismatch |
| 2 | _InfoView | HIGH | Chip rendering uses generic label+value pill rows; Figma specifies horizontal selectable chip rows (`루틴/학습/운동/청소/심부름`) with selected/unselected variants | Mismatch |
| 3 | _InfoView | HIGH | `_AssignedByChip` rendered ABOVE title — spec/recent commit message says title + chip in a header card with title prominent (chip placement order debatable but spec ref says title is the topbar title `방청소하기`, not duplicated) | Layout deviation |
| 4 | _InfoView | MEDIUM | `_RewardChip` placement standalone — spec frames it INSIDE the `지급시간` row of the info tab, not as a top-level page chip | Mismatch |
| 5 | _InfoView | MEDIUM | `BridgeAppBar(title: '미션 정보')` — Figma shows title is the mission title `방청소하기`, not the literal string `미션 정보` | Copy mismatch |
| 6 | _InfoView | MEDIUM | `_RewardChip` segment separator uses two spaces (`'  '`); fragile and not Figma-equivalent (Figma uses fixed gap between `00 시간` / `30 분` chip segments) | Mismatch |
| 7 | _InfoView | LOW | `BridgeAppBar` has no `onBack` override — defaults to `context.pop()` which is correct for info root, but inconsistent with sub-views that pass `controller.goBack` | Defensible |
| 8 | _InfoView | INFO | TabBar 1.4px underline + label colors per spec | OK |
| 9 | _InfoView | LOW | Hard-coded `SizedBox(height: 24)` bottom padding instead of `AppTokens` constant | Minor token leak |
| 10 | _InfoView | LOW | `_MissionPerformInfoTab` is a placeholder copy (`수행하기 버튼을 눌러…`) — spec says when tab is active the body should be the empty-perform card with sticky `수행하기` button (or it should be the separate `_PerformView`) | Stub leak |
| 11 | _PerformView | HIGH | Spec models `수행정보` as a TAB inside the info page (746-11380 IS the info screen with the second tab active), not a separate Scaffold reached via `controller.goToPerform`. Current implementation conflates "perform-empty tab" with a separate "perform" flow step | Architecture mismatch |
| 12 | _PerformView | MEDIUM | Empty icon uses `Icons.assignment_outlined` 32px gray400 — Figma `746-11380` shows NO icon, only centered text at y≈393 | Mismatch |
| 13 | _PerformView | LOW | Empty-state text style: `bodyMedium / gray500` — Figma spec line 64 says `Pretendard 18 Medium #A7ACB2` (= `headlineMedium / gray300`) | Token mismatch |
| 14 | _PerformView | INFO | Sticky `수행하기` BridgeButton → `controller.goToCameraPrompt` wiring | OK |
| 15 | _PerformView | INFO | BridgeAppBar back wired to `controller.goBack` | OK |
| 16 | _CameraPromptView | MEDIUM | AppBar title `'미션 수행'` — spec line 75 says topbar title is `미션수행` (no space). Same view re-uses across photo-preview screens. | Copy nit |
| 17 | _CameraPromptView | HIGH | Title shown is `mission.title` rendered with `heading2Bold` (20px) — spec line 96/104 requires `Pretendard 24 SemiBold` (= `heading1Bold`) for `방청소 하기` title block | Typography mismatch |
| 18 | _CameraPromptView | MEDIUM | Subtitle copy `'사진을 찍어 미션을 인증해주세요.'` — Figma verbatim is `'깨끗해진 방을 찍어서 올려주세요!'` (spec line 97). Not a generic instruction; copy is mission-specific | Copy mismatch |
| 19 | _CameraPromptView | HIGH | Missing hint copy `'최대 4장까지 올릴 수 있어요'` above the disabled submit (spec line 99) — only shown on `_PhotoPreviewView`. Figma 426-18960 includes the hint even in the 0-photo state | Missing element |
| 20 | _CameraPromptView | MEDIUM | `_CameraCTA` height fixed at 200 — spec line 83 specifies h≈156 (padded 52V/83H). Off by ~44px | Dimension mismatch |
| 21 | _CameraPromptView | LOW | `_CameraCTA` icon color `gray700` with size 32 — spec line 84 says icon size 24 | Dimension mismatch |
| 22 | _CameraPromptView | LOW | `_CameraCTA` label uses `headlineMedium` (18 Medium) `gray700` — Figma color is `#47484B` (= `gray700`) ✓ but spec line 84 puts inner column gap at 16 while implementation uses `AppTokens.itemGap` (16) ✓ | OK |
| 23 | _CameraPromptView | INFO | `DottedBorder` with `[6,4]` dash pattern, 2px stroke, `gray400` color | OK |
| 24 | _CameraPromptView | INFO | Disabled `BridgeButton` renders gray200/gray300 per spec | OK |
| 25 | _PhotoPreviewView | HIGH | Wrap grid uses default `Wrap` alignment — Figma 426-18974 spec line 167 requires 2×2 grid layout (`grid-cols-2`); `Wrap` will give 2 cols on a 327-wide canvas with two ~157-wide tiles + 12 gap (≈326), but a single trailing tile in a 1/4 or 3/4 state will left-align rather than honor the 2-col grid spec | Layout fragility |
| 26 | _PhotoPreviewView | MEDIUM | Title `controller.mission.title` rendered with `heading2Bold` — same issue as Issue 17, spec requires `heading1Bold` (24 SemiBold) | Typography mismatch |
| 27 | _PhotoPreviewView | MEDIUM | Missing the mission subtitle (`깨끗해진 방을 찍어서 올려주세요!`) — Figma 426-19035/18995/18974 keeps the title+subtitle block, only the photo grid replaces the dashed CTA | Missing element |
| 28 | _PhotoPreviewView | LOW | Hint `최대 4장까지 올릴 수 있어요` uses `labelMedium` (14 Medium) `gray600` — spec line 85 (`#5F6165` = `gray600`) ✓ and 14 Medium ✓ | OK |
| 29 | _PhotoPreviewView | INFO | `BridgePhotoTile.onDelete` → `controller.removePhoto(i)` index correctness | OK |
| 30 | _PhotoPreviewView | INFO | `BridgeAddPhotoTile` shown only when `!controller.hasMaxPhotos` | OK |
| 31 | _PhotoPreviewView | INFO | Submit gating: `controller.canSubmit ? controller.submit : null` | OK |
| 32 | _PhotoPreviewView | LOW | `BridgePhotoTile` fixed widths 157×156 — on a 327-wide content area with 12 gap, two tiles = 157+12+157 = 326 ≈ 327 ✓ but on devices with non-standard widths the tiles may overflow `Wrap` row | Defensive deviation |
| 33 | _PhotoPreviewView | LOW | `Image.file` errorBuilder returns 157×156 gray200 box with `broken_image` icon — handles stale path case | OK |
| 34 | _SubmittedView | HIGH | Rejected branch handled inline (`Icons.close`, destructive bg) but spec line 232 explicitly notes "No explicit `rejected` screen was provided in this batch" — speculative UI added beyond scope, violates YAGNI / RULES Scope Discipline | Out of scope |
| 35 | _SubmittedView | MEDIUM | Icon size 32 inside 60×60 circle — Figma `426-19052/19062` (`Vector81` check ~33% inset) suggests ~20px icon inside 60px circle. 32px in 60px is ~53% — too large | Dimension mismatch |
| 36 | _SubmittedView | MEDIUM | Reviewing-branch icon `Icons.hourglass_empty` on `gray400` bg — Figma 426-19052 spec line 187 shows **primary blue circle with white check** (same as 426-19062), not a hourglass/gray variant. Both reviewing and completed states share the SAME blue-check icon, differing only by title/subtitle copy | Visual mismatch |
| 37 | _SubmittedView | MEDIUM | Title `'업로드 완료!'` for reviewing branch uses `heading1Bold` — spec line 185 confirms `Pretendard 24 SemiBold` ✓ but no BridgeAppBar present. Spec line 182 says reviewing screen has topbar `미션수행`; current implementation has NO appbar (full-bleed). | Missing topbar |
| 38 | _SubmittedView | LOW | Subtitle text spacing — uses `SizedBox(height: 16)` between title and subtitle. Spec line 184 says gap=16 between text-block lines but gap=40 between text block and icon. Current order is icon → 24 gap → title → 16 gap → subtitle, but Figma layout is text-block (title+subtitle gap 16) → 40 gap → icon. Vertical ORDER reversed | Layout mismatch |
| 39 | _SubmittedView | INFO | `홈으로` BridgeButton → `context.go('/child-home')` navigation | OK |
| 40 | _SubmittedView | INFO | `Spacer` on top and bottom centers content vertically | OK |
| 41 | Controller | MEDIUM | `submit({bool aiAutoApprove = true})` runs `Future.delayed(2s)` with no cancellation if the page is disposed mid-flight. The closure checks `_step` and `_mission.status` after the delay, which guards against state mutation, but the controller itself may have been disposed | Memory-safety leak risk |
| 42 | Controller | LOW | `goBack` from `submitted` does nothing — user can only exit via `홈으로`. System back button (Android) will pop the entire `MissionInfoPage`, bypassing the controller's flow guard | UX gap |
| 43 | Controller | INFO | `addPhoto` auto-transitions `cameraPrompt`/`perform` → `photoPreview` | OK |
| 44 | Controller | LOW | `MissionMock.byId` falls back to `all.first` if id not found — silent fail, mission `'방청소 하기'` may render unexpectedly | Hidden mock fallback |
| 45 | AnimatedBuilder | LOW | `AnimatedBuilder(animation: _controller, builder: (context, _) => switch(...))` rebuilds the entire sub-tree on every controller notification. Cost is negligible (5 stateless views) but `MissionScope` already provides `InheritedNotifier` rebuild — the `AnimatedBuilder` wrapper is redundant | Duplicate listener |

**Findings count**: **45** (6 HIGH, 14 MEDIUM, 12 LOW, 13 OK/INFO).

---

## _InfoView (frame 746-11392)

### Issue 1 — Tab structure conflicts with Figma node split — HIGH

- **Observation**: `_InfoView` builds a `DefaultTabController(length: 2)` with two tabs (`미션정보`, `수행정보`). The `수행정보` tab body is `_MissionPerformInfoTab` (a stub placeholder). Separately, `_PerformView` is reachable as a different `MissionFlowStep`.
- **Root cause**: The Figma spec models `746-11392` and `746-11380` as TWO RENDERINGS OF THE SAME SCREEN with different tab selection (see spec line 9 "tab pair `미션정보` / `수행정보`" and line 52 "The `수행정보` tab default state when the child has not yet started"). Implementation has split them into two distinct flow steps, leaving `수행정보` tab as a stub.
- **Figma ref**: 11-mission.md lines 9-49 (`746-11392` is the `미션정보` ACTIVE tab) and lines 52-71 (`746-11380` is the `수행정보` ACTIVE tab with empty state). Spec confirms it is one screen, one tab control, two visual states.
- **Fix (proposed, do not apply)**: Merge `_PerformView` into the `_InfoView` tab — when tab `수행정보` is active, render the empty-state + sticky CTA inside the `TabBarView`'s second child. Remove `MissionFlowStep.perform` from the controller enum.

### Issue 2 — Chip rows are pills, not selectable category chips — HIGH

- **Observation**: `_MissionInfoTab` renders `_InfoChipRow(label: '카테고리', value: mission.category)` as a `gray100`-bg pill containing a single value text.
- **Root cause**: Spec line 27 explicitly enumerates `루틴 (selected), 학습, 운동, 청소, 심부름` — a horizontal row of multiple chips with one selected (blue bg + white text) and others unselected (`gray100` bg + `gray200` border). Implementation degenerates this into a single-value row.
- **Figma ref**: 11-mission.md lines 27-29 (category/reset/confirm chip enums), lines 33-35 (selected chip: bg `#3A99F8` + text white SemiBold 16; unselected: bg `#F5F7FA` border `#D5D8DE`), line 46 (chip h=52, radius=12, padding 16V/10-12H).
- **Fix (proposed, do not apply)**: Build a `BridgeMissionChipRow` widget that takes `options: List<String>` + `selected: String` and renders horizontal Wrap of selectable chips with selected/unselected variants. Apply to category/reset/confirm rows. Keep `지급시간` and `상세설명` as their distinct shapes (time chip + textarea).

### Issue 3 — `_AssignedByChip` placement above title — LOW/HIGH (ambiguous)

- **Observation**: `_MissionHeaderCard` stacks chip ABOVE title (`Column(start)` with `_AssignedByChip` first, `Text(mission.title)` second).
- **Root cause**: Spec 11-mission.md does NOT describe an `AssignedByChip` at all in node 746-11392. The title `방청소하기` is in the TOPBAR (spec line 14 "Topbar 52h — title `방청소하기` center"), and the chip rows below are the content. The header card is a layered invention; the title belongs in the appbar.
- **Figma ref**: 11-mission.md line 14: "Topbar (52h) — back arrow left, title `방청소하기` center, Pretendard 18 Medium #050505". Line 24: "Title: `방청소하기`" listed under Texts but referenced as topbar title.
- **Fix (proposed, do not apply)**: Move `mission.title` into `BridgeAppBar(title: mission.title)` and delete `_MissionHeaderCard`. Drop `_AssignedByChip` entirely or relocate per a future spec node. Confirm with design whether `AssignedByChip` (AI/parent registration source) is required — not present in spec.

### Issue 4 — `_RewardChip` placed standalone above tabs — MEDIUM

- **Observation**: `_RewardChip(hours, minutes)` is a top-level row BETWEEN header card and tab bar.
- **Root cause**: Spec frames the reward chip INSIDE the `지급시간` row of the `미션정보` tab body (spec line 20 "Row with label + readonly time chip (right)" and line 30 "Time chip: `00 시간`, `30 분` (numbers in primary, units in #050505)"). The chip is contextual to the time field, not a hero element.
- **Figma ref**: 11-mission.md lines 19-20 (지급시간 section), line 30 (time chip content), line 38 (time field bg `#FAFBFC` border `#D5D8DE` radius 8), line 240 ("Mission info screen (`지급시간`) | Numbers in primary `#3A99F8` SemiBold, units in `#050505` Medium, inside a `#FAFBFC` outlined chip").
- **Fix (proposed, do not apply)**: Remove standalone `_RewardChip` from page chrome; pass `hours`/`minutes` into the `지급시간` row of `_MissionInfoTab` and render the chip inline (right-aligned) within that row.

### Issue 5 — AppBar title literal `'미션 정보'` vs mission title — MEDIUM

- **Observation**: `BridgeAppBar(title: '미션 정보')`.
- **Root cause**: Spec line 14 says topbar title is the mission name (`방청소하기`). Hard-coding `'미션 정보'` ignores the dynamic title and conflicts with `_PerformView`'s appbar (`'미션 수행'`) which also doesn't match spec.
- **Figma ref**: 11-mission.md line 14, line 24.
- **Fix (proposed, do not apply)**: `BridgeAppBar(title: mission.title)`.

### Issue 6 — `_RewardChip` segment separator fragile — MEDIUM

- **Observation**: When both hours > 0 and minutes > 0, separator is `TextSpan(text: '  ', style: unitStyle)` (two regular spaces).
- **Root cause**: Two spaces produce a font-dependent variable gap, not the consistent visual gap Figma shows between `00 시간` and `30 분` segments. Letter-spacing on `unitStyle` (headlineMedium = `-0.02`) compounds the inconsistency.
- **Figma ref**: 11-mission.md line 30 ("Time chip: `00 시간`, `30 분`") — comma in spec implies visual separator/gap, not 2 literal spaces.
- **Fix (proposed, do not apply)**: Use `WidgetSpan(child: SizedBox(width: 8))` or split into two separate chips/`Row` with explicit `SizedBox` gap.

### Issue 7 — `BridgeAppBar` no `onBack` override — LOW

- **Observation**: `_InfoView` uses `const BridgeAppBar(title: '미션 정보')` (no `onBack`). All other views pass `onBack: controller.goBack`.
- **Root cause**: Defensible — `_InfoView` is the root, so default `context.pop()` correctly leaves the mission flow. But the visual & wiring inconsistency between root and sub-views may confuse future maintainers.
- **Figma ref**: N/A — navigation behavior, not visual.
- **Fix (proposed, do not apply)**: Add an inline comment noting "root view, defaults to pop", or override with `() => context.pop()` explicitly.

### Issue 8 — TabBar styling — OK

- **Observation**: `indicatorWeight: 1.4`, `labelColor: textPrimary`, `unselectedLabelColor: gray400`, `dividerColor: border`.
- **Root cause**: Matches spec line 15 ("1.4px black underline") and line 16 ("inactive `#91969E`").
- **Figma ref**: 11-mission.md lines 14-16.
- **Fix**: None.

### Issue 9 — Hard-coded bottom padding — LOW

- **Observation**: `const SizedBox(height: 24)` after the `수행하기` button.
- **Root cause**: 24 corresponds to `AppTokens.cardPadding` or could be a new `bottomCtaGap` token. Hard-coding bypasses the token system.
- **Figma ref**: N/A — token discipline rule.
- **Fix (proposed, do not apply)**: Replace with `AppTokens.cardPadding` or introduce `AppTokens.bottomCtaGap = 24`.

### Issue 10 — `_MissionPerformInfoTab` is a stub — LOW

- **Observation**: Renders `'수행하기 버튼을 눌러 미션을 시작해주세요.'` as `bodyRegular / textSecondary`.
- **Root cause**: Tied to Issue 1 — this tab body should be the actual perform-empty content (with sticky CTA), not generic prompt copy.
- **Figma ref**: 11-mission.md lines 52-71 describes the full empty-state with empty copy + sticky `수행하기` CTA.
- **Fix (proposed, do not apply)**: Replace with the merged perform-empty body once Issue 1 is resolved.

---

## _PerformView (frame 746-11380)

### Issue 11 — `_PerformView` exists as a separate flow step — HIGH

- **Observation**: `MissionFlowStep.perform` is a top-level state with its own Scaffold. Reaching it requires `controller.goToPerform()` (only triggered by tapping `수행하기` on `_InfoView`).
- **Root cause**: See Issue 1. Spec models this as a TAB STATE of the info screen, not a separate page. Children navigating tabs (tapping `수행정보`) won't see this state in current implementation.
- **Figma ref**: 11-mission.md lines 52-71.
- **Fix (proposed, do not apply)**: Merge into `_InfoView`'s second tab body. Direct `controller.goToCameraPrompt` from the in-tab `수행하기` button.

### Issue 12 — Empty-state icon not in Figma — MEDIUM

- **Observation**: `Icon(Icons.assignment_outlined, size: 32, color: gray400)` above the empty-state text.
- **Root cause**: Spec lines 56-67 describe ONLY a centered text at y≈393, no icon. Implementation added an icon defensively.
- **Figma ref**: 11-mission.md line 60: "Empty-state copy centered at y≈393" — no icon mentioned.
- **Fix (proposed, do not apply)**: Remove the `Icon` widget.

### Issue 13 — Empty-state text style mismatch — LOW

- **Observation**: `bodyMedium` (16 Medium) + `gray500` (#777A7F).
- **Root cause**: Spec line 64 says `Pretendard 18 Medium, color #A7ACB2, center` — that's `headlineMedium` + `gray300`. Implementation uses 16-size token and a darker gray.
- **Figma ref**: 11-mission.md line 64.
- **Fix (proposed, do not apply)**: `AppTypography.headlineMedium.copyWith(color: AppColors.gray300)`.

### Issue 14 — Sticky CTA → goToCameraPrompt — OK

- **Observation**: `BridgeButton(label: '수행하기', onPressed: controller.goToCameraPrompt)`.
- **Root cause**: Matches spec line 70 "Bottom `수행하기` button → navigate to camera prompt screen (`426-18960`)".
- **Fix**: None.

### Issue 15 — BridgeAppBar back wiring — OK

- **Observation**: `onBack: controller.goBack` correctly returns to `info` step.
- **Fix**: None.

---

## _CameraPromptView (frame 426-18960)

### Issue 16 — AppBar title `'미션 수행'` vs spec `'미션수행'` — LOW

- **Observation**: AppBar title literal `'미션 수행'` (with space).
- **Root cause**: Spec line 75 and 78 consistently spell topbar title `미션수행` (no space). Korean spacing is contextually flexible, but Figma source uses the no-space variant.
- **Figma ref**: 11-mission.md line 75 ("Status bar + topbar (`미션수행`)").
- **Fix (proposed, do not apply)**: Change to `'미션수행'` to match Figma verbatim.

### Issue 17 — Mission title typography mismatch — HIGH

- **Observation**: `Text(mission.title, style: AppTypography.heading2Bold)` (20px SemiBold).
- **Root cause**: Spec line 104 specifies `Pretendard 24 SemiBold` — that is `heading1Bold` in tokens. 4px size difference makes the title visually under-weighted vs Figma.
- **Figma ref**: 11-mission.md line 81 (Title 24 SemiBold `방청소 하기`), line 104 ("Title: Pretendard 24 SemiBold, `#050505`, line 1.364, tracking -1.94").
- **Fix (proposed, do not apply)**: Use `AppTypography.heading1Bold`.

### Issue 18 — Subtitle copy generic vs Figma-specific — MEDIUM

- **Observation**: Subtitle: `'사진을 찍어 미션을 인증해주세요.'`.
- **Root cause**: Spec line 97 verbatim: `'깨끗해진 방을 찍어서 올려주세요!'` — mission-specific copy in Figma. Implementation substituted a generic instruction.
- **Figma ref**: 11-mission.md line 97.
- **Fix (proposed, do not apply)**: Use Figma verbatim copy. If subtitle needs to be dynamic, add a `Mission.captureInstruction` field with the verbatim default.

### Issue 19 — Missing `'최대 4장까지 올릴 수 있어요'` hint — HIGH

- **Observation**: No hint copy between the dashed CTA and the disabled `제출` button.
- **Root cause**: Spec line 99 explicitly places the hint at y=658 between the upload area and submit button on the camera-prompt screen too — not only on photo-preview states.
- **Figma ref**: 11-mission.md line 99 ("Hint copy at y=658 center: `최대 4장까지 올릴 수 있어요` (14 Medium `#5F6165`)").
- **Fix (proposed, do not apply)**: Add hint `Text` styled `AppTypography.labelMedium.copyWith(color: AppColors.gray600)` above the disabled submit.

### Issue 20 — `_CameraCTA` height 200 vs spec ~156 — MEDIUM

- **Observation**: `Container(height: 200, ...)`.
- **Root cause**: Spec line 83 says "h≈156 (padded 52V/83H)". 200px makes the dashed box visually larger than Figma.
- **Figma ref**: 11-mission.md line 83.
- **Fix (proposed, do not apply)**: Reduce height to 156 OR drop the explicit height and let inner padding (52V) drive natural height.

### Issue 21 — Icon size 32 vs spec 24 — LOW

- **Observation**: `Icon(Icons.camera_alt_outlined, size: 32, color: gray700)`.
- **Root cause**: Spec line 84 says "camera icon (24) + label". 32px is 33% larger than design.
- **Figma ref**: 11-mission.md line 84.
- **Fix (proposed, do not apply)**: `size: 24`.

### Issue 22 — Inner column gap — OK

- **Observation**: `SizedBox(height: AppTokens.itemGap)` = 16px between icon and label.
- **Root cause**: Matches spec line 84 ("Inner column gap=16").
- **Fix**: None.

### Issue 23 — DottedBorder configuration — OK

- **Observation**: `DottedBorder(color: gray400, strokeWidth: 2, dashPattern: [6,4], borderType: RRect, radius: 8)`.
- **Root cause**: Matches spec line 83 ("dashed 2px border `#91969E`, radius 8") — `gray400 = #91969E`.
- **Fix**: None. Recent fix applied correctly.

### Issue 24 — Disabled BridgeButton — OK

- **Observation**: `const BridgeButton(label: '제출', onPressed: null)` → renders `gray200` bg + `gray300` text per `_resolvePalette` disabled branch.
- **Root cause**: Matches spec line 86 ("disabled state: bg `#D5D8DE`, text `#A7ACB2`").
- **Fix**: None.

---

## _PhotoPreviewView (frames 426-19035 / 426-18995 / 426-18974)

### Issue 25 — `Wrap` grid not enforcing 2-column layout — HIGH

- **Observation**: `Wrap(spacing: 12, runSpacing: 12, children: [...tiles, ...addTile])` with fixed-width `BridgePhotoTile` (157) and `BridgeAddPhotoTile` (157).
- **Root cause**: `Wrap` honors child intrinsic widths and packs left-aligned. For 1-photo state (1 tile + 1 add-tile = 2 children, both 157w + 12 gap ≈ 326 ≈ 327 content width), this renders as 1 row of 2 — OK. For 4-photo state (4 tiles, no add), this renders as 2 rows of 2 — OK. But for 3-photo state (3 tiles + 1 add = 4 children), spec line 153 wants `row 1: photo, photo / row 2: photo, add-tile`, which `Wrap` produces. Edge case: if devices have content widths <326, the second tile wraps to row 2 alone, breaking the grid.
- **Figma ref**: 11-mission.md lines 165-168 (4-photo "explicit 2×2 grid" — `grid-cols-2`).
- **Fix (proposed, do not apply)**: Replace `Wrap` with `GridView.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, ...)` OR a constrained `Row`+`Column` matrix to guarantee 2 columns regardless of available width.

### Issue 26 — Title typography mismatch — MEDIUM

- **Observation**: `Text(controller.mission.title, style: heading2Bold)`.
- **Root cause**: Same as Issue 17 — spec demands `heading1Bold` (24 SemiBold).
- **Figma ref**: Same as Issue 17. Spec line 81 applies to photo-preview screens too (header card carries over).
- **Fix (proposed, do not apply)**: `AppTypography.heading1Bold`.

### Issue 27 — Missing subtitle on photo-preview screens — MEDIUM

- **Observation**: Only title is rendered; no subtitle.
- **Root cause**: Spec line 124 ("Same screen, after 1 photo captured") implies the same title+subtitle block from 426-18960 is preserved — implementation drops the subtitle.
- **Figma ref**: 11-mission.md line 124 + spec line 97 (subtitle verbatim).
- **Fix (proposed, do not apply)**: Add subtitle below title with `bodyMedium / textSecondary`.

### Issue 28 — Hint copy styling — OK

- **Observation**: `labelMedium` + `gray600`.
- **Root cause**: Matches spec line 85.
- **Fix**: None.

### Issue 29 — Delete index correctness — OK

- **Observation**: `onDelete: () => controller.removePhoto(i)` captures loop index `i` correctly per iteration since the for-loop creates a fresh `i` per closure.
- **Fix**: None. Controller bounds-checks index too.

### Issue 30 — `BridgeAddPhotoTile` conditional visibility — OK

- **Observation**: `if (!controller.hasMaxPhotos) BridgeAddPhotoTile(...)`.
- **Root cause**: Matches spec line 173 ("Deleting any photo reveals the dashed add-more tile again") and line 170 ("Maximum photos reached; no more add-tile").
- **Fix**: None.

### Issue 31 — Submit gating — OK

- **Observation**: `onPressed: controller.canSubmit ? controller.submit : null`.
- **Root cause**: `canSubmit` = `photos.isNotEmpty`. Matches spec line 255 ("disabled when `photos.isEmpty`, primary otherwise").
- **Fix**: None.

### Issue 32 — Fixed 157×156 tiles overflow risk — LOW

- **Observation**: `BridgePhotoTile` width 157, height 156 hard-coded. On a content area of `screenWidth - 48` (pageHorizontal*2), 157*2+12=326 fits a 375-wide device (327 content) but on a 360-wide device (312 content) the second tile wraps.
- **Root cause**: Hard-coded sizes scale poorly. Figma 375 is canonical, but real devices vary.
- **Figma ref**: 11-mission.md line 124 ("Slot 1 = filled photo: 158×156", line 125 "Slot 2 = 'add more' 157×156").
- **Fix (proposed, do not apply)**: Use `LayoutBuilder` + `(maxWidth - gap) / 2` to compute tile width dynamically; keep aspect ratio.

### Issue 33 — `Image.file` errorBuilder — OK

- **Observation**: Falls back to a 157×156 gray200 box with `broken_image_outlined`.
- **Root cause**: Robust handling for stale paths (e.g., user revoked camera permission, file moved).
- **Fix**: None.

---

## _SubmittedView (frames 426-19052 / 426-19062, + speculative rejected)

### Issue 34 — Rejected branch is speculative / out-of-scope — HIGH

- **Observation**: `isRejected` branch renders `Icons.close` on `destructive` bg with `'미션 반려'` title and `'사진을 다시 확인해주세요.'` subtitle.
- **Root cause**: Spec line 232 explicitly states "No explicit `rejected` screen was provided in this batch". Implementation invented a UI without design approval, violating SuperClaude RULES.md "Scope Discipline" / "Build ONLY What's Asked".
- **Figma ref**: 11-mission.md lines 232, 285 (rejected flow flagged as open question, no node).
- **Fix (proposed, do not apply)**: Remove rejected branch OR file a design-system ticket requesting the rejected node. If kept as defensive scaffolding, mark with a `// TODO(design)` comment referencing the open question.

### Issue 35 — Icon 32px in 60px circle too large — MEDIUM

- **Observation**: `Container(width: 60, height: 60, ...)` with `Icon(iconData, size: 32)`.
- **Root cause**: Spec line 187 says check is `Vector81 centered (~33% inset)`. 33% inset means icon is ~67% of circle size = ~40px... actually re-reading: "centered (~33% inset)" suggests 33% padding all around = icon size 60*(1-0.66) ≈ 20px. Either reading puts 32px out of range.
- **Figma ref**: 11-mission.md line 187.
- **Fix (proposed, do not apply)**: Reduce to `size: 20` (or measure pixel from Figma export).

### Issue 36 — Reviewing icon hourglass on gray bg vs spec primary-blue check — MEDIUM

- **Observation**: `iconData = isCompleted ? Icons.check : (isRejected ? Icons.close : Icons.hourglass_empty)` — reviewing variant uses hourglass on `gray400`.
- **Root cause**: Spec line 187 ("primary blue circle `#3A99F8` (`Ellipse40`) with white check `Vector81` centered") describes the icon for 426-19052 (reviewing). Spec line 207 ("Completion icon: same primary-blue circle + white check (60×60)") confirms 426-19062 uses the SAME icon. Both states render identical icons; only title/subtitle differ.
- **Figma ref**: 11-mission.md lines 187, 207.
- **Fix (proposed, do not apply)**: Drop the hourglass variant. Use `Icons.check` + `primary` bg for both reviewing and completed states.

### Issue 37 — Missing topbar — MEDIUM

- **Observation**: `_SubmittedView` Scaffold has no `appBar`.
- **Root cause**: Spec line 182 ("Status bar + topbar `미션수행`") and line 199 (same for completed) both call out a topbar.
- **Figma ref**: 11-mission.md lines 182, 199.
- **Fix (proposed, do not apply)**: Add `appBar: BridgeAppBar(title: '미션수행', showBack: false)` or with `onBack: () => context.go('/child-home')` since spec line 218 says "No back from submitted — user must exit via 홈으로".

### Issue 38 — Vertical order reversed — LOW

- **Observation**: Layout order: `Spacer → icon (60) → SizedBox(24) → title → SizedBox(16) → subtitle → Spacer → button`.
- **Root cause**: Spec line 184 ("Centered container at y≈213, w=212, vertical gap=40 between text block and icon"), line 185-186 (text block first: title 24sb + subtitle 16m, gap 16). Implementation orders icon BEFORE text block; spec order is text-block first (or text-block ABOVE icon — re-reading "vertical gap=40 between text block and icon" the text-block precedes icon vertically per Figma export y-coords).
- **Figma ref**: 11-mission.md lines 184-187. Note: need visual confirmation via `mcp__figma__get_screenshot` to determine exact y-order; spec text is ambiguous on which comes first.
- **Fix (proposed, do not apply)**: Confirm with Figma screenshot; if text-block is at y=213 and icon below, reorder to `text-block → 40 gap → icon`. If icon is above (typical for "completion" UX), keep current order but ensure inter-block gap is 40, not 24.

### Issue 39 — `홈으로` navigation — OK

- **Observation**: `onPressed: () => context.go('/child-home')`.
- **Root cause**: Matches spec line 218 ("Bottom CTA → home").
- **Fix**: None.

### Issue 40 — Spacer centering — OK

- **Observation**: `Column` with `Spacer` top and bottom centers the content block vertically; button fixed at bottom (after second Spacer).
- **Fix**: None.

---

## MissionController flow & cross-cutting concerns

### Issue 41 — `Future.delayed(2s)` auto-approve memory safety — MEDIUM

- **Observation**: `submit({bool aiAutoApprove = true})` schedules `Future.delayed(const Duration(seconds: 2), () { if (_step == ... && _mission.status == ...) { _mission = ...; notifyListeners(); } })`. No `Timer` stored, no cancellation in `dispose`.
- **Root cause**: If the user pops `MissionInfoPage` (and thus the controller is disposed by `_MissionInfoPageState.dispose`) within 2s of submit, the delayed closure runs against a disposed `ChangeNotifier`. The state checks (`_step == submitted`) guard against logical state mutation, but `notifyListeners()` on a disposed notifier throws in debug mode (asserts `_debugAssertNotDisposed`).
- **Figma ref**: N/A — mock-implementation correctness.
- **Fix (proposed, do not apply)**: Store the timer (`Timer? _submitTimer = Timer(...)`) and cancel in `dispose()`. Add `if (_disposed) return;` guard. Consider exposing a `bool get isDisposed` flag.

### Issue 42 — System back from `submitted` step — LOW

- **Observation**: `goBack` is a no-op for `submitted`, but Android system back will pop the whole `MissionInfoPage` via go_router, bypassing `goBack`.
- **Root cause**: Spec line 218 says "user must exit via 홈으로". A `PopScope(canPop: false)` on `_SubmittedView` would enforce this.
- **Figma ref**: 11-mission.md line 218.
- **Fix (proposed, do not apply)**: Wrap `_SubmittedView` in `PopScope(canPop: false, onPopInvoked: ...)`.

### Issue 43 — Auto-transition addPhoto — OK

- **Observation**: `addPhoto` advances `perform`/`cameraPrompt` → `photoPreview` after successful capture.
- **Root cause**: Matches spec line 444 implicit flow ("on success the controller auto-transitions to `MissionFlowStep.photoPreview`").
- **Fix**: None.

### Issue 44 — `MissionMock.byId` silent fallback — LOW

- **Observation**: `firstWhere(..., orElse: () => all.first)` returns mission `'1'` (방청소 하기 pendingCheck) when id not found.
- **Root cause**: Silent fallback may mask routing bugs (e.g., wrong id passed from a card tap). User sees a different mission's data without warning.
- **Fix (proposed, do not apply)**: Throw or return `null`-able + page-level error state.

### Issue 45 — Redundant AnimatedBuilder over InheritedNotifier — LOW

- **Observation**: `MissionScope` extends `InheritedNotifier<MissionController>` (rebuilds dependents on notify). `MissionInfoPage` wraps `MissionScope`'s child in `AnimatedBuilder(animation: _controller, ...)` which also rebuilds on notify.
- **Root cause**: Both mechanisms drive rebuilds. The `AnimatedBuilder` is necessary because the SWITCH on `_controller.step` is OUTSIDE the child tree (it picks the child), so `InheritedNotifier`'s rebuild wouldn't affect the parent. Verdict: actually needed.
- **Fix**: None — defensible as-is, but worth a comment explaining why both exist.

---

## Cross-view structural concerns

1. **Flow-step vs tab-state conflation** (Issues 1, 11): The controller models `info` and `perform` as separate steps; spec models them as tab states of one screen. Resolution requires refactoring `MissionFlowStep` enum (drop `perform`, keep tabs inside `_InfoView`).
2. **Title source of truth** (Issues 3, 5, 17, 26): The mission title (`방청소 하기`) appears in different forms across views — appbar literal vs in-body card vs body heading. Spec consistently places it in the topbar for info screen and as `heading1Bold` body title for camera/preview screens.
3. **Subtitle persistence** (Issues 18, 27): `깨끗해진 방을 찍어서 올려주세요!` should persist from camera-prompt through all photo-preview states; currently dropped after the prompt screen.
4. **Hint copy persistence** (Issue 19): `최대 4장까지 올릴 수 있어요` should appear on camera-prompt AND preview screens; currently only on preview.
5. **Submitted icon unification** (Issue 36): Reviewing and Completed states share the same primary-blue check icon per spec; do not differentiate by hourglass/gray.
6. **Speculative rejected UI** (Issue 34): Remove or flag as out-of-scope per spec line 232.

---

## Open questions (forwarded to design)

1. Confirm `AssignedByChip` is NOT part of `746-11392` (Issue 3) — current implementation adds it speculatively.
2. Confirm topbar title for info screen is the dynamic `mission.title` (`방청소하기`), not literal `미션 정보` (Issue 5).
3. Confirm vertical order on `_SubmittedView`: text-block above or below the 60×60 icon? Spec text is ambiguous (Issue 38).
4. Confirm `미션수행` (no space) vs `미션 수행` (space) for the perform/camera/preview topbar (Issue 16).
5. Provide a Figma node for the rejected state (Issue 34, spec line 232 / line 285 open follow-up).
