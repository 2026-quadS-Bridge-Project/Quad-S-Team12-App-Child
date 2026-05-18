# 08c — 시간 설정 v1: Errors & Completion

Source: Figma file `tzJjQmXtXO7vGlfCT9SASu`
Screen family: Step 3 of 일별 시간 분배 (initial weekly time setup) + final completion screen.

Frame size: 375 × 812 (iPhone). All horizontal content is centered on a 327px content width with `pageHorizontal = 24`.

---

## 시간초과 — error 설정시간초과 (`695:10675`)

State of step 3 when the user has distributed **more** total daily hours than the weekly budget allows (e.g. weekly = 15h, distributed sum > 15h).

### Layout (top → bottom)
1. iOS status bar (44h)
2. `cmp/topbar` — back-button only, empty title (52h)
3. Progress indicator — 3 segment bars, 55×7 each, gap 15, centered top:67.5
   - Seg 1: gray-150 `#EDEEF1` (미선택)
   - Seg 2: gray-150 (current — note that the active blue is NOT shown on this error frame; both step 1 & 2 render as gray, step 3 as light-blue `#C2DFFD`)
   - Seg 3: `#C2DFFD`
4. **Container** (left 23.65, top 105, vertical gap 40):
   - **titleset** (gap 12):
     - Title row: step badge `3` (28px) + `이번주 일간 시간 설정` (Heading1 24/SemiBold, color black)
     - Describe: `거의 다 왔어요!` / `내가 설정한 이번주의 시간을 일별로 분배해요.` (14 Medium, gray-500 `#777A7F`)
   - **week time** block (gap 12):
     - `2월 1주차` (20 SemiBold, gray-800)
     - Time frame card — 327×50, border 2 gray-200 `#D5D8DE`, opacity 80, radius 12, contents: `15 시간 00 분` (18, SemiBold values + Regular units)
   - **Daily Distribution** block (gap 20, centered):
     - Header row: `일별 시간 분배` (20 SemiBold) + right-aligned pill button `스케줄 보기 ›` (bg `#EBF5FE`, text `#3A99F8` 14 Medium, h31, radius 7, pl 13, gap 10)
     - 3 row cards (gap 15), bg white, radius 16, padding 18×15, h ≈ 75:
       - `월, 수, 금  │  7 시간 00 분  [✎]`
       - `화, 목      │  7 시간 00 분  [✎]`
       - `토, 일      │  7 시간 00 분  [✎]`
       - Day label: 18 SemiBold gray-800. Divider: vertical 22px line. Edit pencil 24×24 on the right.
     - **Error banner** (see anatomy below): 327×~46, bg `#FFD3D3`, radius 8, padding 17×10, **right-aligned** text `+ 00시간 00분` in destructive `#FF4242` 18 Medium.
5. CTA `다음` — disabled, full-width 327×54, bg gray-200 `#D5D8DE`, text gray-300 `#A7ACB2` 18 Medium, radius 8, bottom 63
6. iOS home indicator bar (32h)

### Texts (verbatim)
- Title: `이번주 일간 시간 설정`
- Subtitle: `거의 다 왔어요!` (line 1, trailing space preserved) / `내가 설정한 이번주의 시간을 일별로 분배해요.`
- Week label: `2월 1주차`
- Week budget: `15` `시간` `00` `분`
- Section: `일별 시간 분배 `
- Action chip: `스케줄 보기`
- Row labels: `월, 수, 금` / `화, 목` / `토, 일`
- Per row value: `7` `시간` `00` `분`
- CTA: `다음`
- **Error message: `+ 00시간 00분`** (the `+` indicates surplus over budget)
- Annotation (designer note, do not render): `초과분 / 00시간 00분을 위의 설정사항에서 빼서 시간내로 맞춰야, 다음으로 넘어갈 수 있음.`

