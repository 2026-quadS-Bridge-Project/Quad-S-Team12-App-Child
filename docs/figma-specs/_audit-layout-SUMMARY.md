# Layout Audit — Comprehensive Summary

**Scope**: Synthesis of 16 per-page audits at `docs/figma-specs/_audit-layout/01..16-*.md`.
**Date**: 2026-05-18.
**Mode**: Diagnostic only — no code changes recommended in this document; see originating per-page docs for full reasoning.
**Citation convention**: every finding references its per-page audit doc, e.g. `see _audit-layout/12-report.md Issue 20`.

---

## A. Executive summary

| Page (per-audit doc) | Total issues | Critical | Tier 1 | Tier 2 | Tier 3 |
|---|---:|---:|---:|---:|---:|
| 01-BridgeAppBar | 4 | 1 | 2 | 0 | 1 |
| 02-hit-test-onpressed | 21 | 4 | 4 | 9 | 4 |
| 03-safearea-scaffold | 11 FAIL pages | 11 | 0 | 0 | 0 |
| 04-login | 10 | 2 | 3 | 4 | 1 |
| 05-signup | 10 | 1 | 4 | 4 | 1 |
| 06-home-intro | 8 | 0 | 2 | 4 | 2 |
| 07-child-home | 13 | 2 | 3 | 4 | 4 |
| 08-mypage | 9 | 1 | 3 | 3 | 2 |
| 09-password-change | 14 | 1 | 3 | 7 | 3 |
| 10-delete-complete | 13 | 0 | 3 | 1 | 9 |
| 11-notifications | 10 | 0 | 2 | 5 | 3 |
| 12-report | 21 | 6 | 7 | 7 | 1 |
| 13-time-setup-v1 | 27 | 3 | 12 | 10 | 2 |
| 14-time-setup-v2 | 8 | 1 | 5 | 2 | 0 |
| 15-time-confirm | 10 | 3 | 4 | 2 | 1 |
| 16-mission | 45 | 6 | 14 | 12 | 13 |
| **Totals** | **234** | **42** | **71** | **74** | **47** |

Severity buckets:
- **Critical** = blocks usability (dead button, status-bar overlap, broken nav, security flaw, disabled-state bypass).
- **Tier 1** = end-user-visible Figma mismatch (copy, color, size, layout sequence).
- **Tier 2** = drift/polish (token usage, minor spacing, secondary icon swaps).
- **Tier 3** = info/verified-OK checkpoints.

---

## B. Critical (blocks usability)

### B.1 Dead buttons (onTap empty / no-op / null with no path forward)

- `[Notifications] notifications_page.dart:121` — Notification card `onTap: () {}` is a no-op even though `${item.actionLabel} →` invites tap-to-navigate — Wire `_handleTap(item)` dispatcher routing by `item.type` (see `_audit-layout/02-hit-test-onpressed.md` Finding 3 and `_audit-layout/14-time-setup-v2.md` Issue 8).
- `[Weekly time setup] weekly_time_setup_page.dart:72,163` — `자동계산` button is enabled but `_handleAutoDistribute` body is empty `{}` — Either implement even-split (`totalWeeklyCapMinutes / 4`) or null-gate the button until ready (see `_audit-layout/02-hit-test-onpressed.md` Finding 6 and `_audit-layout/13-time-setup-v1.md` weekly Issue 4).
- `[Notifications] notification_card.dart:102–122` — `_DeleteRevealIcon` revealed under the card has no `GestureDetector`; only drag past 85% triggers delete — Wrap the icon in a tap detector that calls `widget.onDeleteIntent(widget.item)` (see `_audit-layout/02-hit-test-onpressed.md` Finding 5).
- `[Child home] child_home_page.dart:327, 616` — Decorative `Icon(Icons.settings, gray300)` with no detector sits where active state has an `IconButton` — Add tooltip or `Semantics(button: true, enabled: false)` (see `_audit-layout/02-hit-test-onpressed.md` Finding 12).
- `[Child home] child_home_page.dart:332–343` — `Text('사용 리포트')` in `!hasContent` branch is not interactive, but the active state wires the same affordance — Either gray out heavily or wire `context.push('/child-home/report')` (see `_audit-layout/02-hit-test-onpressed.md` Finding 13).
- `[Mission camera] mission_info_page.dart:493–496` — `BridgeButton('제출', onPressed: null)` is permanently disabled if user cancels camera picker, with no path forward besides "back" — Auto-pop on cancel or add helper text `사진을 먼저 촬영해주세요` (see `_audit-layout/02-hit-test-onpressed.md` Finding 19).

### B.2 Status bar / notch overlap (back button under notch)

- `[BridgeAppBar root cause] bridge_app_bar.dart:45,49–88` — `preferredSize` is a flat 52 px with no `MediaQuery.padding.top` and no `SafeArea(top: true)`; when supplied to `Scaffold.appBar:` the back chevron renders at absolute Y ≈ 14, inside the 44 px notch region — Fix `BridgeAppBar` source (add SafeArea + inset-aware preferredSize) OR migrate all consumers to inline `SafeArea > Column > [BridgeAppBar, ...]` pattern (see `_audit-layout/01-BridgeAppBar.md` Issues 1, 2, 4 and `_audit-layout/03-safearea-scaffold.md`).
- 11 FAIL pages confirmed via `_audit-layout/03-safearea-scaffold.md`: `report_page.dart:44`, `time_setup_intro_page.dart:34`, `schedule_register_page.dart:40`, `weekly_time_setup_page.dart:42`, `daily_time_setup_page.dart:51`, `time_setup_review_page.dart:33` (also uses `SafeArea(top: false)` so it double-fails), `time_confirm_page.dart:81`, and four sub-views of `mission_info_page.dart` (`_InfoView`, `_PerformView`, `_CameraPromptView`, `_PhotoPreviewView`).
- `[Mission submitted] mission_info_page.dart _SubmittedView` — No appbar at all; spec requires `미션수행` topbar — Add `appBar: BridgeAppBar(title: '미션수행', onBack: () => context.go('/child-home'))` (see `_audit-layout/16-mission.md` Issue 37).

### B.3 Broken navigation (wrong route, stack destruction)

