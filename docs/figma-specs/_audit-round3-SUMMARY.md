# Audit Round 3 — Synthesis Summary

**Date**: 2026-05-18
**Mode**: Diagnostic-only synthesis. Aggregates the 7 Round-3 per-area audit docs and cross-references the Round-1/Round-2 fix history captured in `_audit-layout-SUMMARY.md`.
**Source audits**:
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-build.md`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-routing.md`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-appbar.md`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-time-v1.md`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-time-v2-confirm.md`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-mission.md`
- `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-report-noti.md`

---

## A. Fix tally — 16 fix batches (R1 #1-8, R2 #1-8)

| Batch | Surface | File(s) changed | Status | Round-3 evidence |
|---|---|---|---|---|
| R1 #1 | BridgeAppBar status-bar inset | `lib/core/widgets/layout/bridge_app_bar.dart` | DONE | `_audit-round3-appbar.md` table rows 1-4 + 11/11 Scaffold pages PASS |
| R1 #2 | HomePage cached-login → `/child-home` (was `/child-home/onboarding`) | `lib/features/home/presentation/pages/home_page.dart` | DONE | `_audit-round3-routing.md` §3 Flow A PASS + §5 grep clean |
| R1 #3 | Signup → `AuthSession.saveLogin` → `/child-home` | `lib/features/signup/presentation/pages/signup_page.dart` | DONE | `_audit-round3-routing.md` §3 Flow C PASS |
| R1 #4 | Password input `obscureText` | `login_page.dart` + `signup_page.dart` `_LoginField`/`_SignupField` | DONE | Cross-referenced in Section B item 2; routing audit shows no plaintext call sites flagged |
| R1 #5 | Login/Signup back button — remove `context.go('/')` override | `login_page.dart:120`, `signup_page.dart:231` | DONE | `_audit-round3-routing.md` §4 — both pages use `context.pop()` |
| R1 #6 | `PasswordChangeButton.enabled` → `onPressed: enabled ? onPressed : null` | `password_change_page.dart` | DONE | Cross-referenced — no longer flagged in Round-3 routing/appbar |
| R1 #7 | Mission `_SubmittedView` + `미션수행` topbar; reviewing/completed unified | `mission_info_page.dart:706` | DONE | `_audit-round3-mission.md` checks 10, 11 PASS |
| R1 #8 | Notification card `onTap` wired to `_handleCardTap` dispatcher | `notifications_page.dart:43-46, 143` | DONE | `_audit-round3-report-noti.md` N2 PASS |
| R2 #1 | Weekly v1 `자동계산` — disabled + tooltip `곧 사용 가능한 기능이에요` | `weekly_time_setup_page.dart:81-92` | PARTIAL | `_audit-round3-time-v1.md` weekly PASS for disable; backend logic still TODO |
| R2 #2 | Time-setup wizard PopScope (Android system back rewinds in-wizard) | `time_setup_root_page.dart:61-72` | DONE | `_audit-round3-routing.md` §3 Flow E PASS |
| R2 #3 | TimeSetup v2 controller `_previousWeek` + `.v2NextWeek` + mode-aware `reset()` | `time_setup_controller.dart:34-38, 41, 161-167` | DONE | `_audit-round3-time-v2-confirm.md` rows 1-3c PASS |
| R2 #4 | Weekly v2 — 4 rows (1 locked + 3 editable), locked from `previousWeek` | `weekly_time_setup_page.dart:99-118` | DONE | `_audit-round3-time-v2-confirm.md` rows 4a-4e PASS |
| R2 #5 | Daily v2 pills — `tonal` variant, order `[스케줄 보기, 사용리포트 보기]`, in-flow `showModalBottomSheet` | `daily_time_setup_page.dart:99-118, 226` | DONE | `_audit-round3-time-v2-confirm.md` rows 5a-5d PASS |
| R2 #6 | Daily v2 error frame — 1.2px border (destructiveBorderSoft / primary) | `daily_time_setup_page.dart:279-304` | DONE | `_audit-round3-time-v2-confirm.md` rows 6a-6d PASS |
| R2 #7 | TimeConfirm tooltip — title + 2 bullets + underlined emphasis + close X + arrow below pill | `time_confirm_page.dart:166-220`, `bridge_onboarding_tooltip.dart:40-47, 160-165` | DONE | `_audit-round3-time-v2-confirm.md` rows 7a-7i PASS |
| R2 #8 | Report Card 4 layout `Row[legend, pie]` + Card 5 hour column + `overallCompliancePct = overPct` + cat asset placeholder + Notifications verbatim copy | `report_page.dart` + `usage_report.dart` + `notifications_mock.dart` | DONE | `_audit-round3-report-noti.md` 5/5 + 4/4 PASS |

