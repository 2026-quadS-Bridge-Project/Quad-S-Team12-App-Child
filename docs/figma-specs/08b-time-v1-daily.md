# 08b. 시간 설정 v1 — Daily Distribution

Source: Figma file `tzJjQmXtXO7vGlfCT9SASu` (child onboarding, step 3/3).
This is the third step of the v1 onboarding-style time setup. Children take the previously chosen weekly hours (e.g. 15 시간 00 분) and distribute it across the 7 days of the week via a bottom sheet picker.

Page width: 375. Page horizontal padding: 24 (left content x = 23.65). Section gap: 40 (between titleset / week-time / daily-distribution). Default background: `#FAFBFC` (gray050).

---

## 일간 시간 설정 (`695-9743`)

Empty entry screen for step 3 — week is shown, daily distribution is still empty, the only affordance is the round `+` button to open the bottom sheet.

### Layout (top → bottom)
1. Status bar (44h) + UI bar (notch) bottom.
2. Topbar (52h) — left back button (24, x=24), centered title (empty in this frame; real screen has no title text — back-only).
3. Progress indicator y=67.5, 3 segments × 55w × 7h, gap 15, centered. Order: [gray150 done] [gray150 done] [primaryLight `#C2DFFD` current = step 3].
4. Content container at left=23.65, top=105, vertical gap=40.
   - **titleset** (gap 12):
     - title row (gap 8): step badge "3" + "이번주 일간 시간 설정" (24/SemiBold, black).
     - describe: 2 lines of 14/Medium, gray500 `#777A7F`.
   - **week time** (gap 12):
     - "2월 1주차" — 20/SemiBold, gray800.
     - Time Frame: 327w × 50h, `border: 2px solid #D5D8DE`, radius 12, opacity 0.8, contents centered ("15 시간 00 분"; "15" & "00" 18/SemiBold black, "시간"/"분" 18/Regular black). This is the read-only summary of the weekly target.
   - **Daily Distribution Container** (gap 20, centered):
     - Label row: "일별 시간 분배" (20/SemiBold gray800) + right-aligned chip "스케줄 보기" (109×31, bg `#EBF5FE`, radius 7, text 14/Medium primary `#3A99F8`, right chevron 5.28×10.57).
     - Round `+` button (40×40, white circle w/ border via Ellipse3, plus icon stroke 2 primary). Centered. **This is the only action that opens the bottom sheet.**
5. CTA "다음" — 327w × 54h, radius 8, **disabled** state (bg `#D5D8DE`, text `#A7ACB2`). Bottom = 63.

### Texts (verbatim)
- "이번주 일간 시간 설정"
- "거의 다 왔어요! "
- "내가 설정한 이번주의 시간을 일별로 분배해요."
- "2월 1주차"
- "15", "시간", "00", "분"
- "일별 시간 분배 "
- "스케줄 보기"
- "다음"

### Colors (cross-ref + NEW)
- bg050 `#FAFBFC` ✓, white ✓, gray150 `#EDEEF1` ✓, gray200 `#D5D8DE` ✓, gray300 `#A7ACB2` ✓, gray500 `#777A7F` ✓, gray800 `#2F3032` ✓, black ✓, primary `#3A99F8` ✓.
- **NEW** `primaryLight` `#EBF5FE` (chip bg "Button/Blue/Light").
- **NEW** `primaryLightActive` `#C2DFFD` (progress segment-current).

### Typography
- 24/SemiBold (`Heading 1/Bold`) — main title.
- 20/SemiBold (`Heading 2/Bold`) — section ("일별 시간 분배", week label).
- 18/SemiBold / 18/Regular (`Headline/Bold` & `Headline/Regular`) — time numbers / unit labels & CTA text.
- 14/Medium (`Label/Medium`) — describe lines & chip text.
- 14/SemiBold (`Label/Bold`) — step badge value (color primary).

### Specific controls
- Day rows: **none yet** (this is the empty state — no per-day card rendered).
- Per-day allocated time: not present; only the weekly total is displayed.
- Bottom-sheet trigger: round `+` button (component `404:45356`) — there is no inline "추가" button, only this circular plus.

### State variant
`empty` — no `BridgeDayRow` rendered, primary CTA disabled, `+` button visible. Distinguishing cue: absence of any day card between the section label and the `+` button.

