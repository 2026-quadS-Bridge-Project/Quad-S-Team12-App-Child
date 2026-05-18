# Audit: BridgeAppBar layout

**Target file**: `lib/core/widgets/layout/bridge_app_bar.dart`
**User complaint** (KR): "뒤로가기 버튼이 최상단에 있다" — back button is sitting at the absolute top of the screen, visually overlapping or touching the iOS status bar / notch.
**Reference (parent app)**: `Quad-S-Team12-App-Parent/lib/features/notifications/presentation/pages/notifications_page.dart:291–335` (`_NotificationsTopBar`).
**Figma reference**: `cmp/topbar 325:17287` documented in `docs/figma-specs/03-mypage.md` (Y range 44–96, height 52, padding 22h/5v, back button at left=24, top=14 *relative to the 52h bar*, sitting **after** the 44px status bar region).

---

## Issue 1: AppBar height does not include status-bar inset

### Observation
- `bridge_app_bar.dart:45` declares `preferredSize => Size.fromHeight(AppTokens.topBarHeight)` where `topBarHeight = 52` (`app_tokens.dart:29`).
- `build()` returns a plain `SizedBox(height: 52, …)` with the back button vertically centered inside (line 49–88). There is no `SafeArea`, no `MediaQuery.padding.top` addition, and no `Material`/`AppBar` wrapper.
- This widget is wired into `Scaffold.appBar:` on at least **8** pages (see Issue 4 list).

### Root cause
Flutter's `Scaffold` uses `preferredSize.height` as the **total** vertical region reserved at the top of the body. When `appBar` is a `PreferredSizeWidget` that does **not** itself consume the status-bar inset, Scaffold paints the widget starting at `y=0` and the OS status bar (44 px on notched iPhones, ~24 px on Android) draws on top of — or shares space with — the back button. Because the back button is `Center`-aligned inside a 52 px box, it ends up at roughly `y = (52-24)/2 = 14` from the top of the screen, which is *inside* the notch/status-bar region on every notched device.

Flutter's built-in `AppBar` solves this by wrapping its contents in `SafeArea(top: true, bottom: false, …)` and expanding `preferredSize` by `MediaQuery.viewPadding.top`. `BridgeAppBar` does neither.

### Figma reference
`docs/figma-specs/03-mypage.md` rows 16–17 explicitly map:
- Y 0–44 → status bar (system-rendered)
- Y 44–96 → top bar (52 h), back button at `left=24, top=14` **relative to the 52-px bar**, i.e. absolute Y ≈ 58.

The parent app's `_NotificationsTopBar` is a `SizedBox(height: 52)` placed as the **first child of a `Column` inside `SafeArea`**, so the OS already insets the 44 px status bar before the bar is drawn. The `top: 14` Positioned inside that `SizedBox` therefore lands at absolute Y ≈ 58 — matching Figma.

In `BridgeAppBar`, the same 52-px box is placed by Scaffold **without** the SafeArea inset, so the back button lands at absolute Y ≈ 14 (inside the notch).

### Recommended fix
Two acceptable approaches (do not apply now):
1. **Make BridgeAppBar status-bar aware** (preferred — keeps the `appBar:` usage pattern working):
   - Read `final topInset = MediaQuery.of(context).padding.top;` in `build()`.
   - Set `preferredSize => Size.fromHeight(AppTokens.topBarHeight + topInset)` using an `_inset` field captured at construction *or* expose `preferredSize` via `PreferredSize` wrapper since `MediaQuery` is not available at `preferredSize` getter time. Cleanest pattern: have callers wrap with `PreferredSize(preferredSize: Size.fromHeight(52 + MediaQuery.paddingOf(context).top), child: BridgeAppBar(...))`, OR convert `BridgeAppBar` to internally use `SafeArea(top: true, bottom: false, child: SizedBox(height: 52, …))` and override `preferredSize` to `Size.fromHeight(52 + kToolbarStatusBarApprox)` — but the *correct* idiomatic fix is to add a `SafeArea(top: true, bottom: false)` wrapper **and** compute `preferredSize` from `MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).padding.top` (matches how `AppBar` does it).
