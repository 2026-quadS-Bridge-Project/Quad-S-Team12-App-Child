# Audit: Home Intro layout

**Target file**: `lib/features/home/presentation/pages/home_page.dart`
**Figma reference**: `tzJjQmXtXO7vGlfCT9SASu` node `662:8356` (originally labelled "로그인" in `docs/UI-figma.md:1-2`, but the screen is actually the unauthenticated landing / intro that hosts the `Bridge` wordmark + dual CTAs).
**Scope**: Static intro page only — `/` route in `lib/app/router/app_router.dart:29`. Cached-login users are redirected to `/child-home` in `initState`.
**Reference assets**:
- `lib/core/theme/app_colors.dart:65-68` — `brandWordmark` token (`#6DB5FF`)
- `lib/core/theme/app_tokens.dart:4-9` — frame width / horizontal padding tokens
- `lib/core/widgets/buttons/bridge_button.dart` — shared CTA primitive
- `assets/icons/Icon Container.svg` — 99×98 cloud/bridge mark (registered in `pubspec.yaml:69`)
- `assets/fonts/Sigmar-Regular.ttf` — registered in `pubspec.yaml:75-78`
- `lib/core/auth/auth_session.dart` — `isLoggedIn` flag (SharedPreferences)

---

## Issue 1: `_redirectCachedLogin` introduces a one-frame flash + race window before navigation

### Observation
- `home_page.dart:30-47`. `initState` calls `_redirectCachedLogin()`, which awaits `AuthSession.isLoggedIn()` (an async SharedPreferences round-trip), then calls `context.go('/child-home')` if true.
- Until the await resolves and `setState` (implicit via `context.go`) runs, the intro UI (`Bridge` wordmark + CTAs) is fully built and painted. On a fresh launch with a cached login, the user sees the intro for ~1 frame before the router replaces it.
- There is no loading scrim, no `Visibility(visible: !_redirecting)` gate, and no `Builder` that defers `_IntroContent` until the async check resolves.

### Root cause
SharedPreferences resolves on a background isolate; the first frame is built before the `Future` completes. The intro widget tree is unconditional inside `build()`. The redirect is purely a *post-paint* navigation.

A secondary race: between the `await AuthSession.isLoggedIn()` and the `mounted` guard, the user could conceivably tap "자녀 회원가입" or "로그인" first — `BridgeButton` taps call `context.push(...)` (lines 131, 149), so this would push a second route onto the stack before the redirect's `context.go` replaces it. Unlikely on a slow phone but not impossible to reproduce on a release build with very fast SharedPreferences cache hits.

### Figma reference
Figma `662:8356` shows only the intro frame. There is no design spec for the cached-login flow — this is purely an app-side behavior, but Figma implicitly assumes the intro is shown only to *un-authenticated* users (the CTAs are 회원가입 / 로그인).

### Recommended fix (do not apply now)
1. Gate the body on a `bool? _showIntro` (`null` = still loading). While `null`, render `Scaffold(backgroundColor: AppColors.gray050, body: SizedBox.shrink())` or a centered `CircularProgressIndicator`.
2. Set `_showIntro = false` and `context.go('/child-home')` inside the same `setState` when logged in; set `_showIntro = true` otherwise.
3. Move the redirect into a top-level router redirect (`GoRouter.redirect`) so the intro tree is never constructed for cached-login users in the first place — cleaner separation of routing vs. presentation.

---

## Issue 2: Hardcoded `bottom: 18` padding for the CTA stack is not a token

### Observation
- `home_page.dart:75-80`: `Padding(padding: const EdgeInsets.only(bottom: 18), child: _BottomActions(...))`.
- `18` is not declared in `AppTokens` (`app_tokens.dart`). Nearby tokens are `itemGap=16`, `smallGap=8`, `mediumGap=12`, `pageTop=28`. No `bottomCtaInset = 18`.
- The intent is clear (lift the CTAs off the home-indicator / SafeArea floor) but the value is opaque to other authors.

### Root cause
The intro screen was the first surface needing a bottom CTA cluster, so the value was inlined. No catalog entry was created in `00-CATALOG.md` for "bottom CTA inset" since this is the only screen that uses it (the rest use `Scaffold.appBar:` + scrolling bodies).

