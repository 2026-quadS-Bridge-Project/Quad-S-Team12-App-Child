# 13 — Layout Audit: Time Setup v1 Wizard (Diagnostic Only)

Scope: 7 pages under `lib/features/time_setup/presentation/pages/` that
compose the initial v1 time-setup wizard. Cross-referenced against Figma
spec docs 08a / 08b / 08c (file `tzJjQmXtXO7vGlfCT9SASu`).

Reading audited:
- `time_setup_root_page.dart`
- `time_setup_intro_page.dart`
- `schedule_register_page.dart`
- `weekly_time_setup_page.dart`
- `daily_time_setup_page.dart`
- `time_setup_review_page.dart`
- `time_setup_complete_page.dart`

Controller: `lib/features/time_setup/state/time_setup_controller.dart`.

Audit checks per page:
1. SafeArea / Scaffold composition
2. BridgeAppBar back wiring (Scaffold.appBar vs inline)
3. BridgeStepperPills currentStep ↔ controller.stepIndex alignment
4. BridgeStepHeader copy verbatim
5. Page-specific controls
6. Bottom CTA gating (canProceed)
7. Back nav semantics (goToStep vs context.pop)

CoT format per issue: Observation → Root cause → Figma ref → Fix.

---

## time_setup_root_page

Thin orchestrator. Only renders the current step from
`TimeSetupController.step`. No appbar, no SafeArea (each child page owns
its own Scaffold). Findings concern the routing semantics rather than
layout.

### Issue 1 — `TimeSetupStep.intro` collapses silently into `scheduleRegister`

- **Observation**: lines 49–50 map both `intro` and `scheduleRegister`
  to `const ScheduleRegisterPage()`. The doc comment (lines 46–48)
  explicitly states v1 should never enter `intro`, but if the state ever
  does land there the user sees Step 1 directly with no warning.
- **Root cause**: defensive fallback chosen for switch exhaustiveness.
  `TimeSetupIntroPage` is never referenced anywhere in the v1 root —
  even though the page file exists in this directory.
- **Figma ref**: 08a `695:8850` (시간 설정 진입) IS the intended pre-step
  splash. v1 spec calls for back chevron + `사용시간 설정` heading +
  3-step legend + `시작` CTA. Per 08a §"시간 설정 진입": frame is part of
  initial flow ("진입 → 스케줄 등록 → ...").
- **Fix (DO NOT APPLY)**: route `TimeSetupStep.intro` to
  `const TimeSetupIntroPage()` instead of `ScheduleRegisterPage()`. Then
  decide at construction time whether v1 should start at `intro` (per
  Figma 08a 695:8850) or stay on `scheduleRegister`. The current
  `_controller = TimeSetupController(initial: widget.initial)` defaults
  `_step` to `scheduleRegister` (controller.dart:33), so v1 skips intro
  entirely. Either remove `TimeSetupIntroPage` from v1 scope (and delete
  the unused mapping) or wire v1 to start on `intro`.

### Issue 2 — No `WillPopScope` / `PopScope` around the wizard shell

- **Observation**: `build()` returns `TimeSetupScope` → `AnimatedBuilder`
  → step page. No `PopScope` intercepts the Android system back gesture,
  so a back swipe from Step 3 pops the entire route instead of stepping
  back to Step 2.
- **Root cause**: each sub-page handles its own back via
  `BridgeAppBar.onBack`, but the OS-level back gesture bypasses that.
- **Figma ref**: 08a/08b/08c all show only an inline topbar back chevron
  — system back behaviour isn't specified, but UX consistency demands
  back ⇒ previous step.
- **Fix (DO NOT APPLY)**: wrap the body in `PopScope(canPop: ...)` that
  calls `controller.goToStep(previous)` when not on the first step.

---

## time_setup_intro_page

v2-only splash per its own doc comment, but the file lives in v1 scope.
Audited against 08a 695:8850.

### Issue 1 — Copy diverges from Figma 695:8850 verbatim

- **Observation**: lines 24–28 hard-code list items as
  `'① 사용할 시간을 등록해요'`, `'② 주별 사용 시간을 정해요'`,
  `'③ 일별 사용 시간을 분배해요'`, plus title
  `'Hi! 다음주 시간 계획을 짜볼까요?'`.
- **Root cause**: page was written for v2 (per the doc comment
  referencing 09-time-v2.md frame `750:13034`), reusing the legacy
  intro pattern with new copy.
- **Figma ref**: 08a 695:8850 — title `사용시간 설정`, subtitle
  `한 달 동안 쓸 시간을, 스스로 나눠볼거에요` / `3단계만 따라오면 끝나요`,
  step labels `스케줄 등록` / `주별 시간 분배` / `일별 시간 분배`. CTA
  `시작`. If this page is ever wired into v1 the copy will not match.
