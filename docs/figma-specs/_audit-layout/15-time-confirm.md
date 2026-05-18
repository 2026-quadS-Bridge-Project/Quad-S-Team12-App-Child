# Audit: TimeConfirmPage layout

**Target file**: `lib/features/time_confirm/presentation/pages/time_confirm_page.dart`
**Figma nodes**: `744-11326` (empty), `662-11322` (filled), `662-11249` (filled + tip)
**Spec**: `docs/figma-specs/10-time-confirm.md`
**Audit mode**: Diagnostic only — DO NOT FIX.

---

## Quick-look results

| Check | Status |
|-------|--------|
| 1. SafeArea / Scaffold + BridgeAppBar('시간설정') | ⚠️ AppBar via `appBar:` slot — inherits BridgeAppBar status-bar bug (Issue 1) |
| 2. Three variants (`?variant=`) | ⚠️ Logic correct but `GoRouterState.of(context)` called in `initState()` (Issue 2) |
| 3. Empty state — BridgeEmptyState + 확인 CTA | ⚠️ Action passed as sibling instead of via `action:` slot (Issue 3) |
| 4a. BridgeTotalTimeCard '2월 1주 사용 시간' | ✅ wired correctly |
| 4b. 7px gray150 divider | ⚠️ Raw `Container(height:7, color: gray150)` instead of token/component (Issue 4) |
| 4c. 일간 사용 계획 header | ⚠️ Uses `headlineBold` (18) instead of spec `heading2Bold` (20) (Issue 5) |
| 4d. BridgePillIconButton ghost + Stack tooltip | ⚠️ Magic offsets `top:-64, right:0` (Issue 6) |
| 4e. Read-only BridgeDayRow list | ✅ `onEdit: null, showPencil: false` |
| 4f. 확인 CTA | ✅ wired correctly |
| 5. OnboardingTooltip dark variant | ⚠️ Single-line message lacks title/bullets per spec (Issue 7) |
| 6. 수정요청 snackbar copies | ⚠️ Snackbar fires even before tooltip dismissed; copy is OK but lacks dismiss-tooltip side-effect (Issue 8) |
| 7. Domain decision surfaced | ⚠️ Only via tooltip — when `showOnboarding=false`, child has no UX hint that 수정하기 is indirect (Issue 9) |
| 8. Token discipline | ⚠️ Hard-coded `16`/`24`/`12` spacings instead of `AppTokens.*` (Issue 10) |

---

## Issue 1: BridgeAppBar in `Scaffold.appBar:` slot inherits status-bar overlap bug

### Observation
- `time_confirm_page.dart:81` wires `appBar: const BridgeAppBar(title: '시간설정')`.
- `time_confirm_page.dart:82` wraps the **body only** in `SafeArea`.
- Per the existing audit `_audit-layout/01-BridgeAppBar.md` (Issue 1), `BridgeAppBar` does **not** internally consume `MediaQuery.padding.top`, and `preferredSize` is a flat 52 px. When placed in the `Scaffold.appBar:` slot, the OS status bar paints on top of (or shares space with) the centered title + back chevron.
- A SafeArea around the body does NOT fix this — the body's top is already below the appBar; the appBar itself is the broken surface.

### Root cause
`Scaffold` reserves `preferredSize.height = 52` for the appBar starting at absolute `y=0`. On notched iPhones the 44 px status-bar region collides with the bar. This is a `BridgeAppBar` defect (documented), but `TimeConfirmPage` is one of the broken consumers using the `appBar:` slot rather than the `SafeArea > Column > BridgeAppBar` pattern that other correctly-rendering pages (`my_page.dart:94`, `login_page.dart:118`) use.

### Figma reference
`docs/figma-specs/10-time-confirm.md` lines 13–14 + 53–54: "Status Bar (44px) — system mocks" then "Topbar (52px)". The Figma topbar is at absolute `Y 44–96`, never overlapping the status-bar region.

