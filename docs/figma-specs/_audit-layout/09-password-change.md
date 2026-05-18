# 09 — Password Change Layout Audit

**Target**: `lib/features/my_page/presentation/pages/password_change_page.dart`
**Figma nodes**: `773-11124` (empty), `773-11134` (typing + clear), `773-12009` (all valid), plus `773-11733` / `773-11519` / `773-11626` error variants from spec 04b.
**Specs**: `docs/figma-specs/04a-password-change.md`, `docs/figma-specs/04b-password-change.md`.
**Audit date**: 2026-05-18.
**Mode**: Diagnostic only — no fixes applied.

---

## Issue 1 — Inline `_PasswordChangeTopBar` duplicates `BridgeAppBar`; back-button geometry diverges

**Observation**
- File defines a private `_PasswordChangeTopBar` (lines 261–301) that hand-rolls a `SizedBox(height: 52) + Stack` with a `Positioned(left: 0, top: 14, width: 24, height: 24)` back button.
- The shared `BridgeAppBar` (`lib/core/widgets/layout/bridge_app_bar.dart`) already implements the same 52-height top bar with back + centered title, anchoring the back icon at `left: _edgeInset = 14` and vertically centering it.
- 12 other screens (`login_page`, `my_page`, `mission_info_page`, `time_setup_*`, `report_page`, `time_confirm_page`, `signup_page`, etc.) consume `BridgeAppBar`. Password change is the lone holdout.

**Root cause**
The screen pre-dates the `BridgeAppBar` rollout and was not migrated. Because it lives inside a `Padding(horizontal: AppTokens.pageHorizontal = 24)` wrapper (line 181), the inline top bar uses `left: 0` to compensate, putting the back icon at absolute x=24 from the screen edge — but Figma `325:17287` places back at `left: 24` from the frame edge with the top bar itself spanning full-width 375. Title color also differs: `_PasswordChangeTopBar` uses `AppTypography.headlineMedium` (Medium 500) while `BridgeAppBar` uses `headlineBold` (Semibold 600). Per spec 04a §Typography the title is "Pretendard Medium 18" — so the *inline* one matches Figma, but the *shared* `BridgeAppBar` does not. This is an inconsistency between spec and shared component that needs reconciling before migration, otherwise migrating blindly will regress the title weight.

**Figma ref**
- Spec 04a, lines 17–18: "Centered title '비밀번호 수정' (Pretendard Medium 18 / line-height 1.445 / letter-spacing -0.02 / color `#050505`)."
- Spec 04b, line 12: top bar `H 52`, back `left:24/top:14, size 24`.
- `BridgeAppBar` line 58: `AppTypography.headlineBold` (Semibold) — inconsistent with spec.

**Fix (not applied)**
Pick one of two paths:
1. Replace `_PasswordChangeTopBar` with `BridgeAppBar(title: '비밀번호 수정')` and lift `Padding(horizontal: 24)` so the top bar is full-bleed. Then patch `BridgeAppBar` to use `headlineMedium` if 비밀번호 수정 matches the broader pattern (cross-check mypage/mission-info Figma weights first).
2. Keep the inline bar but rebuild it as a full-bleed widget outside the `Padding`, restoring `left: 24` semantics.

---

## Issue 2 — `Scaffold` lacks `resizeToAvoidBottomInset` handling and uses `Spacer` inside `SingleChildScrollView` (keyboard-overflow risk)

**Observation**
- `Scaffold` (line 164) takes default `resizeToAvoidBottomInset: true`.
- Body is `SafeArea > LayoutBuilder > ConstrainedBox > SingleChildScrollView > ConstrainedBox(minHeight: constraints.maxHeight) > IntrinsicHeight > Column` with a `Spacer()` between Field 3 and the submit button (line 240).
- `LayoutBuilder.constraints.maxHeight` does **not** update when the keyboard appears because the scaffold body is already inset by `MediaQuery.viewInsets.bottom`. The `minHeight` then forces the column to remain tall, the `Spacer` fights to fill leftover space, and the submit button ends up *below* the visible viewport when keyboard is open on smaller devices (iPhone SE / 4-inch). User must scroll, and the scroll glides against the rigid `IntrinsicHeight`.

**Root cause**
`Spacer` inside a scrollable + `IntrinsicHeight` is an anti-pattern: it consumes any leftover flex, but when the viewport shrinks (keyboard) the `minHeight` constraint keeps the column at its pre-keyboard height, so the button lives outside the keyboard-free area unless the user scrolls. Combined with `Spacer`, the button has no natural "anchor near the last field" fallback.

