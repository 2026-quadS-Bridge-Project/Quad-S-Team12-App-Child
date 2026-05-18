# Bridge_K 자녀앱 — Figma 추출 카탈로그 (전수조사 결과)

> 작성일: 2026-05-18
> 출처: Figma MCP 로 추출한 [01-인트로 + 02~11 spec 파일들](.)
> 총 52개 노드 (인트로 1 + 추출 13 spec 그룹, 51 노드)

---

## 1. 검증된 신규 디자인 토큰 (Phase 0 추가 대상)

### 1.1 색상 (cross-screen 검증 끝난 것만)

| 토큰명 (제안) | Hex | 검증 횟수 | 사용처 |
|---|---|---|---|
| `textPrimary` (또는 `inkBlack`) | `#050505` | **6** | mypage, pw-change ×2, child-home, report, confirm, time-v1 |
| `gray150` | `#EDEEF1` | **4** | mypage, child-home, confirm, time-v1 (구분 띠/링 베이스) |
| `primaryLight` (`primary050`) | `#EBF5FE` | **6** | child-home, delete-dialog, noti, report, daily, entry — Button/Blue/Light bg, info chip |
| `primarySubtle` (`primary100`) | `#C2DFFD` | **3** | report, daily 휠 active, entry stepper — Button/Blue/Light :active |
| `destructiveSubtle` (`destructive100`) | `#FFD3D3` | **4** | mypage 탈퇴 chip, noti 삭제 reveal, time-v1 error banner, time-v2 over-budget |
| `scrim` (rgba 68,68,68,0.6) | `0x99444444` | **3** | delete dialog, noti dialog, time-v1 bottom sheet |
| `bonusAmber` | `#FFBF00` | 1 (child-home only) | 보너스시간 도넛 + 라벨 |
| `destructiveBorderSoft` | `#FF7878` | 1 (time-v2) | error 프레임 1.2px 보더 |
| `primarySoft` (`primary025`) | `#E1F0FE` | 2 (report, time-v2) | speech bubble bg, info-tonal chip |

### 1.2 선언만 되어있고 미사용 (스타일 라이브러리에 존재)
- `#006FFD` — `Highlight/Darkest` (child-home + daily에서 declared but unused)
- `#FFCC33` — `secondary` (mission 완료 screen 등록만, 실 사용 X)
- `#655B96` — `lineStyle1` (report 변수만)

→ 토큰에 미리 추가만 해두고, 실제 사용 화면 나올 때 활성화.

### 1.3 타이포그래피 신규
| 토큰명 | Pretendard / 크기 / 행간 / 자간 | 사용처 |
|---|---|---|
| `heading2Medium` | Medium 20 / 1.4 / -1.2 | 휠 피커 단위 ("시간"/"분"), v2 step header |
| 기존 `bodyBold` 자간 보정 | 16 / 1.5 / **0.0912** | delete 완료 메시지 (현 코드 0.57 mismatch) |
| 기존 `captionMedium` 자간 보정 | 12 / 1.334 / **0.3024** | pw-change helper text 일치 |

### 1.4 측정값
| 값 | 용도 |
|---|---|
| `cardRadius` 16 (기존 28과 별개) | 일별 행, 미션 카드, 알림 카드, 데일리플랜 카드 |
| `dialogRadius` 12 | 탈퇴 / 알림 confirm 다이얼로그 |
| `buttonRadius` 8 | 대부분의 CTA (현 16 mismatch) |
| `bottomSheetTopRadius` 24 | 시간 바텀시트 |
| `bottomSheetHeight` 397 (49% of 812) | 시간 바텀시트 (드래그 핸들 Figma 미포함 → 구현시 추가) |
| `photoGap` 12 (기존 itemGap 16 별개) | 미션 사진 그리드 |

---

## 2. 재사용 컴포넌트 카탈로그 (총 25+, Phase 1 대상)

### 2.1 Atoms
- `BridgeButton` (variants: primary / outlined / destructive / textLink) — 거의 모든 화면. **destructive button 은 surfaceSoft bg + destructive text** (red bg 아님)
- `BridgeTextField` (variants: default / focused / error / withClear / withCheck) — login/signup/pw-change
- `BridgeAppBar` (`CmpTopBar`) — 모든 sub-page (mypage, pw-change, 미션, 시간설정 등에서 공통)
- `BridgeWheelPicker` (단일 휠) — 시간 바텀시트
- `BridgeStepCircle` (28×28 numbered badge) — 시간 v1/v2 step header
- `BridgeChip` (variants: weekday on/off, day-tag) — weekly/daily 시간 설정

