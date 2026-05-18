# Audit Round 3 — Build Verification

Date: 2026-05-18
Scope: `flutter pub get`, `flutter analyze lib/`, `dart format` check, `flutter test --no-pub`
Working dir: `/Users/yeongj/Quad-S-Team12-App-Child`

## 1. `flutter pub get`

Status: SUCCESS

- Dependencies resolved (`Got dependencies!`).
- Informational: 14 packages have newer versions blocked by current constraints (non-blocking). Notables: `go_router 16.3.0 → 17.2.3`, `fl_chart 0.69.2 → 1.2.0`, `flutter_svg 2.2.4 → 2.3.0`, `dotted_border 2.1.0 → 3.1.0`. No action required for this audit round.

## 2. `flutter analyze lib/`

Status: CLEAN — 0 errors, 0 warnings.

- Output: `No issues found! (ran in 1.2s)`
- Nothing to list.

## 3. `dart format --output=none --set-exit-if-changed lib/`

Status: NEEDS FORMAT — 5 files require formatting (exit code 1).

Files needing format:
- `lib/features/mission/presentation/pages/mission_info_page.dart`
- `lib/features/report/presentation/pages/report_page.dart`
- `lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`
- `lib/features/time_setup/presentation/pages/schedule_register_page.dart`
- `lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`

Recommendation: run `dart format lib/` separately to apply formatting. Non-blocking for runtime, blocking for CI gates that enforce format.

## 4. `flutter test --no-pub`

Status: FAIL — 2 passed, 3 failed (out of 5).

Passing:
- `child start screen renders primary actions`
- `child home onboarding dismisses from any tap`

Failing (with root cause):

1. `cached login opens child home onboarding` — `test/widget_test.dart:37`
   - Expects `find.text('부모님 계정과 연결하기')` after cached login via `BridgeKApp` boot.
   - Found 0 widgets. The cached-login boot path is not surfacing the onboarding overlay text the test expects (overlay rendering vs. routing mismatch when entering `ChildHomePage` via `BridgeKApp` rather than directly).

2. `child my page renders account details and actions` — `test/widget_test.dart:72`
   - Expects literal strings `마이페이지`, `자녀회원`, `abcd00`, `자녀코드`, `XY785eZ`, `수정하기`, `로그아웃`, `탈퇴하기` in `MyPage`.
   - Found 0 widgets for `로그아웃`. Page content does not match these exact strings (likely refactored copy or rendered via a different widget tree).

3. `logout clears cached login and returns start screen` — `test/widget_test.dart:91`
   - `tester.tap(find.text('로그아웃'))` fails because the logout label is not present (same underlying cause as #2).

These look like test-vs-implementation drift in the `MyPage` and cached-login boot flow. The lib code analyzes clean, but the widget tests assert on copy/structure that no longer matches.

## Overall Verdict

NOT READY TO SHIP.

- `pub get` clean, `analyze` clean.
- 5 files violate formatter — easy fix via `dart format lib/`.
- 3/5 widget tests fail due to mismatch between test expectations and current `MyPage` / cached-login boot rendering. Either update the tests to match current UI copy/structure, or restore the expected widgets/text in `MyPage` and the post-cached-login onboarding overlay.

Action items before ship:
1. Run `dart format lib/`.
2. Reconcile `test/widget_test.dart` with current `MyPage` and `BridgeKApp` cached-login flow (do not skip/disable tests — fix the underlying drift).
3. Re-run `flutter analyze lib/` and `flutter test --no-pub` until both are green.
