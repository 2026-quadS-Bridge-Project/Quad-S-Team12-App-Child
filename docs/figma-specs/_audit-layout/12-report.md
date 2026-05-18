# Audit: Report page (사용 리포트) layout

**Target file**: `lib/features/report/presentation/pages/report_page.dart`
**Figma reference**: node `662:11497` (file `tzJjQmXtXO7vGlfCT9SASu`)
**Spec doc**: `docs/figma-specs/07-report.md`
**Supporting files audited**:
- `lib/features/report/data/mock/usage_report_mock.dart`
- `lib/features/report/data/models/usage_report.dart`
- `lib/core/widgets/charts/bridge_bar_chart.dart`
- `lib/core/widgets/charts/bridge_pie_chart.dart`
- `lib/core/widgets/layout/bridge_app_bar.dart`
- `lib/core/theme/app_tokens.dart`, `app_colors.dart`, `app_typography.dart`
- `lib/app/router/app_router.dart` (CTA target route)

This is a **diagnostic audit only — no fixes applied.** Findings below follow the Chain of Thought template `Observation → Root cause → Figma ref → Recommended fix`.

---

## Issue 1: Card 1 — Speech-bubble tail rendered as a triangle outside the bubble, not the Figma `Polygon 1` shape

### Observation
- `report_page.dart:222–232` paints the bubble tail in a sibling `Padding > Align > CustomPaint(size: 12×8)` placed **below** the bubble container in a `Column`. The `_BubbleTailPainter` (lines 238–257) draws three points: `(0,0)`, `(12,0)`, `(4.2,8)` → a horizontal-top triangle pointing down.
- This produces a tail whose flat edge sits at the bubble's bottom edge and apex points straight down (not diagonally down-right).
- The tail is offset only by `EdgeInsets.only(right: 28)` — there is no pixel-perfect attachment to the bubble's bottom border, and the rendering uses a separate Stack row so even a 1-px vertical gap is possible (`Column` default cross-axis stretch with no negative offset).

### Root cause
- `07-report.md:40` states: *"Bubble has a small `Polygon` tail pointing down-right."*
- The Figma asset `Polygon 1` (present at `/Users/yeongj/Quad-S-Team12-App-Child/assets/icons/Polygon 1.svg`) is a true polygon whose tip points down-right (≈45°), not a centered isosceles triangle. The current CustomPaint approximates direction but the apex is at `x = 0.35 * width = 4.2` of a 12-wide box — closer to centered-left than down-right.
- Placement is also wrong: speech-bubble tails should overlap the bubble border (no visible seam) or extend from inside the rounded-radius edge; rendering it in a sibling Column slot guarantees the tail sits **outside** the rounded-rect's bottom border with possible sub-pixel gap.

### Figma reference
`07-report.md` Card 1 section: bubble bg `#E1F0FE` (matched), 4 lines of Caption/Medium 12 (matched), + `Polygon` tail down-right. Cat illustration 44×43 bottom-right (handled via `Positioned`).

### Recommended fix
Two acceptable approaches:
1. Replace `_BubbleTailPainter` with `SvgPicture.asset('assets/icons/Polygon 1.svg', width: 12, height: 8, colorFilter: ColorFilter.mode(AppColors.primarySoft, BlendMode.srcIn))` (the polygon SVG can be tinted; today the asset is solid white). Verify the SVG's intrinsic direction matches Figma.
2. Keep `CustomPaint` but anchor the tail with a negative-top `Transform.translate(offset: Offset(0, -1))` or wrap bubble + tail in a `Stack` with `Positioned(right: 28, bottom: -8, child: …)` so it overlaps the bubble's bottom border by 1 px, and update the path to vertices `(0,0), (12,0), (10,8)` for a clear down-right slope.

---

## Issue 2: Card 1 — Cat illustration is rendered as a single light-blue blob, not the Figma cat artwork

### Observation
- `report_page.dart:158–181` uses `SvgPicture.asset('assets/icons/cat.svg', …)` with a placeholder fallback that draws a `gray100` rounded square.
- Direct inspection of `/Users/yeongj/Quad-S-Team12-App-Child/assets/icons/cat.svg` shows it is a single `<path>` filled `#E1F0FE` (the same color as the speech-bubble bg).
- Result: even when the SVG loads, the "cat" appears as one flat light-blue silhouette, indistinguishable from the bubble color. There are no facial features, ears, or stroke detail visible.
- The code comment at line 176 acknowledges this: `// TODO(report): swap to dedicated cat illustration export (imgCatIllustration) once design exports it.` Per `RULES.md > Implementation Completeness`, TODOs for core visual elements are forbidden.