- **Fix (DO NOT APPLY)**: either rename / move the file out of v1 scope
  (it is a v2 page) or add a `mode` switch on the strings keyed to
  `controller.mode`. Today the page is dead code in v1 — `root_page`
  never reaches `TimeSetupStep.intro`.

### Issue 2 — Title hierarchy collides with BridgeStepHeader styling

- **Observation**: line 46 uses `AppTypography.heading1Bold`
  (Pretendard SemiBold 24). The Figma 695:8850 title `사용시간 설정`
  is Heading1/Bold centered, but this implementation renders left-aligned
  inside a `Column` with `crossAxisAlignment: CrossAxisAlignment.stretch`.
- **Root cause**: no `textAlign: TextAlign.center` and no `Center`
  wrapper; the Text just inherits the cross-axis stretch.
- **Figma ref**: 08a 695:8850 §"Texts" — title node `695:8857` has
  `text-align center` per spec table row (Heading1/Bold, centered).
- **Fix (DO NOT APPLY)**: set `textAlign: TextAlign.center` and wrap in
  `Center(child: ...)` or change column alignment.

### Issue 3 — Subtitle missing entirely

- **Observation**: between title (line 44) and step list (line 51)
  there is only `SizedBox(height: 16)`. No subtitle Text widget.
- **Root cause**: implementation skipped the 2-line subtitle.
- **Figma ref**: 08a 695:8850 — subtitle node `695:8858`:
  `한 달 동안 쓸 시간을, 스스로 나눠볼거에요` (line 1) /
  `3단계만 따라오면 끝나요` (line 2), Body/Medium gray500.
- **Fix (DO NOT APPLY)**: insert a Body/Medium gray500 2-line text
  between title and step list, gap 40 per Figma.

---

## schedule_register_page

Step 1 — 7×17 hour-of-day grid. Audited against 08a `695:8924` (empty)
and `695:9115` (filled).

### Issue 1 — Back chevron escapes the wizard instead of going to intro

- **Observation**: lines 40–43 wire `BridgeAppBar.onBack` to
  `context.go('/child-home')`. This unconditionally exits the wizard
  and routes to the child home, even though Figma defines a pre-step
  intro screen.
- **Root cause**: a hard-coded escape route was chosen because no intro
  page is wired into v1. There is no `controller.goToStep(TimeSetupStep.intro)`
  call and no confirmation prompt before discarding the user's grid
  selections.
- **Figma ref**: 08a 695:8924 §"Interactions" — "Back chevron | Pop to
  entry (`695:8850`)". The intended target is the intro page, not the
  home.
- **Fix (DO NOT APPLY)**: route back to intro (once wired) via
  `controller.goToStep(TimeSetupStep.intro)`, OR show a dismiss
  confirmation sheet before discarding work. If wizard truly should
  bail to home, gate it behind a confirmation dialog because the
  controller state is destroyed on route pop.

### Issue 2 — `currentStep: controller.stepIndex` couples Step 1 visual to step enum but Figma uses gray150 (not primary) for the active pill in this batch

- **Observation**: line 68 sets `currentStep: controller.stepIndex`,
  which evaluates to `1` for `TimeSetupStep.scheduleRegister`. The
  `BridgeStepperPills` widget renders the current pill in
  `AppColors.primary` (bridge_stepper_pills.dart:50). Past pills use
  `primarySubtle` (lighter blue).
- **Root cause**: widget palette (primary for current, primarySubtle
  for completed) does not match the Figma spec for v1.
- **Figma ref**: 08a 695:8924 §"Colors" — active pill is
  `#C2DFFD` (`primarySubtle`), inactive `#EDEEF1` (`gray150`). Spec
  table on line 100: "Step 1 active = `#C2DFFD`, others = `#EDEEF1`".
  Also 11870 §"Layout" line 240: "Pill 1 = gray150 (Step 1 complete
  but unhighlighted)" — i.e. completed pills should be **gray150**,
  not blue. The widget inverts this.
- **Fix (DO NOT APPLY)**: align `BridgeStepperPills` palette to Figma:
  completed=gray150, current=primarySubtle, upcoming=gray150. Or
  parameterize the colors and let each page override.

### Issue 3 — Title copy diverges from Figma

- **Observation**: line 75 renders title
  `'핸드폰 사용 가능한 시간을 선택해주세요'` and description
  `'학교, 학원 시간 등 사용이 어려운 시간을 제외하고\n선택해주세요.'`.
- **Root cause**: a paraphrased UX copy was used.
- **Figma ref**: 08a 695:8924 §"Texts" — title node `695:8932` is
  `스케줄 등록`; description node `695:8935` is
  `학교, 학원처럼 휴대폰을 거의 못 쓰는 시간을 등록해서` /
  `사용가능한 시간을 편하게 확인해요`.