### Recommended fix (do not apply now)
Either (a) fix `BridgeAppBar` to internally wrap in `SafeArea(top: true)` and grow `preferredSize` by `MediaQuery.paddingOf(context).top` — per the recommendation in `_audit-layout/01-BridgeAppBar.md`, or (b) refactor `TimeConfirmPage` to use the `SafeArea > Column > [BridgeAppBar, Expanded(body)]` pattern that already works in `my_page`/`login_page`.

---

## Issue 2: `GoRouterState.of(context)` invoked from `initState()` will throw on hot-reload / first build in tests

### Observation
- `time_confirm_page.dart:44–47`:
  ```dart
  void initState() {
    super.initState();
    _controller = TimeConfirmController(initial: _resolveInitialData());
  }
  ```
- `_resolveInitialData()` (line 50–51) calls `GoRouterState.of(context).uri.queryParameters['variant']`.

### Root cause
`GoRouterState.of(context)` walks the inherited-widget tree to find the `GoRouter` inherited model. In `initState()`, the element is mounted but `didChangeDependencies` has not yet been called — go_router's inherited widgets *are* usually accessible at this point because `Scaffold` is built later, but the contract is documented to require either `didChangeDependencies` or `build`. Edge cases:
- **Widget tests** that pump `TimeConfirmPage` outside a `MaterialApp.router` will throw `Bad state: No GoRouter found in context`.
- The explicit `widget.variant` override exists (line 50) but is only used when non-null; when both `widget.variant` and a route are absent the access still fires.

### Figma reference
N/A — implementation defect, not a visual one.

### Recommended fix (do not apply now)
Move the `GoRouterState` read into `didChangeDependencies()` (with an `_initialized` guard) **or** make the page build the variant lazily inside `build()` from the existing `widget.variant ?? GoRouterState.of(context).…` (safe in `build`). For tests, prefer always-passing `variant:` as a constructor arg.

---

## Issue 3: BridgeEmptyState does not use its `action:` slot — CTA stacked manually outside

### Observation
- `time_confirm_page.dart:113–127` builds the empty variant as:
  ```dart
  Column(children: [
    Expanded(child: BridgeEmptyState(message: ..., icon: ...)),
    Padding(... BridgeButton(label: '확인', onPressed: onClose)),
  ])
  ```
- `BridgeEmptyState` (`bridge_empty_state.dart:33–43`) explicitly exposes an `action:` parameter with a documented 24 px gap, designed for exactly this case.

### Root cause
The page bypasses the component contract and instead stacks the button below the empty state in an outer `Column`. Consequences:
1. The CTA is pinned to the bottom of the screen (Expanded + Padding), but the Figma empty-state spec (lines 17–18) places the "확인" CTA at `bottom 63px` of the screen — a bottom-pinned CTA, not an empty-state action. So the current layout is actually *closer* to Figma than using `action:` would be.
2. However, the empty-state icon `Icons.event_busy_outlined` (line 117) does NOT appear in Figma. Per spec lines 22 ("Empty message: `이번달 시간규칙이 설정되지 않았습니다.`") and 36 (no icon mentioned), the Figma empty frame is text-only — no icon. Adding an icon is a visual deviation.

### Figma reference
`docs/figma-specs/10-time-confirm.md` lines 11–22, 36: empty state is *text only* + bottom CTA. No icon. Bottom CTA matches Figma.

### Recommended fix (do not apply now)
Remove the `icon: Icons.event_busy_outlined` to match Figma; the `Column + Expanded + bottom-pinned CTA` layout itself is correct. Optionally: pass a no-icon `BridgeEmptyState(message: …)` to match spec exactly.

---

## Issue 4: Raw `Container(height: 7, color: gray150)` divider instead of a reusable component / token

### Observation
- `time_confirm_page.dart:162–165`:
  ```dart
  Container(height: 7, color: AppColors.gray150),
  ```
