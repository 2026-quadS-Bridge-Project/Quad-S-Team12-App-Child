# Audit Round 3 — Time Setup v2 + Time Confirm

**Scope**: Verification-only re-audit after Round 1+2 fixes. Diagnostic, no code changes.
**Date**: 2026-05-18
**Original audits**: `_audit-layout/14-time-setup-v2.md`, `_audit-layout/15-time-confirm.md`
**Figma fileKey**: `tzJjQmXtXO7vGlfCT9SASu` (nodes 750-13034 intro, 750-13686 daily error, 662-11249 confirm tooltip)

---

## Verification matrix

| # | Requirement | Target file | Status | Evidence |
|---|-------------|-------------|--------|----------|
| 1 | `_previousWeek` field present + immutable | `time_setup_controller.dart` | PASS | L41: `final TimeSchedule? _previousWeek;` (final, nullable, never reassigned) |
| 2 | `.v2NextWeek` seeds both `_schedule` AND `_previousWeek` | `time_setup_controller.dart` | PASS | L34-38: `_schedule = previousWeek, _previousWeek = previousWeek, _mode = v2NextWeek, _step = intro` |
| 3a | `reset()` is mode-aware (v2 branch) | `time_setup_controller.dart` | PASS | L161-163: `if (_mode == v2NextWeek) { _schedule = _previousWeek ?? empty; _step = intro; }` |
| 3b | `reset()` preserves v1 behaviour | `time_setup_controller.dart` | PASS | L164-167: v1 falls through to `scheduleRegister` step, empty schedule |
| 3c | `_mode` preserved across reset | `time_setup_controller.dart` | PASS | `_mode` is `final` (L43), never reassigned in `reset()`; `showPastWeekDim` remains stable |
| 4a | Weekly v2: 4 rows total (not 5) | `weekly_time_setup_page.dart` | PASS | L99-118: 1 locked row + `for (int i = 1; i < 4; i++)` = 4 total |
| 4b | Locked `1주차` sourced from `previousWeek` | `weekly_time_setup_page.dart` | PASS | L100-107: `hours/minutes` reads `controller.previousWeek?.weeklyTotals[0]` |
| 4c | Locked row uses `isPast: true` + `onTap: null` | `weekly_time_setup_page.dart` | PASS | L105-106; cross-check `bridge_week_row.dart:100` applies 0.2 opacity |
| 4d | Editable rows labeled `2주차`/`3주차`/`4주차` | `weekly_time_setup_page.dart` | PASS | L111: `'${i + 1}주차'` for `i ∈ [1,3]` produces `2/3/4주차` |
| 4e | v1 fallback still renders 4 editable rows | `weekly_time_setup_page.dart` | PASS | L119-129: else-branch loops `i ∈ [0,3]` with all rows editable |
| 5a | Daily v2 pill order `[스케줄 보기, 사용리포트 보기]` | `daily_time_setup_page.dart` | PASS | L99 `스케줄 보기` first; L109 `사용리포트 보기` second |
| 5b | Daily v2 pills use tonal variant | `daily_time_setup_page.dart` | PASS | L102, L112: `variant: BridgePillVariant.tonal`; resolves to `primaryLight` bg + `primary` text per `bridge_pill_icon_button.dart:120-126` |
| 5c | Pills open `showModalBottomSheet` (no push) | `daily_time_setup_page.dart` | PASS | L226: `showModalBottomSheet<void>`; no `context.push` for reference modal |
| 5d | Pills do NOT exit wizard | `daily_time_setup_page.dart` | PASS | `_openReferenceModal` returns Future, wizard stack preserved |
| 6a | Error frame border width = 1.2px | `daily_time_setup_page.dart` | PASS | L298: `Border.all(color: borderColor, width: 1.2)` |
| 6b | Over-budget border = `destructiveBorderSoft` | `daily_time_setup_page.dart` | PASS | L293-294: `isOver ? destructiveBorderSoft : primary` |
| 6c | Under-budget border = `primary` | `daily_time_setup_page.dart` | PASS | L294 fall-through `AppColors.primary` |
| 6d | Frame omitted when balanced | `daily_time_setup_page.dart` | PASS | L292: `if (!isOver && !isUnder) return child` |
| 7a | TimeConfirm section title = `heading2Bold` / `gray800` | `time_confirm_page.dart` | PASS | L166-170: `AppTypography.heading2Bold.copyWith(color: AppColors.gray800)` |
| 7b | Tooltip positioned BELOW pill | `time_confirm_page.dart` | PASS | L187: `top: 36` (positive, below pill) — was `top: -64` (above) in Round 0 |
| 7c | Tooltip uses `topCenter` arrow alignment | `time_confirm_page.dart` | PASS | L219: `arrowAlignment: TooltipArrowAlignment.topCenter` |
| 7d | Tooltip X close icon present | `bridge_onboarding_tooltip.dart` | PASS | L160-165: `_CloseButton` rendered when `onDismiss != null`; consumer L220 passes `onDismissOnboarding` |
| 7e | Tooltip title `시간 계획 수정은 어떻게 하나요?` | `time_confirm_page.dart` | PASS | L190 verbatim |
| 7f | Bullet 1 contains `주 1회` underlined | `time_confirm_page.dart` | PASS | L194-200: TextSpan with `decoration: TextDecoration.underline` on `주 1회` |
| 7g | Bullet 2 contains `시간 설정 탭` underlined | `time_confirm_page.dart` | PASS | L207-215: matching underline span on `시간 설정 탭` |
| 7h | Verbatim copy for both bullets | `time_confirm_page.dart` | PASS | Bullet 1 L194-203 + Bullet 2 L208-215 match spec `10-time-confirm.md` L130-132 |
| 7i | Tooltip API supports `arrowAlignment`/`bullets`/`onDismiss` | `bridge_onboarding_tooltip.dart` | PASS | L40-47 constructor exposes all three; `TooltipArrowAlignment` enum L16 declares 4 sides |

