# 06 — Notifications (알림)

Source: Figma `tzJjQmXtXO7vGlfCT9SASu`. Screens covered: empty state, filled list, and two "delete" interaction frames (swipe + confirmation dialog).

Conventions: cross-references like `gray050`, `primary` map to the existing token catalog. NEW tokens are listed under each section and consolidated at the bottom.

---

## 알림 탭 — empty/default (`426-19287`)

Figma name: `scr/child-alert-empty`.

### Layout (top → bottom)
- **Status bar** (44 px) — system chrome.
- **Top bar / Header** (height 52 px, padding `22 / 5`) — back button (`btn/back`, 24 px) at left (`left: 24`), centered title `알림` (Pretendard Medium 18).
  - No tab bar — single "알림" screen reached via back navigation.
- **Empty state body** — screen background `#F5F7FA` (`gray100`). A single centered helper line at approximately `top: 393` reading `확인하지 않은 알림이 없습니다.` No illustration, no CTA, no list.
- **Home indicator bar** (32 px) at bottom.

### Texts (verbatim)
- Header: `알림`
- Empty copy: `확인하지 않은 알림이 없습니다.`

### Colors
- Background: `#F5F7FA` → `gray100`
- Header title: `#050505` → near-black (use `gray900` or a new `headerInk`)
- Empty copy: `#A7ACB2` → `gray300`

### Typography
- Header `알림`: Pretendard Medium 18 / line-height 1.445 / letter-spacing −0.02 → `Headline/Medium`
- Empty copy: Pretendard Medium 18 / 1.445 → reuses `Headline/Medium` (color `gray300`)

### Notification tile structure
N/A — empty state has no tiles.

### Delete interaction
N/A.

### Empty vs filled differences
- No list scroll area, no card backgrounds, no icon chips.
- Single centered short string positioned at ~46% of viewport height (no illustration in this revision).

### Reusable components consumed
- `BridgeTopBar` (back + centered title) — same as elsewhere.
- `BridgeEmptyState` text-only variant (no image) — new.

---

## 알림 탭 — 컴포넌트 O (filled) (`426-19293`)

Figma name: `scr/child-alert-filled`. Six notification cards stacked in a `Form` column, gap `15 px`, starting at `top: 119.56` and centered horizontally (width `327`).

### Layout (top → bottom)
- **Status bar** (44 px).
- **Top bar** (52 px) — back + centered title `알림` (identical to empty).
- **Form / list** — vertical stack, `gap: 15`, items width `327`, padding `16 / 14`, radius `12`, background `white`. Order shown in Figma:
  1. 위클리 사용 리포트 (positive)
  2. 시간설정 완료 (primary blue)
  3. 미션 완료 (secondary yellow, "AI가 확인")
  4. 미션 완료 (secondary yellow, "부모님이 확인")
  5. 미션 반려 (destructive red, "부모님이 반려")
  6. 미션 반려 (destructive red, "AI가 반려…부모님 확인 중")
- **Home indicator** (32 px).

### Texts (verbatim)
Per tile (title / body):
1. `위클리 사용 리포트` / `2월 1주차 사용 분석이 담긴 리포트가 도착했어요!\n리포트를 통해 더 나은 계획을 세워봐요.`
2. `시간설정 완료` / `부모님이 1월달 총 사용 시간을 설정했어요!\n이제 시간을 분배할 시간이에요!`
3. `미션 완료` / `숙제하기 미션 수행을 AI가 확인했어요.\n보너스 시간 15분 획득!`
4. `미션 완료` / `숙제하기 미션 수행을 부모님이 확인했어요.\n보너스 시간 15분 획득!`
5. `미션 반려` / `숙제하기 미션 수행을 부모님이 반려했어요.`
6. `미션 반려` / `숙제하기 미션 수행을 AI가 반려했어요.\n부모님이 한번더 확인중이에요.`

Common per tile:
- Timestamp: `15분 전`
- CTA link: `확인하러 가기 →`

(Note: the source uses both `미션완료` and `미션 완료` for the success label — normalise to `미션 완료` in code.)

