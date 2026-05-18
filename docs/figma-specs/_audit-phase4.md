# Phase 4 Audit — 시간 설정 v1 Wizard + Child Home Entry Points

Scope: implementations introduced for the 5-step time-setup wizard (
`time_setup_root_page` → `schedule_register` → `weekly_time_setup` →
`daily_time_setup` → `review` → `complete`) plus the child-home entry
affordances that launch the wizard. Specs:

- `docs/figma-specs/08a-time-v1-entry-weekly.md`
- `docs/figma-specs/08b-time-v1-daily.md`
- `docs/figma-specs/08c-time-v1-errors-done.md`
- `docs/figma-specs/02-child-home.md`

Method: static read of all pages + supporting widgets vs spec tables (layout,
tokens, copy, sheet anatomy, banner anatomy, button states). No live Figma
re-pull was needed (spec docs themselves were validated in Phase 3 and act as
the canonical reference). All file paths in this report are absolute.

---

## 1. `time_setup_root_page.dart`

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_root_page.dart`

### PASS
- Owns the controller, exposes it via `TimeSetupScope`, and disposes it.
- `AnimatedBuilder` re-renders on every controller change.
- Step dispatch table matches `TimeSetupStep` enum 1:1 (no missing case).

### FAIL
- None. (Pure shell with no Figma surface.)

---

## 2. `schedule_register_page.dart` (Figma 695-8924 empty, 695-9115 filled)

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/schedule_register_page.dart`

### PASS
- Top-to-bottom sequence matches Figma: stepper pills → step header (circle + title + description) → grid → CTA.
- Stepper pill is centered and uses `BridgeStepperPills(currentStep: controller.stepIndex, totalSteps: 3)`.
- `BridgeStepHeader` uses `step: 1` and the exact spec copy `핸드폰 사용 가능한 시간을 선택해주세요` (line 75) / `학교, 학원 시간 등 사용이 어려운 시간을 제외하고\n선택해주세요.` (lines 76-77).
- Grid wrapped in `SingleChildScrollView` inside `Expanded` so it can scroll on small viewports.
- CTA disabled when `controller.canProceedToStep2 == false` (no cells), enabled otherwise; advances to `TimeSetupStep.weeklyTotal`.
- Background `AppColors.background` (= gray050) matches spec.
- Page padding 24h is consistent with `AppTokens.pageHorizontal`.
- No stray hex literals (Grep on `/lib/features/time_setup` returned 0 matches for `Color(0x...)`).

### FAIL
- **Copy delta vs Figma**. Figma title (08a §`695:8929` Korean text `695:8932`) reads `스케줄 등록`; implementation (`schedule_register_page.dart:74-77`) renders `핸드폰 사용 가능한 시간을 선택해주세요`. Description also rewritten. Either the spec doc lists the wrong copy or the implementation is using a more conversational rewrite. Designer/PM should confirm — flagged as a copy delta, not a token/layout issue. Spec source: `08a-time-v1-entry-weekly.md:115-117`.
- **Back navigation**. `onBack` calls `context.go('/child-home')` (line 42) instead of the spec'd "Pop to entry (`695:8850`)" (08a §entry interactions). The entry/explainer screen `695:8850` is not implemented in Phase 4, so popping to home is acceptable for now — flag as a scope-difference, not a defect.
- **Stepper indexing**. `BridgeStepperPills` uses 1-indexed `currentStep`; controller emits `stepIndex = 1` for this step (controller line 17). Visually correct (pill 1 active). No issue.
- **Grid background colour for empty cells**. The Figma frame uses `#EDEEF1` (`gray150`) for empty cells. Not directly verifiable in this page (it owns `BridgeTimeGrid` indirectly); needs separate audit on `BridgeTimeGrid` (out of phase 4 file list).

---