**Tally**: 15 DONE · 1 PARTIAL (R2 #1 — UI disabled, backend algorithm pending) · 0 REGRESSED.

---

## B. Critical resolution status (original 5 from `_audit-layout-SUMMARY.md`)

| # | Original critical issue | Status | Evidence |
|---|---|---|---|
| 1 | BridgeAppBar status-bar overlap (11 FAIL pages) | RESOLVED | `_audit-round3-appbar.md` — 11/11 Scaffold pages PASS, 4/4 inline-pattern pages NO REGRESSION, 1/1 N/A |
| 2 | Plaintext password (`_LoginField` / `_SignupField` lacked `obscureText`) | RESOLVED | Round-3 routing/appbar audits do not re-flag; R1 #4 confirmed in fix tally |
| 3 | Notification card `onTap: () {}` dead | RESOLVED | `_audit-round3-report-noti.md` N2 PASS — `onTap: () => _handleCardTap(item)` + `_handleCardTap` 43-46 |
| 4 | Weekly `자동계산` dead button | PARTIAL | `_audit-round3-time-v1.md` weekly PASS for disable + tooltip; algorithm still TODO (Section D residual) |
| 5 | `PasswordChange` disabled-bypass | RESOLVED | R1 #6 in fix tally; Round-3 audits do not re-flag |

**4 RESOLVED, 1 PARTIAL, 0 OPEN.**

---

## C. Round 3 verdict (per-audit)

| Audit | Result | Counts |
|---|---|---|
| build (`_audit-round3-build.md`) | NOT READY (test drift only) | `flutter analyze`: 0 errors / 0 warnings · `dart format`: 5 files need format · `flutter test`: 2 pass / 3 fail (drift on `MyPage` + cached-login boot test expectations) |
| routing (`_audit-round3-routing.md`) | PASS | 14 routes declared · 0 dead nav across `lib/features/` · Flows A/B/C/D/E/F all PASS · 0 residual `go('/child-home/onboarding')` call sites |
| appbar (`_audit-round3-appbar.md`) | PASS | 11/11 Scaffold.appBar pages PASS · 4/4 inline-pattern pages NO REGRESSION · 1/1 custom topbar N/A |
| time-v1 (`_audit-round3-time-v1.md`) | PARTIAL | 5 pages PASS (intro, schedule_register, daily, complete, stepper-pills cross-widget) · 2 pages PARTIAL FAIL (weekly: card not split + `currentStep: 2` literal · review: `currentStep: 3` literal + injected `BridgeTotalTimeCard` title) |
| time-v2 + confirm (`_audit-round3-time-v2-confirm.md`) | PASS | 7 areas × verification matrix = ALL PASS (rows 1, 2, 3a-c, 4a-e, 5a-d, 6a-d, 7a-i) |
| mission (`_audit-round3-mission.md`) | PASS | 12/12 checks PASS · all 5 sub-views (InfoView tab1, tab2, CameraPrompt, PhotoPreview, Submitted) PASS |
| report + noti (`_audit-round3-report-noti.md`) | PASS | Report 5/5 (9/9 sub-checks) · Notifications 4/4 (6/6 sub-checks) · Aggregate 9/9 |

**Aggregate**: ~57 individual verification checks across 7 audits. ~54 PASS · 2 PARTIAL FAIL (weekly v1, review v1 — cosmetic literal drift) · 1 area NOT READY for ship gate (build: format + widget tests). **0 functional regressions detected.**

---

## D. Open work (Tier 1 + Tier 2 remaining)

Aggregated from Round-3 partial fails and non-blocking observations.

1. **Weekly v1 — total-time card 2-section split.** `BridgeTotalTimeCard(title: '주별 총 사용시간', …)` still merged; Figma 08a §245-250 requires (a) `2월 총 사용 시간` block + read-only card and (b) `주별 시간 분배` section header + right-aligned `자동계산` button, separated by gap=40. `weekly_time_setup_page.dart` (see `_audit-round3-time-v1.md` weekly FAIL #1).
2. **Review v1 — `currentStep` literal + total-time card title spec.** `currentStep: 3` hard-coded (should read `controller.stepIndex`); `BridgeTotalTimeCard(title: …)` injects an inline title not present in 08c (spec shows label `2월 1주차` separately). `time_setup_review_page.dart:50, 62-66` (see `_audit-round3-time-v1.md` review FAIL #1, #2).
3. **Weekly + daily v1 — `currentStep` literal drift.** `weekly_time_setup_page.dart:58` (`currentStep: 2`) and `daily_time_setup_page.dart:64` (`currentStep: 3`) hard-coded; should use `controller.stepIndex` for consistency with `schedule_register`.
4. **`자동계산` algorithm (backend).** Round-2 disabled+tooltip workaround in place; even-split logic (`monthlyCap / 4`, idle-after-first-edit predicate) not implemented. `weekly_time_setup_page.dart` + `time_setup_controller.dart`.
5. **Notification deeplinks (backend).** `_defaultRouteFor` covers 3 enum cases with placeholder targets; per-item `item.deeplink` ships as `null` in mocks. Validate string-to-route mapping once backend payloads land. `notifications_page.dart:29-41`.
6. **Settings / bar_chart official SVG (design export).** Child-home empty state still uses filled Material `Icons.settings` and `Icons.bar_chart`; Figma calls for outlined cog + bar-chart SVG masks. `child_home_page.dart:327, 616` + `assets/icons/`.
7. **Cat illustration official asset (design export).** Report Card 1 renders 🐱 emoji at 32sp as placeholder (TODO at `report_page.dart:160-164`); export `imgCatIllustration` from Figma node `750:11937` to `assets/icons/cat.svg`.
8. **Widget test reconciliation (3 failing).** `test/widget_test.dart:37, 72, 91` assert on copy/structure that no longer matches `MyPage` and the cached-login boot path. Fix the drift (do not skip tests).
9. **Routing follow-ups (non-blocking, Round-4 candidates)**: dead `/child-home/onboarding` route declaration (no caller); mission `BridgeAppBar` overrides at `mission_info_page.dart:453, 596` not spot-checked; `/mypage/delete-complete` → `go('/')` needs `AuthSession.clearLogin` confirmation; signup stub TODO must gate `saveLogin` on real 2xx response.

---

## E. Domain decisions log (Figma-based, user-confirmed during the round)

| Surface | Decision | Rationale |
|---|---|---|
| Notifications mock copy | Mirror parent verbatim (`자녀가 숙제하기 미션을…` voice) | Cross-app 1:1 parity; documented at `notifications_mock.dart:3-8` |
| Mission `rejected` branch | Branch removed; rejected status falls through to reviewing visual | Spec line 232 explicitly: no rejected Figma node exists. Documented at `mission_info_page.dart:685-689` |
| MyPage `로그아웃` button | Removed entirely (Figma omits it) | `08-mypage.md` row y=364-399 lists only 탈퇴하기; engineering shipped 로그아웃 in error |
| Report `계획 이행률` percentage | Use `overPct` (50%) for `overallCompliancePct` | Resolves 20% vs 50% ambiguity from `_audit-layout-SUMMARY.md` Section G. Documented at `usage_report.dart:37-44` citing Figma `662:11497` |
| Weekly `자동계산` | Disabled with tooltip `곧 사용 가능한 기능이에요` (backend later) | Removes misleading affordance without blocking ship; backend logic deferred per Section D #4 |

---

## F. Ship verdict

Decision inputs:
1. `flutter analyze lib/` — **0 errors, 0 warnings**.
2. `flutter pub get` — clean.
3. Routing — **14 routes, 0 dead nav, 5/5 flows PASS, 0 residual onboarding-redirect call sites**.
4. Critical-fix re-audits — **100% PASS on appbar (11/11 + 4/4), TimeSetup v2 + Confirm (7/7), Mission (12/12), Report+Notifications (9/9)**.
5. Critical resolution — **4 RESOLVED + 1 PARTIAL (intentional disable+tooltip)** out of 5.
6. Test drift — **3 widget tests failing on intentional Round-1/2 UI changes** (not functional regressions).
7. Format — **5 files need `dart format`** (cosmetic, blocks CI gate only).

**Verdict: READY for runtime smoke test.**

Conditions:
- **READY** for QA / smoke-test deployment.
- **3 widget tests need update** (separate task; do not skip — fix the assertions to match current `MyPage` and cached-login boot flow).
- **5 files need `dart format lib/`** before any CI gate that enforces formatting (cosmetic).
- The 2 PARTIAL-FAIL items in time-v1 (weekly card split, review/weekly/daily `currentStep` literals) are end-user-visible Figma drift but non-blocking for runtime correctness — schedule for the next polish pass.

---

## Doc path

`/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/_audit-round3-SUMMARY.md`
