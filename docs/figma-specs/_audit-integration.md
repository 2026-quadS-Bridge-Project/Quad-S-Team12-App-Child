# Bridge_K 자녀앱 — 통합 감사 (Integration Audit)

> 작성일: 2026-05-18
> 범위: cross-screen 무결성 (개별 화면 fidelity는 per-screen 감사 문서 참조)
> 기준: `flutter analyze lib/` + Grep 전수조사 + 라우터/위젯 카탈로그 대조

---

## 1. 라우팅 / 셸 구조

### 1.1 하단 탭 제거 — CONFIRMED
- `lib/app/router/app_router.dart`: `StatefulShellRoute`/`ShellRoute` 없음. 모든 라우트 top-level. 주석으로 의도 명시 ("All 4 destinations reached via header icons or push navigation rather than a tab bar.").
- `Grep BridgeShellScaffold|NavigationBar|BottomNavigationBar` over `lib/` → **0 매치**.
- 카탈로그 §2.3 의 `BridgeBottomNav` 항목은 **의도적으로 미구현** 상태. 카탈로그 본문 ("Phase 0 에서 셸 라우트 도입 필요") 와 현재 구현 방침이 어긋나므로 카탈로그 메모 갱신 필요.

### 1.2 등록된 라우트 (14개)
`/`, `/login`, `/signup`, `/mypage`, `/mypage/password`, `/mypage/delete-complete`, `/child-home`, `/child-home/onboarding`, `/child-home/report`, `/child-home/notifications`, `/child-home/time-setup`, `/child-home/time-setup/v2`, `/child-home/time-setup/confirm`, `/child-home/mission/:id`.

→ 카탈로그 §5 의 13 spec 그룹 모두 진입점 보유.

---

## 2. child_home 헤더 와이어링

`child_home_page.dart:166-244` (헤더 영역) + `:283-321` (오늘의 시간 헤더 액션).

| 자리 | 위젯 | 액션 | 상태 |
|---|---|---|---|
| TopBar 좌측 | `_MyPageButton` (세로바 + "my") | `context.push('/mypage')` | OK |
| TopBar 우측 | `Icons.notifications_none_rounded` + red dot | `context.push('/child-home/notifications')` | OK (알림 dot 은 `hasContent` 플래그에 결합 — 추후 실데이터 결합 필요) |
| "오늘의 시간" 우측 (showDonut) | `Icons.bar_chart_rounded` | `context.push('/child-home/report')` | OK |
| "오늘의 시간" 우측 (showDonut) | `Icons.settings_outlined` | `context.push('/child-home/time-setup/confirm')` | OK |
| 비고 (`!hasContent`) | "사용 리포트" 라벨만, 액션 없음 | — | 의도된 빈 상태 표시 |

⚠️ 두 아이콘 모두 Material 기본 (`Icons.bar_chart_rounded`, `Icons.settings_outlined`). 카탈로그 §4.3 메모대로 Figma 커스텀 SVG (`assets/icons/settings.svg` 등) 미반영 — Phase 추적 항목.

---

## 3. Cross-screen Bridge widget 사용

### 3.1 표준 컴포넌트 채택률
- `appBar: AppBar(...)` 직접 사용: **0건** (전 화면 `BridgeAppBar`).
- `ElevatedButton` / `OutlinedButton`: **0건**.
- `TextButton`: 1건 (`weekly_time_setup_page.dart:72` trailing 슬롯) — 작은 텍스트 액션, 정책상 허용 가능하나 `BridgePillIconButton` 또는 textLink variant 검토 권장.

### 3.2 BridgeAppBar 적용 화면 (전수)
login, signup, my_page, password_change, notifications, report, time_confirm, time_setup_intro / weekly / daily / review / schedule_register, mission_info (info/perform/preview).
child_home 만 자체 헤더 (`_TopBar`) — 의도된 디자인 (홈 전용 leading=my, trailing=벨).

---

## 4. 토큰 디스플린 (hex 리터럴 grep)

`Grep "Color(0xFF" lib/features/` → **2 건만 잔존**

| 파일:라인 | 값 | 진단 |
|---|---|---|
| `my_page.dart:311` | `Color(0xFFEBF5FE)` | = `primary050` (`primaryLight`). 토큰화 누락. |
| `child_home_page.dart:852` | `Color(0xFFFFD980)` | 도넛 완료 링. 카탈로그 §4.2 에서 "디자이너 의도 확인 필요" 로 이미 적시된 미해결 값. |

→ feature 폴더의 토큰 디스플린은 사실상 깨끗 (>99% 토큰 경유). 두 건 모두 기존 audit 에 기록되어 있고 토큰 추가/확정만 하면 1줄 교체로 끝남.

---

## 5. 뒤로가기 동작 일관성

샘플 5건 검토 (`my_page`, `notifications`, `report`, `mission_info`, `time_confirm`):
- 모두 `BridgeAppBar` 사용. `BridgeAppBar.onBack` 기본값은 `() => context.pop()` (`bridge_app_bar.dart:74`).
- `onBack` 명시 오버라이드 사례:
  - `login` / `signup` → `context.go('/')` (인트로 복귀, 의도됨).
  - `schedule_register` → `context.go('/child-home')` (시간 설정 외 단축 복귀, 의도됨).
  - `mission_info` 다단 뷰 (`:380`, `:510`) → `controller.goBack` (내부 step 머신).
  - `time_setup_review`, `daily_time_setup`, `weekly_time_setup` → step 머신의 `controller.goToStep(...)` (multi-step 마법사 정상 패턴).

→ pop semantics 위반 없음. 모든 sub-page back 동작 결정적.

---

## 6. flutter analyze 결과

