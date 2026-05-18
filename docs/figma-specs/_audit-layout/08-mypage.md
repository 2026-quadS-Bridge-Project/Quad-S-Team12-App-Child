# Audit — 마이페이지 (`my_page.dart`)

**Scope**: Diagnostic only. No code changes performed.
**Target**: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/my_page/presentation/pages/my_page.dart`
**Figma**: file `tzJjQmXtXO7vGlfCT9SASu`, node `773:11103` (frame `scr/child-mypage`); dialog reference node `773:11838`.
**Spec doc**: `/Users/yeongj/Quad-S-Team12-App-Child/docs/figma-specs/03-mypage.md`
**Auditor mindset**: Quality Engineer / Figma parity.

---

## Audit summary table

| # | Check | Result |
|---|-------|--------|
| 1 | SafeArea / Scaffold composition | FAIL — `BridgeAppBar` is rendered inside `body`, not via `Scaffold(appBar:)`. |
| 2 | Back button position / hit area | PASS (with caveat — see Issue 6). |
| 3 | Profile section rows (anatomy + dividers) | PARTIAL — rows OK; no row-level dividers exist in Figma either. |
| 4 | 비밀번호 변경 navigation | PASS — `_PasswordRow` taps `context.push('/mypage/password')`; route exists. |
| 5 | 7px separator band color | PASS — uses `AppColors.gray150` (`#EDEEF1`). |
| 6 | 로그아웃 button presence | FAIL — present in code, absent in Figma; TODO comment flagged but not resolved. |
| 7 | 탈퇴하기 button size | FAIL — Figma 80×35 chip; code renders `BridgeButton(medium)` = 120×42. |
| 8 | Logout flow (`AuthSession.clearLogin()` + `context.go('/')`) | PASS functionally, but couples to unspecced button (Issue 6). |
| 9 | Inline delete-confirm dialog vs Figma `773-11838` | PARTIAL — close visual match, but several hard-coded literals + small geometric drift. |

---

## Issue 1 — Scaffold composition does not use the `appBar` slot

**Observation**
`my_page.dart:84-94` builds the screen as:

```dart
Scaffold(
  backgroundColor: AppColors.gray100,
  body: SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 375),
        child: Column(
          children: [
            const BridgeAppBar(title: '마이페이지'),
            ...
```

`BridgeAppBar` `implements PreferredSizeWidget` (`bridge_app_bar.dart:19`), so it is designed to be supplied through `Scaffold(appBar:)`.

**Root cause**
The app bar is treated as ordinary column content, which:
- Defeats `Scaffold`'s safe-area handling for the app bar zone (status-bar inset is handled by the outer `SafeArea`, which works but is non-idiomatic).
- Constrains the app bar to the 375 max-width box, so on tablets / wider devices the top bar will not stretch across the full viewport, unlike every other screen that uses `Scaffold(appBar:)`.
- Prevents `Scaffold` from applying the standard 52 px reserved area, which is what the Figma spec assumes (top bar at y=44–96 with system status above it).

**Figma ref**
- Node `325:17287` (Cmp/topbar) declares height = 52 anchored to the top edge of the 375 frame.
- 03-mypage.md §Layout: "44–96 Top bar … Height 52".

**Fix (do NOT apply now)**
Move `BridgeAppBar` to the `appBar:` slot; drop the outer `SafeArea` for the body (Scaffold already insets correctly for `appBar`).

---

## Issue 2 — 로그아웃 button present in code but omitted from Figma

**Observation**
`my_page.dart:122-141` renders a row containing both 로그아웃 (`_MyPageActionButton`, 80×35, gray) and 탈퇴하기 (`BridgeButton.destructive`). A TODO at line 125 flags the discrepancy but does not resolve it.

**Root cause**
Engineering shipped a feature that is not in design. Either (a) Figma is missing the button (design omission), or (b) the requirement was added without a design update.

**Figma ref**
- 03-mypage.md §Layout row at y=364–399 lists **only** 탈퇴하기 (node `257:3713`, width 80, height 35, right-aligned).
- 03-mypage.md explicit note line 28: "로그아웃 button is **NOT present** in this Figma frame".
- 03-mypage.md Deltas row #1 calls this out as an action item.

