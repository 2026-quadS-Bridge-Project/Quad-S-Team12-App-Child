# Audit: 시간 설정 v2 (Edit Flow) — Layout & Behavior

**Target file**: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_v2_root_page.dart`
plus v2-aware behavior in the shared sub-pages:
- `lib/features/time_setup/presentation/pages/time_setup_intro_page.dart`
- `lib/features/time_setup/presentation/pages/schedule_register_page.dart`
- `lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`
- `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`
- `lib/features/time_setup/presentation/pages/time_setup_complete_page.dart`
- `lib/features/time_setup/state/time_setup_controller.dart`
- `lib/core/widgets/layout/bridge_week_row.dart`
- `lib/core/widgets/feedback/bridge_delta_banner.dart`

**Figma reference**: spec `docs/figma-specs/09-time-v2.md` (9 nodes, fileKey `tzJjQmXtXO7vGlfCT9SASu`; sample nodes `750:13034` intro, `750:12671` step 1, `750:13686` step 3 error 초과, `750:13624` complete).

**Scope**: read-only diagnostic — DO NOT FIX. Audit format mirrors `_audit-layout/01-BridgeAppBar.md` with CoT (Observation → Root cause → Figma ref → Recommended fix).

---

## Issue 1: v2 entry constructor seeds intro step correctly, but intro page never re-seeds previousWeek if reset/replayed

### Observation
- `time_setup_v2_root_page.dart:37–40` constructs `TimeSetupController.v2NextWeek(previousWeek: TimeScheduleMock.sampleFilled)`.
- `time_setup_controller.dart:27–30` confirms the named constructor sets `_schedule = previousWeek`, `_mode = TimeSetupMode.v2NextWeek`, and `_step = TimeSetupStep.intro`. All three v2 invariants are honored on first build.
- `showPastWeekDim` correctly returns `_mode == TimeSetupMode.v2NextWeek` (line 39).
- `reset()` (line 145–149) hard-resets `_schedule = TimeScheduleMock.empty` and `_step = TimeSetupStep.scheduleRegister`. There is **no** v2-aware reset that preserves `previousWeek` or returns to `intro`. If anything ever calls `controller.reset()` while in v2 mode, the wizard silently drops back into a v1-empty state without changing `_mode`, leaving `showPastWeekDim == true` but `_schedule.weeklyTotals` all zero — a degenerate UI.
- `time_setup_v2_root_page.dart` discards the constructor's `previousWeek` after init; the controller never stores it separately. There is no way to recover the previous-week data once `setWeeklyTotal` overwrites a row.

### Root cause
The controller treats `_schedule` as a single mutable model for both "previous week reference" and "this week edits". Per spec §v2-3 the past-week row (`1주차`, opacity 0.2) must display the **previous** week's allocated hours alongside editable rows for weeks 2–4. The current model collapses both into one `weeklyTotals` list, so once the user edits `weekIndex: 0` the historical record is destroyed. This is flagged in `weekly_time_setup_page.dart:88-91` (`TODO: source previous-week values from a dedicated controller.previousWeekSchedule once v2 separates past vs current schedule.`).

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-3 (frame `750:11991`): "1주차 (opacity 0.2 — past) ... Row 1 already shows `15 시간 00 분`. Past week 1 row appears at the *top of the list* with its used hours `15 시간 00 분` rendered at 20% opacity (immutable record)." Lines 145, 470 reinforce "Historical immutability via opacity" as a *signature v2 pattern*.

### Recommended fix (do not apply now)
1. Add `final TimeSchedule? _previousWeek;` to the controller, populated by the `v2NextWeek` constructor and exposed via `TimeSchedule? get previousWeek`.
2. Make `reset()` mode-aware: if `_mode == v2NextWeek`, reset back to `intro` and re-seed `_schedule = _previousWeek!` instead of `empty`.
3. In `weekly_time_setup_page.dart` line 92–98, source the "지난 주" row from `controller.previousWeek?.weeklyTotals` (a specific week, not the aggregate) so the dimmed row reflects the immutable historical value rather than the live `_schedule` total.

---

## Issue 2: Intro page content does not match spec §v2-1 (heading, subtitle, step labels, missing subtitle line)

### Observation
- `time_setup_intro_page.dart:24–28` defines step rows as:
  - `(number: 1, label: '① 사용할 시간을 등록해요')`
  - `(number: 2, label: '② 주별 사용 시간을 정해요')`
  - `(number: 3, label: '③ 일별 사용 시간을 분배해요')`
- Spec §v2-1 (line 23) requires verbatim: `1 스케줄 등록`, `2 주별 시간 분배`, `3 일별 시간 분배` — three short noun phrases, no encircled-digit prefix (the circled glyph is a duplicate of `BridgeStepCircle(number: number)` already rendered on line 86).
- The heading on `time_setup_intro_page.dart:45` is `'Hi! 다음주 시간 계획을 짜볼까요?'`. Spec §v2-1 heading is `사용시간 설정` (line 22) with a two-line subtitle `저번주 피드백을 고려해서 / 더 나아진 이번주 계획을 짜봐요!`. The current implementation collapses heading+subtitle into one informal English greeting and **omits the subtitle entirely**.
- Step rows use `AppTypography.bodyMedium` with `gray600`. Spec §v2-1 typography (line 37) requires Pretendard SemiBold 18 / Headline-Bold for step labels.
- Step layout uses `SizedBox(height: 12)` separator (line 56). Spec line 16 specifies `gap=20` between step rows in a `w=140` centered container.
- The container itself is `stretch`-aligned full width (line 41) with 24px horizontal padding. Spec places the steps container `top=368, w=140, center` — a *narrow centered* column, not full-width stretch.

### Root cause
Intro page was implemented from memory / placeholder copy rather than from the §v2-1 figma block. Three independent deviations:
1. **Copy**: wrong heading, missing subtitle, wrong step labels (added "①②③" decorative prefix that duplicates the existing `BridgeStepCircle`).
2. **Typography**: step label uses `bodyMedium` (14) instead of `headlineBold` (18).
3. **Layout**: full-width stretched rows instead of a 140-wide centered column with 20px gaps.

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-1 lines 12–39 — full layout, copy, typography, and color spec for the intro screen.

### Recommended fix (do not apply now)
- Heading → `'사용시간 설정'` using `AppTypography.heading1Bold` + `AppColors.inkBlack`.
- Add subtitle `'저번주 피드백을 고려해서\n더 나아진 이번주 계획을 짜봐요!'` using `AppTypography.bodyMedium` + `AppColors.gray500`.
- Step labels → `'스케줄 등록'`, `'주별 시간 분배'`, `'일별 시간 분배'` (drop the encircled-digit prefix entirely; `BridgeStepCircle` already renders the number).
- Step label typography → `AppTypography.headlineBold` (SemiBold 18) + `AppColors.gray500`.
- Restructure to a `w=140` centered column with `gap=20` between rows.

---

## Issue 3: weekly_time_setup_page past-week row sources from aggregate `totalWeeklyHours`, breaking the immutable-historical-record pattern

### Observation
- `weekly_time_setup_page.dart:87–100` renders the dimmed past-week row using `controller.schedule.totalWeeklyHours` / `totalWeeklyMinutes` (the *aggregate* across all 4 weeks).
- The inline comment at 88–91 acknowledges the bug: `TODO: source previous-week values from a dedicated controller.previousWeekSchedule once v2 separates past vs current schedule. For now the row displays the aggregate total; opacity provides the visual cue per spec.`
- The label is hardcoded `'지난 주'` while spec uses `'1주차'` at opacity 0.2 above rows labeled `2주차`/`3주차`/`4주차` (spec §v2-3 line 116).
- The row is rendered *above* the 4 editable rows (lines 87–113), but the 4 editable rows are labeled `1주차`/`2주차`/`3주차`/`4주차` (line 103: `'${i + 1}주차'`). This produces a duplicate `1주차` label visually inconsistent with spec §v2-3 which has exactly 4 weekly rows (`1주차` locked + `2/3/4주차` editable). The current implementation produces **5 rows total**: `지난 주` (dimmed aggregate) + `1주차`/`2주차`/`3주차`/`4주차` (all editable).

### Root cause
Two compounding issues:
1. No data model for "previous week" separate from "current weeks" (see Issue 1).
2. The page treats v2 as "add a dimmed top row above the v1 layout" instead of "the first of 4 weekly rows becomes locked + dimmed". The Figma intent is that `1주차` *is* the past week (immutable record); editable rows are `2/3/4주차`. The current Flutter UI shows 5 rows where spec shows 4.

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-3 lines 116, 145, 469–471 — "4 weekly rows (h=50 each, gap=8): `1주차` (opacity 0.2 — past), `2주차/3주차/4주차` (opacity 0.8)". Row 1 is the past week; row count is 4, not 5.

### Recommended fix (do not apply now)
- Eliminate the separate "지난 주" row.
- When `controller.showPastWeekDim`, render `BridgeWeekRow` for `i == 0` with `isPast: true`, `onTap: null`, and `weekLabel: '1주차'`, sourcing hours/minutes from `controller.previousWeek?.weeklyTotals[0]` (after Issue 1 fix).
- Render `i == 1..3` as editable rows with labels `2주차`/`3주차`/`4주차`.
- Total row count = 4, matching spec.

---

## Issue 4: daily_time_setup_page v2 pill buttons render wrong variant + wrong order + wrong navigation targets

### Observation
- `daily_time_setup_page.dart:78–98` conditionally renders two `BridgePillIconButton` widgets when `controller.showPastWeekDim`:
  - `사용리포트 보기` with `Icons.arrow_forward` + `variant: BridgePillVariant.ghost` → routes to `/child-home/report`
  - `스케줄 보기` with `Icons.arrow_forward` + `variant: BridgePillVariant.ghost` → routes to `/child-home`
- Both pills are placed in a `Row` with `mainAxisAlignment: MainAxisAlignment.end`, with `사용리포트 보기` *before* `스케줄 보기`.
- Spec §v2-6 (line 260–261, 290) places `스케줄 보기 ›` *first*, then `사용리포트 보기 ›` *second*, both styled with bg `#EBF5FE` (primary tonal) + text `#3A99F8` (primary).
- The `ghost` variant in `bridge_pill_icon_button.dart:122–128` resolves to `background: Colors.transparent` + `foreground: AppColors.gray600` — completely opposite to spec which requires the tonal primary palette (`primaryLight` bg + `primary` text), available via `BridgePillVariant.tonal` (lines 115–121).
- `스케줄 보기` navigates to `/child-home`, but per spec §v2-6 lines 301–302 it should "open prior schedule reference (read-only modal)" — i.e. show last week's grid in-flow, not exit the wizard. Routing to `/child-home` *destroys the wizard state* (no `pop` available to resume).
- These buttons are placed *next to the total summary card* (between lines 75 and 99). Spec §v2-6 places them inside the "Daily Distribution Container" header row, attached to the title `일별 시간 분배 ` (line 258–261).

