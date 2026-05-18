# 시간 설정 확인 (Time Settings Review — Child)

**File**: `tzJjQmXtXO7vGlfCT9SASu`
**Frame names**: `scr/child-시간설정-설정시간확인-{all empty | filled | tip}`
**Role confirmation**: This is the **CHILD app**. All three frames are read-only views of a schedule **set by the parent**. The tip explicitly says "꼭 필요한 경우에 부모님의 시간 설정 탭에서 허락을 받아, 수정할 수 있어요" — i.e. the child cannot directly edit; they must request the parent. No approve/reject CTA exists. The single bottom CTA is "확인" (Confirm/Acknowledge).

**Sequence ordering** (intended UX flow): `744-11326` (empty state) → `662-11322` (filled state) → `662-11249` (filled state + tip tooltip on first visit).

---

## 시간 설정 확인 1 (`744-11326`) — All Empty

**Layout** (top → bottom)
1. Status Bar (44px) — system mocks
2. Topbar (52px) — center title, back chevron at left 24px
3. Empty-state message centered (top ~380px from screen top)
4. Primary CTA "확인" (bottom 63px, full-width minus 24px gutters)
5. UI bar (32px home indicator)

**Texts** (verbatim Korean)
- Topbar: `시간설정`
- Empty message: `이번달 시간규칙이 설정되지 않았습니다.`
- CTA: `확인` (rendered as image asset in Figma, label text "확인")

**Colors** (cross-ref + NEW)
- Bg `#FAFBFC` = gray050
- Topbar title `#050505` (existing topbar token — near-black, not gray900)
- Empty-state text `#A7ACB2` = gray300
- CTA bg `#3A99F8` = primary
- CTA label `#FFFFFF` = white

**Typography**
- Topbar: Pretendard Medium 18 / 1.445 / -0.0036 (existing Headline/Medium)
- Empty message: Pretendard Medium 18 / 1.445 / -0.0036, color gray300
- CTA label: Pretendard Medium 18 / 1.445, white

**Confirmation content**: None — empty schedule placeholder. Only the global "확인" button to dismiss/acknowledge.

**Interactions**
- Back chevron → previous screen
- 확인 → ack (likely pops back to home / mypage). No approve/reject, no message field.

**Reusable components**
- `BridgeTopbar(title)` — reuse existing
- `BridgePrimaryButton(label: "확인")` — full-width 54h, radius 8, primary bg
- `BridgeEmptyMessage(text)` — centered gray300 18/Medium

---

## 시간 설정 확인 2 (`662-11322`) — Filled

**Layout** (top → bottom)
1. Status Bar (44px)
2. Topbar (52px) — title `시간설정`, back chevron
3. **Weekly Usage section** (top ≈ 104px, left 23.83px, width 325px)
   - Section title `2월 1주 사용 시간` (SemiBold 20, gray800)
   - Total-time read-only display box (border gray200 2px, radius 12, height 50, opacity 80%) showing `15시간 00분` centered
4. Divider — `#EDEEF1` (gray150), full-width 374×7px at y≈230
5. **Daily Plan section** (offset 80px gap from Weekly)
   - Section title `일간 사용 계획` (SemiBold 20, gray800)
   - "수정하기" pill button (right-aligned within header row, gray150 bg, gray300 label, radius 7, height 31, with pencil icon)
   - 3 stacked plan cards (white bg, radius 16, padding 18×15, gap 15)
     - Card 1: `월, 수, 금` | divider | `7시간 00분`
     - Card 2: `화, 목` | divider | `7시간 00분`
     - Card 3: `토, 일` | divider | `7시간 00분`
6. Primary CTA `확인` (bottom 63px)
7. UI bar

**Texts** (verbatim Korean)
- Topbar: `시간설정`
- Weekly title: `2월 1주 사용 시간`
- Weekly value: `15` `시간` `00` `분`
- Daily title: `일간 사용 계획`
- Edit pill: `수정하기`
- Card 1 days: `월, 수, 금` | value: `7` `시간` `00` `분`
- Card 2 days: `화, 목` | value: `7` `시간` `00` `분`
- Card 3 days: `토, 일` | value: `7` `시간` `00` `분`
- CTA: `확인`

**Colors** (cross-ref + NEW)
- Bg `#FAFBFC` = gray050
- Card bg `#FFFFFF` = white
- Section titles `#2F3032` = gray800
- Body values `#050505` (near-black, existing topbar token)
- Border on weekly box `#D5D8DE` = gray200
- Divider + edit-pill bg `#EDEEF1` = gray150
- Edit-pill label `#A7ACB2` = gray300
- CTA `#3A99F8` / white = primary / white

**Typography**
- Section title: Pretendard SemiBold 20 / 1.4 / -0.24 (Heading 2/Bold) — NEW token: `Heading2Bold` (20/SemiBold)
- Day label & numeric: Pretendard SemiBold 18 / 1.445 / -0.0036 (Headline/Bold)
- Unit suffix (시간/분): Pretendard Regular 18 / 1.445 / -0.0036 (Headline/Regular)
- Weekly value `15` & `00`: SemiBold 18; suffix Regular 18
- Edit pill label: Pretendard Medium 14 / 1.429 / +0.203 (Label/Medium)
- CTA label: Pretendard Medium 18

