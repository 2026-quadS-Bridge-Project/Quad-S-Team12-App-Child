# Signup Page — Layout & Behavior Audit

**Target file**: `lib/features/signup/presentation/pages/signup_page.dart`
**Figma**: out-of-figma per user. Consistency baseline = sibling `lib/features/login/presentation/pages/login_page.dart` and shared widgets (`BridgeAppBar`, `BridgeButton`).
**Audit date**: 2026-05-18
**Audit type**: Diagnostic only — DO NOT FIX.

Each issue follows Chain-of-Thought: Observation -> Root cause -> Fix recommendation.

---

## Issue 1 — Post-signup navigation lands on `/` instead of `/login` or `/child-home`

**Observation**
`signup_page.dart:194` — on successful submit, `_submit()` calls `context.go('/')`, returning the user to `HomePage` (the marketing/entry screen with "자녀 회원가입" / "로그인" buttons). In contrast, `login_page.dart:87` saves an `AuthSession` and navigates to `/child-home`. Signup neither calls `AuthSession.saveLogin(...)` nor advances the user — they must re-enter their just-created credentials manually on `/login`.

**Root cause**
The submit handler has no API integration (stub `_takenUsernames` set on line 35) and no decision was made about post-creation flow. The fallback `context.go('/')` was likely a placeholder. There is no checkpoint between "account created" and "user lands somewhere useful", and the `AuthSession` API exists but is unused here.

**Fix recommendation**
Pick one of two consistent flows and document it:
- **Option A (auto-login)**: after stub success, call `await AuthSession.saveLogin(username: _username)` then `context.go('/child-home')`. Mirrors `login_page.dart` exactly and reduces user friction.
- **Option B (login handoff)**: `context.go('/login')` with the just-created username prefilled via `extra` or query param.
Avoid `context.go('/')` — it sends the user back to the marketing entry, which is regressive. Whichever option is chosen, add an inline `// TODO(api)` comment scoped to the stubbed branch so the placeholder is auditable.

---

## Issue 2 — `BridgeAppBar` rendered inline inside `Column` instead of via `Scaffold.appBar`

**Observation**
`signup_page.dart:226` mounts `BridgeAppBar` as the first child of the scrollable `Column`, identical to `login_page.dart:118`. `BridgeAppBar` implements `PreferredSizeWidget` (`bridge_app_bar.dart:19`) and is explicitly documented as the "Standard top bar used across mypage, password_change, mission info, time settings, and similar secondary screens" with a fixed `AppTokens.topBarHeight`. Other secondary screens (e.g., `schedule_register_page.dart`) presumably consume it via `Scaffold.appBar` — that is the intended slot for a `PreferredSizeWidget`.

**Root cause**
The screen wraps the entire body (app bar + form + button) in a single `SingleChildScrollView` + `IntrinsicHeight` + `Spacer()` pattern so the submit button can pin to the bottom of the viewport while still scrolling on small screens. Putting `BridgeAppBar` into `Scaffold.appBar` would break the `Spacer` math because the body's `maxHeight` would shrink by 52px, and the team likely chose inline mounting to keep the layout calculation simple. The cost: inconsistency with other secondary screens, no system status-bar handling from `Scaffold`, and `BridgeAppBar.preferredSize` is unused.

**Fix recommendation**
Two acceptable directions:
- **Preferred**: lift `BridgeAppBar` into `Scaffold(appBar: BridgeAppBar(...))` and let the body fill the remaining space. Recompute the `Spacer`/`IntrinsicHeight` chain against the post-appBar `constraints.maxHeight`. This aligns with the widget's documented contract.
- **Acceptable (status quo)**: leave inline but add a code comment in both `signup_page.dart` and `login_page.dart` explaining the deliberate deviation, and remove the unused `PreferredSizeWidget` cost from mental model. Choose one direction project-wide; the current mix is the real defect.

---

## Issue 3 — Back button uses `context.go('/')` instead of `context.pop()`, breaks navigation stack