- **Fix (DO NOT APPLY)**: replace title with `'스케줄 등록'` and use
  the verbatim 2-line description from the spec.

### Issue 4 — Hour mapping fragile under future grid resize

- **Observation**: lines 32–33 hard-code `_visibleHourBase = 7` and
  the page does the +/-7 translation inline. `BridgeTimeGrid` reports
  row indices 0..16; controller stores literal hours 7..23.
- **Root cause**: mapping logic lives in the page rather than the
  grid or the controller, so any change to the visible hour range
  (e.g. start at 6) requires editing two files.
- **Figma ref**: 08a 695:8924 §"hour labels" `695:9093` — hour axis
  is 7,8,9,…,12,1,…,12 (so 17 cells starting at hour 7, ending at
  hour 23). Mapping itself is correct today.
- **Fix (DO NOT APPLY)**: encapsulate hour-base inside
  `BridgeTimeGrid` (expose a `startHour` parameter) or move it into
  the controller, so the page reads/writes literal hours only.

### Issue 5 — `BridgeStepperPills` rendered inside Padding 24h but Figma centers within full width

- **Observation**: lines 67–71 wrap pills in `Center(...)` inside the
  page-padded `Column`. Padding is 24h (line 62). Effective width is
  327; the pill row is 185 wide centered within 327.
- **Root cause**: layout is fine for the pills themselves but the
  vertical offset is 16 from topbar (line 62 top=16). Figma shows
  pills at y=66.5 within page, which equals topbar(52) + 14.5 — i.e.
  ~14.5px gap, not 16. Off by ~1.5px.
- **Figma ref**: 08a 695:8924 §"Layout" line 100: "Stepper (`370:22032`)
  centered, w=185, h=7, y=66.5".
- **Fix (DO NOT APPLY)**: cosmetic. Reduce top padding to 14 to match
  exactly, or accept the 2px drift.

### Issue 6 — `SingleChildScrollView` around the grid contradicts the spec's fixed grid

- **Observation**: lines 81–89 wrap `BridgeTimeGrid` in
  `SingleChildScrollView`. Spec shows the grid as a fixed 501h block
  inside the 812 viewport — no scrolling intended.
- **Root cause**: defensive fix to avoid overflow on small devices.
- **Figma ref**: 08a 695:8924 §"Layout" line 104: "time table
  (`695:8936`) w=325, h=501. Left axis hour labels (w=14), then 7
  day columns". The grid has a known size; scrolling is not part of
  the design.
- **Fix (DO NOT APPLY)**: shrink the grid cell height instead of
  scrolling, OR keep the scroll only as a fallback below a
  `MediaQuery` height threshold. Today the body forces a 17-row
  grid into a constrained `Expanded` and silently scrolls.

---

## weekly_time_setup_page

Step 2 — set 4 per-week totals via `BridgeTimeBottomSheet`. Audited
against 08a `695:11870` (empty) and `695:8694` (filled).

### Issue 1 — `BridgeStepperPills(currentStep: 2)` hard-coded; ignores controller.stepIndex

- **Observation**: line 59 sets `currentStep: 2, totalSteps: 3` as
  literals. Compare to schedule_register_page.dart:68 which uses
  `controller.stepIndex`. Inconsistent pattern across pages.
- **Root cause**: copy-paste drift; the controller.stepIndex getter
  already yields `2` for `weeklyTotal`, so literal works today but
  drifts if step enum changes.
- **Figma ref**: 08a 695:11870 §"Layout" lines 240: pill 2 active in
  primarySubtle, pills 1 & 3 inactive in gray150. Visual contract is
  identical to controller value.
- **Fix (DO NOT APPLY)**: read from `controller.stepIndex` consistently
  across all step pages, or move pills into a shared wizard chrome.

### Issue 2 — `BridgeStepHeader` title diverges from Figma

- **Observation**: lines 63–66 render title
  `'주별 사용 시간을 설정해주세요'` and description
  `'이번 한 주 동안 핸드폰을 얼마나 사용할지 정해주세요.'`.
- **Root cause**: paraphrased UX copy.
- **Figma ref**: 08a 695:11870 §"Texts" — title node `695:11880` is
  `주별 시간 분배`; description `695:11883` is
  `부모님이 부여한 이번 달 총 사용 시간을` / `주별로 분배해요!`.
  Also note the spec talks about a **monthly** budget being split into
  4 weeks, not a single week.
- **Fix (DO NOT APPLY)**: replace title and description verbatim,
  including the trailing line `주별로 분배해요!`.

### Issue 3 — Total time card mixes display + interactive trailing button (not in spec)

