# Bridge_K — Figma Spec: 시간 설정 v1 (Entry + Weekly Setup)

Source: Figma file `tzJjQmXtXO7vGlfCT9SASu`
Frame group: `scr/child-초기 시간설정-*` (3-step wizard: 스케줄 등록 → 주별 시간 분배 → 일별 시간 분배)
Frame size: 375 × 812
Background: `#FAFBFC` (gray050)

**Flow context** (per UI-figma.md): 진입(이 문서) → 스케줄 등록(빈/채움) → 주별 총시간 + 바텀시트 시간 입력 → 분배 완성 → (다음 batch) 일별 분배

This batch covers nodes for the **weekly half** (entry through Step 2 filled).

---

## 시간 설정 진입 (`695:8850`)

Korean frame name: `scr/child-초기 시간설정-단계설명`

### Layout (top → bottom)

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–44   | Status bar | system-rendered (notch, time, signal/wifi/battery) |
| 44–96  | cmp/topbar (`325:17287`) | h=52, padding 22h/5v. Back chevron 24×24 @ left=24, top=14. **Empty title** (propValue="") |
| 205–325 | Title container (`695:8855`) | centered, w=327, gap=40 between title block and subtitle |
| 205–238 | Title `사용시간 설정` (`695:8857`) | Heading1/Bold 24, gray900-ish (`#050505`), text-align center |
| 278–326 | Subtitle 2-line (`695:8858`) | Body/Medium 16, gray500 `#777A7F`, 2 lines centered |
| 368–460 | Steps Container (`695:8859`) | centered, w=140, vertical gap=20 between steps |
| —      | Step row (`695:8860`) | numbered circle (28×28) + label, gap=10 |
| bottom-117 → bottom-63 | CTA button `시작` (`252:4802`) | h=54, w=327 (full minus 24h margin), bg primary `#3A99F8`, white text, radius=8 |
| bottom 0–32 | UI bar (`359:5747`) | iOS home indicator |

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `사용시간 설정` | `695:8857` |
| `한 달 동안 쓸 시간을, 스스로 나눠볼거에요` | `695:8858` line 1 |
| `3단계만 따라오면 끝나요` | `695:8858` line 2 |
| `스케줄 등록` | `695:8862` (Step 1 label) |
| `주별 시간 분배` | `695:8865` (Step 2 label) |
| `일별 시간 분배` | `695:8868` (Step 3 label) |
| `시작` | `252:4803` (CTA) |

### Colors

| Hex | Token | Usage |
|-----|-------|-------|
| `#FAFBFC` | gray050 ✓ | Page bg |
| `#050505` | inkBlack (NEW from 03-mypage) | Title text (`695:8857`) |
| `#777A7F` | gray500 ✓ | Subtitle, step labels |
| `#3A99F8` | primary ✓ | CTA button bg, step circle number text |
| `#FFFFFF` | white ✓ | CTA text |
| `#C2DFFD` | NEW `primarySubtle` (Button/Blue/Light :active) | (declared, used as step circle fill) |

**New token**: `primarySubtle = #C2DFFD` (Figma "Button/Blue/Light :active") — used for step number circle background and progress dots.

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Heading1/Bold | Pretendard SemiBold 24 / line 1.364 / letter -1.94 (×0.01) | Page title |
| Body/Medium | Pretendard Medium 16 / line 1.5 / letter 0.57 | Subtitle |
| Headline/Bold | Pretendard SemiBold 18 / line 1.445 / letter -0.02 | Step row labels |
| Label/Bold | Pretendard SemiBold 14 / line 1.429 / letter 1.45 | Step circle number |

### Specific controls

- **BridgeStepCircle**: 28×28 circle, asset-driven (`imgStep` = subtle blue bg), centered number 14px SemiBold primary `#3A99F8`. Used here as a static legend, not a stepper.
- No pickers / chips / progress bars on this screen (this is the explainer/landing).

### State

- Step in flow: **0 (entry / explainer)** before stepper begins.
- Always single state; no empty/filled/error variants.

### Interactions

| Element | Behavior |
|---------|----------|
| Back chevron | Pop route |
| `시작` button | Push to `695:8924` (스케쥴 등록 1, empty state). Button is always enabled (no preconditions). |

