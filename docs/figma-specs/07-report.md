# Usage Report (사용 리포트) — Figma Spec

File: `tzJjQmXtXO7vGlfCT9SASu`
Frame width: 375. Container left/right pad: **24**.
Screen background: `#FAFBFC` (= `AppColors.gray050`).

---

## 사용 리포트 (`662:11497`)

Screen name in Figma: `scr/child-weekly report`. This is the **weekly** report variant
(period selector is implicit — title shows "2월 1주차 사용리포트"; design doesn't expose
day/week/month tabs at this node, only the weekly view).

### Layout (top → bottom)
| Y (top) | Region | Notes |
|---|---|---|
| 0 | Status Bar | h=44 |
| 44 | `CmpTopbar` | h=52, title `"사용 리포트"` centered, left back button (24×24) |
| 96 | Scroll container (Side Panel) | left=24, w=327, vertical `Column` with `gap: 20`, scroll height ~2462 |
| 96 | **Card 1** — Weekly Intro / 물음표 | h=232, white card, radius **16** |
| 268 | **Card 2** — Plan Summary (`Plan Container`) | h=364, white card, radius **16**, padding `19h / 18v` |
| 652 | **Card 3** — Weekly Analysis (graph + per-day list) | h=859, white card, radius **16** |
| 1531 | **Card 4** — Compliance (pie chart) | h=318, white card, radius **16** |
| 1869 | **Card 5** — Adjustment Suggestion (`AI 조정 제안`) | h=455, white card, radius **16** |
| bottom 117 | Footer block | primary button `"다음주 계획 짜러가기 →"` (327×54, radius 8) + UI Bar (h=32) |

All white cards: bg `#FFFFFF`, radius **16**, drop-shadow `0 4 2 rgba(0,0,0,0.1)` (graph/adjustment cards) or `0 4 2.5 rgba(0,0,0,0.1)` (intro card).
Inner day-row tiles (`Day Group Container`): bg `#F5F7FA` (gray100), radius **16**, padding `18h / 15v`, h=45.

### Card 1 — Weekly Intro (`750:11937`)
- Header (top-left, padding 19/18):
  - Caption `"이번주 나는 어떻게 사용했을까?"` — `#91969E`, Label/Medium 14.
  - Title `"2월 1주차 사용리포트"` — `#3A99F8` (primary), Heading 2/Bold 20 SemiBold.
- Speech-bubble container: bg `#E1F0FE` (NEW light blue), radius 16, inside it 4 lines (Caption/Medium 12, color `#777A7F`):
  - `내 기존 계획을 확인하고,`
  - `계획대로 사용했는지,`
  - `계획대로 사용하지 못했다면 그 이유는 무엇인지,`
  - `다음주에 어떻게 조정하는 것이 좋을지 생각해봐요!`
- Bubble has a small `Polygon` tail pointing down-right.
- Cat illustration (44×43) bottom-right corner (image asset `imgCatIllustration`).

### Card 2 — Plan Summary (`662:11502`)
- Header column:
  - Caption `"2월 1주차 나의 계획은"` — `#91969E`, 14 Medium.
  - Big stat `"주 21시간"` — `#050505`, 20 SemiBold.
- Three `Day Group Container` rows (gray100 tile each):
  - `월, 수, 금` — `7 시간 00 분`
  - `화, 목` — `7 시간 00 분`
  - `토, 일` — `7 시간 00 분`
- Day text: 18 SemiBold `#2F3032`. Vertical divider line between day chip and hour: 1×22, `Vector1`.
- Hours: number `SemiBold` + unit (`시간` / `분`) `Regular`, both 18, `#2F3032`. Gap between hour and minute groups = 15; inside group gap = 10.

### Card 3 — Weekly Analysis (`662:11578`)
- Header:
  - Title `"이번주 사용 분석"` — `#050505`, 20 SemiBold.
  - Two lines of summary, `#91969E`, 14 Medium:
    - `화·토·일에 계획보다 많이 사용했어요.`
    - `월·금에는 계획보다 적게 사용하는 날이 많았어요.`
- **Bar chart** (`Usage Graph Container`, w=299, h=168):
  - Y axis on left (`imgLeftSideYAxis` — vertical line, no numeric labels rendered as text; the chart `imgData` is rasterized in Figma).
  - X axis line at bottom (`imgXAxisLine`).
  - X axis tick labels: `월 화 수 목 금 토 일` — Caption/Regular 12, `#91969E`, gap between ticks ≈ 30.5.
  - Bars per day rasterized as a single image (`imgData`); each day appears to render two values (planned vs actual) — implement as grouped bars: planned color `#3A99F8` (primary), over-used color `#FF4242` (destructive), under-used color `#00BF40` (positive). Bar height area = 119px.