- **Observation**: lines 68–85 render `BridgeTotalTimeCard` with a
  `trailing: TextButton('자동계산')` slot. The card thus combines the
  read-only week-total display with an action button.
- **Root cause**: implementation merged Figma's "Total time container"
  (`695:11884`) with the separate "Weekly distribution header"
  (`695:11897`) that contains the `자동계산` button.
- **Figma ref**: 08a 695:11870 §"Layout" lines 245–250 — total time is
  a **section** of its own with a title (`2월 총 사용 시간`) above the
  read-only card. The `자동계산` button sits in the **next** section
  header `주별 시간 분배` (line 249, node `695:11897`). Two distinct
  blocks with `gap=40` between them.
- **Fix (DO NOT APPLY)**: split into (1) section title `2월 총 사용
  시간` + `BridgeTotalTimeCard` (no trailing), and (2) section title
  row `주별 시간 분배` + right-aligned `자동계산` button.

### Issue 4 — `자동계산` button is a stub no-op

- **Observation**: `_handleAutoDistribute(...)` is empty (lines 160–163,
  TODO comment). Pressing the button does nothing even when enabled.
- **Root cause**: explicitly marked TODO — outside Step 2 scope per
  inline comment, but `RULES.md` "Implementation Completeness" treats
  this as a violation (no TODO for core functionality).
- **Figma ref**: 08a 695:11870 §"Interactions" — `자동계산 | Auto-
  distributes monthly total evenly across 4 weeks. Becomes idle/
  disabled after first manual edit`.
- **Fix (DO NOT APPLY)**: either implement (split
  `totalWeeklyCapMinutes / 4` into the 4 weeklyTotals) or remove the
  button entirely until ready. Current state is misleading affordance.

### Issue 5 — `canProceed` enables `자동계산` based on the WRONG predicate

- **Observation**: lines 73–84 — `자동계산` is enabled when
  `canProceed` (which is `canProceedToStep3` = "all 4 weeks > 0"). But
  conceptually `자동계산` should be enabled when there is a monthly
  total to distribute AND the user has NOT yet manually edited any
  week. Today the button enables only after the user has already filled
  in all 4 weeks, at which point auto-distributing is pointless.
- **Root cause**: predicate confusion — `canProceed` was reused
  because the variable was handy, not because it expresses the
  intent.
- **Figma ref**: 08a 695:8694 §"State" — `자동계산` shown in idle
  (gray) state once user has filled values manually. Implicit intent:
  enabled before edits.
- **Fix (DO NOT APPLY)**: introduce a `controller.canAutoDistribute`
  derived from "has a non-zero monthly cap" AND "no week has been
  manually set", and gate the button on that.

### Issue 6 — `setWeeklyTotal(weekIndex: null)` legacy behaviour sets ALL weeks to the same value

- **Observation**: controller.dart lines 73–91 — when `weekIndex` is
  null, `setWeeklyTotal` writes the same hours/minutes to **every**
  week. `WeeklyTimeSetupPage._openTimeSheet` passes a non-null
  `weekIndex` so this is dormant on this page, but the API is a
  footgun and the doc comment (line 71) explicitly calls it "legacy".
- **Root cause**: backward-compat shim left in place.
- **Figma ref**: 08a 695:11870 — each week row is independently edited
  via its own bottom-sheet invocation; no "set them all" affordance
  exists in design.
- **Fix (DO NOT APPLY)**: make `weekIndex` required, or split into
  `setWeeklyTotalFor(int weekIndex, …)` and a separate
  `setAllWeeklyTotals(…)` used only by the (yet-unimplemented)
  auto-distribute logic.

### Issue 7 — `showPastWeekDim` row reuses **aggregate** total instead of last-week schedule

- **Observation**: lines 92–98 — when `showPastWeekDim` is true (v2
  mode) the page renders a 지난 주 row using
  `controller.schedule.totalWeeklyHours/Minutes` which is the
  **aggregate of all 4 current-week totals**. Inline TODO at line
  88–91 acknowledges this.
- **Root cause**: no `previousWeekSchedule` source on the controller
  yet.
- **Figma ref**: 09-time-v2.md (referenced by inline TODO) — v2 should
  show last week's actual total, not the current plan's total.
- **Fix (DO NOT APPLY)**: out of scope for v1, but the dead-data row
  shouldn't render under v1 (showPastWeekDim is false in v1, so it
  doesn't trip today; flag for v2 work).

### Issue 8 — Back chevron sends user to Step 1 via `controller.goToStep` instead of `context.pop`

- **Observation**: lines 42–46 — `BridgeAppBar(onBack: () =>
  controller.goToStep(TimeSetupStep.scheduleRegister))`. This is the
  correct UX (stay inside the wizard), but it ignores
  unsaved-changes — going back loses any partial weekly totals
  silently (controller still holds them, but visually nothing warns).
