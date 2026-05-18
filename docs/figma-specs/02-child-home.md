# Child Home (자녀 대시보드) — Figma Spec

File: `tzJjQmXtXO7vGlfCT9SASu`
Frame width: 375. Container left/right pad: **24**.
Screen background: `#F5F7FA` (= `AppColors.gray100`).

---

## 홈 — 자녀 대시보드 (`426-20978`)

Variant: `scr/child-home-v1`. Empty / pre-mission state. Same layout, but cards are placeholders. Use this to validate "first run" copy and the "+" call-to-action.

### Layout (top → bottom)
| Y (top) | Region | Notes |
|---|---|---|
| 0 | Status Bar | iOS notch/time/network/wifi/battery, h=44 |
| 56 | 상단바 (Top Bar) | left=24, right=24, h=32. Space-between row: `MyPageButton` (36×26) ↔ `NotificationIcon` (32×32) |
| 108 | Container | left=24, w=327, vertical `Column` with `gap: 50` |
| 108 | 오늘의 시간 (block 1) | h=223. Stack: header row at y=0 + white card at y=48 (h=175) |
| 381 | 오늘의 미션 (block 2) | h=281. Header row + centered "empty" copy at y=98 |
| bottom 0 | UI Bar (home indicator) | h=32 |

### "오늘의 시간" card (empty state)
- Header row (w≈326): left = title `"오늘의 시간"` + settings-cog icon (20px, `#A7ACB2`); right = `"사용 리포트"` link.
- Card: bg `#FFFFFF`, radius **16**, padding `28h / 20v`, shadow `0 4 4 rgba(217,217,217,0.5)`.
- Content: a centered 40×40 circular plus button — bg `#EBF5FE`, plus stroke `#3A99F8` (2px wide, 18px long).

### "오늘의 미션" card (empty state)
- Header row: `"오늘의 미션"` (left) ↔ status pill `"0개 완료 | 0"` (right).
  - "0개 완료" = `#47484B`, divider = vertical 1×14 line `#D5D8DE`, "0" = `#D5D8DE`.
- Empty body: centered text `"아직 등록된 미션이 없어요"` at y≈98, color `#777A7F`.

### Texts (verbatim)
- `오늘의 시간`
- `사용 리포트`
- `오늘의 미션`
- `0개 완료`
- `0`
- `아직 등록된 미션이 없어요`
- `my`

### Colors used
| Hex | Token | Note |
|---|---|---|
| `#F5F7FA` | `AppColors.gray100` | screen bg |
| `#FFFFFF` | `AppColors.white` | card bg |
| `#000000` | `AppColors.black` | title text |
| `#2F3032` | `AppColors.gray800` | `my` text + left border |
| `#47484B` | `AppColors.gray700` | "0개 완료" |
| `#91969E` | `AppColors.gray400` | "사용 리포트" link |
| `#777A7F` | `AppColors.gray500` | empty body copy |
| `#D5D8DE` | `AppColors.gray200` | divider + "0" |
| `#A7ACB2` | `AppColors.gray300` | settings cog |
| `#3A99F8` | `AppColors.primary` | plus button stroke |
| `#EBF5FE` | **NEW** | plus-button bg ("Button/Blue/Light") |
| `rgba(217,217,217,0.5)` | **NEW** | card drop-shadow tint |

### Typography
| Use | Style | Token |
|---|---|---|
| Section title (`오늘의 시간`, `오늘의 미션`) | Pretendard SemiBold 20 / 1.4 / -0.24 | `AppTypography.heading2Bold` |
| Link / status text (`사용 리포트`, `0개 완료`, `0`, `my`) | Pretendard SemiBold/Regular 14 / 1.429 / +0.203 | `AppTypography.labelBold` / `labelRegular` |
| Empty body | Pretendard Medium 14 / 1.429 / +0.203 | `AppTypography.labelMedium` |

### Icons / assets (filename hints from `data-name`)
- `Settings Icon` (20×20 mask, gray-300)
- `알림` bell (32×32, `Union` + `Ellipse39` notification dot)
- `My Page Icon` — text `my` with 2px left border, no SVG
- `plus` (inline 18×2 strokes inside 24×24 circle)
- Status bar glyphs (`Network Signal / Light`, `WiFi Signal / Light`, `Battery / Light`) — system, ignore

### Interactions / states
- `my` → push `/mypage` (already wired).
- Notification bell — no destination in Figma; v1 omits the red badge dot.
- `사용 리포트` text — appears tappable (no underline), no target spec'd.
- `+` button — opens "add today's time" sheet (inferred).
- Settings cog beside title — opens time settings (inferred).

