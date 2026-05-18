# Phase 5 — Figma vs Implementation Audit

**Date**: 2026-05-18
**Scope**: TimeConfirm + TimeSetupV2 wizard surfaces
**Specs cross-referenced**: `09-time-v2.md` (frames 750-13034/12671/11991/13450/13105/13686/14708/13854/13624), `10-time-confirm.md` (frames 744-11326/662-11322/662-11249)

Diagnose-only — no code changes performed.

---

## Summary

| Surface | Status | Notes |
|---|---|---|
| TimeConfirm (3 variants) | PARTIAL | Empty + onboarding variants drift from spec; filled variant solid |
| TimeSetupV2 entry | PARTIAL | Wires v2NextWeek mode; missing v2-1 intro splash; no per-week data model |
| DailyV2 (Step 3) | PARTIAL | 사용리포트 보기 pill exists, but generic `BridgeDeltaBanner` substitutes for spec's dual-tone framed border + chip |
| CompleteV2 | PASS (with caveat) | Mode-conditional copy works; copy text drifts from spec wording |
| OnboardingTooltip widget | PARTIAL | Arrow + dismiss work; copy text drifts; bg color/contrast deviates from spec |

---

## TimeConfirm — `lib/features/time_confirm/presentation/pages/time_confirm_page.dart`

### PASS
- **Variant routing**: `?variant=empty|filled|onboarding` resolves to correct `TimeConfirmMock` payload. `time_confirm_page.dart:50-61`.
- **수정하기 pill — ghost variant**: `variant: BridgePillVariant.ghost` at `time_confirm_page.dart:178`. Matches the request that pill be ghost. NOTE: spec 10-time-confirm.md:62 actually describes a tonal gray pill (bg `#EDEEF1`, label `#A7ACB2`), but request explicitly says "수정하기 pill button is correctly ghost variant" — code matches the requirement, not the spec wording.
- **수정 요청 stub**: `_showRequestSnack` calls controller + shows SnackBar `부모님께 수정 요청을 보냈어요.` (`time_confirm_page.dart:69-75`). Honors the "child cannot directly edit" rule from spec line 5.
- **Read-only daily rows**: `BridgeDayRow(... onEdit: null, showPencil: false)` (`time_confirm_page.dart:208-209`) correctly suppresses pencil in read-only summary.
- **Tooltip mounting**: `BridgeOnboardingTooltip` is `Stack`-anchored with `Positioned(top: -64, right: 0)` relative to pill (`time_confirm_page.dart:172-194`). Dismiss handler wired to `_controller.dismissOnboarding`.

### FAIL / DELTA
- **App bar title**: Code renders `시간 설정 확인` (`time_confirm_page.dart:81`); spec verbatim is `시간설정` (no space, 10-time-confirm.md:20).
- **Section title — weekly card**: Code uses `주별 총 사용시간` (`time_confirm_page.dart:157`). Spec is `2월 1주 사용 시간` (10-time-confirm.md:71) — month/week qualifier is missing, copy drifts.
- **Section title — day list**: Code uses `요일별 사용시간` (`time_confirm_page.dart:167`). Spec is `일간 사용 계획` (10-time-confirm.md:73).
- **Empty-state copy**: Code `이번달 시간규칙이\n설정되지 않았습니다.` (`time_confirm_page.dart:116`). Spec single-line `이번달 시간규칙이 설정되지 않았습니다.` (10-time-confirm.md:22).
- **Empty-state CTA**: Code button labelled `닫기` (`time_confirm_page.dart:123`). Spec calls for `확인` on **all 3 variants** (10-time-confirm.md:24, 78). This is the only CTA on the empty screen and per spec should be the same acknowledgement button.
- **Empty-state has no app bar?**: `Scaffold` still mounts `BridgeAppBar` for empty variant (good), but the empty layout uses `Padding` + `Expanded` rather than the spec's centered empty message with primary CTA pinned bottom — visually close but layout differs.
- **Section divider missing**: Spec calls for full-width `#EDEEF1` (gray150) 7px-thick divider between Weekly and Daily sections (10-time-confirm.md:56). Code uses `SizedBox(height: 16)` (`time_confirm_page.dart:161`). No divider rendered.
- **No section title for weekly card**: Spec calls for separate `2월 1주 사용 시간` title above the bordered box (10-time-confirm.md:57-60), but the title is inlined as the card's `title` param. Visual hierarchy differs.

