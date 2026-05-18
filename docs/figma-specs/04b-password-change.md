# 비밀번호 변경 — 에러 상태 변형 (Part 2 of 2)

Frame size: 375 × screen. Background `gray100 #F5F7FA`.
Container: `left:24, top:118, width:327, gap:20` (form column).
Form row internal gap: `10px` (label → field → helper).
Field: `H 50, radius 12, border 1px, padding 16/12, full width 327`.
Helper text area: fixed `H 18px` reserved (preserves layout even when empty).
Submit button: absolute `bottom:63, centered`, `W 328 × H 54, radius 8`, currently disabled in all 3 variants.

Common chrome (shared across all 3 nodes):
- StatusBar `H 44` (top:0)
- Topbar `H 52` (top:44), title `비밀번호 수정`, back button left:24/top:14, size 24
- UI bar (home indicator) bottom, `H 32`

---

## 비밀번호 변경 - 기존 비밀번호 에러 (`773-11733`)

### Layout (top → bottom)
1. StatusBar (44)
2. Topbar `비밀번호 수정` (52)
3. Container (top:118, gap:20):
   - Field 1 `기존 비밀번호` — **error state** (red border + helper)
   - Field 2 `새 비밀번호` — default (empty placeholder)
   - Field 3 `새 비밀번호 확인` — default (empty placeholder)
4. Submit button `완료` — disabled (bottom:63)
5. UI bar

### Texts (verbatim)
- Topbar: `비밀번호 수정`
- Label 1: `기존 비밀번호` / Placeholder: `기존 비밀번호를 입력해주세요`
- Helper (error): `기존 비밀번호가 일치하지 않습니다.`
- Label 2: `새 비밀번호` / Placeholder: `새 비밀번호를 입력해주세요`
- Label 3: `새 비밀번호 확인` / Placeholder: `새 비밀번호를 한번 더 입력해주세요`
- Button: `완료`

### Colors used
- Cross-ref: `gray100 #F5F7FA` (bg), `gray200 #D5D8DE` (default border + disabled button bg), `gray300 #A7ACB2` (placeholder + disabled button text), `gray600 #5F6165` (labels), `destructive #FF4242` (error border + helper text)
- NEW: `#050505` (input value & topbar title — near-black, slightly off pure black)

### Typography
- Cross-ref: Pretendard Medium 18 (topbar, button), Pretendard Medium 16 (labels, placeholders), Pretendard Medium 12 (helper)
- Line heights from design: 1.445 (Headline/Medium 18), 1.5 (Body/Medium 16), 1.334 (Caption/Medium 12)
- Letter spacing: `-0.02` for 18 (Headline), `+0.5699` for 16 (Body), `+2.52` for 12 (Caption)

### Form state — variant
**기존 비밀번호 mismatch error** — fired by submit when input doesn't match stored password. Only field 1 has error styling; field 2 & 3 show empty placeholders (clean default). Submit button still disabled because new/confirm fields are empty.

Notable detail: in this variant the error field has NO visible input value and NO clear button — it shows the placeholder text. The error helper is shown directly under the empty placeholder field. (In InputForm component error variant elsewhere, a value `홍` and clear button appear; here the specific instance overrides to placeholder-only.)

### Interactions
- Field 1: on focus or typing → error clears (border → gray200, helper hidden)
- Submit: disabled while any field invalid; pressing it triggers re-validation that may set this error

### Reusable component candidates
- `InputForm` (default | error) — label + bordered field + reserved helper row (already exists in code as `_PasswordChangeField`)
- `PrimaryButton` (enabled | disabled) — full-width 54px, radius 8 (currently inline `_PasswordChangeButton`)
- `BackTopbar` — shared 52px topbar with centered title + back icon (already inline as `_PasswordChangeTopBar`)

---

## 비밀번호 변경 - 새 비밀번호 에러 (`773-11519`)

### Layout (top → bottom)
1. StatusBar (44)
2. Topbar `비밀번호 수정`
3. Container (top:118, gap:20):
   - Field 1 `기존 비밀번호` — filled value `Abcd00@`, default border, no clear button
   - Field 2 `새 비밀번호` — **error state**: filled value `Abcd00@`, red border, clear button visible, helper text
   - Field 3 `새 비밀번호 확인` — default empty (placeholder)