**Figma ref**
- Spec 04a, line 24: "Submit Button — `bottom: 63`, centered, `width: 327`."
- Spec 04b, line 8: "Submit button: absolute `bottom:63, centered`."
- Figma positions the button absolutely at 63px from the bottom of a 812 canvas — that's the *no-keyboard* layout. The Flutter port should ensure that when the keyboard is open, the button moves *up* with the keyboard (or stays reachable via scroll) without being clipped.

**Fix (not applied)**
- Replace `Spacer()` + `IntrinsicHeight` with a `Column` that uses fixed spacing (e.g., `SizedBox(height: 32)` then submit button) and rely on `SingleChildScrollView` to scroll naturally when keyboard appears.
- Or move the submit button outside the scroll view, into `Scaffold.bottomNavigationBar` (wrapped in `Padding(EdgeInsets.only(bottom: MediaQuery.viewInsets.bottom))`) so it always sits flush above the keyboard.
- Either path needs verification on iPhone SE 1st-gen (375×667) where the spec is tightest.

---

## Issue 3 — Hard-coded scaffold padding ignores `BridgeAppBar` migration path; `pageHorizontal = 24` applied at scroll-view level

**Observation**
- `Padding(horizontal: AppTokens.pageHorizontal)` wraps the entire column (line 181), including the inline top bar.
- Inline `_PasswordChangeTopBar` therefore sits inside a 24px-inset container.
- All other top-bar pages render `BridgeAppBar` as `Scaffold.appBar` (full-bleed) with horizontal padding applied only to the body content.

**Root cause**
The whole-screen `Padding` was chosen so the form column auto-aligns at x=24 to match Figma's `left: 24` container origin. But that same padding now constrains the top bar, which Figma renders full-bleed. This is the structural reason Issue 1 hard-codes `left: 0` in the inline top bar.

**Figma ref**
- Spec 04a lines 17, 19: top bar `top: 44, height: 52, full width 375`; form container at `left: 24, width: 327`.

**Fix (not applied)**
Restructure body as:
```
Scaffold(
  appBar: BridgeAppBar(title: '비밀번호 수정'),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppTokens.pageHorizontal),
      child: Column(...form fields + button...)
    )
  ),
)
```
This naturally separates chrome from content padding and removes the `left: 0` workaround.

---

## Issue 4 — Field container border-radius 12 but spec says 12 (OK), padding 16 horizontal only (missing vertical)

**Observation**
- Field container (line 387): `height: 50`, `borderRadius: 12`, `border: 1`, `padding: EdgeInsets.symmetric(horizontal: 16)`.
- Spec 04a line 23: "input (`height: 50`, `borderRadius: 12`, border `1px #D5D8DE`, `padding: 12/16`)".
- Spec 04b line 6: "Field: `H 50, radius 12, border 1px, padding 16/12, full width 327`".

**Root cause**
Vertical padding (`12`) is absent in code. The fixed `height: 50` + `Row` with no vertical padding leaves Flutter to center the `TextField` content vertically, which usually works but the cursor + baseline drift slightly versus the design intent of `padding: 12 vertical` constraining a `26px` text row inside.

**Figma ref**
- 04a line 23 (`padding: 12/16`), 04b line 6 (`padding: 16/12` — same in different notation).

**Fix (not applied)**
Either:
- `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)` and remove `height: 50` (let intrinsic + padding produce ~50), OR
- Keep `height: 50` but verify the TextField vertical centering matches Figma at 14/Medium baseline.

---

## Issue 5 — Border color does NOT flip on focus to primary; gray200 → destructive only

**Observation**
- Field border logic (line 367–369):
  ```
  final Color borderColor = widget.helperSeverity == _HelperSeverity.error
      ? AppColors.destructive
      : AppColors.gray200;
  ```
- No branch for `widget.focusNode.hasFocus`.

**Root cause**
The implementation derives border purely from `helperSeverity`. The spec mentions focus visually only via the clear button presence; it does NOT specify a primary-color focus border. Re-checking spec 04a variant 2 (`773:11134`): the focused 새 비밀번호 field shows border `#D5D8DE` (gray200), unchanged from neutral. So **no fix is required** for border-on-focus — the audit check item is a false positive against this design. Flag it as "verified intentional".

**Figma ref**
- Spec 04a line 92 (variant 2 colors): "`#D5D8DE` gray200 — Input border (still neutral while typing, no error)".

**Fix (not applied)**
None. Document the intentional absence so future contributors don't add a primary-focus border by mistake.

---

## Issue 6 — Clear button visibility uses `focusNode.hasFocus && content.isNotEmpty` — matches spec, but `onClear` does not re-request focus