**Observation**
`signup_page.dart:228` — `BridgeAppBar(... onBack: () => context.go('/'))`. The user reaches `/signup` via `context.push('/signup')` from `home_page.dart:131`, which adds it to the navigation stack. `BridgeAppBar`'s default `onBack` is already `() => context.pop()` (`bridge_app_bar.dart:74`), which would correctly pop back to the previous route.

**Root cause**
Likely copy-paste from `login_page.dart:120`, which has the same anti-pattern. Both screens hard-code `/` to guarantee landing on `HomePage`, but this assumes a single entry point. In a deep-link or nested-router scenario (e.g., user arrives at signup from an email link or from `/login` via a future "회원가입" CTA), `context.go('/')` will wipe the stack and disorient the user.

**Fix recommendation**
Delete the `onBack` override entirely and rely on the widget default (`context.pop()`). If `pop()` cannot pop (e.g., signup is the root of the stack), `go_router` exposes `context.canPop()` — gate the fallback explicitly:
```
onBack: () => context.canPop() ? context.pop() : context.go('/'),
```
Apply the same fix to `login_page.dart` for consistency.

---

## Issue 4 — Three-field validation: `_FieldCheck` shown on username and confirm, but never on password

**Observation**
`signup_page.dart:254` — the password field is hard-coded to `checkState: _CheckState.hidden`, so the green check never appears for a valid password in isolation. The check only appears on the password-confirm field (line 271) when both `_isPasswordValid && _isPasswordMatched`. Meanwhile the username field shows a check the moment format passes and no duplicate is detected (line 120-125).

**Root cause**
The design intent appears to be: "username has its own validity, password's validity is implicit in the match check on the confirm field." But `_passwordConfirmCheckState` (line 127) requires `_isPasswordValid && _isPasswordMatched` — so if the user types a valid password and a matching confirm, the check appears on the confirm field; if they type an invalid password that matches its own confirm, no check appears anywhere. This conflates two signals (password strength + match) into a single indicator on the confirm field, which is ambiguous UX.

**Fix recommendation**
Decide the contract per field and apply it explicitly:
- **Option A**: show the check on the password field when `_isPasswordValid`, and on the confirm field when `_isPasswordMatched` only. Two independent indicators map to two independent rules.
- **Option B (current intent, made explicit)**: keep confirm-only check, but rename it from a generic checkmark to a "match" affordance (e.g., link icon) and add a tooltip/inline note. Document why password has no check.
Either way, remove the hidden-state hack on line 254 and replace with a deliberate per-field decision.

---

## Issue 5 — `_FieldCheck.inactive` renders a gray check (false-positive affordance)

**Observation**
`signup_page.dart:425-427` — when `state == _CheckState.inactive`, the icon still paints `Icons.check_rounded` at full opacity but in `AppColors.gray200`. A user types one character into the username field — a gray check immediately appears in the field's trailing slot. Users typically read "checkmark = success" regardless of color saturation; gray-200 on a white-ish background is faint but unmistakably check-shaped.

**Root cause**
The three-state enum (`hidden | inactive | active`) was likely introduced to reserve the trailing slot width so the layout doesn't jump when validity flips. But "reserve space" and "show a gray check" are conflated — the icon is painted for the inactive state instead of being `Opacity(0)` or `Visibility(maintainSize: true, visible: false)`.

**Fix recommendation**
For `_CheckState.inactive`, render an invisible placeholder of the same `SizedBox(width: 30, height: 30)` (no `Icon`), or wrap the icon in `Visibility(maintainSize: true, maintainAnimation: true, maintainState: true, visible: state == _CheckState.active)`. This preserves layout stability without signalling false success. The `_CheckState.hidden` branch (used for the password field) already does the right thing via the `if (checkState != _CheckState.hidden)` guard at line 390 — extend the same logic so `inactive` either reserves an empty box or is removed entirely in favour of a two-state visible/hidden model.

---

## Issue 6 — `BridgeButton` enabled/disabled state is correct, but `_canSubmit` ignores duplicate-after-typing race

**Observation**
`signup_page.dart:68-73` — `_canSubmit` returns true iff all fields are filled, username is format-valid AND not duplicate, password is format-valid, passwords match. The button is correctly disabled when any condition fails (line 291). However, the duplicate check (`_isUsernameDuplicate`) is synchronous against a hard-coded `_takenUsernames` set (line 35). When the real API is wired, this gate will need to become async, and the current synchronous `_canSubmit` will become stale between keystrokes.