### Root cause
The asset shipped under `assets/icons/cat.svg` is not the Figma `imgCatIllustration` (per `07-report.md:41`). The current file is a generic light-blue blob — likely a leftover from an earlier mock or an incorrect export. The Figma node should expose a multi-color cat artwork (eyes, body, outline) at 44×43.

### Figma reference
`07-report.md:41`: *"Cat illustration (44×43) bottom-right corner (image asset `imgCatIllustration`)."*

### Recommended fix
Re-export the cat asset from Figma node `750:11937` (Card 1) at 44×43 PNG/SVG and replace `assets/icons/cat.svg`. If a PNG is exported, switch to `Image.asset(...)`. Remove the TODO and the gray100 placeholder once the asset is verified.

---

## Issue 3: Card 1 — Caption text uses dynamic `weekLabel` for the title but ignores spec caption text

### Observation
- `report_page.dart:136–151` renders caption `'이번주 나는 어떻게 사용했을까?'` then title `weekLabel` (which mock supplies as `'2월 1주차 사용리포트'`).
- Card 2 has the same pattern but the caption is hard-coded `'나의 시간 계획'` (`report_page.dart:273`) instead of the Figma spec `'2월 1주차 나의 계획은'` (per `07-report.md:46` and `07-report.md:111`).
- Card 3 spec requires a two-line summary `'화·토·일에 계획보다 많이 사용했어요.' / '월·금에는 계획보다 적게 사용하는 날이 많았어요.'` (`07-report.md:57–59`, `07-report.md:112`). The current code only renders the title `'주간 분석'` (line 360) — neither the spec title `'이번주 사용 분석'` (line 56) nor the two summary lines exist.
- Card 5 spec requires caption `'다음주는 이렇게 조정해보자'` above title `'AI 조정 제안'` (`07-report.md:95–96`). The code renders only `'AI 조정 제안'` (`report_page.dart:584`).

### Root cause
Verbatim copy from the Figma spec (`07-report.md > Texts (verbatim, Korean)`, lines 109–115) was applied to Card 1 only. Cards 2/3/5 ship partial or paraphrased headers, so the page diverges from the design even though the supporting models can hold the strings.

### Figma reference
- Card 2 title text: `07-report.md:46` ("Caption `2월 1주차 나의 계획은` — `#91969E`, 14 Medium" + big stat `주 21시간`).
- Card 3 title + summary: `07-report.md:55–59`.
- Card 5 caption + title: `07-report.md:95–96`.

### Recommended fix
Add caption rows above the big stat / title for Cards 2 / 3 / 5 using `AppTypography.labelMedium.copyWith(color: AppColors.gray400)` (matches Card 1 caption styling). For Card 3 add the two summary lines underneath the title. Source the strings from the model (e.g., extend `UsageReport` with `weeklySummaryLines: List<String>`) rather than hard-coding so future weeks vary.

---

## Issue 4: Card 2 — Day-set divider color/length and hours typography drift from spec

