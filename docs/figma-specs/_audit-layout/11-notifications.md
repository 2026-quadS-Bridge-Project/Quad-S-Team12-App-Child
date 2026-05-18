# Audit — 11 Notifications (child vs parent)

Diagnostic only. No fixes applied.

- **Target (child)**: `lib/features/notifications/presentation/pages/notifications_page.dart`
- **Companion widget (child)**: `lib/features/notifications/presentation/widgets/notification_card.dart`
- **Mock (child)**: `lib/features/notifications/data/mock/notifications_mock.dart`
- **Model (child)**: `lib/features/notifications/data/models/notification_item.dart`
- **Reference (parent)**: `Quad-S-Team12-App-Parent/lib/features/notifications/presentation/pages/notifications_page.dart`
- **Reference widget (parent)**: `Quad-S-Team12-App-Parent/lib/features/notifications/presentation/widgets/notification_card.dart`
- **Reference model (parent)**: `Quad-S-Team12-App-Parent/lib/features/notifications/presentation/models/notification_item.dart`
- **Figma**: `426-19287` (empty), `426-19293` (filled), `773-12916` swipe, `773-12903` dialog
- **Spec**: `docs/figma-specs/06-notifications.md`

Verdict overview: page-level Scaffold/SafeArea/Column composition, top bar, ListView padding, dialog dimensions, empty-state copy, and swipe threshold are 1:1 with parent. Drift is concentrated in (a) mock copy not matching parent verbatim, (b) the title-chip color for `missionCompleted` token mapping, and (c) the raw `0xFFFF4B4B` delete-reveal icon color which both apps duplicate but child has a token available for.

---

## Issue 1 — Mock content drift from parent (mission/time/confirmation copy not 1:1)

**Observation.** Child `NotificationsMock.filled` and parent inline list both render 3 cards with the same `id`s and `type`s, but the `title`/`message` strings differ:

| id | parent.title | child.title | parent.message | child.message |
| --- | --- | --- | --- | --- |
| `mission-completed` | `미션완료` | `미션완료` | `자녀가 숙제하기 미션을 완료했어요.\n보너스 시간 15분 획득!` | `숙제하기 미션 수행이 확인되었어요.\n보너스 시간 15분 획득!` |
| `mission-confirmation-requested` | `미션 확인 요청` | `미션 확인 요청` | `자녀가 숙제하기 미션 완료 확인을 요청했어요.` | `숙제하기 미션 확인 요청을 부모님께 전달했어요.` |
| `time-configured` | `시간설정 완료` | `시간설정 완료` | `자녀가 1월달 사용 시간 설정을 완료했어요!` | `1월달 사용 시간 설정이 완료되었어요!` |

**Root cause.** `mock/notifications_mock.dart` header explicitly states the strings were "rewritten from the child's perspective" (parent-facing → child-facing voice change), but the task brief asks for 1:1 visual parity with parent. The rewrite is intentional content drift, not an oversight.

**Reference.** `Quad-S-Team12-App-Parent/lib/features/notifications/presentation/pages/notifications_page.dart:18-40` holds the canonical copy inline; child seed is in `lib/features/notifications/data/mock/notifications_mock.dart:8-30`.

**Fix (do not apply now).** Decide product-side whether the child surface should keep the parent's parent-perspective text or use a child-perspective rewrite. If "1:1" is the contract, restore the parent's three message strings verbatim. If child perspective is intentional, update `06-notifications.md` and this audit's "1:1 visual" framing, and align the title casing (`미션완료` vs spec's normalized `미션 완료` — note spec §filled also flags this casing inconsistency).

---

## Issue 2 — `missionCompleted` title chip uses raw hex in parent, token in child (correct), but `_NotificationLeadingIcon` color path is still raw in parent and matches in child only because `AppColors.secondaryYellow == 0xFFFFCC33`

**Observation.** Parent `NotificationCard._NotificationStyle.fromType(missionCompleted)` returns `Color(0xFFFFCC33)` raw for both `accentColor` and `backgroundColor` (parent `notification_card.dart:256-258`). Child correctly substitutes `AppColors.secondaryYellow` (child `notification_card.dart:258-259`). The two render identically because `AppColors.secondaryYellow = Color(0xFFFFCC33)` (child `app_colors.dart:75`). Parent has no equivalent token (parent `app_colors.dart` ends at line 33, no secondary tokens defined).

**Root cause.** Token catalogs are intentionally divergent: child has the extended Figma-validated tonal ramp (incl. `secondaryYellow`, `primaryLight`, `destructiveSubtle`, `inkBlack`, `scrim`), parent does not. The visual output is byte-identical for missionCompleted, so this is a **token-discipline drift, not a visual drift**. The change is an improvement in the child direction.