### Colors (cross-ref + NEW)
| Token | Hex | Use |
|---|---|---|
| gray-050 | `#FAFBFC` | page bg (✓ existing) |
| gray-150 | `#EDEEF1` | progress inactive (✓) |
| gray-200 | `#D5D8DE` | time frame border, disabled CTA bg (✓) |
| gray-300 | `#A7ACB2` | disabled CTA text (✓) |
| gray-500 | `#777A7F` | subtitle (✓) |
| gray-800 | `#2F3032` | section headers, row text (✓) |
| primary  | `#3A99F8` | step badge text, chip text, active step seg base (✓) |
| primary-light (Button/Blue/Light) | `#EBF5FE` | chip bg (✓ confirm) |
| primary-light-active (Button/Blue/Light :active) | `#C2DFFD` | progress seg 3 (✓ confirm) |
| destructive | `#FF4242` | error message text (✓) |
| **NEW** error-banner bg | `#FFD3D3` | error banner background (Figma token `Foundation/Violet/Normal` — semantically destructive-100/light) |

### Typography
- Pretendard `SemiBold 24 / 1.364 / -0.4656` → Heading1 Bold (title)
- Pretendard `SemiBold 20 / 1.4 / -0.24` → Heading2 Bold (`2월 1주차`, `일별 시간 분배`)
- Pretendard `SemiBold 18 / 1.445 / -0.0036` + `Regular 18` → Headline Bold/Regular (time values + units; row days)
- Pretendard `Medium 18 / 1.445 / -0.0036` → Headline Medium (CTA, banner)
- Pretendard `Medium 14 / 1.429 / 0.203` → Label Medium (subtitle, chip)
- Pretendard `SemiBold 14 / 1.429 / 0.203` → Label Bold (step badge numeral)

### Error banner anatomy
- **Inline**, page-level (sits at the bottom of the list, above the CTA — *not* a toast, *not* an alert dialog).
- Single-line pill: full content width (327), radius 8, padding 17×10, **right-aligned** content (`justify-end`).
- No icon, no dismiss/close action.
- Single text line in destructive color showing the **delta** (`+ HH시간 MM분` for overflow).
- Behavior implication: CTA `다음` is disabled while delta ≠ 0. (CTA bg/text confirm disabled palette.)
- Designer marked an "edit-request area" overlay (red dashed border `#FF7878`, 326×254, top 420) covering the 3 row cards — this is a *non-rendered Figma annotation* indicating "this whole block needs to be edited"; not a UI element.

### Reusable components
- `BridgeProgressIndicator(steps: 3, current: 3, currentColor: primaryLightActive)`
- `BridgeStepBadge(value: int)` — 28px circle (image asset), centered SemiBold 14 primary numeral
- `BridgeWeekTimeCard(hours, minutes, dimmed: true)` — bordered display, opacity 80
- `BridgeDailyTimeRow(daysLabel, hours, minutes, onEdit)` — white radius-16 card
- `BridgeChipButton(label: '스케줄 보기', trailing: chevronRight, variant: primaryLight)`
- **`BridgeDeltaBanner(variant: .over)`** — bg `#FFD3D3`, text `#FF4242`, displays `+ HHh MMm`

### Interactions
- Tap pencil icon on row → open per-row time-edit sheet
- Tap `스케줄 보기` chip → open weekly schedule preview
- `다음` disabled until delta = 0
- Back button → previous step (weekly total)

---

## 시간남음 — error 설정시간남음 (`695:10817`)

Mirror of the 초과 screen, but the user has distributed **less** than the weekly budget.

### Layout
Identical to `695:10675` (same container, week card, 3 row cards, CTA). The only difference is the **delta banner**.

### Texts (verbatim)
Same as above except the banner:
- **Banner: `- 00시간 00분`** (the `-` indicates remaining/under-allocated time)
- Annotation: `부족분 / 아직 00시간이 남았다는 의미`

All other strings (`이번주 일간 시간 설정`, `거의 다 왔어요!`, …, `다음`) are identical to 695:10675.

### Colors — NEW token only for banner
| Token | Hex | Use |
|---|---|---|
| primary-light (Button/Blue/Light) | `#EBF5FE` | banner bg (under-budget) (✓ already in palette as chip bg) |
| primary | `#3A99F8` | banner text (✓) |

> Note: The 부족분 banner reuses the **primary-light** palette (informational/positive cue) — *not* cautionary `#FF9200`. The design treats "남음" as a non-error informational state (user is on the right track, just needs to allocate more) while "초과" is the destructive state.