### Observation
- `_PlanDaySetRow` (`report_page.dart:303–333`) renders `1×22 gray200` divider — color matches `07-report.md:51` (`Vector1`) and `app_colors.dart:14` (`gray200 = #D5D8DE` matches the spec's `D5D8DE`).
- However the divider sits between `Expanded(daysLabel) | divider | hoursText` — the days label is `Expanded` (stretches), pushing the divider all the way to the right. Spec (`07-report.md:51–52`) says days text uses 18 SemiBold and the hour group uses `"number SemiBold + unit Regular"` at 18, with inner gaps of 10 and 15 px. The current code emits a single `Text('${daySet.hoursPerDay}시간', …)` in `headlineBold` (`fontWeight w600`) — meaning the `시간` unit renders in **SemiBold**, not the Regular weight Figma specifies for the unit.
- There is also no `분` (minute) component, even though the spec format is `"7 시간 00 분"` (`07-report.md:48–50`). Daily plan minutes are zero in the mock so the visual omission is currently acceptable, but the row format diverges from Card 3/Card 5 rows which use `"H시간 MM분"`, so layouts won't visually align across cards.
- Padding: code uses `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` — spec says `18h / 15v` (`07-report.md:22`, `07-report.md:29`), so tiles are 2 px under-padded horizontally and 3 px under-padded vertically.

### Root cause
The plan row was implemented as a single typography token (`headlineBold`) rather than mixing SemiBold (number) + Regular (unit), and the model stores `hoursPerDay: int` so there is no place to render minutes. Padding constants do not match the `Day Group Container` Figma component (`07-report.md:29`).

### Figma reference
`07-report.md:29` ("inner day-row tiles … padding `18h / 15v`, h=45"), `07-report.md:48–52`.

### Recommended fix
1. Split the hour text into two `Text` runs: `'${hoursPerDay}'` in `headlineBold` + `'시간'` in `headlineRegular`, both `gray800`. Add `'${minutes}'` + `'분'` runs if minutes > 0.
2. Change padding to `EdgeInsets.symmetric(horizontal: 18, vertical: 15)` in **all** `_PlanDaySetRow`, `_DayBreakdownRow`, `_SuggestionRow` widgets (single shared tile component would prevent drift — see Issue 11).
3. Extend `DaySetPlan` with `minutesPerDay` or change `hoursPerDay` to `totalMinutes: int` for consistency with `DailyUsageRow`.

---

## Issue 5: Card 3 — On-plan days drop the chip entirely instead of rendering the `imgLine2` dash/wave

### Observation
- `_DayBreakdownRow` (`report_page.dart:434–438`): `if (!isOnPlan) _DayDeltaTriangleChip(...)`. When `deltaMinutes.abs() <= 5`, **no widget** is rendered on the trailing edge.
- The mock supplies on-plan days for 수, 목, 일 (`usage_report_mock.dart:19, 20, 23`), so 3 out of 7 rows show no trailing affordance at all.

### Root cause
- The Figma spec for the on-plan state uses a small dash/wave line asset (`imgLine2`, 14.7 px) that visually communicates "you stayed on plan" (`07-report.md:69`). It is **not** absent — it is a wave/dash line.
- The current implementation silently omits the marker. The code comment at lines 446–449 acknowledges this: *"we omit the widget entirely rather than render a dash, since that asset is not exported locally."*
- This breaks the visual grid: rows alternate between "has chip" and "blank right edge", whereas Figma keeps every row's right edge populated with either a delta chip or the wave-line.

### Figma reference
`07-report.md:69`: *"Wave/dash line (`imgLine2`, 14.7px) = on-plan (no delta number rendered)."* Cross-references the mock data table at `07-report.md:71–79` where 수 and 목 explicitly show "line (on plan)".

### Recommended fix
Export `imgLine2` as `assets/icons/wave_line.svg` (a short stroked wave or 3-dash sequence ~14.7 px wide). Render it in place of the omitted chip:
```dart
if (isOnPlan)
  SvgPicture.asset('assets/icons/wave_line.svg', width: 14.7, height: 6,
      colorFilter: ColorFilter.mode(AppColors.gray400, BlendMode.srcIn))
else
  _DayDeltaTriangleChip(hours: deltaAbsHours, isOver: isOver),
```

---

## Issue 6: Card 3 — Delta chip uses Material `arrow_drop_up`/`arrow_drop_down` icons, not a 12×12 triangle from Figma

### Observation
- `_DayDeltaTriangleChip` (`report_page.dart:450–481`) renders `Icon(Icons.arrow_drop_up, size: 16, ...)`.
- Material `arrow_drop_up`/`arrow_drop_down` are font glyphs from Material Icons — visually they are small triangles with significant negative padding around them. Setting `size: 16` does not match the spec's `12×12 triangle icon` (`07-report.md:67`).
- Additionally `Icons.arrow_drop_down` is used for the "under-plan" case (`isOver == false` branch, line 464), which renders a down-pointing triangle. The spec says under-plan should be a **down-pointing triangle** colored positive green (`07-report.md:68`) — so the direction is correct but the icon source/size are not.
- The "over" branch uses `arrow_drop_up` (up arrow), but spec line 67 says "Triangle UP (flipped)" — Figma flips a downward triangle to point up. Visually equivalent here, but the metric will not match if the design changes the polygon style.

### Root cause
Using Material icon font for a chip whose dimensions are spec'd as `12×12` produces visual size mismatch (Material icons reserve internal padding, so a `size: 16` icon's glyph is ~12 px tall — accidentally close, but the bounding box is wrong). The Figma spec calls for a stand-alone 12 px polygon.

### Figma reference
`07-report.md:67`: *"Delta chip: 12×12 triangle icon + text `"N시간"`, Caption/Medium 12."*
`07-report.md:68`: triangle UP red (over) / triangle DOWN green (under).