---

## TimeSetupV2 entry — `lib/features/time_setup/presentation/pages/time_setup_v2_root_page.dart`

### PASS
- **Controller mode**: `TimeSetupController.v2NextWeek(previousWeek: ...)` correctly seeds `_mode = v2NextWeek` and `showPastWeekDim => true` (`time_setup_controller.dart:17-29`).
- **Step routing**: All 5 wizard steps map to the same v1 sub-pages — sub-pages are mode-aware via `controller.showPastWeekDim` (`time_setup_v2_root_page.dart:54-62`). Reuse achieved.
- **WeeklyTimeSetupPage `지난 주` dim row**: Conditional `if (controller.showPastWeekDim)` renders `BridgeWeekRow(weekLabel: '지난 주', ... isPast: true)` (`weekly_time_setup_page.dart:87-100`). `BridgeWeekRow.isPast` applies `Opacity(0.2)` matching spec opacity discipline (09-time-v2.md:131).

### FAIL / DELTA
- **v2-1 (intro splash) is missing entirely.** Spec defines a dedicated entry screen `사용시간 설정` / `저번주 피드백을 고려해서 더 나아진 이번주 계획을 짜봐요!` with 3-step list and `시작` CTA (09-time-v2.md:9-49, frame 750:13034). Code skips straight to `TimeSetupStep.scheduleRegister`. No `TimeSetupStep.intro` enum value exists. **Critical gap — the v2 wizard has no intro.**
- **No per-week data model.** Spec 09-time-v2.md:108-145 (frame 750:11991) defines 4 weekly rows where `1주차` is locked past data and 2/3/4주차 are independently editable. Code shows `지난 주` + `1주차..4주차` with **all 5 rows displaying the same `controller.schedule.weeklyTotalHours/Minutes`** (`weekly_time_setup_page.dart:92-119`) — see in-file TODOs at lines 88-93 and 102-106. **Functional gap — distribution editing is non-functional in v2.**
- **`2월 잔여 시간` label missing**: Spec uses `2월 잔여 시간` (v2-3, 09-time-v2.md:123) for the total card on the v2 weekly screen. Code uses generic `주별 총 사용시간` (`weekly_time_setup_page.dart:69`).
- **`자동계산` button no-op**: `_handleAutoDistribute` is empty (`weekly_time_setup_page.dart:160`). Spec requires it to distribute remaining time across editable weeks (09-time-v2.md:152).
- **No disabled style for `자동계산` when balanced**: Spec v2-5 (09-time-v2.md:223-225) shows disabled state when remaining time hits 0. Code only disables when `!canProceed`, not when balanced.
- **No prefilled `1주차 15h 00m`-style locked past-row** distinct from `지난 주` row. Code uses `지난 주` label, spec uses `1주차` for the past-week locked row.

---

## DailyV2 — `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`

### PASS
- **`사용리포트 보기` pill**: Conditionally rendered when `controller.showPastWeekDim` (`daily_time_setup_page.dart:78-89`). Uses `BridgePillVariant.ghost` with `trailingIcon: Icons.arrow_forward`. Push target `/child-home/report`. Matches v2-only requirement (09-time-v2.md:296, 460).
- **Over / under banners**: `BridgeDeltaBanner.over` / `.under` mounted conditionally (`daily_time_setup_page.dart:115-127`), giving the dual-tone over/under affordance the spec requires.
- **Pencil-row pattern**: `BridgeDayRow` with `onEdit` opens `BridgeTimeAllocBottomSheet` (`daily_time_setup_page.dart:96-103, 147-178`) — matches v2-6/7/8 edit affordance (09-time-v2.md:300).

