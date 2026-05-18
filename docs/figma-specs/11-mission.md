# 미션 정보/수행 (Mission Detail & Perform)

Specs for 8 Figma nodes covering the full mission lifecycle (information view → perform → camera/photo upload → submitted → reviewing → completed). File key: `tzJjQmXtXO7vGlfCT9SASu`.

Existing tokens in use: primary `#3A99F8`, gray-050 `#FAFBFC`, gray-100 `#F5F7FA`, gray-200 `#D5D8DE`, gray-300 `#A7ACB2`, gray-400 `#91969E`, gray-500/600 `#5F6165`, gray-700 `#47484B`, gray-800 `#2F3032`, gray-900 `#171818`. Pretendard 24/18/16/14 in B(SemiBold 600)/M(Medium 500)/R(Regular 400). pageHorizontal=24.

---

## 미션 - 정보 탭 / Mission Info (`746-11392`)

Read-only summary of mission settings — child's view of the rules a parent created. Uses a tab pair (`미션정보` / `수행정보`).

**Layout** (top → bottom)
1. Status bar (44h) + Topbar (52h) — back arrow left, title `방청소하기` center, Pretendard 18 Medium #050505.
2. Tabs row (`미션정보` active w/ 1.4px black underline, `수행정보` inactive #91969E). 190w container, 6px V padding.
3. Container starts at y=182, w=327, centered, vertical gap=24 between sections, divider = `#F5F7FA` 7h × 374w bar.
4. **카테고리** section — label (18 SemiBold #2F3032) + horizontal chip row, gap 8.
5. **리셋주기** section — same pattern.
6. **확인방식** section — same pattern.
7. **지급시간** section — row with label + readonly time chip (right).
8. **상세설명** section — label + read-only textarea field.

**Texts** (verbatim)
- Title: `방청소하기`
- Section labels: `카테고리`, `리셋주기`, `확인방식`, `지급시간`, `상세설명`
- Category chips: `루틴` (selected), `학습`, `운동`, `청소`, `심부름`
- Reset chips: `매일` (selected), `일주일`, `한 달`
- Confirm method chips: `AI 자동확인`, `자녀 확인` (selected), `부모 확인`
- Time chip: `00 시간`, `30 분` (numbers in primary, units in #050505)
- Description: `방청소하고 깨끗하진 방 사진 찍기` (sic — typo in source design)

**Colors**
- Chip selected: bg `#3A99F8` + text white (SemiBold 16)
- Chip unselected: bg `#F5F7FA`, border `#D5D8DE`, text `#5F6165` or `#2F3032` (Medium 16)
- Section divider: `#F5F7FA`
- Time field: bg `#FAFBFC`, border `#D5D8DE`, radius 8
- Description textarea: bg `#FAFBFC`, border `#D5D8DE`, radius 12, padding 12V/14H
- Numbers in time chip: `#3A99F8`

**Typography**
- Section label: Pretendard 18 SemiBold, line-height 1.445, tracking -0.36%
- Chip text: Pretendard 16 (SemiBold for active / Medium for inactive)
- Number in time chip: Pretendard 18 SemiBold
- Description text: Pretendard 16 Regular

**Chip specs** — h=52, radius=12, padding 16V/10–12H. Widths vary by section: category=58, reset=74, confirm=100.

**State variant**: `info` (read-only). All controls visually exist but should be non-interactive on child side.

---

## 미션 - 수행정보 탭 / Mission Perform Empty (`746-11380`)

The `수행정보` tab default state when the child has not yet started.

**Layout**
1. Status bar + topbar (`방청소하기`).
2. Tabs row — `수행정보` active.
3. Empty-state copy centered at y≈393.
4. Sticky bottom CTA `수행하기` (perform now).

**Texts**
- Empty state: `미션이 아직 수행되지 않았어요.` — Pretendard 18 Medium, color `#A7ACB2`, center.
- Bottom button: `수행하기` — Pretendard 18 Medium white.

**Colors** — page bg `#F5F7FA`. Primary button `#3A99F8`, radius 8, h=54.

**State variant**: `perform-entry` / empty performance log.

**Interactions**: Bottom `수행하기` button → navigate to camera prompt screen (`426-18960`).

---

## 미션 - 카메라 프롬프트 / Photo Upload Prompt — pre-camera (`426-18960`)

The first screen of mission execution. Single empty dashed upload area; submit is **disabled**.

**Layout**
1. Status bar + topbar (`미션수행`).
2. Card container (centered, w=212, y=120, gap=16):
   - Title 24 SemiBold `방청소 하기`
   - Subtitle 16 Medium `깨끗해진 방을 찍어서 올려주세요!`
3. **Dashed upload area** at y=304, full-width (x=24, w=327), h≈156 (padded 52V/83H). bg `#F5F7FA`, dashed 2px border `#91969E`, radius 8.
   - Inner column gap=16: camera icon (24) + label `사진을 업로드해주세요` (18 Medium `#47484B`).
4. Hint copy at y=658 center: `최대 4장까지 올릴 수 있어요` (14 Medium `#5F6165`).
5. Bottom CTA `제출` — **disabled state**: bg `#D5D8DE`, text `#A7ACB2`, h=54, radius 8.

**Photo upload UI**
- Pre-camera state = dashed bordered drop zone with camera-glyph icon (node `55:2062` named `공유`, but visually it's a small share/upload icon — treat as camera icon per annotation).
- **CRITICAL ANNOTATION** on `426:18967`:
  > 클릭시 카메라 앱으로 이동
  > (인터넷에서 사진을 다운로드 받아 이용하는 것을 방지하기 위해 사진 앱으로는 연결되지 않음)
  - Translation: tap launches **camera app**, NOT gallery — explicitly to prevent kids using downloaded internet pictures.

**Texts**
- Title: `방청소 하기`
- Subtitle: `깨끗해진 방을 찍어서 올려주세요!`
- Upload CTA: `사진을 업로드해주세요`
- Hint: `최대 4장까지 올릴 수 있어요`
- Button: `제출`

**Colors / Typography**
- Page bg `#FAFBFC`
- Title: Pretendard 24 SemiBold, `#050505`, line 1.364, tracking -1.94
- Subtitle: Pretendard 16 Medium, `#5F6165`
- Upload label: Pretendard 18 Medium, `#47484B`
- Hint: Pretendard 14 Medium, `#5F6165`
- Disabled button text: Pretendard 18 Medium, `#A7ACB2`

**State variant**: `camera-prompt` (0 photos uploaded). Submit disabled.

**Interactions**
- Tap upload area → open native camera (NOT gallery picker). Use `image_picker` with `ImageSource.camera` only.
- Submit → disabled until ≥1 photo present.

---

## 미션 - 사진 1장 업로드 / One Photo Uploaded (`426-19035`)

Same screen, after 1 photo captured.

**Layout** changes vs `426-18960`:
- Image grid container starts at y=250 (raised because we now show photos), x=24, w=327. Uses `flex-wrap` with gap=12.
- Slot 1 = filled photo: `158×156`, bg `#D5D8DE` (placeholder gray; actual app uses Image), radius 8, with close (×) icon top-right (20px). Padding 8.
- Slot 2 = "add more" dashed drop zone, `157×156`, same dashed style as the empty prompt but smaller. Label: `추가 업로드` (18 Medium `#47484B`).
- Hint and submit at y=658 — submit is **enabled** `#3A99F8` w/ white text.

**Photo preview UX**
- Each photo tile: rounded 8 corners, light gray placeholder bg until image loads, X-button overlay top-right (close glyph 20px on gray-200 bg) for delete.
- Adjacent "+ add more" tile remains as long as count < 4.

**Texts**
- Title/subtitle: same as above.
- Add-more label: `추가 업로드`
- Hint: `최대 4장까지 올릴 수 있어요`
- Button: `제출` (enabled)

**State variant**: `photo-preview` (1 photo, can submit, can add more).

**Interactions**
- Tap × on a photo → remove that photo.
- Tap `추가 업로드` → camera (NOT gallery).
- Tap `제출` → goes to `submitted` (`426-19052` or `426-19062` depending on confirmation method).

---

## 미션 - 사진 3장 업로드 / Three Photos Uploaded (`426-18995`)

Same as above with 3 filled tiles + 1 add-more tile, forming a 2-row grid.

**Layout**
- Image container x=24, y=250, w=327, gap=12 (`flex-wrap`).
- Row 1: photo, photo (each 158×156 / 157×156, radius 8)
- Row 2: photo, `추가 업로드` dashed tile
- Hint y=658 / submit enabled.

**State variant**: `photo-preview` (3 of 4, can still add 1 more).

---

## 미션 - 사진 4장 (만석) / Four Photos Uploaded — full (`426-18974`)

Maximum photos reached; no more add-tile.

**Layout**
- Image grid: explicit 2×2 grid (`grid-cols-2`, gap=12), each tile 157×156, all photo holders (no dashed add-more tile because max reached).
- Each tile has × delete glyph top-right.
- Hint + enabled submit.

**State variant**: `photo-preview` (4 of 4 = max).

**Interactions**
- No new-upload affordance shown.
- Deleting any photo reveals the dashed add-more tile again.

---

## 미션 - 업로드 완료 (검토 대기) / Submitted / Reviewing (`426-19052`)

Post-submission screen shown when confirmation method is AI or 부모확인 (parent approval). Annotation: `AI / 부모 확인인 경우`.

**Layout** — page bg `#FAFBFC`. Status bar + topbar `미션수행`.
- Centered container at y≈213, w=212, vertical gap=40 between text block and icon.
- Text block (gap=16):
  - Title: `업로드 완료!` — Pretendard 24 SemiBold `#050505`, line 1.364.
  - Subtitle: `확인까지 조금만 기다려주세요` — Pretendard 16 Medium `#5F6165`.
- **Completion icon** (60×60): primary blue circle `#3A99F8` (`Ellipse40`) with white check `Vector81` centered (~33% inset).
- Bottom CTA: primary `#3A99F8` h=54 radius 8 — **no label** in design (will likely show `홈으로` per the Button default).

**Reward display** — none on this screen (reward only shown on final completion).

**State variant**: `reviewing` (uploaded, pending parent/AI approval).

**Interactions**
- Bottom CTA → home (assumption: `홈으로` since Button default prop is `홈으로`).

---

## 미션 - 수행 완료 (보상 지급) / Approved / Completed (`426-19062`)

Final completed state — reward time has been credited. Annotation: `자녀 직접 확인인경우 바로 시간지급` (when set to self-confirm, time is paid immediately).

**Layout** — identical container/icon geometry to `426-19052`.
- Text block (gap=16):
  - Title: `미션 수행 완료!` — Pretendard 24 SemiBold `#050505`.
  - Subtitle: `1시간 30분의 보너스 시간이 지급되었어요!` — Pretendard 16 Medium `#5F6165`.
- Completion icon: same primary-blue circle + white check (60×60).
- Bottom CTA: same primary button.

**Reward display** — embedded inline in subtitle text (`1시간 30분의 보너스 시간이 지급되었어요!`). NO separate badge / icon / colored chip in this Figma. The hours value is **not** styled differently from surrounding copy. (Token list mentions `secondary: #FFCC33` but it's unused on this screen — likely reserved for future reward badge.)

**State variant**: `approved` / `completed-with-reward`.

**Interactions**
- Bottom CTA → home.

---

## State variant matrix

| Node | Variant | Submit | Trigger |
|------|---------|--------|---------|
| 746-11392 | `info` | N/A | Tab `미션정보` (read-only) |
| 746-11380 | `perform-empty` | `수행하기` CTA | Tab `수행정보`, no execution |
| 426-18960 | `camera-prompt` | disabled | After tap `수행하기`, 0 photos |
| 426-19035 | `photo-preview` (1/4) | enabled | 1 photo captured |
| 426-18995 | `photo-preview` (3/4) | enabled | 3 photos |
| 426-18974 | `photo-preview` (4/4 max) | enabled | 4 photos, no more upload tile |
| 426-19052 | `reviewing` | "홈으로" | After 제출 with AI/parent confirm |
| 426-19062 | `approved` | "홈으로" | After approval (or instant if self-confirm) |

**No explicit `rejected` screen was provided in this batch.** The `_MissionCard` in `child_home_page.dart` includes `rejected` status for the home list view but no full-screen rejection flow is in these nodes. Need follow-up nodes if rejection deep-dive UI exists.

---

## Reward display summary

| Surface | Treatment |
|---------|-----------|
| Mission info screen (`지급시간`) | Numbers in primary `#3A99F8` SemiBold, units in `#050505` Medium, inside a `#FAFBFC` outlined chip |
| Completed screen | Plain inline text in subtitle (`1시간 30분`) — no badge / icon / chip |

**No dedicated `BridgeRewardBadge` visual present** in these 8 nodes. The "1시간 지급" pattern is rendered as either (a) a `00 시간 / 30 분` split-number chip on the info screen, or (b) plain text inside a sentence on the completion screen.

---

## Photo upload UX rules (Critical)

1. **Camera ONLY, NOT gallery.** Per Figma annotation on node `426:18967`:
   > 인터넷에서 사진을 다운로드 받아 이용하는 것을 방지하기 위해 사진 앱으로는 연결되지 않음
   Implement with `ImagePicker().pickImage(source: ImageSource.camera)` (or `pickMultiImage` substitute looped). Do NOT expose `ImageSource.gallery`.
2. **Use system camera app** (not an in-app custom camera view). The Figma shows tap → external camera launch and return with the captured image. No custom camera preview UI exists in these nodes. Simpler to maintain and gives parents/kids native UX.
3. **Max 4 photos.** Hard cap; UI hides "add more" tile once `photos.length == 4`.
4. **Per-photo delete (X)** is always available on captured tiles (top-right 20px close glyph on `#D5D8DE` gray placeholder bg).
5. **Submit gating**: disabled (`#D5D8DE`/`#A7ACB2`) when `photos.isEmpty`, primary (`#3A99F8`/white) otherwise.

---

## Reusable components

| Component | Maps to nodes | Notes |
|-----------|---------------|-------|
| `BridgeMissionDetailCard` | 746-11392 sections | Read-only label + chip-row pattern. Reuse same chip widget for category/reset/confirm. |
| `BridgeTimeChip` (NEW) | 746-11392 `지급시간` | Outlined chip w/ split-color number+unit. Width hugs content. |
| `BridgeMissionHeader` | 426-18960/19035/18995/18974 | Centered 24 SemiBold title + 16 Medium subtitle, w=212, gap=16. |
| `BridgeCameraCTA` (NEW) | 426-18960 (large), 426-19035/18995 (small "추가 업로드") | Dashed border 2px `#91969E` on `#F5F7FA`, radius 8, icon+label center. Two size variants (large full-width, small 157×156 tile). |
| `BridgePhotoTile` (NEW) | 426-19035/18995/18974 | 157×156, radius 8, bg `#D5D8DE` placeholder, child `Image`, top-right delete `BridgeCloseIcon`. |
| `BridgePhotoGrid` (NEW) | 426-19035/18995/18974 | Wrap or 2×2 grid with gap 12; appends `BridgeCameraCTA.small` if count<4. |
| `BridgeCompletionPanel` (NEW) | 426-19052, 426-19062 | Centered title+subtitle+circle-check icon at fixed offset; props: `title`, `subtitle`, `iconColor` (default primary). |
| `BridgePrimaryButton` (existing) | All screens | h=54, radius 8, primary/disabled variants already exist. |
| `BridgeMainTabs` (NEW) | 746-11392, 746-11380 | Two-tab toggle w/ 1.4px underline; 16 SemiBold active vs Medium #91969E inactive. |
| Status badges | `_MissionCard` on home only | Not present on these full-screen nodes. |

---

## Alignment with existing `_MissionCard` (`child_home_page.dart`)

Home dashboard uses `_MissionStatus { pendingCheck, rejected, reviewing, completed }` rendered as a circular icon (`_CircleStatusIcon` / `_ReviewingStatusIcon`). The 8 full-screen Figma nodes map as follows:

| `_MissionStatus` (home card) | Full-screen flow | Notes |
|------------------------------|------------------|-------|
| `pendingCheck` | tap → `746-11380` (perform tab empty) → `426-18960` (camera prompt) | Child has not yet executed; full-screen guides them to capture and submit. |
| `reviewing` | tap → `426-19052` (`업로드 완료!`) | "확인까지 조금만 기다려주세요" matches the reviewing semantics. |
| `completed` | tap → `426-19062` (`미션 수행 완료!`) | Reward credit message. |
| `rejected` | **no full-screen Figma in this batch** | Home card shows red rejected icon, but no detail/redo screen yet. Need follow-up. |

Naming alignment: home uses `pendingCheck` / `reviewing` / `completed` / `rejected`. Suggest matching the perform-flow controller's enum to those exact names (`MissionStatus.pendingCheck → CameraPromptPage`, `MissionStatus.reviewing → SubmittedPage`, `MissionStatus.completed → ApprovedPage`). Avoid introducing parallel naming like `submitted` to keep one source of truth.

---

## New tokens needed

- `secondary` `#FFCC33` — appears in Figma styles list for completion screens but is **not actually rendered** there. Likely reserved for a future reward badge. Add to palette but do not use unless a future spec requires it.
- All other colors fit existing gray/primary scale. No new color tokens are strictly required by these 8 nodes.
- New spacing: photo-grid gap = 12 (slightly tighter than the existing `itemGap=16`). Suggest `photoGap = 12`.
- New radius: photo tile / upload tile = 8 (existing buttons already use 8; no new token needed).
- New border: dashed 2px `#91969E` for upload zones. Implement via `DottedBorder` package or custom painter.

---

## Open questions / follow-ups

1. **Rejected full-screen flow** is missing from this batch. Home card has `rejected` status but no detail screen — need a Figma node for child-facing rejection (parent comment? retry CTA?).
2. **Reward badge styling** — info screen shows time as a chip; completion screen shows it as inline text. Confirm with design whether a dedicated `BridgeRewardBadge` (e.g. with `secondary #FFCC33`) is planned.
3. **Bottom CTA label on `426-19052` / `426-19062`** is empty in the Figma export (Button rendered without `propValue`). Default prop is `홈으로`; confirm with design.
4. **Camera implementation** — Figma annotation is unambiguous: camera only, no gallery. Verify Android/iOS image_picker config matches (no `pickImage(ImageSource.gallery)` calls anywhere in mission flow).