4. Submit `완료` — disabled
5. UI bar

### Texts (verbatim)
- Field 1 value: `Abcd00@`
- Field 2 value: `Abcd00@`
- Helper (error, field 2): `새 비밀번호는 기존 비밀번호와 달라야 합니다.`
- Field 3 placeholder: `새 비밀번호를 한번 더 입력해주세요`
- (Other labels/placeholders same as `773-11733`)

### Colors used
- Same palette as 773-11733. No new tokens introduced.

### Typography
- Same as 773-11733. No new tokens.

### Form state — variant
**새 비밀번호 == 기존 비밀번호 (same-as-current) error** — triggered live on new-password change when value equals current password. Field 1 is filled but treated as valid (no error styling, no clear button — implies unfocused state). Field 2 shows error with clear button (implies focused). Field 3 is empty default.

Note on field 1: in this design the filled value displays WITHOUT a clear button, indicating Figma is showing the "filled + blurred" state. The current implementation in code only shows clear button when focused (matches).

### Interactions
- Field 2 clear button: tap → clears value → error hides
- Field 2 typing: live re-validation; once new ≠ current, border returns to gray200
- Submit stays disabled until all 3 fields valid

### Reusable component candidates
- Same as above. Reinforces InputForm needing `value` + `isFocused` driving clear button visibility, and `errorText` driving border + helper.

---

## 비밀번호 변경 - 새 비밀번호 확인 에러 (`773-11626`)

### Layout (top → bottom)
1. StatusBar (44)
2. Topbar `비밀번호 수정`
3. Container (top:118, gap:20):
   - Field 1 `기존 비밀번호` — filled `abcd00`, default border
   - Field 2 `새 비밀번호` — filled `abcd00`, default border
   - Field 3 `새 비밀번호 확인` — **error state**: filled `abcd01`, red border, clear button visible, helper text
4. Submit `완료` — disabled
5. UI bar

### Texts (verbatim)
- Field 1 value: `abcd00`
- Field 2 value: `abcd00`
- Field 3 value: `abcd01`
- Helper (error, field 3): `비밀번호가 일치하지 않습니다.`
- (Other labels/placeholders same as above)

### Colors used
- Same palette. No new tokens.

### Typography
- Same. No new tokens.

### Form state — variant
**confirm-mismatch error** — triggered when 새 비밀번호 확인 ≠ 새 비밀번호. Fields 1 & 2 filled with no error styling (note: `abcd00` would actually fail the rule pattern in current impl — Figma uses a simplified mock value for visual demo). Field 3 shows mismatch.

Submit remains disabled — likely because in spec semantics fields 1 & 2 might not pass full validation either, or simply because field 3 is in error. Implementation should keep `_canSubmit` gating on ALL validations.

### Interactions
- Field 3 clear button: clears input, hides error
- Field 3 typing: live re-validation against field 2 value
- Editing field 2 should also re-validate field 3 (already handled in current impl via `_handleNewPasswordChanged`)

### Reusable component candidates
- Same three: `InputForm`, `PrimaryButton`, `BackTopbar`.
- Cross-field validation pattern (field A change re-validates field B) is a candidate for a small form controller helper.

---

## Cross-variant summary

| Variant | Node | Error field | Trigger | Helper |
|---|---|---|---|---|
| 기존 비밀번호 mismatch | 773-11733 | 1 | submit | `기존 비밀번호가 일치하지 않습니다.` |
| 새 비밀번호 == 기존 | 773-11519 | 2 | live onChange | `새 비밀번호는 기존 비밀번호와 달라야 합니다.` |
| 확인 mismatch | 773-11626 | 3 | live onChange | `비밀번호가 일치하지 않습니다.` |

Submit button is `disabled` in all 3 frames (`bg gray200 #D5D8DE`, text `gray300 #A7ACB2`).
Container always reserves an 18px helper row per field so layout doesn't shift when error appears/disappears.