- Spec line 113 explicitly calls for a `BridgeSectionDivider` component: "`BridgeSectionDivider` — gray150 7px-thick horizontal bar".
- No such component exists yet in `lib/core/widgets/`. Grep across `lib/` confirms zero references to `BridgeSectionDivider`.

### Root cause
The 7-px section divider is a documented reusable Bridge component (used potentially in other "section break" screens). The page inlines the raw container, bypassing both the component layer and the token system (height `7` is a magic number — no `AppTokens.sectionDividerHeight`).

### Figma reference
`docs/figma-specs/10-time-confirm.md` line 56 ("Divider — `#EDEEF1` (gray150), full-width 374×7px at y≈230") and line 113 (component name).

### Recommended fix (do not apply now)
Create `BridgeSectionDivider({double thickness = 7, Color color = AppColors.gray150})` in `lib/core/widgets/layout/`. Replace the inline `Container` with the component. Optionally add `AppTokens.sectionDividerThickness = 7`.

---

## Issue 5: 일간 사용 계획 section title uses wrong typography token (`headlineBold` 18 vs spec `heading2Bold` 20)

### Observation
- `time_confirm_page.dart:171–176`:
  ```dart
  Text('일간 사용 계획',
    style: AppTypography.headlineBold.copyWith(color: AppColors.textPrimary))
  ```
- `AppTypography.headlineBold` is Pretendard SemiBold **18** / line-height 1.445 (`app_typography.dart:62`).
- Spec line 91 mandates: "Section title: Pretendard SemiBold **20** / 1.4 / -0.24 (Heading 2/Bold) — NEW token: `Heading2Bold` (20/SemiBold)".
- `AppTypography.heading2Bold` exists (`app_typography.dart:35`, size 20, weight w600, height 1.4) — the correct token.

### Root cause
The page picked the closest-looking style instead of the spec-mandated section-title token. Also: `color: AppColors.textPrimary` (= `labelStrong` = black `#000000`) deviates from spec color `#2F3032` = `gray800` (spec line 84: "Section titles `#2F3032` = gray800").

So this issue has **two** deviations:
1. Wrong size token (18 vs 20)
2. Wrong color token (black vs gray800)

The same defect almost certainly applies to the "2월 1주 사용 시간" title rendered by `BridgeTotalTimeCard` — but that one is the component's responsibility, not this page's; quick check shows `bridge_total_time_card.dart:61` uses `headlineMedium` (18 medium) which is wrong per spec too. Out-of-scope here but noted.

### Figma reference
`docs/figma-specs/10-time-confirm.md` lines 84, 91 — section titles are 20/SemiBold/gray800.

### Recommended fix (do not apply now)
Replace with `AppTypography.heading2Bold.copyWith(color: AppColors.gray800)`. File a separate ticket for `BridgeTotalTimeCard` title color/size.

---

## Issue 6: OnboardingTooltip positioned with hard-coded magic offsets (`top: -64, right: 0`)

### Observation
- `time_confirm_page.dart:186–196`:
  ```dart
  if (data.showOnboarding)
    Positioned(
      top: -64,
      right: 0,
      child: BridgeOnboardingTooltip(...))
  ```
- The `-64` is a guess at "tooltip height + arrow + gap". `BridgeOnboardingTooltip` has no exposed `height` and uses dynamic `Column(mainAxisSize: min)` — so the tooltip height depends on the wrapped text and font metrics.
- If the tooltip grows (longer copy, larger text scale, accessibility scale factor), the arrow no longer aligns with the pill button's top edge; the tooltip detaches visually.
- `right: 0` aligns the tooltip's right edge with the pill's right edge — but the spec arrow is `bottomCenter` (line 193), so the arrow now points *down at the right edge of the tooltip*, not at the center of the pill. The arrow misses its target unless the tooltip is exactly as wide as the pill.

