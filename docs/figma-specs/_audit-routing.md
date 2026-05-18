# Routing Graph Audit — Bridge_K Child App

Source of truth: `lib/app/router/app_router.dart`
Auditor scope: every `GoRoute` registered + every `context.push`/`context.go`/`context.pop` call site in `lib/`.

---

## 1. Registered Routes (14 total)

| # | Path | Builder | parentNavigatorKey |
|---|------|---------|--------------------|
| 1 | `/` | `HomePage` (intro) | (default) |
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
| 12 | `/child-home/time-setup/v2` | `TimeSetupV2RootPage` (v2 wizard shell) | root |
| 13 | `/child-home/time-setup/confirm` | `TimeConfirmPage` | root |
| 14 | `/child-home/mission/:id` | `MissionInfoPage(missionId)` | root |

Note: routes are flat (no `ShellRoute`, no `routes:` nesting). Every screen is reached via header icons, CTAs, or deeplinks — no bottom-nav shell.

---

## 2. Navigation Graph (text)

```
                           ┌──────────────────┐
                           │ / (HomePage)     │◄─────────────────────────────┐
                           │ intro/splash     │                              │
                           └─┬─────────┬──────┘                              │
                  push       │         │       push                          │
                ┌────────────┘         └──────────────┐                      │
                ▼                                     ▼                      │
        ┌──────────────┐                       ┌──────────────┐              │
        │ /signup      │  go('/') back/submit  │ /login       │              │
        │              ├──────────────────────►│              │              │
        └──────────────┘                       └──────┬───────┘              │
                                  go('/child-home/onboarding')               │
                                                      ▼                      │
                                              ┌───────────────────┐          │
              auto on app start if logged-in: │ /child-home/      │          │
              HomePage initState ─────────────► onboarding        │          │
                                              │ (ChildHomePage    │          │
                                              │  showOnb=true)    │          │
                                              └───────┬───────────┘          │
                                          tap overlay │ (setState only;      │
                                          → dismiss   │  URL stays the same) │
                                                      ▼                      │
                                       ┌──────────────────────────┐          │
                            ┌──────────┤ /child-home              ├────────┐ │
                            │          │ (dashboard)              │        │ │
                            │          └──────┬─────────┬─────┬───┘        │ │
                            │ push 'my'       │bell push│gear │bar         │ │
                            ▼                 ▼  push   │push │push        │ │
                    ┌───────────┐    ┌───────────────┐ │     │             │ │
                    │ /mypage   │    │ /child-home/  │ │     │             │ │
                    └─┬───┬─┬───┘    │ notifications │ │     │             │ │
                push  │   │ │        └───┬───────────┘ │     │             │ │
              password│   │ │ logout     │ go(deeplink)│     │             │ │
                      │   │ └────────────┼──────► / ───┼─────┼─────────────┘ │
                      ▼   ▼              ▼             ▼     ▼               │
            /mypage/      /mypage/      n1→ /child-home/report ◄─────────────┤
            password      delete-       n2→ /child-home/time-setup/v2        │
                         complete       n3-n6→ no deeplink (CTA inert)       │
                          │                                                  │
                          └─auto 3s→ go('/') ────────────────────────────────┘

  child-home mission card push → /child-home/mission/:id ── go('/child-home')
  child-home + button (empty)  push → /child-home/time-setup ── (inside wizard)
                                                                 │
   v1 wizard shell renders one of:                              │
     scheduleRegister (Cmp/topbar) → onBack go('/child-home')   │
     weeklyTotal/dailyAllocation/review (intra-shell setState)  │
     complete → BridgeButton go('/child-home')                  │
                                                                │
   Report footer CTA  push → /child-home/time-setup/v2 ◄────────┤
                              (same wizard structure; only      │
                               daily page exposes 사용리포트 보기 │
                               + 스케줄 보기 ghost pills →       │
                               push /child-home/report          │
                               push /child-home)                │
```

---

## 3. Per-Route Reachability + Pop Behavior

### `/` — HomePage (intro)
- Entry: `initialLocation: '/'` in `appRouter`.
- Also reached by `context.go('/')` from logout, signup submit, signup back, login back, delete-complete auto-redirect.
- **Pop**: top of stack — no app-bar back. System back exits app. OK.
- **Auto-redirect**: `_redirectCachedLogin()` → `context.go('/child-home/onboarding')` if `AuthSession.isLoggedIn()`.

### `/login`
- Reached: `home_page.dart:159` `context.push('/login')`.
- Back: `_LoginTopBar(onBack: () => context.go('/'))` — uses `go`, not `pop`.
  - Side effect: replaces the stack rather than popping. Loses the `push` history. Functionally OK because `/` is the only sensible predecessor, but inconsistent with `pop` semantics elsewhere.
