# Phase 6 Mission Flow — Figma Audit

**Scope**: `lib/features/mission/presentation/pages/mission_info_page.dart`
**Spec**: `docs/figma-specs/11-mission.md`
**Figma nodes**: 746-11392, 746-11380, 426-18960, 426-19035, 426-18995, 426-18974, 426-19052, 426-19062
**Date**: 2026-05-18
**Auditor**: Quality Engineer (Phase 6 verification, no fixes applied)

---

## Summary

| Result | Count |
|--------|-------|
| PASS   | 9 |
| FAIL   | 7 |
| WARN   | 4 |

Overall: **PARTIAL PASS**. The four sub-views (`_InfoView`, `_PerformView`, `_PhotoPreviewView`, `_SubmittedView`) are correctly branched off `MissionFlowStep` and the submitted state correctly forks on `MissionStatus` (reviewing / completed / rejected). Token discipline is excellent — zero stray hex literals across the mission feature. Three medium-severity Figma deltas remain, all visual.

---

## Check matrix

| # | Check | State | Notes |
|---|-------|-------|-------|
| 1 | Step routing via `MissionFlowStep` | PASS | Switch at line 56 maps all 4 steps correctly |
| 2 | `_InfoView` layout (`746-11392`) | FAIL | Spec requires tabs (`미션정보` / `수행정보`) + 5 settings sections (카테고리/리셋주기/확인방식/지급시간/상세설명). Current implementation collapses these into header + reward chip + free-form description. Major content gap. |
| 3 | Title typography (`heading1Bold`, 24 SemiBold) | PASS | Matches spec line 14 |
| 4 | "Assigned by" chip | WARN | Not in Figma spec for `746-11392` — extra UI element. Could be intentional for child-side context, but not specified. |
| 5 | `_RewardChip` split-color number/unit | PASS | Numbers in `AppColors.primary` (`#3A99F8`), units in `AppColors.textPrimary` — matches §"Colors" line 38 + §"Reward display summary" |
| 6 | `_RewardChip` pad-left format (`00 시간`) | PASS | `padLeft(2, '0')` matches `00 시간 / 30 분` spec line 30 |
| 7 | `_PerformView` layout (`746-11380`) | FAIL | Spec is **empty state**: centered `미션이 아직 수행되지 않았어요.` copy + sticky `수행하기` CTA. Current view jumps straight to camera CTA (mixing `746-11380` and `426-18960` concerns), eliminating the perform-empty state. |
| 8 | `_PerformView` should navigate, not embed camera | FAIL | Per state matrix (spec line 226), `746-11380` `수행하기` should route to `426-18960` camera-prompt screen. Currently `_PerformView` IS the camera prompt. |
| 9 | Camera CTA dashed border | **FAIL** | Spec line 83 + line 297: `dashed 2px #91969E`. Implementation uses **solid** `Border.all(color: AppColors.gray400, width: 2)` (line 314). The `dotted_border` package IS already in use by `BridgePhotoTile` — should be reused here. |
| 10 | Camera CTA background | PASS | `AppColors.surfaceMuted` = `#F5F7FA` matches spec |
| 11 | Camera CTA label `사진을 업로드해주세요` | PASS | Verbatim match |
| 12 | Camera CTA height | WARN | Hardcoded 200; spec says `h≈156 (padded 52V/83H)` (line 83). 28% taller than spec. |
| 13 | Submit button disabled when `photos.isEmpty` | PASS | `_PerformView` Submit `onPressed: null`; `_PhotoPreviewView` uses `controller.canSubmit ? submit : null` |
| 14 | Photo grid 2-col Wrap with gap=12 | PASS | `Wrap(spacing: 12, runSpacing: 12)` matches `AppTokens.photoGap = 12`. Tile width 157px × 2 + 12 gap + 24×2 horizontal padding = 374 ≈ 375 frame width. |
| 15 | Add-photo tile hides at max=4 | PASS | `if (!controller.hasMaxPhotos)` correctly omits add tile |
| 16 | Per-photo delete handle | PASS | `BridgePhotoTile` renders top-right 24px circular × overlay |
| 17 | Hint copy `최대 4장까지 올릴 수 있어요` | PASS | Verbatim match (line 407) |
| 18 | `_SubmittedView` branches reviewing/completed/rejected | PASS | Lines 446-462 correctly fork icon/title/subtitle |
| 19 | Reviewing icon color | WARN | Spec `426-19052` (line 187) shows **primary blue** circle with white check even in reviewing state — current impl uses `gray400` + hourglass. Design intent unclear (annotation: AI/parent confirm); deviation may be intentional but flag for design review. |
| 20 | Rejected state visual | WARN | Spec explicitly notes no Figma node for rejected (line 232, 286). Current `destructive` red × with `미션 반려` is a reasonable invented variant; no validation possible. |
| 21 | Completed reward subtitle (`...의 보너스 시간이 지급되었어요!`) | PASS | Matches `426-19062` spec line 206 |
| 22 | Bottom CTA `홈으로` routes to `/child-home` | PASS | Matches assumption in spec line 195 |
| 23 | No stray hex literals in mission feature | PASS | Grep `0xFF\|Color(0x` in `lib/features/mission/`: 0 hits. Token discipline clean. |
| 24 | Use of `Colors.white` | WARN | Line 484 uses `Colors.white` for the check/× icon. Minor — should be `AppColors.white` for consistency with token catalog. |
| 25 | `BridgeAppBar` on submitted state | FAIL | `_SubmittedView` has no app bar; spec line 182 requires topbar `미션수행` on `426-19052` and `426-19062`. Hidden topbar breaks navigation affordance. |
| 26 | Tabs (`미션정보` / `수행정보`) component | FAIL | Spec lines 14-15 + 56-57 require a 2-tab toggle with 1.4px black underline. Not implemented anywhere. Listed as new component `BridgeMainTabs` in spec line 271. |
| 27 | Info screen section divider `#F5F7FA` | FAIL | Spec line 16 calls for 7h × 374w divider bars between sections. Not implemented (no sections to divide because section content is missing). |