### Interactions
- Tap `+` → open `BridgeTimeAllocBottomSheet` in `empty` variant.
- Tap "스케줄 보기" chip → navigate to `695-11096` (스케줄 화면).
- Tap back → return to step 2 (weekly time set).
- Tap "다음" (only when ≥1 row exists & total day allocations ≤ week total) → next route.

### Reusable components
- `BridgeStepBadge(value)` — reused from 08a.
- `BridgeProgressIndicator(currentStep, totalSteps)` — same as 02/08a.
- `BridgeWeekTimeBox(hours, minutes)` — read-only outlined box, opacity 0.8, gray200 border.
- `BridgeAddCircleButton` — 40×40 plus circle.
- `BridgeChevronChip(label="스케줄 보기")` — small primary-tinted chip.

---

## 일별 시간 설정 완료시 스케쥴 화면 (`695-11096`)

Read-only weekly schedule preview reached from "스케줄 보기" chip on the main screen.

### Layout (top → bottom)
1. Status bar + Topbar with title **"스케줄 보기"** and back button.
2. Content container left=24.5, top=105, width=327, vertical gap=40.
   - **나의 스케줄** section (gap 10):
     - Header row: "나의 스케줄" (20/SemiBold black) + 20×20 settings icon on the right (a7acb2 mask).
     - Time table 327w × 501h:
       - Day headers row (top=0): Mon–Sun cells 42w × 34h, radius 12, text 16/SemiBold gray400 `#91969E` ("월 화 수 목 금 토 일"). Gap=2.
       - Hour gutter (left=0, w=14, top=26): 18 hour labels 7..12, 1..12, 12; 12/Regular gray400 (label 7 is Medium/bold). Vertical pitch ≈27.5.
       - Time grid (left=19, top=34): 7 columns × 17 rows of `TimeSelect` cells 42w × 27h, gap col=4, gap row=0.5. Filled cells = primary `#3A99F8`, unfilled = gray150 `#EDEEF1`. Each cell has a faint inner border line.
   - **여유시간** section (gap 10): header "여유시간" (20/SemiBold) + 4 white cards, each 291×~40, radius 16, padding 18×5. Format inside a row: days string ("월, 화, 수, 목, 금, 토" / "화, 목" / "토" / "일") + thin vertical divider + "24:00" (18/SemiBold gray800).
3. UI bar bottom.

### Texts (verbatim)
- "스케줄 보기", "나의 스케줄", "여유시간", "월", "화", "수", "목", "금", "토", "일".
- Hour gutter: "7", "8", "9", "10", "11", "12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12".
- Free-time row labels: "월, 화, 수, 목, 금, 토", "화, 목", "토", "일"; trailing value "24:00".

### Colors (cross-ref + NEW)
- gray050, gray150, gray200, gray300, gray400 `#91969E` ✓, gray800, white, black, primary ✓.
- **NEW** `gray100` `#F5F7FA` (referenced in token list; used as light cell ground in pickers).
- **NEW** `highlightDarkest` `#006FFD` (declared in tokens, unused in this frame — keep for blue text highlights).

### Typography
- 20/SemiBold (`Heading 2/Bold`) — section titles.
- 18/SemiBold (`Headline/Bold`) — free-time row text.
- 16/SemiBold (`Body/Bold`) — day header.
- 12/Regular (`Caption/Regular`) — hour gutter (first label `7` and `8` are Medium).

### Specific controls
- Day rows: **read-only "free-time" cards** (4 rows by grouped weekdays).
- Per-day allocated time: shown indirectly as `24:00` for each grouped day in 여유시간 section.
- Time grid is a heat-map of selected slots — not interactive in this view.

### State variant
`schedule-read-only` of the table. Visual cue: filled cells in primary color vs. gray150 empty cells. Free-time cards always rendered as filled state.

### Interactions
- Back arrow → return to caller (`695-9743` / 13193).
- Settings icon (top-right of 나의 스케줄) → not wired in this frame.
- Cards — no tap target shown (read-only).

### Reusable components
- `BridgeWeeklyHeatmap(days: 7, rows: 17, selected: bool[7][17])`.
- `BridgeHourGutter(start=7, end=12, format=12h)`.
- `BridgeFreeTimeCard(days, time)` — same anatomy as a "filled day row" minus edit icon.

