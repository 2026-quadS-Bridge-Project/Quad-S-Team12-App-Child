# Round 3 Routing Audit — Post Round 1+2 Fixes

**Date**: 2026-05-18
**Scope**: Verify routing graph + entry/exit flow integrity. **Diagnose only — no fixes applied.**
**Source of truth**: `lib/app/router/app_router.dart`

---

## 1. Routing Graph (declared routes)

| # | Path | Builder | Nav key |
|---|---|---|---|
| 1 | `/` | `HomePage` | (default) |
| 2 | `/login` | `LoginPage` | (default) |
| 3 | `/signup` | `SignupPage` | (default) |
| 4 | `/mypage` | `MyPage` | root |
| 5 | `/mypage/password` | `PasswordChangePage` | root |
| 6 | `/mypage/delete-complete` | `DeleteAccountCompletePage` | root |
| 7 | `/child-home` | `ChildHomePage()` | root |
| 8 | `/child-home/onboarding` | `ChildHomePage(showOnboarding:true, showContent:false)` | root |
| 9 | `/child-home/report` | `ReportPage` | root |
| 10 | `/child-home/notifications` | `NotificationsPage` | root |
| 11 | `/child-home/time-setup` | `TimeSetupRootPage` (v1 wizard shell) | root |
| 12 | `/child-home/time-setup/v2` | `TimeSetupV2RootPage` | root |
| 13 | `/child-home/time-setup/confirm` | `TimeConfirmPage` | root |
| 14 | `/child-home/mission/:id` | `MissionInfoPage` | root |

Total: **14 routes**, all top-level (no ShellRoute). All non-auth screens nailed to `_rootNavigatorKey`.

---

## 2. Dead-Nav Sweep — `context.(go|push|pop|replace)` across `lib/features/`

All targets resolved against routing table above.

| Caller | Call | Target route | Resolves? |
|---|---|---|---|
| `home_page.dart:53` | `go('/child-home')` | #7 | PASS |
| `home_page.dart:150` | `push('/signup')` | #3 | PASS |
| `home_page.dart:168` | `push('/login')` | #2 | PASS |
| `login_page.dart:87` | `go('/child-home')` | #7 | PASS |
| `login_page.dart:120` | `pop()` (BridgeAppBar back) | implicit | PASS |
| `signup_page.dart:199` | `go('/child-home')` (after `AuthSession.saveLogin`) | #7 | PASS |
| `signup_page.dart:233` | `pop()` | implicit | PASS |
| `child_home_page.dart:190` | `push('/child-home/notifications')` (bell) | #10 | PASS |
| `child_home_page.dart:227` | `push('/mypage')` (my button) | #4 | PASS |
| `child_home_page.dart:321` | `push('/child-home/report')` (bar_chart icon) | #9 | PASS |
| `child_home_page.dart:347` | `push('/child-home/time-setup/confirm')` (gear) | #13 | PASS |
| `child_home_page.dart:428` | `push('/child-home/time-setup')` (+ button) | #11 | PASS |
| `child_home_page.dart:818` | `push('/child-home/mission/${id}')` | #14 | PASS |
| `notifications_page.dart:45` | `push(route)` from `_defaultRouteFor` / `item.deeplink` | #7 or #13 | PASS (mock data only) |
| `notifications_page.dart:71,110,238` | `pop()` (delete dialog, top-bar back, cancel) | implicit | PASS |
| `mypage.dart:213,221` | `pop()` (logout / delete dialogs) | implicit | PASS |
| `mypage.dart:334` | `push('/mypage/password')` | #5 | PASS |
| `password_change_page.dart:149,176` | `pop()` (success + topbar back) | implicit | PASS |
| `delete_account_complete_page.dart:29` | `go('/')` | #1 | PASS |
| `report_page.dart:66` | `push('/child-home/time-setup/v2')` | #12 | PASS |
| `time_confirm_page.dart:89,93` | `pop()` (close + confirm) | implicit | PASS |
| `time_setup_complete_page.dart:82` | `go('/child-home')` | #7 | PASS |
| `schedule_register_page.dart:49` | `pop()` (BridgeAppBar back, exits wizard) | implicit | PASS |
| `mission_info_page.dart:752` | `go('/child-home')` (홈으로) | #7 | PASS |