**Fix (do NOT apply now)**
Either remove the 로그아웃 button or update Figma. The current TODO has been outstanding since the file was created — it needs a decision.

---

## Issue 3 — 탈퇴하기 button size mismatches Figma chip

**Observation**
`my_page.dart:133-139` uses `BridgeButton(variant: destructive, size: medium, fullWidth: false)`. `bridge_button.dart:225-234` resolves `BridgeButtonSize.medium` to height = 42 and `fixedWidth: 120` (when `fullWidth: false`). On screen this renders a 120×42 chip.

Figma `257:3713` specifies the 탈퇴하기 chip as **80×35**, which matches the 로그아웃 chip's bespoke `_MyPageActionButton` (80×35, `my_page.dart:171-187`) — i.e. the wrong widget is being used.

**Root cause**
`BridgeButton` was selected for token correctness (destructive palette), but its `medium` size is calibrated for **dialog buttons** (per docblock at `bridge_button.dart:228-229`), not for the mypage chip footprint.

**Figma ref**
- 03-mypage.md §Layout y=364–399: "Width 80, height 35".
- 03-mypage.md Reusable component candidates: `MyPageActionChip({ ... })` — 80×35 rounded-8.

**Fix (do NOT apply now)**
Either (a) add a new `BridgeButtonSize.chip` (80×35) variant to `BridgeButton`, or (b) extend `_MyPageActionButton` to accept the destructive palette and use it for 탈퇴하기.

---

## Issue 4 — Inline literal colors in delete-account dialog bypass theme tokens

**Observation**
`_DeleteAccountDialog` and `_DeleteDialogButton` (`my_page.dart:191-330`) contain several hard-coded `Color(0xFF...)` literals:
- `Color.fromRGBO(68, 68, 68, 0.6)` at line 44 (barrierColor) — `AppColors.scrim` (`#99444444`) already encodes this.
- `Color(0xFFEBF5FE)` at line 311 (outlined background) — `AppColors.primaryLight` is the same value.

**Root cause**
The dialog was implemented before the token vocabulary was finalised; later token additions (Issue 1 of spec doc) never refactored the dialog.

**Figma ref**
- Dialog node `773:11838` (referenced by parent prompt) — modal scrim spec is documented in `app_colors.dart:62-63` as `rgba(68,68,68,0.60)`.
- 03-mypage.md token table line 53: `#FF4242` = destructive ✓.

**Fix (do NOT apply now)**
Replace inline literals with the existing tokens. No design change required.

---

## Issue 5 — Delete dialog uses fractional pixel dimensions

**Observation**
`my_page.dart:198-199`: dialog `width: 294.897, height: 189.705`.
`my_page.dart:307-308`: buttons `width: 107.889, height: 37.761`.
`my_page.dart:269`: `SizedBox(width: 13.486)` gap.
`my_page.dart:315`: `Border.all(... width: 0.899)`.

**Root cause**
Dimensions were transcribed directly from Figma's auto-layout output at non-1× export scale. The Figma source likely uses 12×24 grid values; the fractional numbers are an artefact of the screenshot/import workflow, not the design intent.

**Figma ref**
- Dialog reference node `773:11838` (per parent prompt). Without re-fetching the exact spec, the suspicion is rounded values (e.g. 295×190, 108×38, 13, 0.9).

**Fix (do NOT apply now)**
Round to integer pixels (or document the fractional values as deliberate). Sub-pixel borders (0.899) may anti-alias inconsistently across DPRs.

---

## Issue 6 — Back-button hit area is smaller than Material guideline

**Observation**
`bridge_app_bar.dart:102-122`: the back button is wrapped in `InkResponse(radius: 20)` over a `SizedBox(24, 24)`. Effective tap target is ~24 px.

**Root cause**
Figma's visual icon is 24×24, but Apple HIG / Material both require ≥44×44 hit area. `InkResponse(radius: 20)` produces a 40 px splash circle but does not enlarge the actual `GestureDetector` hit zone beyond the SizedBox.