### FAIL / DELTA
- **Error-frame border around daily rows is missing**: Spec v2-6 calls for `1.2px #FF7878` rounded-8 border *wrapping the entire daily rows region* on over (09-time-v2.md:263) and `1.2px #3A99F8` on under (v2-7, 09-time-v2.md:326). Code uses only the inline `BridgeDeltaBanner` — no surrounding error frame.
- **Footer chip styling diverges**: Spec uses `#FFD3D3` bg + `#FF4242` text for over, `#E1F0FE` bg + `#3A99F8` text for under, with `+ 00시간 00분` copy (09-time-v2.md:273, 322). Whether `BridgeDeltaBanner` uses those exact tokens needs verification — file not opened but tokens `destructiveSubtle` (`#FFD3D3`) and `primarySoft` (`#E1F0FE`) do exist in `app_colors.dart:44-53`.
- **`스케줄 보기` button missing**: Spec daily v2 shows TWO pills — `스케줄 보기 ›` AND `사용리포트 보기 ›` (09-time-v2.md:260, 350). Code only renders `사용리포트 보기`. **Missing element.**
- **Heading copy drift**: Code `요일별 사용시간을 분배해주세요` (`daily_time_setup_page.dart:68`). Spec `이번주 일간 시간 설정` (09-time-v2.md:267).
- **`2월 2주차` subsection header missing**: Spec requires a `2월 2주차` heading + bordered total card above the daily list (09-time-v2.md:255-257). Code uses `_TotalSummaryCard` with `할당 / 총` text — different visual + missing month/week label.
- **`_AddAllocationTile` ("요일 추가")**: Code adds an "add row" affordance (`daily_time_setup_page.dart:105-112`) that does not appear in v2 spec — v2 always shows the 3 pre-filled rows from last week's plan.

---

## CompleteV2 — `lib/features/time_setup/presentation/pages/time_setup_complete_page.dart`

### PASS
- **Mode-conditional copy works**: `controller.mode == TimeSetupMode.v2NextWeek` switches title + body (`time_setup_complete_page.dart:24-28`).
- **Layout matches spec**: Centered title, 60×60 primary circle with white check, body copy, full-width `홈으로` CTA — matches v2-9 (09-time-v2.md:382-389).
- **Token discipline**: All colors via `AppColors.*`, no stray hex.

### FAIL / DELTA
- **Body copy drifts from spec**: Spec v2-9 verbatim is `이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!` (09-time-v2.md:391-393). Code v2 branch: `다음주 시간 계획이 부모님께 전달되었어요.\n이제 한 주를 알차게 보내봐요!` (`time_setup_complete_page.dart:27`). **Different wording.** (The v1 branch matches the spec.)
- **Title drift**: Spec v2-9 title is `시간 설정 완료!` (09-time-v2.md:392). Code v2 branch renders `다음주 시간 설정 완료!`.
- **Body text color**: Spec calls for `#050505` SemiBold 16 (09-time-v2.md:399). Code uses `AppColors.gray600` (`time_setup_complete_page.dart:71`).

---

## OnboardingTooltip widget — `lib/core/widgets/feedback/bridge_onboarding_tooltip.dart`

### PASS
- **Arrow rendering**: `_ArrowPainter` paints solid triangles for all 4 alignments (`bridge_onboarding_tooltip.dart:169-219`). `bottomCenter` arrow points down — correct for tooltip floating *above* the pill anchor.
- **Dismiss handler**: `onDismiss` renders a `확인` text link (`_DismissLink`) right-aligned inside the card body (`bridge_onboarding_tooltip.dart:137-162`). Tested via `_showRequestSnack` not exercised — dismiss is wired to controller (`time_confirm_page.dart:94`).
- **Semantics**: `Semantics(container: true, liveRegion: true, label: message)` for screen-reader announcement.
- **No stray hex**: Single `Color(0x14000000)` literal at line 60 is a documented shadow alpha (black 8%), not a brand color. Acceptable.