**Observation**
- Clear button shown when `widget.focusNode.hasFocus && widget.controller.text.isNotEmpty` (line 364–365). Matches Figma variant 2.
- `_clearField` (line 120) calls `controller.clear()` + `onChanged('')` but does **not** call `widget.focusNode.requestFocus()`.

**Root cause**
After clearing, focus *should* remain on the field so the user can keep typing (and Figma variant 2 implies sustained focus). In practice, the `GestureDetector` for the clear icon does NOT steal focus from the `TextField`, so focus stays — but only because Flutter's default behavior doesn't unfocus on outside taps within the same Material parent. This is fragile: if the parent ever wraps in a `GestureDetector(onTap: unfocus)` for dismiss-keyboard-on-tap, the clear-button tap will lose focus.

**Figma ref**
- Spec 04a line 114: "Clear button (✕) inside focused field → clears that field, returns to placeholder state."

**Fix (not applied)**
Explicit defensiveness:
```dart
void _clearField(...) {
  controller.clear();
  onChanged('');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) widget.focusNode.requestFocus();
  });
}
```
Low priority — works today, brittle to surrounding changes.

---

## Issue 7 — Helper-text severity logic for "기존 비밀번호" only flips error after submit, never neutral

**Observation**
- Field 1 helper severity (line 195–197):
  ```
  helperSeverity: _currentPasswordHelperText != null
      ? _HelperSeverity.error
      : _HelperSeverity.neutral
  ```
- `_currentPasswordHelperText` returns the error string only when `_currentPasswordError == currentMismatch`. There is no neutral rule hint for field 1.
- Field 2 (new password) correctly switches between neutral (rule hint) and error (same-as-current or rule-failure-post-submit) per `_newPasswordHelperSeverity`.
- Field 3 (confirm) only ever shows error.

**Root cause**
Logic is correct *per spec* — field 1 has no neutral hint state (spec 04b variant `773-11733`); field 3 has only an error helper (spec 04b variant `773-11626`). Field 2's `_newPasswordRuleSeverityIsError` toggles correctly between neutral on typing and error on submit. **This check passes.**

**Figma ref**
- Spec 04a lines 185–186 (deltas): "Helper-text color is wrong for the neutral rule hint" — *this delta was already fixed* because the current code has `_HelperSeverity` enum and `_newPasswordHelperSeverity` getter.

**Fix (not applied)**
None — verified compliant.

---

## Issue 8 — Validation messages are verbatim Korean per spec — VERIFIED

**Observation**
- Line 66: `'기존 비밀번호가 일치하지 않습니다.'` matches spec 04b line 32.
- Line 71: `'새 비밀번호는 기존 비밀번호와 달라야 합니다.'` matches spec 04b line 77.
- Line 74: `'영문 대문자, 소문자, 숫자, 특수문자 모두 혼합 (12~15자)'` matches spec 04a line 78.
- Line 93: `'비밀번호가 일치하지 않습니다.'` matches spec 04b line 118.
- Placeholders/labels lines 190–225 all match.

**Root cause**
None — strings are correct.

**Figma ref**
Spec 04a §Texts and spec 04b §Texts across all three error variants.

**Fix (not applied)**
None.

---

## Issue 9 — Submit button height = 54 ✓, radius via `AppTokens.buttonRadius = 8` ✓; disabled label color uses `gray300` ✓

**Observation**
- `SizedBox(height: 54)` (line 475), `borderRadius: AppTokens.buttonRadius` (line 483, = 8).
- Disabled bg `gray200`, disabled label `gray300`. Enabled bg `primary`, enabled label `white`.

**Root cause**
None — matches spec 04a lines 24, 50, 56 and spec 04b line 8.

**Fix (not applied)**
None.

---

## Issue 10 — Token discipline: clean. No stray hex literals found

**Observation**
- No `Color(0xFF050505)` in the file — input/label text colors use `AppColors.inkBlack`, `AppColors.gray600`, `AppColors.gray500`, `AppColors.gray300`, `AppColors.gray200`, `AppColors.gray100`, `AppColors.primary`, `AppColors.destructive`, `AppColors.white`.
- `AppColors.inkBlack` confirmed in `app_colors.dart:37` as `Color(0xFF050505)`.
- `AppColors.gray500` confirmed at `Color(0xFF777A7F)` — matches spec 04a "NEW — flag" gray500 helper color, but the field helper currently uses `gray500` for neutral severity ✓.

**Root cause**
None — token migration already complete from the 04a spec's "deltas" notes.

**Fix (not applied)**
None.

---

## Issue 11 — Keyboard scrolling: `SingleChildScrollView` present but `Spacer` + `IntrinsicHeight` defeats it on small devices

