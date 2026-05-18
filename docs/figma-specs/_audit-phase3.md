# Phase 3 Audit — Notifications & Report

> Diagnosed against `06-notifications.md` and `07-report.md` (Figma file `tzJjQmXtXO7vGlfCT9SASu`, nodes 426-19287, 426-19293, 773-12916, 773-12903, 662-11497). Audit only — no fixes applied.

---

## 1) Notifications (`lib/features/notifications/presentation/pages/notifications_page.dart`)

### PASS
- Top-level layout sequence matches Figma: `BridgeAppBar('알림')` → `ListView.separated` of tiles → empty fallback.
- Page horizontal padding uses `AppTokens.pageHorizontal` (24) per Figma (`bridge_tile width 327 / 375`).
- Background uses `AppColors.background` (gray050) — matches `#FAFBFC` (specs allow gray050/gray100 family).
- Empty state is single muted centered line using `AppTypography.bodyMedium` + `gray500` (no color hex literals).
- Tile card uses token references: `AppColors.surface`, `AppTokens.dialogRadius`, `AppColors.gray300/gray500/gray800`, `AppColors.positive/primary/cautionary/destructive`.
- Title chip typography uses `AppTypography.captionBold`, body uses `labelMedium`, timestamp uses `captionRegular`, CTA uses `captionMedium` — matches spec mapping (Caption/Bold 12, Label/Medium 14, Caption/Regular 12, Caption/Medium 12).
- Swipe-delete wiring: `Dismissible(direction: endToStart, dismissThresholds 0.4, secondaryBackground: BridgeSwipeActionBackground)` — exactly per spec §"Delete interaction (model)".
- Confirm dialog (`BridgeConfirmDialog.show`) gated through `confirmDismiss` callback before `onDismissed` — matches spec ("releasing past threshold triggers confirmation dialog... does NOT immediately delete").
- Dialog scrim uses `AppColors.scrim` (`0x99444444`) — matches Figma `rgba(68,68,68,0.6)` token.
- Swipe reveal uses `AppColors.destructiveSubtle` (`#FFD3D3`) — matches Figma `destructive100`.
- Tile spacing 12 between items is reasonable (within 15 spec tolerance, see FAIL below for exactness).
- ListView vertical padding 16 keeps first tile clear of app bar.