---

## 일별시간분배-바텀시트-empty (`695-12148`)

Bottom sheet opened from `+` with day chips deselected and time placeholder.

### Layout (sheet only)
- Scrim: full-screen `rgba(68,68,68,0.6)` overlay.
- Sheet: 375w × 397h, white, top corners radius 24 (`rounded-tl-[24] rounded-tr-[24]`), pinned to bottom (with bottom UI bar inside).
- Inner content container left=24.5, top=37.5, width=327.
  - **요일 선택** (gap 10):
    - Label "요일 선택" 18/SemiBold gray800.
    - Day buttons row (gap 8): 7 chips × 40×40 square, radius 12, padding 12×16. **Empty state cell**: bg `#F5F7FA` (gray100), border 1 `#D5D8DE`, text 16/Medium gray600 `#5F6165`.
  - At top=106 (inside same 192h frame): **시간 선택** (gap 10):
    - Label "시간 선택" 18/SemiBold gray800.
    - Outlined input 327×50, border 2 gray200, radius 12, opacity 0.8. Center text "00 시간 00 분" — numbers 18/SemiBold **gray300** `#A7ACB2` (placeholder color); units "시간"/"분" 18/Regular black.
- CTA "확인" 328×54 radius 8 at bottom=63 — **disabled** state (bg gray200, text gray300).

### Texts (verbatim)
- "요일 선택", "시간 선택", "월", "화", "수", "목", "금", "토", "일", "00", "시간", "분", "확인".

### Colors / Typography
- Same palette as above. **NEW** `gray600` `#5F6165` (used for inactive day chip label).
- 18/SemiBold for labels; 16/Medium for day chips; 18/SemiBold for time numbers (placeholder color = gray300).

### Specific controls — bottom sheet behavior
- 7 toggle chips (multi-select for grouping multiple days into one allocation).
- Tapping anywhere on the outlined time row opens the time picker variant of the sheet.
- Sheet is modal; tapping scrim dismisses.

### State variant — `empty`
- 0/7 day chips selected (all gray100).
- Time = `00 시간 00 분` rendered in gray300.
- CTA "확인" disabled.

### Interactions
- Tap day chip → toggle to selected (turns primary).
- Tap time row → switch sheet content to time-picker variant (`695-12742`).
- Tap "확인" (disabled until ≥1 day selected AND time > 0) → commit row & close sheet → return to main screen with new row.
- Tap scrim or system back → dismiss without commit.

### Reusable components
- `BridgeDayChip(label, selected: bool)` — also used in 02-onboarding (off variant identical).
- `BridgeTimeAllocBottomSheet(state: empty | setting | filled)`.
- `BridgeOutlinedTimeRow(hours?, minutes?, placeholder: bool)`.

---

## 일별시간분배-바텀시트 시간설정 (`695-12742`)

Same sheet, switched into the **wheel time picker** sub-state. The day selector is replaced by two scrolling wheels.

### Layout (sheet content delta)
- Sheet header: centered "시간 선택" 18/SemiBold black at top=26.86.
- Two scroll wheels:
  - **hour** column, left=92.5, top=87, w=56, h=133, items 24/SemiBold center; selected = gray800, others = gray200. Gap 17 between items. Sample sequence visible: 00, **01**, 02, 03, …10. Scroll axis vertical.
  - **min** column, left=227.5, top=85, w=56, h=139, items 24/SemiBold; selected = gray800; gap 20. Sample: 00, **05**, 10, 15, 15, 15, 30, 35, 20, 40, 50, 55.
- Selection band: full-width strip left=25.5, top=128, w=324, h=50; borders only `border-y: 2px solid #3A99F8`, opacity 0.8. Inside band: trailing units "시간" (left ≈144.83) and "분" (left ≈287.64), each 20/Medium black. (Type token `Heading 2/Medium` introduced here.)
- CTA "확인" 327×54 radius 8 at bottom=63 — **primary enabled** (bg `#3A99F8`, text 18/Medium white).

### Texts
- "시간 선택", "시간", "분", "확인" + the numeric wheel labels.

### Colors / Typography
- Adds primary `#3A99F8` as horizontal band borders, white CTA text.
- **NEW** typography `Heading 2/Medium` (20/Medium) — unit labels inside the selection band.
- Wheel numbers: 24/SemiBold, color `#2F3032` (selected) / `#D5D8DE` (others).