## 3. `weekly_time_setup_page.dart` (Figma 695-11870 empty, 695-8694 filled, 695-13485 bottom sheet)

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`

### PASS
- Top-to-bottom: stepper pills → step header (`2 / 주별 사용 시간을 설정해주세요`) → total time card → week row → spacer → CTA. Mirrors Figma sequence.
- `BridgeTotalTimeCard` (display-only) is the spec'd "60시간 30분" summary.
- `BridgeTimeBottomSheet.show()` invoked with `maxHours: 168` for weekly totals (line 119) — correct domain widening over the default 23.
- `setWeeklyTotal` writes back to controller (line 122).
- Back chevron returns to `TimeSetupStep.scheduleRegister` (line 44-45), matching spec back navigation.
- CTA disabled until `controller.canProceedToStep3` (weekly > 0).
- Sheet anatomy (drag handle 40×4 gray200 + header `시간 선택` + two `BridgeWheelPicker` + 324×50 selection band with 2px primary top/bottom borders + bottom CTA `확인`) is implemented in `bridge_time_bottom_sheet.dart` exactly per spec §13485.

### FAIL
- **Section copy mismatch**. Spec (08a §11870) calls the total-time row `2월 총 사용 시간` (or analogous "weekly total"); implementation hardcodes `주별 총 사용시간` (`weekly_time_setup_page.dart:69`). Acceptable rewording but technically a delta vs spec.
- **Week row label**. Spec shows four rows `1주차 / 2주차 / 3주차 / 4주차` (08a §11870 lines 246-252). Implementation renders **one** `BridgeWeekRow` labelled `이번 주` (line 88). This is a deliberate simplification (single weekly total instead of monthly→4-week distribution) but **diverges materially from the Figma**: the Figma screen is about distributing a *monthly* budget across 4 weeks; the implementation treats step 2 as a single "this week's total". This is the largest structural delta in Phase 4. Either the spec or the implementation needs to be reconciled with the PM (spec doc 08a should be updated, or the page should render 4 rows).
- **`자동계산` button**. Implementation wires a `TextButton` (lines 72-85) whose `onPressed` calls `_handleAutoDistribute` which is a no-op (line 128 `// TODO`). Figma calls for `BridgeIconButton` with leading icon, pill background `#EBF5FE` active / `#EDEEF1` idle, radius 7, padding 5h/2v. Current impl ships a plain text button without the chip pill — visual + interaction delta.
- **`자동계산` placement**. Spec (08a §11870 line 249) places `자동계산` to the right of the `주별 시간 분배` section title, *not* inside the total-time card. Implementation puts it as the `trailing` slot of the total-time card.
- **Bottom sheet wheel snap step**. Sheet defaults to `minuteStep: 5`. Spec 08a §13485 line 350 hints at 5-minute increments in the minute column. Matches.

---