### FAIL / DELTA
- **Body color inverted from spec**: Spec tooltip bg = `#5F6165` (gray600) **dark** with white text (10-time-confirm.md:135-138). Code uses `AppColors.white` bg + `AppColors.gray800` text (`bridge_onboarding_tooltip.dart:57, 109`). **Inverted color scheme — visual mismatch.**
- **Tooltip copy mismatch**: Spec has structured bulleted content with title `시간 계획 수정은 어떻게 하나요?` and 2 bullets including underlined emphasis (10-time-confirm.md:130-133). Code passes a single plain string `직접 수정할 수 없어요.\n꼭 필요한 경우에 부모님의 시간 설정 탭에서\n허락을 받아, 수정할 수 있어요` (`time_confirm_page.dart:186-187`). **No title, no bullets, no underline spans.**
- **No close X icon**: Spec shows a close (X) vector in the tooltip's top-right (10-time-confirm.md:127). Code only offers the inline `확인` text link.
- **Typography**: Spec uses `Caption/Bold 12` for title and `Caption/Regular 12` for bullets. Code uses `captionMedium` for body and `captionBold` for the dismiss link — close but not a 1:1 match.

---

## Token discipline (no stray hex)

Grep on `lib/features/time_setup/` and `lib/features/time_confirm/` returned **0 raw `Color(0x...)` or `#RRGGBB` literals**. All colors routed through `AppColors.*`. PASS.

`bridge_onboarding_tooltip.dart:60` has one inline `Color(0x14000000)` for shadow — documented as black @ 8%. Acceptable but could be promoted to an `AppShadows` token.

---

## Recommended Tiered Fixes

### Tier 1 — Spec-correctness blockers
1. **TimeConfirm**: Rename app bar `시간 설정 확인` → `시간설정`; section titles `주별 총 사용시간` → `2월 1주 사용 시간`, `요일별 사용시간` → `일간 사용 계획`. Empty CTA `닫기` → `확인`.
2. **CompleteV2**: Restore spec copy — title `시간 설정 완료!` (drop "다음주" prefix), body to spec text. Body color → `inkBlack`/`textPrimary` not gray600.
3. **OnboardingTooltip**: Invert palette to dark (bg `gray600`, text `white`/`gray100`). Add bulleted structure + close X icon. Match Figma tooltip layout exactly or split into a `BridgeDarkTooltip` variant.
4. **TimeSetupV2 intro screen**: Add `TimeSetupStep.intro` + `IntroPage` rendering v2-1 splash (heading + subtitle + 3-step list + `시작` CTA).

### Tier 2 — Functional gaps
5. **Per-week data model**: Extend `TimeSchedule` with `List<WeeklyTotal>` (4 entries). Wire `BridgeWeekRow.onTap` per week. Resolves the TODOs at `weekly_time_setup_page.dart:88-93, 102-106`.
6. **`자동계산` implementation**: Populate `_handleAutoDistribute` to evenly split remaining time across editable weeks (09-time-v2.md:152).
7. **DailyV2**: Add `스케줄 보기` pill alongside `사용리포트 보기`. Wrap rows in `Border` (1.2px `destructiveBorderSoft` for over, `primary` for under) when out of balance.
8. **TimeConfirm divider**: Insert `Container(height: 7, color: AppColors.gray150)` between weekly + daily sections.

### Tier 3 — Polish / token hygiene
9. **`자동계산` disabled-when-balanced state** (v2-5 spec).
10. **WeeklyTimeSetupPage v2 title** `주별 총 사용시간` → `2월 잔여 시간` when `showPastWeekDim`.
11. **Remove `_AddAllocationTile`** from v2 daily flow (or hide when `showPastWeekDim` — v2 always opens with 3 prefilled rows).
12. **Promote shadow `Color(0x14000000)` to an `AppShadows.cardSmall` token** for tooltip + future card surfaces.

---

## Files referenced in this audit
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_v2_root_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/schedule_register_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_review_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/time_setup_complete_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/state/time_setup_controller.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_confirm/presentation/pages/time_confirm_page.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_confirm/state/time_confirm_controller.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_confirm/data/mock/time_confirm_mock.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/feedback/bridge_onboarding_tooltip.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/buttons/bridge_pill_icon_button.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/layout/bridge_week_row.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/layout/bridge_day_row.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/layout/bridge_total_time_card.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/theme/app_colors.dart`
