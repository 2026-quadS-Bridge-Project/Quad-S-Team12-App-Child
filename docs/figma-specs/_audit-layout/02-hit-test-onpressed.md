# Hit-Test / onPressed Audit (Diagnostic Only — No Fixes Applied)

User complaint: "버튼자체가 동작하지 않는 경우도 많아서" (many buttons don't work).

Scope: every interactive element in `lib/features/**/presentation/pages/**/*.dart`
and `lib/core/widgets/**/*.dart` that is visually a button/tap target but
either does not wire a handler, has a dead/no-op handler, has a too-small hit
area, or is shadowed by a transparent overlay.

Date: 2026-05-18.
Author: quality-engineer audit.

---

## Summary

- **DEAD interactive elements (handler is null / `() {}` / no-op):** 5
- **POTENTIALLY BROKEN (wired but blocked by upstream bug, double-handler, or
  hit-area issue):** 10
- **STYLE / SPEC violations (still works, but skews from Bridge button system):** 3
- **DEAD pixels (visual button look-alike with no detector at all):** 3
- **TOTAL findings:** 21 across 11 files

Top 5 pages with the most or most severe issues:

1. `lib/features/my_page/presentation/pages/password_change_page.dart`
2. `lib/features/notifications/presentation/pages/notifications_page.dart`
   + `lib/features/notifications/presentation/widgets/notification_card.dart`
3. `lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`
4. `lib/features/child_home/presentation/pages/child_home_page.dart`
5. `lib/features/my_page/presentation/pages/my_page.dart`

---

## Page: lib/features/my_page/presentation/pages/password_change_page.dart

### Finding 1 — `완료` CTA fires when supposed to be disabled  [CRITICAL]
1. **Observation:** lines 465–495 `_PasswordChangeButton` wraps `FilledButton`.
   At line 477 `onPressed: onPressed` is passed unconditionally. The `enabled`
   flag only controls colors (lines 480–489). Caller at line 241–244 passes
   `onPressed: _submit` regardless of `_canSubmit`.
2. **Root cause:** `enabled` is decorative, not gating. `_submit()` (line 128)
   does run the validation guard `if (!_canSubmit) return;`, so the bug is
   not catastrophic — BUT the button still consumes the tap, runs
   `FocusScope.unfocus()`, calls `setState`, and surfaces error states even
   when the user hasn't filled any fields. The button claims to be disabled
   (gray) but is hit-testable.
3. **User symptom:** User taps the gray "completed-look-disabled" 완료 button
   and gets keyboard dismiss + sudden red helper text on fields they have not
   touched. They report "버튼이 이상하게 동작한다."
4. **Fix recommendation:** Change `_PasswordChangeButton` to use `BridgeButton`
   (matches the rest of the app) and pass `onPressed: enabled ? onPressed : null`.
   This unifies disabled visual + disabled hit-test.

### Finding 2 — Standalone `FilledButton` violates Bridge widget convention
1. **Observation:** line 476 `FilledButton(` is the only Material-style button
   left in this page; the rest of the app uses `BridgeButton`.
2. **Root cause:** Page predates the Bridge button system.
3. **User symptom:** Slightly different splash/ripple/disabled palette vs other
   pages. Not a "doesn't work" complaint, but listed because previous audits
   asked these to be replaced.
4. **Fix recommendation:** Swap to `BridgeButton` (variant primary, size large).

---

## Page: lib/features/notifications/presentation/pages/notifications_page.dart

### Finding 3 — Notification card tap is a NO-OP  [CRITICAL — direct match for user complaint]
1. **Observation:** line 121 `onTap: () {},` passed to `NotificationCard`. The
   card visually shows `${item.actionLabel} →` (line 182 of `notification_card.dart`)
   which is clearly a tap-to-navigate affordance.
2. **Root cause:** Empty closure handler — likely placeholder waiting for the
   navigation/deep-link wiring that never landed.
3. **User symptom:** User taps a notification row, nothing happens. The arrow
   suggests it should navigate to the relevant mission/time-setup/report page,
   but no router push is wired.
4. **Fix recommendation:** Route based on `item.type` (e.g.
   `missionCompleted → /child-home/mission/:id`,
   `timeConfigured → /child-home/time-setup/confirm`).

---

## Page: lib/features/notifications/presentation/widgets/notification_card.dart

### Finding 4 — Nested GestureDetectors with no `behavior` on outer  [HIGH risk of swallowed taps]
1. **Observation:** lines 87–96 outer `GestureDetector` handles
   `onHorizontalDragUpdate/End/Cancel` but does NOT set `behavior:` and has no
   `onTap`. Lines 126–128 inner `GestureDetector` has
   `behavior: HitTestBehavior.opaque, onTap: widget.onTap`.
2. **Root cause:** While Flutter's gesture arena correctly routes pure taps to
   the inner detector when the outer only has drag callbacks, any cross-axis
   movement (a child accidentally swiping vertically while scrolling
   `ListView.separated`) can hand the gesture to the outer drag, which then
   ignores it. The outer detector consumes the gesture even though `onTap` was
   intended. Symptom-wise this looks like "tapped the row, nothing happened."
3. **User symptom:** Intermittent — most taps work, but if the user makes a
   tiny scroll motion while pressing, the tap is eaten by the drag detector
   and the card simply doesn't react.
4. **Fix recommendation:** Either (a) merge drag + tap into the outer detector,
   or (b) add `dragStartBehavior: DragStartBehavior.down` and a minimum drag
   threshold so accidental drags don't beat the inner tap. Combined with
   Finding 3 (the no-op tap handler), the user-facing impact is doubled.

### Finding 5 — `_DeleteRevealIcon` revealed under the card has no tap
1. **Observation:** lines 102–122 reveal a delete icon when the user drags
   the card left. The icon is rendered inside an `Opacity` widget that is NOT
   inside any detector. The reveal only completes the delete via the drag
   threshold (line 66).
2. **Root cause:** Visually the user thinks "tap the red × to delete" but only
   the drag action is wired.
3. **User symptom:** After revealing the × icon (mid-drag), the user releases
   and taps the icon directly — nothing happens until they drag past the 85%
   threshold.
4. **Fix recommendation:** Wrap `_DeleteRevealIcon` (or its full reveal pad)
   in a `GestureDetector(onTap: () => widget.onDeleteIntent(widget.item))`.

---

## Page: lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart

### Finding 6 — `자동계산` button is wired but its handler is empty  [CRITICAL — direct match for complaint]
1. **Observation:** line 72 `TextButton(onPressed: canProceed ? () => _handleAutoDistribute(controller) : null, ...)`.
   Line 163 `void _handleAutoDistribute(TimeSetupController controller) {}`.
2. **Root cause:** TODO at lines 160–162 admits the handler is intentionally
   empty pending Step-3 work. Button is fully enabled visually + hit-testable.
3. **User symptom:** User taps `자동계산`, gets the tap ripple, but nothing
   happens. The weekly totals do not auto-fill.
4. **Fix recommendation:** Either disable the button (`onPressed: null`) with
   a "coming soon" tooltip until Step-3 distribution lands, or implement the
   even-split logic now.

### Finding 7 — Use of Material `TextButton` instead of Bridge widget
1. **Observation:** line 72 `TextButton(`. Per recent Bridge widget audits this
   should be a `BridgePillIconButton` (ghost variant) or a `BridgeButton.textLink`.
2. **Root cause:** Pre-Bridge code.
3. **User symptom:** Slightly different splash/disabled palette; minor.
4. **Fix recommendation:** Replace with `BridgePillIconButton(label: '자동계산', variant: BridgePillVariant.ghost, onPressed: ...)`.

### Finding 8 — Past-week `BridgeWeekRow` is intentionally non-interactive but still looks tappable
1. **Observation:** lines 92–98 `BridgeWeekRow(... onTap: null, isPast: true)`.
   `BridgeWeekRow` (file `lib/core/widgets/layout/bridge_week_row.dart` lines
   97–108) wraps the card in `IgnorePointer(ignoring: onTap == null, ...)`.
2. **Root cause:** Read-only by design, but the visual is only differentiated
   by 0.2 opacity. Users may try to tap it because it sits in the same row stack
   as the four interactive `1주차…4주차` rows.
3. **User symptom:** User taps the dim "지난 주" row → no response, no toast,
   no visual feedback. They conclude "버튼이 안 먹는다."
4. **Fix recommendation:** Add a subtle "read-only" badge OR show a
   `SnackBar('지난 주 계획은 수정할 수 없어요')` via a wrapping `GestureDetector`
   so the user receives feedback.

---

## Page: lib/features/child_home/presentation/pages/child_home_page.dart

### Finding 9 — Two `IconButton` actions have hit area below WCAG minimum
1. **Observation:** lines 291–306 and 308–323. Both `IconButton`s have
   `padding: EdgeInsets.zero` and `constraints: BoxConstraints(minWidth: 22, minHeight: 22)`
   with `visualDensity: VisualDensity.compact`. Effective hit target = 22×22 px.
2. **Root cause:** Spec called for a 22 px visual icon but the hit target was
   not expanded. WCAG 2.1 AAA recommends ≥44×44, Material's default is 48×48.
   The two icons sit side-by-side with only 8 px gap (line 307) so users
   easily mis-tap one when intending the other.
3. **User symptom:** "I tapped the bar-chart icon and the settings page
   opened" (or vice-versa). Or "I tapped slightly off-icon and nothing
   happened."
4. **Fix recommendation:** Keep visual size 22, but expand the constraints
   to ≥44×44 with a transparent `Padding`/`SizedBox` and let `IconButton`
   center the smaller glyph inside.

### Finding 10 — Empty-state `+` button has marginal hit area (40×40)
1. **Observation:** lines 402–414 `GestureDetector` with a 40×40 circular
   container.
2. **Root cause:** Hit area is the visible bounds only; slightly below the
   44×44 floor. Behavior `HitTestBehavior.opaque` is correct.
3. **User symptom:** Edge taps on the circle miss.
4. **Fix recommendation:** Wrap in `SizedBox(width: 48, height: 48, child: Center(...))`
   so the gesture detector picks up nearby pixels.

### Finding 11 — Long-press card debug toggle silently shadows tap
1. **Observation:** lines 347–379. The empty-state card uses
   `GestureDetector(behavior: HitTestBehavior.opaque, onLongPress: onDebugToggleSchedule, child: ...)`.
   The inner `_ScheduleEmptyState` contains its own `GestureDetector` (line 402)
   for the + button.
2. **Root cause:** With `HitTestBehavior.opaque` on the outer detector, the
   outer wins the hit and the inner + button still works (Flutter delegates
   to children first for taps) BUT any taps on the empty area DO consume the
   touch — there's no feedback that nothing will happen. Long-press is a
   developer-only affordance left in production. Per the inline comment at
   lines 27–30 this is intentional, but it's a hit-area trap for non-debug
   users.
3. **User symptom:** User long-presses anywhere on the empty card hoping for
   a context menu / detail view and instead toggles the demo schedule on/off
   randomly.
4. **Fix recommendation:** Gate `onLongPress` behind a debug-build check
   (`kDebugMode`) so production builds don't expose it.

### Finding 12 — Standalone disabled `Icon(Icons.settings)` is a dead pixel
1. **Observation:** line 327 (and again at line 616) renders
   `Icon(Icons.settings, color: AppColors.gray300, size: 22)` with NO detector.
   It sits next to `오늘의 시간` and `미션 현황` headers respectively, where the
   active state of that slot IS an `IconButton`.
2. **Root cause:** Disabled-look icon with no gesture wiring. The active state
   has two interactive icons (Finding 9); the disabled state shows one
   non-interactive icon, but its size and color suggest "tap me when this is
   available."
3. **User symptom:** User taps the gray gear icon, nothing happens, no tooltip
   tells them why it's disabled.
4. **Fix recommendation:** Wrap in a `Tooltip(message: '시간 계획이 등록되면 사용할 수 있어요')`
   or wrap with an empty `Semantics(button: true, enabled: false, ...)`.

### Finding 13 — `사용 리포트` text in `!hasContent` branch is not interactive
1. **Observation:** lines 332–343. When `hasContent == false` a `Text('사용 리포트')`
   is rendered with no detector at all. In the `hasContent == true` branch (lines
   285–325) the same affordance lives as a bar-chart icon button. Visually the
   text looks like a tappable link (placed where the icon button would be).
2. **Root cause:** Empty-state placeholder text — not wired.
3. **User symptom:** Dead pixel — users tap the `사용 리포트` label expecting
   the same navigation as the active state.
4. **Fix recommendation:** Either gray it out heavily and add the `disabled`
   semantic, or wrap with the same `context.push('/child-home/report')` push.

---

## Page: lib/features/my_page/presentation/pages/my_page.dart

### Finding 14 — `_MyPageActionButton` (`로그아웃`) bypasses Bridge widget system
1. **Observation:** lines 153–189. The `로그아웃` button is a hand-rolled
   `GestureDetector + Container`. Functional, but Bridge has a `BridgeButton`
   variant + size that matches (medium, fullWidth=false).
2. **Root cause:** Pre-Bridge legacy. Confirmed by TODO at line 125
   ("로그아웃 visibility — Figma omits this. Confirm with design before shipping").
3. **User symptom:** None — works. Listed for spec compliance.
4. **Fix recommendation:** Either remove (per TODO) or replace with a
   `BridgeButton(variant: BridgeButtonVariant.outlined, size: BridgeButtonSize.medium, fullWidth: false)`.

### Finding 15 — Dialog buttons (`_DeleteDialogButton`) bypass `BridgeConfirmDialog`
1. **Observation:** lines 290–330. Hand-rolled `_DeleteDialogButton` used in
   the inline `_DeleteAccountDialog`. The project ships a
   `BridgeConfirmDialog` (file `lib/core/widgets/feedback/bridge_confirm_dialog.dart`)
   exactly for this case.
2. **Root cause:** Pre-Bridge dialog left in place.
3. **User symptom:** None functional — works. Different ripple palette vs
   `BridgeConfirmDialog`.
4. **Fix recommendation:** Replace `_showDeleteAccountDialog` body with
   `BridgeConfirmDialog.show(context, title: '탈퇴하시겠습니까?')`.

### Finding 16 — `_PasswordRow.수정하기` is a hand-rolled tap target
1. **Observation:** lines 387–406 `GestureDetector(...)+Container('수정하기')`.
   Equivalent affordances elsewhere use `BridgePillIconButton` or `BridgeButton`.
2. **Root cause:** Pre-Bridge legacy.
3. **User symptom:** Works. Spec violation only.
4. **Fix recommendation:** Replace with `BridgeButton(variant: outlined, size: medium, fullWidth: false)`.

---

## Page: lib/features/notifications/presentation/pages/notifications_page.dart (cont.)

### Finding 17 — Inline `_DeleteDialogButton` instead of `BridgeConfirmDialog`
1. **Observation:** lines 234–274 — same hand-rolled dialog button as
   `my_page.dart`.
2. **Root cause:** Same as Finding 15.
3. **User symptom:** None functional.
4. **Fix recommendation:** Use `BridgeConfirmDialog.show`.

---

## Page: lib/features/time_setup/presentation/pages/daily_time_setup_page.dart

### Finding 18 — `사용리포트 보기` + `스케줄 보기` ghost pills sit at extreme right edge
1. **Observation:** lines 80–98 `Row(mainAxisAlignment: end, children: [pill, gap(8), pill])`.
   Pills use `BridgePillVariant.ghost` (transparent surface). Hit area is the
   32-tall pill itself only — no extra padding around the row.
2. **Root cause:** Two transparent-surface pills aligned to the right with only
   8 px between them. Ghost pills have no visible boundary, so when users tap
   they may miss the 12 px horizontal padding zone.
3. **User symptom:** Tap registers on whitespace between or around the pills,
   nothing happens.
4. **Fix recommendation:** Either widen the pills' horizontal padding, or
   ensure a `tonal` variant on at least one so the boundary is visually clear.

---

## Page: lib/features/login/presentation/pages/login_page.dart

(No interactive bugs found. `BridgeButton` correctly null-gates `onPressed`
on `!_canSubmit`, hit-test is correct on all controls.)

---

## Page: lib/features/signup/presentation/pages/signup_page.dart

(No interactive bugs found. Same pattern as login.)

---

## Page: lib/features/home/presentation/pages/home_page.dart

(No interactive bugs found.)

---

## Page: lib/features/report/presentation/pages/report_page.dart

(No interactive bugs found. Single `BridgeButton` CTA with correct push.)

---

## Page: lib/features/mission/presentation/pages/mission_info_page.dart

### Finding 19 — Permanently-disabled `BridgeButton('제출')` in `_CameraPromptView`
1. **Observation:** lines 493–496 `const BridgeButton(label: '제출', onPressed: null)`.
   The comment (lines 489–492) says the controller auto-transitions on photo
   capture so this disabled state is effectively unreachable in normal flow.
2. **Root cause:** If `CameraService.capturePhoto()` resolves to `null` (user
   cancels picker), the user stays on this view with a permanently disabled
   `제출` button and no path forward besides "back."
3. **User symptom:** User opens camera, cancels, then taps `제출` — nothing
   happens because it's `null`-gated. They don't know they need to tap the
   camera CTA again.
4. **Fix recommendation:** Either auto-pop on cancel (return to mission info)
   or add a helper text below the disabled CTA: `사진을 먼저 촬영해주세요`.

---

## Page: lib/features/time_setup/presentation/pages/time_setup_intro_page.dart

(No interactive bugs found. Single CTA, correctly wired.)

---

## Page: lib/features/time_setup/presentation/pages/time_setup_review_page.dart

(No interactive bugs found. `BridgeButton` wired to `controller.submit`.)

---

## Page: lib/features/time_setup/presentation/pages/time_setup_complete_page.dart

(No interactive bugs found.)

---

## Page: lib/features/time_setup/presentation/pages/schedule_register_page.dart

(No interactive bugs found.)

---

## Page: lib/features/my_page/presentation/pages/delete_account_complete_page.dart

(No interactive elements — splash + timed redirect.)

---

## Page: lib/features/time_confirm/presentation/pages/time_confirm_page.dart

(No interactive bugs found. Pills + `BridgeButton`s all correctly wired.)

---

## Core widget findings

### Finding 20 — `BridgeAppBar` back button hit area only 24×24
1. **Observation:** `lib/core/widgets/layout/bridge_app_bar.dart` lines 92–125.
   `_BackButton` uses `InkResponse(radius: 20, containedInkWell: false)` around
   a 24×24 `SvgPicture.asset`. `InkResponse` radius extends the splash visually
   but `radius: 20` is below the 24×24 Material spec; effective hit area is
   still ~24×24 from the `SizedBox`.
2. **Root cause:** No surrounding `Padding` to expand the gesture area.
3. **User symptom:** Edge taps near the back chevron miss; users tap and stay
   on the page.
4. **Fix recommendation:** Wrap `_BackButton` in `Padding(EdgeInsets.all(12))`
   to bring the gesture area to ~48×48 while keeping the visual at 24.

### Finding 21 — Custom back buttons in pages with manual SVG (8×8 hit area)
1. **Observation:** `notifications_page.dart` lines 287–303 and
   `password_change_page.dart` lines 272–288 both render manual
   back buttons with `Positioned(width: 24, height: 24, ...)` + 2-px padding
   instead of using `BridgeAppBar`.
2. **Root cause:** Pre-Bridge top bars.
3. **User symptom:** Same as Finding 20 — small hit area + edge taps miss.
4. **Fix recommendation:** Replace these custom top bars with `BridgeAppBar`
   (notifications already imports it elsewhere; password_change does not).

---

## Cross-cutting patterns observed

1. **No-op `() {}` handlers** appear at notifications_page.dart:121 and
   `_handleAutoDistribute` at weekly_time_setup_page.dart:163. Both are the
   classic "looks like a button, does nothing" pattern that maps directly to
   the user's complaint.
2. **Hand-rolled buttons co-exist with Bridge widgets** in mypage,
   notifications and password_change. Even where they work, they break
   keyboard/semantics consistency and bypass the Bridge disabled-state pattern.
3. **22-pt and 24-pt hit targets** in child_home top-right action cluster
   and all `BridgeAppBar` back buttons are below Apple's 44×44 and Material's
   48×48 guidance. This is the most likely root cause of "many buttons don't
   work" for child users (ages 9–14 typically have larger thumb contact areas
   and lower fine-motor precision).