- Submit success: `context.go('/child-home/onboarding')`.

### `/signup`
- Reached: `home_page.dart:130` `context.push('/signup')`.
- Back: `_SignupTopBar(onBack: () => context.go('/'))` — same `go`-as-back pattern as login.
- Submit success: `context.go('/')` (signup_page.dart:194) — returns to intro instead of going to home/onboarding. Possible UX gap (no auto-login after signup).

### `/child-home`
- Reached by `go` from: login submit (via `/child-home/onboarding`), signup auto-redirect (cached only), mission "홈으로" button, time-setup-complete "홈으로", schedule-register back, daily-time-setup pill, logout? (no — logout goes `/`).
- Reached by `push` from: daily-time-setup "스케줄 보기" pill (`daily_time_setup_page.dart:94`).
- **No AppBar back** — page is composed of `_TopBar` + `_TodayTimeSection` + `_MissionSection` in a `Scaffold` with no `appBar:`. System back on Android pops if there is history; otherwise exits. OK as a "home" destination.

### `/child-home/onboarding`
- Reached by: HomePage cached-login redirect, LoginPage submit.
- Same `ChildHomePage` widget with `showOnboarding:true, showContent:false`. The onboarding overlay is dismissed via local `setState` — **URL stays `/child-home/onboarding` even after dismissing the overlay**. Subsequent push targets work, but back navigation will return to the onboarding URL state (which then rebuilds with `showOnboarding:true` again from the route arg). **Dead-end-ish: a user who pushes to mypage and pops back will see the onboarding overlay re-appear** because `ChildHomePage(showOnboarding:true)` is rebuilt by the router.
  - Verified: `didUpdateWidget` resets `_showOnboarding = widget.showOnboarding` on widget arg change, but on a fresh `pop` back the route rebuilds the widget with `showOnboarding:true` again.

### `/child-home/notifications`
- Reached: `child_home_page.dart:181` bell icon push.
- AppBar: `BridgeAppBar(title:'알림')` → back defaults to `context.pop()`. OK.
- CTA `onCtaTap` uses `context.go(item.deeplink!)` — `go` replaces stack. After tapping n1 (report) or n2 (time-setup v2) the back button no longer returns to notifications, it returns to whatever the prior URL was. **Inconsistent with push semantics from the rest of the app.**
- n3–n6 have `ctaLabel` but `deeplink == null` → button is inert (no CTA wired). Per code: `(item.ctaLabel != null && item.deeplink != null)` gate. Treat as orphan CTA copy.

### `/child-home/report`
- Reached: bar-chart icon on `_TodayTimeSection` (`child_home_page.dart:302`), n1 notification deeplink (via `go`), daily-time-setup v2 pill (`daily_time_setup_page.dart:87`).
- AppBar: `BridgeAppBar(title:'사용 리포트')` → default `pop`. OK.
- Footer CTA: `context.push('/child-home/time-setup/v2')`.

### `/child-home/time-setup` (v1)
- Reached: `_ScheduleEmptyState` + button (`child_home_page.dart:397`).
- Internal shell renders steps. **ScheduleRegisterPage uses `BridgeAppBar(onBack: () => context.go('/child-home'))`** — `go` instead of `pop`, so the time-setup route is replaced, not popped. Acceptable but inconsistent.
- Complete step → button `context.go('/child-home')`. OK.
- WeeklyTotal/Daily/Review steps are intra-wizard (no URL changes).

### `/child-home/time-setup/v2`
- Reached: report footer CTA, n2 notification deeplink (via `go`).
- Same internal shell as v1. Inherits the same back behavior. No dedicated v2 back override beyond what the sub-pages already do (all `go('/child-home')`).

### `/child-home/time-setup/confirm`
- Reached: gear icon on `_TodayTimeSection` (`child_home_page.dart:318`).
- AppBar: `BridgeAppBar(title:'시간설정')` → default `pop`. OK.
- Empty/filled both close via `context.pop()`. OK.

### `/child-home/mission/:id`
- Reached: mission card tap (`child_home_page.dart:760`) — `context.push('/child-home/mission/${data.id}')`.
- CTA "홈으로": `context.go('/child-home')` — replaces stack. No AppBar back found in the snippet read (line 500-529); confirmed mission page has no `BridgeAppBar` with a back chevron — the only nav exit is the "홈으로" filled button. **Possible UX gap on Android system-back** if users expect a chevron.

### `/mypage`
- Reached: "my" button on child home (`child_home_page.dart:218`).
- AppBar: `BridgeAppBar(title:'마이페이지')` with no `onBack` override → defaults to `context.pop()`. OK.
- Logout: `context.go('/')`. OK.
- 탈퇴 dialog → confirm → `context.pop()` (close dialog) → `router.push('/mypage/delete-complete')`.