## 4. `daily_time_setup_page.dart` (Figma 695-9743 empty, 695-13193 filled, 695-11096 schedule, 695-10675 over, 695-10817 under)

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`

### PASS
- Stepper pills with `currentStep: 3` (line 61) → step header `이번 시간 분배` → `_TotalSummaryCard` with progress bar → list of `BridgeDayRow` + add tile → optional `BridgeDeltaBanner` → CTA `다음`.
- `_AddAllocationTile` enforced max 3 rows (line 91, `_maxAllocations = 3`) — matches Figma's 3-row example (월,수,금 / 화,목 / 토,일).
- `BridgeDeltaBanner.over` (lines 102-105) and `BridgeDeltaBanner.under` (lines 108-111) are wired with correct controller predicates (`isOverBudget`, `isUnderBudget`).
- `BridgeDayRow` has pencil icon + days label + divider + time inline, matches 08b §13193 anatomy.
- `_openSheet` opens `BridgeTimeAllocBottomSheet` which supports the two modes (`dayPicker` / `timePicker`) per 08b state machine table (lines 256-270).
- Tokens: card radius uses `AppTokens.cardRadiusSmall`, colours use `AppColors.gray200/gray600/primary/white`. No stray hex.
- Back chevron → `weeklyTotal` (line 51) matches spec.

### FAIL
- **`_TotalSummaryCard` is bespoke, not in Figma**. Figma 08b §9743 lines 22-25 specifies a `BridgeWeekTimeBox(hours, minutes)` outlined card showing `15 시간 00 분` with 2px gray200 border, opacity 0.8, plus `2월 1주차` label above. Implementation instead renders a custom `_TotalSummaryCard` with `할당 / 총` progress bar (lines 169-231). The progress bar pattern is **not** in any of the 08b frames — this is a designer-friendly addition not backed by Figma. Either upstream Figma needs to add this, or implementation should revert to the spec'd `BridgeWeekTimeBox`.
- **Missing `스케줄 보기` chip**. Figma 08b §9743 line 26 shows a right-aligned chip `스케줄 보기 ›` (bg `#EBF5FE`, primary text, h31 w109). Implementation does not render this chip. Confirmed by `grep` — no `스케줄 보기` literal in this file. The corresponding `695-11096` schedule preview screen is also not implemented in Phase 4.
- **Missing `2월 1주차` week label**. Spec (08b §9743 line 23) shows a 20/SemiBold gray800 label `2월 1주차` above the week-time card. Implementation skips this label entirely.
- **`+` round add button visual mismatch**. Spec (08b §9743 line 27) calls for a 40×40 white circle with primary plus icon (via `Ellipse3`). Implementation renders a full-width dashed "요일 추가" tile with `Icons.add_circle_outline` (lines 236-285). This is a deliberate UX change (full-width tile vs floating circle) — flag as structural delta.
- **Delta banner copy**. `BridgeDeltaBanner` renders text `'$prefix$hours시간 $minutes분 $suffix'` where suffix defaults to `초과`/`남음` (`bridge_delta_banner.dart:115`). Figma (08c §10675 line 49) renders only `+ 00시간 00분` (no `초과` suffix). The current impl produces `+0시간 30분 초과` instead of `+0시간 30분`. Trailing word should be omitted to match Figma exactly, or spec doc updated.
- **Step header copy delta**. Figma title `이번주 일간 시간 설정` (08c §10675 line 24) vs impl `요일별 사용시간을 분배해주세요` (line 66). Description also rewritten.
- **Stepper pill on error frames**. Figma 08c §10675 lines 19-21 shows pill 1 + 2 = gray150, pill 3 = primarySubtle (`#C2DFFD`) — *no* primary blue active pill. Implementation passes `currentStep: 3` to `BridgeStepperPills` which renders pills 1-2 as `primarySubtle` (completed) and pill 3 as `primary` (current). This is the **pre-spec'd general behaviour** but conflicts with the 08c frames. Verify with designer.
- **`_TotalSummaryCard` border colour**. Uses `AppColors.gray200` (line 193). Spec calls for the same with 2px width + opacity 0.8 — current impl uses 1px and no opacity (lines 193). Minor.

---

## 5. `time_setup_review_page.dart` (Figma 695-11487 완성)

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_review_page.dart`

### PASS
- Layout: stepper → step header (3 / `아래 내용으로 시간계획을 등록할게요`) → `BridgeTotalTimeCard` → `ListView.separated` of read-only `BridgeDayRow` (showPencil=false, no onEdit) → CTA `등록하기`. Matches Figma 08c §11487 anatomy minus the schedule-view chip.
- Spec rule "review = balanced state, no banner" is correctly enforced — banner is omitted on this page entirely.
- CTA label `등록하기` matches the submit semantics described in spec.
- Back chevron → `TimeSetupStep.dailyAllocation` allows user to revise allocations.
- Background `AppColors.gray050` matches Figma page bg (`#FAFBFC`).
- Pencil-less rows: `BridgeDayRow(showPencil: false)` correctly disables the trailing pencil for read-only review.