### Colors
- Card background: `#FFFFFF` → `white`
- Screen background: `#F5F7FA` → `gray100`
- Title colors by type:
  - `위클리 사용 리포트` `#00BF40` → `positive`
  - `시간설정 완료` `#3A99F8` → `primary`
  - `미션 완료` `#FFCC33` → `secondary` (yellow; matches existing token)
  - `미션 반려` `#FF4242` → `destructive`
- Body text: `#2F3032` → `gray800`
- Timestamp: `#A7ACB2` → `gray300`
- CTA `확인하러 가기 →`: `#777A7F` → `gray500`

NEW: none (all map to existing semantic + gray tokens).

### Typography
- Title (chip label, 12 sp): Pretendard SemiBold 12 / 1.334 / letter-spacing 2.52 → `Caption/Bold`
- Body (14 sp): Pretendard Medium 14 / 1.429 / letter-spacing 1.45 → `Label/Medium`
- Timestamp (12 sp): Pretendard Regular 12 / 1.334 → `Caption/Regular`
- CTA (12 sp): Pretendard Medium 12 / 1.334 → `Caption/Medium`
- Header `알림`: Pretendard Medium 18 → `Headline/Medium`

### Notification tile structure (anatomy)
Card: `BackgroundColor=white`, `radius=12`, `padding=horizontal 16 / vertical 14`, internal column `gap=12`, internal content width `294`.

```
┌─ Card ──────────────────────────────────────────────┐
│ ┌─ Header row (space-between, full width) ────────┐ │
│ │  [Icon 20–24px] [Title chip 12 SemiBold]   15분 전│ │
│ └────────────────────────────────────────────────┘ │
│                                                     │
│  Body text (14 Medium, gray800, max 2 lines, …)     │
│                                                     │
│  확인하러 가기 →   (12 Medium, gray500)              │
└─────────────────────────────────────────────────────┘
```

- **Icon**: 20–24 px, colored circle/badge matching the category color (positive check, primary clock, secondary star/check, destructive cross). Source uses raster assets; in Flutter use the matching `Icon` from the icon set with the semantic color.
- **Title chip**: small SemiBold label colored by type (no pill background). Fixed inner width ~84 px in design but should be intrinsic in code.
- **Timestamp**: relative time string (`15분 전`, `1시간 전`, …) right-aligned.
- **Body**: 1–2 lines, soft wrap with explicit `\n` allowed.
- **CTA**: text link (`확인하러 가기 →`), `gray500`, taps into the related context (mission, report, time settings).
- **Unread dot**: NOT visible in this revision — there is no leading dot. If unread state is required, plan to add an 8 px circle in `primary` to the left of the icon (mark as future enhancement, not in current spec).

### Delete interaction
Not shown on this screen — see `773-12916` and `773-12903`.

### Empty vs filled differences
- Filled adds a vertically scrolling `Form` column starting `~120 px` from top; cards have white backgrounds with shadow-less 12 px radius.
- Empty omits the form entirely and centers a single muted line.

### Reusable components
- `BridgeNotificationTile`
  - Required: `type` enum (`report` / `timeSetCompleted` / `missionCompleted` / `missionRejected` / `missionConfirmRequest`), `title`, `body`, `timestamp`, optional `ctaLabel = '확인하러 가기 →'`, `onTap`.
  - Theming derived from `type` → color + icon.
- `BridgeTopBar` (back + title, already shared).
- `BridgeEmptyState` (text-only).

---

## 알림 탭 — 컴포넌트 삭제 1 (`773-12916`)

Figma name: `scr/child-alert-삭제` — captures the **swipe-to-delete in progress** state. The frame is rendered at ~90% of the standard 375 width (337 px) because Figma scaled the design; the proportions are otherwise identical.

### Layout (top → bottom)
- Status bar, Top bar with `알림` (same as filled).
- Form area (`top: 107.89`, width `294`, height `593.39`, `overflow-clip`) containing three alert cards plus a red "swipe action" surface revealed under the top card:
  - Top card is **translated left by 57 px** (`left: -57.09`), revealing a `#FFD3D3` rounded `14.385` panel beneath. The reveal panel contains a single trailing destructive icon (red filled circle with white X) right-aligned, vertically centered.
  - The two lower cards (시간설정 완료, 미션 확인 요청) sit in their normal positions.