- `[Login] login_page.dart:120` — Back button uses `context.go('/')` which wipes the navigation stack and re-triggers `HomePage._redirectCachedLogin` — Remove override; rely on `BridgeAppBar`'s default `context.pop()`, or change default to `context.canPop() ? context.pop() : context.go('/')` (see `_audit-layout/04-login.md` Issue 4).
- `[Signup] signup_page.dart:228` — Same anti-pattern (`onBack: () => context.go('/')`) (see `_audit-layout/05-signup.md` Issue 3).
- `[Signup] signup_page.dart:194` — Post-signup success calls `context.go('/')`, dumping the user back on the marketing entry screen instead of auto-logging in to `/child-home` or handing off to `/login` — Pick Option A (auto-login + go `/child-home`) or B (`go /login` with prefilled username) (see `_audit-layout/05-signup.md` Issue 1).
- `[Schedule register] schedule_register_page.dart:40–43` — Back chevron unconditionally `context.go('/child-home')`, destroying wizard state and any partial selections without confirmation; spec says back should return to wizard intro — Route to `controller.goToStep(intro)` or gate behind confirmation dialog (see `_audit-layout/13-time-setup-v1.md` schedule_register Issue 1).
- `[Time setup v2 pills] daily_time_setup_page.dart:78–98` — `사용리포트 보기` / `스케줄 보기` pills push `/child-home/...` routes, destroying the wizard state mid-flow; spec models them as in-flow reference modals — Replace with bottom-sheet / dialog presenters (see `_audit-layout/14-time-setup-v2.md` Issue 4).

### B.4 Security flaws (plaintext password)

- `[Login] login_page.dart:139–153, 226` — `_LoginField` lacks `obscureText`; 비밀번호 input renders typed characters as cleartext on screen — Add `obscureText` parameter to `_LoginField` and pass `true` for the password field; consider `autofillHints: [AutofillHints.password]` (see `_audit-layout/04-login.md` Issue 1).
- `[Signup] signup_page.dart:360 (_SignupField)` — Same plaintext defect (see `_audit-layout/04-login.md` Issue 1 and `_audit-layout/05-signup.md` for sibling reference).
- `[Login] login_page.dart:21–22` — `_mockUsernames`/`_mockPassword` (`'Gdg123456789!'`) baked into release binary as `static const` — Gate behind `kDebugMode` or remove before any external release (see `_audit-layout/04-login.md` Issue 10).

### B.5 Disabled-state bypass (button fires when visually disabled)

- `[Password change] password_change_page.dart:241–244, 465–495` — `_PasswordChangeButton.enabled` flag only paints colors; the underlying `FilledButton.onPressed` is wired unconditionally, so the gray "disabled" button still consumes the tap, dismisses keyboard, and surfaces red helper text on fields the user has not touched — Change to `onPressed: enabled ? onPressed : null` (or swap to `BridgeButton`) so disabled visual matches disabled hit-test (see `_audit-layout/02-hit-test-onpressed.md` Finding 1).

### B.6 Other Critical findings flagged in per-page audits

- `[Child home] child_home_page.dart:671–796` — All 5 mission cards render identical mock copy (`방청소 하기` + `청소` icon); only the trailing status icon varies — Extend `_MissionItemData` with `title/subtitle/iconAsset` and seed distinct values (see `_audit-layout/07-child-home.md` Issue 2).
- `[Child home] child_home_page.dart:26–29, 48–52, 356` — Debug-only long-press toggle (`_toggleHasScheduleForDebug`) wired to the today-time card in production — Gate behind `kDebugMode` (see `_audit-layout/07-child-home.md` Issue 3).
- `[Home intro] home_page.dart:30–47` — `_redirectCachedLogin()` paints the intro UI for ~1 frame before navigating away on cached login; race window allows user to push `/signup` or `/login` before the redirect's `context.go` replaces (see `_audit-layout/06-home-intro.md` Issue 1).
- `[Report] report_page.dart:158–181, assets/icons/cat.svg` — `imgCatIllustration` is a single-path light-blue blob (same color as bubble bg), not the Figma cat artwork — Re-export from Figma node `750:11937` (see `_audit-layout/12-report.md` Issue 2).
- `[Report] report_page.dart:404, 450–481` — Sub-hour deltas round to `0시간` chips (e.g., 20-min delta → `▲ 0시간`); Material `arrow_drop_*` icon used in place of 12×12 polygon — Add `<1시간` / minute formatting and replace icon with SVG triangle (see `_audit-layout/12-report.md` Issues 6, 7).
- `[Report] report_page.dart:491–537, bridge_pie_chart.dart:56` — Pie + legend stacked vertically (spec is side-by-side); per-slice label positions diverge from Figma's bespoke offsets — Refactor card to `Row[legend, pie]`; consider hard-coded per-slice offsets (see `_audit-layout/12-report.md` Issues 10, 11).
- `[Report] report_page.dart:498, bridge_pie_chart.dart:94, usage_report.dart:27` — Title displays `계획 이행률 20%` (`onPlanPct`) but spec text is `계획 이행률 50%` — Clarify semantics with design (see `_audit-layout/12-report.md` Issue 12 and Section G below).
- `[Report] report_page.dart:606–625, usage_report.dart:30–35` — Card 5 suggestion rows missing the `7 시간 00 분` hour column required by spec; model lacks `plannedHoursPerDay` — Extend `AiSuggestion` and add the column (see `_audit-layout/12-report.md` Issue 14).
- `[Time-confirm tooltip] time_confirm_page.dart:186–196` — `BridgeOnboardingTooltip` positioned with magic `top: -64, right: 0` and `arrowAlignment: bottomCenter`, but Figma puts the tooltip BELOW the pill with arrow pointing UP — Switch arrow direction and compute offset from layout (see `_audit-layout/15-time-confirm.md` Issue 6).
- `[Time-confirm tooltip] time_confirm_page.dart:191–192` — Tooltip body lacks title, 2nd bullet, underlined emphasis, and close (X) icon — Extend `BridgeOnboardingTooltip` API with `title`, `List<TooltipBullet>`, `onClose` (see `_audit-layout/15-time-confirm.md` Issue 7).
- `[Time-confirm section title] time_confirm_page.dart:171–176` — `일간 사용 계획` uses `headlineBold` (18) + `textPrimary` (black) instead of `heading2Bold` (20) + `gray800` — Replace with `AppTypography.heading2Bold.copyWith(color: AppColors.gray800)` (see `_audit-layout/15-time-confirm.md` Issue 5).
- `[Time-setup v2] daily_time_setup_page.dart, bridge_delta_banner.dart` — Spec `1.2px destructiveBorderSoft / primary` frame border around day rows is **never rendered**; token defined at `app_colors.dart:54` but no consumer — Add conditional `Container(decoration: ... border: ...)` wrap when `controller.isOverBudget || isUnderBudget` (see `_audit-layout/14-time-setup-v2.md` Issue 6).
- `[Time-setup v1] daily_time_setup_page.dart:73–77` — `_TotalSummaryCard` invents a progress bar; spec has no progress bar — Replace with `BridgeTotalTimeCard` (see `_audit-layout/13-time-setup-v1.md` daily Issue 1).
- `[Time-setup v1] daily_time_setup_page.dart:259–309` — `_AddAllocationTile` is a 75h white rounded card; spec is a 40×40 circular `+` button — Replace with `BridgeAddCircleButton` (see `_audit-layout/13-time-setup-v1.md` daily Issue 3).
- `[Mission tab architecture] mission_info_page.dart _PerformView vs _InfoView` — Figma models `746-11380` as the `수행정보` TAB STATE of one screen, but implementation builds a separate Scaffold under `MissionFlowStep.perform`; the `_MissionPerformInfoTab` stub leaks into production — Merge `_PerformView` into `_InfoView`'s second tab (see `_audit-layout/16-mission.md` Issues 1, 11).
- `[Mission submitted] mission_info_page.dart _SubmittedView reviewing branch` — Uses `Icons.hourglass_empty` on `gray400`; spec says reviewing AND completed share the SAME primary-blue circle + white check, differing only by copy — Drop hourglass; unify to `Icons.check` + `primary` (see `_audit-layout/16-mission.md` Issue 36).
- `[Mission rejected] mission_info_page.dart _SubmittedView rejected branch` — Branch invented (`Icons.close`, destructive bg, `미션 반려` copy) but spec line 232 explicitly says "No explicit `rejected` screen was provided in this batch" — Remove or mark `// TODO(design)` (see `_audit-layout/16-mission.md` Issue 34 and Section G below).