### Reusable component candidates
- `TopBar` (`my` + bell + optional badge)
- `SectionHeader` (title + trailing widget: cog / link / count pill)
- `EmptyStateCard` (white rounded-16 card, shadow, centered child)
- `AddCirclePlusButton` (40px, blue-tint bg)
- `MissionCountBadge` (`{n}개 완료 | {total}` with vertical divider)

---

## 홈 2 — 변형 (`426-21005`)

Variant: `scr/child-home-v2`. Populated state. Same chrome as v1; differences are the time card body and a 5-row mission list.

### Layout deltas vs v1
- Container `top: 118` (v1 = 108) — pushed down 10px.
- 오늘의 시간 card body shows a dual-ring donut + time labels (no plus button, no "사용 리포트" right link).
- 오늘의 미션 region grows to **h=520** to hold the list.

### "오늘의 시간" card (populated)
- Container Row: `gap: 40`, inner width 265.
- Left: `Chart Container` 124×124 with `Inner Chart Container` 92×92 offset by (16, 16). Dual ring donut.
  - Outer ring: radius 55, stroke 14, base `#EDEEF1`, progress `#3A99F8`.
  - Inner ring: radius 39, stroke 11, base `#EDEEF1`, progress `#FFBF00`.
  - Start angle = -π/2 (12 o'clock), clockwise.
- Right: `Time Details Container` w=105, `gap: 16` column.
  - `기본시간` label (Medium 14, `#3A99F8`) + value `01:30` (SemiBold 24, `#3A99F8`, line-height 1.364, letter-spacing -0.466).
  - `보너스시간` label (Medium 14, `#FFBF00`) + value `00:30` (same scale, `#FFBF00`).

### "오늘의 미션" list
- Header row identical to v1 but `2개 완료` (gray-700) and total `4` (gray-200).
- List: vertical `Column` `gap: 12`, 5 items, each 327×84.
- `MissionField` = white rounded-16 card, padding `19h / 18v`, inner row `gap: 19`:
  - Left: 48×48 category icon (`청소` SVG — broom illustration).
  - Middle: title `방청소 하기` (Medium 16, `#2F3032`, h=1.5, ls +0.0912) + subtitle `1시간 지급` (Regular 12, `#777A7F`, h=1.334, ls +0.302).
  - Right: 24×24 status icon (see states).
- Completed variant: card bg `#EDEEF1`, icon opacity 0.3, title+subtitle `#A7ACB2` with strikethrough.

### Mission status icons (`체크`)
| State | Annotation in Figma | Visual |
|---|---|---|
| 미완료 (pending check) | default empty | gray-200 ring with check glyph |
| 반려 (rejected) | "수행인증을 했으나, 확인에 통과되지 않음" | red ring with X (`Vector83`/`Vector84` × through `Ellipse42`) |
| 확인중 (reviewing) | "AI 혹은 부모 확인 대기중" | green/spinner ring (`Frame7317`) |
| 완료 (completed) | "수행인증을 했고, 확인에 통과한 상황" | yellow ring with check (`Ellipse40` + `Vector81`) |

### Texts (verbatim, additions to v1)
- `기본시간`, `01:30`
- `보너스시간`, `00:30`
- `2개 완료`, `4`
- `방청소 하기`, `1시간 지급` (×5)

### Colors used (deltas to v1)
| Hex | Token | Note |
|---|---|---|
| `#FFBF00` | **NEW** | bonus-time accent ("amber") — used for inner donut + bonus labels |
| `#EDEEF1` | **NEW** | completed mission card bg + donut base ring ("Gray/gray-150") |
| `#A7ACB2` | `AppColors.gray300` | completed mission text |
| `#181818` | **NEW** (≈ gray-900 alt) | reported as "주문제작케이크/GRAY/G-900" — likely accidental, treat as `AppColors.gray900` (`#171818`) |
| `#006FFD` | **NEW** | "Highlight/Darkest" — present in style metadata, no visible use |

Mission status icon fills (inferred, need designer confirmation):
- rejected → reuse `AppColors.destructive` (`#FF4242`)
- reviewing → green ring; current impl uses `#16BF40` (vs token `AppColors.positive` `#00BF40` — minor delta)
- completed → yellow ring; current impl uses `#FFD980` (no token)

### Typography (deltas to v1)
| Use | Style | Token |
|---|---|---|
| Time value (`01:30`, `00:30`) | Pretendard SemiBold 24 / 1.364 / -0.466 | `AppTypography.heading1Bold` |
| Time label (`기본시간`, `보너스시간`) | Pretendard Medium 14 / 1.429 / +0.203 | `AppTypography.labelMedium` |
| Mission title | Pretendard Medium 16 / 1.5 / +0.0912 | `AppTypography.bodyMedium` |
| Mission subtitle | Pretendard Regular 12 / 1.334 / +0.302 | `AppTypography.captionRegular` |

### Icons / assets
- `청소.svg` — broom illustration, 48×48 (already in `assets/icons/`).
- `체크` (24×24, four variants: pending / rejected / reviewing / completed). Currently drawn programmatically.
- Donut rings — `CustomPaint`, no asset.

### Interactions / states
- Tapping a mission field — Figma marks card as `cursor-pointer`. No target spec'd; presumably opens mission detail / proof upload.
- Completed cards are visually disabled (no tap target inferred).
- Status icon is decorative only; no separate tap target.

### Reusable component candidates
- `DualRingDonut` (radii, strokes, two colors, two progress %).
- `TimeDetailGroup` (label/value pair with color).
- `MissionCard` (icon + title + subtitle + trailing status; supports 4 states).
- `MissionStatusIcon` (4 enum variants).
- `MissionCountBadge` (shared with v1).
- `SectionHeader` (shared with v1).

---

## Deltas vs current `lib/features/child_home/presentation/pages/child_home_page.dart`

The current page already covers both variants well. Concrete deltas to align with Figma:

1. **Container top offset** — current code uses one fixed `SizedBox(height: 12)` then `_TopBar`. Figma: top-bar y=56 (44 status + 12), container y=108 (v1) or y=118 (v2). For v2 (`hasContent=true`), bump the gap between top-bar and content by ~10px (currently 30, should be 40).
2. **Notification dot color** — code uses `AppColors.destructive` `#FF4242`. Figma v1 shows no badge in the bell SVG; v2 also has no red dot, only `Vector` accent. Decide whether badge is product-driven; if kept, document as a delta.
3. **Reviewing status color** — code `#16BF40` vs token `AppColors.positive` `#00BF40`. Swap to the token (or confirm the variant) for consistency.
4. **Completed status ring color** — code `#FFD980` (hard-coded). Figma uses the bonus-time amber family; consider tokenizing as `bonusTime`/`amber` `#FFBF00` with a 0.5 tint, or introduce a `AppColors.amber050` token.
5. **Bonus-time accent** — `#FFBF00` is hard-coded in two places (`_TimeDetails`, donut painter). Add `AppColors.bonus = #FFBF00` token and reference it.
6. **Completed-card bg / donut base** — `#EDEEF1` hard-coded in three places. Promote to `AppColors.gray150` token (Figma calls it `Gray/gray-150`).
7. **Plus-button bg** — `#EBF5FE` hard-coded. Promote to `AppColors.primaryTint` (Figma "Button/Blue/Light").
8. **Card radius** — code uses 16; `AppTokens.cardRadius` is 28. Either add a `AppTokens.cardRadiusSmall = 16` constant or accept the inline literal (it's the only radius used on every card in this screen).
9. **Card shadow** — code `Color(0x80D9D9D9)` is correct (= rgba(217,217,217,0.5)), but consider extracting to `AppTokens.cardShadow`.
10. **Settings cog** — current `Icons.settings` (Material) doesn't match Figma's lighter, outlined cog (`Fill` mask asset). Consider exporting the Figma SVG into `assets/icons/settings.svg`.
11. **Status icon glyph sizes** — code draws 15px Material icons; Figma uses custom 6–10px vector strokes. Visually close but not pixel-perfect.
12. **Mission empty body Y** — Figma centers at y=98 inside the 281-tall block. Current code uses `top: 78` for `'오늘의 미션'` and `top: 88` for `'미션 현황'`. Adjust toward 90–98 if matching Figma v1 exactly.
13. **`사용 리포트` link** — Figma color is `#91969E` (gray-400), already correct in code.
14. **No code change needed** for: layout structure, top-bar, `my` button border, dual-ring donut geometry, mission list structure, copy strings — all already match.

### New design tokens to add (proposed)
```dart
// AppColors
static const Color gray150       = Color(0xFFEDEEF1); // Figma "Gray/gray-150"
static const Color primaryTint   = Color(0xFFEBF5FE); // Figma "Button/Blue/Light"
static const Color bonus         = Color(0xFFFFBF00); // bonus-time amber
static const Color highlightDark = Color(0xFF006FFD); // "Highlight/Darkest" (unused yet)

// AppTokens
static const double cardRadiusSmall = 16;
static const BoxShadow cardShadow = BoxShadow(
  color: Color(0x80D9D9D9), offset: Offset(0, 4), blurRadius: 4,
);
```