### Reusable components

- `BridgeStepCircle({int number, bool active})` — small numbered badge (28×28).
- `BridgeOnboardingScaffold` — topbar + centered title/subtitle + bottom CTA pattern (matches earlier onboarding screens).

---

## 스케쥴 등록 1 — empty (`695:8924`)

Korean frame name: `scr/child-초기 시간설정-스케줄등록-empty`

### Layout (top → bottom)

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–44   | Status bar | system |
| 44–96  | cmp/topbar | empty title |
| 66.5   | **Stepper** (`370:22032`) | centered, w=185, h=7. 3 pills 55×7, gap=15. Step 1 active = `#C2DFFD`, others = `#EDEEF1` |
| 107–158.5 | titleset (`695:8929`) | x=24, w=328, gap=12 between title row and description |
| —      | title row (`695:8930`) | step circle "1" + `스케줄 등록` (Heading1/Bold 24 black). gap=8 |
| —      | describe (`695:8933`) | 2-line Label/Medium 14 gray500 `#777A7F` |
| 211.5–712.5 | time table (`695:8936`) | w=325, h=501. Left axis hour labels (w=14), then 7 day columns |
| 211.5–245 | week header row (`695:9078`) | 7 chips, each 42×34, radius=12, gap=2. Day labels Body/Bold 16 gray400 `#91969E`. All **unselected** state in this empty screen |
| 245.5+ | 7 day columns × 17 cells | each cell 42×27, 0.5px gap. Columns gap=4. Cell bg `#EDEEF1` (gray150). All cells empty (unselected). Diagonal line image overlay (imgLine1) on each |
| left edge | hour labels (`695:9093`) | vertical strip w=14, labels 7,8 (Medium) then 9..12,1..12 (Regular). Caption/Regular 12, gray400 |
| bottom-117 → bottom-63 | CTA `다음` | h=54, w=328, **disabled** state bg `#D5D8DE` (gray200), text `#A7ACB2` (gray300) |
| bottom 0–32 | UI bar | system |

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `스케줄 등록` | `695:8932` |
| `학교, 학원처럼 휴대폰을 거의 못 쓰는 시간을 등록해서 ` | `695:8935` line 1 |
| `사용가능한 시간을 편하게 확인해요` | `695:8935` line 2 |
| `월` `화` `수` `목` `금` `토` `일` | `695:9080`..`9092` |
| `7` `8` `9` `10` `11` `12` `1` `2` `3` `4` `5` `6` `7` `8` `9` `10` `11` `12` | `695:9094`..`9111` (hour axis) |
| `다음` | `252:4783` |

### Colors

| Hex | Token | Usage |
|-----|-------|-------|
| `#FAFBFC` | gray050 ✓ | bg |
| `#EDEEF1` | gray150 ✓ | Empty time cells, inactive stepper pill |
| `#C2DFFD` | primarySubtle (NEW) | Active stepper pill (Step 1) |
| `#91969E` | NEW `gray400` | Day chip labels, hour axis labels |
| `#777A7F` | gray500 ✓ | Description text |
| `#D5D8DE` | NEW `gray200` | Disabled button bg |
| `#A7ACB2` | NEW `gray300` | Disabled button text |
| `#3A99F8` | primary ✓ | Step circle number |
| `#050505` (alias `Black`) | inkBlack | Title text |

**New tokens**: `gray400 = #91969E`, `gray200 = #D5D8DE`, `gray300 = #A7ACB2`, `gray150 = #EDEEF1` (also in 03-mypage), `primarySubtle = #C2DFFD`.

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Heading1/Bold | Pretendard SemiBold 24 / 1.364 | Page title `스케줄 등록` |
| Label/Medium | Pretendard Medium 14 / 1.429 / letter 0.203 | Description text |
| Body/Bold | Pretendard SemiBold 16 / 1.5 / letter 0.0912 | Day chip labels |
| Caption/Regular | Pretendard Regular 12 / 1.334 / letter 0.3024 | Hour axis |
| Headline/Medium | Pretendard Medium 18 / 1.445 | Button label |
| Label/Bold | Pretendard SemiBold 14 / 1.429 | Step circle number |

### Specific controls