**Confirmation content**: Read-only summary
- Total weekly time (single boxed value)
- 3-row daily plan list grouped by day-set (월수금 / 화목 / 토일)
- NOT a weekly grid, NOT a calendar — just summary cards
- NO approve/reject, NO message field

**Interactions**
- 수정하기 pill → likely navigates to a request-edit flow (child cannot directly edit per the tip)
- 확인 → acknowledge / dismiss
- Back chevron → previous screen

**Reusable components**
- `BridgeWeeklyTotalBox(hours, minutes)` — bordered gray200 read-only box, radius 12
- `BridgeDailyPlanCard(days: String, hours: int, minutes: int)` — white card radius 16, day-label + vertical divider + time
- `BridgePillIconButton(icon, label)` — gray150 pill, gray300 label, radius 7 (used for "수정하기")
- `BridgeSectionDivider` — gray150 7px-thick horizontal bar
- `BridgeTopbar`, `BridgePrimaryButton` — reuse

---

## 시간 설정 확인 3 (`662-11249`) — Filled + Tip

Identical to `662-11322` plus a tooltip card overlaying near the "수정하기" pill.

**Layout** (top → bottom)
1–6: same as filled
7. **Tip tooltip** (top ≈ 323px, ~255×150px, centered-ish under the edit pill)
   - Dark gray rounded box with triangular notch pointing up toward the 수정하기 pill
   - Title + bulleted list inside
   - Small X / close vector at top-right inside the tooltip

**Texts** (verbatim Korean)
- Tooltip title: `시간 계획 수정은 어떻게 하나요?`
- Bullet 1: `시간 설정은 주 1회 진행돼요. 이번주 시간계획이 미흡했다면 다음주에 반영해서 수정해봐요!` (the phrase `주 1회` is underlined)
- Bullet 2: `꼭 필요한 경우에 부모님의 시간 설정 탭에서 허락을 받아, 수정할 수 있어요.` (the phrase `시간 설정 탭` is underlined)

**Colors** (cross-ref + NEW)
- Tooltip bg `#5F6165` = gray600
- Tooltip title `#FFFFFF` = white
- Bullet body `#F5F7FA` = gray100
- Triangle notch `#5F6165` (same as bg)

**Typography**
- Tooltip title: Pretendard SemiBold 12 / 1.334 / +2.52 (Caption/Bold)
- Bullets: Pretendard Regular 12 / 1.334 / +2.52 (Caption/Regular), with `underline` decoration on highlighted phrases

**Confirmation content**: same summary as state 2 + onboarding tip

**Interactions**
- Tap outside tooltip / X → dismiss tooltip (likely first-launch-only via flag)
- 수정하기 → request-edit flow (still indirect — child must ask parent)
- 확인 → acknowledge

**Reusable components**
- `BridgeOnboardingTooltip({title, bullets, anchor})` — gray600 rounded-12 card with directional triangle notch, dismissible, supports inline underline spans
- All other components same as state 2

---

## New / confirmed tokens to add
- `gray600` = `#5F6165` (tooltip bg) — NEW
- `gray100` = `#F5F7FA` (tooltip body text) — NEW
- `gray150` = `#EDEEF1` (divider, pill bg) — confirm/add
- `gray200` = `#D5D8DE` (box border) — confirm/add
- `gray800` = `#2F3032` (section titles) — confirm/add
- `nearBlack` = `#050505` (topbar + body numeric) — confirm/add (distinct from gray900 `#171818`)
- Typography: `Heading2Bold` = Pretendard SemiBold 20/1.4/-0.24 — NEW
- Typography: `CaptionBold` = Pretendard SemiBold 12/1.334/+2.52 — NEW
- Typography: `CaptionRegular` = Pretendard Regular 12/1.334/+2.52 — NEW
- Typography: `LabelMedium` = Pretendard Medium 14/1.429/+0.203 — NEW
- Typography: `HeadlineRegular` = Pretendard Regular 18/1.445/-0.0036 — NEW (companion to existing Headline/Medium & Bold)
- Component note: CTA in these screens uses radius **8** (not the global `cardRadius=28`). Keep a separate `buttonRadius=8` token.

## Hypothesis verdict
**Confirmed**: Child-side READ-ONLY review of a schedule set by the parent. There is NO approve/reject/수정요청 button — only `확인` (acknowledge) and an indirect `수정하기` pill that (per the tip) routes through the parent. So this is closer to "view + ack" than the originally hypothesised "approve+reject+send-back" pattern. Components `BridgeApproveRejectActions` and `BridgeScheduleSummaryCard` should be renamed accordingly — propose `BridgeWeeklyTotalBox` + `BridgeDailyPlanCard` + single `BridgePrimaryButton(label: "확인")`.
