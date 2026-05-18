# Layout Audit — Child Home (07)

**Target file**: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/child_home/presentation/pages/child_home_page.dart`
**Figma fileKey**: `tzJjQmXtXO7vGlfCT9SASu`
**Figma nodes**: `426-20978` (v1, empty) + `426-21005` (v2, populated)
**Spec**: `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/02-child-home.md`
**Audit type**: Diagnostic only — DO NOT FIX. Findings to be triaged by maintainer.
**Date**: 2026-05-18

---

## Summary

The page is structurally close to Figma. Most deltas are token-discipline lapses, debug-only hooks left in production, and `_MissionListSection` mock data that violates "Real Code Only" (RULES.md — Implementation Completeness). The donut geometry, top-bar, my-button, schedule empty-state, and onboarding bubble all match Figma within tolerance. The most material risk is broken navigation on tap of the bar-chart icon (route mismatch surfaces 404) and the 5 identical mock mission cards shipping in the v2 state.

---

## Issue 1 — Bar chart "report" icon route does not exist

**Severity**: HIGH (broken navigation)

- **Observation**: `_TodayTimeSection` line 304-305 calls `context.push('/child-home/report')`. Searching the router (`lib/app/router/app_router.dart:59`) confirms the route exists and maps to `ReportPage`. OK — route works. **Re-check**: this is fine. Downgrading severity.
- **Re-classify as MEDIUM** (verified valid): Both icon tap targets resolve. However tap target is undersized: `IconButton` `minWidth: 22, minHeight: 22` violates Material 48-dp minimum and the Figma annotation (`Settings Icon 20×20 mask` is decorative, but tap area should still be 44+). Children frequently mis-tap small targets.
- **Root cause**: `BoxConstraints(minWidth: 22, minHeight: 22)` chosen for visual fidelity over a11y minimum.
- **Figma ref**: `426-21005` header row — icons render at 20×20, but no spec on tap area.
- **Fix direction (not applied)**: Increase `minWidth/minHeight` to 32-44 and keep visual `size: 20`; or wrap with `SizedBox(width: 44, height: 44)`.

---

## Issue 2 — All 5 mission cards render identical mock copy ("방청소 하기" + "청소" icon)

**Severity**: HIGH (visual regression vs Figma + violates RULES.md "No Mock Objects")

- **Observation**: `_MissionListSection` (line 671-677) defines 5 `_MissionItemData` with only `id` and `status`. `_MissionCard` (line 764) hardcodes `'assets/icons/청소.svg'` and `_MissionText` (line 796, 807) hardcodes `'방청소 하기'` / `'1시간 지급'`. All 5 cards look like clones except for the trailing status icon.
- **Root cause**: `_MissionItemData` has no `title`, `subtitle`, `iconAsset`, or `category` field. The class is a stub.
- **Figma ref**: Spec line 110-112 — each card has title + subtitle + 48×48 category icon; Figma uses one variant repeated for visual placeholder, but in shipped code each card should carry distinct content (or at minimum a deterministic varied mock until backend wires up).
- **Fix direction (not applied)**: Extend `_MissionItemData` with `title`, `subtitle`, `iconAsset`. Available icons in `assets/icons/`: 청소, 운동, 학습, 심부름, 루틴, 시계 — enough for 5 distinct cards.

---

## Issue 3 — Production code retains debug-only long-press toggle

**Severity**: MEDIUM (RULES.md — No TODO, No partial features)

- **Observation**: Lines 26-29 carry a `TODO` comment plus a `_hasSchedule` boolean defaulting to `false`. Line 48-52 defines `_toggleHasScheduleForDebug`. Line 356 wires `onLongPress: onDebugToggleSchedule` to the time card. A real user long-pressing the card will silently flip between empty and donut states.
- **Root cause**: Schedule state not wired to repository/provider yet. Debug hook left in for QA.
- **Figma ref**: No Figma spec for long-press behavior. Long-press would not appear in design but is shippable as silent surprise interaction.
- **Fix direction (not applied)**: Either gate `onLongPress` behind `kDebugMode`, or move to a dedicated test harness, and replace `_hasSchedule` with a real state source (`ScheduleRepository.hasTodayPlan()`).

---

## Issue 4 — `_TodayTimeSection` shows donut header icons only when `showDonut == true`; v1 empty state shows a single solid gray `Icons.settings`

**Severity**: MEDIUM (Figma fidelity)

- **Observation**: Lines 285-331 — when `showDonut` is true, the header renders a bar-chart icon (20px) + gear icon (20px) at `gray600`. When false, renders one solid `Icons.settings` (Material filled) at `gray300`, size 22. The empty-state v1 Figma (`426-20978`) actually shows the outlined Settings icon, not the filled Material `Icons.settings`. Spec line 53: `Settings Icon (20×20 mask, gray-300)` — outlined cog mask.
- **Root cause**: `Icons.settings` is the filled Material glyph (solid gear silhouette); Figma uses an outlined cog asset that isn't yet exported.
- **Figma ref**: Spec line 53, 185 — "current `Icons.settings` (Material) doesn't match Figma's lighter, outlined cog (`Fill` mask asset). Consider exporting the Figma SVG into `assets/icons/settings.svg`."
- **Fix direction (not applied)**: Export `settings.svg` from Figma into `assets/icons/`, swap `Icon(Icons.settings)` → `SvgPicture.asset('assets/icons/settings.svg')`. Same swap applies to the `_MissionSection` empty-state cog on line 616 and the populated-state gear on line 316.

---

## Issue 5 — `_TodayTimeSection` empty-state hides bar-chart icon AND "사용 리포트" link simultaneously

**Severity**: MEDIUM (interaction inconsistency)

- **Observation**: Lines 285-343 use two different conditional branches:
  - If `showDonut == true` → render bar-chart icon + gear icon (both 20px, gray600).
  - Else (no donut) → render the single gray-300 Icons.settings + (if `!hasContent`) the `사용 리포트` text on the right.
  - But if `hasContent == true && hasSchedule == false` (i.e. user has app data but no schedule), neither the bar-chart icon nor the "사용 리포트" link appears — header is just title + cog.
- **Root cause**: Branching logic conflates `hasContent` and `hasSchedule`. The empty-but-active state (hasContent true, hasSchedule false) loses both report entry points.
- **Figma ref**: Spec line 24 — v1 empty state header has title + cog + "사용 리포트" link. v2 populated has title + bar-chart icon + gear icon (no link). The "active but empty" state isn't drawn in Figma — needs design clarification.
- **Fix direction (not applied)**: Confirm intended design for active-but-empty state; if it should mirror v1, change `if (!hasContent)` → `if (!showDonut)`.

---

## Issue 6 — `_ParentConnectGuide` onboarding overlay has no manual close affordance

**Severity**: MEDIUM (UX clarity)

- **Observation**: Lines 80-100 — overlay is dismissed only by tapping anywhere via the outer `GestureDetector(behavior: HitTestBehavior.translucent, onTap: _dismissOnboarding)`. There is no X button or explicit "다음" CTA on the bubble itself.
- **Root cause**: Whole-screen-tap-to-dismiss pattern; bubble itself contains no interactive close.
- **Figma ref**: Spec doesn't enumerate dismiss UX. Step "1" badge (line 982-990) suggests multi-step tutorial, but only step 1 is implemented. If multi-step, full-screen tap is the wrong dismissal pattern.
- **Fix direction (not applied)**: Clarify with design — multi-step or single-step? If single-step, add a small CTA in the bubble (e.g., "확인"). If multi-step, gate dismissal behind explicit advance/skip.

---

## Issue 7 — Reviewing status uses `AppColors.positive` (#00BF40); Figma's `_ReviewingStatusIcon` shows a sync glyph but Figma annotates "spinner"

**Severity**: LOW (visual nuance)

- **Observation**: Line 870-881 — `_ReviewingStatusIcon` renders a green circle with `Icons.sync_rounded` (size 13). Figma annotation calls it `Frame7317` and the spec line 121 describes it as `green/spinner ring`.
- **Root cause**: Material `Icons.sync_rounded` is a static glyph; Figma's spec word "spinner" implies animation, but the static rendering is acceptable for static UI.
- **Figma ref**: Spec line 121 — `green/spinner ring (Frame7317)`. Color confirmed: `AppColors.positive` is correct (#00BF40), matches updated tokenization from spec line 178.
- **Fix direction (not applied)**: Static glyph is fine; if animation is desired add a `RotationTransition`. No color change needed.

---

## Issue 8 — Donut chart hardcodes mock progress (76% / 78%)

**Severity**: LOW (acceptable for current phase, but flags as mock)

- **Observation**: Lines 485-498 — `_TimeDonutChartPainter` hardcodes `progress: 0.76` (outer/primary) and `progress: 0.78` (inner/bonus).
- **Root cause**: Chart is decoupled from any data source; matches the Figma reference image but not real schedule state.
- **Figma ref**: Spec line 100-105 confirms the geometry (radius 55/39, stroke 14/11, colors primary/bonusAmber). Figma renders ~76% / ~78% — visually accurate.
- **Fix direction (not applied)**: Parameterize the painter (`final double primaryProgress; final double bonusProgress`) and pass real values once schedule wiring lands. Currently violates RULES.md "No Mock Objects" if shipped to users.

---

## Issue 9 — Token discipline: residual hex literal in mission card

**Severity**: LOW

- **Observation**: Grep for `Color(0x` / `0xFF` in `child_home_page.dart` returns zero matches — token discipline is mostly clean. Card radius `16` is inline (`BorderRadius.circular(16)` on lines 360, 757) but `AppTokens.cardRadiusSmall = 16` exists in `app_tokens.dart:20`.
- **Root cause**: Token added but not adopted at call sites.
- **Figma ref**: Spec line 183 explicitly recommends `AppTokens.cardRadiusSmall`. The token now exists.
- **Fix direction (not applied)**: Replace `BorderRadius.circular(16)` with `BorderRadius.circular(AppTokens.cardRadiusSmall)` on lines 360 and 757.

---

## Issue 10 — Card shadow uses raw `cardShadowColor` instead of `AppColors.cardShadow` alias

**Severity**: LOW (cosmetic — duplicate definition)

- **Observation**: Line 363 references `AppTokens.cardShadowColor`; `AppColors.cardShadow` (line 86 of app_colors.dart) holds the same value (`Color(0x80D9D9D9)`). Two parallel token names for the same color creates drift risk.
- **Root cause**: Token defined twice — once in `AppTokens`, once in `AppColors`.
- **Figma ref**: Spec line 200-203 proposed `AppTokens.cardShadow` (BoxShadow). Neither name is wrong, but only one should exist.
- **Fix direction (not applied)**: Consolidate to a single `AppTokens.cardShadow` `BoxShadow` constant and remove `AppColors.cardShadow`.

---

## Issue 11 — `_TodayTimeSection` uses fixed `SizedBox(height: 223)` with `Stack`; v1 spec calls for 223 (48 header + 175 card), v2 also 223 — same. OK.

**Severity**: NONE (verified compliant)

- **Observation**: Line 268 `height: 223`. Line 350-351 `top: 48, height: 175`. Matches spec exactly (48 + 175 = 223). No issue.

---

## Issue 12 — SafeArea / Scaffold composition

**Severity**: NONE (verified compliant)

- **Observation**: Lines 58-104 — `Scaffold > Stack > Center > ConstrainedBox > SafeArea(bottom: false) > _ChildHomeContent`. Onboarding overlay duplicates the wrapper (`Center > ConstrainedBox > SafeArea`). No overlap — the overlay is `Positioned.fill` so the lower stack is still rendered and dimmed via the per-child `Opacity(0.2)`.
- **Verification**: `_ChildHomeContent` applies `Opacity(opacity: onboarding ? 0.2 : 1)` (line 144) to its content column — content stays interactive (still scrollable) underneath the dim. This is consistent with the onboarding overlay pattern; however the underlying content remains pressable while the overlay's translucent gesture detector should swallow taps. Verified: outer `GestureDetector(behavior: HitTestBehavior.translucent)` captures taps and dismisses — but `translucent` allows hit-test to fall through to widgets behind. The `_ParentConnectGuide` itself absorbs taps within the bubble; the rest dismisses. **Minor concern**: tapping the dim background could accidentally trigger interactive elements below (mypage `my` button, top-right bell). Consider `HitTestBehavior.opaque` if Figma intends to block underlying interaction.

---

## Issue 13 — Mission card lacks `Material` ink-well / pressed feedback

**Severity**: LOW (UX polish)

- **Observation**: Line 748-775 — `GestureDetector` wraps a `Container`. Tap has no ripple, no visual press state. Children apps benefit from explicit tactile feedback.
- **Root cause**: `GestureDetector` chosen over `InkWell` for simplicity.
- **Figma ref**: Spec line 157 — "Tapping a mission field — Figma marks card as cursor-pointer." No press-state spec.
- **Fix direction (not applied)**: Wrap with `Material(color: Colors.transparent, child: InkWell(borderRadius: ..., onTap: ..., child: ...))` for ripple feedback; or add a `Color` change on press via `StatefulWidget`.

---

## Risk-prioritized fix backlog

| Priority | Issue | Effort | Risk if shipped |
|---|---|---|---|
| P0 | #2 Identical 5 mock mission cards | M | High — looks broken to user |
| P0 | #3 Long-press debug toggle in prod | S | High — silent state flip surprises user |
| P1 | #4 Filled `Icons.settings` vs outlined SVG | S | Medium — visible Figma drift |
| P1 | #5 Active-but-empty header loses report entry | S | Medium — design clarification needed |
| P1 | #6 Onboarding dismiss UX | S | Medium — unclear affordance |
| P2 | #1 Icon tap target <44dp | S | Low — a11y nicety |
| P2 | #8 Hardcoded donut progress | M | Low — accurate to mock |
| P3 | #9 `cardRadiusSmall` not adopted | S | Cosmetic |
| P3 | #10 Duplicate `cardShadow` token | S | Cosmetic |
| P3 | #13 No ink ripple | S | Polish |

---

## Files touched (for fix planning — not modified here)

- `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/child_home/presentation/pages/child_home_page.dart` (primary)
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/theme/app_tokens.dart` (token consolidation)
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/theme/app_colors.dart` (duplicate cardShadow)
- `/Users/yeongj/Quad-S-Team12-App-Child/assets/icons/` (export settings.svg, bar_chart.svg)
