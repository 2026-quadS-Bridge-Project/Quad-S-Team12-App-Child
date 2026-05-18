# Bridge_K — Figma Spec: 마이페이지

Source: Figma file `tzJjQmXtXO7vGlfCT9SASu`
Frame: `scr/child-mypage`
Frame size: 375 × (full screen)
Background: `#F5F7FA` (gray100)

---

## 마이페이지 (`773:11103`)

### Layout (top → bottom)

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–44   | Status bar | iOS status (notch, time `9:41`, signal/wifi/battery) — system-rendered on device |
| 44–96  | Top bar (`325:17287` cmp/topbar) | Height 52, padding 22h/5v. Back button left (24×24 @ left=24, top=14). Title centered |
| 96–121 | Spacing (~25px) | |
| 121–325 | Info rows container (`773:11105`) | left=23.92, width=327, vertical gap=24 between rows |
| 121–145 | Row 1: 회원유형 (`773:11106`) | Label + vertical divider + value |
| 169–193 | Row 2: 아이디 (`773:11111`) | Label + vertical divider + value |
| 217–241 | Row 3: 자녀코드 (`773:11412`) | Label + vertical divider + value |
| 265–300 | Row 4: 비밀번호 (`773:11116`) | Label + 수정하기 button (height=35) |
| 332–339 | Separator bar (`773:11123`) | Full-width 374×7 band, color `#EDEEF1` |
| 364–399 | 탈퇴하기 button (`257:3713`) | Width 80, height 35, positioned right (`left=calc(60%+46px)`) |
| bottom | UI bar (`359:5747`) | 32px iOS home indicator (system) |

Note: 로그아웃 button is **NOT present** in this Figma frame — only the destructive 탈퇴하기 button is shown floating right below the separator.

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `마이페이지` | `325:17273` (topbar title) |
| `회원유형` / `자녀회원` | `773:11108` / `773:11110` |
| `아이디` / `abcd00` | `773:11113` / `773:11115` |
| `자녀코드` / `XY785eZ` | `773:11414` / `773:11416` |
| `비밀번호` | `773:11118` |
| `수정하기` | `I773:11119;270:4904` (password edit button) |
| `탈퇴하기` | `257:3714` (destructive button) |

### Colors used

| Hex | Token | Usage |
|-----|-------|-------|
| `#F5F7FA` | gray100 ✓ | Page background |
| `#5F6165` | gray600 ✓ | Row label text, 수정하기 button bg |
| `#D5D8DE` | gray200 ✓ | (declared in styles, vertical divider color appears lighter via img) |
| `#050505` | NEW (near-black) | Topbar title color, row value text — NOT same as gray900 (`#171818`) |
| `#FFFFFF` | white ✓ | 수정하기 button text, 탈퇴하기 ripple |
| `#EDEEF1` | NEW `gray150` | Separator bar between info & action area |
| `#FFD3D3` | NEW `destructiveSubtle` | 탈퇴하기 button background |
| `#FF4242` | destructive ✓ | 탈퇴하기 button text |
| `#FAFBFC` | gray050 ✓ | declared (unused in visible layout) |
| `#171818` | gray900 ✓ | declared (status-bar battery fill) |

**New tokens to add**: `#050505` (titleBlack / inkBlack), `#EDEEF1` (gray150), `#FFD3D3` (destructiveSubtle).

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Headline/Medium | Pretendard Medium 18 / line 1.445 / letter -0.02 | Topbar title `마이페이지` |
| Body/Medium     | Pretendard Medium 16 / line 1.5 / letter 0.0912 | Row labels, values, 수정하기, 탈퇴하기 |

(All match existing `AppTypography.headlineMedium` / `AppTypography.bodyMedium`.)

### Icons / Assets

| Asset | Filename hint | Node |
|-------|---------------|------|
| Back chevron (24×24, inner 8×16) | `assets/icons/cmp/btn/back.svg` (already in repo) | `325:17277` btn/back |
| Vertical divider (1×22) between label/value | inline `Container(width:1, height:22)` — no asset needed | `773:11109`, `:11114`, `:11415` |
| Status-bar glyphs (signal, wifi, battery, time) | system-rendered — ignore | `773:11120` |

No new SVGs required.

### Interactions