- Bottom navigation bar (~29 px, scaled).

### Texts (verbatim)
- Header: `알림`
- Cards visible (top → bottom of the form):
  1. (Being swiped) `미션완료` / `자녀가 숙제하기 미션을 완료했어요.\n보너스 시간 15분 획득!`
  2. `미션 확인 요청` / `자녀가 숙제하기 미션 완료 확인을 요청했어요.`
  3. `시간설정 완료` / `자녀가 1월달 사용 시간 설정을 완료했어요!`
- Per card timestamp: `15분 전`, CTA `확인하러 가기 →`.

### Colors
- Swipe reveal panel: `#FFD3D3` → token `destructive/light` (NEW alias; design system labels it `Foundation/Violet/Normal` but it is the destructive tint used here).
- Trailing X icon: filled circle `destructive` `#FF4242` with white glyph.
- Other colors identical to filled screen.

NEW tokens:
- `destructiveBg` = `#FFD3D3` — background of the swipe reveal (and of any destructive surface tint). Suggested name: `destructive100` or `destructive/surface`.

### Typography
Same scale as filled screen — note this frame is rendered at ~90% raster scale, so production should use the full-size text scale (18 header, 14 body, 12 caption).

### Notification tile structure
Same as filled.

### Delete interaction (model)
- **Gesture**: horizontal swipe-left on a single tile (Dismissible-style). No long-press, no bulk-select chrome, no trailing always-visible button.
- **Revealed action area**: full-tile-height `#FFD3D3` rounded surface (radius 14.385 ≈ `14`) with a single trailing 24 px destructive icon (filled red circle + X) at right edge, padded `16 / 16`.
- **Threshold**: design shows ~57 / 294 ≈ **19% horizontal offset** while in-flight — implementation should use Flutter `Dismissible` with `direction: endToStart`, `dismissThresholds = 0.4`, and `background` widget = red surface + trailing icon.
- **Commit**: releasing past threshold triggers the confirmation dialog from `773-12903` (does NOT immediately delete).

### Empty vs filled
This frame is a sub-state of the filled list, only meaningful when cards exist.

### Reusable components
- `BridgeNotificationTile` wrapped in `Dismissible`.
- `BridgeSwipeActionBackground` — new helper: rounded `destructive100` surface with trailing destructive icon.

---

## 알림 탭 — 컴포넌트 삭제 2 (`773-12903`)

Figma name: `scr/child-alert-삭제확인` — the **delete confirmation modal** layered over the swipe state.

### Layout (top → bottom)
- All elements of `773-12916` (swipe in progress) are still present underneath.
- **Scrim**: `bg-[rgba(68,68,68,0.6)]` covering the full viewport (337 × 730 in scaled frame → use `Color(0x99444444)` or `Colors.black54`).
- **Confirmation dialog** centered:
  - Width `294.897`, height `189.705`, `bg=white`, radius `12`.
  - Top: warning icon (28.77 px) — yellow circle with white exclamation bar + dot. Color `secondary` `#FFCC33`.
  - Title (single line, centered): `알림을 삭제하시겠습니까?` — Pretendard SemiBold 14.39 / line-height 1.5, color `#2F3032` (`gray800`).
  - Footer: two equal half-buttons centered with `gap=13.486`:
    - **Cancel**: `취소` — background `#EBF5FE` (light blue tint), border `0.899` solid `#3A99F8` (`primary`), text `primary`, radius 8, height 37.76, padding `13`, font Medium 12.59.
    - **Confirm**: `확인` — solid `primary` `#3A99F8`, white text, same dims.
  - (A second `홈으로` solid button exists in the figma file at `bottom -483.7` — this is an unused/overflow variant from the master component, not visible on this screen. Ignore for implementation.)

### Texts (verbatim)
- Dialog title: `알림을 삭제하시겠습니까?`
- Buttons: `취소` / `확인`
- Stray (do not render): `홈으로`