### Root cause
Manual offset positioning of a tooltip whose height is unknown and whose arrow alignment doesn't match its horizontal anchor. The component itself documents (lines 38–40 of `bridge_onboarding_tooltip.dart`) that "Positioning is the caller's responsibility — wrap in a [Stack]/[Positioned] or [OverlayEntry]" — but it gives no helper for "anchor my arrow to this target". Result: visual drift across font scales and copy changes.

Additionally, `Stack` is wrapped tightly inside the header `Row` (line 167). The `Stack` shrink-wraps to the pill size, so the tooltip overflowing to `top:-64` overflows the row's vertical bounds; with `clipBehavior: Clip.none` (line 178) it draws outside, but parent Row layout still treats the Stack as pill-sized, possibly clipping if any ancestor has clipping enabled.

### Figma reference
`docs/figma-specs/10-time-confirm.md` lines 122–127: "Tip tooltip (top ≈ 323px, ~255×150px, centered-ish under the edit pill) — Dark gray rounded box with triangular notch pointing **up** toward the 수정하기 pill".

⚠️ **Spec says arrow points UP** (notch on top of body, body BELOW pill). Implementation uses `TooltipArrowAlignment.bottomCenter` (arrow at bottom of body → body ABOVE pill). This is a **direction inversion**. The current code shows the tooltip floating *above* the pill; Figma shows it floating *below* the pill.

### Recommended fix (do not apply now)
Either:
1. Build a `BridgeAnchoredTooltip(target, alignment)` helper that uses an `OverlayEntry` + `CompositedTransformFollower` to true-anchor against the target, OR
2. Switch `arrowAlignment` to `topCenter` (body below pill, arrow pointing up) and use `top: <pill bottom + 8>` for spacing — matching Figma `y≈323`. Compute offset from layout, not from a magic `-64`.

---

## Issue 7: OnboardingTooltip body lacks structured title + bullets + close icon per Figma

### Observation
- `time_confirm_page.dart:191–192` passes a single multi-line `message:` string:
  ```dart
  message: '직접 수정할 수 없어요.\n꼭 필요한 경우에 부모님의 시간 설정 탭에서\n허락을 받아, 수정할 수 있어요',
  ```
- `BridgeOnboardingTooltip` renders this as a single `Text` block (line 120–125) with an optional right-aligned "확인" link (line 126–135).

### Root cause
The tooltip widget itself explicitly TODOs this gap (line 34–37 of `bridge_onboarding_tooltip.dart`):
> "spec also calls for a structured layout with a bold title (`시간 계획 수정은 어떻게 하나요?`), bulleted bullets, and a close (X) icon in the top-right (see `docs/figma-specs/_audit-phase5.md` "OnboardingTooltip widget" → FAIL/DELTA). Out of scope for this color-inversion pass; tracked for a follow-up structural revision."

So the dark-variant color fix landed but the structural revision did not.

Specific deviations from spec:
1. **Missing title**: `시간 계획 수정은 어떻게 하나요?` (spec line 130).
2. **Missing 2nd bullet**: `시간 설정은 주 1회 진행돼요. 이번주 시간계획이 미흡했다면 다음주에 반영해서 수정해봐요!` (spec line 131). Implementation only ships bullet 2 (line 132 of spec).
3. **Missing underlined emphasis**: `주 1회` (bullet 1) and `시간 설정 탭` (bullet 2) must be underlined per spec.
4. **Missing close (X) icon**: spec line 127 calls for "Small X / close vector at top-right inside the tooltip". Current widget offers an "확인" text link instead — different affordance.
5. **Copy mismatch even for bullet 2**: spec is `꼭 필요한 경우에 부모님의 시간 설정 탭에서 허락을 받아, 수정할 수 있어요.` (with period). Implementation: `직접 수정할 수 없어요.\n꼭 필요한 경우에 부모님의 시간 설정 탭에서\n허락을 받아, 수정할 수 있어요` (no period, plus an added intro line `직접 수정할 수 없어요.` not in spec).

### Figma reference
`docs/figma-specs/10-time-confirm.md` lines 128–143.