### FAIL
- **CTA label divergence**. Figma (08c §11487 line 164) shows CTA `다음`, navigating to the completion screen. Implementation uses `등록하기` (line 89). Acceptable label rewrite, but doesn't match Figma verbatim — confirm with PM.
- **No `스케줄 보기` chip / `2월 1주차` label**. Figma 08c §11487 line 154 retains the same chrome as 08b 9743 (step header + week card + chip). Implementation omits both, same as the daily-allocation page.
- **Step header copy delta**. Implementation uses `아래 내용으로 시간계획을 등록할게요` (line 58). Spec (08c §11487 line 154 → 08b §9743 line 32) keeps `이번주 일간 시간 설정`. Delta.
- **`safeArea(top: false)`** (line 38) is acceptable because the AppBar covers the status bar, but inconsistent with other pages (`schedule_register_page.dart:44` uses default `SafeArea` with top). Inconsistent SafeArea behaviour across the wizard.

---

## 6. `time_setup_complete_page.dart` (Figma 695-12086 완료)

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_complete_page.dart`

### PASS
- Layout: full-bleed centered hero stack — Spacer + check circle (60×60 primary BoxShape.circle + 32px white check) + heading `시간 설정 완료!` + body 2-line message + Spacer + `BridgeButton(label: '홈으로')`. Matches Figma 08c §12086.
- No AppBar — correct per spec line 195.
- Copy verbatim per spec (line 60: `이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!`) — matches `08c-time-v1-errors-done.md:208-209`.
- CTA `홈으로` matches spec (line 204).
- `context.go('/child-home')` replaces stack — matches "navigate to child home (replace stack, no back to setup flow)" per spec line 239.
- Background `AppColors.gray050` matches spec `#FAFBFC` page bg.

### FAIL
- **Spec hero order**. Spec lists: Title → Icon → Message (top-to-bottom). Implementation renders: Icon → Title → Message. Visual order differs (impl has icon first). Spec line 197-201 explicitly says order is Title (centered) → Icon → Message. Confirm with designer; may be intentional for stronger success affordance.
- **Title fixed `letterSpacing`**. `AppTypography.heading1Bold` is applied with `.copyWith(color: AppColors.textPrimary)` (line 53). Spec calls for `-0.4656` letter-spacing (line 223); assuming the typography token already encodes this. If not, the title may look slightly off. Verify token.
- **Body uses `bodyMedium`**. Spec calls for `Body/Bold 16` (line 224: Pretendard SemiBold 16). Implementation uses `bodyMedium` (line 61). Weight delta (Medium vs SemiBold).
- **No SafeArea bottom inset on CTA**. CTA is followed by `SizedBox(height: 24)` (line 74). Acceptable, but ensure home-indicator safe inset isn't doubled.

---

## 7. Child Home Entry Points (Figma 426-20978 / 426-21005)

File: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/child_home/presentation/pages/child_home_page.dart`

### PASS
- Gear icon (line 284-298) navigates to `/child-home/time-setup/confirm` when `showDonut` (filled state). Empty state shows greyed gear (lines 300-304) — visually correct per spec.
- `_ScheduleEmptyState` (lines 356-389) presents an empty-state message + circular `+` button (40×40, `primaryLight` bg, primary icon) that pushes `/child-home/time-setup` — matches the inferred entry-to-wizard flow.
- `_AddCircleButton` (lines 554-569) for hasContent=false (onboarding) state is centered with the same `#EBF5FE` bg & primary icon — matches 02-child-home spec line 27.
- Mission card tap (line 736-738) pushes `/child-home/mission/${data.id}` (with TODO acknowledging the route is not yet registered for Phase 6).
- Mission status icon variants (pendingCheck/rejected/reviewing/completed) implemented (lines 814-830).
- Notification dot uses `AppColors.destructive` (line 195) — discussed in 02-child-home deltas as acceptable.
- `_MyPageButton` left-border + `my` text + `context.push('/mypage')` matches spec.