- **BridgeStepperPills** (3-pill horizontal progress bar, 55×7 each, radius=10, gap=15). Active=primarySubtle, inactive=gray150.
- **BridgeWeekdaySelector**: 7 chips (월–일), each 42×34, radius=12, label centered. All unselected here; selected style appears on filled screen (see 695:9115 — but interestingly chip backgrounds remain unstyled in this Figma; the **cell column body** carries the selection state, not the chip).
- **BridgeTimeGrid**: 7-column × 17-row grid (one cell per hour-slot of the day from 7am–12am), each cell 42×27, gap 0.5px vertical / 4px horizontal. Tap toggles cell `unselected` ↔ `selected`. The diagonal line image (imgLine1) appears on every cell — likely a hatch overlay indicating the cell is interactive.
- No hour/minute wheel picker on this screen (the grid IS the picker).

### State

- Step 1 of 3 wizard (stepper pill index 0 active).
- **Empty** variant — no cells selected, all gray150.
- CTA disabled because no selections made.

### Interactions

| Element | Behavior |
|---------|----------|
| Back chevron | Pop to entry (`695:8850`) |
| Day chip tap | (Likely) filter highlight or scroll; in this design, selection happens cell-by-cell |
| Time cell tap / drag | Toggle cell `selected` (primary blue). Drag-select pattern likely |
| `다음` button | **Disabled** until ≥1 cell selected → then enabled (→ `695:9115` filled state) |

### Reusable components

- `BridgeStepperPills(currentStep, totalSteps)`
- `BridgeWeekdaySelector(values, onChange)`
- `BridgeTimeGrid(slots, onToggle)` — owns the 7×17 grid
- `BridgeStepHeader(stepNumber, title, description)` — circle + title + description block
- `BridgePrimaryButton` with `disabled` style

---

## 스케쥴 등록 2 — filled (`695:9115`)

Korean frame name: `scr/child-초기 시간설정-스케줄등록-filled`

### Layout

Identical to `695:8924` (same regions, same positions). **Diff**: many time cells now have `bg-[#3A99F8]` (primary) instead of `#EDEEF1` (i.e., selected blocks for school/academy hours). CTA `다음` is now **enabled** (bg primary, text white).

Selected cell pattern visible in the frame:
- Col 1 (월): rows 3–9 + 13–15 selected
- Col 2 (화): rows 3–9 selected
- Col 3 (수): rows 3–8 + 13–15 selected
- Col 4 (목): rows 3–9 selected
- Col 5 (금): rows 3–9 + 13–15 selected
- Col 6 (토): rows 4–5 selected (lighter)
- Col 7 (일): no cells selected

### Texts

Same as `695:8924`. CTA text remains `다음`.

### Colors

Same palette + adds **`#3A99F8` (primary)** as the selected-cell fill.

### Typography

Same as empty state.

### Specific controls

Same as empty. Demonstrates `selected` cell visual: solid primary background with diagonal hatch overlay still visible (imgLine1 line svg on top).

### State

- Step 1 of 3.
- **Filled** variant — some cells selected.
- CTA **enabled** (bg=primary, text=white).

### Interactions

- `다음` button: navigate to Step 2 — 주별 시간 분배 (`695:11870`).

### Reusable components

Same as empty (BridgeTimeGrid handles both states via cell-level `selected` flag).

---

## 초기 주별 사용시간 설정 (`695:11870`)

Korean frame name: `scr/child-초기 시간설정-주별시간분배-empty`