### `/mypage/password`
- Reached: `my_page.dart:388` `context.push('/mypage/password')`.
- AppBar: `_PasswordChangeTopBar(onBack: context.pop)`. OK.
- Submit success: `context.pop()`. OK.

### `/mypage/delete-complete`
- Reached: `router.push('/mypage/delete-complete')` from delete dialog confirm.
- No AppBar back. 3-second `Timer` → `context.go('/')`. OK (intentional terminal screen).

---

## 4. Orphan / Missing / Dead-End Findings

### Orphan routes (registered, no in-app caller)
- **None.** Every registered path has at least one `push`/`go` call site verified above.

### Missing routes (referenced but not registered)
- **None.** All deeplink strings (`/child-home/report`, `/child-home/time-setup/v2`) and all `push`/`go` targets resolve to registered routes.

### Dead-ends / friction points
1. **Onboarding re-trigger on back** — `/child-home/onboarding` route arg is sticky. Popping back from `/mypage` or `/child-home/notifications` will rebuild `ChildHomePage(showOnboarding:true)` and re-show the overlay. Local `_dismissOnboarding` only sets state, doesn't `context.go('/child-home')`. Recommend: on dismiss, `context.go('/child-home')` to clear the route arg.
2. **`go`-as-back in login/signup top bars** — replaces the stack instead of popping. If anything else ever pushes to `/login` (e.g. session expiry from an inner screen), the back will lose that prior context. Recommend swap to `context.pop()` when there is history, else `context.go('/')` as a fallback.
3. **Notification CTA uses `go` not `push`** — `notifications_page.dart:109` `context.go(item.deeplink!)` means tapping "확인하러 가기 →" on n1/n2 dumps the notifications screen from the stack. After reading the report/time-setup, the back button skips notifications. Should be `context.push` so users can return to the notifications list.
4. **Mission detail has no back chevron** — only exit is the "홈으로" CTA at the bottom of the screen. Android system back still works (route was `push`ed) but iOS users have no on-screen back affordance. Add `BridgeAppBar` to match the rest of the secondary screens.
5. **n3–n6 notification CTAs are inert** — `ctaLabel: '확인하러 가기 →'` is rendered but `deeplink: null`, so the gate at line 108 disables `onCtaTap`. Either remove the CTA label for these items or wire deeplinks (e.g. n3/n4 → `/child-home/mission/:id`, n5/n6 → ???).
6. **Signup success goes to `/` not `/child-home`** — user has to log in again after creating an account. Likely a missed auto-login hook, not a router bug, but worth flagging because the routing graph offers no alternate path.
7. **Time-setup back goes `go('/child-home')`** — `schedule_register_page.dart:42` uses `go` instead of `pop`. If a user enters the wizard from notifications (push) the back will still replace the stack. Functionally equivalent here, but inconsistent.

### Inconsistent back semantics summary
| Screen | Back method | Recommended |
|---|---|---|
| /login | `go('/')` | `pop()` (with `go` fallback) |
| /signup | `go('/')` | `pop()` (with `go` fallback) |
| /child-home/time-setup (schedule_register) | `go('/child-home')` | `pop()` |
| /child-home/notifications CTA | `go(deeplink)` | `push(deeplink)` |
| /mypage, /mypage/password, /child-home/{notifications,report,time-setup/confirm} | default `pop()` | OK |
| /child-home/mission/:id | no chevron, CTA `go('/child-home')` | add `BridgeAppBar`, use `pop()` |

---

## 5. Recommendations (priority order)

1. **Fix onboarding stickiness** — on tap-to-dismiss, call `context.go('/child-home')` so the URL no longer carries `showOnboarding:true`. Prevents the overlay reappearing after any push/pop round-trip.
2. **Notifications CTA → `push`** — preserves the notifications list under the destination so users can swipe-back or chevron-back to it.
3. **Add `BridgeAppBar` to mission_info_page** — restores iOS back chevron parity.
4. **Standardize back semantics** — replace `go('/')` and `go('/child-home')` back overrides in login/signup/schedule_register with `Navigator.canPop(context) ? context.pop() : context.go('/...')`. Keeps stack history intact when pages are reached via push.
5. **Wire or remove n3–n6 deeplinks** — every visible CTA should either navigate or not be rendered.
6. **Decide signup post-submit behavior** — either auto-login → `/child-home/onboarding`, or explicitly route to `/login` with a success toast. Right now it dumps users at `/` with no feedback.
7. **Consider a redirect guard** on the router (`GoRouter.redirect`) for `/child-home/*` paths when `!AuthSession.isLoggedIn()` — currently any direct deeplink (e.g. notification while logged out) would render the page without an auth check.