- **Root cause**: intentional wizard-stays-in-place pattern; no
  confirmation flow.
- **Figma ref**: 08a 695:11870 §"Interactions" — "Back | Returns to
  Step 1 schedule". Behaviour matches spec.
- **Fix (DO NOT APPLY)**: matches spec, no change. Flag noted for
  Issue 2 of the root page (system back gesture is unhandled).

---

## daily_time_setup_page

Step 3 — distribute weekly cap across day allocations. Audited against
08b `695-9743` (empty) and 08c `695:10675` (over) / `695:10817` (under)
/ `695:11487` (filled).

### Issue 1 — `_TotalSummaryCard` replaces Figma's `2월 1주차` week label + outlined total card

- **Observation**: lines 73–77 render a custom `_TotalSummaryCard`
  showing `할당 X / 총 Y` plus a `LinearProgressIndicator`. Figma
  shows a different anatomy entirely: a section label like `2월 1주차`
  (Heading2/Bold gray800) above a 327×50 read-only outlined card
  displaying `15 시간 00 분`.
- **Root cause**: implementation invented its own summary widget that
  combines remaining/total + a progress bar. The Figma spec has **no
  progress bar** anywhere in step 3.
- **Figma ref**: 08b 695-9743 §"week time" (line 23–24):
  `2월 1주차` — `Time Frame: 327w × 50h, border: 2px solid #D5D8DE,
  radius 12, opacity 0.8, contents centered ('15 시간 00 분'…)`.
  Same in 08c 695:10675 lines 26–27.
- **Fix (DO NOT APPLY)**: replace `_TotalSummaryCard` with the same
  `BridgeTotalTimeCard` already used in `weekly_time_setup_page` +
  preceding section label. Remove the progress bar.

### Issue 2 — `BridgeStepHeader` title diverges from Figma

- **Observation**: lines 66–71 use title
  `'요일별 사용시간을 분배해주세요'` and description
  `'주별 총 시간 $weeklyHrs시간 $weeklyMin분 안에서\n자유롭게 분배해보세요.'`.
- **Root cause**: paraphrased UX copy; description dynamically injects
  the weekly cap (not in spec).
- **Figma ref**: 08b 695-9743 §"Texts" — title `이번주 일간 시간 설정`,
  description `거의 다 왔어요!` (line 1, trailing space preserved) /
  `내가 설정한 이번주의 시간을 일별로 분배해요.`
- **Fix (DO NOT APPLY)**: replace with verbatim Figma copy; move the
  weekly-cap display into the outlined card (Issue 1) instead of the
  description text.

### Issue 3 — `_AddAllocationTile` shape (rounded rect + add icon) diverges from Figma's 40×40 circular `+` button

- **Observation**: lines 259–309 — `_AddAllocationTile` is a 75h
  white rounded card with a centered `Icons.add_circle_outline` and
  `'요일 추가'` label. It only appears when
  `dayAllocations.length < _maxAllocations` (=3).
- **Root cause**: implementation invented a row-shaped affordance.
- **Figma ref**: 08b 695-9743 §"Daily Distribution Container"
  (line 27): "Round `+` button (40×40, white circle w/ border via
  Ellipse3, plus icon stroke 2 primary). Centered. **This is the only
  action that opens the bottom sheet.**" Spec is explicit: a 40×40
  circular button, no label.
- **Fix (DO NOT APPLY)**: replace with `BridgeAddCircleButton` (40×40,
  white circle, primary `+`), centered between the last day row and
  the CTA.

### Issue 4 — `_maxAllocations = 3` cap is not in spec; allocations should sum to weekly cap, not be capped by count

- **Observation**: line 30 hard-caps allocations at 3. Once the user
  creates 3 rows the `+` tile disappears regardless of whether the
  weekly cap is filled.
- **Root cause**: implementation hard-coded the example count from
  Figma 08c (which shows 3 example rows `월,수,금` / `화,목` / `토,일`).
- **Figma ref**: 08c 695:10675 §"Layout" line 30 lists 3 example rows
  but spec text never says 3 is a hard cap. 08b spec lines 26-27 just
  says `+` button opens sheet; no mention of max rows.
- **Fix (DO NOT APPLY)**: remove the cap, or derive it from
  "remaining days not yet assigned" (= 7 minus sum of
  weekdayIndices across existing allocations). User cannot fit more
  rows when all 7 weekdays are claimed.

### Issue 5 — Allocations dedup keyed by `daysLabel` allows duplicate weekday assignment

- **Observation**: controller.dart lines 99–114 — `upsertAllocation`
  matches by `daysLabel` string. Two allocations with overlapping
  weekday sets but different label strings (e.g. `'월,수'` and
  `'월,금'`) coexist, double-counting Monday.