### Recommended fix (do not apply now)
Extend `BridgeOnboardingTooltip` API with `title`, `List<TooltipBullet>` (each with optional underline spans), and `onClose` (X icon). Migrate this caller to pass spec-accurate copy.

---

## Issue 8: 수정하기 tap shows snackbar without dismissing the onboarding tooltip

### Observation
- `time_confirm_page.dart:69–75`:
  ```dart
  void _showRequestSnack() {
    _controller.requestModification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('부모님께 수정 요청을 보냈어요.')),
    );
  }
  ```
- When `showOnboarding == true` and the user taps 수정하기, the tooltip stays on screen, the snackbar appears at the bottom, and the request goes out. UX is confusing: the tooltip is explaining "you can't edit directly" while the snackbar simultaneously says "request sent".

### Root cause
`_showRequestSnack` does not call `_controller.dismissOnboarding()` as a side-effect, and `requestModification()` is currently a stubbed TODO (lines 22–24 of `time_confirm_controller.dart`) so there is no debounce / no "already requested today" guard. A child can spam the pill and emit unlimited snackbars.

Additionally, the controller's `requestModification()` is a no-op TODO — yet the snackbar copy "부모님께 수정 요청을 보냈어요" is a **factual claim** that a request was sent. With no backend integration this is a lie surfaced to the user. Per RULES.md "No TODO Comments for core functionality" and "Professional Honesty", this is a behavior-vs-copy mismatch.

### Figma reference
`docs/figma-specs/10-time-confirm.md` line 106: "수정하기 pill → likely navigates to a request-edit flow". Spec does not specify a snackbar; the snackbar is an implementation choice. No spec violation, but a UX/integrity concern.

### Recommended fix (do not apply now)
1. Dismiss the onboarding tooltip on first 수정하기 tap.
2. Either implement the backend request in `TimeConfirmController.requestModification()` OR change snackbar copy to "수정 요청 기능은 곧 제공될 예정입니다" until it is wired.
3. Add tap debounce / "already requested" state to avoid duplicate snackbars.

---

## Issue 9: Domain decision (child read-only) only surfaces via the onboarding tooltip — invisible after dismissal

### Observation
- The page has no persistent visual cue that 수정하기 is *indirect* (a request, not a direct edit). The only signal is the onboarding tooltip, which:
  - Renders only when `data.showOnboarding == true` (line 186).
  - Is dismissible (line 194 → `onDismissOnboarding`).
  - Is gated by `TimeConfirmMock.filledWithOnboarding` (mock-only); production state likely defaults to `showOnboarding: false`.
- After first dismissal, the child sees a pill labeled "수정하기" with a pencil icon — universal "edit" affordance. Tapping it produces a snackbar, not an edit screen. This violates the principle of least surprise.

### Root cause
The spec confirms the domain decision (spec line 5: "the child cannot directly edit; they must request the parent"). The implementation surfaces this only via a transient onboarding hint. Better signal options:
- Pill label could be `수정 요청` (request modification) instead of `수정하기` (edit).
- Pill icon could be an outbound/send icon instead of a pencil.
- A persistent helper line under the section header.

### Figma reference
`docs/figma-specs/10-time-confirm.md` lines 5, 60, 106 — confirms the domain constraint. Note: Figma label IS `수정하기` (verbatim, line 73), so changing the label would deviate from Figma copy. The misleading-affordance problem is therefore a **Figma-level UX defect**, not a code defect — but worth flagging for the design team.

### Recommended fix (do not apply now)
Surface for product/design discussion. Code-side could add a `BridgeOnboardingTooltip` that re-shows on each fresh app launch (until N-time dismissed) instead of a one-shot mock flag.

---

## Issue 10: Token discipline — hard-coded paddings and gaps instead of `AppTokens.*`