**Root cause**
The MVP stubs duplicate-check as a `Set` lookup, which is O(1) and synchronous, so `_canSubmit` works today. The submit handler also re-checks duplicate at line 170, so there is a defensive second layer. But there is no debounce, no loading state on the button, and no "checking..." indicator near the field. When this becomes a network call, the button enabled-state will lie momentarily.

**Fix recommendation**
For the current stubbed state, the logic is correct — no fix needed. Document for the API-wiring phase:
- Add a `_DuplicateCheckState { idle, checking, available, taken }` and reflect "checking" on the field + disable the button while in-flight.
- Debounce the username check (e.g., 400ms after last keystroke).
- Keep the submit-time re-check as a server-authoritative safety net.

---

## Issue 7 — Toast widget duplicated across signup and login (`_SignupToast` ≡ `_LoginToast`)

**Observation**
`signup_page.dart:438-498` defines `_SignupToast` and `_ToastWarningIcon`. `login_page.dart:261-321` defines `_LoginToast` and `_LoginToastWarningIcon`. The two are byte-identical except for class names: same `AppColors.gray500` bg, same `BorderRadius.circular(8)`, same 16x10 padding, same red circular `!` icon, same typography. Also: the toast has no dismiss affordance — it disappears only when the underlying error state clears via `_onXChanged` handlers.

**Root cause**
Copy-paste duplication. There is no shared `BridgeToast` or `BridgeInlineError` widget in `lib/core/widgets/`, so each screen redefines it.

**Fix recommendation**
Extract a shared widget — proposed path: `lib/core/widgets/feedback/bridge_inline_toast.dart` exposing `BridgeInlineToast({required String message, IconData? leadingIcon})`. Replace both `_SignupToast` and `_LoginToast` with the shared widget. On UX: confirm with design whether the toast needs an explicit dismiss (X) button — currently it auto-dismisses on input, which is acceptable for inline form feedback but unusual for the toast terminology. Consider renaming to `InlineError` or `FormBanner` to match its actual behavior (persistent, contextual, auto-clearing on edit).

---

## Issue 8 — Token discipline: typography literals duplicate the typography presets

**Observation**
`signup_page.dart:339-343, 369-373, 401-407, 459-464, 488-491` — every `Text` style does `AppTypography.<preset>.copyWith(fontSize: X, height: Y, letterSpacing: Z, color: ...)`. The `copyWith` overrides three of the four properties of the preset, which suggests either (a) the preset doesn't match the design and is being patched per-call, or (b) the preset matches and the explicit numbers are redundant defensive copies. Either way, the literals (`16`, `1.5`, `0.0912`, `0.203`, etc.) are scattered with no token names. No raw hex `0xFF...` literals were found — colors all route through `AppColors.*` (`gray100/200/500/600`, `destructive`, `black`, `white`, `primary`). That part of the token discipline is clean.

**Root cause**
Typography presets in `AppTypography` likely use design tokens (font family, weight) but not the per-screen size/height/letterSpacing tuples. The signup screen captures Figma-derived values inline because there is no `AppTypography.fieldLabel`, `AppTypography.fieldInput`, `AppTypography.fieldHelper`, etc. to target.

**Fix recommendation**
Either:
- **Strengthen presets**: audit `AppTypography` and either fix the presets so `copyWith` is unnecessary, or add screen-class presets like `AppTypography.formLabel16`, `AppTypography.formHelper12`, `AppTypography.toastLabel14`.
- **Document the tuples**: if Figma genuinely demands per-screen numbers, extract them into a private constant block at the top of the file (`static const double _labelLetterSpacing = 0.0912;`) so the magic numbers are named and reviewable.
No hex literals to fix on the color side.

---

## Issue 9 — Keyboard scrolling: `SingleChildScrollView` + `Spacer` + `IntrinsicHeight` may not handle keyboard inset

