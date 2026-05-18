# Bridge_K — Figma Spec: 탈퇴 플로우 (Account Deletion)

Source: Figma file `tzJjQmXtXO7vGlfCT9SASu`
Frames: `scr/child-mypage-탈퇴` (confirm), `scr/child-mypage-탈퇴완료` (complete)
Frame size: 375 × 812
Background (confirm overlay): underlying 마이페이지 + scrim `rgba(68,68,68,0.6)`
Background (complete): `#FAFBFC` (gray050)

---

## 탈퇴 확인 (`773:11838`)

This node is the **마이페이지** frame with a centered confirmation **modal dialog** layered on top via a full-screen scrim. The mypage layout underneath is identical to `03-mypage.md` (`773:11103`). Only the dialog is new in this spec.

### Layout (top → bottom)

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–812  | Scrim (`773:12007`) | Full-screen overlay `375×812`, color `rgba(68,68,68,0.6)` — dims mypage behind |
| (center) 300.5–511.5 | Popup container (`773:11102`) | `328×211`, centered horizontally & vertically. Inner card `100%×100%` |
| – inside dialog – | | |
| 37–69 (within card) | Warning icon (`I773:11102;…;308:3960`) | 32×32, circular red badge (`#FF4242`) with white "!" mark — centered, top=37 |
| 87–111 (within card) | Title text (`I773:11102;…;190:6227`) | `탈퇴하시겠습니까?` — Pretendard SemiBold 16, color `#2F3032`, centered. Stacked 18px below icon |
| 139–181 (within card) | Button row (`I773:11102;…;257:3138`) | Two `120×42` buttons centered, gap 15, bottom inset 30 |

Card spec: `328 × 211`, background `#FFFFFF`, corner radius `12`.

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `탈퇴하시겠습니까?` | `I773:11102;426:26944;190:6227` (dialog title) |
| `취소` | `I773:11102;…;257:3138;257:3125` (left button, outline) |
| `확인` | `I773:11102;…;257:3138;257:3127` (right button, filled) |

### Colors

| Hex | Token | Usage |
|-----|-------|-------|
| `rgba(68,68,68,0.6)` | NEW `scrimDim` | Full-page scrim behind dialog |
| `#FFFFFF` | white ✓ | Dialog card background, 확인 button text, warning glyph fill |
| `#FF4242` | destructive ✓ | Warning icon circle background |
| `#2F3032` | gray800 ✓ | Dialog title text |
| `#3A99F8` | primary ✓ | 확인 button bg, 취소 button border + text |
| `#EBF5FE` | NEW `primaryLight` (Button/Blue/Light) | 취소 button background |

**New tokens to add**: `scrimDim = Color.fromRGBO(68, 68, 68, 0.6)` (already inlined in current impl), `primaryLight = Color(0xFFEBF5FE)` (already inlined as `_DeleteDialogButton` outline bg).

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Body/Bold | Pretendard **SemiBold** 16 / line 1.5 / letter 0.0912 | `탈퇴하시겠습니까?` title |
| Label/Medium | Pretendard Medium 14 / line 1.429 / letter 0.203 | `취소` / `확인` buttons |

Both styles are already declared in the design system (Body/Bold and Label/Medium). Match `AppTypography.bodyBold` (SemiBold 16) and `AppTypography.labelMedium` (Medium 14).

### Icons / Assets

| Asset | Hint | Node |
|-------|------|------|
| Warning glyph (32×32) | Red circle `#FF4242` + white `!` (vertical bar 2.67×10.67, dot 2.67×2.67) — render inline, no asset needed | `I773:11102;…;308:3960` |

### Interactions

| Element | Behavior |
|---------|----------|
| Scrim tap | Dismiss dialog (current impl: `barrierDismissible: true`) |
| `취소` button (outline) | Close dialog, stay on 마이페이지 |
| `확인` button (filled) | Clear auth session → navigate to `/mypage/delete-complete` |

**Format**: This is **a modal dialog over the 마이페이지** (NOT a separate full page). The Figma node renders the mypage underneath + scrim + centered popup. The current inline `_DeleteAccountDialog` in `my_page.dart` is the correct pattern.

### Reusable component candidates