### Typography
Same as 695:10675; banner text uses Pretendard `Medium 18 / 1.445 / -0.0036` (Headline Medium) in primary `#3A99F8`.

### Error banner anatomy
- Same inline pill geometry (327×~46, radius 8, padding 17×10, right-aligned, no icon, no dismiss).
- Two semantic variants:
  - `.over` → bg `#FFD3D3`, text `#FF4242`, prefix `+`
  - `.under` → bg `#EBF5FE`, text `#3A99F8`, prefix `-`
- Outer "edit-request" dashed overlay border on this screen is blue `#3A99F8` (vs red on 초과) — again, Figma-only annotation.

### Reusable components
- Same as 695:10675. `BridgeDeltaBanner` should support both variants via enum:
  ```
  enum BridgeDeltaVariant { over, under }
  // .over   -> Foundation/Violet (#FFD3D3) bg + destructive (#FF4242) text + "+" prefix
  // .under  -> primaryLight (#EBF5FE) bg + primary (#3A99F8) text + "-" prefix
  ```

### Interactions
- Identical to 695:10675. `다음` remains disabled until delta = 0.

---

## 초기 시간 설정 완성 — filled / valid state (`695:11487`)

Step 3 in its **valid (success-ready) state**: all daily allocations sum exactly to the weekly budget. No delta banner is rendered, and the CTA becomes the active primary button.

> Naming clarification: Figma calls this frame `scr/child-초기 시간설정-일별시간분배-filled`. "완성" here means the step-3 form is fully filled and validated — it is **not** a celebration/success screen. It is the same screen as the two error frames with the banner removed and the CTA enabled.

### Layout (top → bottom)
Identical structure to the error frames:
1. Status bar (44)
2. Topbar (52, back only)
3. Progress indicator (3 segments — seg 3 is `#C2DFFD`)
4. Container (top 105, gap 40):
   - titleset (step 3 badge + `이번주 일간 시간 설정` + subtitle)
   - week time card (`2월 1주차` + `15시간 00분`)
   - Daily Distribution (header + chip + 3 row cards)
   - **No banner.**
5. CTA `다음` — **enabled**, bg primary `#3A99F8`, text white, 327×54, radius 8, bottom 63, `cursor-pointer`
6. Home indicator (32)

### Texts (verbatim)
Same as the error frames minus the banner. CTA: `다음`.

### Colors
All existing tokens. Notable change vs error frames:
- CTA bg: `#3A99F8` (primary) — replaces gray-200 disabled
- CTA text: `#FFFFFF` — replaces gray-300

### Typography
Identical to 695:10675.

### Error banner / completion anatomy
- N/A. This is the "no error" variant. The delta banner is omitted; total vertical height of the daily list shrinks accordingly.

### Reusable components
Reuses all `BridgeStepBadge`, `BridgeProgressIndicator`, `BridgeWeekTimeCard`, `BridgeDailyTimeRow`, `BridgeChipButton`, plus the project's primary `BridgePrimaryButton` for the active CTA. **No `BridgeDeltaBanner` instance.**

### Interactions
- Edit pencil → row time-edit sheet (will re-validate sum on save; if invalid, the same screen re-renders with a `BridgeDeltaBanner` and the CTA flips to disabled)
- `스케줄 보기` → weekly schedule preview
- `다음` (enabled) → navigates to **완료** screen `695:12086`
- Back → previous step

---

## 초기 시간 설정 완료 — completion / success (`695:12086`)

Final celebration screen shown after the user successfully submits the weekly+daily plan from `695:11487`.

### Layout (top → bottom)
1. Status bar (44)
2. `cmp/topbar` — back-button only, empty title (52)
3. **Main container** — centered horizontally, top 213, vertical gap 40, items-center:
   - **Title**: `시간 설정 완료!` (24 SemiBold, black `#050505`, centered, width 328)
   - **Success illustration**: 60×60, a blue-filled circle (`Ellipse 40`) with a white check mark vector. Tokens: outer circle uses primary `#3A99F8`; check is white. This is a *reusable* "success check" icon.
   - **Message block** (centered, width 328, 16 SemiBold black, line-height 1.5):
     - Line 1: `이번주 시간 계획이 부모님께 전달되었어요.`
     - Line 2: `이제 계획대로 사용해봐요!`
