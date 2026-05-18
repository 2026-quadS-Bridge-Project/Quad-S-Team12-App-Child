# 비밀번호 변경 (Password Change) — Part 1 of 2

File key: `tzJjQmXtXO7vGlfCT9SASu`
Nodes: `773-11124`, `773-11134`, `773-12009`
Frame width: 375
Existing implementation: [lib/features/my_page/presentation/pages/password_change_page.dart](../../lib/features/my_page/presentation/pages/password_change_page.dart)

---

## 비밀번호 변경 - empty / initial (`773:11124`)

Figma name: `scr/child-mypage-비밀번호 수정` (frame `773:11124`, container `773:11125`).

### Layout (top → bottom)
- **StatusBar** — `top: 0`, `height: 44` (system status bar mock; Notch + time `9:41` + signal/wifi/battery).
- **TopBar** (`325:17287`) — `top: 44`, `height: 52`, full width 375.
  - Back button (`btn/back`, `24×24`) at `left: 24`, `top: 14`.
  - Centered title "비밀번호 수정" (Pretendard Medium 18 / line-height 1.445 / letter-spacing -0.02 / color `#050505`).
- **Form Container** (`773:11125`) — absolute at `left: 24`, `top: 118`, `width: 327`, vertical `gap: 20` between fields.
  - **Field 1** — label "기존 비밀번호" + input placeholder "기존 비밀번호를 입력해주세요"
  - **Field 2** — label "새 비밀번호" + placeholder "새 비밀번호를 입력해주세요"
  - **Field 3** — label "새 비밀번호 확인" + placeholder "새 비밀번호를 한번 더 입력해주세요"
  - Each field: label (16/Medium, `#5F6165`, `gap: 10` below) → input (`height: 50`, `borderRadius: 12`, border `1px #D5D8DE`, `padding: 12/16`) → helper-text slot (`height: 18`, empty in this variant).
- **Submit Button** (`252:4795`) — `bottom: 63`, centered, `width: 327` (Figma shows 328 here; treat as 327 to match the other variants), `height: 54`, `borderRadius: 8`, background `#D5D8DE` (disabled), label "완료" (Pretendard Medium 18, color `#A7ACB2`).
- **UiBar** (home indicator) — `bottom: 0`, `height: 32`.

### Texts (verbatim Korean)
- Top bar: `비밀번호 수정`
- Labels: `기존 비밀번호`, `새 비밀번호`, `새 비밀번호 확인`
- Placeholders: `기존 비밀번호를 입력해주세요`, `새 비밀번호를 입력해주세요`, `새 비밀번호를 한번 더 입력해주세요`
- Button: `완료`

### Colors used
| Hex | Token | Notes |
| --- | --- | --- |
| `#F5F7FA` | gray100 (existing) | Page background |
| `#FFFFFF` | white (existing) | Input field fill (implicit / no fill in Figma) |
| `#D5D8DE` | gray200 (existing) | Input border, disabled button bg |
| `#A7ACB2` | gray300 (existing) | Placeholder text, disabled button label |
| `#5F6165` | gray600 (existing) | Field label color |
| `#050505` | NEW — flag | Top-bar title color (close to `gray900 #171818` but not identical). Existing impl already uses `Color(0xFF050505)` hard-coded. Consider promoting to a token e.g. `AppColors.textPrimary`. |
| `#171818` | gray900 (existing) | Battery icon fill in status bar |

### Typography
| Style | Family / Weight / Size / LH / LS | Token | Notes |
| --- | --- | --- | --- |
| Top-bar title | Pretendard Medium 18 / 1.445 / -0.02 | NEW — flag | Figma "Headline/Medium". Existing `AppTypography.headlineMedium` likely covers it but verify line-height/letter-spacing match. |
| Field label | Pretendard Medium 16 / 1.5 / 0.0912 | existing 16/Medium | "Body/Medium" |
| Input / placeholder | Pretendard Medium 16 / 1.5 / 0.0912 | existing 16/Medium | Same |
| Button label | Pretendard Medium 18 / 1.445 / -0.0036 | existing 18/Medium | "Headline/Medium" |

### Form state
**State: empty / pristine — submit disabled.**
- All three inputs show placeholders only (no value).
- No focus, no clear button, no helper text on any field.
- Submit button: `bg = #D5D8DE`, label color `#A7ACB2` (disabled visual).

### Interactions
- Back button → previous page.
- Tapping a field → focus + show keyboard (transition to next variant).
- Submit button is non-interactive in this variant.