### Layout (top → bottom)

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–44   | Status bar | system |
| 44–96  | cmp/topbar | empty title |
| 67.5   | Stepper (`695:11875`) | Step 2 active. Pill 1 = gray150 (Step 1 complete but unhighlighted — note: this Figma uses gray150 for past steps, primarySubtle for current). Pill 2 = `#C2DFFD`. Pill 3 = gray150. |
| 105–145 | titleset (`695:11877`) | step circle "2" + `주별 시간 분배` Heading1/Bold |
| 145–193 | describe (`695:11881`) | 2 lines Label/Medium 14 gray500 |
| 185+    | Main Container (`695:11876`) | x=24, w=327, vertical gap=40 between titleset / total-time / weekly-distribution |
| 273–335 | Total time container (`695:11884`) | gap=12 between section title and value |
| —      | Section title `2월 총 사용 시간` (`695:11885`) | Heading2/Bold 20 gray800 `#2F3032` |
| —      | Time breakdown card (`695:11887`) | h=50, w=327, border 2px gray200 `#D5D8DE`, radius=12, opacity 0.8. Centered hour+minute display |
| —      | Hour container (`695:11890`) | "60" SemiBold + "시간" Regular, both Headline/Medium 18 |
| —      | Minute container (`695:11893`) | "30" SemiBold + "분" Regular, Headline/Medium 18 |
| 375–408 | Weekly distribution header (`695:11897`) | `주별 시간 분배` (Heading2/Bold 20 gray800) + `자동계산` icon button (right) |
| —      | 자동계산 icon button (`695:12075`) | bg `#EBF5FE` (NEW Button/Blue/Light), radius=7, padding 5h/2v. Icon 18.77 + text `자동계산` Label/Medium 14 primary `#3A99F8` |
| 420–650 | Weekly distributions container (`695:12010`) | h=230, w=327, gap=8 between week rows. 4 rows |
| —      | Each row "time set" (`695:12011` etc.) | h=50, padding 8h/11v, radius=12. Layout: `1주차` label (w=55) — vertical divider (h=22) — empty time value (`00시간 00분` placeholder, **gray200 `#D5D8DE`** for 00 because unset). gap=22 between items |
| bottom-117 → bottom-63 | CTA `다음` | **disabled** bg gray200, text gray300 |
| bottom 0–32 | UI bar | system |

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `주별 시간 분배` | `695:11880` (page title) and `695:11898` (section title — duplicated) |
| `부모님이 부여한 이번 달 총 사용 시간을` | `695:11883` line 1 |
| `주별로 분배해요! ` | `695:11883` line 2 |
| `2월 총 사용 시간` | `695:11885` |
| `60` `시간` `30` `분` | total time values |
| `자동계산` | `I695:12075;592:20029` |
| `1주차` `2주차` `3주차` `4주차` | week labels |
| `00` `시간` `00` `분` | placeholder per week (시간/분 are inkBlack, `00` is gray200 placeholder) |
| `다음` | CTA |

### Colors

| Hex | Token | Usage |
|-----|-------|-------|
| `#FAFBFC` | gray050 ✓ | bg |
| `#2F3032` | NEW `gray800` | Section titles (`2월 총 사용 시간`, `주별 시간 분배`) |
| `#050505` | inkBlack | Number text in total-time card, 주차 labels, 시간/분 unit text |
| `#D5D8DE` | gray200 (NEW) | Total-time card border, placeholder `00` for unset week rows, CTA disabled bg |
| `#A7ACB2` | gray300 (NEW) | CTA disabled text |
| `#EBF5FE` | NEW `primaryBg` (Button/Blue/Light) | 자동계산 button bg |
| `#3A99F8` | primary ✓ | 자동계산 text + step circle number |
| `#777A7F` | gray500 ✓ | description text |
| `#EDEEF1` | gray150 | inactive stepper pills |
| `#C2DFFD` | primarySubtle (NEW) | current stepper pill |

**New tokens this screen**: `gray800 = #2F3032`, `primaryBg = #EBF5FE`.

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Heading1/Bold | Pretendard SemiBold 24 / 1.364 / letter -1.94 | Page title |
| Heading2/Bold | Pretendard SemiBold 20 / 1.4 / letter -1.2 | Section titles |
| Headline/Medium | Pretendard Medium 18 / 1.445 / letter -0.02 | Time numerics + 주차 labels (semibold variant used for number) |
| Label/Medium | Pretendard Medium 14 / 1.429 / letter 0.203 | Description, 자동계산 |
| Headline/Regular | Pretendard Regular 18 / 1.445 | (declared) — used for 시간/분 unit suffix |
| Label/Bold | Pretendard SemiBold 14 / 1.429 | Step circle number |

### Specific controls