- **Root cause**: dedup key chosen for the happy path; no validation
  on weekdayIndices uniqueness.
- **Figma ref**: 08c 695:10675 example rows have disjoint weekday
  sets (`월,수,금` / `화,목` / `토,일`). Implicit invariant: each
  weekday appears in exactly one allocation.
- **Fix (DO NOT APPLY)**: enforce weekday disjointness in
  `upsertAllocation` (reject or auto-remove overlap) and update the
  bottom-sheet day chips to disable already-claimed weekdays.

### Issue 6 — Delta banner only renders for over/under, but `isAllocationBalanced` ALSO requires `dayAllocations.isNotEmpty`

- **Observation**: controller.dart line 128–131 — `isAllocationBalanced`
  is `deltaMinutes == 0 && dayAllocations.isNotEmpty`. On the empty
  state (no allocations yet, deltaMinutes = -capMinutes), the page
  shows the under-budget banner. That's correct. But when capMinutes
  is also zero (user somehow lands here without setting weekly
  totals), deltaMinutes is 0, dayAllocations is empty, the CTA
  remains disabled but no banner shows — silent dead-end.
- **Root cause**: edge case in the 0-weekly-cap state.
- **Figma ref**: 08c 695:10675/10817 only specifies over/under
  banners. The 0-cap state shouldn't be reachable per nav (Step 3 is
  gated by `canProceedToStep3` which requires all weeks > 0).
- **Fix (DO NOT APPLY)**: defensive — add an assertion or a "set
  weekly totals first" banner when `capMinutes == 0`.

### Issue 7 — `BridgePillIconButton` cluster shown only in v2 mode collides with the daily-list `Expanded`

- **Observation**: lines 78–98 — when `showPastWeekDim` is true the
  page injects a row of 2 pill buttons (`사용리포트 보기`, `스케줄
  보기`) right above the day-allocation list `Expanded`. The pills
  consume vertical space, pushing the list down.
- **Root cause**: v2 hint UI overlaid onto v1 layout.
- **Figma ref**: 08b 695-9743 §"Daily Distribution Container"
  (line 26) — only the `스케줄 보기` chip exists in v1, placed
  inline with the section header (`일별 시간 분배`). v1 shows no
  `사용리포트 보기` pill.
- **Fix (DO NOT APPLY)**: v1 should render the single `스케줄
  보기` chip in the section header row (replacing the missing
  `일별 시간 분배` header). The v2 pill cluster belongs in the v2
  pages, not on the shared step 3.

### Issue 8 — Back chevron resets state via `controller.goToStep` but does not reverse `dayAllocations` writes

- **Observation**: lines 51–54 — back goes to `weeklyTotal`. If user
  taps back after creating allocations, then changes a weekly total,
  the existing allocations may now exceed the new cap (delta becomes
  positive) with no warning.
- **Root cause**: no invalidation hook on weekly-total changes.
- **Figma ref**: 08a 695:11870 §"Interactions" — back returns to
  Step 1. Step 2 → Step 3 transition is silent on whether step 3
  state is wiped when revisited.
- **Fix (DO NOT APPLY)**: either snapshot/restore allocations when
  back is pressed, or recompute and trim allocations when weekly
  totals change. Add a delta-banner reminder if mismatch is
  detected on re-entering Step 3.

---

## time_setup_review_page

Read-only summary before submit. Audited against 08c 695:11487 ("완성").

### Issue 1 — Background uses `gray050` while other wizard pages use `AppColors.background`

- **Observation**: line 32 — `backgroundColor: AppColors.gray050`. All
  other steps (intro/schedule/weekly/daily) use
  `AppColors.background`.
- **Root cause**: copy-paste from completion page (which intentionally
  uses gray050 per spec). Background inconsistency.
- **Figma ref**: 08c 695:11487 — bg is `#FAFBFC` (gray050) for the
  page. 08a/08b also show the same `#FAFBFC` bg. So **all wizard
  pages should be gray050**, not just review. Today the other 4 pages
  use `AppColors.background`, which may or may not equal `gray050`
  depending on `AppColors` definitions.
- **Fix (DO NOT APPLY)**: normalize all wizard pages to the same
  background token. If `AppColors.background == gray050`, leave
  alone; otherwise unify.

### Issue 2 — Title `'이번주 일간 시간 설정'` repeated from Step 3 instead of a review-specific copy

- **Observation**: lines 56–60 use title `'이번주 일간 시간 설정'`
  with description `'확인 후 등록해주세요.'`.
- **Root cause**: implementation chose the same title as Step 3
  (which Figma also calls `이번주 일간 시간 설정`), distinguishing
  only via description. Acceptable — the title is shared between Step
  3 entry and the validated review state.
