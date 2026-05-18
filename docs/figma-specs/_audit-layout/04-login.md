# Login Page Audit (Diagnostic Only — No Fixes Applied)

**Target file**: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/login/presentation/pages/login_page.dart`
**Date**: 2026-05-18
**Auditor**: Quality Engineer (diagnostic-only pass)
**Spec status**: Out-of-Figma per user. Audit benchmarks against sibling pages (`signup_page.dart`, `password_change_page.dart`) for consistency.

---

## Scope of Checks

1. SafeArea / Scaffold composition (top bar vs status bar overlap)
2. `BridgeAppBar` placement (`Scaffold.appBar` vs inline body)
3. Back-button behavior (`context.go('/')` vs `context.pop()`)
4. Button wiring (`_submit`, validation toast, clear-icon affordances)
5. Field UX (focus behavior, error states, helper text severity)
6. `BridgeButton` variant correctness (primary/large/fullWidth)
7. Token discipline (stray hex / hardcoded colors)
8. Keyboard handling (`SingleChildScrollView`, overflow avoidance)

---

## Issue 1: Password field renders in plaintext (no `obscureText`)

**Severity**: HIGH (security + UX)

**Observation**
The `_LoginField` widget used for the 비밀번호 input (line 139–153) configures `keyboardType: TextInputType.visiblePassword` and `autocorrect: false`, but the underlying `TextField` (line 226) never sets `obscureText: true`. The password value typed by the user is therefore rendered as readable cleartext on screen. The same issue exists in `signup_page.dart` (`_SignupField` line 360), so this is a shared regression rather than a per-page deviation.

**Root cause**
`_LoginField` does not expose an `obscureText` parameter, and the inner `TextField` hard-codes only the visual-input properties (`cursorColor`, `style`, `decoration`). Because the parent constructor never threads obscure-text state into the child, password and non-password inputs share the same visible-text rendering path.

**Fix recommendation**
Add an `obscureText` (and optional `obscuringCharacter`) parameter to `_LoginField`, default it to `false`, and pass `obscureText: true` from the 비밀번호 field instantiation. Pair with `enableSuggestions: false` (already set) and consider `autofillHints: [AutofillHints.password]` for OS-level password manager integration. Apply the same fix in `_SignupField` for consistency.

---

## Issue 2: `BridgeAppBar` rendered inline inside scrollable body — not via `Scaffold.appBar`

**Severity**: MEDIUM (architectural inconsistency + keyboard regression risk)

**Observation**
`BridgeAppBar` (line 118) is placed as the first child of a `Column` that lives inside `SingleChildScrollView` → `IntrinsicHeight` → `Padding(horizontal: 24)`. The class itself implements `PreferredSizeWidget` (line 19 of `bridge_app_bar.dart`) and was clearly designed to be assigned to `Scaffold.appBar`. Two consequences:

a. **Scroll regression**: When the keyboard rises and `resizeToAvoidBottomInset` (default `true`) shrinks the body, the top bar scrolls upward with the content because it is *inside* the scroll view, not above it. The top bar can be pushed off-screen during keyboard interaction.

b. **Horizontal-padding contamination**: The 24px horizontal padding wrapping the `Column` is also applied to the `BridgeAppBar`, shifting its 14px back-button inset to an effective ~38px from the screen edge. This contradicts the spec contract documented in `bridge_app_bar.dart:40` (`_edgeInset = 14`).

c. The same anti-pattern is present in `signup_page.dart:226` and `password_change_page.dart:187` — so this is a project-wide convention, but it still violates the widget's stated contract.

**Root cause**
The page was authored to colocate the app bar with form content under a single `IntrinsicHeight + Spacer` layout (so the login button sticks to the bottom via `Spacer()`). To preserve that layout while moving the app bar to `Scaffold.appBar`, the author would have needed to refactor the body to use `Column + Expanded` rather than `IntrinsicHeight + Spacer`.

**Fix recommendation**
Move `BridgeAppBar` out of the scrollable body and assign it to `Scaffold(appBar: BridgeAppBar(...))`. Restructure the body to use `Column(children: [..., Spacer(), button])` inside an `Expanded`-wrapped scroll view, OR keep `IntrinsicHeight` but compute `minHeight = constraints.maxHeight - kToolbarHeightFromBar`. Apply consistently across `signup_page.dart` and `password_change_page.dart` to standardize the convention.

---

## Issue 3: `Spacer()` inside `SingleChildScrollView` + `IntrinsicHeight` is fragile under keyboard

**Severity**: MEDIUM (keyboard overflow risk on small devices)

**Observation**
Line 154 uses `Spacer()` between the password field and the toast/button. `Spacer` requires bounded vertical space, which `IntrinsicHeight` provides only because the outer `ConstrainedBox(minHeight: constraints.maxHeight)` (line 110) clamps the scroll content to viewport height. This works in the empty/no-keyboard case, but when the soft keyboard appears:

- If `resizeToAvoidBottomInset = true` (default), `constraints.maxHeight` shrinks. `Spacer` collapses, but if the combined intrinsic height of fields + toast + button exceeds the shrunk viewport, the user sees a RenderFlex / scroll-jank. The `SingleChildScrollView` softens this, but `IntrinsicHeight` re-measures children on every keyboard frame — performance smell.
- If a user types into the 아이디 field on a short device, the toast (which appears below the password field) may fall under the keyboard with no auto-scroll-to-field behavior (no `FocusNode`/`Scrollable.ensureVisible` wiring exists).

**Root cause**
The page uses a bottom-anchored button pattern (`Spacer` pushes the login button to the bottom) but combines it with `IntrinsicHeight` inside `SingleChildScrollView`. This is the canonical Flutter "fill viewport with intrinsic content" idiom, but it does not handle keyboard-induced focus-into-view automatically.

**Fix recommendation**
Either (a) replace the `Spacer` with a fixed `SizedBox` and let the scroll view handle keyboard overflow naturally, or (b) keep the bottom-anchored button but attach `FocusNode`s to both text fields and call `Scrollable.ensureVisible(focusedFieldContext)` on focus to guarantee the focused field stays visible above the keyboard. Confirm `Scaffold.resizeToAvoidBottomInset` is explicit (currently relying on default `true`).

---

## Issue 4: Back button bypasses `context.pop()` and force-navigates to `/`

**Severity**: LOW–MEDIUM (history-stack semantics)

**Observation**
Line 120: `onBack: () => context.go('/')`. The same pattern is used in `signup_page.dart:228`. `BridgeAppBar`'s default behavior (when `onBack` is omitted) is `context.pop()` (see `bridge_app_bar.dart:74`), which is the documented contract.

Using `context.go('/')` instead of `context.pop()`:
- Wipes the navigation stack and rebuilds the root route. If the user navigated `/ → /login → tap back`, the resulting `/` route triggers `HomePage._redirectCachedLogin` (line 37 of `home_page.dart`) even though the user explicitly chose to leave login.
- Breaks the Android system-back gesture vs. UI-back-button parity (system back uses `pop`, UI back uses `go` — inconsistent).
- Cannot be reused if `/login` is ever opened as a deep link or modal route from somewhere other than `/`.

**Root cause**
Likely defensive coding to handle the case where `/login` is opened directly via deep link (where `pop` would fail because the stack is empty). However, `go_router` handles this case via `canPop()` checks; manually forcing `go('/')` is over-engineered.

**Fix recommendation**
Remove the `onBack` override and let `BridgeAppBar` use its default `context.pop()`. If deep-link safety is required, change the default in `BridgeAppBar` itself to `context.canPop() ? context.pop() : context.go('/')`. Centralizes the policy and removes per-page divergence.

---

## Issue 5: No "clear" affordance on text fields — divergent from `password_change_page.dart`

**Severity**: LOW (UX consistency)

**Observation**
The sibling `password_change_page.dart` (line 199–204) provides an `onClear` callback that clears the field with a trailing icon. `signup_page.dart` provides a `_FieldCheck` validity indicator (line 392). `login_page.dart` provides **neither** — there is no way to clear the username or password field besides backspacing each character.

**Root cause**
`_LoginField` (line 182) was authored as a minimal field wrapper without the trailing slot that sibling fields support. There is no design-system component for "input with trailing slot"; each page reimplements the row pattern, leading to drift.

**Fix recommendation**
Extract a shared `BridgeTextField` widget in `core/widgets/inputs/` that supports `obscureText`, `trailing` (clear icon / check icon / custom), `helperText`, and `helperSeverity`. Replace `_LoginField`, `_SignupField`, and `_PasswordChangeField` with the shared component. For the immediate audit, add an optional clear icon to `_LoginField` to match `password_change_page` UX.

---

## Issue 6: Toast warning icon uses ad-hoc text-as-icon (`'!'` glyph) rather than SVG

**Severity**: LOW (visual fidelity)

**Observation**
`_LoginToastWarningIcon` (line 296–321) renders a red circle with a centered `'!'` text glyph using `AppTypography.captionBold.copyWith(fontSize: 12, height: 1, letterSpacing: 0)`. This relies on font metrics for the exclamation-mark glyph centering, which differs across platforms (iOS SF Pro vs. Android Roboto vs. fallback fonts) and produces inconsistent vertical alignment.

**Root cause**
No SVG icon asset was used; a text fallback was chosen for simplicity. The same icon pattern is duplicated in `_SignupToast` in `signup_page.dart` (line 470+ likely).

**Fix recommendation**
Replace with an SVG warning icon under `assets/icons/cmp/feedback/warning.svg` and use `SvgPicture.asset` for pixel-perfect rendering. If no SVG exists, use `Icon(Icons.priority_high, size: 12, color: AppColors.white)` for cross-platform consistency.

---

## Issue 7: Token discipline — all colors flow through `AppColors`; no stray hex detected

**Severity**: INFO (no action)

**Observation**
Every color reference in `login_page.dart` uses `AppColors.*` (`gray100`, `gray200`, `gray500`, `gray600`, `black`, `white`, `destructive`). No raw `Color(0xFF...)` or `Colors.red` usage. Typography flows through `AppTypography.bodyMedium`, `AppTypography.labelMedium`, `AppTypography.captionBold`.

**Root cause**
N/A — compliant.

**Fix recommendation**
None. However, two `copyWith` calls override `fontSize`, `height`, and `letterSpacing` on `AppTypography.bodyMedium` (lines 208–213, 235–240) and `labelMedium` (lines 282–287). If these specific metrics recur (they appear in `signup_page.dart` and `password_change_page.dart` too), promote them to named styles in `AppTypography` (e.g., `inputLabel`, `inputText`, `toastText`) to eliminate `copyWith` boilerplate.

---

## Issue 8: `BridgeButton` variant — correctly set to primary/large/fullWidth

**Severity**: INFO (no action)

**Observation**
Line 159–165: `BridgeButton(label: '로그인', variant: BridgeButtonVariant.primary, size: BridgeButtonSize.large, fullWidth: true, onPressed: _canSubmit ? _submit : null)`. This matches `signup_page.dart:286` exactly. Disabled state correctly driven by `_canSubmit` getter (line 31: `_username.isNotEmpty && _password.isNotEmpty`).

**Root cause**
N/A — compliant.

**Fix recommendation**
None.

---

## Issue 9: No `SystemUiOverlayStyle` annotation — status bar icon color undefined

**Severity**: LOW (visual polish)

**Observation**
`home_page.dart:51` wraps its `Scaffold` in `AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, ...)` to force dark status-bar icons over the light `gray050` background. `login_page.dart` uses `AppColors.gray100` (same light background) but does **not** declare a `SystemUiOverlayStyle`. The status-bar icon color is therefore inherited from whichever screen was previously active — typically `HomePage`, so the visual result is usually correct by accident, but the dependency is implicit and breaks if `/login` is opened from a dark-background route.

**Root cause**
Missing per-page overlay declaration. Inconsistent with `HomePage` precedent.

**Fix recommendation**
Wrap the `Scaffold` in `AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: Scaffold(...))` to match `HomePage`. Or, better, set a global `SystemUiOverlayStyle` at app boot in `lib/app/app.dart` so every screen inherits a consistent default.

---

## Issue 10: Mock credentials hardcoded in widget state — leaks into production binary

**Severity**: HIGH (security / release-readiness — outside layout scope but flagged)

**Observation**
Lines 21–22: `static const Set<String> _mockUsernames = {'gdg12', 'abcd00'}; static const String _mockPassword = 'Gdg123456789!';`. These constants are baked into the release binary. Any user who reverse-engineers the APK/IPA will see them. The same pattern exists in `signup_page.dart:35` (`_takenUsernames`).

**Root cause**
Stub implementation pending real auth API wiring (acknowledged by code comment in `signup_page.dart:34`: "Temporary duplicate-check stub until API wiring is added"). No such comment exists in `login_page.dart`.

**Fix recommendation**
Out of scope for layout audit, but flagged: (a) add a `// TODO(auth)` comment marking this as a stub, (b) gate the mock branch behind `kDebugMode` so release builds throw "auth not configured", (c) replace with real auth service call before any external release. Layout-wise this does not affect rendering.