- **BridgeStepperPills** (same as scheduling screens).
- **BridgeStepHeader** (circle "2" + title + description).
- **BridgeTotalTimeCard**: read-only h=50, w=full, radius=12, border 2px gray200, opacity 0.8. Inner inline "00 시간 00 분" with 2 number+unit pairs. Center-aligned via translate(-50%).
- **BridgeIconButton** ("자동계산"): h=31, w=88 (or hug content w=variable), radius=7, padding 5h/2v, gap=7, leading icon + text. Two visual states observed:
  - Active/clickable (`695:12075`): bg `primaryBg #EBF5FE`, text primary `#3A99F8`
  - Idle/disabled (in bottomsheet/filled screens `695:13514`, `695:12069`): bg gray150 `#EDEEF1`, text gray300 `#A7ACB2`
- **BridgeWeekRow**: h=50, padding 8h/11v, radius=12, layout `label(w=55) — VerticalDivider(h=22) — TimeInline(141×28)`. The `TimeInline` is **tappable** to open the bottom sheet.
- No wheel pickers on the page itself — these come in the bottom sheet (`695:13485`).

### State

- Step 2 of 3.
- **Empty** — all 4 week rows show `00시간 00분` in gray200 placeholder color.
- CTA `다음` disabled until all 4 weeks summed equal the monthly total (60시간 30분).

### Interactions

| Element | Behavior |
|---------|----------|
| Tap on any week row's time area | Opens `BridgeTimeBottomSheet` (`695:13485` overlay) for that week |
| `자동계산` button (idle here) | Auto-distributes monthly total evenly across 4 weeks. Becomes idle/disabled after first manual edit (per filled variants) |
| Back | Returns to Step 1 schedule |
| `다음` | (disabled) — enables when sum matches monthly total → navigate to Step 3 일별 분배 |

### Reusable components

- `BridgeStepperPills`
- `BridgeStepHeader`
- `BridgeTotalTimeCard({int hours, int minutes})` (display-only)
- `BridgeIconButton({IconData icon, String label, VoidCallback? onTap, BridgeIconButtonState state})`
- `BridgeWeekRow({String label, int? hours, int? minutes, VoidCallback onTap})`
- `BridgeTimeBottomSheet` (opened from row tap)
- `BridgePrimaryButton` (disabled state)

---

## 초기 시간 설정 — 시간 바텀시트 (`695:13485`)

Korean frame name: `scr/child-초기 시간설정-주별시간분배-바텀시트`

### Layout

Full-screen scrim + bottom sheet over the **filled** version of `695:11870`.

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–681  | Scrim (`695:13625`) | bg `rgba(68,68,68,0.6)` covering w=375, h=681 |
| 415–812 (bottom-aligned) | **Bottom sheet** (`695:13695`) | h=397, w=375, bg white, top corners radius=24 (rounded-tl-[24px] / -tr-[24px]). No visible drag handle in Figma — handle should be added in implementation (4×40 px gray pill at top, ~12px from top). |
| 26.86 (within sheet) | Header title `시간선택` (`I695:13695;369:15686`) | Headline/Bold 18 inkBlack, horizontal-centered |
| 85 (within sheet) | **Hour wheel** (`I695:13695;369:15674`) | left=92.5, w=56, h=133. Vertical list, gap=17, font Heading1/Bold 24, center-selected value (`01`) inkish `#2F3032` (gray800), unselected `#D5D8DE` (gray200). Items shown: `00 01 02 03 04 05 06 07 08 09 10` (scrollable) |
| 85 (within sheet) | **Minute wheel** (`I695:13695;369:15661`) | left=227.5, w=56, h=139. Same style. Selected = `05`. Items: `00 05 10 15 15 15 30 35 20 40 50 55` (raw figma data — implementation should use `00 05 10 ... 55` in 5-min increments) |
| 128 (within sheet, ~50px tall) | **Selection band** (`I695:13695;369:15687`) | h=50, left=25.5, w=324, opacity 0.8. **Top & bottom border 2px primary `#3A99F8`** (top-only + bottom-only borders forming the selection viewport). Inside: anchor labels `시간` (left, x=144.83) and `분` (right, x=287.64), Heading2/Medium 20, inkBlack |
| bottom-117 → bottom-63 (within sheet) | CTA `확인` (`I695:13695;369:15690`) | h=54, w=327, bg primary `#3A99F8`, text white Headline/Medium 18, radius=8 |
| bottom 0–32 (within sheet) | UI bar | system |

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `시간선택` | `I695:13695;369:15686` (sheet header) |
| `시간` | left anchor in selection band |
| `분` | right anchor in selection band |
| `00`..`10` (hour items) | wheel cells |
| `00`,`05`,`10`,`15`,…`55` (minute items) | wheel cells |
| `확인` | CTA |