### Figma reference
Figma `662:8356` — the "자녀 회원가입" button sits ~18 px above the home-indicator on a 812-h canvas. Needs re-measurement against Figma's actual Y coordinate (likely `Y = 770, height = 54, ∴ bottom inset = 812 - 770 - 54 = -12`… i.e., the measurement should be re-derived from the Figma frame). The current `18` is plausibly correct but undocumented.

### Recommended fix (do not apply now)
1. Re-measure against Figma and either reuse an existing token (e.g., `itemGap`) or add `AppTokens.introBottomInset` (or `bottomSheetSafeInset`) with the Figma-derived value.
2. Reference the token in `home_page.dart:76`.

---

## Issue 3: `_bridgeTitleStyle` duplicates typography logic outside `AppTypography`

### Observation
- `home_page.dart:12-21`. A top-level `const TextStyle _bridgeTitleStyle` is declared in the file scope, with `fontFamily: 'Sigmar'`, `fontSize: 40`, `letterSpacing: -0.776`, `height: 1.364`.
- The fallback `fontFamilyFallback: <String>[AppTypography.fontFamily]` is good — Sigmar only covers Latin glyphs.
- However, `AppTypography` (`app_typography.dart`) contains no Sigmar-based style; the brand wordmark is a one-off. There is no `AppTypography.brandWordmark` or `AppTypography.sigmar40` style for re-use.

### Root cause
The intro screen is the only consumer of the Sigmar font today, so the author scoped the style file-locally to avoid bloating the global typography catalogue. Defensible, but it breaks the project rule "all typography goes through `AppTypography`" — any future surface that needs the wordmark (e.g., splash screen, error boundary, "About" page) will copy this `TextStyle` and risk drift.

### Figma reference
Figma `662:8356` — the `Bridge` wordmark uses:
- font-family: `Sigmar` (Google Fonts)
- font-size: `40`
- font-weight: `400` (Regular only)
- color: `#6DB5FF` (matches `AppColors.brandWordmark`)
- letter-spacing: `-1.94%` × `40` = `-0.776` (matches code)
- line-height: `136.4%` (matches `height: 1.364`)

All values are correct against Figma. The defect is *location*, not values.

### Recommended fix (do not apply now)
1. Promote `_bridgeTitleStyle` to `AppTypography.brandWordmark` (or `displayBrandWordmark`).
2. Add a comment on the new constant noting "Used only for the Bridge intro wordmark; do not reuse for body text" so future authors don't pick it up by accident.

---

## Issue 4: `_IntroContent` vertical alignment uses magic `Alignment(0, -0.08)` — fragile across viewport heights

### Observation
- `home_page.dart:69-74`. `Expanded(child: Align(alignment: Alignment(0, -0.08), child: _IntroContent()))`.
- `Alignment(0, -0.08)` means horizontally centered, vertically biased 8% above the geometric center of the `Expanded` region (because Alignment uses the `(-1, -1)` top-left to `(1, 1)` bottom-right space).
- On a 812-h iPhone with `_BottomActions` consuming ~150 px (CTA 54 + gap 16 + textLink row 24 + bottom padding 18 + status bar 44 ≈ 156), `Expanded` is ~656 high. -0.08 offset = `-26 px` from center, i.e., `~302 px` from the top of the Expanded region — which corresponds to the Figma Y coordinate for the wordmark on a 812-canvas (rough).
- On a smaller phone (568-h iPhone SE 1st gen, viewport ~412 after SafeArea), -0.08 → ~13 px above center → wordmark at ~185 px from top of Expanded. Probably still acceptable but not visually pinned to a Figma anchor.

### Root cause
The alignment was tuned empirically against the 812-h reference rather than derived from a Figma Y coordinate. There is no comment explaining the `-0.08` magic number. The `isCompact` LayoutBuilder (`home_page.dart:78`) only adjusts the gap between the CTA and textLink row — not the intro content's vertical anchor.

### Figma reference
Figma `662:8356` (canvas 375×812) — the `Bridge` wordmark baseline is approximately at Y=257 (top of wordmark text). Status bar 44 + intent center ~258 / available height (812 − 44 − ~156) ≈ Y=214 of the Expanded region. With Expanded height ≈ 612, center = 306, target = 214 → fraction = `(214 − 306) / (612/2) = −0.30`, *not* `-0.08`. The current `-0.08` actually places the wordmark *lower* than Figma intends.