**Figma ref**
- 03-mypage.md §Icons: "Back chevron (24×24, inner 8×16)".
- This is a **systemic** issue with `BridgeAppBar`, not unique to mypage — but it is exercised here.

**Fix (do NOT apply now)**
Wrap `_BackButton` in a 44×44 `SizedBox` and keep the visual icon at 24. Update `BridgeAppBar` rather than mypage.

---

## Issue 7 — `_DeleteAccountDialog` uses `Spacer` inside a `SizedBox`-less column

**Observation**
`my_page.dart:204-283`: the dialog `Column` contains `Spacer()` (line 260) without `mainAxisSize: MainAxisSize.max`. This works only because the parent `Container` is given a fixed `height: 189.705`. If the height ever becomes intrinsic (e.g., to support dynamic text length / accessibility large fonts), the `Spacer` will throw.

**Root cause**
Fixed-height container papers over the layout fragility. Not Figma-accurate behaviour for accessibility (text scaling will overflow).

**Figma ref**
- N/A — accessibility quality concern, not a Figma deviation.

**Fix (do NOT apply now)**
Replace fixed height + Spacer with `mainAxisSize: MainAxisSize.min` + explicit `SizedBox(height: ...)` spacing.

---

## Issue 8 — Hard-coded sample data (`_accountType`, `_childCode`)

**Observation**
`my_page.dart:18-19`: `_accountType = '자녀회원'`, `_childCode = 'XY785eZ'` are static constants. Only `_username` is loaded from `AuthSession`.

**Root cause**
Backend wiring for account type and child code is unimplemented. Spec doc (Deltas row #3) acknowledges this as a known TODO.

**Figma ref**
- 03-mypage.md row Δ#3: "Hard-coded `XY785eZ` / OK — both static; backend wiring still TODO."

**Fix (do NOT apply now)**
Wire to a repository/provider once the API exists. Out of scope for layout audit.

---

## Issue 9 — `Align + ConstrainedBox(maxWidth: 375)` is the wrong responsive idiom

**Observation**
`my_page.dart:87-91` centres a 375-wide column on the screen. On a tablet, the side margins will be flat gray100 with the column floating in the middle — the separator band (`width: double.infinity`, line 113) will also stop at 375.

**Root cause**
Treating Figma's 375 frame width as a hard maximum collides with full-bleed elements (separator band) that visually rely on edge-to-edge rendering.

**Figma ref**
- Figma frame is 375 wide; the separator at node `773:11123` is documented as `374×7` (i.e., effectively full-bleed within the 375 canvas).

**Fix (do NOT apply now)**
Either let the screen stretch (drop the 375 cap), or move the cap to a single inner content column and render the separator outside of it.

---

## Cross-cut verifications (checks that passed cleanly)

- **Check 4 — Password navigation**: `_PasswordRow` (`my_page.dart:387-388`) calls `context.push('/mypage/password')`. Route registered at `app_router.dart:37-41`. Working.
- **Check 5 — Separator band token**: `Container(height: 7, color: AppColors.gray150)` (`my_page.dart:112-116`) matches Figma `#EDEEF1`.
- **Check 8 — Logout flow**: `AuthSession.clearLogin()` (defined `auth_session.dart:24-28`) followed by `context.go('/')` is correct — `/` is the `HomePage` per `app_router.dart:29`. Logic is correct *if* the button stays (see Issue 2).
- **Row spacing**: 24 px gaps between rows match Figma `gap=24`.
- **Vertical divider in `_InfoRow`**: 1×22 px `AppColors.gray200` matches Figma `#D5D8DE`.

---

## Recommendations (deferred — no fixes yet)

1. Resolve the **로그아웃 button decision** (Issue 2) — blocking design parity sign-off.
2. Fix the **탈퇴하기 chip size** (Issue 3) — most visible parity defect.
3. Move app bar into `Scaffold(appBar:)` (Issue 1) — improves correctness across all routes using `BridgeAppBar`.
4. Replace dialog inline literals with tokens (Issue 4) and round fractional dimensions (Issue 5).
5. Enlarge back-button hit area to 44 px (Issue 6) — accessibility benefit beyond this screen.
