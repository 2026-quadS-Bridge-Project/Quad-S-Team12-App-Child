# Audit — Delete Account Complete Page

**Target**: `lib/features/my_page/presentation/pages/delete_account_complete_page.dart`
**Figma node**: `773-11070` (`scr/child-mypage-탈퇴완료`)
**Spec ref**: `docs/figma-specs/05-delete.md` § "탈퇴 완료 (`773:11070`)"
**Mode**: Diagnostic only — **do not fix**.

---

## Summary

| # | Severity | Topic | Status |
|---|----------|-------|--------|
| 1 | INFO | SafeArea / Scaffold composition | OK |
| 2 | INFO | Centering pattern (`Center` vs `Align(topCenter)`) | OK — already fixed |
| 3 | INFO | Text style token choice (`heading2Bold`) | OK at the token-selection level |
| 4 | HIGH | Font weight — token is SemiBold w600, Figma requires Bold w700 | Mismatch |
| 5 | MEDIUM | Letter spacing — token uses `-1.2`, Figma requires `-0.24` | Mismatch |
| 6 | HIGH | Text color — current `inkBlack` (#050505), Figma `#5F6165` (gray600) | Mismatch |
| 7 | INFO | Width 328 | OK |
| 8 | INFO | 3-second `Timer` auto-redirect with `dispose()` cancel | OK |
| 9 | INFO | `AuthSession.clearLogin()` in `initState` | OK |
| 10 | INFO | Message text content verbatim | OK |
| 11 | LOW | `ConstrainedBox(maxWidth: 375)` outer cap | Unnecessary but harmless |
| 12 | LOW | Back navigation not blocked / `PopScope` missing | Possible session-cleared back-stack issue |
| 13 | LOW | `decoration: TextDecoration.none` explicit override | Defensive but redundant under `Scaffold`/`Material` |

**Findings count**: **13** (3 mismatches against Figma, 3 low-risk concerns, 7 verified-OK checkpoints).

---

## Issue 1 — SafeArea / Scaffold composition (OK)

- **Observation**: `Scaffold(backgroundColor: AppColors.gray050, body: SafeArea(child: Center(...)))` — bg fills entire screen incl. status bar area; `SafeArea` insets the message away from notch/home indicator.
- **Root cause**: N/A — correct composition.
- **Figma ref**: Frame `375×812` with `0–44` status bar + `bottom` 32px home indicator (`359:5747`). Spec lines 89–95 confirm "no header, no topbar, no back button"; `SafeArea` correctly defers status-bar/home-indicator space to system.
- **Fix**: None required.

---

## Issue 2 — Centering pattern (OK — recently fixed)

- **Observation**: Uses `Center(child: ConstrainedBox(... SizedBox(width: 328, child: Text(...))))`. Both axes are centered.
- **Root cause**: Spec docs/figma-specs/05-delete.md line 92 (`anchor: left=calc(50%-0.5px), top=calc(50%-51.5px)`) and the spec's delta table (line 171 originally flagged `Align(topCenter)` as incorrect — the current `Center` resolves that).
- **Figma ref**: `773:11071` is centered both horizontally and vertically inside the 375×812 frame.
- **Fix**: None — previous fix is correct.

---

## Issue 3 — Text style token (OK at selection)

- **Observation**: Uses `AppTypography.heading2Bold.copyWith(color: AppColors.inkBlack, decoration: TextDecoration.none)`.
- **Root cause**: `heading2Bold` is the named token whose font-size (20) matches Figma. Token choice is correct in principle.
- **Figma ref**: 05-delete.md line 117–120 — "Pretendard Bold 20 / line 1.4 / letter -0.24".
- **Fix**: None at token-selection level. See Issue 4 / 5 / 6 for property-level mismatches that the token does not satisfy.

---

## Issue 4 — Font weight: token is SemiBold (w600), Figma requires Bold (w700) — HIGH

- **Observation**: `AppTypography.heading2Bold` is declared in `lib/core/theme/app_typography.dart:35-42` with `fontWeight: FontWeight.w600` (SemiBold). The `copyWith` call does **not** override `fontWeight`, so the rendered weight is **SemiBold 600**.
- **Root cause**: Token naming says "Bold" but the actual `FontWeight` constant is `w600`. The 05-delete.md spec (line 122) explicitly calls this out: "weight should be **Bold (700)**". Current page inherits the token weight unmodified.
- **Figma ref**: 773:11072 rendered runs use Pretendard **Bold 700**. Spec line 118: "Heading 2 / Bold (override) — Pretendard **Bold 20**".
- **Fix (proposed, do not apply)**: Either override per-call with `.copyWith(fontWeight: FontWeight.w700)` or correct `heading2Bold` token to `w700`. Token-level fix is preferable but has cross-screen impact — verify all `heading2Bold` consumers before changing.

---

## Issue 5 — Letter spacing: token uses `-1.2`, Figma requires `-0.24` — MEDIUM

- **Observation**: `heading2Bold` token (`app_typography.dart:40`) declares `letterSpacing: -1.2`. The page does not override it.
- **Root cause**: Figma rendered run letter-spacing is `-0.24` (Bold override); the **declared** style on the text node is `Heading 2/Regular` with `-1.2`, but the rendered text overrides to `-0.24`. Spec line 122 confirms: "letter-spacing **-0.24** (not -0.2158)".
- **Figma ref**: 773:11072 rendered runs.
- **Fix (proposed, do not apply)**: `.copyWith(letterSpacing: -0.24)` at the call site (token-level change would affect every other `heading2Bold` consumer where -1.2 may be intentional for short titles).

---

## Issue 6 — Text color: `inkBlack` vs Figma `gray600` — HIGH

- **Observation**: Current uses `color: AppColors.inkBlack` (`#050505`).
- **Root cause**: Per spec, the target color is `#5F6165` (gray600). Switching to `inkBlack` produces a near-black tone that visually diverges from the muted gray intended by Figma.
- **Figma ref**: 05-delete.md lines 107–112 — Color table: `#5F6165` → gray600 → "Title text color". Spec delta line 177: "Color — `AppColors.gray600` ✓ — OK".
- **Fix (proposed, do not apply)**: Replace `AppColors.inkBlack` with `AppColors.gray600`.

---

## Issue 7 — Width 328 (OK)

- **Observation**: `SizedBox(width: 328, child: Text(...))`.
- **Root cause**: N/A.
- **Figma ref**: 05-delete.md line 92 — intro section `328` wide.
- **Fix**: None.

---

## Issue 8 — 3-second auto-redirect with Timer dispose (OK)

- **Observation**: `_redirectTimer = Timer(const Duration(seconds: 3), () { if (!mounted) return; context.go('/'); })` in `initState`; `_redirectTimer?.cancel()` in `dispose()`. `mounted` guard present.
- **Root cause**: N/A — textbook Timer disposal pattern. Prevents `setState`/`context` after dispose, prevents leaks if the user pops manually before 3s elapses.
- **Figma ref**: Not specified in Figma (passive screen). 05-delete.md line 132 acknowledges "not specified in Figma, but Figma has no interactive elements, so a timed auto-redirect or user-tap-to-continue is required".
- **Fix**: None.

---

## Issue 9 — AuthSession.clearLogin() in initState (OK)

- **Observation**: `unawaited(AuthSession.clearLogin())` invoked synchronously inside `initState`.
- **Root cause**: Fire-and-forget is acceptable here because (a) we do not need the result before navigating, (b) the page is the final UX state of the deletion flow, (c) any failure surfaces in the next session's login attempt.
- **Figma ref**: Not in Figma — UX/security requirement.
- **Fix**: None. Minor optional improvement (not required): chain the redirect after `clearLogin()` completes to guarantee storage flush before `/` route loads any auth-aware widget. Current 3s window almost certainly exceeds clearLogin's IO latency, so the race is theoretical.

---

## Issue 10 — Message text content (OK — verbatim)

- **Observation**: `'탈퇴가 완료되었습니다.\n언제든 다시 찾아와주세요!'`
- **Root cause**: N/A.
- **Figma ref**: 05-delete.md lines 101–103 — `탈퇴가 완료되었습니다.` (line 1), `언제든 다시 찾아와주세요!` (line 2). `\n` line break and trailing `!` / `.` punctuation match.
- **Fix**: None.

---

## Issue 11 — `ConstrainedBox(maxWidth: 375)` outer cap — LOW

- **Observation**: `ConstrainedBox(constraints: BoxConstraints(maxWidth: 375), child: SizedBox(width: 328, ...))`.
- **Root cause**: The inner `SizedBox(width: 328)` already pins the content width. The outer 375 cap is redundant for centering — `Center` already centers the 328-wide child within any larger viewport. The 375 cap is only meaningful on tablets / very wide screens, but even then the inner 328 box dominates.
- **Figma ref**: 375×812 frame is the design reference, but Figma-frame width is not a layout constraint in Flutter — it's the device width assumption. No equivalent wrapping primitive in Figma node tree.
- **Fix (proposed, do not apply)**: Drop `ConstrainedBox` — the `SizedBox(width: 328)` alone is sufficient. Harmless but adds one widget layer for no functional benefit.

---

## Issue 12 — Back navigation not blocked — LOW

- **Observation**: No `PopScope` / `WillPopScope` / `onWillPop`. Hardware back during the 3s window could pop back to the previous route (likely the dialog parent / mypage) — but mypage requires an authenticated session that was just cleared.
- **Root cause**: Session has been cleared via `AuthSession.clearLogin()`; popping back to mypage leaves the user on a page whose data sources will fail auth checks. The router may auto-redirect, but the behavior depends on the auth guard chain (not audited here).
- **Figma ref**: 05-delete.md line 133 — "Back / hardware back: Should be disabled or redirected to root (session is already cleared)". Spec explicitly flags this requirement.
- **Fix (proposed, do not apply)**: Wrap body in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go('/'); })` to coerce back-button to root, or simply `PopScope(canPop: false)` since the 3s redirect handles forward motion.

---

## Issue 13 — `decoration: TextDecoration.none` explicit override — LOW

- **Observation**: `.copyWith(color: ..., decoration: TextDecoration.none)`.
- **Root cause**: Inside a `Scaffold` with a `MaterialApp`, Text defaults to `DefaultTextStyle` which does not set an underline. The explicit `TextDecoration.none` is defensive — useful if this widget is ever rendered outside Material context (e.g., raw `Navigator` without `MaterialApp` wrap, or under a `WidgetsApp` directly), where Flutter applies a yellow-underline error style. Not strictly necessary here.
- **Figma ref**: No text decoration in Figma node.
- **Fix (proposed, do not apply)**: Safe to remove; or keep as defensive coding. No behavioral impact under current `MaterialApp`-rooted router.

---

## Cross-references

- `lib/core/theme/app_typography.dart:35-42` — `heading2Bold` token definition.
- `lib/core/theme/app_colors.dart:10,37` — `gray600` and `inkBlack` definitions.
- `lib/core/auth/auth_session.dart:24` — `clearLogin()` signature.
- `docs/figma-specs/05-delete.md:84-138` — complete spec section for `773:11070`.
- `docs/figma-specs/05-delete.md:167-180` — pre-existing delta table for this page.

---

## Verdict

The page is **functionally correct** (redirect, session clear, layout, text content all match intent). The remaining mismatches are **visual fidelity** issues against Figma:

- **Must fix** (visible to user): Issue 4 (font weight), Issue 6 (text color).
- **Should fix** (subtle): Issue 5 (letter spacing).
- **Nice to have**: Issue 12 (back-button guard).
- **Cosmetic / cleanup**: Issue 11 (redundant ConstrainedBox), Issue 13 (defensive decoration override).