**Observation**
Already covered under Issue 2. Cross-references:
- Three fields × (label + input50 + helper-or-spacer18) ≈ 3 × ~96 = 288px + gaps 22 + 20 + 20 = 350px just for form column.
- Top bar 52 + bottom button 54 + bottom 28 padding = 134.
- Total ≈ 484. On iPhone SE 2nd-gen (375 × 667) minus status/system insets (~120) = ~547 usable. Fits without keyboard.
- With keyboard (~291px on iPhone SE), usable becomes ~256px — column will overflow heavily and the `Spacer` will collapse to zero, but `IntrinsicHeight` will still try to keep min height, causing scroll friction.

**Root cause**
Same as Issue 2.

**Figma ref**
N/A — keyboard handling is a Flutter implementation concern not in Figma.

**Fix (not applied)**
See Issue 2.

---

## Issue 12 — `LengthLimitingTextInputFormatter(15)` enforces max length, but `FilteringTextInputFormatter.deny(\s)` blocks whitespace — verify regex `[^\s]{12,15}$` consistency

**Observation**
- Input formatter blocks any whitespace (line 405): `FilteringTextInputFormatter.deny(RegExp(r'\s'))`.
- Validation regex (line 24): `^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])[^\s]{12,15}$`.
- These are consistent — the regex's `[^\s]{12,15}` is implicitly enforced by the deny-whitespace formatter + length limit 15.
- However, the regex's minimum-length-12 is NOT pre-enforced; the user can submit an 11-character valid-character-class password and it will silently fail validation. Current UX: button stays disabled, and on submit the helper appears.

**Root cause**
By design (helper text "12~15자" guides the user). No bug.

**Figma ref**
Spec 04a line 74 (helper text).

**Fix (not applied)**
None.

---

## Issue 13 — `_handleCurrentPasswordChanged` clears the error too eagerly

**Observation**
- Line 96–100: on every keystroke to current password, `_currentPasswordError = null` is set, regardless of whether the new value matches.
- The error only re-appears on the next submit. So once a user fails submit, types one character, the red border disappears — even if the new value is still wrong.

**Root cause**
Defensible UX (clear error on user activity) but inconsistent with field 2/3 which re-validate live. Field 1 cannot validate live because validation requires comparing against `_mockCurrentPassword` (server roundtrip in production). Current code's mock comparison would actually allow live validation, but the implementer chose submit-time-only to mirror real API behavior. This is intentional.

**Figma ref**
Spec 04b line 53: "Field 1: on focus or typing → error clears (border → gray200, helper hidden)" — matches current behavior.

**Fix (not applied)**
None — verified compliant with spec interactions.

---

## Issue 14 — `IntrinsicHeight` + `SingleChildScrollView` is performance-expensive

**Observation**
`IntrinsicHeight` forces a second layout pass to measure children's intrinsic height. Combined with three `TextField`s (which themselves trigger frequent re-layouts on focus/text changes), this can cause jank on lower-end Android devices.

**Root cause**
Used to make `Spacer` work inside scroll view. Removing `Spacer` (Issue 2) removes the need for `IntrinsicHeight`.

**Figma ref**
N/A — Flutter perf concern.

**Fix (not applied)**
Bundled with Issue 2's fix.

---

## Summary of Checks (10-item rubric)

| # | Check | Status | Note |
|---|-------|--------|------|
| 1 | SafeArea / Scaffold composition + back-button position | ⚠️ | Issues 1, 2, 3 |
| 2 | `_PasswordChangeTopBar` vs `BridgeAppBar` | ❌ | Issue 1 — duplicates shared widget |
| 3 | Field height 50, padding 16/12, border 1px | ⚠️ | Issue 4 — vertical padding 12 missing |
| 4 | Focus border flips primary | ✅ | Issue 5 — intentional per Figma (no flip) |
| 5 | Clear ✕ visible only when focused + has content | ✅ | Issue 6 — works, brittle to focus-stealing parents |
| 6 | Helper severity neutral vs error | ✅ | Issue 7 — `_HelperSeverity` enum correctly applied |
| 7 | Validation messages verbatim Korean | ✅ | Issue 8 |
| 8 | Submit disabled/enabled, height 54, radius 8 | ✅ | Issue 9 |
| 9 | Keyboard scrolling | ❌ | Issues 2, 11, 14 — `Spacer` + `IntrinsicHeight` anti-pattern |
| 10 | Token discipline | ✅ | Issue 10 — all hex literals migrated to tokens |

**Severity ranking (highest impact first)**
1. **Issue 2/11/14** — Keyboard scrolling: submit button can be clipped on small devices; jank risk.
2. **Issue 1/3** — Inline top bar duplicates `BridgeAppBar`; structural inconsistency with rest of app.
3. **Issue 4** — Field vertical padding 12 missing; minor visual drift from Figma.