- **Figma ref**: 08c 695:11487 §"Texts (verbatim)" — "Same as the
  error frames minus the banner". So title is indeed `이번주 일간
  시간 설정` (same as Step 3). Description is also identical to Step 3
  (`거의 다 왔어요!` / `내가 설정한 이번주의 시간을 일별로 분배해요.`)
  — but the implementation invented `'확인 후 등록해주세요.'`.
- **Fix (DO NOT APPLY)**: use Figma's verbatim description, not a
  paraphrased one.

### Issue 3 — `SafeArea(top: false)` differs from other pages and may collide with AppBar

- **Observation**: line 38 — `SafeArea(top: false, …)`. Other wizard
  pages use plain `SafeArea(child: …)`. Because `BridgeAppBar` is
  inside `Scaffold.appBar`, the appBar already sits inside the safe
  area; `top: false` here is defensive but inconsistent.
- **Root cause**: copy from a page that needed top:false (likely
  child_home).
- **Figma ref**: not directly specified; Figma assumes status bar is
  system-rendered above the topbar.
- **Fix (DO NOT APPLY)**: remove `top: false` for consistency with
  other steps.

### Issue 4 — `BridgeDayRow.showPencil: false` hides the edit affordance but the row remains tappable in widget code (potential)

- **Observation**: lines 76–83 — rows passed `showPencil: false` and
  no `onEdit`. Need to verify `BridgeDayRow` does not still wrap the
  whole card in an `InkWell` when `onEdit` is null.
- **Root cause**: not verified — `bridge_day_row.dart` not read in
  this audit. If the card has a tap target irrespective of `onEdit`,
  the review page is silently editable.
- **Figma ref**: 08c 695:11487 — review state has no edit interactions
  (no pencil rendered, card is read-only).
- **Fix (DO NOT APPLY)**: verify `BridgeDayRow` behaviour;
  alternatively wrap in `IgnorePointer`.

### Issue 5 — `BridgeStepperPills(currentStep: 3)` hard-coded again; same drift as Step 2

- **Observation**: line 51 — literal `currentStep: 3`. Cross-page
  inconsistency (Step 1 reads controller, Step 2/3/Review use
  literals).
- **Root cause**: copy-paste.
- **Figma ref**: 08c 695:11487 — pill 3 is current (primarySubtle in
  spec, primary in widget).
- **Fix (DO NOT APPLY)**: use `controller.stepIndex` everywhere.

### Issue 6 — Submit CTA wired to `controller.submit` which immediately advances to `complete` without server roundtrip

- **Observation**: line 93 — `onPressed: controller.submit`. The
  controller method (controller.dart:140–143) sets step to
  `complete` and notifies. No mock async, no loading state, no
  error path.
- **Root cause**: explicit mock per controller doc comment.
- **Figma ref**: 08c 695:11487 §"Interactions" line 184 — "tap `다음`
  navigates to **완료** screen `695:12086`". No loading state shown
  in Figma.
- **Fix (DO NOT APPLY)**: when wiring to backend, add a loading
  spinner state on the CTA and an error path that re-renders the
  review with an error banner.

---

## time_setup_complete_page

Final success acknowledgement. Audited against 08c 695:12086.

### Issue 1 — Hero stack ORDER is title → icon → message; Figma is the same order BUT the implementation gaps are wrong

- **Observation**: lines 38–73 — stack is Spacer → Title (heading1Bold)
  → SizedBox(24) → Icon (60×60 circle) → SizedBox(16) → Body (bodyBold)
  → Spacer → CTA.
- **Root cause**: gaps chosen ad hoc.
- **Figma ref**: 08c 695:12086 §"Layout" (line 195): "Main container
  — top 213, vertical gap **40**, items-center: Title → Success
  illustration → Message block". Spec is gap=40 between BOTH (title
  ↔ icon AND icon ↔ message), not 24/16. Also `top: 213` not centered
  Spacer.
- **Fix (DO NOT APPLY)**: switch to gap=40 between title/icon and
  icon/message; consider replacing the bottom Spacer with a fixed
  top offset (213) for exact Figma match, or accept centered hero.

### Issue 2 — Title verbatim `'시간 설정 완료!'` matches; body matches; CTA matches — OK

- **Observation**: lines 26–27 — title `'시간 설정 완료!'`, body
  `'이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!'`,
  CTA `'홈으로'`. All verbatim.
- **Root cause**: n/a — copy is correct.
- **Figma ref**: 08c 695:12086 §"Texts" — matches verbatim.
- **Fix**: none required for copy.

### Issue 3 — No `BridgeAppBar`; route pop / Android back is unhandled

- **Observation**: scaffold has no `appBar` (lines 29–30). User
  cannot navigate back to review (intentional per Figma), and
  Android back gesture bubbles up to GoRouter which will pop the
  whole wizard back to the review state (which is now stale because
  controller.step == complete).
- **Root cause**: Figma explicitly hides the topbar on completion;
  no back-press handler attached.
- **Figma ref**: 08c 695:12086 §"Completion anatomy" line 228 —
  "Page-level success screen … No dismiss 'X', no secondary action".
  Spec line 241–243 also notes: "Back button in topbar: present but
  flow should probably either disable it or also route home — confirm
  with PM."
- **Fix (DO NOT APPLY)**: wrap in `PopScope(canPop: false, …)` and
  route the back gesture to `/child-home` (same destination as the
  CTA), to avoid landing on a stale review screen.

### Issue 4 — `body` uses `AppTypography.bodyBold` but Figma spec calls for `Body Bold 16`

- **Observation**: line 70 — `AppTypography.bodyBold`. Spec §"Typography"
  (line 224): "Body message: Pretendard SemiBold 16 / 1.5 / 0.0912
  → Body Bold". Likely matches token, but verify `AppTypography.bodyBold`
  is 16/SemiBold/1.5.
- **Root cause**: needs token-level verification.
- **Figma ref**: 08c 695:12086 §"Typography" line 224.
- **Fix (DO NOT APPLY)**: verify token; if `bodyBold` is not 16px
  SemiBold, define a `body16Bold` and use it.

### Issue 5 — Background uses `gray050`; consistent with Figma, INCONSISTENT with sibling pages

- **Observation**: line 30 — `backgroundColor: AppColors.gray050`. See
  cross-cutting Issue 1 on review page — all wizard pages should use
  the same token.
- **Root cause**: see review page Issue 1.
- **Figma ref**: 08c 695:12086 — bg gray050.
- **Fix (DO NOT APPLY)**: unify across wizard.

---

## Cross-cutting issues (apply to ≥2 pages)

1. **Stepper palette inversion** — `BridgeStepperPills` widget uses
   primary for current pill, primarySubtle for completed. Figma 08a
   shows primarySubtle (`#C2DFFD`) for the current pill and gray150
   for both completed and upcoming. Affects all 4 stepper-bearing
   pages (schedule/weekly/daily/review).