---

## C. Tier 1 (visible Figma mismatch)

End-user-visible mismatches: wrong layout sequence, wrong colors, wrong text, wrong sizes.

### C.1 Chip/button sizes

- `[Mypage] my_page.dart:133–139` — 탈퇴하기 uses `BridgeButton(size: medium, fullWidth: false)` = **120×42**; Figma `257:3713` spec = **80×35** — Add `BridgeButtonSize.chip` variant OR extend `_MyPageActionButton` to accept destructive palette (see `_audit-layout/08-mypage.md` Issue 3).
- `[Mission] mission_info_page.dart _CameraPromptView _CameraCTA` — Dashed CTA height **200**; spec ~**156** (padded 52V/83H). Icon size **32**; spec **24** (see `_audit-layout/16-mission.md` Issues 20, 21).
- `[Mission submitted] mission_info_page.dart _SubmittedView` — Icon **32 px** inside **60 px** circle; spec ~20 px (33% inset) (see `_audit-layout/16-mission.md` Issue 35).
- `[Delete-complete] delete_account_complete_page.dart` — Token `heading2Bold` is w600 (SemiBold); Figma requires **Bold w700**; text color `inkBlack` (#050505) vs Figma `gray600` (#5F6165) (see `_audit-layout/10-delete-complete.md` Issues 4, 6).

### C.2 Paraphrased Korean copy (verbatim Figma strings missing)

- `[Time-setup v1 intro] time_setup_intro_page.dart:46` — Title `'Hi! 다음주 시간 계획을 짜볼까요?'` vs Figma `사용시간 설정`; entire subtitle (`한 달 동안 쓸 시간을…` / `3단계만 따라오면 끝나요`) missing; step labels render `① 사용할 시간을 등록해요` instead of `스케줄 등록` (see `_audit-layout/13-time-setup-v1.md` intro Issues 1, 3 and `_audit-layout/14-time-setup-v2.md` Issue 2).
- `[Schedule register] schedule_register_page.dart:75` — Title `'핸드폰 사용 가능한 시간을 선택해주세요'` vs Figma `스케줄 등록`; 2-line description paraphrased (see `_audit-layout/13-time-setup-v1.md` schedule_register Issue 3).
- `[Weekly] weekly_time_setup_page.dart:63–66` — Title `'주별 사용 시간을 설정해주세요'` vs Figma `주별 시간 분배`; description paraphrased (see `_audit-layout/13-time-setup-v1.md` weekly Issue 2).
- `[Daily] daily_time_setup_page.dart:66–71` — Title `'요일별 사용시간을 분배해주세요'` vs Figma `이번주 일간 시간 설정`; description `'주별 총 시간 …'` paraphrased; spec is `거의 다 왔어요! / 내가 설정한 이번주의 시간을 일별로 분배해요.` (see `_audit-layout/13-time-setup-v1.md` daily Issue 2).
- `[Review] time_setup_review_page.dart:56–60` — Description `'확인 후 등록해주세요.'` invented; spec reuses the daily-step description verbatim (see `_audit-layout/13-time-setup-v1.md` review Issue 2).
- `[Report Cards 2/3/5] report_page.dart` — Card 2 caption hard-coded `'나의 시간 계획'` vs Figma `2월 1주차 나의 계획은`; Card 3 missing two-line summary (`화·토·일에 계획보다 많이 사용했어요.` / `월·금에는 계획보다 적게 사용하는 날이 많았어요.`); Card 5 missing caption `다음주는 이렇게 조정해보자` (see `_audit-layout/12-report.md` Issue 3).
- `[Mission camera] mission_info_page.dart _CameraPromptView` — Subtitle `'사진을 찍어 미션을 인증해주세요.'` vs Figma verbatim `'깨끗해진 방을 찍어서 올려주세요!'`; hint `최대 4장까지 올릴 수 있어요` missing on the camera-prompt screen (spec requires it on 426-18960 as well as preview screens) (see `_audit-layout/16-mission.md` Issues 18, 19).
- `[Mission preview] mission_info_page.dart _PhotoPreviewView` — Mission subtitle dropped after camera-prompt; should persist through 1/3/4-photo states (see `_audit-layout/16-mission.md` Issue 27).
- `[Mission topbar] mission_info_page.dart _InfoView, _CameraPromptView` — AppBar title literals `'미션 정보'` / `'미션 수행'` vs Figma `방청소하기` (dynamic) / `미션수행` (no space) (see `_audit-layout/16-mission.md` Issues 5, 16).
- `[Time-setup complete] time_setup_complete_page.dart:38–73` — Hero stack gaps **24/16** vs Figma **gap=40** for both title↔icon and icon↔message (see `_audit-layout/13-time-setup-v1.md` complete Issue 1).
- `[Notifications mock] notifications_mock.dart:8–30` — Three mock messages rewritten in child-perspective vs parent's parent-perspective (`자녀가 ...` → `... 부모님께 전달`); product decision required (see `_audit-layout/11-notifications.md` Issue 1).

### C.3 Missing 5/5 mission card differentiation

- `[Child home] child_home_page.dart:671–796` — All 5 mission cards render `방청소 하기` + `청소` SVG; only trailing status icon varies — Extend `_MissionItemData` with `title/subtitle/iconAsset`; assets exist for 청소/운동/학습/심부름/루틴/시계 (see `_audit-layout/07-child-home.md` Issue 2).

### C.4 Wrong layout sequence / wrong slot

- `[Time-setup v2 weekly] weekly_time_setup_page.dart:87–113` — Renders 5 rows (`지난 주` dimmed aggregate + `1주차/2주차/3주차/4주차`) where spec has 4 rows (`1주차` locked + `2/3/4주차` editable); past-week row sources from `controller.schedule.totalWeeklyHours` (aggregate) instead of `previousWeek.weeklyTotals[0]` (see `_audit-layout/14-time-setup-v2.md` Issues 1, 3).
- `[Time-setup v2 daily pills] daily_time_setup_page.dart:78–98` — Wrong `BridgePillVariant.ghost` (should be `tonal`); order swapped (`사용리포트` first instead of `스케줄`); placed above day list instead of inside section header (see `_audit-layout/14-time-setup-v2.md` Issue 4).
- `[Report Card 4 pie] report_page.dart:491–537` — Pie + legend stacked vertically; spec is `Row[legend, pie]` side-by-side with `imgEllipseGroupContainer` 5-wide color strip (see `_audit-layout/12-report.md` Issue 11).
- `[Mission info layout] mission_info_page.dart _InfoView` — `_AssignedByChip` stacked above `mission.title` in a `_MissionHeaderCard`; spec puts `방청소하기` in the appbar with no header card and no chip; `_RewardChip` rendered as standalone hero element, but spec frames it INSIDE the `지급시간` row of the info tab (see `_audit-layout/16-mission.md` Issues 3, 4).
- `[Mission category chips] mission_info_page.dart _MissionInfoTab` — `_InfoChipRow(label: '카테고리', value: mission.category)` is a single-value pill; spec requires a horizontal Wrap of selectable chips (`루틴/학습/운동/청소/심부름`) with selected/unselected variants (see `_audit-layout/16-mission.md` Issue 2).
- `[Time-confirm empty] time_confirm_page.dart:117` — Adds `Icons.event_busy_outlined` icon; spec empty state is **text-only** (see `_audit-layout/15-time-confirm.md` Issue 3).
- `[Time-setup v1 stepper palette] bridge_stepper_pills.dart` — Widget uses `primary` for current pill + `primarySubtle` for completed; Figma is `primarySubtle` for current + `gray150` for completed/upcoming (palette inverted) (see `_audit-layout/13-time-setup-v1.md` schedule Issue 2 + cross-cutting #1).

### C.5 Wrong typography size (visible weight/size mismatch)

- `[Mission] mission_info_page.dart _CameraPromptView, _PhotoPreviewView` — Mission title rendered with `heading2Bold` (20px SemiBold); spec demands `heading1Bold` (24 SemiBold) (see `_audit-layout/16-mission.md` Issues 17, 26).
- `[Time-confirm] time_confirm_page.dart:171–176` — `일간 사용 계획` uses `headlineBold` 18 + `textPrimary`; spec `heading2Bold` 20 + `gray800` (see `_audit-layout/15-time-confirm.md` Issue 5).
- `[Time-setup v1 weekly Card 2 row] weekly_time_setup_page.dart` — Hours rendered as single `headlineBold` text (`시간` unit also SemiBold); spec mixes SemiBold number + Regular unit; padding `16h/12v` vs spec `18h/15v` (see `_audit-layout/13-time-setup-v1.md` weekly Issue 4 and `_audit-layout/12-report.md` Issue 4).

### C.6 Wrong icons / wrong color tones

- `[Child home] child_home_page.dart:327, 616` — Filled Material `Icons.settings` used in empty states; Figma uses outlined cog `mask` SVG asset — Export `settings.svg` (see `_audit-layout/07-child-home.md` Issue 4).
- `[Report Card 5] report_page.dart:642–647` — Positive-tone AI suggestion chip uses `primarySoft` (blue) bg with `positive` (green) text; missing token `positiveSoft` (see `_audit-layout/12-report.md` Issue 15).
- `[Report Card 3] report_page.dart` — `BridgeBarChart` borderData hidden; spec requires L-frame (left + bottom axis line `imgLeftSideYAxis` + `imgXAxisLine`); on-plan rows render no marker (`imgLine2` wave/dash missing) (see `_audit-layout/12-report.md` Issues 5, 8).
- `[Report Card 1] report_page.dart:222–232` — Speech-bubble tail is a centered isosceles triangle in a sibling Column slot; spec is `Polygon 1` (down-right slope) overlapping the bubble border (see `_audit-layout/12-report.md` Issue 1).

---

## D. Tier 2 (drift / polish)

### D.1 Typography token mismatches (catalogue-wide)

- `[AppTypography catalogue-wide unit confusion] app_typography.dart:94, 103, et al.` — `bodyMedium.letterSpacing = 0.57` should be `0.0912` (`bodyBold` on line 94 already uses `0.0912`); likely the same px-vs-%-of-em mistake affects `heading1*`/`heading2*` `letterSpacing: -1.94/-1.2` and `labelBold/Medium: 1.45` and `captionBold/Regular: 2.52` — Audit and fix at catalogue level; remove per-screen `copyWith(letterSpacing: ...)` overrides afterwards (see `_audit-layout/06-home-intro.md` Issue 7).
- `[Delete-complete] heading2Bold token] app_typography.dart:35–42` — Token name says "Bold" but `fontWeight: w600` (SemiBold); Figma `탈퇴가 완료되었습니다.` requires `w700` (see `_audit-layout/10-delete-complete.md` Issue 4).
- `[Password-change topbar] _PasswordChangeTopBar vs BridgeAppBar` — Inline bar uses `headlineMedium` (Medium 500) matching spec; `BridgeAppBar` uses `headlineBold` (SemiBold 600) — spec/widget inconsistency to reconcile before migration (see `_audit-layout/09-password-change.md` Issue 1).

### D.2 Token-defined-but-unreferenced (verified)

- `AppColors.destructiveBorderSoft` (defined `app_colors.dart:54`) — **No consumer in `lib/`** (verified via grep); v2 daily error frame `1.2px` border depends on it (see `_audit-layout/14-time-setup-v2.md` Issue 6).
- `AppColors.secondaryYellow` — Defined `app_colors.dart:75`, used by `notification_card.dart:258–259` for `missionCompleted` chip; **token is consumed** (see `_audit-layout/11-notifications.md` Issue 2).
- `AppColors.scrim` (`#99444444`) — Defined but `_DeleteAccountDialog` (`my_page.dart:44`) and `notifications_page.dart` dialogs both inline `Color.fromRGBO(68,68,68,0.6)` instead (see `_audit-layout/08-mypage.md` Issue 4 and `_audit-layout/11-notifications.md` token table row 16).
- `AppColors.primaryLight` (`#EBF5FE`) — Defined and used by child notifications; parent inlines hex (see `_audit-layout/11-notifications.md` Issue 7).
- `AppTokens.cardRadiusSmall = 16` — Defined `app_tokens.dart:20`; `child_home_page.dart:360, 757` still inline `BorderRadius.circular(16)` (see `_audit-layout/07-child-home.md` Issue 9).
- Duplicate token: `AppTokens.cardShadowColor` and `AppColors.cardShadow` both hold `Color(0x80D9D9D9)` (see `_audit-layout/07-child-home.md` Issue 10).
- `0xFFFF4B4B` (notification swipe icon) — Raw hex in both child + parent; no token either side; verify whether intentional vs `destructive` (`#FF4242`) (see `_audit-layout/11-notifications.md` Issue 3).

### D.3 Secondary icon swaps / dimension polish

- `[Report Card 3 delta chip] report_page.dart:450–481` — Material `arrow_drop_up/down` (font glyph) instead of 12×12 polygon SVG (see `_audit-layout/12-report.md` Issue 6).
- `[Report shadow] report_page.dart:94–99` — `blurRadius: 8` is **4×** spec (`2`/`2.5`); per-card variant blur required (see `_audit-layout/12-report.md` Issue 17).
- `[Child home] child_home_page.dart:291–306, 308–323, 402–414` — Top-right icon buttons 22×22 (below 44×44 WCAG floor) and `+` button 40×40 (below floor); `BridgeAppBar` back button hit area 24×24 (see `_audit-layout/02-hit-test-onpressed.md` Findings 9, 10, 20 and `_audit-layout/07-child-home.md` Issue 1 and `_audit-layout/08-mypage.md` Issue 6).
- `[Password-change inline topbar + notifications inline topbar]` — Custom back buttons with 24-px hit areas duplicating BridgeAppBar; should consolidate (see `_audit-layout/02-hit-test-onpressed.md` Finding 21 and `_audit-layout/09-password-change.md` Issue 1).
- `[Time-confirm divider] time_confirm_page.dart:162–165` — Raw `Container(height: 7, color: gray150)` instead of spec component `BridgeSectionDivider` (see `_audit-layout/15-time-confirm.md` Issue 4).
- `[Mypage dialog] my_page.dart:198–199, 307–308, 269, 315` — Fractional pixel dimensions (`294.897 × 189.705`, `107.889 × 37.761`, `0.899` border) imported as-is from Figma export at non-1× scale (see `_audit-layout/08-mypage.md` Issue 5).
- `[Bubble in report] report_page.dart Card 1` — Cat illustration single-color blob with TODO; bubble tail as triangle, not Polygon SVG (see `_audit-layout/12-report.md` Issues 1, 2).

### D.4 Token / spacing magic numbers

- `[Time-confirm] time_confirm_page.dart` — Magic `24/16/12/-64/7` spacings throughout; existing `AppTokens.pageHorizontal/itemGap/mediumGap` ignored (see `_audit-layout/15-time-confirm.md` Issue 10).
- `[Home intro] home_page.dart:75–80` — `Padding(bottom: 18)` not a token; `Alignment(0, -0.08)` magic number for intro content vertical anchor; `isCompact` LayoutBuilder only changes a 2-px gap (see `_audit-layout/06-home-intro.md` Issues 2, 4, 5).

---

## E. Cross-cutting themes

1. **`BridgeAppBar` in `Scaffold.appBar:` causes status-bar overlap on 11 pages.** Root cause: `bridge_app_bar.dart:45` returns `const Size.fromHeight(52)` and `build()` is a flat `SizedBox(height: 52)` with no `SafeArea` and no `MediaQuery.padding.top`. Inline usage (login, signup, mypage, notifications, password_change) places the bar inside `SafeArea > Column` and works; appBar-slot usage (report, time_confirm, all 5 time_setup pages, all 4 mission sub-views) is broken. Single-source fix at `BridgeAppBar` source resolves all 11 (see `_audit-layout/01-BridgeAppBar.md` Issues 1, 2, 4 and `_audit-layout/03-safearea-scaffold.md` totals: 11 FAIL · 9 PASS · 2 N/A).

2. **Keyboard handling fragility — `Spacer` + `IntrinsicHeight` inside `SingleChildScrollView`.** `login_page.dart:154`, `signup_page.dart:207–305`, `password_change_page.dart:181–240` all use the same anti-pattern; the `Spacer` collapses but `IntrinsicHeight` keeps the column tall and the submit button slips below the keyboard on iPhone SE-class devices (see `_audit-layout/04-login.md` Issue 3, `_audit-layout/05-signup.md` Issue 9, `_audit-layout/09-password-change.md` Issues 2, 11, 14).

3. **Hand-rolled top bars / buttons duplicating Bridge widgets.** `_PasswordChangeTopBar` re-implements `BridgeAppBar`; `_NotificationsTopBar` re-implements it (intentionally per parent-app pattern, but means 3 implementations coexist); `_MyPageActionButton`, `_PasswordRow.수정하기`, `_DeleteDialogButton` (in both mypage and notifications) all duplicate `BridgeButton` / `BridgeConfirmDialog` variants (see `_audit-layout/02-hit-test-onpressed.md` Findings 14, 15, 16, 17, 21 and `_audit-layout/09-password-change.md` Issue 1).

4. **Tokens defined but unreferenced or duplicated.** `destructiveBorderSoft` (no consumer — verified), `AppTokens.cardShadowColor` duplicates `AppColors.cardShadow`, `AppColors.scrim` defined but `_DeleteAccountDialog` and notifications dialogs inline `Color.fromRGBO(68,68,68,0.6)`. `AppColors.secondaryYellow` IS consumed; `AppColors.primaryLight` IS consumed by child (see Section D.2).

5. **Auto-redirect race (HomePage cached-login one-frame flash).** `home_page.dart:30–47` paints the intro UI before `AuthSession.isLoggedIn()` resolves; users with cached login see the marketing screen flash for 1 frame and could conceivably tap a CTA before the redirect's `context.go` lands (see `_audit-layout/06-home-intro.md` Issue 1).

6. **Stepper palette inversion across all 4 stepper-bearing pages.** `BridgeStepperPills` renders current pill as `primary` + completed as `primarySubtle`; Figma is current = `primarySubtle` + completed/upcoming = `gray150` (see `_audit-layout/13-time-setup-v1.md` schedule Issue 2 and cross-cutting #1).

7. **`stepIndex` reading inconsistent.** `schedule_register` reads `controller.stepIndex`; `weekly`, `daily`, `review` hard-code `2`/`3` (see `_audit-layout/13-time-setup-v1.md` weekly Issue 1 + review Issue 5).

8. **No `PopScope` anywhere in the time-setup wizard.** Android system back gesture skips controller's wizard semantics on every page; from Step 3 it pops the entire route (see `_audit-layout/13-time-setup-v1.md` root Issue 2 + complete Issue 3 and `_audit-layout/16-mission.md` Issue 42).

9. **Hit-area regression for child users.** 22 px (`child_home` action cluster), 24 px (`BridgeAppBar` back), 40 px (`child_home` `+`) are all below Apple 44×44 / Material 48×48; children's larger thumbs + lower fine-motor precision amplify this (see `_audit-layout/02-hit-test-onpressed.md` cross-cutting pattern 3).

10. **AppTypography unit confusion (catalogue-wide).** `bodyMedium.letterSpacing` and likely all `heading*Bold/Medium/Regular` styles encode raw %-of-em as px; every consumer overrides via `copyWith(letterSpacing: ...)`, defeating the catalogue purpose (see `_audit-layout/06-home-intro.md` Issue 7).

---

## F. Recommended fix order (ranked sequence)

Critical first, then by impact + dependency chain.

step 1. [Critical] Patch `BridgeAppBar` to wrap `build()` in `SafeArea(top: true, bottom: false)` and expose a constructor / factory that supplies a `MediaQuery`-aware `PreferredSize` wrapper for `appBar:` callers. File: `lib/core/widgets/layout/bridge_app_bar.dart`. Dependencies: none. Unblocks 11 FAIL pages (cite `_audit-layout/01-BridgeAppBar.md` Issues 1, 4 and `_audit-layout/03-safearea-scaffold.md`).

step 2. [Critical] Wire notification card `onTap` dispatcher (route by `item.type`). File: `lib/features/notifications/presentation/pages/notifications_page.dart`. Dependencies: none (cite `_audit-layout/02-hit-test-onpressed.md` Finding 3, `_audit-layout/14-time-setup-v2.md` Issue 8).

step 3. [Critical] Implement OR null-disable `자동계산` button. File: `lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`. Dependencies: none (cite `_audit-layout/02-hit-test-onpressed.md` Finding 6, `_audit-layout/13-time-setup-v1.md` weekly Issue 4).

step 4. [Critical] Fix `_PasswordChangeButton.enabled` mismatch — pass `onPressed: enabled ? onPressed : null`. File: `lib/features/my_page/presentation/pages/password_change_page.dart`. Dependencies: none (cite `_audit-layout/02-hit-test-onpressed.md` Finding 1).

step 5. [Critical] Add `obscureText` parameter to `_LoginField` and `_SignupField`; pass `true` for password slots. File: `lib/features/login/presentation/pages/login_page.dart` + `lib/features/signup/presentation/pages/signup_page.dart`. Dependencies: none (cite `_audit-layout/04-login.md` Issue 1).

step 6. [Critical] Remove `onBack: () => context.go('/')` overrides on login + signup; rely on `BridgeAppBar` default `pop()`. File: `lib/features/login/presentation/pages/login_page.dart`, `lib/features/signup/presentation/pages/signup_page.dart`. Dependencies: none (cite `_audit-layout/04-login.md` Issue 4, `_audit-layout/05-signup.md` Issue 3).

step 7. [Critical] Pick post-signup flow (auto-login → `/child-home` OR handoff → `/login`); replace `context.go('/')`. File: `lib/features/signup/presentation/pages/signup_page.dart`. Dependencies: none (cite `_audit-layout/05-signup.md` Issue 1).

step 8. [Critical] Gate `child_home_page.dart` long-press debug toggle behind `kDebugMode`. File: `lib/features/child_home/presentation/pages/child_home_page.dart`. Dependencies: none (cite `_audit-layout/07-child-home.md` Issue 3).

step 9. [Critical] Extend `_MissionItemData` with `title/subtitle/iconAsset` and seed 5 distinct cards. File: `lib/features/child_home/presentation/pages/child_home_page.dart`. Dependencies: none (cite `_audit-layout/07-child-home.md` Issue 2).

step 10. [Critical] Gate the `schedule_register_page` back-chevron escape behind a confirmation dialog OR route to wizard intro. File: `lib/features/time_setup/presentation/pages/schedule_register_page.dart`. Dependencies: step 11 (intro wiring) if routing to intro (cite `_audit-layout/13-time-setup-v1.md` schedule_register Issue 1).

step 11. [Tier 1] Wire `TimeSetupStep.intro` → `TimeSetupIntroPage` in `time_setup_root_page.dart`; decide whether v1 starts at `intro`. File: `lib/features/time_setup/presentation/pages/time_setup_root_page.dart`. Dependencies: none (cite `_audit-layout/13-time-setup-v1.md` root Issue 1).

step 12. [Critical] Fix `time_confirm_page` onboarding tooltip arrow direction + remove magic `-64` offset (anchor via `OverlayEntry`/`CompositedTransformFollower` or switch to `topCenter` + computed offset). File: `lib/features/time_confirm/presentation/pages/time_confirm_page.dart` + `lib/core/widgets/feedback/bridge_onboarding_tooltip.dart`. Dependencies: none (cite `_audit-layout/15-time-confirm.md` Issue 6).

step 13. [Critical] Add title + 2nd bullet + close (X) + underlined emphasis to `BridgeOnboardingTooltip` API; migrate `time_confirm_page` caller to spec-accurate copy. File: `lib/core/widgets/feedback/bridge_onboarding_tooltip.dart`, `lib/features/time_confirm/presentation/pages/time_confirm_page.dart`. Dependencies: step 12 (cite `_audit-layout/15-time-confirm.md` Issue 7).

step 14. [Critical] Restore Figma-verbatim copy on time-setup v1/v2 intro, schedule, weekly, daily, review headers. Files: `time_setup_intro_page.dart`, `schedule_register_page.dart`, `weekly_time_setup_page.dart`, `daily_time_setup_page.dart`, `time_setup_review_page.dart`. Dependencies: none (cite `_audit-layout/13-time-setup-v1.md` schedule/weekly/daily/review Issue 2/3 and `_audit-layout/14-time-setup-v2.md` Issue 2).

step 15. [Critical] Replace `_TotalSummaryCard` (progress bar) with `BridgeTotalTimeCard`; replace `_AddAllocationTile` with 40×40 `BridgeAddCircleButton`. File: `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`. Dependencies: none (cite `_audit-layout/13-time-setup-v1.md` daily Issues 1, 3).

step 16. [Critical] Add `previousWeek` to `TimeSetupController`; refactor `weekly_time_setup_page` to render 4 rows (1주차 locked + 2/3/4주차 editable) instead of 5; pull dimmed row from `controller.previousWeek?.weeklyTotals[0]`. Files: `time_setup_controller.dart`, `weekly_time_setup_page.dart`. Dependencies: none (cite `_audit-layout/14-time-setup-v2.md` Issues 1, 3).

step 17. [Critical] Fix daily v2 pills: variant `tonal` (not `ghost`), swap order (`스케줄 보기` first), replace `context.push` with in-flow modals, move into section header row. File: `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`. Dependencies: none (cite `_audit-layout/14-time-setup-v2.md` Issue 4).

step 18. [Critical] Implement `1.2px destructiveBorderSoft / primary` error frame around day rows when `isOverBudget || isUnderBudget`. File: `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`. Dependencies: none (cite `_audit-layout/14-time-setup-v2.md` Issue 6).

step 19. [Critical] Unify `_SubmittedView` reviewing + completed icons (both = `Icons.check` on `primary` 60×60 circle); add `미션수행` topbar. File: `lib/features/mission/presentation/pages/mission_info_page.dart`. Dependencies: step 1 (cite `_audit-layout/16-mission.md` Issues 36, 37).

step 20. [Critical] Merge `_PerformView` into `_InfoView` as the `수행정보` tab body; drop `MissionFlowStep.perform`. File: `lib/features/mission/presentation/pages/mission_info_page.dart` + `lib/features/mission/state/mission_controller.dart`. Dependencies: none (cite `_audit-layout/16-mission.md` Issues 1, 11).

step 21. [Critical] Remove speculative `_SubmittedView` rejected branch OR mark `// TODO(design)`; file design ticket. File: `lib/features/mission/presentation/pages/mission_info_page.dart`. Dependencies: none (cite `_audit-layout/16-mission.md` Issue 34).

step 22. [Critical] Replace report Card 1 cat asset with re-exported Figma artwork; fix Card 3 sub-hour delta formatting (`<1시간` / minute fallback); replace Material `arrow_drop_*` with 12×12 SVG triangle. Files: `assets/icons/cat.svg`, `lib/features/report/presentation/pages/report_page.dart`. Dependencies: design export (cite `_audit-layout/12-report.md` Issues 2, 6, 7).

step 23. [Critical] Refactor report Card 4: `Row[legend, pie]` side-by-side; reconsider per-slice label offsets; reconcile `계획 이행률` percentage with design semantics. File: `lib/features/report/presentation/pages/report_page.dart` + `lib/core/widgets/charts/bridge_pie_chart.dart` + `lib/features/report/data/models/usage_report.dart`. Dependencies: Section G product decision (cite `_audit-layout/12-report.md` Issues 10, 11, 12).

step 24. [Critical] Add hour column to report Card 5 suggestion rows; extend `AiSuggestion` model. Files: `report_page.dart`, `usage_report.dart`. Dependencies: none (cite `_audit-layout/12-report.md` Issue 14).

step 25. [Tier 1] Fix 탈퇴하기 chip 120×42 → 80×35 (add `BridgeButtonSize.chip` OR extend `_MyPageActionButton`). File: `lib/core/widgets/buttons/bridge_button.dart` + `lib/features/my_page/presentation/pages/my_page.dart`. Dependencies: none (cite `_audit-layout/08-mypage.md` Issue 3).

step 26. [Tier 2] Fix `AppTypography.bodyMedium.letterSpacing` (and audit all heading*/label*/caption* styles for px-vs-%-of-em). File: `lib/core/theme/app_typography.dart`. Dependencies: catalogue-wide regression test before merging (cite `_audit-layout/06-home-intro.md` Issue 7).

step 27. [Tier 2] Fix `heading2Bold` token weight `w600 → w700` (or override per-call on `delete_account_complete_page`); also fix that page's color `inkBlack → gray600`. File: `lib/core/theme/app_typography.dart` OR `lib/features/my_page/presentation/pages/delete_account_complete_page.dart`. Dependencies: step 26 if catalogue fix; verify all `heading2Bold` consumers (cite `_audit-layout/10-delete-complete.md` Issues 4, 5, 6).

step 28. [Tier 2] Migrate keyboard-layout pages off `Spacer + IntrinsicHeight + SingleChildScrollView` to fixed-spacing column or move CTA to `Scaffold.bottomNavigationBar` + `MediaQuery.viewInsets.bottom`. Files: `login_page.dart`, `signup_page.dart`, `password_change_page.dart`. Dependencies: step 1 (so `BridgeAppBar` can be lifted to `Scaffold.appBar:`) (cite `_audit-layout/04-login.md` Issue 3, `_audit-layout/05-signup.md` Issue 9, `_audit-layout/09-password-change.md` Issues 2, 11, 14).

step 29. [Tier 2] Replace hand-rolled `_DeleteDialogButton` (mypage + notifications) with `BridgeConfirmDialog.show`; replace `_MyPageActionButton`, `_PasswordRow 수정하기`, `_PasswordChangeButton` with `BridgeButton` variants; replace `_PasswordChangeTopBar` with `BridgeAppBar`. Files: `my_page.dart`, `notifications_page.dart`, `password_change_page.dart`. Dependencies: step 27 (verify `BridgeAppBar` title weight matches `_PasswordChangeTopBar`'s Medium-500 per spec 04a) (cite `_audit-layout/02-hit-test-onpressed.md` Findings 14, 15, 16, 17 and `_audit-layout/09-password-change.md` Issue 1).

step 30. [Tier 2] Fix stepper palette: current = `primarySubtle`, completed/upcoming = `gray150`. File: `lib/core/widgets/layout/bridge_stepper_pills.dart`. Dependencies: none (cite `_audit-layout/13-time-setup-v1.md` schedule Issue 2 + cross-cutting #1).

---

## G. Out-of-scope / design decisions pending

- **Notifications child vs parent message direction.** Mock copy was rewritten from child perspective (`자녀가 ...` → `... 부모님께 전달`); product must decide whether child surface should mirror parent verbatim or keep child-perspective rewrite. The shared `NotificationType` enum collapses two opposite-direction events under one symbol (`missionConfirmationRequested` = sent vs received). See `_audit-layout/11-notifications.md` Issues 1, 10.
- **Mission rejected screen design absence.** Spec line 232 (`11-mission.md`) explicitly says "No explicit `rejected` screen was provided in this batch"; current `_SubmittedView` rejected branch is speculative — needs Figma node or removal. See `_audit-layout/16-mission.md` Issue 34, open question 5.
- **사용 리포트 `계획 이행률` semantics (20% vs 50%).** Model returns `onPlanPct = 20%`; spec text shows `계획 이행률 50%` (= over-plan days). Three interpretations possible: on-plan only / on-plan + over / used-hours ÷ planned-hours. Design must clarify before model gates. See `_audit-layout/12-report.md` Issue 12.
- **`자동계산` (weekly) logic spec.** Current implementation is empty TODO; spec says "Auto-distributes monthly total evenly across 4 weeks. Becomes idle/disabled after first manual edit" — needs explicit predicate definition (`controller.canAutoDistribute` derivation, behavior when `monthlyCap == 0`, behavior after partial edits). See `_audit-layout/13-time-setup-v1.md` weekly Issues 4, 5.
- **Settings / bar-chart SVG assets needed.** Figma outlined cog `settings.svg`, bar-chart `bar_chart.svg`, `imgLine2` wave/dash, `Polygon 1` re-export, `imgCatIllustration`, `imgEllipseGroupContainer`, 12×12 triangle SVGs all need export to `assets/icons/`. See `_audit-layout/07-child-home.md` Issue 4 and `_audit-layout/12-report.md` Issues 1, 2, 5, 6, 13.
- **Logout button visibility in mypage (Figma omits).** Engineering shipped `로그아웃` (TODO at `my_page.dart:125`), but Figma `03-mypage.md` row at y=364–399 lists only 탈퇴하기 and explicitly notes "로그아웃 button is **NOT present** in this Figma frame". Either remove the button or update Figma. See `_audit-layout/08-mypage.md` Issue 2.
- **Time-confirm `수정하기` affordance vs "request-only" domain model.** Spec line 5: "the child cannot directly edit; they must request the parent" — but pill label is `수정하기` (universal edit affordance) with pencil icon. After onboarding tooltip dismisses, child has no persistent cue that the action is indirect. Possible design changes: `수정 요청` label, outbound/send icon, persistent helper line. Figma label IS `수정하기` (verbatim) — so this is a Figma-level UX defect to surface to design, not a code defect. See `_audit-layout/15-time-confirm.md` Issue 9.
- **`AssignedByChip` on `_InfoView`.** Implementation stacks it above the mission title; spec for `746-11392` does not describe this chip at all. Confirm whether AI/parent registration-source chip is part of the design or speculative scaffolding. See `_audit-layout/16-mission.md` Issue 3, open question 1.
- **Time-setup complete copy unification (`이번주` vs v1 `이번달`).** Phase 5 unified both v1 + v2 to v2 copy (`이번주`); v1's mock uses 4-week (month) totals, so the message is semantically inconsistent with v1's data model. Cross-check `docs/figma-specs/08c-time-v1-errors-done.md` to confirm v1 spec actually wants `이번주`. See `_audit-layout/14-time-setup-v2.md` Issue 5.
- **Time-confirm `수정하기` snackbar honesty.** Snackbar says "부모님께 수정 요청을 보냈어요." but `TimeConfirmController.requestModification()` is a stubbed TODO — surfaces a factual claim with no backend. Either wire the request or change copy to "수정 요청 기능은 곧 제공될 예정입니다". See `_audit-layout/15-time-confirm.md` Issue 8.