**Reference.** Spec §filled "Title colors by type" line 87 maps `#FFCC33 → secondary` — child usage of `AppColors.secondaryYellow` is the spec-correct path.

**Fix (do not apply now).** None on child side — child is correct. If perfect symbol-for-symbol parity with parent is required, would need to revert child to `Color(0xFFFFCC33)` raw, which contradicts token discipline rule 8 in the task brief. Recommend keeping the child token and back-porting `secondaryYellow` to parent in a separate task.

---

## Issue 3 — `_DeleteRevealIcon` color `0xFFFF4B4B` is raw hex in both apps; child has a token but does not use it

**Observation.** Child `notification_card.dart:212` declares `color: Color(0xFFFF4B4B)` for the swipe-reveal trailing circle. Parent same file line 210 does the exact same thing. Child `AppColors` has `destructive = 0xFFFF4242` (different hex — note `FF4B4B` ≠ `FF4242`) but no `0xFFFF4B4B` token.

**Root cause.** The figma swipe-reveal icon color (`#FF4B4B`) is a **distinct shade** from the destructive title color (`#FF4242`) used elsewhere. Spec §"Delete interaction (model)" line 174 only documents the X icon as "filled red circle" without giving the exact hex; spec §"Colors" line 161 lists `#FF4242 destructive` for the title chip, leaving `#FF4B4B` undocumented. The raw literal is in both apps because no token exists for it.

**Reference.** Child `lib/core/theme/app_colors.dart:21` defines `destructive = 0xFFFF4242`; spec `06-notifications.md:160-165` documents `#FFD3D3 → destructive100`/`destructiveSubtle` (which child uses correctly at line 108) and `#FF4242 → destructive` but is silent on `#FF4B4B`.

**Fix (do not apply now).** Two options, in priority order:
1. Re-measure the Figma node `773-12916` to confirm whether the reveal icon is `#FF4B4B` or actually `#FF4242` rounded differently — if `#FF4242`, replace with `AppColors.destructive` (cleanest).
2. If `#FF4B4B` is intentional, add a new token (e.g. `AppColors.destructiveSwipeAction = Color(0xFFFF4B4B)`) and update `06-notifications.md` to document it, then update child + parent.

---

## Issue 4 — `actionLabel` default `'확인하러 가기'` is unused on child seed and adds a non-spec arrow concatenation pathway

**Observation.** Child `NotificationItem` constructor (model `notification_item.dart:14`) provides `this.actionLabel = '확인하러 가기'` default; `NotificationCard` then renders `'${widget.item.actionLabel} →'` (widget line 182). Parent model + widget have the identical pattern. No card in either mock overrides the default.

**Root cause.** Field exists for future per-card CTA flexibility but every consumer uses the default, so the abstraction layer adds no value today. Not a bug — minor YAGNI flag only.

**Reference.** Spec §filled "Common per tile" line 76: `CTA link: 확인하러 가기 →`. The default value is spec-correct.

**Fix (do not apply now).** Acceptable as-is; revisit only if `NotificationItem` is consolidated into shared package.

---

## Issue 5 — Drag-swipe gesture: works on iOS but competes with horizontal route-pop gesture

**Observation.** `NotificationCard` uses `GestureDetector(onHorizontalDragUpdate / onHorizontalDragEnd / onHorizontalDragCancel)` (widget `notification_card.dart:88-97`). The page is reached via `context.pop` from `_NotificationsTopBar` back button — typical entry is through a `MaterialPageRoute` (or Cupertino route) which on iOS gives the user a back-swipe-from-left-edge gesture by default. The card's horizontal drag handler claims drags in the `dx > 0` direction within the card area, but the card only consumes negative offsets (`.clamp(-_maxSlide, 0)` at line 93). A right-to-left swipe on iOS will be recognised by Flutter's `GestureDetector` competitively with `CupertinoPageTransitionsBuilder`'s back-swipe recognizer.

**Behaviour on iOS.**
- Left-edge swipe (back gesture): the `_CupertinoBackGestureDetector` only activates within ~20px of the leading edge, so cards in the centre of the screen will still receive horizontal drag updates → swipe-to-reveal works.
- Mid-screen right-to-left swipe: gesture arena resolves in favour of the `GestureDetector` since `CupertinoBackGestureDetector` is not contesting outside the edge zone → swipe-to-reveal works.
- Mid-screen left-to-right swipe (after the user has revealed the action): `_dragOffset` already negative, drag increases it back toward 0 via the same handler → card snaps back, no conflict with route pop because we are not at the leading edge.