### Observation
Hard-coded spacings in `time_confirm_page.dart`:
- Line 111: `EdgeInsets.symmetric(horizontal: 24)` — should be `AppTokens.pageHorizontal` (= 24).
- Line 121: `EdgeInsets.only(bottom: 24)` — magic 24.
- Line 151: `EdgeInsets.symmetric(horizontal: 24, vertical: 16)` — magic 24 + 16.
- Line 155: `SizedBox(height: 16)` — should be `AppTokens.itemGap` (= 16).
- Line 161, 166: `SizedBox(height: 16)` — magic 16.
- Line 188: `top: -64` — opaque magic offset (Issue 6).
- Line 201: `SizedBox(height: 12)` — should be `AppTokens.mediumGap` (= 12).
- Line 206: `SizedBox(height: 12)` — magic 12.
- Line 220: `EdgeInsets.only(top: 12, bottom: 24)` — magic 12 + 24.

Existing tokens that could replace these: `AppTokens.pageHorizontal`, `AppTokens.itemGap`, `AppTokens.mediumGap`, `AppTokens.smallGap`.

Additionally, `Container(height: 7, color: AppColors.gray150)` on line 162–165 has no token — but that's Issue 4.

### Root cause
Token system exists (`app_tokens.dart`) but is not consistently adopted. Future changes to the global page padding (e.g., shrinking to 20 px) would require touching every magic-number site.

### Figma reference
N/A — token hygiene, not visual.

### Recommended fix (do not apply now)
Sweep replace magic numbers with `AppTokens.*` equivalents. Add tokens for any spacing that recurs ≥2 times without an existing token (e.g., the 7 px section divider thickness).

---

## Chain-of-Thought summary table

| # | Observation | Root cause | Figma ref | Severity |
|---|-------------|------------|-----------|----------|
| 1 | AppBar status-bar overlap on notched devices | BridgeAppBar lacks SafeArea + uses `appBar:` slot | spec L13–14 | 🔴 high (visual collision) |
| 2 | `GoRouterState.of(context)` in initState | wrong lifecycle hook | N/A | 🟡 med (test fragility) |
| 3 | Empty state has icon not in Figma | extra icon vs text-only spec | spec L22, L36 | 🟡 med (visual deviation) |
| 4 | Inline 7px Container divider | missing `BridgeSectionDivider` component | spec L113 | 🟡 med (no reuse) |
| 5 | 일간 사용 계획 wrong size + color token | `headlineBold 18 + textPrimary` instead of `heading2Bold 20 + gray800` | spec L84, L91 | 🔴 high (typography violation) |
| 6 | Tooltip with magic `-64` offset + wrong arrow direction | manual positioning, arrow inverted vs Figma | spec L124 | 🔴 high (visual misalignment) |
| 7 | Tooltip body lacks title/bullets/X/underlines | structural revision pending | spec L128–143 | 🔴 high (content gap, ~70% of spec missing) |
| 8 | Snackbar fires without dismissing tooltip; copy claims success on stub backend | missing side-effect + honesty | spec L106 | 🟡 med (UX + integrity) |
| 9 | Domain "request-only" model only surfaced via dismissible tooltip | persistent cue missing | spec L5 | 🟢 low (design concern) |
| 10 | Magic numbers throughout (24/16/12/-64/7) | tokens not adopted | N/A | 🟢 low (maintainability) |

---

## Top 3 issues (priority order)

1. **Issue 6 — Onboarding tooltip arrow direction is inverted** (Figma: arrow points UP, body BELOW pill; code: arrow points DOWN, body `top:-64` ABOVE pill). Combined with magic offset and tight Stack scope, this is the most visible visual defect.
2. **Issue 7 — OnboardingTooltip body is missing ~70% of the Figma content**: no title, only 1 of 2 bullets, no underlined emphasis, no close icon, wrong/added copy. The widget self-TODOs this gap.
3. **Issue 5 — Section title uses wrong typography & color token** (`headlineBold` 18 / black instead of `heading2Bold` 20 / gray800). Affects every section header on the filled variant.