4. **`IgnorePointer(ignoring: onTap == null)`** in `BridgeWeekRow` and
   `BridgeDayRow` correctly disables hit-testing when no handler, but the
   visual disabled state (0.2 opacity) doesn't match the strong disabled
   palette of `BridgeButton`. Users still try.
5. **No global hit-area expansion** — none of the pages wrap small icons in
   a min-44 transparent extender. This is a project-wide quality risk.

---

## Recommended fix priority

1. (P0) Wire notifications card `onTap` (Finding 3) and `_DeleteRevealIcon`
   (Finding 5). These map directly to "button doesn't work."
2. (P0) Implement or null-disable `자동계산` (Finding 6).
3. (P0) Fix `_PasswordChangeButton` enabled-vs-onPressed mismatch (Finding 1).
4. (P1) Expand hit areas on `child_home` action cluster, `BridgeAppBar` back
   button, custom back buttons (Findings 9, 10, 20, 21).
5. (P1) Replace hand-rolled dialog buttons + `_MyPageActionButton` +
   `_PasswordRow` 수정하기 with Bridge equivalents (Findings 14, 15, 16, 17).
6. (P2) Wrap nested gesture detectors in NotificationCard with proper
   `dragStartBehavior` + threshold (Finding 4).
7. (P2) Address dead-pixel `Icon(Icons.settings)` and `Text('사용 리포트')` in
   `_TodayTimeSection` / `_MissionSection` (Findings 12, 13).
8. (P2) Provide read-only feedback on past-week `BridgeWeekRow` (Finding 8).