### Recommended fix (do not apply now)
1. Re-derive the alignment from a Figma Y coordinate. Either:
   - Use a top `SizedBox(height: figmaY - statusBar)` + `Column(mainAxisSize: min)` instead of `Align`.
   - Or compute the fraction once with a comment: `// −0.30 = Figma Y 257 in 612-h available region`.
2. Add a `Tolerances` comment if the `-0.08` value is intentionally a compromise for smaller devices.

---

## Issue 5: `LayoutBuilder` "compact" breakpoint at 700 px applies to inner `BoxConstraints`, not screen height

### Observation
- `home_page.dart:56-78`. `LayoutBuilder` is wrapped by `Center > ConstrainedBox(maxWidth: 375)`. The `constraints.maxHeight` passed to the builder is therefore the **height of the Scaffold body minus SafeArea** (not the device height) — but the **width** is `375` because of the inner ConstrainedBox.
- `isCompact: constraints.maxHeight < 700` compares against `700` — but on a 812-h iPhone with `~44` status bar + `~34` home indicator, the SafeArea body is `~734`, which is *above* 700 → not compact. On an iPhone SE (1st gen, 568 h, ~20 status bar) → SafeArea body ≈ 548 → compact (true). Reasonable.
- However, the `isCompact` branch (`home_page.dart:133`) only swaps `16 → 14` px gap between the CTA and the textLink row. That is a 2-px change, which is imperceptible. The actual overflow risk on small devices is the **intro content + bottom actions both fighting for vertical space** — and `Expanded` handles that gracefully, so the compact path is largely cosmetic theater.

### Root cause
The compact breakpoint was added to satisfy "responsive thinking" but the only thing it changes is a 2-px gap — not enough to materially affect layout. Meanwhile, the *real* small-device risk (intro content getting squeezed below the wordmark Figma position) is not addressed.

### Figma reference
N/A — Figma defines only the 375×812 canvas. Smaller devices are an app-side responsibility.

### Recommended fix (do not apply now)
1. Either remove the `isCompact` branch entirely (the 2-px gap change is noise) and use a single `SizedBox(height: 16)`.
2. Or make `isCompact` meaningfully different: e.g., shrink the icon (`99 × 0.85`), reduce the `SizedBox(height: 28)` body-copy gap, or both.
3. Consider switching the breakpoint to `MediaQuery.sizeOf(context).height < 700` so it reflects the actual device, not the post-SafeArea body — clearer intent.

---

## Issue 6: `BridgeButton` "로그인" textLink is wrapped in a `Row` with `'이미 계정이 있나요?'` label — accessibility regression

### Observation
- `home_page.dart:134-152`. The Row contains a plain `Text('이미 계정이 있나요?', ...)` followed by a `BridgeButton(variant: textLink, label: '로그인', ...)`.
- `BridgeButton` already wraps its `tappable` in `Semantics(button: true, enabled: ..., label: label)` (`bridge_button.dart:149-154`), so the screen reader will announce "로그인, button".
- However, the **context** ("이미 계정이 있나요?") is a sibling `Text` widget with no semantic association to the button. A VoiceOver/TalkBack user navigating linearly will hear "이미 계정이 있나요?" → swipe → "로그인, button" — acceptable but not optimal.
- A user navigating by buttons only (rotor / heading nav) will hear just "로그인, button" with no context. They'd need to manually inspect the surroundings to understand it's a sign-in shortcut.

### Root cause
The two text elements were composed visually without considering screen-reader semantics. There's no `Semantics(container: true, label: '이미 계정이 있나요? 로그인', button: true)` wrapper around the Row.

### Figma reference
Figma `662:8356` — the design shows the two pieces as visually separate (different colors: gray label, primary-blue link). The visual treatment is correct. The accessibility composition is an app-side concern Figma does not specify.

### Recommended fix (do not apply now)
1. Wrap the Row in `Semantics(container: true, button: true, label: '이미 계정이 있나요? 로그인', onTap: () => context.push('/login'), child: ExcludeSemantics(child: Row(...)))`.
2. Or merge the two into a single `RichText` with a `TapGestureRecognizer` on the "로그인" span — heavier refactor.