---

## Recommendations by tier

### Tier 1 — Critical (visual fidelity blocker)

1. **Replace solid border with dashed in `_CameraCTA`** (lines 309-315).
   The `dotted_border` package is already a project dependency (`bridge_photo_tile.dart:3`). Match `BridgeAddPhotoTile` exactly:
   ```dart
   DottedBorder(
     color: AppColors.gray400,
     strokeWidth: 2,
     dashPattern: const [6, 4],
     borderType: BorderType.RRect,
     radius: Radius.circular(AppTokens.buttonRadius),
     child: ...
   )
   ```
   Aligns with spec line 83 and the existing add-photo tile pattern (DRY).

2. **Restore `_InfoView` settings sections** (`746-11392`).
   Implement the five labeled sections (카테고리/리셋주기/확인방식/지급시간/상세설명) with read-only chip rows. Either extend `Mission` model to carry these fields or back with mock data. Current view is missing roughly 60% of the spec's required content.

3. **Split `_PerformView` into perform-empty (`746-11380`) and camera-prompt (`426-18960`)**.
   `746-11380` is an empty-state screen with centered copy `미션이 아직 수행되지 않았어요.` and a sticky `수행하기` CTA that navigates to the camera prompt. Add a new `MissionFlowStep.cameraPrompt` (or rename `perform → cameraPrompt`) and a true empty-state view before it.

### Tier 2 — Important (medium-severity)

4. **Add `BridgeAppBar` to `_SubmittedView`** with title `미션수행`. Without a topbar the user has no back affordance other than the `홈으로` CTA.

5. **Implement `BridgeMainTabs`** (spec line 271). 2-tab toggle with 1.4px black underline, 16 SemiBold active / Medium `#91969E` inactive. Required by both `746-11392` and `746-11380`.

6. **Reconcile `_SubmittedView` reviewing icon** with `426-19052`. Spec shows primary-blue circle + white check for both reviewing and completed states. If design intends a differentiated reviewing visual (hourglass on gray), update the spec; otherwise update the code.

7. **Reduce `_CameraCTA` height from 200 → ~156** to match spec padding 52V/83H, or document the deliberate uplift.

### Tier 3 — Polish

8. Swap `Colors.white` → `AppColors.white` on line 484 for token consistency.

9. Decide on the "assigned by" chip (`_AssignedByChip`). It is not in the Figma spec for `746-11392`. Either remove or document as a child-side enhancement in spec §"Open questions".

10. Confirm `_SubmittedView` rejected branch with design — no Figma exists; current invention may need formalization (parent reject reason? retry CTA?).

11. Consider extracting `_RewardChip` to `BridgeTimeChip` (spec line 265) so the info-screen `지급시간` row and any future surfaces can reuse it.

---

## Risk assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Camera CTA dashed-vs-solid visual regression | High (visible in QA) | Low (cosmetic) | Tier 1 #1 |
| Missing info-tab content fails acceptance | Certain | High (incomplete feature) | Tier 1 #2 |
| Combined perform/camera screens confuse users with no perform empty state | Medium | Medium (UX) | Tier 1 #3 |
| Missing topbar on submitted leaves user stranded if `홈으로` fails to route | Low | Medium (navigation) | Tier 2 #4 |
| Rejected screen design drift if backend ever surfaces rejection | Medium | Low (rare path) | Tier 3 #10 |

---

## Files inspected

- `lib/features/mission/presentation/pages/mission_info_page.dart` (520 lines)
- `lib/features/mission/state/mission_controller.dart`
- `lib/features/mission/data/models/mission.dart`
- `lib/core/widgets/inputs/bridge_photo_tile.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_tokens.dart`
- `lib/core/theme/app_typography.dart`
- `docs/figma-specs/11-mission.md`