### Specific controls — bottom sheet behavior
- Two independent infinite/scrollable wheels (CupertinoPicker-like). Center selection band is fixed; user drags numbers under the band.
- Header "시간 선택" replaces day chip block.
- CTA enabled the moment user is in this state (allows committing current wheel position; product may also enable only when > 00:00).

### State variant — `setting` (time-picker active)
- Distinguishing cues: header reads "시간 선택"; two number wheels instead of day chips; primary-colored horizontal band; CTA enabled in primary.

### Interactions
- Wheel drag → updates current hour/minute.
- "확인" → write value back to sheet state, switch sheet back to the day-chip layout (now in `filled` variant) OR close sheet & commit row if both day & time picked. (Implementation choice; recommended: two-pass — first sets time, returns to day-picker variant.)

### Reusable components
- `BridgeWheelPicker(items, selectedIndex)` (one for hours, one for minutes).
- `BridgeTimeAllocBottomSheet(state: setting)` — same outer shell.

---

## 일별시간분배-바텀시트-채움 (`695-13019`)

Sheet returns to the day-chip view but now with **some chips selected** and the time row populated. CTA enabled.

### Layout (sheet content delta)
- Same 요일 선택 / 시간 선택 frames as `empty`. Differences only inside the chips and the time row.
- Day chip row, gap 8:
  - "월" — **selected** (bg primary `#3A99F8`, text 16/SemiBold white).
  - "화" — unselected (gray100/gray200/gray600).
  - "수" — selected.
  - "목" — unselected.
  - "금" — selected.
  - "토" — unselected.
  - "일" — unselected.
- Time row text now reads **"02 시간 30 분"** with numbers `02` and `30` colored primary `#3A99F8` (18/SemiBold), units kept black (18/Regular). Border still gray200, opacity 0.8.
- CTA "확인" enabled — bg primary, text 18/Medium white, width 327.

### Texts
- Same labels; chip labels Mon–Sun; "02", "시간", "30", "분", "확인".

### Colors
- Same palette plus selected-chip uses primary fill + white text.
- Selected-numbers in time row use primary `#3A99F8` instead of placeholder gray300.

### Typography
- Selected chip label: 16/SemiBold white (`Body/Bold`).
- Unselected chip label: 16/Medium gray600 (`Body/Medium`) — **NEW** token tier.

### State variant — `filled` (chip view with selections)
Distinguishing cues vs `empty`:
1. ≥1 day chip filled (primary bg + white SemiBold text).
2. Time row digits colored primary (not gray300).
3. CTA "확인" enabled (primary bg + white text), no longer gray200.

### Interactions
- Tap any chip → toggle selection (re-rendering as `empty` if none remain selected).
- Tap time row → re-open wheel picker (`setting` variant).
- Tap "확인" → close sheet & emit a new (or updated) `DayAllocation { days: [...], hours, minutes }` to the parent screen → triggers `filled` state on `695-13193`.

### Reusable components
- Same as empty + selected chip variant of `BridgeDayChip`.

---

### Bottom-sheet variant deltas (12148 / 12742 / 13019) — state machine

Implement as a **single widget** `BridgeTimeAllocBottomSheet` with `enum BottomSheetMode { dayPicker, timePicker }` and a draft model.

| Aspect | empty (12148) | setting (12742) | filled (13019) |
|---|---|---|---|
| Mode | `dayPicker` | `timePicker` | `dayPicker` |
| Body header | "요일 선택" 18/SemiBold | "시간 선택" 18/SemiBold (centered) | "요일 선택" 18/SemiBold |
| Body content | 7 day chips (all off) + outlined time row placeholder | Hour wheel + min wheel + horizontal primary band | 7 day chips (mixed) + outlined time row showing selected primary numbers |
| Time row text color | "00"/"00" in gray300 | n/a (replaced by wheels) | "02"/"30" in primary |
| Chip selected styling | none | n/a | primary bg + white 16/SemiBold |
| CTA "확인" | disabled gray200 / gray300 | primary enabled | primary enabled |
| CTA width | 328 | 327 | 327 |
| Tap chip | toggle | n/a | toggle |
| Tap time row | switch mode → timePicker | n/a | switch mode → timePicker |
| "확인" action | (disabled) | commit wheels → mode=dayPicker | commit row → close sheet |