### FAIL
- **Stray hex colours**. `child_home_page.dart` still contains 12 raw `Color(0x...)` literals where tokens exist (`grep` results above). These were called out in the 02-child-home deltas (lines 175-188) and should be tokenised:
  - L336: `Color(0x80D9D9D9)` → suggested `AppTokens.cardShadow` (not yet introduced).
  - L458, L465: `Color(0xFFEDEEF1)` → `AppColors.gray150` ✓ token exists.
  - L466, L502: `Color(0xFFFFBF00)` → `AppColors.bonusAmber` ✓ token exists.
  - L563: `Color(0xFFEBF5FE)` → `AppColors.primaryLight` ✓ token exists.
  - L743: `Color(0xFFEDEEF1)` → `AppColors.gray150` ✓ token exists.
  - L826: `Color(0xFFFFD980)` — no token; consider `bonusAmber.withOpacity(0.5)` or add `bonusAmberSoft`.
  - L859: `Color(0xFF16BF40)` — should be `AppColors.positive` (`#00BF40`) per 02-child-home delta #3.
  - L895, L909: `Color(0xFFE1F0FE)` → `AppColors.primarySoft` ✓ token exists.
  - L963: `Color(0xFFC2DFFD)` → `AppColors.primarySubtle` ✓ token exists.
- **Gear route**. `_TodayTimeSection` gear button routes to `/child-home/time-setup/confirm` (line 297) — TODO at line 281-283 notes the route is not registered yet (Phase 5). Tap will 404 today. Acceptable per the comment but should be tracked.
- **`_hasSchedule` hardcoded**. Line 27 has `bool _hasSchedule = true` with a long-press debug toggle (line 329). This means the empty-state `+` flow is unreachable in default state — needs real state wiring.
- **Card radius literal**. Lines 333, 744 use `BorderRadius.circular(16)` directly instead of `AppTokens.cardRadiusSmall`. Cosmetic but inconsistent with the wizard pages which do use the token.
- **`Icons.settings` vs Figma SVG**. Lines 301, 603 use Material `Icons.settings`/`Icons.settings_outlined`. Figma calls for a custom mask asset; 02-child-home delta #10 already flagged.
- **Empty-state copy** for `_ScheduleEmptyState` (line 366: `아직 등록된 시간 계획이 없어요.`) is not in 02-child-home.md (spec assumes a `+` only). This is a new child-home variant introduced for Phase 4 — needs to be added to the spec doc.
- **`+` button hit target**. `_AddCircleButton` (lines 554-569) used in the `hasContent: false` onboarding card has no `GestureDetector` — it is purely decorative. Only the `_ScheduleEmptyState` variant has tap routing. If the onboarding `+` should launch the wizard too, this is a missing handler.

---

## Recommended Fixes (Prioritised)

### Tier 1 — Blocks correctness / breaks at runtime

1. **`daily_time_setup_page.dart`: align the weekly-total summary with Figma**. Replace the bespoke `_TotalSummaryCard` (progress bar) with the spec'd `BridgeWeekTimeBox` + `2월 1주차` label (or the runtime-computed equivalent). Without this, the screen visually does not match any Figma frame.
2. **`weekly_time_setup_page.dart`: 4-row distribution vs 1-row 이번 주**. Decide with PM whether step 2 should render 4 weekly rows (per Figma) or remain a single "이번 주" total. If the latter, update spec 08a to reflect this; if the former, refactor to a list backed by `controller.schedule.weekAllocations`. Currently impl and spec disagree on the core control.
3. **`BridgeDeltaBanner`: drop the trailing `초과` / `남음` word** to match Figma `+ 00시간 00분` / `- 00시간 00분` exactly. Or update spec 08c to add the suffix word — single source of truth needed.
4. **`child_home_page.dart`: wire `_hasSchedule` to real state** (currently hardcoded `true` with a debug long-press). Without this the empty-state `+` entry point is unreachable. Once the schedule persistence lands, the `+` becomes the primary entry to the wizard.

### Tier 2 — Spec/code drift, fix to keep documentation honest