### Root cause
1. Wrong `BridgePillVariant` chosen — `ghost` (transparent neutral) instead of `tonal` (primary-light tinted).
2. Order swapped (`사용리포트 보기` rendered first instead of `스케줄 보기`).
3. Navigation semantics wrong — `context.push('/child-home/report')` and `context.push('/child-home')` push new routes onto the stack rather than open lightweight reference modals; tapping either button exits the wizard.
4. Placement above the day list instead of inside the day-list header row.

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-6 lines 258–261, 280, 290, 301–302; cross-screen §v2-only patterns line 477.

### Recommended fix (do not apply now)
- Change variant to `BridgePillVariant.tonal` (verify `bridge_pill_icon_button.dart:115–121` produces `primaryLight`/`primary` palette matching spec).
- Swap order: `스케줄 보기` first, then `사용리포트 보기`.
- Replace `context.push('/child-home/...')` with bottom-sheet / dialog presenters that show the previous week's grid (`controller.previousWeek!.allowedHours`) and last week's report inline without leaving the wizard.
- Move the pill `Row` into a header `Row` adjacent to a `일별 시간 분배` section title above the day list.

---

## Issue 5: complete page hardcoded to single copy variant — controller `_mode` ignored despite spec calling for "이번주" v2-specific wording

### Observation
- `time_setup_complete_page.dart:26–27` hardcodes:
  - title `'시간 설정 완료!'`
  - body `'이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!'`