**Threshold.** Code line 66: `_dragOffset <= -_maxSlide * 0.85` → trigger at `-48.5` of `-57.09` max = 85% (parent line 64 identical). Spec line 175 says implementation "should use Flutter `Dismissible` with `dismissThresholds = 0.4`" (40%). Both apps use a custom non-`Dismissible` implementation at 85% — **deliberate divergence from spec**, but **matches parent exactly**.

**Root cause.** Custom `Transform.translate` + manual `GestureDetector` was chosen instead of `Dismissible` to give the open-then-dialog-then-snap-back UX with no auto-removal animation. This is intentional in parent and faithfully copied in child.

**Reference.** Parent `notification_card.dart:25-77` (full state machine + thresholds copied byte-for-byte). Spec `06-notifications.md:173-176` describes the alternative `Dismissible` approach.

**Fix (do not apply now).** Behaviour is correct on iOS in normal cases. Two latent risks to validate manually:
1. Confirm no jank when the user swipes a card while the page is transitioning in (route animation + drag should not deadlock).
2. Consider wrapping the page in `PopScope` if the dialog should not be back-swipe-dismissible while open (currently `barrierDismissible: true` is fine, but iOS back-swipe on the underlying route while dialog is open could cause stack confusion — needs manual test).

---

## Issue 6 — Underscore-prefixed unused parameter syntax `(_, _) =>` requires Dart ≥3.7

**Observation.** Child `notifications_page.dart:115` and `:33` use `(_, _) =>` and `(BuildContext context, _, _) {}` — wildcard variable pattern. Parent same file uses named ignored parameters (`(context, index)`, `(context, animation, secondaryAnimation)`). Code style drift; both compile but child requires SDK ≥3.7 to use wildcard variables.

**Root cause.** Modernisation pass during the child rewrite. Not a bug if `pubspec.yaml` SDK constraint allows it.

**Reference.** Parent `notifications_page.dart:130, :48, :75` for the named-param style.

**Fix (do not apply now).** Verify `pubspec.yaml` constraint includes Dart 3.7+. If yes, child style is fine; if no, restore named-but-ignored params to match parent.

---

## Issue 7 — `_DeleteDialogButton` cancel-bg token: parent raw, child uses `AppColors.primaryLight` (correct)

**Observation.** Parent `notifications_page.dart:270`: `color: filled ? AppColors.primary : const Color(0xFFEBF5FE)`. Child `notifications_page.dart:255`: `color: filled ? AppColors.primary : AppColors.primaryLight`. Token resolves to the same hex (`#EBF5FE` per child `app_colors.dart:46`).

**Root cause.** Same as Issue 2 — child token catalog is richer.

**Reference.** Spec `06-notifications.md:213,251` defines `primary050 = primaryLight = #EBF5FE`.

**Fix (do not apply now).** Child is correct.

---

## Issue 8 — `_NotificationsTopBar` title color: parent raw, child uses `AppColors.inkBlack` (correct)

**Observation.** Parent line 326: `color: const Color(0xFF050505)`. Child line 311: `color: AppColors.inkBlack`. Equivalent at runtime.

**Root cause.** Child token catalog adds `inkBlack` per `00-CATALOG.md` §1.1; parent does not.

**Reference.** Spec `06-notifications.md:28` "Header title: #050505 → near-black".

**Fix (do not apply now).** Child is correct.

---

## Issue 9 — Mock messages reference 1월달 (January) hard-coded — same on both apps

**Observation.** Both apps hardcode `1월달 사용 시간`. Not a parity issue; flagged for product context (will become stale when crossing year boundary or if real backend supplies the month).

**Root cause.** Mock-only data; expected when wiring to backend.

**Reference.** N/A — copy parity preserved.

**Fix (do not apply now).** Replace with templated string `'${month}월달 사용 시간'` only when real data lands.

---

## Issue 10 — Mock id `mission-confirmation-requested` semantics differ between apps

**Observation.** Both apps use the same `id` + same `NotificationType.missionConfirmationRequested`, but in parent the message says "자녀가 ... 확인을 **요청**했어요" (request received from child), while child says "확인 요청을 부모님께 **전달**했어요" (request sent to parent). The `type` enum on each side is identical, so the icon (`Icons.autorenew_rounded`) and color (`AppColors.positive`, green) are the same on both — but the *direction* of the action is opposite.

**Root cause.** A single shared `NotificationType` is used to describe two different real-world events from two different actor perspectives. Loud semantics warning: when the model is eventually shared between apps, this enum will need either splitting (`missionConfirmationRequestedByChild` vs `missionConfirmationRequestSent`) or a separate `actor` field.