Single source-of-truth: `draft = { Set<int> selectedDays, int hours, int minutes }`. CTA enabled iff `selectedDays.isNotEmpty && (hours + minutes) > 0` in `dayPicker`; always enabled in `timePicker`.

---

## 일별시간분배-filled (`695-13193`)

Main screen after a row has been committed. Shows ≥1 `BridgeDayRow` between the section label and the `+` button.

### Layout (top → bottom)
Identical to `695-9743` (empty) for status bar, topbar, progress, titleset, week-time, label row, CTA. Differences:
- Daily Distribution Container changes to a tappable column ("cursor-pointer flex") with gap=20:
  1. Label row (with chip "스케줄 보기").
  2. **Daily Distribution Row** — 328.25w container holding one Day card.
  3. Round `+` button (still present, centered).
- **Day card** (`BridgeDayRow`): white bg, radius 16, padding 18×15, content row h=45 w=291:
  - Left: "월, 수, 금" 18/SemiBold gray800.
  - Vertical divider (0w line, h=22, draws as 1px via inset hack).
  - Time block (gap 15):
    - hour group (gap 10): "2" 18/SemiBold + "시간" 18/Regular.
    - minute group (gap 10): "30" 18/SemiBold + "분" 18/Regular.
  - Right end: 24×24 **edit pencil icon** (component "수정").

### Texts (verbatim)
Same chrome as 9743 plus the day card example: "월, 수, 금", "2", "시간", "30", "분".

### Colors
- Card bg = white, content gray800, edit icon mask color (Group asset).
- Otherwise identical token set.

### Typography
- 18/SemiBold for days + numeric values, 18/Regular for unit labels.

### Specific controls — day row anatomy
`BridgeDayRow({ required String daysLabel, required int hours, required int minutes, required VoidCallback onEdit })`
- Outer: `Container(decoration: rounded16 white, padding EdgeInsets.symmetric(h:18, v:15))`.
- Row: `Row(MainAxisAlignment.spaceBetween, children:[Row(gap:20,[Text(daysLabel), Divider(vertical, h:22, color:gray200), Row(gap:15,[hour, min])]), EditIcon])`.
- hour = `Row(gap:10,[Text('$hours', 18/SemiBold), Text('시간', 18/Regular)])`.
- min = `Row(gap:10,[Text('$minutes', 18/SemiBold), Text('분', 18/Regular)])`.

### State variant — `filled`
Distinguishing cue vs `empty`: presence of one or more `BridgeDayRow` widgets. The "다음" CTA may transition from disabled→enabled only once allocations cover the weekly total (this is product logic; design still shows it disabled in the captured frame — keep disabled style until validation passes).

### Interactions
- Tap pencil icon (or anywhere on the card per the wrapper `<a>`) → re-open `BridgeTimeAllocBottomSheet` in `filled` (= editing) mode pre-filled with that row's values.
- Tap `+` → open empty sheet to add another row.
- Tap "스케줄 보기" → navigate to 11096.
- Tap "다음" once valid → finalize and proceed (route depends on flow; ends onboarding step 3).

### Reusable components
- `BridgeDayRow` — same anatomy as `BridgeFreeTimeCard` from 11096 (could share with optional trailing widget).
- `BridgeAddCircleButton` shared with empty.
- `BridgeTimeAllocBottomSheet` shared.

---

## Token additions summary

Append to the design-tokens file (suggested keys):
- `gray100 = #F5F7FA`
- `gray600 = #5F6165`
- `primaryLight = #EBF5FE` (Button/Blue/Light)
- `primaryLightActive = #C2DFFD` (Button/Blue/Light :active — progress current)
- `highlightDarkest = #006FFD` (reserved; not yet used in these frames)
- Typography: `heading2Medium` = Pretendard Medium 20 / 1.4 / -1.2 (selection band units in wheel sheet).

Existing tokens reused: `primary #3A99F8`, gray050/150/200/300/400/500/800, black, white, `Pretendard 24/20/18/16/14/12 × B/M/R`, pageHorizontal=24, sectionGap≈40, itemGap≈12-20, cardRadius=16 (note: NOT 28 here — daily-distribution cards use radius 16, sheet uses radius 24 top-only).