**Observation**
`signup_page.dart:207-305` — body is `SafeArea > LayoutBuilder > Center > ConstrainedBox(maxWidth: 375) > SingleChildScrollView > ConstrainedBox(minHeight: constraints.maxHeight) > IntrinsicHeight > Padding > Column[..., Spacer(), button]`. The `Scaffold` does not set `resizeToAvoidBottomInset` (no matches project-wide via grep), so it defaults to `true`. When the keyboard opens for the password-confirm field (bottom-most), the viewport shrinks; `LayoutBuilder`'s `constraints.maxHeight` reflects the shrunk height, `IntrinsicHeight` forces the column to fit, and `Spacer()` collapses. The submit button gets pushed up against the helper text, potentially overlapping the keyboard or becoming non-tappable on small phones.

**Root cause**
The combination of `IntrinsicHeight` + `Spacer()` is fundamentally at odds with a shrinking viewport: `Spacer` only adds positive space, never negative, so when content > viewport the column overflows. `SingleChildScrollView` allows scroll but the user has to scroll manually past the keyboard to reach the button. Additionally, there is no `Scrollable.ensureVisible` or `TextField.scrollPadding` tuning, so a focused field may sit directly behind the keyboard.

**Fix recommendation**
Two-part fix:
1. Replace `Spacer()` with a layout that tolerates keyboard inset — either remove `IntrinsicHeight` and use a fixed `SizedBox` + bottom-anchored button via `Stack`, or wrap the button block in `SafeArea(minimum: EdgeInsets.only(bottom: 24))` outside the scrollable area.
2. Add `scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24)` on each `TextField` to guarantee the focused field is scrolled above the keyboard.
Validate manually on a small device (iPhone SE size, 320x568 logical) with each field focused.

---

## Issue 10 — Helper text color hard-codes destructive red even for non-error helper messages

**Observation**
`signup_page.dart:397-410` — when `helperText != null`, the text is always painted in `AppColors.destructive`. The `helperText` value comes from `_usernameInlineMessage` / `_passwordInlineMessage` / `_passwordConfirmInlineMessage`, all of which return either `null` (when valid/empty) or a Korean validation rule string (when invalid). Today, every non-null helper IS an error, so the color happens to be correct.

**Root cause**
The "helper" abstraction is misnamed — it is actually an "error message" slot. The widget signature `helperText: String?` suggests reusability for neutral hints (e.g., "영문 소문자 + 숫자 6~12자"), but the implementation forecloses that by hard-coding the destructive color.

**Fix recommendation**
Two paths:
- **Rename for clarity**: change the parameter to `errorMessage: String?` so the contract matches reality, and the destructive color is semantically correct.
- **Generalize for reuse**: add `helperColor: Color` parameter (default `AppColors.destructive` to preserve current behavior) so future neutral-hint use cases don't require a rewrite.
Low-priority — current usage is correct; this is a naming/extensibility concern, not a defect.

---

## Summary

| # | Issue | Severity | Effort |
|---|---|---|---|
| 1 | Post-signup `context.go('/')` — wrong landing | High | S |
| 2 | `BridgeAppBar` inline vs `Scaffold.appBar` mismatch | Medium | M |
| 3 | Back button hard-codes `/` instead of `pop()` | Medium | S |
| 4 | Password field never shows check; confirm conflates two signals | Medium | M |
| 5 | `_FieldCheck.inactive` paints a gray check (false affordance) | Medium | S |
| 6 | `_canSubmit` correct for stub; needs async story for API | Low (now) | M (later) |
| 7 | `_SignupToast` duplicates `_LoginToast` — extract to core widget | Low | S |
| 8 | Typography `copyWith` floods + magic numbers; colors are clean | Low | M |
| 9 | Keyboard scroll: `Spacer` + `IntrinsicHeight` + soft keyboard fragile | Medium | M |
| 10 | Helper slot hard-codes destructive color, misnamed | Low | S |

**Top 3 priorities**: Issue 1 (broken success flow), Issue 3 (back button stack corruption), Issue 9 (keyboard-occluded submit on small devices).

**Out of scope (per Figma absence)**: pixel-level spacing/typography verification against a design source. Consistency check against `login_page.dart` was used as the de-facto contract.