- The page does not consume `TimeSetupScope.of(context)` at all — no controller injection.
- Inline comment on lines 21–25 explicitly states: "Per Figma spec (09-time-v2.md frame 750-13624) and audit phase 5: v2-9 copy is identical to v1 — ... Controller mode is no longer used to gate copy; both v1 and v2NextWeek share the same completion strings."
- Spec §v2-9 lines 391–408 confirm v2 copy: title `시간 설정 완료!`, body `이번주 시간 계획이 부모님께 전달되었어요. / 이제 계획대로 사용해봐요!`. The "differs from v1" note on line 408 says v2 uses "week-scoped + parent-share confirmation" rather than the v1 monthly framing.
- The audit task spec line 4 ("Complete page mode-conditional copy — currently unified per recent fix (audit Phase 5)") confirms this is intentional. **However**, the v1 spec (`08c-time-v1-errors-done.md`) is not loaded here; if v1's "완료" screen actually expected month-scoped copy (`이번달 ...`) then unifying to v2 copy on v1 produces a v1 regression. Worth re-validating against `08c-time-v1-errors-done.md`.

### Root cause
Intentional unification per audit phase 5. Risk: v1 path now displays v2-flavored "이번주" copy regardless of whether the v1 flow was originally month-scoped. The mock fixture `TimeScheduleMock.sampleFilled` uses 4-week (month) totals (`time_schedule_mock.dart:31–44`), implying v1 frames a month — but the complete screen says "이번주" for both, which is semantically inconsistent with the v1 data model.

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-9 lines 389–408 (v2 copy). v1 complete-screen copy is in `docs/figma-specs/08c-time-v1-errors-done.md` (not re-read in this audit; cross-check before changing).