4. CTA `홈으로` — primary, 327×54, bg `#3A99F8`, text white 18 Medium, radius 8, bottom 63, centered
5. Home indicator (32)

> Note: Figma's `Button` default propValue is `홈으로`; the instance on this frame does not override it, so the rendered label is **`홈으로`**.

### Texts (verbatim)
- Heading: `시간 설정 완료!`
- Message line 1: `이번주 시간 계획이 부모님께 전달되었어요.`
- Message line 2: `이제 계획대로 사용해봐요!`
- CTA: `홈으로`

### Colors
| Token | Hex | Use |
|---|---|---|
| gray-050 | `#FAFBFC` | bg |
| primary | `#3A99F8` | success check circle, CTA bg |
| white | `#FFFFFF` | check mark, CTA text |
| black `#050505` (effectively gray-900 family) | title + message |

No new tokens — reuses primary for both icon and CTA.

### Typography
- Heading: Pretendard `SemiBold 24 / 1.364 / -0.4656` (Heading1 Bold)
- Body message: Pretendard `SemiBold 16 / 1.5 / 0.0912` → **Body Bold** (this is a *new typography reference* if `Body Bold 16` is not yet in the design-token map; spec token: `Body/Bold`)
- CTA: Pretendard `Medium 18 / 1.445 / -0.0036` (Headline Medium)

### Completion anatomy
- **Page-level success screen** (not a banner, not a toast).
- Vertical center stack: title → icon → message (gaps of 40).
- Single primary CTA at the bottom returning the user home.
- No dismiss "X", no secondary action (no "edit", no "share").

### Reusable components
- `BridgeSuccessIcon(size: 60)` — primary-filled circle + white check; reusable for any "completed" feedback throughout the app
- `BridgeCompletionScreen({ title, message: [line1, line2], cta: { label, onPressed } })` — generic celebration layout that takes the above icon as the visual hero
- `BridgePrimaryButton(label: '홈으로', onPressed)` (already exists in the design system)

### Interactions
- `홈으로` → navigate to child home (replace stack, no back to setup flow)
- Back button in topbar: present but flow should probably either disable it or also route home — confirm with PM.

---

## 완성 (11487) vs 완료 (12086) — what's the difference?

| | 완성 — `695:11487` | 완료 — `695:12086` |
|---|---|---|
| Korean nuance | 완성 = "fully filled in / form complete" | 완료 = "done / finished" |
| Screen role | **Summary / review** of step 3 with all values validated; *pre-submit* | **Success / celebration**; *post-submit* |
| Layout | Same as the two error screens (progress, week card, 3 daily rows) | Centered hero stack: title + check icon + message |
| Progress indicator | Visible (3-step) | **Removed** |
| Delta banner | None (because valid) | N/A |
| Hero visual | None | 60×60 blue circle with white check |
| CTA | `다음` (advances to 완료) | `홈으로` (exits flow to home) |
| Edit affordances | Pencil per row, chip "스케줄 보기" | None |
| Confirmation copy | None — just the form | `시간 설정 완료! / 이번주 시간 계획이 부모님께 전달되었어요. / 이제 계획대로 사용해봐요!` |

In short: **11487 is the validated review state** (user can still edit; tapping `다음` submits), **12086 is the success acknowledgement** (server confirmed; plan delivered to parent; one-tap exit).

---

## Token additions summary

Add to design tokens:

```dart
// Color
const errorBannerBg = Color(0xFFFFD3D3);   // destructive-100 / Foundation/Violet/Normal
// (Optional alias) infoBannerBg = primaryLight (#EBF5FE) — already present
// (Optional alias) destructive = #FF4242 — already present

// Typography
TextStyle bodyBold = pretendard(16, FontWeight.w600, height: 1.5, letterSpacing: 0.0912);
```

All other styles map to existing Bridge_K tokens.