---

## Issue 7: `'이미 계정이 있나요?'` label color uses `gray400` but `letterSpacing` deviates from `AppTypography.bodyMedium`

### Observation
- `home_page.dart:139-143`. `AppTypography.bodyMedium.copyWith(color: AppColors.gray400, letterSpacing: 0.09)`.
- `AppTypography.bodyMedium` (`app_typography.dart:98-105`) declares `letterSpacing: 0.57`. The override to `0.09` is an 84% reduction — visibly tighter tracking on screen.
- The body copy on line 109-112 (`heading2Regular.copyWith(letterSpacing: -0.24)`) also overrides letter-spacing from the base style's `-1.2` to `-0.24` — another large deviation.

### Root cause
The base `AppTypography` styles encode letter-spacing as raw px values (e.g., `0.57`, `-1.2`, `-1.94`), which look like they were imported as *percentages-of-em* from Figma (`+0.57%` → `+0.0057em` → `+0.228 px` at 40px, not `0.57 px`). The unit mismatch means every consumer overrides letter-spacing per-screen, defeating the purpose of having a typography catalogue.

This is a **catalogue-wide issue**, not a home-page-only issue, but it surfaces here because both text styles on this screen override letter-spacing.

### Figma reference
Figma `662:8356`:
- Wordmark: `letterSpacing: -1.94% × 40 = -0.776 px` → code uses `-0.776` ✓ (correct in `_bridgeTitleStyle`).
- Body copy "통제를 넘어 자율로...": `letterSpacing: -1.2% × 20 = -0.24 px` → code uses `-0.24` ✓.
- "이미 계정이 있나요?": `letterSpacing: 0.57% × 16 = 0.0912 px` → code uses `0.09` ≈ ✓ (but `bodyBold` style on `app_typography.dart:94` already has the correct `0.0912` value, while `bodyMedium` on line 103 has the wrong `0.57`).

So the bug is in `AppTypography.bodyMedium` (line 103) — it should be `0.0912`, not `0.57`. The home page's `letterSpacing: 0.09` override is a *workaround* for the catalogue bug, not a defect of the home page itself.

### Recommended fix (do not apply now)
1. Fix `AppTypography.bodyMedium.letterSpacing` from `0.57` to `0.0912` (the value already used by `bodyBold` on line 94).
2. Audit other `AppTypography` styles for the same px-vs-%-of-em unit confusion. Likely `heading1Bold/Medium/Regular` (`letterSpacing: -1.94`) and `heading2*` (`letterSpacing: -1.2`) and `labelBold/Medium` (`letterSpacing: 1.45`) and `captionBold/Regular` (`letterSpacing: 2.52`) are all wrong — they look like raw `%` values that were never multiplied by font-size and converted to px.
3. Remove the per-screen `letterSpacing` overrides once the catalogue is fixed.

---

## Issue 8: Status-bar overlay style hardcoded to `dark` — fragile if intro background ever changes

### Observation
- `home_page.dart:51-52`. `AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: Scaffold(backgroundColor: AppColors.gray050, ...))`.
- `SystemUiOverlayStyle.dark` means **dark icons on a light background** (good — the intro background `gray050` is `#FAFBFC`).
- If the design ever changes to a dark intro (e.g., a brand-color gradient), this would need updating in lockstep.

### Root cause
Inline constant instead of a theme-derived value. Defensible (intro is intentionally locked to a light background), but worth flagging as a one-line coupling.

### Figma reference
Figma `662:8356` background is `#FAFBFC` (matches `AppColors.gray050`). Dark status bar icons are correct.

### Recommended fix (do not apply now)
1. Either accept the inline constant (low risk, light background unlikely to change).
2. Or expose a helper `AppTheme.overlayStyleFor(backgroundColor)` that returns `dark`/`light` based on luminance — defers the decision to the color.

---

## Token discipline summary