### Recommended fix (do not apply now)
- If v1's complete screen *also* uses "이번주" per `08c`, leave as-is and note unification is correct.
- If v1 uses month-scoped copy (`이번달 ...`), re-introduce mode gating: inject `TimeSetupScope.of(context)`, then `final body = controller.mode == TimeSetupMode.v2NextWeek ? '이번주 ...' : '이번달 ...';`.

---

## Issue 6: error frame border (1.2px destructiveBorderSoft / primary) is NOT implemented — banner-only fallback used

### Observation
- Spec §v2-6 lines 263, 281–282, 296: a 1.2px rounded-8 border wraps the daily-rows area: `#FF7878` (destructive) for over-budget, `#3A99F8` (primary) for under-budget. Token already defined: `AppColors.destructiveBorderSoft = Color(0xFFFF7878)` in `app_colors.dart:54`.
- Cross-reference grep: `destructiveBorderSoft` is referenced **only at its declaration site** — no consumer in any widget (verified via Grep over `lib/`).
- `daily_time_setup_page.dart:100–123` wraps the day rows in a plain `Expanded > ListView` with **no `Container(decoration: BoxDecoration(border: ...))`** around it. There is no conditional border based on `controller.isOverBudget` / `controller.isUnderBudget`.
- The over/under feedback is delivered solely by `BridgeDeltaBanner.over()` / `.under()` placed *below* the list (lines 124–136). `bridge_delta_banner.dart:97–122` renders a full-width pill with `destructiveSubtle`/`primaryLight` bg + colored text — this is a *separate* component documented per `08c-time-v1-errors-done.md` (frames 695:10675 / 695:10817), **not** the v2 frame-border treatment from §v2-6/v2-7.
- Spec §v2-7 lines 324–326 require the under-budget variant to use `#E1F0FE` (primarySoft / `primary025`) bg + `#3A99F8` text + `#3A99F8` 1.2px border. The implementation uses `primaryLight` (`#EBF5FE`) for the banner bg, which is a different token (`primary050`), and skips the border entirely.