5. **Copy reconciliation**. Multiple pages rewrite Korean copy (titles, descriptions, CTAs):
   - `schedule_register_page.dart:74-77` vs Figma `스케줄 등록`.
   - `weekly_time_setup_page.dart:64` vs Figma `주별 시간 분배`.
   - `daily_time_setup_page.dart:66` vs Figma `이번주 일간 시간 설정`.
   - `time_setup_review_page.dart:58` vs Figma identical.
   - `time_setup_review_page.dart:89` CTA `등록하기` vs Figma `다음`.
   Either update spec docs or revert impl to match.
6. **Add `스케줄 보기` chip** to `daily_time_setup_page.dart` + `time_setup_review_page.dart` per 08b/08c spec. (Even if the `695-11096` schedule-view page doesn't ship in Phase 4, the chip itself should render as a disabled placeholder so the layout matches.)
7. **`자동계산` button**: ship as a proper `BridgeIconButton` chip (active `primaryLight` / idle `gray150`) per 08a §11870 line 250-251. Currently it's a plain `TextButton` and the `_handleAutoDistribute` body is a TODO no-op — either implement the auto-split logic or remove the button until ready.
8. **`time_setup_complete_page.dart`**:
   - Reorder hero stack to Title → Icon → Message per spec line 197-201.
   - Switch body text from `bodyMedium` to `bodyBold` (Pretendard SemiBold 16) per spec line 224.
9. **Tokenise the 12 stray hex literals in `child_home_page.dart`** (list under §7 FAIL above). All 12 either have an existing token (`gray150`, `bonusAmber`, `primaryLight`, `primarySoft`, `primarySubtle`, `positive`) or warrant adding `cardShadow` / `bonusAmberSoft`.

### Tier 3 — Polish / consistency

10. **`SafeArea(top: false)` consistency** across wizard pages. Standardise so all pages either trust the AppBar to handle the status-bar or wrap with `SafeArea(top: true)`.
11. **Step-header `BridgeStepCircle` colour on error frames**. Spec 08c describes pill 1 + 2 = gray150 on error frames; current `BridgeStepperPills` would render them as `primarySubtle` because they are "completed". Either parameterise the colour or note this as a known minor delta.
12. **Card radius literal usage** in `child_home_page.dart` (lines 333, 744) — replace `BorderRadius.circular(16)` with `BorderRadius.circular(AppTokens.cardRadiusSmall)`.
13. **`_TotalSummaryCard` border width**: 1px → 2px, add `Opacity(0.8)` wrapper, per 08b §9743 line 24.
14. **Hide `+` add tile** when 3 allocations have been added (already correct — `if (... < _maxAllocations)`), but verify with a unit test.
15. **Add a unit test** for `BridgeDeltaBanner` covering both variants once Tier 1 #3 is resolved.
16. **`_AddCircleButton` on child-home empty/onboarding card** (lines 554-569) — wrap in `GestureDetector` if it should also launch the wizard, or document that it's a decorative placeholder.
17. **Replace `Icons.settings(_outlined)` in child-home** with the Figma SVG mask asset for visual parity.

---

## Summary Counts

| Page | PASS items | FAIL items |
|---|---|---|
| `time_setup_root_page` | 3 | 0 |
| `schedule_register_page` | 9 | 4 |
| `weekly_time_setup_page` | 7 | 4 |
| `daily_time_setup_page` | 7 | 7 |
| `time_setup_review_page` | 7 | 4 |
| `time_setup_complete_page` | 6 | 4 |
| `child_home_page` (entry) | 7 | 7 |

Total: 46 PASS / 30 FAIL across 7 surfaces. Most failures are spec-vs-impl
copy/structure drift rather than code defects — the underlying widget library
(`BridgeStepperPills`, `BridgeDayRow`, `BridgeDeltaBanner`, `BridgeTimeBottomSheet`,
`BridgeTimeAllocBottomSheet`) is well-tokenised and structurally faithful.

No stray hex literals exist inside `lib/features/time_setup` (verified by Grep).
The 12 hex literals remaining are all in `child_home_page.dart` and were
already enumerated in `02-child-home.md` deltas.