| Concern | Token used | Status |
|---|---|---|
| Wordmark color | `AppColors.brandWordmark` | ✓ correct |
| Wordmark font | `'Sigmar'` literal + `AppTypography.fontFamily` fallback | △ font literal not in token catalogue |
| Wordmark style | `_bridgeTitleStyle` (file-local) | ✗ should be `AppTypography.brandWordmark` |
| Body copy style | `AppTypography.heading2Regular.copyWith(...)` | ✓ token base + override |
| Body copy color | `AppColors.gray600` | ✓ correct |
| Sign-in label color | `AppColors.gray400` | ✓ correct |
| Frame width | `AppTokens.mobileFrameWidth` | ✓ correct |
| Horizontal padding | `AppTokens.mobileHorizontalPadding` | ✓ correct |
| Bottom CTA inset | `18` (literal) | ✗ not in `AppTokens` (see Issue 2) |
| Background | `AppColors.gray050` | ✓ correct |
| Icon container size | `width: 99, height: 98` (literal) | △ matches SVG intrinsic but not a named token |
| Inter-element gaps | `20`, `28`, `16/14` literals | △ ad-hoc, not from `AppTokens.itemGap/sectionGap` |

---

## Routing checks

| Check | Status | Evidence |
|---|---|---|
| `/signup` route exists | ✓ | `app_router.dart:31` |
| `/login` route exists | ✓ | `app_router.dart:30` |
| `/child-home` route exists | ✓ | `app_router.dart:48-51` |
| "자녀 회원가입" wired to `/signup` | ✓ | `home_page.dart:131` (`context.push('/signup')`) |
| "로그인" wired to `/login` | ✓ | `home_page.dart:149` (`context.push('/login')`) |
| Cached-login redirect to `/child-home` | ✓ (with flash — see Issue 1) | `home_page.dart:46` |
| `/` mounted to `HomePage` | ✓ | `app_router.dart:29` |
| Push vs. go semantics | △ | CTAs use `push` (intro stays in stack), redirect uses `go` (intro replaced). Push means the user can swipe back from /signup or /login *to the intro* even after authenticating. Possibly intentional, possibly a regression vector — flag for product. |

---

## Asset checks

| Check | Status | Evidence |
|---|---|---|
| `assets/icons/Icon Container.svg` exists | ✓ | 2667 bytes, 99×98 viewBox |
| Asset bundled in `pubspec.yaml` | ✓ | `pubspec.yaml:69` (`assets/icons/`) |
| `Sigmar-Regular.ttf` bundled | ✓ | `pubspec.yaml:75-78` |
| `flutter_svg` imported | ✓ | `home_page.dart:3` |

---

## Composition checks

| Check | Status | Evidence |
|---|---|---|
| `Scaffold` wraps body | ✓ | `home_page.dart:53` |
| `SafeArea` wraps content | ✓ | `home_page.dart:55` |
| `Center > ConstrainedBox(maxWidth: 375)` for mobile frame | ✓ | `home_page.dart:58-61` |
| `LayoutBuilder` for responsiveness | ✓ but limited impact (see Issue 5) | `home_page.dart:56-87` |
| `Expanded + Align` for intro vertical pin | △ magic alignment (see Issue 4) | `home_page.dart:69-74` |
| `Column > mainAxisSize.min` for intro & bottom | ✓ | `home_page.dart:100, 127` |
| No deprecated `Stack` overlap, no `Positioned` outside `Stack` | ✓ | clean tree |

---

## Summary of severity

| # | Issue | Severity |
|---|---|---|
| 1 | One-frame intro flash before cached-login redirect | 🟡 medium — user-visible jank, race-window risk |
| 7 | `AppTypography.bodyMedium.letterSpacing` likely uses wrong units (catalogue-wide) | 🟡 medium — affects every screen using bodyMedium |
| 3 | `_bridgeTitleStyle` should live in `AppTypography` | 🟢 low — DRY/token discipline, no visual defect today |
| 4 | `Alignment(0, -0.08)` is a magic number, may not match Figma Y | 🟢 low — visual nudge, needs Figma re-measurement to confirm |
| 2 | Hardcoded `bottom: 18` padding not a token | 🟢 low — token discipline |
| 5 | `LayoutBuilder` `isCompact` branch only changes 2 px | 🟢 low — cosmetic |
| 6 | "이미 계정이 있나요? 로그인" lacks combined `Semantics` | 🟢 low — a11y improvement |
| 8 | `SystemUiOverlayStyle.dark` hardcoded | 🟢 low — inline constant |

No 🔴 critical issues. The page renders correctly against Figma on the reference 375×812 viewport.