### Colors

| Hex | Token | Usage |
|-----|-------|-------|
| `rgba(68,68,68,0.6)` | NEW `scrimBlack60` | Modal scrim |
| `#FFFFFF` | white ✓ | Sheet bg, CTA text |
| `#050505` | inkBlack | Header title `시간선택` |
| `#2F3032` | gray800 | Selected wheel value, anchor labels |
| `#D5D8DE` | gray200 | Unselected wheel values |
| `#3A99F8` | primary ✓ | Selection band top/bottom border, CTA bg |

**New token**: `scrimBlack60 = rgba(68,68,68,0.6)`.

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Headline/Bold | Pretendard SemiBold 18 / 1.445 / letter -0.02 | Sheet header |
| Heading1/Bold | Pretendard SemiBold 24 / 1.364 / letter -1.94 | Wheel items |
| Heading2/Medium | Pretendard Medium 20 / 1.4 / letter -1.2 | Selection-band anchor labels (`시간`/`분`) |
| Headline/Medium | Pretendard Medium 18 / 1.445 | CTA `확인` |

### Specific controls

- **BridgeTimeBottomSheet** — modal sheet, **h=397** (≈49% of 812 viewport), top radius=24, white bg.
  - Anatomy (top→bottom):
    1. **Drag handle** (implementation-only; not in Figma — add 40×4 gray200 pill, 8px from top, centered)
    2. **Header**: 1-line title `시간선택` (Headline/Bold 18, centered horizontally), top offset ~27px from sheet top.
    3. **Wheel row**: two `ListWheelScrollView`-style columns side-by-side (left=hour, right=minute), each 56px wide. Gap between wheels ~80px. Anchor labels `시간`/`분` sit in a separately-rendered selection band that overlays the centered row of both wheels.
    4. **Selection band overlay**: full-width inside sheet (324px), h=50, top/bottom 2px primary border (no fill), opacity 0.8, contains the `시간`/`분` anchor text at fixed x positions to the right of each wheel's selected value.
    5. **CTA button row**: single full-width primary button `확인`, h=54, bottom-anchored 63px from bottom of sheet (above UI bar).
  - **Picker style**: classic iOS-style wheel picker — center selection highlighted by colored top/bottom rule, items fade to gray200 at top/bottom. Snap on release. Hour range likely 0–999 (or 0–24 depending on context), minute range 0–55 in 5-minute steps.

### State

- Step in flow: **Step 2, sub-state = editing a single week**.
- Always opened from a `BridgeWeekRow` tap on `695:11870` / `695:8694`.
- Background main page is the **filled** Step-2 layout (visible darkened under scrim) — note the underlying page shows `1주차 15시간 00분`, `2주차 15시간 00분`, etc.

### Interactions

| Element | Behavior |
|---------|----------|
| Scrim tap | Dismiss sheet (cancel changes) |
| Drag handle / sheet drag down | Dismiss sheet |
| Wheel scroll | Update selected hour/minute |
| `확인` button | Commit value to the week row that opened the sheet, dismiss sheet, recalculate sum, refresh `다음` CTA enabled state |

### Reusable components

- `BridgeTimeBottomSheet({required int initialHours, required int initialMinutes, required ValueChanged<(int h, int m)> onConfirm})`
- `BridgeWheelPicker` (single column, used twice inside the sheet)
- `BridgeScrim` (rgba(68,68,68,0.6) full-screen overlay)
- `BridgePrimaryButton` (`확인`)

---

## 주별 시간 분배 완성 (`695:8694`)

Korean frame name: `scr/child-시간설정-주별시간분배-filled` (note: this is the **non-초기** version per the name, but visually identical to the filled Step 2)

### Layout

Identical to `695:11870` (empty). **Diffs from empty**:

- Each week row's time area now shows actual values (all inkBlack `#050505`):
  - 1주차: `15 시간 00 분`
  - 2주차: `15 시간 00 분`
  - 3주차: `15 시간 00 분`
  - 4주차: `15 시간 30 분`  (note last row has 30 minutes → sum = 60h 30m = monthly total ✓)
