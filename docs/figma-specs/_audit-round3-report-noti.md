# Round 3 Re-Audit — Report + Notifications

**Date**: 2026-05-18
**Scope**: Verify Round 1+2 fixes for Report (12-report.md) and Notifications (11-notifications.md).
**Method**: Static code inspection of 8 target files vs. acceptance criteria.

---

## Report — `lib/features/report/...` + `bridge_pie_chart.dart`

| # | Criterion | Result | Evidence |
|---|---|---|---|
| R1 | `overallCompliancePct` returns `overPct` (50), not `onPlanPct` (20) | **PASS** | `usage_report.dart:44` — `double get overallCompliancePct => overPct;` with inline rationale doc comment (lines 37-43) citing Figma `662:11497` |
| R2 | `AiSuggestion` has `suggestedHours: int` field | **PASS** | `usage_report.dart:47-61` — field declared (line 58) with docstring `"7 → renders as '7시간 00분'"` |
| R2a | Mock entries populate `suggestedHours` | **PASS** | `usage_report_mock.dart:45-70` — all 4 entries set `suggestedHours: 7` |
| R3 | Card 4 = `Column(header, Row(legend left + pie right))` | **PASS** | `report_page.dart:493-557` — outer `Column` with header `Row` (lines 501-519) then body `Row` (lines 521-555) containing `_LegendColumn` then `BridgePieChart` |
| R3a | Pie inner header suppressed (no duplicate `계획 이행률`) | **PASS** | `report_page.dart:534` — `BridgePieChart` constructed without `complianceRatePct`; `bridge_pie_chart.dart:89` gates header on `complianceRatePct != null` |
| R3b | Header text shows `계획 이행률 50%` (uses `overallCompliancePct`) | **PASS** | `report_page.dart:513` — `'${compliance.overallCompliancePct.toInt()}%'`; with mock data (overPct=50) → `50%` |
| R4 | Card 5 `_SuggestionRow` uses `[days] | divider | H시간 00분 | chip` pattern | **PASS** | `report_page.dart:644-685` — Row with `daysLabel` (664) → 1×22 gray200 divider (671) → `'$hours시간 $minutesLabel분'` (674, minutesLabel = `'00'`) → `_SuggestionDeltaChip` (680) |
| R4a | Pattern mirrors Card 3 `_DayBreakdownRow` | **PASS** | Both share same padding (16h/12v), gray100 bg, radius, divider geometry — compare `_DayBreakdownRow` (403-431) vs `_SuggestionRow` (656-684) |
| R5 | Card 1 has cat placeholder | **PASS** | `report_page.dart:165-178` — `Positioned(right:0, bottom:0)` with 44×43 `SizedBox` rendering `🐱` at 32sp; TODO comment (160-164) flags asset swap pending `imgCatIllustration` export |

**Report verdict: PASS (5/5 criteria, 9/9 sub-checks).**

Notes (non-blocking):
- `bridge_pie_chart.dart:64` keeps `_labelRadialPadding=14` (radial placement) instead of Figma's absolute coords — explicitly documented at lines 41-47 as intentional to avoid layout overflow in the new Row-based Card 4 box. Acceptable design trade-off.
- `_SuggestionDeltaChip` (688-734) renders `계획대로` for `neutral` tone instead of `0시간` — matches spec intent; verify against Figma 662:11585 copy if strict.

---

## Notifications — `lib/features/notifications/...`

| # | Criterion | Result | Evidence |
|---|---|---|---|
| N1 | 3 mock items mirror parent VERBATIM (자녀가… voice) | **PASS** | `notifications_mock.dart:13-33` — all 3 items use `자녀가` phrasing: `'자녀가 숙제하기 미션을 완료했어요.\n보너스 시간 15분 획득!'` (17), `'자녀가 숙제하기 미션 완료 확인을 요청했어요.'` (24), `'자녀가 1월달 사용 시간 설정을 완료했어요!'` (31). File header (lines 3-8) documents 1:1 parent-app parity source |
| N1a | Titles match parent | **PASS** | `미션완료`, `미션 확인 요청`, `시간설정 완료` — three categories present (lines 16, 23, 30) |
| N2 | `NotificationCard.onTap` wired to `_handleCardTap` (not empty `{}`) | **PASS** | `notifications_page.dart:143` — `onTap: () => _handleCardTap(item)`; `_handleCardTap` defined at 43-46 → resolves deeplink/default and `context.push(route)` |
| N3 | `_defaultRouteFor` returns valid routes for all enum values | **PASS** | `notifications_page.dart:32-41` — exhaustive switch over `NotificationType` returns: `missionCompleted→/child-home`, `missionConfirmationRequested→/child-home`, `timeConfigured→/child-home/time-setup/confirm`. All routes plausible (existing app routes) |
| N3a | `deeplink` field exists on model for per-item override | **PASS** | `notification_item.dart:28` — `final String? deeplink;` with docstring referencing fallback (lines 25-27) |
| N3b | `_handleCardTap` honors `deeplink` first, then default | **PASS** | `notifications_page.dart:44` — `item.deeplink ?? _defaultRouteFor(item.type)` |
| N4 | `_DeleteRevealIcon` uses `AppColors.destructive` (#FF4242), not hard-coded `#FF4B4B` | **PASS** | `notification_card.dart:215` — `color: AppColors.destructive`; comment (212-214) explicitly references spec line `06-notifications.md:160` and calls out the prior `#FF4B4B` drift |

**Notifications verdict: PASS (4/4 criteria, 6/6 sub-checks).**

Notes (non-blocking):
- Default routes are placeholders (TODO at `notifications_page.dart:29-31`) — acceptable until backend deeplinks ship. No criterion violated.
- `_DeleteNotificationDialog` icon container (line 184) also uses `AppColors.destructive` — token consistency confirmed.

---

## Aggregate

- **Report**: 5/5 PASS
- **Notifications**: 4/4 PASS
- **Total: 9/9 PASS — Round 3 verification clean. No regressions detected.**

Round 1+2 fixes for both surfaces are correctly applied and documented inline. No remaining work blocks shipping these screens against the cited Figma specs.