### Root cause
Two distinct v2-specific affordances are conflated under one component:
1. **Footer chip + bordered frame** = v2 §v2-6/v2-7 dual-tone error surface (chip *and* border around rows).
2. **Banner** = v1 §08c footer (chip only, no border).

The current implementation reuses (2) for both v1 and v2 and never builds (1). The tokens are wired up (`destructiveBorderSoft`, `primarySoft`) but no widget consumes them.

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-6 lines 263, 281–282; §v2-7 lines 322–326; cross-screen §v2-specific patterns line 476 ("Error surfaces are dual-tone").

### Recommended fix (do not apply now)
- When `controller.showPastWeekDim && (isOverBudget || isUnderBudget)`, wrap the `Expanded > ListView` of day rows in a `Container` with:
  - `border: Border.all(width: 1.2, color: isOver ? AppColors.destructiveBorderSoft : AppColors.primary)`
  - `borderRadius: BorderRadius.circular(8)`
- Switch the under-budget banner bg to `AppColors.primarySoft` (`#E1F0FE`) when in v2 mode, distinct from v1's `primaryLight` (`#EBF5FE`). This requires extending `BridgeDeltaBanner` or passing an override.
- Consider extracting a `BridgeErrorFrame` wrapper widget so the border + chip pair stays tightly coupled.

---

## Issue 7: SafeArea / Scaffold pattern is consistent with v1, but intro page omits a fixed top spacer that v1 sub-pages include

### Observation
- v1 root: `time_setup_root_page.dart:39–59` — single `AnimatedBuilder` returning a switch over `step`. Identical pattern in v2 root (`time_setup_v2_root_page.dart:49–66`). ✓ consistent.
- All sub-pages use `Scaffold(backgroundColor: AppColors.background, appBar: BridgeAppBar(...), body: SafeArea(child: Padding(...)))` ✓ consistent.
- Intro page padding: `EdgeInsets.fromLTRB(24, 0, 24, 24)` (`time_setup_intro_page.dart:39`) with `const SizedBox(height: 32)` first child (line 43).
- Other sub-pages use `EdgeInsets.fromLTRB(24, 16, 24, 24)` (weekly: line 49–54) or `EdgeInsets.symmetric(horizontal: 24)` + first `SizedBox(height: 16)` (daily: lines 56–61). The intro page's `top: 0` + `SizedBox(height: 32)` is functionally equivalent to `top: 32`, but pattern-wise the other pages use `top: 16` + smaller spacers.
- More critically: `time_setup_complete_page.dart:29` uses `backgroundColor: AppColors.gray050` while every other sub-page uses `AppColors.background` (which is also `gray050` per `app_colors.dart:27`). Functionally identical, stylistically inconsistent — the explicit `gray050` reference circumvents the semantic `background` alias.
- Complete page also omits `BridgeAppBar` entirely (no back affordance), which is *correct* per spec §v2-9 line 384–390 (terminal screen, back arrow exists but is system-rendered).

### Root cause
Minor cosmetic drift between page implementations. No functional impact. Listed for completeness because the task spec called for consistency validation.

### Figma reference
`docs/figma-specs/09-time-v2.md` §v2-1 lines 13–18 (intro layout with `top=205` for the title, not 32); §v2-9 line 384 (no BridgeAppBar on complete).

### Recommended fix (do not apply now)
- Replace `AppColors.gray050` on `time_setup_complete_page.dart:29` with `AppColors.background` for consistency.
- Align intro padding to `EdgeInsets.fromLTRB(24, 16, 24, 24)` to match sibling pages, *or* rewrite to match the spec's `top=205` centered-stack layout (the spec is fundamentally a centered hero layout, not a top-anchored column).

---

## Issue 8: Routing — `/child-home/time-setup/v2` is reachable from report footer CTA but NOT from notification `n2`