- **`BridgeConfirmDialog({ icon, title, cancelLabel, confirmLabel, onConfirm, isDestructive })`** — centered `328×211` card with optional warning icon + title + two-button footer. Reusable for any destructive confirmation (delete account, leave mission, etc.). Card radius 12, white bg, scrim `rgba(68,68,68,0.6)`.
- **`BridgePrimaryHalfButton({ label, filled })`** — 120×42 half-width button pair (outline + filled) used in dialog footers. Outline variant: bg `#EBF5FE`, border `#3A99F8`, text `#3A99F8`. Filled variant: bg `#3A99F8`, text `#FFFFFF`. Both Label/Medium 14.
- **`WarningBadge({ size })`** — circular destructive badge with `!` glyph. Currently inlined in `_DeleteAccountDialog` (lines 200–248 of `my_page.dart`). Extract for reuse in other destructive flows.

Note: the Figma dialog title is `탈퇴하시겠습니까?` (no body text); current impl matches. The destructive button **variant** for `확인` in Figma is **primary blue**, not red — destructive coloring is only applied to the warning icon and the trigger button on mypage, not to the confirmation action.

---

## 탈퇴 완료 (`773:11070`)

### Layout (top → bottom)

| Y (px) | Region | Notes |
|--------|--------|-------|
| 0–44   | Status bar | iOS system (notch, time, signal/wifi/battery) — system-rendered |
| 44–~330 | Empty space | (no header, no topbar, no back button) |
| ~330–404 | Intro section (`773:11071`) | `328` wide, centered horizontally and vertically (anchor: `left=calc(50%-0.5px)`, `top=calc(50%-51.5px)`). Height of inner text block: ~74.4 |
| ~330–404 | Title text block (`773:11072`) | Two lines, Pretendard **Bold 20**, centered, color `#5F6165` |
| bottom | UI bar (`359:5747`) | 32px iOS home indicator (system) |

No app bar, no buttons, no back navigation in the Figma frame — it is a passive confirmation screen.

### Texts (verbatim Korean)

| Text | Node |
|------|------|
| `탈퇴가 완료되었습니다.` | `773:11072` line 1 |
| `언제든 다시 찾아와주세요!` | `773:11072` line 2 |

### Colors

| Hex | Token | Usage |
|-----|-------|-------|
| `#FAFBFC` | gray050 ✓ | Page background |
| `#5F6165` | gray600 ✓ | Title text color |

No new tokens.

### Typography

| Style | Spec | Where |
|-------|------|-------|
| Heading 2 / Bold (override) | Pretendard **Bold 20** / line 1.4 / letter `-0.24` | Both lines of the title |

Note: the Figma style **declared** on the text node is `Heading 2/Regular` (Pretendard Regular 20, line 1.4, letter `-1.2`), but the rendered runs override to **Bold 20** with letter `-0.24`. Use Bold.

The existing impl uses `AppTypography.heading2Regular.copyWith(fontSize: 17.982, …, color: gray600)` — this should be updated: weight should be **Bold (700)**, font-size **20** (not 17.982), letter-spacing **-0.24** (not -0.2158).

### Icons / Assets

None. Pure text screen.

### Interactions

| Element | Behavior |
|---------|----------|
| Page load | Auto-redirect after delay (current impl: 3s `Timer` → `context.go('/')`) — not specified in Figma, but Figma has no interactive elements, so a timed auto-redirect or user-tap-to-continue is required. |
| Back / hardware back | Should be disabled or redirected to root (session is already cleared) |

### Reusable component candidates

- **`BridgeCenteredMessage({ title, lines, color })`** — vertically + horizontally centered multi-line message. Could also serve other "completion" or "empty state" screens. Not strictly necessary if this is the only consumer.

---

## Deltas vs current implementation

### `_DeleteAccountDialog` in `my_page.dart` (confirm step)

