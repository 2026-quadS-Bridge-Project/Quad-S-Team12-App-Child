# SafeArea + Scaffold Composition Audit (Child App)

**Date:** 2026-05-18
**Scope:** Diagnostic only — no code changes.
**Complaint:** Layout broken: status bar / notch overlap; back button rendering "at the very top".
**Reference pattern (parent app):** `Quad-S-Team12-App-Parent/lib/features/notifications/presentation/pages/notifications_page.dart`
- `Scaffold(body: SafeArea(child: Column[_NotificationsTopBar, ...]))`
- **Zero** `Scaffold.appBar:` usages anywhere in the parent app (`grep appBar: lib/` → no matches).
- The custom `_NotificationsTopBar` is a plain `SizedBox(height: 52)` inside the body, so the `SafeArea` above it owns the status-bar inset.

---

## Background: how Flutter handles top inset

| Pattern | Status-bar handling | Risk |
|---|---|---|
| `Scaffold(appBar: AppBarLike, body: SafeArea(child: X))` | Material `Scaffold` reserves `MediaQuery.padding.top` for the appBar; `SafeArea` inside body sees **`top=0`** because the appBar already consumed it. | **Safe IF** the widget given to `appBar:` actually accounts for `MediaQuery.padding.top` (Material's own `AppBar` does this in `_PreferredAppBarSize`). Custom widgets that only report `preferredSize: Size.fromHeight(52)` and do **not** add `MediaQuery.paddingOf(context).top` to their build will be **clipped under the notch** — they render flush against pixel 0. |
| `Scaffold(body: SafeArea(child: Column[TopBar, ...]))` | `SafeArea` injects `Padding(top: MediaQuery.padding.top)`; custom top bar sits below the status bar with no extra logic required. | **Safe by construction.** This is the parent app's choice. |
| `Scaffold(body: Column[TopBar, ...])` (no SafeArea) | Nothing reserves top inset. | **Always overlaps** notch/status bar. |
| `Stack` with `SafeArea(bottom:false)` deeper in the tree | Works only if the SafeArea actually wraps the visible top content; commonly broken when a `Positioned.fill` sibling renders above it. | Suspect — needs visual check. |

### Critical Flutter detail: `BridgeAppBar` is **NOT** a real `AppBar`

`lib/core/widgets/layout/bridge_app_bar.dart` lines 19, 45, 48-89:
```dart
class BridgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(AppTokens.topBarHeight); // 52
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: AppTokens.topBarHeight, ...); // 52 px, no top padding
  }
}
```

`Scaffold` reserves **exactly `preferredSize.height` (52 px)** for the appBar slot regardless of `MediaQuery.padding.top`. Material's stock `AppBar` solves this internally by reading `MediaQuery.paddingOf(context).top` and adding it to its own height during layout. `BridgeAppBar` does **not** do that. Therefore every page that uses `appBar: BridgeAppBar(...)` will render the 52-px bar starting at pixel `y=0`, with the status bar / notch drawn on top of the back chevron and the centered title.

This is the **root cause** of the user-reported "back button at the very top" symptom.

---

## Per-page audit

CoT format: **Observation → Root cause → Comparison → Fix recommendation**.

Status legend:
- **PASS** — composition is safe and matches parent app pattern.
- **FAIL** — confirmed status-bar / notch overlap based on the composition rules above.
- **SUSPECT** — uses a non-standard pattern that may overlap in some device classes (notched only).

| # | Page | Pattern | Status |
|---|---|---|---|
| 1 | `login/.../login_page.dart` | `Scaffold(body: SafeArea(... Column[BridgeAppBar, ...]))` | PASS |
| 2 | `signup/.../signup_page.dart` | `Scaffold(body: SafeArea(... Column[BridgeAppBar, ...]))` | PASS |
| 3 | `home/.../home_page.dart` | `Scaffold(body: SafeArea(...))` — no top bar | PASS |
| 4 | `child_home/.../child_home_page.dart` | `Scaffold(body: Stack[ Center → SafeArea(bottom:false) → content with `_TopBar` ])` | PASS |
| 5 | `my_page/.../my_page.dart` | `Scaffold(body: SafeArea(... Column[BridgeAppBar, ...]))` | PASS |
| 6 | `my_page/.../password_change_page.dart` | `Scaffold(body: SafeArea(... Column[_PasswordChangeTopBar(52), ...]))` (inlined custom top bar, not `BridgeAppBar`) | PASS |
| 7 | `my_page/.../delete_account_complete_page.dart` | `Scaffold(body: SafeArea(child: Center(...)))` — no top bar | PASS |
| 8 | `notifications/.../notifications_page.dart` | `Scaffold(body: SafeArea(... Column[_NotificationsTopBar(52), ...]))` — 1:1 with parent | PASS |
| 9 | `report/.../report_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(ListView))` | **FAIL** |
| 10 | `time_setup/.../time_setup_intro_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 11 | `time_setup/.../schedule_register_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 12 | `time_setup/.../weekly_time_setup_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 13 | `time_setup/.../daily_time_setup_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 14 | `time_setup/.../time_setup_review_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(top:false, ...))` | **FAIL** |
| 15 | `time_setup/.../time_setup_complete_page.dart` | `Scaffold(body: SafeArea(...))` — no top bar | PASS |
| 16 | `time_setup/.../time_setup_root_page.dart` | Shell only (no Scaffold) | N/A |
| 17 | `time_setup/.../time_setup_v2_root_page.dart` | Shell only (no Scaffold) | N/A |
| 18 | `time_confirm/.../time_confirm_page.dart` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 19 | `mission/.../mission_info_page.dart` — `_InfoView` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 19a | `mission_info_page.dart` — `_PerformView` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 19b | `mission_info_page.dart` — `_CameraPromptView` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 19c | `mission_info_page.dart` — `_PhotoPreviewView` | `Scaffold(appBar: BridgeAppBar(...), body: SafeArea(...))` | **FAIL** |
| 19d | `mission_info_page.dart` — `_SubmittedView` | `Scaffold(body: SafeArea(...))` — no top bar | PASS |

**Totals:** 11 FAIL · 9 PASS · 2 N/A.

---

## CoT analysis per FAIL page

### 9 — `report_page.dart` (line 42-45)
1. **Observation.** `Scaffold(backgroundColor: AppColors.background, appBar: const BridgeAppBar(title: '사용 리포트'), body: SafeArea(child: ListView(...)))`.
2. **Root cause.** `BridgeAppBar.preferredSize = Size.fromHeight(52)` and its `build` returns a flat `SizedBox(height: 52)`. `Scaffold` reserves only 52 px for the appBar slot, so the back chevron (`Positioned(left:14, top:0, bottom:0)` → centered vertically in the 52 px box) renders at roughly `y = 14..38` — directly under the status bar / notch on any device with `padding.top > 0` (iPhone 14: 47 px, Pixel 7: 42 px).
3. **Comparison.** Parent app's `notifications_page.dart` puts `_NotificationsTopBar` *inside* `SafeArea`, so it sits at `y = MediaQuery.padding.top`, well clear of the notch.
4. **Fix recommendation.** Either (a) **fix `BridgeAppBar` at the source** so its `preferredSize` and `build` both add `MediaQuery.paddingOf(context).top` (would fix every FAIL page in one change), or (b) refactor each page to `Scaffold(body: SafeArea(child: Column[BridgeAppBar(...), ...]))` and drop the `appBar:` slot. Option (a) is the minimal-diff fix that matches the user's mental model that "AppBar should handle the notch automatically".

### 10 — `time_setup_intro_page.dart` (line 34-37)
1. **Observation.** Same shape as #9.
2. **Root cause.** Same as #9.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9.

### 11 — `schedule_register_page.dart` (line 38-44)
1. **Observation.** `appBar: BridgeAppBar(...)` with `body: SafeArea(...)`. Note the body content starts with `Padding.fromLTRB(24, 16, 24, 0)` — the 16-px top assumes the 52-px appBar above is already clear of the status bar.
2. **Root cause.** Same as #9. Additionally, this page is a wizard step that the user lands on most often from the empty-state `+` button on the home — visibility is high.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9.

### 12 — `weekly_time_setup_page.dart` (line 40-47)
1. **Observation.** Same shape as #9.
2. **Root cause.** Same as #9.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9.

### 13 — `daily_time_setup_page.dart` (line 49-56)
1. **Observation.** Same shape as #9.
2. **Root cause.** Same as #9.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9.

### 14 — `time_setup_review_page.dart` (line 31-39)
1. **Observation.** `appBar: BridgeAppBar(...)` + `body: SafeArea(top: false, ...)`. The author **explicitly disabled the top SafeArea** in the body, which is the correct posture when paired with a real `AppBar` — but `BridgeAppBar` is not a real AppBar.
2. **Root cause.** Identical to #9, plus `top: false` removes the body-level fallback safety net.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9. If the global `BridgeAppBar` fix is adopted, this page's `SafeArea(top: false, ...)` becomes correct as-is.

### 18 — `time_confirm_page.dart` (line 79-82)
1. **Observation.** Same shape as #9.
2. **Root cause.** Same as #9.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9.

### 19 / 19a / 19b / 19c — `mission_info_page.dart` `_InfoView`, `_PerformView`, `_CameraPromptView`, `_PhotoPreviewView`
1. **Observation.** Four nested sub-Scaffolds (one per `MissionFlowStep`) each declare `appBar: BridgeAppBar(...)` + `body: SafeArea(...)`.
2. **Root cause.** Same as #9, multiplied across four sub-views inside a single feature.
3. **Comparison.** Same as #9.
4. **Fix recommendation.** Same as #9 — a fix at `BridgeAppBar` source resolves all four sub-views in one diff.

---

## PASS pages — why they're safe (sanity check)

- **#1 login, #2 signup, #5 my_page, #6 password_change, #8 notifications** all use the parent-app shape: `Scaffold(body: SafeArea(... Column[<TopBarWidget>, ...]))`. `SafeArea` injects the top inset *before* the top bar renders, so the back chevron lands at `y = MediaQuery.padding.top + (52/2 - 12) = padding.top + 14`. Note that #6 inlines its own `_PasswordChangeTopBar` instead of using `BridgeAppBar` — when used inside the body this works fine, but it's a **convention drift** that the next "PASS" page might forget to copy.
- **#3 home, #7 delete_account_complete, #15 time_setup_complete, #19d _SubmittedView** have no top bar at all; their content is centered/spaced and unaffected by the inset.
- **#4 child_home** is the most complex: `Stack` with `Center → ConstrainedBox → SafeArea(bottom: false) → SingleChildScrollView`. The first child of the scroll view is `SizedBox(height: 12)` then `_TopBar` (the `my` button + bell icon). The `SafeArea(bottom: false)` correctly injects the top inset, so the 12 px gap stacks **above** the top bar but **below** the status bar — visually correct.

---

## Top 3 inconsistencies

1. **`BridgeAppBar` declares `PreferredSizeWidget` but ignores the status-bar inset.** This single bug causes 11 of the audited pages to overlap the notch. The widget contract says: when supplied to `Scaffold.appBar:`, the widget *is* the chrome that owns the top inset. The parent app sidesteps this by never using `Scaffold.appBar:` at all — they always put the top bar inside the body's `SafeArea`. The child app *does* use `Scaffold.appBar:` (11 places) with a widget that lies about its preferred size.
2. **Two divergent top-bar conventions within the child codebase.** Pages 1/2/5/8 put `BridgeAppBar` inside `SafeArea` (works). Pages 9-14/18/19* put `BridgeAppBar` in `Scaffold.appBar:` (broken). Page 6 invents its own custom `_PasswordChangeTopBar` instead of reusing `BridgeAppBar`. There is no enforced rule; each agent picked whichever shape they saw first.
3. **`time_setup_review_page.dart` uses `SafeArea(top: false, ...)`** which is the correct posture *only when paired with a real `AppBar` that owns the inset*. Because `BridgeAppBar` doesn't own the inset, this page double-fails: no inset from the appBar and no inset from the SafeArea. It's the worst-case visual on this list.

---

## Recommended minimal fix (informational; do not apply per instructions)

Modify `lib/core/widgets/layout/bridge_app_bar.dart` so:
```
@override
Size get preferredSize {
  // Cannot read MediaQuery here (no context). Document that callers MUST
  // either (a) pass BridgeAppBar via Scaffold.appBar: AND wrap it in a
  // MediaQuery-aware sizer, or (b) embed it inside Scaffold.body's SafeArea.
}
```
Because `PreferredSizeWidget.preferredSize` is a context-less getter, the cleanest production fix is to **stop using `Scaffold.appBar:` for `BridgeAppBar`** and standardize all pages on the parent-app shape:
```
Scaffold(body: SafeArea(child: Column(children: [BridgeAppBar(...), ...])))
```
This converges the codebase on one rule, eliminates the 11 FAILs, and matches the parent app 1:1.
