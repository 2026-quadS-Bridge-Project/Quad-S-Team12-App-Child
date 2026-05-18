# Audit Round 3 — BridgeAppBar Status-Bar Inset Fix

**Date**: 2026-05-18
**Scope**: Verify Round 1 fix to `lib/core/widgets/layout/bridge_app_bar.dart` resolves the back-button-under-notch issue and does not regress inline-pattern pages.

## Round 1 Fix (verified in source)

`/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/layout/bridge_app_bar.dart`

| Element | Status | Evidence |
|---|---|---|
| `preferredSize` includes `_topInset` | PASS | line 67: `Size.fromHeight(AppTokens.topBarHeight + _topInset)` |
| `_topInset` reads platform view padding | PASS | lines 58–64: `WidgetsBinding.instance.platformDispatcher.views.first.padding.top / devicePixelRatio` (context-free, valid for PreferredSizeWidget) |
| `build()` pads by `MediaQuery.paddingOf(context).top` | PASS | lines 71–73: `Padding(padding: EdgeInsets.only(top: topInset), child: SizedBox(height: AppTokens.topBarHeight, …))` |
| Inner content height unchanged at 52 | PASS | line 75: `SizedBox(height: AppTokens.topBarHeight)` |

**Behavior**: When used via `Scaffold.appBar:`, the Scaffold consumes the top inset from the body's MediaQuery and forwards it to the AppBar — so `MediaQuery.paddingOf(context).top` inside `build()` is the real status-bar inset, and the `Padding(top: topInset)` pushes the 52px bar down below the notch. No double-pad.

## 11 Scaffold.appBar Pages (Round 1 target)

All use the canonical `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` pattern.

| # | Page | File | appBar line | body SafeArea | Status |
|---|---|---|---|---|---|
| 1 | report | `lib/features/report/presentation/pages/report_page.dart` | 43 | 44 | PASS |
| 2 | time_setup_intro | `lib/features/time_setup/presentation/pages/time_setup_intro_page.dart` | 38 | 39 | PASS |
| 3 | schedule_register | `lib/features/time_setup/presentation/pages/schedule_register_page.dart` | 40 | 51 | PASS |
| 4 | weekly_time_setup | `lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart` | 42 | 46 | PASS |
| 5 | daily_time_setup | `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart` | 52 | 56 | PASS (2nd SafeArea at line 233 is inside `showModalBottomSheet`, unrelated) |
| 6 | time_setup_review | `lib/features/time_setup/presentation/pages/time_setup_review_page.dart` | 33 | 37 | PASS |
| 7 | time_confirm | `lib/features/time_confirm/presentation/pages/time_confirm_page.dart` | 82 | 83 | PASS |
| 8 | mission_info (intro view) | `lib/features/mission/presentation/pages/mission_info_page.dart` | 90 | 91 | PASS |
| 9 | mission_info (view 2) | same | 453 | 457 | PASS |
| 10 | mission_info (view 3) | same | 596 | 600 | PASS |
| 11 | mission_info (view 4 — `showBack:false`) | same | 706 | 707 | PASS |

### Why `body: SafeArea(top:true)` does NOT double-pad

When `Scaffold.appBar` is non-null, Flutter's Scaffold removes the top padding from the MediaQuery it provides to the body. The SafeArea inside the body therefore sees `top: 0` and adds nothing. This is the standard Flutter idiom. Confirmed safe in all 11 cases.

### ConstrainedBox(maxWidth: 375) interaction

None of the 11 Scaffold.appBar pages place the BridgeAppBar inside a `ConstrainedBox(maxWidth: 375)`. The appBar spans the full Scaffold width as expected. No interaction issue.

## 5 Inline-Pattern Pages (regression check)

These wrap `BridgeAppBar` inside `SafeArea > Column` as a body child (NOT via `Scaffold.appBar`). The concern: SafeArea consumes the top inset, so `MediaQuery.paddingOf(context).top` returns 0 inside BridgeAppBar — meaning the Round 1 `Padding(top: topInset)` adds nothing. Net: no change, no double-pad, no regression.

| # | Page | File | Pattern | Status |
|---|---|---|---|---|
| 1 | my_page | `lib/features/my_page/presentation/pages/my_page.dart` | `Scaffold > body: SafeArea > Align > ConstrainedBox(375) > Column[BridgeAppBar(L89), ...]` | NO REGRESSION |
| 2 | login | `lib/features/login/presentation/pages/login_page.dart` | `Scaffold > body: SafeArea > LayoutBuilder > Center > ConstrainedBox(375) > … > Column[BridgeAppBar(L118), ...]` | NO REGRESSION |
| 3 | signup | `lib/features/signup/presentation/pages/signup_page.dart` | `Scaffold > body: SafeArea > … > Column[BridgeAppBar(L231), ...]` | NO REGRESSION |
| 4 | password_change | `lib/features/my_page/presentation/pages/password_change_page.dart` | `Scaffold > body: SafeArea > … > Column[BridgeAppBar(L176), ...]` (separate `bottomNavigationBar: SafeArea` at L247 is unrelated) | NO REGRESSION |
| 5 | notifications | `lib/features/notifications/presentation/pages/notifications_page.dart` | Uses custom `_NotificationsTopBar` (L110, defined L298), NOT BridgeAppBar | N/A — not affected |

### Regression analysis (inline pattern)

- `SafeArea` (top:true) consumes status-bar inset and removes it from the MediaQuery it provides to descendants.
- Inside BridgeAppBar.build(): `MediaQuery.paddingOf(context).top` returns `0`.
- `Padding(padding: EdgeInsets.only(top: 0), child: SizedBox(height: 52))` → renders as plain 52px bar, identical to pre-fix behavior.
- `preferredSize` is unused because BridgeAppBar is rendered as a Column child, not via `Scaffold.appBar`.

**Conclusion**: Round 1 fix is opaque to inline-pattern pages. SafeArea-provided inset already pushes the bar below the notch. No double-pad, no visual change.

## Summary

- 11 / 11 Scaffold.appBar pages: PASS
- 4 / 4 inline-pattern BridgeAppBar pages: NO REGRESSION
- 1 / 1 custom topbar page (notifications): N/A
- Round 1 fix correctly handles both rendering contexts.