---

## Summary Table

| # | Issue | Severity | Layout-Relevant |
|---|---|---|---|
| 1 | Password field renders plaintext (no `obscureText`) | HIGH | Yes |
| 2 | `BridgeAppBar` inside scroll body, not `Scaffold.appBar` | MEDIUM | Yes |
| 3 | `Spacer` + `IntrinsicHeight` fragile under keyboard | MEDIUM | Yes |
| 4 | Back button overrides default `pop` with `go('/')` | LOW-MED | Behavior |
| 5 | No clear-icon affordance on fields | LOW | Yes |
| 6 | Toast warning icon uses text glyph instead of SVG | LOW | Yes |
| 7 | Token discipline: clean | INFO | Yes |
| 8 | `BridgeButton` variant: correct | INFO | Yes |
| 9 | Missing `SystemUiOverlayStyle` annotation | LOW | Yes |
| 10 | Mock credentials in source | HIGH | No |

## Cross-Cutting Recommendation

Issues 1, 2, 5, and 6 all stem from the absence of a shared `BridgeTextField` and `BridgeToast` widget in `core/widgets/`. Each form page (`login`, `signup`, `password_change`) reimplements the field + toast pattern with slight drift. Promoting these to design-system components would resolve four of the ten findings simultaneously and unblock future form pages from repeating the same drift.