2. **Drop `PreferredSizeWidget` and inline the bar inside `SafeArea > Column`** on every page (matches the parent app's `_NotificationsTopBar` pattern). Higher refactor cost but mirrors the working reference.

The currently-correct usages (`my_page.dart:94`, `login_page.dart:118`, `signup_page.dart:226`) already place `BridgeAppBar` inside `SafeArea > Column`, so they render correctly. The broken usages are the `appBar:` slot consumers.

---

## Issue 2: Inconsistent usage pattern (`appBar:` vs inline) produces inconsistent vertical placement

### Observation
Two distinct call patterns coexist:
- **Inline pattern** (works, matches parent's `_NotificationsTopBar`):
  - `lib/features/my_page/presentation/pages/my_page.dart:94` — inside `SafeArea > Column`
  - `lib/features/login/presentation/pages/login_page.dart:118` — inside `SafeArea > … > Column`
  - `lib/features/signup/presentation/pages/signup_page.dart:226` — inside `SafeArea > … > Column`
- **`Scaffold.appBar:` pattern** (broken on notched devices — bar sits behind status bar):
  - `lib/features/time_confirm/presentation/pages/time_confirm_page.dart:81`
  - `lib/features/mission/presentation/pages/mission_info_page.dart:87, 384, 455, 585`
  - `lib/features/time_setup/presentation/pages/time_setup_intro_page.dart:36`
  - `lib/features/time_setup/presentation/pages/time_setup_review_page.dart:33`
  - `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart:51`
  - `lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart:42`
  - `lib/features/time_setup/presentation/pages/schedule_register_page.dart:40`
  - `lib/features/report/presentation/pages/report_page.dart:44`

### Root cause
`BridgeAppBar` implements `PreferredSizeWidget`, signalling "I am safe to drop into `Scaffold.appBar`", but its build method does not behave like a Material `AppBar` (no SafeArea, no inset-aware height). Therefore the pattern that the type signature invites is exactly the one that fails on notched devices.

### Figma reference
`03-mypage.md` describes the bar as a 52-h component sitting *after* the 44-px status bar region (Y 44–96). Both call patterns must produce the same absolute Y 58 back-button center. Today only the inline pattern does.

### Recommended fix
After Issue 1 is resolved (status-bar-inset awareness), both patterns will work identically. Then standardize on one pattern across the codebase (recommend `Scaffold.appBar:` since that is the idiomatic Flutter slot for this widget and would let the `body:` SafeArea use `top: false`).

---

## Issue 3: Back-button vertical centering relies on the 52-px box, not the Figma `top:14`

### Observation
Lines 67–77 position the back button with `top: 0, bottom: 0` inside a `Center`. So its vertical anchor is `(52 - 24) / 2 = 14` — accidentally identical to the Figma `top: 14` spec, but only because the bar is exactly 52 high and the icon is 24×24.

### Root cause
Not a bug today, but it is a coupling trap: if `topBarHeight` (`app_tokens.dart:29`) ever changes (e.g., for tablet, or to accommodate the inset described in Issue 1 by *expanding* the SizedBox rather than wrapping in SafeArea), the back-button vertical position will drift away from the Figma `top: 14` anchor.

### Figma reference
`03-mypage.md` row 17: "Back button left (24×24 @ left=24, top=14)". Parent app `_NotificationsTopBar` explicitly hard-codes `Positioned(left: 0, top: 14, width: 24, height: 24, …)` — anchored from the top of the 52-h bar, not centered. (Note: parent uses `left: 0`, child uses `left: 14` via `_edgeInset`. Figma says `left: 24`. That is a separate horizontal-inset discrepancy worth confirming with design — left-edge of the *back-icon glyph* vs left-edge of the *hit-box*.)

### Recommended fix
- Explicitly anchor the back button with `Positioned(left: 14 /* or 24 per Figma */, top: 14, width: 24, height: 24, …)` instead of `top: 0, bottom: 0 + Center`. This decouples back-button placement from `topBarHeight`.
- Resolve the `left: 14` vs Figma `left: 24` discrepancy (child uses 14, parent uses 0 — neither matches Figma 24). The 22-px horizontal padding noted in `03-mypage.md` row 17 ("padding 22h/5v") plus a 2-px glyph inset would yield `left=24` for the glyph. Flag for design clarification.

---

## Issue 4: `PreferredSizeWidget` contract — `preferredSize` is `const`, cannot access `MediaQuery`

### Observation
Line 45: `Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);`. The getter has no `BuildContext` parameter, so it cannot read the device's status-bar inset.

### Root cause
This is a Flutter framework constraint, not a code defect. But it means that any fix for Issue 1 cannot simply "add `MediaQuery.of(context).padding.top` to `preferredSize`" — the `preferredSize` getter has no context. The framework's own `AppBar` works around this by exposing `preferredSize` as a *fixed* `kToolbarHeight` and then wrapping its `build()` output in `SafeArea`; Scaffold separately accounts for the inset via `MediaQueryData.removePadding` semantics around the body.

### Figma reference
N/A — framework constraint.

### Recommended fix
The correct pattern (mirroring `AppBar`):
```dart
// preferredSize stays a const value: the visible bar height only.
@override
Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight);

@override
Widget build(BuildContext context) {
  return SafeArea(
    top: true,
    bottom: false,
    child: SizedBox(
      height: AppTokens.topBarHeight,
      width: double.infinity,
      child: Stack(/* existing children */),
    ),
  );
}
```
However, **this alone is not sufficient** when used as `Scaffold.appBar:` because Scaffold expects `preferredSize` to represent the *total* slot it must reserve at the top — including the inset. With only a SafeArea wrap and `preferredSize=52`, Scaffold reserves 52 px, the SafeArea pushes the bar's contents down by 44 px (notch), and the bar overflows into the body region by 44 px (the body's top 44 px is hidden behind the bar).

The robust fix is to also override `preferredSize` to include the inset by reading `MediaQueryData.fromView(...).padding.top` at construction (the way `AppBar`'s internal `_PreferredAppBarSize` does it), or to wrap the widget in `PreferredSize` at every call site that uses `appBar:`. Cleanest: add a factory `BridgeAppBar.forScaffold(context, …)` that returns a `PreferredSize(preferredSize: Size.fromHeight(52 + MediaQuery.paddingOf(context).top), child: BridgeAppBar(...))`.

---

## Summary table

| # | Severity | Location | Issue |
|---|----------|----------|-------|
| 1 | High | `bridge_app_bar.dart:45,49–88` | No status-bar inset → back button sits under notch on notched devices |
| 2 | High | 9 call sites use `appBar:`, 3 use inline | Inconsistent usage; only inline pattern renders correctly today |
| 3 | Low | `bridge_app_bar.dart:67–77` | Back button vertical placement coupled to 52-px box rather than explicit Figma `top:14` |
| 4 | Info | `bridge_app_bar.dart:45` | `preferredSize` is context-free; any inset fix must follow `AppBar`'s pattern |

## Files reviewed

- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/layout/bridge_app_bar.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/theme/app_tokens.dart`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/03-mypage.md`
- `/Users/yeongj/Quad-S-Team12-App-Parent/lib/features/notifications/presentation/pages/notifications_page.dart` (reference `_NotificationsTopBar`, lines 291–335)
- All 12 BridgeAppBar call sites in `lib/features/**` (enumerated in Issue 2)