### Observation
- `app_router.dart:73–77` declares the route correctly.
- `report_page.dart:62–68` — `BridgeButton(label: '다음주 계획 짜러가기 →', ..., onPressed: () => context.push('/child-home/time-setup/v2'))`. ✓ wired.
- `notifications_page.dart:117–124` — `NotificationCard(item: item, onTap: () {}, ...)`. **All notification taps are no-op closures.** There is no per-type routing.
- `notifications_mock.dart:8–30` defines three seeded items:
  - `mission-completed` (NotificationType.missionCompleted)
  - `mission-confirmation-requested` (NotificationType.missionConfirmationRequested)
  - `time-configured` (NotificationType.timeConfigured)
- None of these maps to a "next-week schedule" notification (n2 in the audit task spec). The category does not exist in the mock at all.
- Grep for `time-setup/v2` across `lib/features/notifications/` returns no matches — confirmed not wired.

### Root cause
The notification system has no per-type tap router, and the mock does not contain an n2-style "다음주 시간을 등록해주세요" notification. Either:
1. The audit task spec assumed a notification type that was never added to the mock seed, OR
2. The intended dispatch logic (notification → route) was deferred.

### Figma reference
Notification spec lives in `docs/figma-specs/06-notifications.md` (not re-read here). The v2 entry route is documented in `docs/figma-specs/09-time-v2.md` §v2-1 line 45 ("`시작` → push v2-2") and the **prior** transition (from notification or report) is implied but not enumerated in §v2.

### Recommended fix (do not apply now)
1. Add a `NotificationType.nextWeekScheduleRequested` (or similar) enum value.
2. Seed `notifications_mock.dart` with an n2-style item using that type.
3. In `notifications_page.dart:121`, replace `onTap: () {}` with a `_handleTap(item)` dispatcher that switches on `item.type`:
   - `nextWeekScheduleRequested` → `context.push('/child-home/time-setup/v2')`
   - `timeConfigured` → `context.push('/child-home/time-setup/confirm')` (or `/child-home/report`)
   - others → no-op or report.
4. Cross-reference `docs/figma-specs/06-notifications.md` to confirm the canonical n2 copy + icon and type.

---

# Cross-issue synthesis

## Severity ranking
| # | Severity | Domain | Impact |
|---|---|---|---|
| 1 | 🟡 IMPORTANT | State model | `previousWeek` lost on first edit; `reset()` corrupts v2 state |
| 2 | 🟡 IMPORTANT | Copy + typography | Intro screen does not match spec (all 4 dimensions: heading, subtitle, labels, typography) |
| 3 | 🟡 IMPORTANT | Layout | 5 rows rendered vs spec's 4; duplicate `1주차` label |
| 4 | 🟡 IMPORTANT | Pills + nav | Wrong variant, wrong order, navigation destroys wizard |
| 5 | 🟢 RECOMMENDED | Copy gating | Mode-conditional copy removed; verify v1 spec alignment |
| 6 | 🟡 IMPORTANT | Visual feedback | `destructiveBorderSoft` token defined but unused — error frame border missing |
| 7 | 🟢 RECOMMENDED | Style consistency | `gray050` vs `background` alias drift |
| 8 | 🟡 IMPORTANT | Routing | n2 notification tap is no-op; route reachable only from report footer |

## Top-3 priorities
1. **Issue 4** — daily pills render wrong variant + wrong nav targets, breaking the wizard's mid-flow reference-data pattern (a v2-only signature affordance per spec §v2-only patterns #7).
2. **Issue 6** — `destructiveBorderSoft` is wired into tokens but never consumed; error-frame border is the most visually distinctive v2-only affordance per spec §v2-only patterns #6 and is currently absent.
3. **Issue 1+3** (tightly coupled) — `previousWeek` is not preserved in controller state, so the dimmed past-week row in `weekly_time_setup_page.dart` displays the live aggregate (not the historical snapshot), producing 5 rows where spec shows 4 and losing the "historical immutability" signature pattern (§v2-only patterns #3).