| Element | Behavior |
|---------|----------|
| Back button (top-left) | `context.pop()` → returns to previous screen |
| 회원유형 / 아이디 / 자녀코드 rows | Read-only display (no tap target in Figma) |
| 수정하기 (비밀번호) | Navigates to password-change screen (`/mypage/password`) |
| 탈퇴하기 | Opens confirm dialog → on 확인 clears session and navigates to `/mypage/delete-complete` |
| Separator bar (7px) | Pure visual divider — no interaction |
| 로그아웃 | **Not in Figma frame** (see deltas below) |

### Reusable component candidates

- `MyPageInfoRow({ label, value })` — fixed-width label (~69px) + vertical 1×22 divider + value. Already implemented as private `_InfoRow`; consider promoting to shared widget for settings-style screens.
- `MyPageActionChip({ label, bg, fg, onTap })` — 80×35 rounded-8 chip used for 탈퇴하기 (and current 로그아웃). Already implemented as `_MyPageActionButton`.
- `SectionSeparatorBand({ color, height })` — 7px full-width band reused as section break.
- `CmpTopbar({ title, onBack })` — centered title + left back. Currently inlined as `_MyPageTopBar`; the Figma component (`325:17287`) is reused across multiple screens (e.g., 미션 정보), so worth extracting into `core/widgets/`.

---

## Deltas vs current `my_page.dart`

| # | Topic | Current (`my_page.dart`) | Figma `773:11103` | Action |
|---|-------|--------------------------|-------------------|--------|
| 1 | Action buttons | Two buttons in a row: **로그아웃** (gray) + **탈퇴하기** (red), both right-aligned | **Only 탈퇴하기** shown, positioned right (`left = calc(60% + 46px)`) | Remove 로그아웃 button OR confirm with PM. If kept, it is an addition beyond design. |
| 2 | Aiди value | Reads `_username` from `AuthSession` (dynamic) | Hard-coded `abcd00` | OK — dynamic is correct, ignore Figma sample. |
| 3 | 자녀코드 value | Hard-coded `XY785eZ` | Hard-coded `XY785eZ` | OK — both static; backend wiring still TODO. |
| 4 | Topbar title color | `#050505` ✓ matches | `#050505` | OK |
| 5 | Row label color | `AppColors.gray600` ✓ | `#5F6165` | OK |
| 6 | Row value color | `#050505` ✓ | `#050505` | OK |
| 7 | Vertical divider | `AppColors.gray200` (#D5D8DE), width 1, height 22 | Same dimensions; asset is a thin Vector image rendered ~1px (color appears lighter, likely `#D5D8DE`) | OK |
| 8 | Separator band color | `#EDEEF1` ✓, height 7 | `#EDEEF1`, height 7 | OK — add `AppColors.gray150` token to formalize. |
| 9 | 탈퇴하기 bg | `#FFD3D3` ✓ | `#FFD3D3` | OK — add `AppColors.destructiveSubtle` token. |
| 10 | 탈퇴하기 fg | `AppColors.destructive` ✓ | `#FF4242` | OK |
| 11 | 수정하기 button bg | `AppColors.gray600` ✓ | `#5F6165` | OK |
| 12 | Row spacing | 24px between rows ✓ | gap=24 | OK |
| 13 | Container left inset | 24 | 23.92 (Figma) | OK (rounding). |
| 14 | Top spacing after topbar | 25 | 121 - 96 = 25 | OK |
| 15 | Spacing topbar → separator | 32 + content | Figma: separator at y=332; content ends ~y=300 → ~32px gap | OK |
| 16 | Delete dialog | Implemented (`_DeleteAccountDialog`) — 294.897×189.705 | Not in this node | Implementation extends Figma — keep, but trace dialog spec from a separate node if available. |
| 17 | Top-bar horizontal padding | `EdgeInsets.symmetric(horizontal: 22)` ✓ | px-22 | OK |

### Recommended changes to `my_page.dart`

1. Decide on **로그아웃 button**: Figma does not show it. Either (a) remove it to match design, or (b) confirm requirement with design and add to Figma. Action button row should otherwise contain only 탈퇴하기.
2. Add tokens to `core/theme/app_colors.dart`:
   - `gray150 = Color(0xFFEDEEF1)`
   - `destructiveSubtle = Color(0xFFFFD3D3)`
   - `inkBlack = Color(0xFF050505)` (or reuse via theme)
3. Replace inline `Color(0xFFEDEEF1)`, `Color(0xFFFFD3D3)`, `Color(0xFF050505)` literals with the new tokens.
4. Promote `_MyPageTopBar` to a shared `CmpTopBar` widget (Figma component `325:17287` is reused across screens).
