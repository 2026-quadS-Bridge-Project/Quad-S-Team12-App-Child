# Phase 2 Audit — Existing Screens (Login / Signup / Home Intro / Delete Complete / Child Home)

> Audit only — no fixes applied. Verified against `docs/figma-specs/02-child-home.md`,
> `docs/figma-specs/05-delete.md`, `docs/figma-specs/00-CATALOG.md`, and `docs/UI-figma.md`.
> Per user, login/signup are out-of-Figma-scope; only token discipline + shared-widget
> reuse is checked there. Severity tiers: **Tier 1** = blocking visual delta or hex
> literal violation. **Tier 2** = should-fix (token/shared-widget reuse). **Tier 3** =
> nice-to-have polish.

---

## Files audited
1. `lib/features/login/presentation/pages/login_page.dart`
2. `lib/features/signup/presentation/pages/signup_page.dart`
3. `lib/features/home/presentation/pages/home_page.dart`
4. `lib/features/my_page/presentation/pages/delete_account_complete_page.dart`
5. `lib/features/child_home/presentation/pages/child_home_page.dart`

---

## 1) `login_page.dart`

### PASS
- All field/border/text colors flow through `AppColors` tokens (`gray100`, `gray200`,
  `gray500`, `gray600`, `gray300`, `destructive`, `white`, `primary`, `black`).
- Typography uses `AppTypography.{headlineMedium, bodyMedium, labelMedium, captionBold}`
  — no inline `TextStyle(fontFamily: …)` constructions.
- Toast pattern (gray500 pill + destructive `!` glyph + white text) matches the
  shared toast pattern used in signup.
- Frame width 375 / horizontal pad 24 / button height 54 / radius 8 match
  `00-CATALOG.md` button standard.

### FAIL
- **login_page.dart:209 — stray hex `Color(0xFF050505)` for topbar title.** This is
  the `inkBlack` color and `AppColors.inkBlack = #050505` exists (app_colors.dart:37).
  Replace literal with token.
- **login_page.dart:174-217 — bespoke `_LoginTopBar` instead of `BridgeAppBar`.**
  Shared `BridgeAppBar('로그인')` (lib/core/widgets/layout/bridge_app_bar.dart) covers
  identical 52h Stack-with-centered-title + back at left=14 + SVG `back.svg`. Keeping
  the bespoke version creates two divergent topbars; `BridgeAppBar` already uses
  `AppTypography.headlineBold` + `textPrimary` (= inkBlack), which is closer to the
  CATALOG standard than the local `headlineMedium` copyWith.
- **login_page.dart:360-399 — `_LoginButton` reimplements `BridgeButton.primary`.**
  Same height 54, radius 8, primary bg, gray200 disabled bg, gray300 disabled fg.
  The shared `BridgeButton(variant: primary, size: large)` is the canonical
  implementation; using `FilledButton` here bypasses the token system and the
  established splash/highlight states.

### Tier
- Tier 1: 0 (no Figma node to violate)
- Tier 2: 3 (hex literal, BridgeAppBar reuse, BridgeButton reuse)
- Tier 3: 0

---

## 2) `signup_page.dart`

### PASS
- Token discipline identical to login: every color flows through `AppColors.*`.
- Field check states (`_CheckState.{hidden,inactive,active}`) cleanly mapped to
  `primary`/`gray200`/transparent — no hex.
- Helper text uses `captionMedium` + `destructive` color; toast uses
  `labelMedium` + `gray500` bg — both pattern-consistent with login.

### FAIL
- **signup_page.dart:338 — stray hex `Color(0xFF050505)`.** Same defect as login.
  Use `AppColors.inkBlack`.
- **signup_page.dart:303-346 — bespoke `_SignupTopBar` duplicates `_LoginTopBar`
  which duplicates `BridgeAppBar`.** Three copies of the same widget exist.
  Consolidate via `BridgeAppBar('회원가입')`.
- **signup_page.dart:539-578 — `_SignupButton` reimplements `BridgeButton.primary`.**
  Identical pattern to login. Same recommendation: swap to shared widget.
- **signup_page.dart:456-475 — `_FieldCheck` uses `Icons.check_rounded` (Material).**
  The 회원가입 Figma node is not in the audited specs, but the catalog's
  `BridgeTextField (withCheck variant)` lists this exact use case (00-CATALOG.md §2.1).
  When the input atom lands it should absorb this.

### Tier
- Tier 1: 0
- Tier 2: 3 (hex literal, BridgeAppBar reuse, BridgeButton reuse)
- Tier 3: 1 (Material check icon vs eventual `BridgeTextField`)

---

## 3) `home_page.dart` (intro)

### PASS
- Uses `AppTokens.mobileFrameWidth` + `AppTokens.mobileHorizontalPadding` correctly.
- All non-logo colors flow through `AppColors` (`gray050`, `primary`, `white`,
  `gray400`).