2. **Title/description copy paraphrased** in 4 of 5 wizard pages
   (intro/schedule/weekly/daily) — only the complete page has
   verbatim Figma copy. Review page also diverges (Issue 2).

3. **`stepIndex` reading inconsistent** — schedule_register reads
   `controller.stepIndex`, but weekly/daily/review hard-code `2`/`3`.

4. **Background token inconsistent** — `AppColors.background` (used
   in 5 pages) vs `AppColors.gray050` (used in review + complete).

5. **`BridgeStepHeader` invented widget vs spec's loose "step badge +
   title row" pattern** — header widget pairs circle + title in one
   row + description below, which differs from Figma's pattern that
   separates section labels (e.g. `2월 1주차`, `일별 시간 분배`) from
   the page title.

6. **No `PopScope` anywhere in the wizard** — Android back gesture
   skips the controller's wizard semantics on every page.

7. **Mocked/stub interactions silently present** — `자동계산` button
   (weekly) is a no-op, `setWeeklyTotal(weekIndex: null)` is a legacy
   footgun, `_AddAllocationTile` count cap is invented, and
   `controller.submit` is synchronous mock with no loading state.

8. **Hour-base mapping leak** — `_visibleHourBase = 7` is duplicated
   between the page and the implicit grid contract; encapsulate in
   the widget.

---

## Summary by page (top 2)

| Page | Top Issue | Secondary Issue |
|---|---|---|
| root | `intro` step routes to `ScheduleRegisterPage` (intro dead in v1) | No `PopScope` for system back |
| intro | Copy diverges from Figma 695:8850 | Subtitle missing entirely |
| schedule_register | Back chevron escapes wizard to `/child-home` | Title `핸드폰 사용 가능한…` ≠ Figma `스케줄 등록` |
| weekly | Title `주별 사용 시간을 설정해주세요` ≠ Figma `주별 시간 분배` | `자동계산` button is a no-op stub |
| daily | `_TotalSummaryCard` invents a progress bar not in spec | `_AddAllocationTile` rounded card replaces Figma's 40×40 `+` button |
| review | `BridgeDayRow` may still be tappable when `onEdit` null | Description `확인 후 등록해주세요.` ≠ Figma `거의 다 왔어요! / 내가 설정한…` |
| complete | Hero stack gaps 24/16 ≠ Figma gap=40 | No `PopScope` to redirect Android back to home |

End of audit. No code changes performed.