### Colors
- Scrim: `rgba(68,68,68,0.6)` → NEW token `scrim/dim` = `Color(0x99444444)` (or reuse a generic `scrim` if one already exists).
- Dialog bg: `white`.
- Warning icon: `secondary` `#FFCC33`.
- Title text: `gray800` `#2F3032`.
- Cancel button bg: `#EBF5FE` → NEW token `primary050` / `primary/light` (matches design system label `Button/Blue/Light`).
- Cancel border + text: `primary` `#3A99F8`.
- Confirm bg: `primary`, text `white`.

NEW tokens:
- `scrim` = `Color(0x99444444)` (60% opacity over #444)
- `primary050` (a.k.a. `primary/light`) = `#EBF5FE`

### Typography
- Title: Pretendard SemiBold 14 / 1.5 (rounded; close to existing `Label/SemiBold 14` — confirm or add `Title/Dialog`).
- Button labels: Pretendard Medium 12 / 1.429 → `Label/Small` (12) (or reuse `Caption/Medium`).

### Notification tile structure
Same as previous, the tiles are not interactive while the dialog is open.

### Delete interaction (commit step)
- Triggered after the user swipes past threshold (or, alternatively, by a future trailing-action button).
- Modal is a **blocking AlertDialog** with two actions:
  - `취소` → dismiss dialog, snap tile back to position.
  - `확인` → animate tile out and remove from list.
- No undo snackbar shown in this revision (could be added later).

### Empty vs filled
Only relevant when at least one tile exists. If the deletion empties the list, screen falls back to `426-19287` empty state.

### Reusable components
- `BridgeConfirmDialog`
  - Props: `iconColor` (default `secondary`), `title`, `cancelLabel='취소'`, `confirmLabel='확인'`, `onCancel`, `onConfirm`, `destructive` flag (when true, confirm button uses `destructive` instead of `primary`).
- `BridgePrimaryButton` (filled) and `BridgeSecondaryButton` (outlined/tinted) — already in spec from other screens; this dialog can reuse them at compact `S` size (height 38).
- Reuses `BridgeNotificationTile`, `BridgeSwipeActionBackground`, `Dismissible`.

---

## Consolidated NEW tokens for this spec

| Token | Value | Usage |
| --- | --- | --- |
| `destructive100` (a.k.a. `destructive/surface`) | `#FFD3D3` | Swipe-to-delete reveal background |
| `primary050` (a.k.a. `primary/light`) | `#EBF5FE` | Cancel button background in confirm dialog |
| `scrim` | `Color(0x99444444)` (rgba 68,68,68,0.60) | Modal scrim behind confirmation dialog |

All other colors, text styles, paddings, radii, and gaps map to existing tokens (`primary`, `secondary`, `positive`, `destructive`, `gray100/300/500/800`, `white`, Pretendard `Headline/Medium`, `Label/Medium`, `Caption/Bold|Medium|Regular`).

## Reusable components introduced

| Component | Purpose |
| --- | --- |
| `BridgeNotificationTile` | White rounded card with type-themed title chip, body, timestamp, and CTA link |
| `BridgeSwipeActionBackground` | `destructive100` rounded surface with trailing destructive icon, used as `Dismissible.background` |
| `BridgeConfirmDialog` | Centered modal with warning icon, title, and Cancel/Confirm half-buttons |
| `BridgeEmptyState` (text-only variant) | Single centered `Caption/Headline` line for empty list screens |
| `BridgeTopBar` | Reused: back button + centered title (already shared across app) |

## Implementation notes (Flutter)

- Use `ListView.separated` with `SizedBox(height: 15)` separators and 24 px horizontal padding (matches existing `pageHorizontal`; note tiles render at `width 327` on a 375 viewport, i.e. 24 px on each side).
- Wrap each `BridgeNotificationTile` in `Dismissible`:
  - `key: ValueKey(notification.id)`
  - `direction: DismissDirection.endToStart`
  - `dismissThresholds: { DismissDirection.endToStart: 0.4 }`
  - `background: BridgeSwipeActionBackground()`
  - `confirmDismiss: (_) async => showDialog<bool>(... BridgeConfirmDialog ...)`
- Modal: `showDialog(barrierColor: BridgeColors.scrim, barrierDismissible: true)`.
- Empty state replaces the list when `notifications.isEmpty`; use the same `BridgeTopBar` above it.