- Bridge brand logo gets explicit `'Sigmar'` family + `Pretendard` fallback —
  acceptable since this is a one-off brand wordmark, not body text.

### FAIL
- **home_page.dart:12 — stray hex `Color(0xFF6DB5FF)` for the Bridge wordmark.**
  This blue is NOT `AppColors.primary` (`#3A99F8`) — it's a lighter tint specific to
  the wordmark. Either (a) add a `AppColors.brandWordmark = #6DB5FF` token with a
  comment that it's brand-only, or (b) document why it deviates from `primary`. The
  current bare literal violates the catalog token discipline.
- **home_page.dart:127-145 — `ElevatedButton` for the primary CTA instead of
  `BridgeButton`.** `BridgeButton(label: '자녀 회원가입', variant: primary, size: large,
  onPressed: ...)` is the canonical path. Current impl manually sets `elevation: 0`,
  radius, background and text style — all already encapsulated in `BridgeButton`.
- **home_page.dart:158-167 — `GestureDetector + Text` for the "로그인" link.**
  `BridgeButton(variant: textLink)` is purpose-built for inline navigation links
  (bridge_button.dart:195-202) and would provide a Semantics button role + tap
  feedback. Current implementation is silent to screen readers.

### Tier
- Tier 1: 1 (hex literal in brand wordmark needs decision)
- Tier 2: 2 (BridgeButton reuse for both CTA and text link)
- Tier 3: 0

### Notes
- The intro node is `662-8356` per the user; the in-spec page is named "로그인"
  in `docs/UI-figma.md` but the rendered frame is this Bridge intro. No
  per-pixel Figma spec doc was produced for this screen, so visual-fidelity
  deltas cannot be verified — only token/widget discipline.

---

## 4) `delete_account_complete_page.dart`

### PASS
- Background `AppColors.gray050` ✓ matches spec (`05-delete.md` line 8).
- Text color `AppColors.gray600` ✓ matches `#5F6165` (05-delete.md line 110).
- Auto-redirect via 3 s `Timer` + `AuthSession.clearLogin()` in `initState` ✓
  matches the documented UX requirement (05-delete.md line 132).
- No hex literals.

### FAIL
- **delete_account_complete_page.dart:55-58 — Three Figma-spec deltas in one
  `TextStyle.copyWith`** (per `05-delete.md` "Deltas" table lines 167-180):
  - `fontSize: 17.982` — Figma is **20**. This is the "90% scale" symptom (see
    Cross-cutting below).
  - `letterSpacing: -0.2158` — Figma is **-0.24**.
  - `heading2Regular` (weight 400) — Figma rendered runs override to **Bold 700**
    even though the declared style is Regular (05-delete.md line 121).
- **delete_account_complete_page.dart:50 — `SizedBox(width: 294.897)`.** Figma
  width is **328** (05-delete.md line 171). The fractional `.897` is another
  90%-scale artifact (294.897 / 0.8997 ≈ 327.8).
- **delete_account_complete_page.dart:46-65 — `Align(topCenter) → Center(...)`
  produces vertical centering only inside the `ConstrainedBox(maxWidth:375)`
  child column, not relative to the viewport.** For a 812h frame this happens
  to land correctly, but the spec wants vertical + horizontal centering anchored
  to the viewport. Replacing with a single `Center` wrapping the `SizedBox`
  inside the `SafeArea` would be both simpler and spec-correct.

### Tier
- Tier 1: 1 (font size 17.982 vs 20 — visible)
- Tier 1: 1 (font weight Regular vs Bold — visible)
- Tier 2: 2 (width 294.897 vs 328; layout simplification)
- Tier 3: 1 (letter-spacing -0.2158 vs -0.24)

---

## 5) `child_home_page.dart`

### PASS
- Uses `AppTokens.mobileFrameWidth` for frame ✓.
- Almost-complete migration of previously-hard-coded colors to tokens:
  `bonusAmber`, `gray150`, `primaryLight`, `primarySoft`, `primarySubtle`,
  `scrim`-adjacent — all now token-backed.
- Top-bar uses bespoke `_TopBar` + `_MyPageButton` — acceptable here because the
  child-home top bar is **not** the standard `BridgeAppBar` pattern (it has no
  back button, no centered title, and a custom `my` left-border glyph).
  `00-CATALOG.md` §2.3 explicitly lists `BridgeTopBar (자녀홈 전용)` as a separate
  organism.
- Dual-ring donut math matches `02-child-home.md` lines 100-105 (radii 55/39,
  strokes 14/11, start angle -π/2, base `gray150`, progress `primary`/`bonusAmber`).
- Mission card chrome (84h, radius 16, 19h/18v padding, 19px row gap) matches
  spec line 110-113.

### FAIL
- **child_home_page.dart:359 — `Color(0x80D9D9D9)` for the time-card shadow.**
  Matches the Figma value (`rgba(217,217,217,0.5)` per 02-child-home.md line 56),
  but the spec's "Deltas vs current" §9 (line 184) explicitly calls for
  `AppTokens.cardShadow` extraction. The literal works visually but undermines
  catalog token discipline.