- **Per-day breakdown list** (7 `Day Group Container` rows, gray100 tiles, below the chart). Each row: day label · divider · `H 시간 MM 분` · optional usage delta chip on the right.
  - Delta chip: 12×12 triangle icon + text `"N시간"`, Caption/Medium 12.
  - Triangle UP (flipped) + color `#FF4242` (destructive) = over plan.
  - Triangle DOWN + color `#00BF40` (positive) = under plan.
  - Wave/dash line (`imgLine2`, 14.7px) = on-plan (no delta number rendered).
- Mock per-day data captured from Figma (all show `7 시간 00 분`; deltas shown below):
  | Day | Hours | Delta chip |
  |---|---|---|
  | 월 | 7시간 00분 | `2시간` positive (`#00BF40`) — under |
  | 화 | 7시간 00분 | `2시간` destructive (`#FF4242`) — over |
  | 수 | 7시간 00분 | line (on plan) |
  | 목 | 7시간 00분 | line (on plan) |
  | 금 | 7시간 00분 | `2시간` destructive — over |
  | 토 | 7시간 00분 | `3시간` destructive — over |
  | 일 | (implied, scrolls) | — |

### Card 4 — Compliance (`662:11551`)
- Header title: `"계획 이행률 50%"` — `#050505`, 20 SemiBold.
- Legend block (left of pie): vertical color-dots strip (5px wide, h=43, `imgEllipseGroupContainer`) + 3 labels, Caption/Medium 12, `#A7ACB2`:
  - `계획대로 사용한 날`
  - `계획보다 많이 사용한 날`
  - `계획보다 적게 사용한 날`
- **Donut/Pie chart** (`Pie Chart`, 124×124, rasterized `imgPieChart`):
  - Three slices with percentage labels overlaid:
    - `20%` at (80, 13.5) — `#00BF40` (positive) = 계획대로
    - `50%` at (216, 77.5) — `#3A99F8` (primary) = 계획보다 많이
    - `30%` at (60, 119.5) — `#FF4242` (destructive) = 계획보다 적게
  - Chart shadow: `0 4 1.5 rgba(0,0,0,0.15)`. Wrapper has `0 4 4 rgba(217,217,217,0.5)` drop shadow.

### Card 5 — Adjustment Suggestion (`662:11585`)
- Header:
  - Caption `"다음주는 이렇게 조정해보자"` — `#91969E`, 14 Medium.
  - Title `"AI 조정 제안"` — `#050505`, 20 SemiBold.
- 4 `Day Group Container` rows (same component as Card 3 list):
  - `월, 금` — `7 시간 00 분` — delta `2시간` positive (under-plan recommendation)
  - `토, 일` — `7 시간 00 분` — delta `2시간` destructive
  - `화, 목` — `7 시간 00 분` — line (on plan)
  - `수` — `7 시간 00 분` — line (on plan)

### Footer (`750:11990`, h=117)
- Primary CTA button: bg `#3A99F8`, w=327, h=54, radius **8**, label `"다음주 계획 짜러가기 →"` — Headline/Medium 18, white.
- iOS home indicator below.

### Texts (verbatim, Korean)
- Topbar: `사용 리포트`
- Card 1: `이번주 나는 어떻게 사용했을까?`, `2월 1주차 사용리포트`, `내 기존 계획을 확인하고,`, `계획대로 사용했는지,`, `계획대로 사용하지 못했다면 그 이유는 무엇인지,`, `다음주에 어떻게 조정하는 것이 좋을지 생각해봐요!`
- Card 2: `2월 1주차 나의 계획은`, `주 21시간`, `월, 수, 금`, `화, 목`, `토, 일`, `시간`, `분`
- Card 3: `이번주 사용 분석`, `화·토·일에 계획보다 많이 사용했어요.`, `월·금에는 계획보다 적게 사용하는 날이 많았어요.`, `월 화 수 목 금 토 일`, `2시간`, `3시간`
- Card 4: `계획 이행률 50%`, `계획대로 사용한 날`, `계획보다 많이 사용한 날`, `계획보다 적게 사용한 날`, `20%`, `50%`, `30%`
- Card 5: `다음주는 이렇게 조정해보자`, `AI 조정 제안`
- Button: `다음주 계획 짜러가기 →`