### 2.2 Molecules
- `BridgeStepperPills` (3 pills 55×7, primary100 active) — 시간 v1/v2 진행 표시
- `BridgeStepHeader` (circle + title + description) — 시간 v1/v2
- `BridgeInfoRow` (label-divider-value) — mypage
- `BridgeWeekRow` (요일라벨 + divider + 시간/분 + 우측 pencil) — daily 분배 + v2
- `BridgeTotalTimeCard` (`60 시간 30 분` 인라인 디스플레이) — weekly 총시간
- `BridgeWeekdaySelector` (7 chip horizontal) — bottom sheet
- `BridgeTimeGrid` (7×17 hour grid, tap toggle) — 스케쥴 등록
- `BridgePillIconButton` (수정하기, 자동계산 등 작은 라벨+아이콘) — confirm, weekly
- `BridgeDeltaBanner` (variants: `.over` red / `.under` info-blue) — daily error
- `BridgeMissionCard` (statuses: pendingCheck / reviewing / completed / rejected) — child_home + 미션 화면
- `BridgeNotificationTile` (category-tinted chip + body + CTA) — 알림
- `BridgeSwipeActionBackground` (red reveal) — 알림 swipe
- `BridgeRewardInline` (분리 색상 number/unit text, NO badge bg) — 미션
- `BridgePhotoTile` (157×156, 8-radius placeholder) + `BridgeAddPhotoTile` (dashed border) — 미션
- `BridgeEmptyState` (text only) — noti / confirm empty
- `BridgeSuccessIcon` (60×60 primary 원 + white check) — time 완료, mission 완료

### 2.3 Organisms
- `BridgeTopBar` (자녀홈 전용: my 버튼 + 알림 벨)
- `BridgeBottomNav` (홈/리포트/알림/마이) — **Phase 0 에서 셸 라우트 도입 필요**
- `TimeDonutChart` (듀얼 링) — child_home
- `BridgeBarChart` + `BridgePieChart` — report (`fl_chart` 도입)
- `BridgeTimeBottomSheet` (header + 휠피커×2 + primary 보더 selection band + 확인 버튼) — 시간 설정 다수
- `BridgeTimeAllocBottomSheet` (`BottomSheetMode { dayPicker, timePicker }` 상태머신) — daily 분배
- `BridgeConfirmDialog` (취소 outlined + 확인 primary, NO destructive red) — 탈퇴 + 알림 공용
- `BridgeOnboardingTooltip` (자녀홈, confirm onboarding) — 신규 강조 UX

---

## 3. 도메인 결정 (사용자 확인 필요)

추출 결과로 추론한 가설:

### 3.1 시간 설정 흐름 — **가장 일관된 해석**
| 화면 그룹 | 역할 | 누가 | 언제 |
|---|---|---|---|
| **시간 설정 v1** (16 화면) | 자녀의 **초기 시간 계획 등록** | 자녀 | 첫 가입 직후, 월 단위 |
| **시간 설정 v2** (9 화면) | 자녀의 **다음 주차 계획 등록** | 자녀 | 매주 (이전 주 prefilled, 수정 가능) |
| **시간 설정 확인** (3 화면) | 부모가 임의 변경한 계획을 **자녀가 read-only로 확인** | 자녀 | 부모 강제 조정 후 |

**근거**:
- v1/v2 의 완료 메시지: "이번주 시간 계획이 **부모님께 전달되었어요**" → 자녀 → 부모 방향
- 확인 화면 툴팁: "꼭 필요한 경우에 **부모님의 시간 설정 탭에서 허락을 받아 수정**할 수 있어요" → 자녀는 read-only

⚠️ **사용자 확인 요청**: 위 해석이 맞는지? 시간 설정 v1/v2 화면이 자녀앱 화면이 맞는지? (부모앱은 별도라고 하셨는데, v1/v2 의 풍부한 편집 UI 가 자녀 권한과 일치?)

### 3.2 회원가입 (Figma 미포함)
UI-figma.md 에 "# 로그인" 항목만 있고 회원가입 항목 없음. 그리고 "# 로그인" 노드는 사실 **인트로 화면** (Bridge 로고 + 자녀회원가입 CTA). 진짜 로그인/회원가입 화면이 Figma 다른 곳에 있는지 확인 필요.

### 3.3 미션 거절(rejected) 풀스크린 디자인 누락
자녀홈의 _MissionCard 는 4 상태 (pendingCheck/reviewing/completed/rejected) 를 갖지만, 미션 풀스크린은 rejected 변형이 Figma 에 없음. 재시도/사유 확인 화면 디자인 필요.

