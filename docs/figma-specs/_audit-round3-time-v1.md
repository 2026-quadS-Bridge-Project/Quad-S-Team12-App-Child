# Round 3 Re-Audit — Time Setup v1 Wizard (Diagnostic Only)

Verification of Round 2 fixes against original audit
`docs/figma-specs/_audit-layout/13-time-setup-v1.md`. All checks are
read-only; no code changes performed.

Cross-referenced against Figma specs `08a-time-v1-entry-weekly.md`,
`08b-time-v1-daily.md`, `08c-time-v1-errors-done.md` (file
`tzJjQmXtXO7vGlfCT9SASu`).

---

## time_setup_root_page — PASS

- **PopScope wired**: lines 61-72 wrap body in `PopScope(canPop: previous == null, onPopInvokedWithResult: …)`. `_previousStep()` maps each step to its predecessor (scheduleRegister→null, weeklyTotal→scheduleRegister, dailyAllocation→weeklyTotal, review→dailyAllocation, complete→null). Android system back now rewinds in-wizard.
- **Intro mapping**: still routes `TimeSetupStep.intro → ScheduleRegisterPage` as defensive fallback (line 77). Acceptable; v1 never enters `intro` per controller init.

## time_setup_intro_page — PASS (v2 only, dead in v1)

- Title `사용시간 설정`, subtitle 2-line `한 달 동안 쓸 시간을, 스스로 나눠볼거에요\n3단계만 따라오면 끝나요`, step labels `스케줄 등록 / 주별 시간 분배 / 일별 시간 분배` — all verbatim per 08a `695:8850`. Title `textAlign: center`, gap 40 between title/subtitle/list — matches Round 2 fixes.

## schedule_register_page — PASS

- Title `스케줄 등록`, description `학교, 학원처럼 휴대폰을 거의 못 쓰는 시간을 등록해서\n사용가능한 시간을 편하게 확인해요` — verbatim per 08a `695:8924` nodes 695:8932 / 695:8935.
- `currentStep: controller.stepIndex` (line 74) — consistent with controller.
- `SingleChildScrollView` around the grid still present (line 89). Original Issue 6 (cosmetic) unresolved; out of Round 2 scope.

## weekly_time_setup_page — PARTIAL FAIL

- **PASS** title `주별 시간 분배` and description `부모님이 부여한 이번 달 총 사용 시간을\n주별로 분배해요!` verbatim per 08a `695:11870`.
- **PASS** `자동계산` disabled with Tooltip `곧 사용 가능한 기능이에요` (lines 81-92) — onPressed: null, gray300 text. Misleading affordance removed.
- **FAIL — drift**: `BridgeTotalTimeCard(title: '주별 총 사용시간', …)` still passes a title prop instead of splitting into Figma's two distinct sections: (1) section label `2월 총 사용 시간` + read-only card, (2) `주별 시간 분배` section header + `자동계산` button right-aligned. Spec 08a lines 245-250 explicitly separates these two blocks with gap=40. Round 2 fix kept the merged anatomy.
- **FAIL — drift**: `currentStep: 2` literal (line 58) — not aligned with cross-cutting fix to read `controller.stepIndex` (schedule_register uses controller; weekly still hard-coded).

## daily_time_setup_page — PASS

- **PASS** `_TotalSummaryCard` removed. Replaced with section label `2월 1주차` (Heading2/Bold gray800, line 80-85) + `BridgeTotalTimeCard(hours, minutes)` (lines 87-90). Progress bar gone. Matches 08b §"week time" (border 2px #D5D8DE, radius 12, "15 시간 00 분" centered).
- **PASS** `_AddCircleButton` (lines 306-343) is a 40×40 circular Material with `CircleBorder` + `Icons.add_rounded` size 28 primary, centered via `Center()` wrapper (line 147). Matches 08b §"Daily Distribution Container".
- **PASS** Title `이번주 일간 시간 설정` + description `거의 다 왔어요!\n내가 설정한 이번주의 시간을 일별로 분배해요.` verbatim per 08b/08c.
- **NOTE** `_maxAllocations` raised from 3 to 7 (line 31) — aligns with original Issue 4 spirit, though still a count cap rather than weekday-disjointness gate.
- **FAIL — minor drift**: `currentStep: 3` literal (line 64) — same stepIndex inconsistency as weekly.

## time_setup_review_page — PARTIAL FAIL

- **FAIL — drift**: description `거의 다 왔어요!\n내가 설정한 이번주의 시간을 일별로 분배해요.` (line 59) is acceptable per 08c §"Texts (verbatim)" ("Same as the error frames minus the banner"). However, `BridgeTotalTimeCard(title: '주별 총 사용시간', …)` (line 62-66) injects a title prop not present in 08c spec (which shows label `2월 1주차` separately, NOT inline title).
- **FAIL — drift**: `currentStep: 3` literal (line 50); should use `controller.stepIndex`.
- **NOTE**: `BridgeDayRow.showPencil: false` (line 82) used but tappability of the row when `onEdit` is null was NOT verified in this round.

## time_setup_complete_page — PASS

- **PASS** Hero gaps now 40/40: line 48 `SizedBox(height: 40)` between title and icon, line 68 `SizedBox(height: 40)` between icon and message. Matches 08c `695:12086` §"Main container" line 195 (vertical gap = 40).
- **PASS** Copy verbatim: title `시간 설정 완료!`, body `이번주 시간 계획이 부모님께 전달되었어요.\n이제 계획대로 사용해봐요!`, CTA `홈으로`.
- **NOTE** PopScope is at root level now (handles complete→null = allow pop), no per-page PopScope needed.

## BridgeStepperPills color (cross-widget) — PASS

- `bridge_stepper_pills.dart` lines 49-54: current pill = `AppColors.primarySubtle` (#C2DFFD), others = `AppColors.gray150` (#EDEEF1). Inversion from Round 1 (which used `primary` for current) is corrected and matches 08a `695:11870` §Layout line 240.

---

## Remaining Drift Summary

| Page | Remaining Issue |
|---|---|
| weekly | `BridgeTotalTimeCard` not split into 2 Figma sections (`2월 총 사용 시간` block + `주별 시간 분배` block w/ button) |
| weekly | `currentStep: 2` literal — should read `controller.stepIndex` |
| daily | `currentStep: 3` literal — same as weekly |
| review | `currentStep: 3` literal; `BridgeTotalTimeCard(title: …)` injects unspecified inline title |
| review | `BridgeDayRow` tap-target with `showPencil: false` not verified |
| schedule_register | `SingleChildScrollView` wrapper still present (cosmetic, Issue 6 carryover) |
| controller | `_maxAllocations = 7` cap exists but weekday-disjointness invariant not enforced |
| controller | `자동계산` logic still TODO (Round 2 used disabled+tooltip workaround) |

## Doc path

`/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-time-v1.md`

End of Round 3 audit. No code changes performed.