- `자동계산` button is in **disabled/idle** state: bg gray150 `#EDEEF1`, text gray300 `#A7ACB2` (because user has manually edited — auto-calc no longer applicable).
- CTA `다음` is **enabled** (bg primary, text white) because sum matches total.

### Texts

Same Korean texts as `695:11870`, with week values populated.

### Colors

Same palette as `695:11870`. Adds:
- `#050505` inkBlack — for filled week-row numbers (vs gray200 placeholder)
- `#EDEEF1` gray150 — for now-idle `자동계산` button bg (changed from `#EBF5FE` active state)
- `#A7ACB2` gray300 — for idle `자동계산` text

### Typography

Same as `695:11870`.

### Specific controls

Same components. Demonstrates filled state of `BridgeWeekRow` and idle state of `BridgeIconButton` ("자동계산").

### State

- Step 2 of 3, **completed**.
- All 4 weeks filled, sum = monthly total → `다음` enabled.
- `자동계산` button visually disabled/idle (already-customized indicator).

### Interactions

| Element | Behavior |
|---------|----------|
| Week row tap | Re-opens `BridgeTimeBottomSheet` with that week's current value pre-selected |
| `자동계산` (idle) | Tappable to reset all weeks to even split, then becomes idle again. Idle styling is purely visual feedback that auto distribution is already applied / not the next expected action |
| `다음` | Navigate to Step 3 (일별 시간 분배 — next batch) |
| Back | Returns to Step 1 |

### Reusable components

Same as `695:11870`. Confirms the same `BridgeWeekRow` widget renders both empty and filled visuals based on `hours`/`minutes` props (null = gray200 `00`, set = inkBlack).

---

## Cross-screen reusable components (summary)

| Widget | Used on |
|--------|---------|
| `BridgeStepperPills(3-pill progress)` | 8924, 9115, 11870, 13485 (background), 8694 |
| `BridgeStepHeader(stepNumber + title + description)` | 8924, 9115, 11870, 8694 |
| `BridgeStepCircle(number badge)` | 8850, plus inside BridgeStepHeader |
| `BridgeWeekdaySelector` | 8924, 9115 |
| `BridgeTimeGrid(7×17 hour-cells)` | 8924, 9115 |
| `BridgeTotalTimeCard` | 11870, 13485 (bg), 8694 |
| `BridgeWeekRow` | 11870, 13485 (bg), 8694 |
| `BridgeIconButton` | 11870, 8694 (자동계산) |
| `BridgeTimeBottomSheet` (+ `BridgeWheelPicker` ×2, `BridgeScrim`) | 13485 |
| `BridgePrimaryButton` (default / disabled) | all screens |

## New design tokens introduced in this batch

| Token | Hex | First appearance | Notes |
|-------|-----|------------------|-------|
| `primarySubtle` | `#C2DFFD` | 8850, 8924 | Active stepper pill, step circle bg |
| `primaryBg` | `#EBF5FE` | 11870 | 자동계산 active bg |
| `gray800` | `#2F3032` | 11870, 13485 | Section titles, selected wheel value |
| `gray400` | `#91969E` | 8924, 9115 | Day chip labels, hour axis |
| `gray300` | `#A7ACB2` | 8924, 11870, 8694 | Disabled button text |
| `gray200` | `#D5D8DE` | 8924, 11870, 13485, 8694 | Disabled button bg, card borders, wheel unselected |
| `gray150` | `#EDEEF1` | already noted in 03-mypage; reused | Empty time cells, inactive stepper, idle 자동계산 bg |
| `scrimBlack60` | `rgba(68,68,68,0.6)` | 13485 | Modal scrim |
| `inkBlack` | `#050505` | reused from 03-mypage | All primary text |

Recommended Flutter naming in `AppColors`:
```
static const primarySubtle = Color(0xFFC2DFFD);
static const primaryBg     = Color(0xFFEBF5FE);
static const gray800       = Color(0xFF2F3032);
static const gray400       = Color(0xFF91969E);
static const gray300       = Color(0xFFA7ACB2);
static const gray200       = Color(0xFFD5D8DE);
static const gray150       = Color(0xFFEDEEF1);
static const scrimBlack60  = Color(0x99444444);
```