### 3.4 다이얼로그 destructive 액션 색상
탈퇴 다이얼로그의 확인 버튼이 **primary blue** (destructive red 아님). 의도된 디자인 결정 OK 확인.

---

## 4. 기존 코드와의 정합성 이슈 (Phase 2 검수 대상)

### 4.1 시스템적 90% scale 문제
- `password_change_page.dart` 의 필드 높이, 폰트 크기, 보더 두께 등이 모두 약 0.899x 배율로 축소
- 다른 기존 화면들도 잠재적으로 같은 문제 보유 가능 → Phase 2 에서 전수 비교

### 4.2 색상 코드 오타
- `child_home_page.dart` 에 `#16BF40` (오타) — 정답 `AppColors.positive #00BF40`
- `child_home_page.dart` 에 `#FFD980` (도넛 완료 링) — 디자이너 의도 색 확인 필요 (`#FFBF00` bonusAmber 의 변형?)

### 4.3 디자인 mismatch
- mypage 의 **로그아웃 버튼**: Figma에 없음. 현 impl에는 존재 → 디자이너 확인 (제거? 유지?)
- 자녀홈 settings 아이콘: 현 Material `Icons.settings` → Figma 는 커스텀 SVG. `assets/icons/settings.svg` export 필요
- pw-change helper text: 현 impl 항상 destructive red → Figma 는 중립(gray500)/에러(red) 분기 필요. `helperSeverity` enum 도입
- letter-spacing 불일치: `bodyBold` 0.57 → 0.0912, `captionMedium` 0.12 → 0.3024

### 4.4 누락 인프라
- 하단 탭 셸 라우트 (StatefulShellRoute) — 알림/리포트/홈/마이 4탭 진입점
- `fl_chart` 패키지 (report)
- `image_picker` 패키지 + `camera-only` 분기 (mission)
- `dotted_border` 또는 CustomPainter (mission 사진 추가 dashed border)

---

## 5. spec 파일 인덱스

| # | 화면 그룹 | Spec 파일 | 노드 수 |
|---|---|---|---|
| 01 | 인트로/로그인 화면 | (인라인 추출, [home_page.dart](../../lib/features/home/presentation/pages/home_page.dart) 와 일치) | 1 |
| 02 | 자녀 홈 (v1/v2) | [02-child-home.md](02-child-home.md) | 2 |
| 03 | 마이페이지 | [03-mypage.md](03-mypage.md) | 1 |
| 04a | 비밀번호 변경 전반 | [04a-password-change.md](04a-password-change.md) | 3 |
| 04b | 비밀번호 변경 후반 | [04b-password-change.md](04b-password-change.md) | 3 |
| 05 | 탈퇴 + 탈퇴 완료 | [05-delete.md](05-delete.md) | 2 |
| 06 | 알림 탭 | [06-notifications.md](06-notifications.md) | 4 |
| 07 | 사용 리포트 | [07-report.md](07-report.md) | 1 |
| 08a | 시간 설정 v1 — 진입/주별 | [08a-time-v1-entry-weekly.md](08a-time-v1-entry-weekly.md) | 6 |
| 08b | 시간 설정 v1 — 일별 분배 | [08b-time-v1-daily.md](08b-time-v1-daily.md) | 6 |
| 08c | 시간 설정 v1 — 에러/완료 | [08c-time-v1-errors-done.md](08c-time-v1-errors-done.md) | 4 |
| 09 | 시간 설정 v2 | [09-time-v2.md](09-time-v2.md) | 9 |
| 10 | 시간 설정 확인 | [10-time-confirm.md](10-time-confirm.md) | 3 |
| 11 | 미션 정보/수행 | [11-mission.md](11-mission.md) | 8 |
| **합계** | | | **53** |

---

## 6. 다음 단계 권장 순서

1. **사용자 확인** (§3.1, §3.2, §3.3)
2. **Phase 0** — 토큰 + 인프라 보강 (병렬 9 에이전트)
   - 신규 색상/타이포 토큰 추가
   - 하단 탭 셸 라우트 도입
   - `pubspec.yaml` 에 `fl_chart`, `image_picker`, `dotted_border` 추가
   - `lib/core/widgets/` 디렉터리 골격
3. **Phase 1** — 컴포넌트 추출 (병렬 9+ 에이전트)
   - inline 위젯들을 `lib/core/widgets/` 로 승격
   - 90% scale 시스템적 보정 포함
4. **Phase 2~7** — 화면 구현 (계획서 §3 참조)