- **child_home_page.dart:852 — `Color(0xFFFFD980)` for completed-mission ring.**
  Already flagged with a `TODO(tokens)` comment (lines 848-851). Spec
  (02-child-home.md line 142, "Deltas" §4 line 179) suggests tokenizing as
  `AppColors.amber050` or treating as `bonusAmber` with 0.5 tint. This is the
  last hex literal in the file.
- **child_home_page.dart:138 — top-bar→content gap is `30` when `hasContent`,
  but Figma v2 specifies 40 px (container at y=118 with top-bar at y=56 +
  h=32 → gap of 40).** Spec "Deltas" §1 line 176.
- **child_home_page.dart:323-327 — empty-state settings cog uses
  `Icons.settings` (Material).** Figma uses a lighter outlined glyph
  (02-child-home.md line 24, "Deltas" §10 line 185). The bar-chart icon at line
  297 has the same issue.
- **child_home_page.dart:887-892 — `_ReviewingStatusIcon` uses
  `AppColors.positive` (`#00BF40`).** Spec (02-child-home.md "Deltas" §3
  line 178) notes the implementation drifted to `#16BF40` historically; the
  current code is now token-correct but the spec also questions whether
  positive-green is the right semantic (it's a "reviewing" state, not a
  success state). Designer confirmation pending.

### Tier
- Tier 1: 0 (no blocking visual deltas)
- Tier 2: 4 (two hex literals; top-bar gap 30→40; settings/bar-chart Material icons)
- Tier 3: 1 (reviewing semantic-color question)

### Notes
- `child_home_page.dart:139-157 — `Opacity(opacity: onboarding ? 0.2 : 1)`
  scrim approach** correctly matches the Figma overlay pattern. The
  `_ParentConnectGuide` tooltip uses `primarySoft` + `primarySubtle` tokens
  correctly.
- The bottom-nav bar referenced in `00-CATALOG.md` §2.3 is **not** present in
  this screen — confirmed acceptable; bottom nav is a Phase-0 shell concern.

---

## Cross-cutting findings

### "90% scale" symptom
**Present** in `delete_account_complete_page.dart` only (font-size 17.982
≈ 20 × 0.8991, width 294.897 ≈ 328 × 0.8991, letter-spacing -0.2158 ≈
-0.24 × 0.8991). The login/signup/intro/child-home screens are all clean
(no fractional pixel values, no .X scaled font sizes).

### Stray hex literals across audited files (4 total)
| File | Line | Hex | Token replacement |
|---|---|---|---|
| login_page.dart | 209 | `0xFF050505` | `AppColors.inkBlack` |
| signup_page.dart | 338 | `0xFF050505` | `AppColors.inkBlack` |
| home_page.dart | 12 | `0xFF6DB5FF` | (new) `AppColors.brandWordmark` or decision |
| child_home_page.dart | 359 | `0x80D9D9D9` | (new) `AppTokens.cardShadow` |
| child_home_page.dart | 852 | `0xFFFFD980` | (new) `AppColors.amber050` or `bonusAmber` w/ tint |

### Shared-widget reuse gaps
| Widget | Used in | Should be reused in |
|---|---|---|
| `BridgeAppBar` | mypage, password change, etc. | login (`_LoginTopBar`), signup (`_SignupTopBar`) |
| `BridgeButton(primary, large)` | most CTAs | login (`_LoginButton`), signup (`_SignupButton`), home (`ElevatedButton`) |
| `BridgeButton(textLink)` | n/a yet | home `로그인` link |
| `BridgeButton(outlined/primary, medium)` | mission flow | mypage `_DeleteDialogButton` (separate audit; only complete page in scope) |

### Things that look correct
- All five files use `Pretendard` via `AppTypography` (no direct
  `TextStyle(fontFamily: 'Pretendard')` constructions).
- Background colors uniformly use `AppColors.gray100` or `gray050` per spec.
- Status-bar treatment via `AnnotatedRegion<SystemUiOverlayStyle>` is consistent
  in home/intro and child-home.

---

## Severity tally

| File | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| login_page.dart | 0 | 3 | 0 |
| signup_page.dart | 0 | 3 | 1 |
| home_page.dart | 1 | 2 | 0 |
| delete_account_complete_page.dart | 2 | 2 | 1 |
| child_home_page.dart | 0 | 4 | 1 |
| **Total** | **3** | **14** | **3** |

Overall posture: **PARTIAL PASS**. No blocking visual deltas on the three
in-Figma-spec screens (child home v1/v2 + delete complete) once the delete
complete font size/weight is corrected. Token discipline is 90%+ clean — the
five remaining hex literals are localized and tokenizable. Largest debt is the
parallel topbar/button implementations in login/signup/home that should
collapse onto `BridgeAppBar` + `BridgeButton`.