### Recommended fix
Replace Material icons with a `CustomPaint` drawing an equilateral 12×12 triangle (or export Figma's polygon to `assets/icons/triangle_up.svg` / `triangle_down.svg` and tint via `colorFilter`). Reduce `size` to 12. Remove the `SizedBox(width: 2)` and let the chip's tight bounding box drive layout.

---

## Issue 7: Card 3 — Delta hours rounded to nearest hour drops sub-hour deltas

### Observation
- `report_page.dart:404`: `final int deltaAbsHours = (deltaMinutes.abs() / 60).round();`
- For mock data 토 (`actualMinutes: 600, plannedMinutes: 420 → delta +180 → 3시간`) this prints "3시간" — matches spec exactly.
- But for any week with non-hour-aligned deltas (e.g., +90 min would round to "2시간", +30 min would round to "1시간", +20 min would round to "0시간" — printing literally `0시간`!), the chip lies about the actual delta.
- `isOnPlan` threshold is `abs() <= 5`, so a 20-minute delta is still classified as off-plan, and rounding 20 min to 0 hours produces the absurd chip `▲ 0시간`.

### Root cause
The display layer collapses the precision of `DailyUsageRow.deltaMinutes` to an integer hour by rounding. Spec text examples (`2시간`, `3시간`) coincidentally align with hour-aligned mock data — but the production model is in minutes. Once real data flows in this becomes a visible bug.

### Figma reference
`07-report.md:67` says "text `\"N시간\"`" but the Figma mock only ever displays hour-aligned deltas. Real-world usage will produce minute-level values; the design system has no documented sub-hour treatment, so this is an ambiguity to surface.

### Recommended fix
1. Show `Nh Mmin` when the minute remainder is significant, e.g., `${h}시간 ${m}분`, OR
2. Show `< 1시간` when the rounded value would be 0, OR
3. Display in minutes when delta < 60 (`'${deltaMinutes}분'`).
Validate with design before shipping. Today this is **untested for non-hour data** — flag as a quality risk.

---

## Issue 8: Card 3 — Bar chart `fl_chart` setup uses correct 0.69 API but the Y-axis line and Y-tick semantics from Figma are absent

### Observation
- `bridge_bar_chart.dart:108–151` calls `BarChart(BarChartData(...))` with `gridData: FlGridData(show: false)` and `borderData: FlBorderData(show: false)`. The fl_chart 0.69 API is correctly used (no deprecated calls — `BarChartGroupData(x, barsSpace, barRods)`, `BarChartRodData(toY, color, width, borderRadius)`, `AxisTitles(sideTitles: SideTitles(...))` all match 0.69.0).
- However Figma includes a left-side Y axis vertical line (`imgLeftSideYAxis`) and a bottom X axis line (`imgXAxisLine`) — `07-report.md:61–62`. Both are turned off (`borderData: FlBorderData(show: false)`).
- The result: bars float in space with only weekday labels below; the spec calls for two thin axis lines forming an "L" frame.

### Root cause
`borderData: FlBorderData(show: false)` was used wholesale rather than selectively enabling the left + bottom sides.

### Figma reference
`07-report.md:61–62`: *"Y axis on left (`imgLeftSideYAxis` — vertical line, no numeric labels …). X axis line at bottom (`imgXAxisLine`)."*

### Recommended fix
```dart
borderData: FlBorderData(
  show: true,
  border: Border(
    left: BorderSide(color: AppColors.gray200, width: 1),
    bottom: BorderSide(color: AppColors.gray200, width: 1),
  ),
),
```
No numeric Y ticks (already correct via `leftTitles.sideTitles.showTitles: false`).

---

## Issue 9: Card 3 — `_groupsSpace: 12` produces narrower groupings than Figma's ~30.5 px tick spacing

### Observation
- `bridge_bar_chart.dart:51`: `_groupsSpace = 12`.
- `07-report.md:63` documents X-axis tick spacing of "≈ 30.5" px between weekday labels across a 299-px-wide chart container (`07-report.md:60`).
- With 7 groups, two 8-wide rods + 4-wide barsSpace per group → group bandwidth ≈ 20 px + 12 px groupsSpace ≈ 32 px per cell × 7 = 224 px used, leaving 75 px slack distributed by `BarChartAlignment.spaceAround`. The relative spacing will look reasonable, but the planned/actual rod **pair** centers are not necessarily landing under the weekday tick label (which is positioned by `bottomTitles.sideTitles`).
- Specifically: `BarChartAlignment.spaceAround` adds equal padding before the first group and after the last group, but fl_chart 0.69's bottom-title positioning anchors to the group's `x` integer index — not to the visual group center. In practice they align fine for `alignment: spaceAround`, but visual verification is required.

### Root cause
The chart sizes were tuned by eye, not derived from the 299-px Figma container width. There is no width assertion (`SizedBox(width: 299)` wrapper) so the chart will reflow to whatever width the parent provides — could be 287 (with 20 px card padding off 327 width).

### Figma reference
`07-report.md:60` (chart container 299×168), `07-report.md:63` (tick spacing ≈ 30.5).

### Recommended fix
1. Wrap `BridgeBarChart` in a `SizedBox(width: 299)` or `LayoutBuilder` and recompute `_groupsSpace` from `(availableWidth - rods - barsSpace * groups) / (groups + 1)` to honor the 30.5-px tick rhythm.
2. Add a golden test that renders the chart at 327 - 40 = 287 px (card content width) and snapshots it. Currently no golden test exists for this widget.

---

## Issue 10: Card 4 — Pie label radial-padding fixed at 14 px causes labels to clip card edge on the 50% slice

### Observation
- `bridge_pie_chart.dart:56`: `_labelRadialPadding = 14` (constant).
- `bridge_pie_chart.dart:62–63`: label box is `40 × 18` and `stackSize = size + _labelBoxWidth = 124 + 40 = 164`.
- For the 50% slice in the mock (`mid % = 20 + 25 = 45 → angle = -π/2 + 0.9π = 0.4π` ≈ 72° from top, measured clockwise → label sits ~3-o'clock-low position) the label box left edge ≈ `centerX + (62+14) * cos(72°) - 20 = 82 + 76*0.31 - 20 ≈ 85.5`, right edge ≈ `125.5`. Within the 164-px stack: OK.
- BUT the pie chart is centered inside `_ReportCard` which has 20 px internal padding (`report_page.dart:89`). Card content width is `327 - 40 = 287 px`. Stack width is 164 px → centered → 61.5 px slack on each side. Labels fit.
- The 20% slice (계획대로, green, mid% = 10 → angle = -π/2 + 0.2π = -0.3π ≈ -54° → top-right of pie) — label rendered at `(centerX + 76*cos(-54°), centerY + 76*sin(-54°)) = (82+45, 82-61) = (127, 21)`. With label box 40 wide and centered → left edge 107, right edge 147. **Outside the 124-px pie bounds** ✓ but inside the 164-px stack. OK.
- However the spec (`07-report.md:90–91`) places labels at very specific Figma coordinates:
  - `20%` at (80, 13.5) → top-center, *above* the pie
  - `50%` at (216, 77.5) → far right, ≈ 92 px right of pie center
  - `30%` at (60, 119.5) → bottom-left
- Computed positions vs Figma:
  - 20%: computed `(127, 21)` vs Figma `(80, 13.5)` → ~47 px right of where Figma expects. Wrong direction (Figma places it at the **top of the slice**, our math puts it at the slice's mid-angle → top-right because 계획대로 spans 0–20%).
  - 30% (적게 사용, mid% = 20+50+15 = 85 → angle = -π/2 + 1.7π = 1.2π ≈ 216°): cos = -0.81, sin = -0.59 → computed `(82-61, 82-45) = (21, 37)`. Vs Figma `(60, 119.5)` (bottom-left). **Off by ~80 px vertically** — the math places it at top-left, Figma puts it at bottom-left.

### Root cause
The angle math assumes labels sit on a ring at the slice's mid-angle. Figma instead positions labels with bespoke offsets (some inside the slice, some outside, some flipped) — there is no single radial rule. The current implementation will produce **valid but visually different** label positions for every slice configuration.

### Figma reference
`07-report.md:88–91`: per-slice absolute coordinates `(80,13.5)`, `(216,77.5)`, `(60,119.5)` for 20/50/30 respectively. Note `216` exceeds the 124-px pie box → label is fully outside, anchored to the right edge of the card area.

### Recommended fix
Either:
1. Hard-code per-slice label offsets (matches Figma exactly but loses generality).
2. Document the label-positioning algorithm as "auto-radial with `_labelRadialPadding=14`" and accept that it diverges from Figma for non-uniform slice distributions — flag as a known visual divergence.
3. Compute label position based on slice mid-angle but bias offset by slice size (larger slices push label further out). Requires design input.

This is the **largest visual divergence on the page** — recommend a design review before locking the algorithm.

---

## Issue 11: Card 4 — Centered pie + left-aligned column constraint produces asymmetric layout vs Figma's "legend left + pie right"

### Observation
- `_PieChartCard` (`report_page.dart:491–537`) renders `Center(child: BridgePieChart(...))` followed by 3 `_LegendRow` widgets stacked **below** the pie.
- Spec (`07-report.md:82–86`): legend block is on the **left** of the pie, with a vertical color-dots strip (`imgEllipseGroupContainer`, 5 px wide, 43 h) acting as the bullet column.
- Current layout: title above, pie centered, legend below — a top-to-bottom stack.
- Spec layout: title above, then a row of `[legend column] [pie]` side-by-side.

### Root cause
The card uses a vertical `Column` instead of a `Row(crossAxisAlignment: center, children: [legend, pie])`. No `imgEllipseGroupContainer` strip is rendered.

### Figma reference
`07-report.md:82–86` (legend strip on left, 3 labels) + `07-report.md:87` (pie at 124×124 on right).

### Recommended fix
Convert Card 4 body to:
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(child: Column(children: [_LegendRow(...), _LegendRow(...), _LegendRow(...)])),
    SizedBox(width: 16),
    BridgePieChart(...),
  ],
)
```
Render `imgEllipseGroupContainer` either as `Column(children: [Container(width:5, height:5, ...dot), ...])` or export the SVG.

---

## Issue 12: Card 4 — Compliance rate displayed as `complianceRatePct: compliance.overallCompliancePct` resolves to 20% (계획대로 슬라이스), not the spec's 50%

### Observation
- `usage_report.dart:27`: `double get overallCompliancePct => onPlanPct;` returns `onPlanPct = 20.0`.
- `report_page.dart:498`: `complianceRatePct: compliance.overallCompliancePct` → 20.
- `bridge_pie_chart.dart:94`: renders `'계획 이행률 20%'`.
- Figma spec (`07-report.md:82, 113`): title is **`계획 이행률 50%`** — and `50%` corresponds to "계획보다 많이 사용한 날" (primary blue), not "계획대로".

### Root cause
The model's getter assumes "compliance rate = days on plan" (20%). The Figma title shows the **largest slice's** percentage (50% = over-plan days), which is semantically confusing — likely the design uses "이행률" loosely to mean "of the planned hours, what % were actually used" (over + on = 70%) or is simply showing the dominant slice. Either way the current code computes a different number than Figma displays.

### Figma reference
`07-report.md:82`: *"Header title: `\"계획 이행률 50%\"` — `#050505`, 20 SemiBold."*
`07-report.md:113`: verbatim `계획 이행률 50%`.

### Recommended fix
1. Clarify with design what "계획 이행률" measures. Possible interpretations:
   - On-plan days only → 20% (current code).
   - On-plan + over → 70%.
   - Used-hours ÷ planned-hours → ratio (needs additional fields).
2. Update `overallCompliancePct` getter or pass a dedicated `compliancePct: 50` field once defined.
3. Header should also display `계획 이행률 ` in `gray800/inkBlack` SemiBold (currently uses `textPrimary` which is `black`/`labelStrong = #000000` — close to but not the `#050505` `inkBlack` token).

---

## Issue 13: Card 4 — Legend label color mismatch

### Observation
- `report_page.dart:560`: `_LegendRow` uses `AppColors.gray300` (`#A7ACB2`) — matches spec.
- BUT the **dots** in `_LegendRow` (line 549–556) are `10×10` filled circles, while the spec asks for a single vertical 5-wide strip with 3 dots (`imgEllipseGroupContainer`, h=43). Three separate inline dots ≠ a single vertical color strip.

### Root cause
Same as Issue 11 — the layout decision to stack legend rows below the pie forced per-row dots instead of a left-aligned vertical strip.

### Figma reference
`07-report.md:83`: *"vertical color-dots strip (5 px wide, h=43, `imgEllipseGroupContainer`)"*.

### Recommended fix
See Issue 11. If staying with stacked legend rows, at least reduce dot size to 5×5 to match Figma scale.

---

## Issue 14: Card 5 — Suggestion row missing `'7 시간 00 분'` hour column between days label and delta chip

### Observation
- `_SuggestionRow` (`report_page.dart:606–625`) renders `[Expanded(daysLabel)] | [_SuggestionDeltaChip]`.
- Spec (`07-report.md:99–102`) shows each AI suggestion row as: `[days] | [divider] | [7 시간 00 분] | [delta chip]` — i.e., reusing the **same Day Group Container** layout as Card 3.
- The hours column is entirely missing, so suggestion rows look visually different from breakdown rows even though Figma uses the same component (`07-report.md:98`: *"4 `Day Group Container` rows (same component as Card 3 list)"*).

### Root cause
- The model `AiSuggestion` (`usage_report.dart:30–35`) stores only `daysLabel`, `deltaHours`, `tone` — it has no hours field.
- The page renders only what the model exposes, so the hour column is structurally impossible.

### Figma reference
`07-report.md:98–102` (suggestion rows use the same `Day Group Container` as Card 3 — days + hours + delta chip).

### Recommended fix
1. Extend `AiSuggestion` with `plannedHoursPerDay: int` (or `plannedMinutesPerDay: int`).
2. Update `_SuggestionRow` to mirror `_DayBreakdownRow` layout (days + divider + hours + chip).
3. Extract a shared `_DayGroupContainer` widget used by **all three** consumers (Card 2 plan rows, Card 3 breakdown rows, Card 5 suggestion rows) — eliminates the 3-way drift (Issue 4, this issue, and any future change).

---

## Issue 15: Card 5 — `_SuggestionDeltaChip` `positive` tone uses `primarySoft` bg (blue), not a green-soft surface

### Observation
- `report_page.dart:642–647`:
  ```dart
  case AiSuggestionTone.positive:
    bg = AppColors.primarySoft;  // light blue
    fg = AppColors.positive;     // green text
  ```
- Result: a **blue background** with green text. Visually clashes — most design systems pair tone surfaces (green-soft + green-text, red-soft + red-text).
- The destructive branch correctly uses `destructiveSubtle` (light red) + `destructive` (red), but positive uses `primarySoft` (light blue) + `positive` (green).

### Root cause
No `positiveSubtle` / `positiveSoft` token exists in `app_colors.dart` (lines 39–66). The author defaulted to `primarySoft` because no green-tinted surface is available. This is a missing token, not a deliberate choice.

### Figma reference
The spec doesn't explicitly export AI suggestion chip surface colors per tone — but the Figma node should be inspected. The current blue-green pairing is almost certainly unintended.

### Recommended fix
1. Inspect Figma node `662:11585` to confirm the positive-tone chip surface color.
2. Add `positiveSoft = Color(0xFFD3F5DE)` (or whatever Figma exports) to `app_colors.dart`.
3. Update the `positive` switch case to use `positiveSoft`.

---

## Issue 16: Card spacing uses `SizedBox(height: 20)` between cards — matches spec gap (20)

### Observation
- `report_page.dart:53, 55, 57, 59` all use `SizedBox(height: 20)`.
- Spec (`07-report.md:20`): *"vertical `Column` with `gap: 20`"* → confirmed match.
- Card-to-CTA gap is `24` (line 61) — spec footer block has 24+ padding so reasonable.

### Root cause
N/A — this is correct.

### Recommended fix
None. Documenting for completeness.

---

## Issue 17: All cards use `cardRadiusSmall: 16` and shadow `BoxShadow(color: 0x1A000000, offset: (0,4), blur: 8)` — radius matches, shadow does not

### Observation
- `report_page.dart:92`: `BorderRadius.circular(AppTokens.cardRadiusSmall)` → 16. Matches spec (`07-report.md:21–26`: radius **16**). ✓
- `report_page.dart:94–99`: shadow is `color: 0x1A000000` (= black @ 10%), offset `(0, 4)`, blur `8`, spread `0`.
- Spec (`07-report.md:28`):
  - Graph/adjustment cards: `0 4 2 rgba(0,0,0,0.1)` (offset y=4, blur=**2**, color black @ 10%).
  - Intro card: `0 4 2.5 rgba(0,0,0,0.1)` (offset y=4, blur=**2.5**).
- Code uses `blurRadius: 8` — **4× the spec blur**. This produces a much softer, more diffuse shadow than Figma.

### Root cause
A common default of `blurRadius: 8` was used regardless of the Figma spec value. The spec uses tighter blur (2–2.5) for a crisper card edge.

### Figma reference
`07-report.md:28`.

### Recommended fix
Differentiate the two shadow variants:
- Pass an optional `shadowBlur: double = 2` parameter to `_ReportCard`.
- Use `blurRadius: 2.5` for Card 1, `blurRadius: 2` for Cards 2–5.
- Token both into `AppTokens` (e.g., `reportCardShadowBlur`, `reportIntroCardShadowBlur`) so other screens can reuse.
- Consider also documenting that `AppTokens.cardShadow` (`#80D9D9D9`, 50% gray) is **not** what this screen uses — different shadow color (`0x1A000000`, 10% black) — flag the token divergence.

---

## Issue 18: CTA pushes correct route, but the trailing arrow `→` is part of the label string

### Observation
- `report_page.dart:62–68`: `BridgeButton(label: '다음주 계획 짜러가기 →', …, onPressed: () => context.push('/child-home/time-setup/v2'))`.
- Route exists in `app_router.dart:74` and points to `TimeSetupV2RootPage`. ✓
- The arrow `→` is glyphed into the label text. `BridgeButton` accepts a `trailing` parameter (`bridge_button.dart:53`) which would render an icon with 8-px gap — that's the intended slot for the arrow.
- The arrow `→` (U+2192) renders inconsistently across font weights in `headlineMedium` (the button label style) — it can render as a heavy or thin glyph depending on the Pretendard subset shipped.

### Root cause
The arrow is treated as text rather than as an icon. The spec (`07-report.md:106`) shows the arrow in the label, so this is acceptable, but a `trailing: Icon(Icons.arrow_forward, size: 18)` would be more robust and accessible (screen readers would announce "forward arrow" rather than literally reading "오른쪽 화살표").

### Figma reference
`07-report.md:106`: `다음주 계획 짜러가기 →` — verbatim label includes the arrow.

### Recommended fix
Acceptable as-is. If consistency matters, move the arrow to the `trailing:` slot and drop it from the label. Verify Pretendard renders the `→` glyph at 18 Medium without falling back to system font.

---

## Issue 19: ListView scrolls but contents are not constrained to `mobileContentWidth` (327)

### Observation
- `report_page.dart:47–50`: `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)` — gives card content area `327 px` at 375 frame width (`AppTokens.mobileContentWidth = 327`). ✓ for 375-wide canvas.
- On wider canvases (iPad, foldables, web debug), cards stretch to fill — there is no max-width clamp.

### Root cause
The page is built directly with `EdgeInsets.symmetric(horizontal: 24)` rather than a `Center(child: ConstrainedBox(maxWidth: 327, child: ListView(...)))` pattern.

### Figma reference
`07-report.md:4`: *"Frame width: 375."* — this is a mobile-only screen, so the lack of clamp is acceptable for v1.

### Recommended fix
Optional: wrap the ListView in `Center > ConstrainedBox(maxWidth: 375)` for tablet/web debug builds. Not a release blocker.

---

## Issue 20: `BridgeAppBar` is wired via `Scaffold.appBar:` — known status-bar inset bug from audit doc `01-BridgeAppBar.md`

### Observation
- `report_page.dart:44`: `appBar: const BridgeAppBar(title: '사용 리포트')`.
- `_audit-layout/01-BridgeAppBar.md` Issue 1 + Issue 2 explicitly call out this exact file (line 58: `lib/features/report/presentation/pages/report_page.dart:44`) as one of the broken `Scaffold.appBar:` consumers — on notched devices the back button overlaps the status bar.

### Root cause
See `01-BridgeAppBar.md` — `BridgeAppBar` does not include `SafeArea(top: true)` nor extend `preferredSize` by `MediaQuery.viewPadding.top`. Slotting it into `Scaffold.appBar:` causes status-bar overlap on notched devices.

### Figma reference
`07-report.md:19`: status bar h=44 + topbar h=52 → back button at absolute Y ≈ 58. Current rendering puts the back button at Y ≈ 14.

### Recommended fix
Inherit the fix from `01-BridgeAppBar.md` (no per-page change needed once `BridgeAppBar` is patched). Track this as a cross-cutting bug — fixing in one place benefits all 8 affected pages.

---

## Issue 21: `SafeArea` wraps the body but `BridgeAppBar` is outside it — bottom inset (home indicator) may overlap CTA on tall devices

### Observation
- `report_page.dart:45`: `body: SafeArea(child: ListView(...))`.
- `SafeArea` defaults to `top: true, bottom: true, left: true, right: true`.
- ListView's last child is `SizedBox(height: 24)` after the CTA. On devices with a tall home indicator (≥34 px on iPhone 14 Pro), SafeArea inset adds ~34 px below, so the visible gap between CTA and home indicator is `24 + 34 = 58` — acceptable.
- However if `BridgeAppBar` is fixed to consume the top inset (Issue 20 fix), `SafeArea(top: true)` will **double-inset** the top of the body, pushing Card 1 down by another 44 px.

### Root cause
Defensive double-SafeArea handling. After Issue 20 is fixed, this body SafeArea should drop `top: false`.

### Figma reference
N/A (this is platform plumbing).

### Recommended fix
After `BridgeAppBar` is patched per `01-BridgeAppBar.md`:
```dart
body: SafeArea(top: false, child: ListView(...))
```

---

## Summary table

| # | Severity | Card | Issue |
|---|----------|------|-------|
| 1 | 🟡 | 1 | Bubble tail wrong shape/placement |
| 2 | 🔴 | 1 | Cat asset is a flat blob, not the Figma cat |
| 3 | 🟡 | 2/3/5 | Missing caption/title/summary strings from spec |
| 4 | 🟢 | 2 | Hours typography weight + tile padding drift |
| 5 | 🟡 | 3 | On-plan rows render no trailing marker |
| 6 | 🟢 | 3 | Delta chip uses Material icons (size mismatch) |
| 7 | 🔴 | 3 | Sub-hour deltas round to `0시간` chip |
| 8 | 🟡 | 3 | Bar chart missing L-frame axis lines |
| 9 | 🟢 | 3 | Group spacing not derived from 299-px container |
| 10 | 🔴 | 4 | Pie label positions diverge from Figma per-slice offsets |
| 11 | 🔴 | 4 | Pie + legend laid out vertically; spec is side-by-side |
| 12 | 🔴 | 4 | `계획 이행률` shows 20% (mock) but spec text says 50% |
| 13 | 🟢 | 4 | Legend dots oversized vs Figma `imgEllipseGroupContainer` |
| 14 | 🔴 | 5 | Suggestion rows missing hour column (model gap) |
| 15 | 🟡 | 5 | Positive-tone chip uses blue surface + green text |
| 16 | ✓ | all | Card gap 20 px correct |
| 17 | 🟡 | all | Shadow `blurRadius: 8` vs spec 2/2.5 |
| 18 | 🟢 | footer | Arrow as text glyph (works, not robust) |
| 19 | 🟢 | page | No max-width clamp for tablets |
| 20 | 🔴 | page | `BridgeAppBar` known status-bar overlap bug |
| 21 | 🟡 | page | SafeArea will double-inset after Issue 20 fix |

🔴 = critical (visual/data wrong) · 🟡 = important (drifts from spec) · 🟢 = recommended (polish)