### Reusable component candidates
- `PasswordChangeField` (label + input + helper slot) — matches current `_PasswordChangeField`.
- `PrimaryActionButton` with `enabled` flag — matches current `_PasswordChangeButton`.
- `AppTopBar` with back + center title — matches `_PasswordChangeTopBar`.

---

## 비밀번호 변경 - typing / clear-button + helper (`773:11134`)

Figma name: `scr/child-mypage-비밀번호 수정중` (frame `773:11134`, container `773:11135`).

### Layout (top → bottom)
- StatusBar / TopBar / UiBar / Submit identical to `773:11124`.
- **Form Container** (`773:11135`) — `left: 24`, `top: 118`, `width: 327`, `gap: 20`.
  - **Field 1 — 기존 비밀번호** (`773:11137`): filled value `Abcd00@` rendered in black `#050505`. No clear button visible (input lost focus). Helper slot empty.
  - **Field 2 — 새 비밀번호** (`773:11138`): focused, value `Ab` + a blinking cursor (rendered as `imgCursor` line). Right side shows **clear button** (24×24, circle outline `Ellipse40` + ✕ vectors). Helper text shown below in gray: `영문 대문자, 소문자, 숫자, 특수문자 모두 혼합 (12~15자)`.
    - Container padding shifts to `pl: 13, pr: 16, py: 13`, `gap: 3` between input row and clear icon.
  - **Field 3 — 새 비밀번호 확인**: still empty (placeholder).
- Submit Button — still disabled (`#D5D8DE` / `#A7ACB2`, label "완료").

### Texts (verbatim Korean)
- Sample value: `Abcd00@` (existing pw), `Ab` (in-progress new pw).
- Helper (rule hint): `영문 대문자, 소문자, 숫자, 특수문자 모두 혼합 (12~15자)`
- All labels/placeholders/button same as variant 1.

### Colors used
| Hex | Token | Notes |
| --- | --- | --- |
| `#F5F7FA` | gray100 (existing) | bg |
| `#D5D8DE` | gray200 (existing) | Input border (still neutral while typing, no error) |
| `#050505` | NEW — flag | Filled input text color (same as top-bar title; promote to token) |
| `#5F6165` | gray600 (existing) | Field labels |
| `#777A7F` | NEW — flag | Helper text color in neutral-hint state. Sits between existing gray600 (`#5F6165`) and gray300 (`#A7ACB2`). Suggest adding `gray500` to palette. |
| `#A7ACB2` | gray300 (existing) | Disabled button label |
| Clear icon stroke/fill | (svg asset — already in `assets/icons/Clear button.svg`) | — |

### Typography
| Style | Spec | Token | Notes |
| --- | --- | --- | --- |
| Helper text | Pretendard Medium 12 / 1.334 / 0.3024 | existing 12/Medium ("Caption/Medium") | NEW letter-spacing — Figma reports `0.3024px` (≈ 2.52% of 12px in earlier exposure). Current impl uses `0.12`. Flag mismatch. |
| Field label / input | same as variant 1 | — | |

### Form state
**State: 새 비밀번호 field focused & typing — clear button visible + neutral helper hint shown.**
- This is the **focus-with-content** state for the "new password" field, before validation fires.
- Existing 기존 비밀번호 already populated and unfocused (no clear btn).
- Confirm field untouched.
- Helper text here is **neutral guidance**, not an error (color `#777A7F`, not destructive red).
- Submit still disabled because new pw not yet valid.

### Interactions
- Clear button (✕) inside focused field → clears that field, returns to placeholder state.
- Typing in new-password triggers live validation (rule helper shown until satisfied).
- Helper-text slot reserves `height: 18` even when no message (prevents layout jump).

### Reusable component candidates
- `PasswordChangeField` variants: `default` / `focused-filled-with-clear` / `with-helper-text`.
- `HelperText` component with severity prop: `neutral` (gray `#777A7F`) / `error` (`#FF4242` destructive) / possibly `success`.

---

## 비밀번호 변경 - all valid / submit enabled (`773:12009`)

Figma name: `scr/child-mypage-비밀번호 수정완료` (frame `773:12009`, container `773:12010`).

### Layout (top → bottom)
- StatusBar / TopBar / UiBar identical.
- **Form Container** (`773:12010`) — `left: 24`, `top: 118`, `width: 327`, `gap: 20`.
  - **Field 1 — 기존 비밀번호**: value `Abcd00@`, no clear button (unfocused), helper slot empty.
  - **Field 2 — 새 비밀번호**: value `Abcd09!`, no clear button (unfocused), helper slot empty.
  - **Field 3 — 새 비밀번호 확인**: value `Abcd09!`, no clear button (unfocused), helper slot empty.
  - All three fields use neutral border `#D5D8DE` (no green/positive success border).