### Colors (cross-ref + NEW)
| Hex | Token | Usage |
|---|---|---|
| `#FAFBFC` | `AppColors.gray050` | Scaffold bg |
| `#FFFFFF` | white | Card bg |
| `#F5F7FA` | `AppColors.gray100` | Day-row tile bg |
| `#3A99F8` | `AppColors.primary` | Title accent, primary slice, CTA, 50% label |
| `#E1F0FE` | **NEW** `AppColors.primary050` (연한 하늘) | Speech bubble bg, also matches button hover token |
| `#C2DFFD` | **NEW** `AppColors.primary100` (조금더 진한 하늘) | From token list (Button Blue/Light :active) — not used on this screen but in tokens |
| `#00BF40` | `AppColors.positive` | Under-plan delta, 20% slice label |
| `#FF4242` | `AppColors.destructive` | Over-plan delta, 30% slice label |
| `#050505` | **NEW** `AppColors.textBlack` (near-black) | Section titles (20 SemiBold) — used here instead of `#171818` |
| `#2F3032` | `AppColors.gray800` | Day-row text |
| `#47484B` | `AppColors.gray700` | (token only) |
| `#777A7F` | `AppColors.gray500` | Bubble body text |
| `#91969E` | `AppColors.gray400` | Caption header, x-axis labels, summary text |
| `#A7ACB2` | `AppColors.gray300` | Legend labels |
| `#D5D8DE` | `AppColors.gray200` | (vertical dividers) |
| `#655B96` | **NEW** `AppColors.lineStyle1` (라인 보라) | "Line Style 1" listed in variable defs — not visibly used on this screen but in tokens |

### Typography
| Style | Spec | Used for |
|---|---|---|
| Heading 2/Bold | Pretendard SemiBold 20 / lh 1.4 / ls -0.24 | Card titles, big stats |
| Headline/Bold | Pretendard SemiBold 18 / lh 1.445 / ls -0.0036 | Day-row hour numbers, day labels |
| Headline/Medium | Pretendard Medium 18 / lh 1.445 | CTA button label |
| Label/Medium | Pretendard Medium 14 / lh 1.429 / ls 0.203 | Caption headers, summary lines |
| Caption/Medium | Pretendard Medium 12 / lh 1.334 / ls 0.3024 | Delta chips, bubble body, slice % labels |
| Caption/Regular | Pretendard Regular 12 / lh 1.334 / ls 0.3024 | X-axis tick labels |

### Chart structure summary
- **Card 3 chart**: vertical grouped bar chart, 7 day-categories on X axis, Y axis vertical line (no rendered text ticks in this node), bars grouped per day (planned vs actual). Implement with `fl_chart` `BarChart`. Series colors: planned `#3A99F8`; over `#FF4242`; under `#00BF40`. No legend rendered above chart — semantics come from the per-day delta chips beneath.
- **Card 4 chart**: 3-slice pie chart (visually rendered with slight donut feel via the centered shadow), 124×124. Slice colors map to plan-compliance categories. Labels positioned outside each slice (absolute-positioned text). Implement with `fl_chart` `PieChart` with `centerSpaceRadius` near 0.

### Period selector
- **Not present at this node.** Title statically reads `2월 1주차 사용리포트`. Treat as weekly-only for v1; period switcher (`일 / 주 / 월`) is out of scope for this spec.

### Interactions
- Tap back arrow → pop to Child Home.
- Tap CTA `"다음주 계획 짜러가기 →"` → navigate to next-week planning flow (parent flow, TBD).
- Vertical scroll over Side Panel (height ~2462) — entire body scrolls; header/topbar fixed.
- No swipe-between-periods interaction (no period tabs in this node).
- Tap pie slice / bar / per-day row — no documented interaction; treat as static for v1.

### Reusable Flutter components to extract
- `BridgeWeeklyReportTopbar` — reuse existing `CmpTopbar` with `title: '사용 리포트'`.
- `BridgeReportCard` — white card, radius 16, shadow `0 4 2 rgba(0,0,0,0.1)`, padding `19h / 18v`.
- `BridgeDayRow` — gray100 tile with `[dayLabel] | [hours]시간 [mins]분 [optional deltaChip]`. Reused across Card 2, Card 3 list, Card 5 — single source of truth.
- `BridgeDeltaChip` — 12px triangle icon + 12-Medium text; variants `over` (red, ▲) / `under` (green, ▼) / `onPlan` (small dash line `imgLine2`).
- `BridgeBarChart` — grouped `fl_chart` BarChart, 7-day weekly axis, planned vs actual series.
- `BridgeCompliancePie` — `fl_chart` PieChart (124×124), 3 slices + side-positioned percentage labels.
- `BridgeSpeechBubble` — `#E1F0FE` bg, radius 16, with `Polygon` tail asset.
- `BridgePrimaryButton` — already exists from earlier specs; reuse for CTA.
- `BridgeWeeklyReportPage` — page assembling all 5 cards inside a `SingleChildScrollView`.