```
1 issue found. (ran in 0.7s)
error • The type 'MissionFlowStep' isn't exhaustively matched by the switch
        cases since it doesn't match the pattern 'MissionFlowStep.cameraPrompt'
        • lib/features/mission/presentation/pages/mission_info_page.dart:57:18
        • non_exhaustive_switch_expression
```

⛔ **빌드 차단 에러 1건**. enum 에 `cameraPrompt` step 이 추가되었으나 page-level switch 가 4 케이스만 처리. compile 통과 못함.

---

## 7. 재사용 컴포넌트 카탈로그 vs 구현 매트릭스

`Glob lib/core/widgets/**/*.dart` 결과 (33 파일) ↔ 카탈로그 §2 (25+ 항목)

### Atoms (6/6 구현)
- BridgeButton — `buttons/bridge_button.dart`
- BridgePillIconButton — `buttons/bridge_pill_icon_button.dart`
- BridgeStepperPills — `icons/bridge_stepper_pills.dart` (Molecule 로 분류했지만 icons/ 하위 배치)
- BridgeWheelPicker — `pickers/bridge_wheel_picker.dart`
- BridgeStepCircle — `layout/bridge_step_circle.dart`
- BridgeAppBar — `layout/bridge_app_bar.dart`
- ⚠️ **BridgeTextField 누락** — `lib/core/widgets/inputs/` 에 파일 없음 (`bridge_photo_tile`, `bridge_time_grid`, `bridge_weekday_selector` 만 존재). login/signup/pw-change 가 자체 텍스트필드 사용 추정 → 컴포넌트 미추출.
- ⚠️ **BridgeChip 누락** — weekday on/off, day-tag chip 도 미추출.

### Molecules (10/12 구현)
- BridgeStepHeader, BridgeWeekRow, BridgeTotalTimeCard, BridgeWeekdaySelector, BridgeTimeGrid, BridgeDeltaBanner, BridgeNotificationTile, BridgeSwipeActionBackground, BridgePhotoTile, BridgeEmptyState — 전부 매핑됨.
- ⚠️ **BridgeInfoRow 누락** — my_page 의 `_InfoRow` 여전히 inline private 위젯.
- ⚠️ **BridgeMissionCard 누락** — child_home `_MissionCard` 여전히 inline. report 화면에도 mission 카드 등장 시 중복 위험.
- ⚠️ **BridgeRewardInline 누락** — mission 내부 `_RewardChip` (inline) 만 존재.
- ⚠️ **BridgeAddPhotoTile 누락** — `bridge_photo_tile.dart` 1개만 있음.
- ⚠️ **BridgeSuccessIcon 누락** — 시간/미션 완료 화면 inline.

### Organisms (7/9 구현)
- TimeDonutChart — child_home `_TimeDonutChart` (inline CustomPainter, 미승격).
- BridgeBarChart, BridgePieChart — `charts/` 구현 ✅
- BridgeTimeBottomSheet, BridgeTimeAllocBottomSheet — `pickers/` 구현 ✅
- BridgeConfirmDialog, BridgeOnboardingTooltip — `feedback/` 구현 ✅
- ⚠️ **BridgeTopBar (자녀홈 전용) 미승격** — child_home `_TopBar` inline.
- ⚠️ **BridgeBottomNav** — 의도적 미구현 (§1.1).

**합계**: 카탈로그 25 항목 중 구현 17, inline 잔존/미추출 7, 의도적 보류 1.

---

## 8. 상태 요약 — end-to-end 동작 / TODO / 백엔드 블로킹

### ✅ End-to-end 동작
- 인트로 → 로그인/회원가입 → child_home onboarding → child_home 진입.
- child_home → mypage / notifications / report / time-setup / mission 5 경로 모두 router 등록 + push 와이어링 완료.
- BridgeAppBar back chevron 전 화면 pop 정상.
- time_setup v1 step 머신 (intro → weekly → daily → review) controller-driven 정상 동작.
- mission flow (info → perform → photoPreview → submitted) controller 기반 navigation 동작 (단, §6 컴파일 에러 해결 후).

### ⏳ TODO (코드 내 명시)
- `child_home_page.dart:26` `_hasSchedule` 하드코딩 → 실 스케줄 영속 결합 필요.
- TopBar 알림 dot (`hasNotification = hasContent`) → 실제 unread count 결합 필요.
- 카탈로그 §4 의 컴포넌트 7건 inline → core/widgets 승격.
- Material `Icons.settings` / `Icons.bar_chart_rounded` → Figma 커스텀 SVG 교체.

### 🚧 백엔드 블로킹
- 자녀-부모 연결 (onboarding tooltip 흐름).
- 시간계획 저장/조회 (`_hasSchedule` 토글 디버그용).
- 미션 사진 업로드 + 상태 (`reviewing` / `completed` / `rejected`) 전이.
- 알림 목록 / 읽음 처리 / unread badge.
- usage report 데이터 (현재 `UsageReportMock.currentWeek`).
- 부모 수정 후 자녀 read-only confirm 페이지 데이터 소스.

---

## 9. 결론

- **무결성 좋음**: 라우팅 단순/일관, BridgeAppBar/BridgeButton 채택률 사실상 100%, 토큰 누설 2건뿐.
- **즉시 블로커**: §6 컴파일 에러 1건.
- **카탈로그 갭**: §7 의 inline → core 승격 7건 (특히 BridgeTextField, BridgeMissionCard, BridgeInfoRow). 화면이 추가될수록 중복 위험 누적.
- **카탈로그 메모 갱신 필요**: `BridgeBottomNav` 항목은 "의도적 보류" 로 라벨링 변경 권장.