---

## Per-area summary

### Area A — Controller state model (`time_setup_controller.dart`)
**Status: PASS**
- `_previousWeek` immutable (`final`, set once in `.v2NextWeek` constructor).
- `.v2NextWeek` correctly seeds both schedules + sets `_mode` + jumps to `intro` step.
- `reset()` now branches on `_mode`: v2 restores `_previousWeek` snapshot and returns to `intro`; v1 returns empty + `scheduleRegister`. Mode preserved in both branches, so `showPastWeekDim` stays stable.
- Resolves original Round-0 Issue 1 (state-model corruption on edit/reset).

### Area B — v2 root shell (`time_setup_v2_root_page.dart`)
**Status: PASS**
- Constructs controller via `.v2NextWeek(previousWeek: TimeScheduleMock.sampleFilled)` (L37-39).
- Disposes controller on unmount (L43-46).
- Routes `intro` → `TimeSetupIntroPage` (L56), unchanged.

### Area C — Weekly v2 page (`weekly_time_setup_page.dart`)
**Status: PASS**
- 4 rows total (1 locked + 3 editable), eliminating the Round-0 5-row regression.
- Locked row sources from `controller.previousWeek?.weeklyTotals[0]` (immutable historical record). Null-coalesce to 0 is defensive but unreachable in v2 mode (constructor guarantees non-null).
- Labels: `1주차` (locked, opacity 0.2 via `BridgeWeekRow.isPast`) + `2주차/3주차/4주차` (editable). No duplicate label.
- v1 path unaffected (else-branch preserved).
- Resolves Round-0 Issue 3.

### Area D — Daily v2 page (`daily_time_setup_page.dart`)
**Status: PASS**
- Pill order: `스케줄 보기` first, `사용리포트 보기` second (matches spec §v2-6 L260-261).
- Both pills tonal (primaryLight bg + primary fg) — verified via component palette resolver.
- `_openReferenceModal` uses `showModalBottomSheet` with rounded top corners (L226-231), preserving wizard stack. Body is a placeholder `미리보기는 곧 추가될 예정이에요.` (L259) — non-fatal stub but flagged below.
- Error frame: `_DayRowsFrame` (L279-304) wraps day-rows list with `Border.all(width: 1.2)` using `destructiveBorderSoft` (over) or `primary` (under). Balanced state passes through transparently.
- Resolves Round-0 Issues 4 and 6.

### Area E — TimeConfirm tooltip (`time_confirm_page.dart` + `bridge_onboarding_tooltip.dart`)
**Status: PASS**
- Section title uses `heading2Bold` (20/SemiBold) + `gray800` (`#2F3032`).
- Tooltip body positioned BELOW the pill via `Positioned(top: 36, right: 0)` inside the same `Stack` that wraps the pill. Direction inversion from Round 0 corrected.
- Arrow alignment `topCenter` (notch on top, pointing up at pill).
- Verbatim copy for both bullets with underline emphasis on `주 1회` and `시간 설정 탭`.
- Close (X) icon rendered top-right when `onDismiss` provided; consumer wires `onDismissOnboarding`.
- New `BridgeOnboardingTooltip` API supports title + `List<TextSpan> bullets` + `arrowAlignment` + `onDismiss` — fully replaces old single-`message` API.
- Resolves Round-0 Issues 5, 6, 7 (TimeConfirm audit).

---

## Residual notes (out of scope for Round 3)

These were NOT in the Round 3 verification checklist but observed during the pass:

1. `daily_time_setup_page.dart:259` — reference modal body is a placeholder string. Future work: render previous-week grid / report preview inline.
2. `time_setup_v2_root_page.dart:21-23` — TODO comment about v1 sub-pages adopting `showPastWeekDim` remains. Currently only weekly + daily pages are v2-aware; intro/register/review/complete still render the v1 layout regardless of mode. Not a regression — intentional staged migration.
3. `bridge_onboarding_tooltip.dart:80-84` — drop shadow uses `Color(0x0F000000)` (~6% black). Spec did not mandate a token; acceptable as a component-internal constant.
4. Round-0 Issue 8 (notification routing for n2) and Issue 2 (intro page copy) were not in the Round 3 target list; status unchanged from Round 0 (still FAIL pending separate work).

---

## Overall verdict

All 7 Round 3 verification requirements PASS. The Round 1+2 fixes correctly address the high-priority defects from `_audit-layout/14` (Issues 1, 3, 4, 6) and `_audit-layout/15` (Issues 5, 6, 7). No regressions detected against the v1 path.