- **Submit Button** (`252:4802`) — `bottom: 63`, centered, `width: 327`, `height: 54`, `borderRadius: 8`, background `#3A99F8` (primary), label "완료" in `#FFFFFF`.

### Texts (verbatim Korean)
- Sample values: `Abcd00@`, `Abcd09!`, `Abcd09!`
- Same labels / button text as variant 1.

### Colors used
| Hex | Token | Notes |
| --- | --- | --- |
| `#F5F7FA` | gray100 (existing) | bg |
| `#D5D8DE` | gray200 (existing) | Field borders (neutral even when valid) |
| `#050505` | NEW — flag | Filled input text |
| `#5F6165` | gray600 (existing) | Field labels |
| `#3A99F8` | primary (existing) | Enabled submit button bg |
| `#FFFFFF` | white (existing) | Enabled submit button label |

### Typography
Same set as variants 1-2; button label switches to white.

### Form state
**State: all fields valid & matching — submit enabled.**
- Current pw matches stored value, new pw passes regex rule, confirm equals new pw.
- No helper text shown anywhere (success is implicit; no green confirmation).
- Submit button: `bg = #3A99F8`, label `#FFFFFF`.

### Interactions
- Tap submit → trigger password change API → on success, pop / navigate.
- Tapping any field re-focuses it (returns to variant-2-style state for that field).

### Reusable component candidates
- `PrimaryActionButton` `enabled` variant (primary blue + white label).
- Same `PasswordChangeField` (filled-unfocused, no helper).

---

## Cross-variant notes

### New tokens discovered (not in existing palette)
- **`#050505` near-black** — used for top-bar title AND filled input text. Recommend `AppColors.textPrimary` (currently hard-coded in `password_change_page.dart`).
- **`#777A7F` gray500** — neutral helper-text color used for non-error rule hint. Should be added between `gray600` and `gray300`.
- **Helper-text letter-spacing `0.3024`** for 12/Medium captions (existing impl uses `0.12`).

### Variant → state mapping
| Node | State |
| --- | --- |
| `773:11124` | empty/pristine, submit disabled |
| `773:11134` | "새 비밀번호" focused + typing, clear button + neutral rule helper, submit still disabled |
| `773:12009` | all valid, submit enabled (primary blue) |

### Deltas vs current `password_change_page.dart`
1. **Helper-text color is wrong for the neutral rule hint.** Current code always renders helper text in `AppColors.destructive` (red). Figma variant 2 shows the rule-hint helper in neutral gray `#777A7F` when it's just guidance (no input yet / typing in progress). Only an actual validation failure (e.g., "기존 비밀번호가 일치하지 않습니다.", "비밀번호가 일치하지 않습니다.") should be destructive red.
   - Suggested fix: introduce `helperSeverity` (neutral / error) on `_PasswordChangeField`; default the rule hint to neutral and switch to error only after validation fails on blur or submit.
2. **Border color on neutral-helper state.** Current code sets border to `AppColors.destructive` whenever `helperText != null`. Should only turn destructive for error-severity helpers.
3. **Hard-coded `Color(0xFF050505)`** appears twice (top-bar, input text). Promote to `AppColors.textPrimary` (or similar).
4. **Field font sizes use fractional values** (`14.39`, `16.18`) — Figma actually specifies `16` and `18`. The fractional values look like a residual `0.8989` scale factor. Consider snapping to integer sizes (`14`, `16`, `18`) and re-checking visual diff against Figma's 375-wide canvas.
5. **Container padding & widths.** Figma puts container at `left: 24` with `width: 327` and gap `20` between fields. Current impl uses `horizontal: 22` and `SizedBox(height: 24)` between fields. Align to `horizontal: 24` and `gap: 20`.
6. **Caption letter-spacing** for helper text: Figma `0.3024`, current `0.12`. Update.
7. **Field internal height.** Figma input field height is `50` (with `padding: 12/16`). Current `Container` uses `44.954` — likely another scale artifact. Use `50`.
8. **Clear button position.** Figma shows the clear `✕` icon inset within the field at the right (24×24). Current impl uses `'assets/icons/Clear button.svg'` at `21.578×21.578` with `SizedBox(width: 8)` — adjust to `24×24` and verify spacing (`gap: 3`-ish from text).
9. **No success state styling found.** Figma "수정완료" variant does NOT show a green/positive helper or border — success is implicit via enabled submit button only. Current impl already matches this; no change needed.
10. **Submit button height.** Figma `54`, current `48.55`. Bump to `54`.