**Reference.** Child model `notification_item.dart:1-5`; parent model `models/notification_item.dart:1-5` (identical enums).

**Fix (do not apply now).** Defer until cross-app shared model is introduced.

---

## Token-discipline summary

| # | Item | Child uses | Parent uses | Status |
| --- | --- | --- | --- | --- |
| 1 | Page bg `#F5F7FA` | `AppColors.gray100` | `AppColors.gray100` | Match |
| 2 | Top bar title `#050505` | `AppColors.inkBlack` | raw `0xFF050505` | Child better |
| 3 | Card bg `#FFFFFF` | `AppColors.white` | `AppColors.white` | Match |
| 4 | Body `#2F3032` | `AppColors.gray800` | `AppColors.gray800` | Match |
| 5 | Timestamp `#A7ACB2` | `AppColors.gray300` | `AppColors.gray300` | Match |
| 6 | CTA `#777A7F` | `AppColors.gray500` | `AppColors.gray500` | Match |
| 7 | Mission completed chip `#FFCC33` | `AppColors.secondaryYellow` | raw `0xFFFFCC33` | Child better |
| 8 | Confirmation chip `#00BF40` | `AppColors.positive` | `AppColors.positive` | Match |
| 9 | Time-set chip `#3A99F8` | `AppColors.primary` | `AppColors.primary` | Match |
| 10 | Swipe panel `#FFD3D3` | `AppColors.destructiveSubtle` | raw `0xFFFFD3D3` | Child better |
| 11 | Swipe icon `#FF4B4B` | raw `0xFFFF4B4B` | raw `0xFFFF4B4B` | **No token either side** |
| 12 | Dialog cancel bg `#EBF5FE` | `AppColors.primaryLight` | raw `0xFFEBF5FE` | Child better |
| 13 | Dialog confirm bg `#3A99F8` | `AppColors.primary` | `AppColors.primary` | Match |
| 14 | Dialog title `#2F3032` | `AppColors.gray800` | `AppColors.gray800` | Match |
| 15 | Dialog warning icon `#FF4242` | `AppColors.destructive` | `AppColors.destructive` | Match |
| 16 | Scrim `rgba(68,68,68,0.6)` | inline `Color.fromRGBO(68,68,68,0.6)` | inline `Color.fromRGBO(68,68,68,0.6)` | **Both miss `AppColors.scrim`** |

---

## Layout checklist (per task brief, items 1–10)

1. **SafeArea / Scaffold composition**: `Scaffold(body: SafeArea(Align(ConstrainedBox(maxWidth:375) → Padding(20) → Column[_NotificationsTopBar, Expanded(empty|list)])))`. Child line 76-134 vs parent line 91-149 — **identical**.
2. **`_NotificationsTopBar` height 52, back button at `left:0, top:14, 24x24`** with `EdgeInsets.all(2)` SVG padding. Child line 283-303 vs parent line 298-318 — **identical**.
3. **ListView padding/separator**: `padding: EdgeInsets.zero`, separator `SizedBox(height: 13.486)`, list wrapped in `Padding(EdgeInsets.only(top: 22))`. Child line 110-126 vs parent line 125-141 — **identical**.
4. **`NotificationCard` drag-swipe**: state machine, `_maxSlide = 57.09`, threshold `-_maxSlide * 0.85`, `_animateTo` curve `easeOutCubic`, 180 ms. iOS behaviour analysed in Issue 5 — works correctly outside the leading 20 px back-gesture zone.
5. **Delete dialog dimensions**: `294.897 × 189.705`, radius 12, padding `(18, 33, 18, 27)`, button `107.889 × 37.761` with `gap: 13.486`. Child line 144-231 vs parent line 159-246 — **identical pixel values**.
6. **Mock data**: 3 categories (missionCompleted / missionConfirmationRequested / timeConfigured) — **structure matches**, **copy does not** (Issue 1).
7. **Empty state copy**: `'확인하지 않은 알림이 없습니다.'`, `fontSize: 16.183`, `height: 1.445`, `letterSpacing: -0.0032`, `color: AppColors.gray300`. Child line 94-104 vs parent line 109-119 — **identical**.
8. **`Color(0xFFFF4B4B)` for delete reveal icon**: present raw in both apps — see Issue 3.
9. **Category icon colors**: missionCompleted uses `AppColors.secondaryYellow` (child) vs raw `#FFCC33` (parent) — see Issue 2. Confirmation = `positive`, time-set = `primary` — **match both apps**.
10. **Background `AppColors.gray100`**: confirmed both apps line 77/92 — **match**.