| # | Topic | Current | Figma `773:11838` | Action |
|---|-------|---------|-------------------|--------|
| 1 | Pattern (page vs dialog) | Inline dialog via `showGeneralDialog` ✓ | Modal dialog over mypage ✓ | OK — pattern matches |
| 2 | Scrim color | `Color.fromRGBO(68, 68, 68, 0.6)` ✓ | `rgba(68,68,68,0.6)` | OK |
| 3 | Card size | `294.897 × 189.705` | `328 × 211` | Adjust to **328 × 211** |
| 4 | Card radius | (not visible in excerpt, but appears 8 or 12) | `12` | Verify and use `12` |
| 5 | Card background | white ✓ | `#FFFFFF` | OK |
| 6 | Warning icon | Custom inline drawing (28.77 circle) ✓ | 32 circle, inner glyph dimensions match | Adjust outer size to **32×32**; inner bar 2.67×10.67, dot 2.67×2.67 |
| 7 | Title text | `탈퇴하시겠습니까?` ✓ | same | OK |
| 8 | Title style | `AppTypography.labelBold` size 14.39 | Pretendard **SemiBold 16** line 1.5 letter 0.0912 | Change to **Body/Bold (SemiBold 16)** |
| 9 | Title color | `AppColors.gray800` ✓ | `#2F3032` | OK |
| 10 | Title gap from icon | 16px (`SizedBox(height: 16)`) | 18px (`gap-[18px]`) | Adjust to **18** |
| 11 | Buttons | `_DeleteDialogButton`, size `107.889 × 37.761`, gap `13.486` | `120 × 42`, gap `15` | Adjust to **120 × 42**, gap **15** |
| 12 | 취소 button bg | `Color(0xFFEBF5FE)` ✓ | `#EBF5FE` | OK — promote to `AppColors.primaryLight` |
| 13 | 취소 button border | `AppColors.primary` width `0.899` | `1px` solid `#3A99F8` | Use **1px** border |
| 14 | 취소/확인 text style | `AppTypography.labelMedium` ✓ | Label/Medium 14 line 1.429 letter 0.203 | OK |
| 15 | 확인 button bg | `AppColors.primary` ✓ | `#3A99F8` | OK |
| 16 | Bottom inset | (uses `Spacer`) | 30px from card bottom | Use fixed **30** bottom padding |
| 17 | Tap behavior — 확인 | `pop → clearLogin → router.push('/mypage/delete-complete')` | Same | OK |
| 18 | Tap behavior — 취소 | `context.pop()` | Same | OK |

### `delete_account_complete_page.dart`

| # | Topic | Current | Figma `773:11070` | Action |
|---|-------|---------|-------------------|--------|
| 1 | Background | `AppColors.gray050` ✓ | `#FAFBFC` | OK |
| 2 | Layout | `Align(topCenter) → Center(SizedBox(width: 294.897, …))` | Vertically + horizontally centered, width `328` | Adjust width to **328**; centering already correct |
| 3 | Text content | `탈퇴가 완료되었습니다.\n언제든 다시 찾아와주세요!` ✓ | Same (two `<p>` lines) | OK |
| 4 | Font weight | `heading2Regular` (**Regular** 400) | Pretendard **Bold** 700 | Change to **Bold** |
| 5 | Font size | `17.982` | `20` | Adjust to **20** |
| 6 | Line height | `1.4` ✓ | `1.4` | OK |
| 7 | Letter spacing | `-0.2158` | `-0.24` | Adjust to **-0.24** |
| 8 | Color | `AppColors.gray600` ✓ | `#5F6165` | OK |
| 9 | Auto-redirect | 3-second `Timer → context.go('/')` | (not specified in Figma) | OK — keep as UX requirement |
| 10 | Session clear | `AuthSession.clearLogin()` in `initState` | (not in Figma) | OK — keep |

### New tokens summary

To add to `core/theme/app_colors.dart`:

```dart
static const Color primaryLight = Color(0xFFEBF5FE);  // Button/Blue/Light — outline button bg in confirm dialog
static const Color scrimDim = Color.fromRGBO(68, 68, 68, 0.6); // dialog scrim
```

(Both are already inlined in `my_page.dart`; this just formalizes them as tokens.)

No new typography tokens required — Body/Bold (SemiBold 16) and Heading 2 with Bold weight are achievable via existing `AppTypography.bodyBold` and `AppTypography.heading2Regular.copyWith(fontWeight: FontWeight.w700)`. Consider adding `heading2Bold` to the typography theme for clarity.