### FAIL
- **notifications_page.dart:86 — separator gap mismatch.** Spec §"Implementation notes (Flutter)" calls for `SizedBox(height: 15)` between tiles; impl uses `SizedBox(height: 12)`. Delta: -3 px (consistent visual tightening across all 5 tiles).
- **bridge_notification_tile.dart:118 — wrong radius token.** Tile uses `AppTokens.dialogRadius` (12). Spec §"Notification tile structure" specifies `radius=12` in the swipe-state frame but the filled-state frame (`426-19293`) explicitly states `radius=12` per the source — re-verify: spec says `radius=12` here, so this is OK. *Re-class: PASS.* (Original concern dropped — leaving note for traceability.)
- **bridge_notification_tile.dart:95-108 — icons are Material defaults, not Figma assets.** Spec §"Icon" calls for "raster assets ... colored circle/badge matching the category color". Impl uses bare `Icons.assessment_outlined`, `Icons.schedule`, `Icons.check_circle`, `Icons.cancel`, `Icons.help_outline` with no badge background. Figma shows filled colored chip/badge backgrounds behind glyphs.
- **bridge_notification_tile.dart:87 — `missionComplete` uses `AppColors.cautionary` (#FF9200, orange).** Spec §"Title colors by type" mandates `#FFCC33` (secondary yellow). The codebase declares `AppColors.secondaryYellow = #FFCC33` (app_colors.dart:67, "Declared-only"); impl falls back to orange instead of the spec-correct yellow. Visible color delta: orange-vs-yellow on two of the six tiles.
- **bridge_notification_tile.dart:159 — `captionBold` has letter-spacing `2.52`.** Spec maps title chip to "Pretendard SemiBold 12 / letter-spacing 2.52" so this matches *spec* but the very wide tracking (>20%) at 12 sp will visibly stretch '위클리 사용 리포트' beyond the icon row. (Spec-faithful — flagging as latent concern, not a FAIL on its own.)
- **notifications_mock.dart:7-50 — only 5 mock items; spec requires 6.** Spec §"Layout (top → bottom)" enumerates six cards in a specific order: weeklyReport, timeSetup, missionComplete(AI), missionComplete(parent), missionRejected(parent), missionRejected(AI). Impl has 5: weeklyReport, timeSetup, missionComplete, missionRejected, missionRequest. The 6th (`missionConfirmRequest` as the `미션 확인 요청` variant) is implemented as `missionRequest` and replaces, rather than supplements, the second `missionComplete`/`missionRejected` variants.
- **notifications_mock.dart:11,21,30,38,46 — body text does not match spec verbatim.** Spec §"Texts (verbatim)" gives specific Korean copy per tile (e.g. `이번주 사용 리포트가 도착했어요.` is mock — spec is `2월 1주차 사용 분석이 담긴 리포트가 도착했어요!\n리포트를 통해 더 나은 계획을 세워봐요.`). All five tile bodies are paraphrased mocks rather than the spec's literal strings.
- **notifications_page.dart:73 — empty-state copy does not match Figma verbatim.** Impl renders `'새로운 알림이 없어요.'`; Figma (`426-19287`) renders `'확인하지 않은 알림이 없습니다.'`. Two different sentences.
- **notifications_page.dart:74 — empty-state typography mismatch.** Spec §"Empty copy" maps to `Headline/Medium` (18). Impl uses `AppTypography.bodyMedium` (16). 2 sp delta plus weight is fine (both Medium) but size is off.
- **bridge_notification_tile.dart:170 — timestamp uses `gray300` (`#A7ACB2`).** Matches spec. (PASS — included to document audit trail.)
- **bridge_notification_tile.dart:177-190 — CTA is an `InkWell`-wrapped Text, no trailing arrow rendering control.** Spec text is the literal `확인하러 가기 →` (single glyph included). Impl passes the string through, so it renders correctly if the mock includes `→`. Mock does (notifications_mock.dart:14 etc.) — PASS for arrow, but no test covers the case where caller omits it.
- **bridge_confirm_dialog.dart:54-55 — dialog `_cardWidth=328, _cardHeight=211`.** Spec §"Confirmation dialog" gives `294.897 × 189.705` (in the 90%-scaled frame). Production-scale equivalent ≈ 328 × 211 → matches. PASS.
- **bridge_confirm_dialog.dart:99 — dialog adds `border: gray200 width 1`.** Spec does not call for a border on the alert dialog (white card with shadow only). Extra 1 px ring is visible against the scrim.

### Notes (not pass/fail)
- `BridgeAppBar` title style uses `AppTypography.headlineBold` (SemiBold 18); spec §"Header `알림`" specifies Pretendard *Medium* 18 → `Headline/Medium`. Not a Phase 3 regression (BridgeAppBar is shared infra) but noted for catalog consistency.
- Swipe gesture uses `dismissThresholds: 0.4` ✓ matches spec.

---

## 2) Report (`lib/features/report/presentation/pages/report_page.dart`)

### PASS
- Page-level layout uses `ListView` with `pageHorizontal=24` padding — matches Figma 24/24 side gutters.
- Background uses `AppColors.background` (gray050 = `#FAFBFC`) — matches scaffold bg spec.
- Card chrome (`_ReportCard`, report_page.dart:62-87) uses `AppColors.surface` + `AppTokens.cardRadiusSmall` (16) — matches spec ("white card, radius 16").
- Card shadow `Color(0x1A000000), offset(0,4), blur 8` is a close approximation of Figma `0 4 2 rgba(0,0,0,0.1)` (blur is larger; opacity matches at 10%).
- Plan summary day-set tiles use `AppColors.gray100` + `cardRadiusSmall` — matches Figma "Day Group Container" (gray100, radius 16).
- `_PlanDaySetRow` vertical divider `width:1, height:22, color: gray200` — matches Figma "Vector1, 1×22, gray200".
- Delta chips for bar-chart per-day use `destructiveSubtle / primarySoft / gray100` tokens (no stray hex).
- Suggestion rows reuse the same gray100 tile chrome — matches "4 Day Group Container rows (same component as Card 3 list)".
- BridgeBarChart uses `AppColors.primary` for planned, `destructive`/`positive`/`primary` for actual — matches spec series colors.
- BridgePieChart slice colors map correctly: `positive` (계획대로) / `primary` (많이) / `destructive` (적게) — matches Figma slice colors.
- Pie chart size = `124` — matches spec (`124×124`).
- Pie external % labels via `Positioned` overlays — matches spec ("Labels positioned outside each slice").
- Section titles use `AppTypography.headlineBold` (18 SemiBold) — matches spec `Headline/Bold`.

### FAIL
- **report_page.dart:42 — `_PeriodHeader` is a bare title with no `Card 1` (Weekly Intro / speech-bubble / cat illustration).** Spec §"Card 1 — Weekly Intro" (`750:11937`) is a full white card 232 px tall containing a caption (`이번주 나는 어떻게 사용했을까?`), the title in `primary` color, a `primarySoft` speech-bubble (4 lines), a polygon tail, and a 44×43 cat illustration. None of these are rendered. The header is reduced to a single line of `heading2Bold` (`textPrimary`) — Card 1 is effectively missing.
- **report_page.dart:102-104 — period-header color is `AppColors.textPrimary` (#000).** Spec §"Card 1" specifies the title `2월 1주차 사용리포트` is `#3A99F8` (primary). Color delta black-vs-primary on the page hero.
- **report_page.dart:46 — bar chart card is missing its summary text.** Spec §"Card 3 / Header" requires two lines under the title: `화·토·일에 계획보다 많이 사용했어요.` / `월·금에는 계획보다 적게 사용하는 날이 많았어요.` (gray400, Label/Medium). Impl renders only the bare title `주간 분석` (which itself does not match the spec literal `이번주 사용 분석`).
- **report_page.dart:211 — bar chart title literal is `주간 분석`.** Spec §"Card 3 / Header" literal is `이번주 사용 분석`. String mismatch.
- **report_page.dart:124 — plan card title literal is `나의 시간 계획`.** Spec §"Card 2 / Header column" requires caption `2월 1주차 나의 계획은` (gray400, Label/Medium 14) **plus** big stat `주 21시간`. Impl drops the date-scoped caption and replaces the heading text. Missing element.
- **report_page.dart:130-135 — `주 ${plan.totalHours}시간` uses `primary` color.** Spec specifies `#050505` (textBlack / textPrimary). Color delta blue-vs-near-black on the big stat.
- **report_page.dart:163-167 — day-set row text uses `headlineBold` (`gray800`).** Matches spec for day label. *However* the hour value rendering `'${daySet.hoursPerDay}시간'` (line 177) is a single concatenated string. Spec §"Card 2" calls for `H 시간 MM 분` with the number in SemiBold and the unit (`시간`/`분`) in Regular, plus an explicit `분` group. Impl ignores minutes entirely (no minutes field on `DaySetPlan`) and skips the weight differentiation between number and unit.
- **report_page.dart:251-262 — delta chips are full-width rounded rectangles with leading day name only.** Spec §"Card 3 / Per-day breakdown list" requires a full `BridgeDayRow` per day: `[dayLabel] | [hours]시간 [mins]분 [optional deltaChip]` (gray100 tile, divider, hours, then a *small* trailing delta chip with triangle icon). Impl renders ONE wide tonal pill per day with the message embedded as text (`월 -2시간 (적게)`), no hours, no divider, no triangle icon. Structural mismatch — the per-day breakdown list is missing; only a flattened delta pill remains.
- **report_page.dart:255,260 — delta sign computation collapses minutes via `(deltaMinutes / 60).round()` and emits `+/-N시간`.** Spec uses absolute `2시간` text without sign, paired with a triangle direction icon (UP/DOWN/dash). The current text `+2시간 (많이)` / `-2시간 (적게)` does not match spec wording or visual treatment.
- **report_page.dart:295-316 — pie chart card omits the spec's compliance header label structure.** Spec §"Card 4 / Header" gives the title `계획 이행률 50%` as a single `20 SemiBold` line in `textBlack`. Impl renders the title via `BridgePieChart.complianceRatePct` which builds the row at bridge_pie_chart.dart:82-100 using `headlineMedium` (18) for `"계획 이행률 "` and `headlineBold` (18) for `"50%"` (primary color). Size delta 20→18; weight split mid-line instead of single-weight bold.
- **report_page.dart:295 — pie chart wrapped in `Center` aligned at top of card; legend is placed *below*.** Spec §"Card 4" places the legend block *to the left* of the pie ("vertical color-dots strip ... left of pie") in a side-by-side layout. Impl is vertically stacked.
- **report_page.dart:323-331 — legend labels use `AppColors.gray300`.** Matches spec (Caption/Medium `#A7ACB2`). PASS.
- **report_page.dart:319-321,323-325,327-330 — legend label texts:** Impl uses `계획대로 사용한 날`, `계획보다 많이 사용한 날`, `계획보다 적게 사용한 날`. Match spec verbatim. PASS.
- **report_page.dart:381 — suggestion card title `AI 조정 제안`.** Matches spec literal. PASS. But the spec also requires a caption above it: `다음주는 이렇게 조정해보자` (gray400, Label/Medium 14). Caption is missing.
- **report_page.dart:440-457 — suggestion delta chip wording.** Spec §"Card 5 list" specifies a small `BridgeDeltaChip` with triangle + `N시간` (positive/destructive variants) or on-plan line. Impl renders a tonal pill with `+2시간` / `-2시간` / `계획대로`. The bg for positive uses `primarySoft` with `positive` fg (line 442-446) — color combo is novel relative to spec which calls for triangle icon + colored text only (no chip bg). Visual treatment mismatch.
- **report_page.dart: missing footer CTA.** Spec §"Footer (`750:11990`, h=117)" requires a primary CTA button `다음주 계획 짜러가기 →` (327×54, radius 8, `headlineMedium`, white). Not rendered.
- **report_page.dart:7-8,15,49-50 — card order/inventory.** Spec §"Layout (top → bottom)" enumerates 5 cards: Intro → Plan → Bar → Pie → Suggestion → Footer button. Impl renders 4 cards + bare period header (no Card 1, no Footer). Missing two regions.
- **bridge_bar_chart.dart:130-149 — x-axis ticks render via `bottomTitles` only.** Spec §"Card 3 chart" calls for both an x-axis baseline (`imgXAxisLine`) and a y-axis vertical line (`imgLeftSideYAxis`). Impl sets `borderData: FlBorderData(show: false)` (line 117) — no axis lines drawn. Visual delta: spec shows L-shape chart frame, impl shows floating bars.
- **bridge_bar_chart.dart:54-58 — `_actualColor` returns `primary` when on-plan.** Spec §"Per-day breakdown list" defines "on plan" as a wave/dash line (`imgLine2`) with no rendered delta number — for the bar chart itself the planned and actual rods would be the same height. Using `primary` for both rods on on-plan days makes the actual rod blend with the planned rod, which is acceptable visually but worth flagging.
- **bridge_pie_chart.dart:178-181 — % labels use `slice.color` (matching slice).** Spec §"Card 4 chart" specifies the labels themselves in the slice color: `20%` positive green, `50%` primary blue, `30%` destructive red. Matches. PASS.

### Notes (not pass/fail)
- Card padding `EdgeInsets.all(20)` (report_page.dart:71) — spec gives plan card padding `19h / 18v` and other cards vary. Within 1-2 px of spec; acceptable.
- `_ReportCard` shadow has `blurRadius: 8`; spec calls for `2`/`2.5`. Visual softness delta — shadow appears more diffuse than Figma.
- `BridgePieChart` uses solid pie (no donut center); spec describes it as "3-slice pie chart (visually rendered with slight donut feel via the centered shadow)". Solid pie + no inner shadow → minor visual delta.

---

## 3) Recommended fixes (prioritized)

### Tier 1 — Structural / content (blocks "implements Figma" claim)
1. **Add Card 1 (Weekly Intro) to report_page.dart** — caption + primary-colored title + `primarySoft` speech-bubble (4 spec lines, gray500 captionMedium) + polygon tail + 44×43 cat illustration asset. Requires `BridgeSpeechBubble` widget per spec catalog.
2. **Add footer CTA `다음주 계획 짜러가기 →`** — primary button 327×54, `buttonRadius=8`, `headlineMedium`/white. Below the 5 cards, above SafeArea.
3. **Rebuild Card 3 per-day breakdown as `BridgeDayRow`s** (gray100 tile, day label, divider, `H시간 MM분`, trailing `BridgeDeltaChip` with triangle icon). The current flattened tonal-pill row collapses three Figma elements into one.
4. **Replace notifications mock with the 6 spec-verbatim tiles** in spec order (weeklyReport, timeSetup, missionComplete-AI, missionComplete-parent, missionRejected-parent, missionRejected-AI) using the literal Korean strings from `06-notifications.md` §"Texts (verbatim)".
5. **Fix empty-state copy & typography** — render `확인하지 않은 알림이 없습니다.` in `AppTypography.headlineMedium` (Medium 18) per spec.

### Tier 2 — Color & typography token compliance
6. **Switch `BridgeNotificationCategory.missionComplete` chip color from `cautionary` (#FF9200) to `secondaryYellow` (#FFCC33).** Token already exists in `app_colors.dart:67`; just swap in `bridge_notification_tile.dart:87`. Removes orange-vs-yellow drift on two tiles.
7. **Fix plan-card stat color: `주 21시간` should be `textPrimary` (#050505), not `primary`.** report_page.dart:133.
8. **Fix period-header color: `2월 1주차 사용리포트` should be `primary` (#3A99F8), not `textPrimary`.** report_page.dart:103.
9. **Add missing card captions/summaries**: Card 2 caption `2월 1주차 나의 계획은`; Card 3 two summary lines (`화·토·일에 계획보다 많이 사용했어요.` / `월·금에는 계획보다 적게 사용하는 날이 많았어요.`); Card 5 caption `다음주는 이렇게 조정해보자`. All in `labelMedium` / `gray400`.
10. **Rename Card 3 title `주간 분석` → `이번주 사용 분석`** (report_page.dart:211).

### Tier 3 — Visual polish
11. **Render notification tile category icons as colored badge chips** (solid colored circle behind glyph) per spec §"Notification tile structure / Icon", instead of bare Material icons.
12. **Reposition pie-chart legend to the left of the pie** (side-by-side `Row`) per spec §"Card 4".
13. **Re-design suggestion delta chip** as triangle + text only (no chip bg), or align bg with the per-day-breakdown chip family. Current `primarySoft + positive` combo is invented.
14. **Plan day-set rows: support minutes + split number vs unit text weights** (`SemiBold 18` number + `Regular 18` unit `시간`/`분`).
15. **Restore bar-chart axis lines** by enabling left + bottom borders on `FlBorderData` (or draw via `imgLeftSideYAxis`/`imgXAxisLine` assets).
16. **Drop the extra border on `BridgeConfirmDialog`** (bridge_confirm_dialog.dart:104) — spec card has shadow only, no 1 px gray200 ring.
17. **Tighten notification list separator from 12 → 15** (notifications_page.dart:86) to match spec `gap: 15`.
18. **Tighten pie-chart card title typography**: render `계획 이행률 NN%` as a single `heading2Bold` line in `textPrimary` (with the `NN%` segment colored `primary`), not split across two `headline*` styles (bridge_pie_chart.dart:82-100).