**Dead nav count: 0.** Every `go`/`push` target maps to a declared route.

---

## 3. User Flow Traces

### Flow A — App start `/` → cached login → `/child-home`
- `HomePage.initState` → `_redirectCachedLogin()` → if `AuthSession.isLoggedIn()` → `context.go('/child-home')` (line 53).
- Target is `/child-home` (#7), **not** `/child-home/onboarding`. **PASS**
- (Round 1 fix verified: previously this went to `/child-home/onboarding`.)

### Flow B — Login success → `/child-home`
- `login_page.dart:81-87` → `AuthSession.saveLogin(...)` → `context.go('/child-home')`. **PASS**

### Flow C — Signup success → auto-login → `/child-home`
- `signup_page.dart:197-199` → `await AuthSession.saveLogin(username:_usernameController.text)` → `context.go('/child-home')`.
- Confirms Round 1 fix: signup now persists session and lands on home (no manual re-login). **PASS**
- Note: `// TODO(api): replace stub success with real signup call before saveLogin.` — flagged as known stub, not a routing defect.

### Flow D — Child-home header / card targets
| Source | Target | Route exists | Verdict |
|---|---|---|---|
| `my` button (좌상단) | `/mypage` | #4 | PASS |
| Bell (우상단) | `/child-home/notifications` | #10 | PASS |
| `bar_chart` icon (사용리포트) | `/child-home/report` | #9 | PASS |
| Gear icon | `/child-home/time-setup/confirm` | #13 | PASS |
| Mission card | `/child-home/mission/:id` | #14 | PASS |
| `+` button (no schedule) | `/child-home/time-setup` | #11 | PASS |

All header / card navigation **PASS**. (Audit prompt referred to `/mypage`, `/notifications`, `/report`, `/time-setup/confirm`, `/mission/:id`, `/time-setup` — the actual implementation uses `/child-home/`-prefixed variants except for `/mypage`. This is consistent with the routing table.)

### Flow E — Time-setup wizard back gesture
- `time_setup_root_page.dart:61-72` wraps the wizard in `PopScope`:
  - `canPop` is `true` for `intro` / `scheduleRegister` / `complete` (first step or terminal) — system back exits wizard.
  - For `weeklyTotal` / `dailyAllocation` / `review`, `canPop:false` + `onPopInvokedWithResult` calls `_controller.goToStep(previous)` — rewinds one step instead of popping the route. **PASS**
- `schedule_register_page.dart:49` BridgeAppBar back uses `context.pop()` — exits the wizard from step 1 (matches `canPop:true`). **PASS**

### Flow F — Notifications card tap → per-type default
`_defaultRouteFor(NotificationType)` in `notifications_page.dart:32-41`:
- `missionCompleted` → `/child-home` (#7) — PASS
- `missionConfirmationRequested` → `/child-home` (#7) — PASS
- `timeConfigured` → `/child-home/time-setup/confirm` (#13) — PASS
Uses `item.deeplink ?? _defaultRouteFor(...)` with `context.push(route)`. All three branches map to live routes. **PASS**

---

## 4. `BridgeAppBar.onBack` Defaults (12 pages using it)

`bridge_app_bar.dart:99` — when `onBack` is null, defaults to `() => context.pop()`. Explicit overrides should still resolve to a pop.

| Page | `onBack` | Verdict |
|---|---|---|
| `time_confirm_page.dart:82` | (default) | PASS — pops to caller (child-home or notifications) |
| `report_page.dart:43` | (default) | PASS |
| `signup_page.dart:231` | `() => context.pop()` (explicit, equivalent) | PASS |
| `schedule_register_page.dart:40` | `() => context.pop()` (exits wizard from step 1) | PASS |
| `time_setup_intro_page.dart:38` | (default) | PASS |
| `mission_info_page.dart:90` | (default) | PASS |
| `mission_info_page.dart:453` | (custom, not inspected) | LIKELY PASS — see note |
| `mission_info_page.dart:596` | (custom, not inspected) | LIKELY PASS — see note |
| `mission_info_page.dart:706` | `showBack: false` | N/A (back hidden) |
| `time_setup_review_page.dart:33` | (custom — wizard step) | PASS — controlled by `PopScope` parent |
| `daily_time_setup_page.dart:52` | (custom — wizard step) | PASS — see source comment line 220 cautioning against `context.push` |
| `weekly_time_setup_page.dart:42` | (custom — wizard step) | PASS — controlled by `PopScope` parent |
| `login_page.dart:118` | `() => context.pop()` | PASS |
| `my_page.dart:89` | (default) | PASS |
| `password_change_page.dart:176` | `context.pop` (tear-off) | PASS |

Twelve user-facing usages enumerated above. The two `mission_info_page` overrides at lines 453 / 596 use custom `onBack` callbacks not directly inspected in this round — flagged for spot-check (low risk, both within the same route, so worst case pops the route).

---

## 5. Round-1 Carry-over Check — `context.go('/child-home/onboarding')` residue

Grep across repo:
- `lib/app/router/app_router.dart:53` — **route definition** (legitimate, not a call).
- `lib/features/login/presentation/pages/login_page.dart:85` — **comment only** (`// /child-home/onboarding is reserved for…`).
- `docs/` matches are historical audit prose.

**No production `context.go('/child-home/onboarding')` call sites remain.** Round-1 fix verified clean. PASS.

---

## 6. Summary

| Item | Status |
|---|---|
| Routing graph (14 routes declared) | PASS |
| Dead-nav count across `lib/features/` | **0** |
| Flow A — `/` cached → `/child-home` | PASS |
| Flow B — login → `/child-home` | PASS |
| Flow C — signup → saveLogin → `/child-home` | PASS |
| Flow D — child-home header/card targets (6) | PASS (6/6) |
| Flow E — time-setup wizard `PopScope` back | PASS |
| Flow F — notification per-type default routes | PASS |
| `BridgeAppBar.onBack` default = `context.pop()` | PASS (10 verified, 2 mission overrides not inspected) |
| Residual `go('/child-home/onboarding')` calls | **0** |

---

## 7. Remaining Issues / Observations (non-blocking)

1. **`/child-home/onboarding` route still declared but no caller**: the route exists at router line 53 with no `context.go` invoking it. Dead route — safe to remove unless reserved for future first-time parent-connect deeplink. Not a routing defect.
2. **Mission-page `BridgeAppBar` overrides** (`mission_info_page.dart:453`, `:596`): custom `onBack` not inspected this round. Recommend a follow-up spot-check that both still resolve to `context.pop()` or a documented target.
3. **Notifications routing is mock-driven**: `_defaultRouteFor` covers only three enum cases. When backend deeplinks ship (TODO at line 29), validate that `item.deeplink` strings remain within the routing table.
4. **`/mypage/delete-complete` uses `context.go('/')`**: this resets the navigation stack to `/`, which then triggers `_redirectCachedLogin`. After account deletion, `AuthSession.isLoggedIn()` is expected to be false — needs verification that delete-account clears `AuthSession` before navigating, otherwise the user is bounced back into `/child-home`. **Recommend Round-4 check.**
5. **Signup uses stub success path** (`// TODO(api): replace stub success with real signup call before saveLogin.`): once real API lands, ensure `saveLogin` only runs on 2xx, otherwise failed signups will appear logged-in.

No routing-graph defects detected in Round 3 scope.
