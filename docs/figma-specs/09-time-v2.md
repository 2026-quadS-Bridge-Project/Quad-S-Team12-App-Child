# 09 — 시간 설정 v2 (Edit Flow)

UI-figma.md note: "이전 주차에 등록한 스케쥴을 그대로 보여주고, 수정 가능". This is the *re-run* of the 3-step time-setting wizard for weeks 2/3/4 (after Week 1 has elapsed). The wizard reuses the same Step1/Step2/Step3 components from v1 (08a/08b/08c) but pre-fills them with last week's plan and uses adjusted descriptions/data.

File key: `tzJjQmXtXO7vGlfCT9SASu` · clientFrameworks=flutter · clientLanguages=dart

---

## v2-1 (`750:13034`) — Intro / 단계 설명
Name: `scr/child-시간설정-단계설명`

**Layout** (top→bottom)
- StatusBar (h44, notch)
- CmpTopbar (h52, back arrow only, empty title)
- Title container (center, top=205): heading + body description
- Steps container (center, top=368, w=140, gap=20): three numbered rows
- Bottom UiBar
- Primary CTA "시작" (bottom 63, w327, h54, bg #3A99F8)

**Texts** (verbatim)
- Heading: `사용시간 설정`
- Subtitle: `저번주 피드백을 고려해서` / `더 나아진 이번주 계획을 짜봐요!`
- Step rows: `1 스케줄 등록`, `2 주별 시간 분배`, `3 일별 시간 분배`
- CTA: `시작`

**Colors**
- bg: `#FAFBFC` (gray-050)
- title: `#050505` (near-black)
- subtitle: `#777A7F` (gray-500)
- step badge inner: `#3A99F8` (primary) on white circle (svg asset)
- step label: `#777A7F`
- CTA: `#3A99F8` / white text

**Typography**
- Heading: Pretendard SemiBold 24 / lh 1.364 / letter-spacing −0.4656px (Heading 1/Bold)
- Subtitle: Pretendard Medium 16 / lh 1.5 / 0.0912 (Body/Medium)
- Step label: Pretendard SemiBold 18 / 1.445 / −0.0036 (Headline/Bold)
- Step number: Pretendard SemiBold 14 / 1.429 / 0.203 (Label/Bold)
- CTA: Pretendard Medium 18 / 1.445 (Headline/Medium)

**State variant**: Wizard splash/intro shown before entering the 3-step v2 edit flow. Differs from v1 intro by replacing the v1 copy ("이번주 사용 시간을 설정해요") with feedback-oriented copy that references last week.

**Edit affordances**: None on this screen — it is informational.

**Interactions**: `시작` → push v2-2 (스케줄 등록 v2).

**Reusable components vs v1**
- Reused: StatusBar, CmpTopbar, UiBar, primary Button, Step badge component, Title+Subtitle pattern.
- v2-specific: Subtitle copy only.

---

## v2-2 (`750:12671`) — Step 1: 스케줄 등록 v2 (filled)
Name: `scr/child-시간설정-스케줄등록-v2-filled`

**Layout** (top→bottom)
- StatusBar + CmpTopbar (empty title, back)
- Progress indicator (top=67.5, 3 dots/pills w=55 each, gap=15): `[c2dffd, edeef1, edeef1]` → step 1 of 3
- contentArea (left=24, top=107, w=327):
  - titleset (gap=12): Step badge `1` + heading `스케줄 등록`; description (gap=0)
  - time table (top=104.5 inside contentArea): 7 weekday columns × 17 time-slot rows (each row h=27, gap 0.5); week header row (월~일) above; left time axis (7AM…12AM)
- CTA `다음` (bottom 63, primary)

**Texts** (verbatim)
- Heading: `스케줄 등록`
- Description: `이전에 등록한 스케줄과 동일하다면 다음을 클릭하고,` / `스케줄에 변동이 생겼다면 수정해요!`
- Week labels: `월 화 수 목 금 토 일`
- Hour labels: `7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12`
- CTA: `다음`

**Colors**
- bg `#FAFBFC`
- Heading text black `#000000`
- Description `#777A7F`
- Time slot selected: `#3A99F8` (primary)
- Time slot unselected: `#EDEEF1` (gray-150)
- Week / hour labels: `#91969E` (gray-400)
- CTA primary `#3A99F8`
- NEW vs v1: same palette — no new tokens. Active state on slots reuses primary.

**Typography**
- Heading: SemiBold 24 / Heading 1/Bold
- Description: Medium 14 / 1.429 / 0.203 (Label/Medium)
- Week label: SemiBold 16 / 1.5 (Body/Bold)
- Hour label: Regular 12 / 1.334 / 0.3024 (Caption/Regular). Hours 7 & 8 are tinted Medium (slightly bolder edge).

**State variant**: Same UI as v1 step 1 "filled" but the canvas starts already populated with the previously-saved schedule (figma annotation `이전주차에 등록한 스케줄 그대로 보여줌 / 수정가능`). v1 step 1 starts empty.

**Edit affordances**
- In-place tap on any time slot toggles selected/unselected (no pencil, no edit mode).
- Drag selection across slots (inferred from layout — touch grid like v1).
- No discard/reset button on the screen; "back" arrow exits flow.
- Prefilled values: yes — `prop1="선택"` cells reflect prior plan.

**Interactions**
- Tap slot → toggle.
- `다음` → push v2-3 (주별 시간 분배 v2 empty).

**Reusable components vs v1**
- Reused: StatusBar, CmpTopbar, UiBar, Step badge, Progress indicator (`Step1` dots), TimeSelect cell, Week header chip, Hour axis, primary Button.
- v2-specific: only the description copy and the pre-filled data model (TimeSelect grid identical).

---

## v2-3 (`750:11991`) — Step 2: 주별 시간 분배 v2 (empty)
Name: `scr/child-시간설정-주별시간분배-v2-empty`

**Layout** (top→bottom)
- StatusBar + CmpTopbar
- Progress indicator: `[edeef1, c2dffd, edeef1]` → step 2 of 3
- Main Container (left=24, top=105, gap=40):
  1. titleset (gap=12): Step `2` + heading `주별 시간 분배`; description
  2. Total time container (gap=12): label `2월 잔여 시간`; bordered card (border #D5D8DE, radius 12, h=50, opacity 0.8) showing `45 시간 30 분`
  3. Weekly distribution container (gap=12):
     - Header row with title `주별 시간 분배 ` + "자동계산" icon button (bg #EBF5FE, radius 7, primary text, divide icon) — *active*
     - 4 weekly rows (h=50 each, gap=8): `1주차` (opacity 0.2 — past), `2주차/3주차/4주차` (opacity 0.8) — each row: week label + vertical divider + `00 시간 00 분`. Row 1 already shows `15 시간 00 분`.
- CTA `다음` (disabled state — bg #D5D8DE, text #A7ACB2)

**Texts** (verbatim)
- Heading: `주별 시간 분배`
- Description: `2월 1주차에 사용하고 남은 시간으로` / `주별 시간 분배를 다시 설정해요!`
- Section labels: `2월 잔여 시간`, `주별 시간 분배 ` (trailing space preserved)
- Week labels: `1주차`, `2주차`, `3주차`, `4주차`
- Units: `시간`, `분`
- Auto-button: `자동계산`
- CTA: `다음`

**Colors**
- Total card border `#D5D8DE` (gray-200), text `#050505`
- Past-week row opacity 0.2 (figma annotation `이미 지나간 주차는 투명도 조절`); active rows opacity 0.8
- Empty time values: `#D5D8DE`; filled values: `#050505`
- Auto button bg `#EBF5FE` (Button/Blue/Light), text `#3A99F8`
- Disabled CTA: bg `#D5D8DE`, label `#A7ACB2` (gray-300)
- NEW vs v1: 그레이 row dimming via opacity (0.2 for past weeks) — already in v1 token set but used here as a *signature v2 dimming pattern*.

**Typography**
- Heading: SemiBold 24 (Heading 1/Bold)
- Description: Medium 14 (Label/Medium)
- Section label `잔여 시간` / `주별 시간 분배`: SemiBold 20 / 1.4 / −0.24 (Heading 2/Bold)
- Week label: SemiBold 18 (Headline/Bold)
- Number: SemiBold 18; unit (`시간`/`분`): Regular 18
- Auto button text: Medium 14 (Label/Medium)
- CTA disabled: Medium 18

**State variant**: Step 2 entry / empty. Past week 1 row appears at the *top of the list* with its used hours `15 시간 00 분` rendered at 20% opacity (immutable record). Remaining weeks 2-4 are zero and editable. Differs from v1 step 2 because v1 lists 4 fully active weeks for a full month; v2 has 1 locked past-week + 3 editable future weeks and the "2월 잔여 시간" total is recomputed.

**Edit affordances**
- 2주차 row is a clickable `<a>` (Figma cursor=pointer) → opens time-picker bottom sheet.
- 3주차/4주차 rows are also tappable (same structure but no explicit cursor in markup — implied tap area).
- 1주차 row is dimmed and non-interactive (no `<a>` wrapper).
- "자동계산" button distributes remaining time across editable weeks automatically.
- No pencil icon — entire row is the affordance.

**Interactions**
- Tap editable row → open bottom sheet (see v2-4).
- Tap `자동계산` → fill 2/3/4주차 evenly.
- CTA disabled until distribution sums equal `2월 잔여 시간`; then enabled `다음` → step 3.

**Reusable components vs v1**
- Reused: StatusBar, CmpTopbar, Progress indicator, Step badge, titleset, Total time card, Weekly row, Vector divider, Auto-calc icon button, disabled Button.
- v2-specific: past-week opacity treatment (0.2); description copy referencing "잔여 시간"; total label `2월 잔여 시간` (vs v1 `이번달 총 시간`).

---

## v2-4 (`750:13450`) — Step 2 with bottom sheet (time picker)
Name: `scr/child-시간설정-주별시간분배-v2-바텀시트`

**Layout** (top→bottom)
- Same v2-3 screen as background
- Scrim overlay (full screen `rgba(68,68,68,0.6)`, h=681)
- Bottom sheet (h=397, white, top corners radius 24, anchored bottom):
  - Title `시간선택` (SemiBold 18, top=27)
  - Two wheel pickers: hour wheel (left at 92.5, w=56) + min wheel (right at 227.5, w=56). Selected row centered, gray `#D5D8DE` for non-selected, `#2F3032` for selected.
  - Selection highlight band: 50px-tall row with primary `#3A99F8` border-top/bottom 2px, opacity 0.8, labels `시간` / `분` (Heading 2/Medium 20)
  - CTA `확인` (primary, bottom 63)
  - UiBar
- "자동계산" pill in background is now passive (no cursor) since sheet is modal.

**Texts** (verbatim)
- Sheet title: `시간선택`
- Column labels: `시간`, `분`
- Hour values rendered: `00, 01, 02, …, 10` (selected = `01`)
- Min values rendered: `00, 05, 10, 15, 15, 15, 30, 35, 20, 40, 50, 55` (selected = `05`)
- CTA: `확인`

**Colors**
- Scrim `rgba(68,68,68,0.6)` — **NEW token candidate**: `scrim.overlay = 0x99444444` (60% opacity #444444)
- Sheet bg white
- Selected wheel value: `#2F3032` (gray-800)
- Unselected wheel value: `#D5D8DE` (gray-200)
- Selection band border: `#3A99F8` primary
- CTA primary `#3A99F8`

**Typography**
- Sheet title: SemiBold 18 (Headline/Bold)
- Wheel values: SemiBold 24 (Heading 1/Bold)
- Band labels (`시간`/`분`): Medium 20 / 1.4 / −0.24 (Heading 2/Medium — **NEW** vs prior token set, only Heading 2/Bold was registered)
- CTA: Medium 18

**State variant**: Modal time-picker invoked from a weekly row tap on v2-3. v1 step 2 also uses this picker but the entry route differs (v1 entry is from empty form rows; v2 entry is from prefilled rows).

**Edit affordances**
- Wheel scroll → choose hour/min.
- `확인` → commit selection to the row, dismiss sheet.
- Scrim tap (typical pattern, not explicit in spec) → discard / dismiss.
- No "취소" button surfaced inside the sheet — discard happens by back/scrim.

**Interactions**
- Tap value column → scrolls picker.
- Tap `확인` → state propagates to the active 2/3/4주차 row in v2-3 background.

**Reusable components vs v1**
- Reused: Scrim + Bottom sheet shell + time wheel picker — identical to v1 picker (component `369:15661`-`15690` family).
- v2-specific: nothing new in the sheet itself — only the entry context (already-populated row).

---

## v2-5 (`750:13105`) — Step 2 filled (auto-calc disabled / next enabled)
Name: `scr/child-시간설정-주별시간분배-v2-filled`

**Layout** (top→bottom)
- Same shell as v2-3
- All 4 week rows populated (`1주차 15h 00m` [opacity 0.2], `2주차 15h 00m`, `3주차 15h 00m`, `4주차 15h 30m`)
- "자동계산" pill in **disabled** style (bg `#EDEEF1`, label `#A7ACB2`)
- CTA `다음` **enabled** primary `#3A99F8`

**Texts**: identical to v2-3 plus all filled numeric values.

**Colors**
- Disabled auto-calc button: bg `#EDEEF1`, text `#A7ACB2` — **NEW combination** documenting disabled icon-button state.
- Enabled CTA: `#3A99F8`

**Typography**: same as v2-3.

**State variant**: Step 2 fully-filled. Distinction from v2-3: (a) all weeks have values, (b) auto-calc disabled because remaining time is now 0, (c) `다음` enabled. Differs from v1 step 2 filled in that *one row (1주차) remains permanently locked* as historical record.

**Edit affordances**
- Editable rows (2/3/4주차) still tappable to re-open picker (idempotent).
- Auto-calc unavailable (already balanced).
- No discard/reset CTA — back arrow only.

**Interactions**: tap row → re-open sheet; `다음` → step 3 (v2-6/v2-7).

**Reusable components vs v1**: 100% same components; the only delta is the disabled state of the auto-calc icon button.

---

## v2-6 (`750:13686`) — Step 3: 일별 시간 분배 v2 (error 초과)
Name: `scr/child-시간설정-일별시간분배-v2-error-초과`

**Layout** (top→bottom)
- StatusBar + CmpTopbar
- Progress indicator: `[edeef1, edeef1, c2dffd]` → step 3 of 3
- Container (left=23.65, top=105, gap=40):
  1. titleset: Step `3` + heading `이번주 일간 시간 설정`; description
  2. week time block (gap=12): label `2월 2주차` (Heading 2/Bold) + bordered total card `15 시간 00 분`
  3. Daily Distribution Container (gap=54, centered):
     - Header row with title `일별 시간 분배 ` and two arrow-buttons:
       - `스케줄 보기 ›` (primary text, bg #EBF5FE, h=31, radius 7)
       - `사용리포트 보기 ›` (same style) — **NEW v2 button**, absolute positioned at top=40
     - 3 daily rows (white cards, radius 16, px=18 py=15): `월,수,금 | 7 시간 00 분 [✎]`, `화,목 | 7 시간 00 분 [✎]`, `토,일 | 7 시간 00 분 [✎]`
     - Footer chip `+ 00시간 00분` on bg `#FFD3D3` with text `#FF4242` (destructive) → indicates **초과** (over budget)
- Error highlight area (overlay border): rounded-8, border 1.2px `#FF7878`, h=254, top=454 — wraps the daily rows area (figma annotation: `이전주차 주간 계획 보여줌, 여기에서 사용리포트 데이터 바탕으로 수정가능`)
- CTA `다음` disabled (`#D5D8DE` / `#A7ACB2`)

**Texts** (verbatim)
- Heading: `이번주 일간 시간 설정`
- Description: `거의 다 왔어요! ` / `내가 설정한 이번주의 시간을 일별로 분배해요.`
- Subsection: `2월 2주차`, `일별 시간 분배 `
- Buttons: `스케줄 보기`, `사용리포트 보기`
- Day groups: `월, 수, 금`, `화, 목`, `토, 일`
- Per-row time: `7` `시간` `00` `분`
- Footer warning: `+ 00시간 00분`
- CTA: `다음`

**Colors**
- Daily row card: white on `#FAFBFC` bg
- Day group text: `#2F3032` (gray-800)
- Pencil icon stroke: dark (group asset)
- Arrow-button bg `#EBF5FE`, text `#3A99F8`
- Footer 초과 chip: bg `#FFD3D3` (Foundation/Violet/Normal — misnamed in tokens), text `#FF4242` (Status/Destructive) — **NEW tokens vs prior 09-spec set**
- Error border: `#FF7878` 1.2px — **NEW** lighter destructive border tone
- Disabled CTA: `#D5D8DE` / `#A7ACB2`

**Typography**
- Heading: SemiBold 24
- Description: Medium 14
- `2월 2주차` & `일별 시간 분배`: SemiBold 20 (Heading 2/Bold)
- Day group label: SemiBold 18 (Headline/Bold)
- Numbers: SemiBold 18; units: Regular 18
- Arrow-button: Medium 14 (Label/Medium)
- Footer chip: Medium 18 (Headline/Medium)

**State variant**: Step 3, over-budget error. Per-day sum exceeds weekly total. Differs from v1 step 3 by:
- v2 surfaces `사용리포트 보기` button (data-driven editing hint from last week's report)
- Wraps the rows in a red border to flag the error
- 초과 chip in destructive color

**Edit affordances**
- Pencil icon (24×24, `data-name="수정"`) trailing each row → tap opens time-picker bottom sheet (same picker as v2-4).
- `스케줄 보기` → open prior schedule reference (read-only modal).
- `사용리포트 보기` → open usage report (history-driven editing aid). v2-only.
- Card itself may be tappable as an entire row.
- No discard button; back arrow exits.

**Interactions**
- Pencil tap → edit sheet → recompute footer chip & error border.
- `다음` stays disabled while error border/chip present (mismatch with weekly total).

**Reusable components vs v1**
- Reused: StatusBar, CmpTopbar, Progress indicator, Step badge, titleset, total time card, daily row card (with pencil), bottom sheet picker (when invoked).
- v2-specific: `사용리포트 보기` arrow button; destructive footer chip (`#FFD3D3` bg + `#FF4242` text); error-bounding 1.2px `#FF7878` border overlay.

---

## v2-7 (`750:14708`) — Step 3: 일별 시간 분배 v2 (error 남음)
Name: `scr/child-시간설정-일별시간분배-v2-error-남음`

**Layout**: Identical structure to v2-6 with palette differences.

**Texts**: same as v2-6 (footer reads `+ 00시간 00분` — sign/magnitude indicates *under* budget in this variant).

**Colors (only deltas vs v2-6)**
- Footer chip bg: `#E1F0FE` (Button/Blue/Light :hover — **NEW info-tonal background**)
- Footer chip text: `#3A99F8` (primary)
- Error border around rows: `#3A99F8` 1.2px (primary) — informational rather than destructive

**Typography**: identical to v2-6.

**State variant**: Step 3 under-budget. User has not allocated all weekly hours yet. Same UI grammar as v2-6 but tinted in primary blue instead of destructive red to convey "still has budget" rather than "exceeded".

**Edit affordances**: same as v2-6.

**Interactions**: same as v2-6; CTA enables only when footer goes to 0/00.

**Reusable components vs v1**: same reuse map as v2-6; the only v2-only deviation is the primary-tonal error chip + border, which doesn't exist in v1 step 3.

---

## v2-8 (`750:13854`) — Step 3: 일별 시간 분배 v2 (filled / valid)
Name: `scr/child-시간설정-일별시간분배-v2-filled`

**Layout** (top→bottom)
- StatusBar + CmpTopbar
- Progress indicator `[edeef1, edeef1, c2dffd]`
- Container left=23.65, top=105, gap=40:
  1. titleset (Step `3`, heading `이번주 일간 시간 설정`, description)
  2. week time block `2월 2주차` + total card `15 시간 00 분`
  3. Daily Distribution Container:
     - Header `일별 시간 분배 ` + `스케줄 보기 ›` + `사용리포트 보기 ›`
     - 3 daily rows `월,수,금 | 7 0`, `화,목 | 7 0`, `토,일 | 7 0` (each with pencil)
     - NO footer warning chip
     - NO error border
- CTA `다음` **enabled** primary

**Texts**: same as v2-6/v2-7 minus the footer chip.

**Colors**
- Card white on gray-050; text `#2F3032`
- Arrow buttons `#EBF5FE` / `#3A99F8`
- Enabled CTA `#3A99F8` / white

**Typography**: same as v2-6.

**State variant**: Step 3 happy path — sum equals weekly total exactly. No chip, no error border, CTA enabled. Differs from v1 step 3 filled chiefly by the presence of `사용리포트 보기` button (v2-only edit aid).

**Edit affordances**
- Pencil per row remains active → re-opens picker.
- `스케줄 보기`, `사용리포트 보기` for reference.

**Interactions**
- Tap pencil/row → bottom sheet picker (shared with v2-4).
- `다음` → push v2-9 (complete).

**Reusable components vs v1**: full reuse of v1 step 3 layout; only addition is `사용리포트 보기`.

---

## v2-9 (`750:13624`) — Complete
Name: `scr/child-시간설정-complete`

**Layout** (top→bottom)
- StatusBar + CmpTopbar (empty title, back)
- Main container centered (top=213, gap=40):
  - Title `시간 설정 완료!` (SemiBold 24)
  - Completion badge (size 60: blue ellipse + white check vector)
  - Message: `이번주 시간 계획이 부모님께 전달되었어요.` / `이제 계획대로 사용해봐요!`
- UiBar
- CTA primary (bottom 63) — propValue defaults to `홈으로` (the JSX leaves `propValue` unset so the Button component's default "홈으로" is rendered)

**Texts** (verbatim)
- Title: `시간 설정 완료!`
- Message: `이번주 시간 계획이 부모님께 전달되었어요.` / `이제 계획대로 사용해봐요!`
- CTA: `홈으로` (default from Button component)

**Colors**
- bg `#FAFBFC`
- Title text `#050505`
- Message text `#050505` (SemiBold 16, Body/Bold)
- Completion ellipse: primary `#3A99F8` (asset); check stroke white
- CTA `#3A99F8` / white

**Typography**
- Title: SemiBold 24 (Heading 1/Bold)
- Message: SemiBold 16 / 1.5 / 0.0912 (Body/Bold)
- CTA: Medium 18 (Headline/Medium)

**State variant**: Success terminal screen of the v2 wizard. Differs from a v1 complete screen by the message: v2 explicitly says "이번주 시간 계획이 부모님께 전달되었어요" (week-scoped + parent-share confirmation) rather than the v1 monthly framing.

**Edit affordances**: none — terminal state.

**Interactions**
- `홈으로` → navigate home (pops the wizard stack).
- Back arrow same behavior.

**Reusable components vs v1**
- Reused: StatusBar, CmpTopbar, UiBar, primary Button, Completion badge (370:22119).
- v2-specific: only copy.

---

# Cross-screen synthesis

## NEW tokens introduced by v2 (vs. existing palette)
| Token | Hex / value | Used in | Notes |
|---|---|---|---|
| `gray.150` | `#EDEEF1` | v2-2 unselected slots, v2-5 disabled auto-button bg | Already cataloged but heavily relied on by v2 |
| `gray.200` | `#D5D8DE` | total-card border, disabled CTA bg, empty wheel values | |
| `gray.300` | `#A7ACB2` | disabled CTA text, disabled auto-button text | |
| `gray.800` | `#2F3032` | section labels (잔여 시간 / 일별 시간 분배), wheel selected value, day group text | |
| `gray.400` | `#91969E` | week / hour axis labels | |
| `button.blueLight` | `#EBF5FE` | auto-calc pill, 스케줄 보기 / 사용리포트 보기 pills | |
| `button.blueLightHover` | `#E1F0FE` | v2-7 under-budget footer chip | **NEW** as a *semantic info-tonal bg* |
| `status.destructive` | `#FF4242` | v2-6 over-budget chip text | already in 8c likely; reconfirmed |
| `destructive.surfaceSoft` | `#FFD3D3` | v2-6 over-budget chip bg (mapped from Foundation/Violet/Normal naming) | **NEW** |
| `destructive.borderSoft` | `#FF7878` 1.2px | v2-6 error frame around daily rows | **NEW** |
| `scrim.overlay` | `rgba(68,68,68,0.6)` | v2-4 bottom-sheet scrim | **NEW** |
| Typography `Heading 2/Medium` | Pretendard Medium 20 / 1.4 / −0.24 | v2-4 sheet band `시간` `분` | **NEW** (only Heading 2/Bold known prior) |
| Component `editPencil` (24×24, node `325:17178`) | svg | trailing every daily row | reused but worth registering as `IconEdit` |

## v1 → v2 component reuse map
| Component | v1 nodes (8a/8b/8c) | v2 reused? | v2 deltas |
|---|---|---|---|
| StatusBar / Notch | yes | identical | – |
| CmpTopbar (back + title) | yes | identical | – |
| UiBar (home indicator) | yes | identical | – |
| primary Button (default/disabled) | yes | identical | – |
| Step badge (`369:19938`) | yes | identical | – |
| Progress indicator (3 pills) | yes | identical | progress state advances same way |
| Step-1 schedule grid + TimeSelect cell | yes | identical | prefilled data only |
| Week header chips (월~일) | yes | identical | – |
| Hour axis labels | yes | identical | – |
| Total time card (border + hr/min) | yes | identical | label string varies (`이번달 총 시간` → `2월 잔여 시간`) |
| Weekly row + vertical divider | yes | identical | adds **opacity dimming (0.2)** for past weeks |
| Auto-calc icon button | yes | identical | adds **disabled visual** (gray bg + gray text) |
| Bottom-sheet time picker (`369:15661…15690`) | yes | identical | – |
| Daily-row card with pencil | yes | identical | – |
| Footer chip (over/under indicator) | new in 8c if present | reused | v2 adds info-tonal variant (`#E1F0FE` + primary text) |
| Arrow button `스케줄 보기` | yes (8c) | identical | – |
| Arrow button `사용리포트 보기` | NO | **v2-only** | new component instance |
| Error border frame around rows | NO | **v2-only** | both destructive (`#FF7878`) and info (`#3A99F8`) variants |
| Completion badge + complete screen | yes | identical | copy varies (week + parent-share) |

## v2-specific UX patterns
1. **Initial state = prefilled snapshot.** Step 1 grid, weekly totals, daily distribution all open with last week's plan visible. The wizard's job is *diff & adjust*, not *create from scratch*. Description copy in each step explicitly invites edits ("스케줄에 변동이 생겼다면 수정해요!", "주별 시간 분배를 다시 설정해요!").
2. **Edit triggers — in-place, no modes.** No global "edit mode" toggle. Edit affordances per surface:
   - Step 1 grid: direct tap-toggle on each TimeSelect cell.
   - Step 2 weekly rows: whole-row tap → bottom-sheet picker (v2-4).
   - Step 3 daily rows: trailing pencil icon (24px) on each row → same bottom-sheet picker.
3. **Historical immutability via opacity.** Past-week rows (e.g. `1주차` in step 2) render at opacity 0.2 with no tap target. Same row component, only the wrapper opacity differs — clean engineering signal.
4. **Discard / reset UX.** No explicit "취소" / "초기화" affordance. Discard happens by:
   - Hardware/system back arrow on the topbar (cancels current step).
   - Bottom-sheet scrim tap (cancels current picker).
   - Re-edit is idempotent (rows remain tappable until `다음`).
5. **Save semantics.** No intermediate "저장" button. `다음` advances through the 3 steps; the implicit *save* happens only on the terminal `홈으로` after v2-9 (`시간 설정 완료!`). Parent share is bundled into the same commit: "이번주 시간 계획이 부모님께 전달되었어요."
6. **Error surfaces are dual-tone.** v2 step 3 distinguishes *over* (destructive red border + `#FFD3D3` chip + `#FF4242` text) from *under* (primary blue border + `#E1F0FE` chip + `#3A99F8` text). Same component, color-token swap.
7. **Reference-data hooks.** Step 3 surfaces two arrow buttons (`스케줄 보기`, `사용리포트 보기`) so the child can consult prior plan + actual usage report from inside the edit flow — a v2-only "data-aware editing" pattern. (`사용리포트 보기` is the v2-unique signal.)

## Sequence ordering hypothesis (9 screens)
Based on node names + progress-indicator state + UI semantics:

1. **v2-1 `750:13034`** — intro / `단계 설명` (entry splash, lists 1/2/3, CTA `시작`)
2. **v2-2 `750:12671`** — step 1, 스케줄 등록 v2 filled (`[active, dot, dot]`)
3. **v2-3 `750:11991`** — step 2, 주별 시간 분배 v2 empty (`[dot, active, dot]`, CTA disabled)
4. **v2-4 `750:13450`** — step 2, bottom-sheet picker invoked on a weekly row
5. **v2-5 `750:13105`** — step 2, 주별 시간 분배 v2 filled (auto-calc disabled, CTA enabled)
6. **v2-6 `750:13686`** — step 3, 일별 시간 분배 v2 *error 초과* (`[dot, dot, active]`, destructive)
7. **v2-7 `750:14708`** — step 3, 일별 시간 분배 v2 *error 남음* (`[dot, dot, active]`, info-tonal)
8. **v2-8 `750:13854`** — step 3, 일별 시간 분배 v2 filled (valid, CTA enabled)
9. **v2-9 `750:13624`** — complete (success terminal screen)

Rationale: each step shows progressive disclosure (intro → step 1 → step 2 empty → picker → step 2 filled → step 3 error states → step 3 filled → complete). The two step-3 error states (초과 / 남음) bracket the happy path filled state because they represent the two ways the user can be mid-editing before reaching the valid sum.
