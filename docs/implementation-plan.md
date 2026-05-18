# Bridge_K 자녀앱 UI 구현 계획서

> 작성일: 2026-05-18
> 대상 범위: [docs/UI-figma.md](UI-figma.md) 에 명시된 모든 화면을 Mock UI로 100% 디자인 정합되게 구현
> 전략: 재사용 컴포넌트 우선 추출 → 화면 조립 → Mock 데이터로 발전

---

## 진행 상황 (2026-05-18 업데이트)

> 본 섹션은 계획 수립 이후의 실제 구현 상태를 요약한다. 아래의 원본 Phase 0~7 계획은 변경 없이 유지하되, 본 섹션이 가장 최신의 단일 진실 공급원(Single Source of Truth)이다.
> 진행 상황 판단의 근거는 `docs/figma-specs/_audit-phase2-existing.md` / `_audit-phase3.md` / `_audit-phase4.md` / `_audit-phase5.md` / `_audit-phase6.md` 5개 audit 문서이며 본 문서에서 cross-reference 한다.

### A. Phase 완료 매트릭스

| Phase | 범위 | 상태 | 근거 audit 문서 |
|---|---|---|---|
| **Phase 0** — 토큰·인프라 보강 | AppBar/BottomSheet/Dialog/SnackBar 테마, `lib/core/widgets/` 골격, StatefulShellRoute, mock 폴더 | ✅ DONE | (인프라; audit 대상 외) |
| **Phase 1** — 재사용 컴포넌트 추출 | BridgeButton/TextField/Toast/AppBar/InfoRow/MissionCard/TimeDonutChart/CircleIcon | ✅ DONE | _audit-phase2-existing.md §"Shared-widget reuse gaps" (재사용 측면만 일부 잔존) |
| **Phase 2** — 기존 화면 디자인 정합화 | login / signup / home(intro) / child-home / mypage / password / delete-complete | 🟡 PARTIAL | _audit-phase2-existing.md (Tier1: 3 / Tier2: 14 / Tier3: 3) |
| **Phase 3** — 알림 + 사용 리포트 | NotificationsPage(empty/filled/swipe-delete) + UsageReportPage + 차트 | ✅ DONE | _audit-phase3.md (Tier1~3 잔존, 골격 완성) |
| **Phase 4** — 시간 설정 v1 (16 화면) | scheduleRegister → weeklyTotal → dailyAllocation → review → complete + 바텀시트 + 에러 배너 | ✅ DONE | _audit-phase4.md (46 PASS / 30 FAIL — 골격 완성, 카피·구조 드리프트 잔존) |
| **Phase 5** — 시간 설정 v2 + 확인 | v2 wizard (mode=v2NextWeek) + TimeConfirm(empty/filled/onboarding) + OnboardingTooltip | ✅ DONE | _audit-phase5.md (PARTIAL; intro splash 미구현, per-week data model 미완) |
| **Phase 6** — 미션 정보/수행 (8 화면) | MissionInfo → Perform → PhotoPreview → Submitted(reviewing/completed/rejected) | ✅ DONE | _audit-phase6.md (9 PASS / 7 FAIL / 4 WARN) |
| **Phase 7** — 통합 검증 | 골든 스크린샷, mock 시드 정리, 라우팅 그래프, A11y, analyze, 빌드, 트레이서빌리티 | 🔄 IN PROGRESS | (5개 audit 문서가 7-1/7-3/7-7 의 부분 산출물에 해당) |

요약: 0/1/3/4/5/6 완료 · 2 부분 · 7 진행 중.

### B. 작성된 파일 수 (실측)

| 영역 | 파일 수 | 경로 |
|---|---|---|
| `lib/core/widgets/` (위젯 + barrel) | **31** | buttons / charts / feedback / icons / inputs / layout / pickers 7개 카테고리 |
| `lib/features/*` (페이지 + state + data) | **35** | child_home / home / login / mission / my_page / notifications / report / signup / time_confirm / time_setup |
| 합계 (신규 + 기존 합산) | **66** | |

신규 작성 비중이 가장 큰 디렉터리: `lib/features/time_setup/` (10 파일), `lib/core/widgets/` 전체 (Phase 1 산출물).

### C. 신규 컴포넌트 카탈로그 (Phase 0/1 ~ 6 누적 — 26개)

Buttons (3): `BridgeButton`, `BridgePillIconButton`, (barrel `buttons.dart`)
Charts (2): `BridgeBarChart`, `BridgePieChart`
Feedback (6): `BridgeConfirmDialog`, `BridgeDeltaBanner`, `BridgeEmptyState`, `BridgeNotificationTile`, `BridgeOnboardingTooltip`, `BridgeSwipeActionBackground`
Icons (1): `BridgeStepperPills`
Inputs (3): `BridgePhotoTile`, `BridgeTimeGrid`, `BridgeWeekdaySelector`
Layout (5): `BridgeAppBar`, `BridgeDayRow`, `BridgeStepCircle`, `BridgeStepHeader`, `BridgeTotalTimeCard`, `BridgeWeekRow` (6)
Pickers (3): `BridgeTimeAllocBottomSheet`, `BridgeTimeBottomSheet`, `BridgeWheelPicker`

총 26개 위젯 + 7 barrel 파일. 모두 token-only API (audit 결과 `lib/features/time_setup/`, `lib/features/time_confirm/`, `lib/features/mission/` 에서 stray hex 0건). 잔존 hex 5건은 `child_home_page.dart`(2) / `login_page.dart`(1) / `signup_page.dart`(1) / `home_page.dart`(1) — Phase 2 잔여.

### D. 완료된 화면 매트릭스 (figma-specs ↔ lib/features)

| Figma spec | Figma node | 구현 파일 | Phase | 상태 |
|---|---|---|---|---|
| 02-child-home (v1/v2) | 426-20978, 426-21005 | `lib/features/child_home/presentation/pages/child_home_page.dart` | 2 | 🟡 (hex 2, 아이콘 Material) |
| 05-delete (complete) | 773-11070 | `lib/features/my_page/presentation/pages/delete_account_complete_page.dart` | 2 | 🟡 (90% scale 잔존) |
| (intro) | 662-8356 | `lib/features/home/presentation/pages/home_page.dart` | 2 | 🟡 (`#6DB5FF` 토큰화 결정 필요) |
| (login) | (out-of-figma) | `lib/features/login/presentation/pages/login_page.dart` | 2 | 🟡 (BridgeAppBar/Button 재사용 미반영) |
| (signup) | (out-of-figma) | `lib/features/signup/presentation/pages/signup_page.dart` | 2 | 🟡 (동일) |
| 06-notifications (4 변형) | 426-19287, 426-19293, 773-12916, 773-12903 | `lib/features/notifications/presentation/pages/notifications_page.dart` + `BridgeNotificationTile` | 3 | 🟡 (카피·아이콘 드리프트) |
| 07-report | 662-11497 | `lib/features/report/presentation/pages/report_page.dart` + `BridgeBarChart`/`BridgePieChart` | 3 | 🟡 (Card1/Footer 누락) |
| 08a 시간 설정 v1 entry+weekly | 695-8924/9115/11870/8694/13485 | `schedule_register_page.dart` + `weekly_time_setup_page.dart` + `BridgeTimeBottomSheet` | 4 | 🟡 (4주 분배 미구현) |
| 08b 시간 설정 v1 daily | 695-9743/13193/11096 | `daily_time_setup_page.dart` + `BridgeTimeAllocBottomSheet` | 4 | 🟡 (스케줄 보기 chip 누락) |
| 08c 시간 설정 v1 errors+done | 695-10675/10817/11487/12086 | `time_setup_review_page.dart`, `time_setup_complete_page.dart`, `BridgeDeltaBanner` | 4 | 🟡 (배너 suffix·완료 화면 순서) |
| 09 시간 설정 v2 (9 화면) | 750-13034/12671/11991/13450/13105/13686/14708/13854/13624 | `time_setup_v2_root_page.dart` + 공유 sub-pages (mode=`v2NextWeek`) + `time_setup_intro_page.dart` | 5 | 🟡 (v2-1 intro splash 미구현, per-week model 미완) |
| 10 시간 설정 확인 (3 화면) | 744-11326, 662-11322, 662-11249 | `time_confirm_page.dart` + `BridgeOnboardingTooltip` + `TimeConfirmController` | 5 | 🟡 (수정요청 stub만; 카피 드리프트) |
| 11 미션 (8 화면) | 746-11392/11380, 426-18960/19035/18995/18974/19052/19062 | `mission_info_page.dart` + `MissionController` + `BridgePhotoTile` | 6 | 🟡 (info 5섹션 미구현, perform/camera 분리 필요) |

### E. 잔존 TODO / Tier 2-3 보정 사항 (audit 종합)

**Tier 1 (구조·내용 누락 — Figma 정합성 차단)**
- _audit-phase3.md §Tier 1 #1 — Report Card 1 (Weekly Intro, speech bubble, 고양이 일러스트) 미구현
- _audit-phase3.md §Tier 1 #2 — Report Footer CTA `다음주 계획 짜러가기 →` 미구현
- _audit-phase3.md §Tier 1 #3 — Report Card 3 per-day breakdown `BridgeDayRow + BridgeDeltaChip` 구조 재작성
- _audit-phase3.md §Tier 1 #4 — 알림 6개 verbatim mock 으로 교체 (현재 5개, paraphrase)
- _audit-phase4.md §Tier 1 #1 — `daily_time_setup_page.dart`의 `_TotalSummaryCard` → 스펙 `BridgeWeekTimeBox`
- _audit-phase4.md §Tier 1 #2 — weekly v2: 4주 행 vs 1행 `이번 주` 의사결정 + per-week 데이터 모델 (현재 모든 행이 같은 totalHours 표시; `weekly_time_setup_page.dart:88-93, 102-106` TODO)
- _audit-phase4.md §Tier 1 #3 — `BridgeDeltaBanner` `초과`/`남음` suffix 제거 (Figma 는 `+ 00시간 00분` 만)
- _audit-phase4.md §Tier 1 #4 — child-home `_hasSchedule` 하드코딩 `true` → 실제 상태 와이어링
- _audit-phase5.md §Tier 1 #4 — TimeSetupV2 intro splash (`TimeSetupStep.intro` + IntroPage) 미구현
- _audit-phase5.md §Tier 1 #3 — `BridgeOnboardingTooltip` 팔레트 반전 (현재 white/gray800 → 스펙은 gray600/white + bullet + close X)
- _audit-phase6.md §Tier 1 #1 — `_CameraCTA` dashed border (`dotted_border` 재사용)
- _audit-phase6.md §Tier 1 #2 — Mission `_InfoView` 5개 settings 섹션 (카테고리/리셋주기/확인방식/지급시간/상세설명) 미구현
- _audit-phase6.md §Tier 1 #3 — `_PerformView` 분리: `MissionFlowStep.cameraPrompt` 도입 (현재 perform=camera 혼합)

**Tier 2 (드리프트 — 문서·코드 정합성)**
- 5개 audit 전반: 카피 verbatim 미일치 (시간 설정 wizard 헤더, TimeConfirm 섹션 타이틀, Report Card 카피)
- _audit-phase4.md §6 — `자동계산` 버튼: `BridgeIconButton` chip 미구현, `_handleAutoDistribute` no-op
- _audit-phase4.md §6 — `스케줄 보기 ›` chip 미구현 (`695-11096` 화면도 미구현)
- _audit-phase3.md §Tier 2 #6/8 — 알림 `missionComplete` 색상 `cautionary` → `secondaryYellow` 교체 / 영역 헤더 색
- _audit-phase2-existing.md §"Shared-widget reuse gaps" — login/signup/home 의 `_*TopBar` / `_*Button` → `BridgeAppBar` / `BridgeButton` 흡수
- _audit-phase2-existing.md §"Cross-cutting / 90% scale" — `delete_account_complete_page.dart` 의 17.982/294.897 fractional 값 정규화
- _audit-phase5.md §Tier 2 #5/6 — `TimeSchedule` 모델에 `List<WeeklyTotal>(4)` 확장 + `_handleAutoDistribute` 구현
- _audit-phase6.md §Tier 2 #4/5 — `_SubmittedView` AppBar 추가 + `BridgeMainTabs` 위젯 신규

**Tier 3 (폴리시)**
- 5개 hex 잔존: `child_home_page.dart`(2: `0x80D9D9D9` 카드 그림자, `0xFFFFD980` 완료 미션 링) / `login_page.dart:209`, `signup_page.dart:338`(`0xFF050505`) / `home_page.dart:12`(`0xFF6DB5FF` 브랜드 워드마크)
- Material `Icons.settings` / `Icons.assessment_outlined` 등 Figma SVG 자산 미반영 (audit-phase2 §5 / audit-phase3 §1)
- `SafeArea(top: false)` wizard 페이지 간 불일치 (audit-phase4 Tier 3 #10)
- 도입 후보 토큰: `AppTokens.cardShadow`, `AppColors.brandWordmark`, `AppColors.bonusAmberSoft`, `AppShadows.cardSmall`

### F. 도메인 결정 (제품 규칙 — 코드와 spec 양쪽에 반영됨)

- **시간 계획 1차 제안권 = 자녀**: TimeSetup v1 wizard (`time_setup_root_page` → scheduleRegister → weeklyTotal → dailyAllocation → review → complete) 의 결과물이 부모에게 전달되는 흐름 (`time_setup_complete_page.dart:60`: "이번주 시간 계획이 부모님께 전달되었어요").
- **수정권 = 부모 단독**: 자녀는 직접 수정 불가. 자녀 측 화면(`TimeConfirm`)은 **read-only confirm + 수정 요청 stub** 만 제공.
  - 근거: `time_confirm_page.dart:69-75`의 `_showRequestSnack` (`부모님께 수정 요청을 보냈어요.` SnackBar) + `BridgeDayRow(onEdit: null, showPencil: false)` (audit-phase5 §TimeConfirm PASS #4).
  - `BridgeOnboardingTooltip` 카피(자녀 측): "직접 수정할 수 없어요. 꼭 필요한 경우에 부모님의 시간 설정 탭에서 허락을 받아, 수정할 수 있어요" — 이 규칙을 사용자에게 명시.
- **v2 (다음주 계획) 모드**: `TimeSetupController.v2NextWeek(previousWeek: ...)` 로 진입 시 `showPastWeekDim = true` 가 켜져 지난 주 행이 `Opacity(0.2)` 로 dim 처리 (audit-phase5 §TimeSetupV2 PASS #3). 즉 자녀가 다음주 계획을 짤 때 이전 주 데이터를 참조용으로 본다.

### G. 향후 백엔드 연동 시 처리할 사항

현재 모든 상태는 in-memory `ChangeNotifier` + SharedPreferences (AuthSession) 기반이다. 백엔드 합류 시 아래 진입점을 실 API 호출로 교체한다.

| 진입점 | 현재 구현 | 백엔드 연동 시 처리 |
|---|---|---|
| `MissionController.submit` | 로컬 상태를 `MissionStatus.reviewing` 으로 전환 | `POST /missions/:id/submissions` (photos multipart 업로드) → 응답 status 반영 |
| `MissionController` 상태 폴링 | 미구현 (mock immediate) | reviewing → completed/rejected 전이는 푸시 알림 또는 폴링 필요 |
| `TimeConfirmController.requestModification` | `_showRequestSnack` 만 표시 (서버 호출 없음) | `POST /time-plans/:id/modification-requests` + 부모 측 알림 트리거 |
| `TimeSetupController` 등록 (`time_setup_complete_page`) | `_handleSubmit` → in-memory `_schedule` 저장 + `/child-home` 이동 | `PUT /children/:id/time-plans/:week` (v1) / `PUT /children/:id/time-plans/next-week` (v2) |
| `NotificationsController.dismiss` | 로컬 mock list 제거 | `DELETE /notifications/:id` + 서버 sync; unread count 갱신 |
| `AuthSession` | SharedPreferences (loggedIn / childName) | JWT/refresh token, `parentId`/`childId` 관계, 권한 토큰 (자녀 vs 부모 액션 분리) 까지 확장 |
| `Mission` / `TimeSchedule` / `UsageReport` 모델 | UI 표시 필드 위주 단순화 | 백엔드 스키마와 매핑 어댑터 추가 (서버 enum → 클라이언트 enum) |
| `UsageReport` 데이터 | mock 고정 (2월 1주차) | `GET /reports?week=YYYY-WW` + 기간 선택 UI 활성화 |
| `자동계산` (weekly v2) | `_handleAutoDistribute` no-op | 클라이언트 계산이면 그대로, 서버 추천이면 `GET /time-plans/auto-suggest` |
| Push notifications | 미구현 | 부모 측 액션 (시간 수정 승인/반려, 미션 검토) → 자녀 측 푸시. FCM/APNs 결정 필요 |
| 카메라 권한 거부 폴백 | 미정 (Phase 6 open question) | 권한 영구 거부 시 설정 페이지 deep-link 안내 |

---

## 0. ⚠️ Figma 데이터 수급 블로커 (선결 필수)

**전수조사 결과 12개 서브에이전트가 `figma.com/design/...` URL을 fetch 시도했으나 0/45 성공.**
사유: Figma 디자인 URL은 인증된 SPA로, JS 실행 + 로그인 쿠키 없이는 캔버스 데이터에 접근 불가. 모든 fetch 응답은 빈 HTML shell("Figma" 문자열 1개)만 반환.

**100% 디자인 정합성을 만족하려면 본 계획 실행 전에 아래 중 하나 필요:**

| 옵션 | 정합도 | 소요 | 권장 |
|---|---|---|---|
| A. 각 프레임을 PNG @2x 로 export → `docs/figma-exports/<screen>.png` 커밋 | 중-상 (시각 기반) | 사용자 수동, 1회 | ⭐ 1순위 |
| B. Figma Personal Access Token 발급 → REST API (`/v1/files/.../nodes?ids=...`) 호출 | 최상 (토큰 단위 추출) | 토큰 발급 + 환경변수 1회 | ⭐ 2순위 (장기) |
| C. Figma Dev Mode MCP 서버 설치 (`figma-developer-mcp`) | 최상 | MCP 설정 | 3순위 |
| D. Dev Mode 인스펙터 텍스트 수동 paste | 하 (오류 가능) | 화면 수만큼 반복 | 비권장 |

**제안 폴더 규약** (Option A 채택 시):
```
docs/figma-exports/
├── 01-login.png                    # node 662-8356
├── 02-home.png                     # node 426-20978
├── 02-home-2.png                   # node 426-21005
├── 03-mypage.png                   # node 773-11103
├── 04-pwchange-{1..6}.png          # 773-11124 ~ 773-11626
├── 05-delete-confirm.png           # 773-11838
├── 05-delete-complete.png          # 773-11070
├── 06-noti-{empty,filled,delete-1,delete-2}.png
├── 07-report.png                   # 662-11497
├── 08-time-v1-{01..16}.png         # 695-* 시리즈
├── 09-time-v2-{01..09}.png         # 750-* 시리즈
├── 10-time-confirm-{1..3}.png
└── 11-mission-{01..08}.png
```

PNG가 들어오면 Read 툴로 이미지 직독 → 픽셀 단위 레이아웃·텍스트·근사 색상 추출이 즉시 가능.

---

## 1. 현재 코드베이스 감사 결과

### 1.1 디자인 토큰 (이미 잘 정의됨, 즉시 사용 가능)

[lib/core/theme/](../lib/core/theme/) 에 다음이 갖춰져 있음:

- **색상** ([app_colors.dart](../lib/core/theme/app_colors.dart))
  - Primary `#3A99F8`, Positive `#00BF40`, Cautionary `#FF9200`, Destructive `#FF4242`
  - Gray 050~900 11단계, white/black, 시맨틱 alias (background/surface/border/textPrimary/textSecondary)
- **타이포** ([app_typography.dart](../lib/core/theme/app_typography.dart)) — Pretendard, 6 단계 × 3 weight = 18 스타일
  - Heading1(24) / Heading2(20) / Headline(18) / Body(16) / Label(14) / Caption(12)
- **스페이싱** ([app_tokens.dart](../lib/core/theme/app_tokens.dart))
  - mobileFrameWidth 375, pageHorizontal 24, sectionGap 32, itemGap 16, smallGap 8, mediumGap 12
  - cardRadius 28, cardPadding 24
- **테마** ([app_theme.dart](../lib/core/theme/app_theme.dart)) — AppBar/Card/ElevatedButton/InputDecoration 까지 wiring 완료

### 1.2 토큰 누락 항목 (Phase 0 에서 보강)

- BottomNavigationBarTheme (홈/리포트/마이/알림 4탭 예상)
- BottomSheetTheme (시간 설정에서 다수 사용)
- DialogTheme (탈퇴 확인 다이얼로그용)
- SnackBarTheme
- OutlinedButton / TextButton 테마
- Elevation 토큰 (현재 미정의)
- Sigmar 폰트 — pubspec 등록되어 있으나 [app_typography.dart](../lib/core/theme/app_typography.dart)에서 미사용. `home_page` 인트로의 "Bridge" 로고만 사용 중

### 1.3 라우팅 ([lib/app/router/app_router.dart](../lib/app/router/app_router.dart))

기존 라우트:
| 경로 | 위젯 | 상태 |
|---|---|---|
| `/` | HomePage (인트로) | ✅ |
| `/login` | LoginPage | ✅ Mock 자격증명 |
| `/signup` | SignupPage | ✅ 로컬 검증, 계정 생성 미연동 |
| `/child-home` | ChildHomePage | ✅ Mock |
| `/child-home/onboarding` | ChildHomePage (showOnboarding=true) | ✅ |
| `/mypage` | MyPage | ✅ |
| `/mypage/password` | PasswordChangePage | ✅ |
| `/mypage/delete-complete` | DeleteAccountCompletePage | ✅ |

**누락 라우트 (신규 화면용)** — Phase 1 에서 추가 예정:
```
/child-home/notifications              # 알림 탭
/child-home/report                     # 사용 리포트
/child-home/time-setup                 # 시간 설정 진입
/child-home/time-setup/weekly          # 초기 주별 사용시간
/child-home/time-setup/daily/:weekday  # 일간 시간 설정
/child-home/time-setup/confirm         # 시간 설정 확인 (자녀 승인 화면)
/child-home/time-setup/v2              # 이전 주차 스케쥴 수정
/child-home/mission/:id                # 미션 정보
/child-home/mission/:id/perform        # 미션 수행 (카메라)
```

또한 **하단 탭 셸 라우트 (StatefulShellRoute) 도입 필요**: 현재 ChildHomePage 의 하단 알림 → 하단 탭 구조로 전환되어야 자연스러움. UI-figma.md 의 "알림 탭" / "사용 리포트" 명칭이 탭 컨셉을 시사함.

### 1.4 기능별 현재 상태

| 영역 | 파일 | 구현도 | 비고 |
|---|---|---|---|
| Auth (Login) | [login_page.dart](../lib/features/login/presentation/pages/login_page.dart) | 90% (UI 완성, Mock 인증) | Figma 정합성 확인 필요 |
| Auth (Signup) | [signup_page.dart](../lib/features/signup/presentation/pages/signup_page.dart) | 90% (UI 완성, 계정생성 미연동) | Figma에 회원가입 화면 미명시 → 별도 확인 필요 |
| Intro/Home | [home_page.dart](../lib/features/home/presentation/pages/home_page.dart) | 100% (Sigmar 로고 + CTA) | UI-figma.md '홈'과 동일 의도인지 검증 필요 |
| Child Home | [child_home_page.dart](../lib/features/child_home/presentation/pages/child_home_page.dart) | 80% (도넛+미션 카드, 하드코딩) | 컴포넌트 추출 필요 |
| My Page | [my_page.dart](../lib/features/my_page/presentation/pages/my_page.dart) | 90% | 컴포넌트 추출 필요 |
| Password Change | [password_change_page.dart](../lib/features/my_page/presentation/pages/password_change_page.dart) | 90% | 컴포넌트 추출 필요 |
| Delete Complete | [delete_account_complete_page.dart](../lib/features/my_page/presentation/pages/delete_account_complete_page.dart) | 100% | OK |
| **알림 탭** | — | 0% | 신규 (4 figma 변형) |
| **사용 리포트** | — | 0% | 신규 (1 화면, 차트 포함) |
| **시간 설정 v1** | — | 0% | 신규 (16 화면, 가장 큰 작업) |
| **시간 설정 v2** | — | 0% | 신규 (9 화면, 수정 플로우) |
| **시간 설정 확인** | — | 0% | 신규 (3 화면) |
| **미션 정보/수행** | — | 0% | 신규 (8 화면, 카메라 연동) |

### 1.5 에셋 인벤토리 ([assets/](../assets/))

- 총 52개 (svg 49 / png 2 / ttf 1)
- 카테고리: 알림, 자녀선택, 화살표, 버튼(cmp/btn), 액션(루틴/심부름/운동/청소/학습/완료), 시계
- **누락**: 보상 아이콘, 캘린더, 하단 탭 아이콘(홈/리포트/마이/알림 셋트), 미션 상태(checking/approved/rejected) 아이콘 일부, 카메라/카메라 권한 일러스트
- **명명 규칙 혼재** — kebab-case + snake_case + 한국어 + 숫자 prefix. Phase 0에서 정리 권장하나 신규 작업 차질 없으면 후순위

### 1.6 상태 관리 / 데이터 레이어

- 전부 `StatefulWidget` + `setState`. Bloc/Provider/Riverpod 미도입.
- 영속화는 [auth_session.dart](../lib/core/auth/auth_session.dart) 의 SharedPreferences 만 존재.
- 데이터 모델 클래스 0개. Mock 데이터는 page 파일 내부에 inline.
- **계획**: 백엔드 미정 상태이므로 `lib/features/*/data/models/` 와 `lib/features/*/data/mock/` 폴더만 우선 만들고, ChangeNotifier 기반 단순 ViewModel 도입 (Bloc/Riverpod 도입은 백엔드 합류 시 별도 결정).

---

## 2. 재사용 컴포넌트 카탈로그 (Phase 1 의 핵심 산출물)

**원칙**: 현재 page 파일 안에 inline 으로 흩어진 private widget (`_LoginField`, `_SignupField`, `_LoginToast`, `_SignupToast`, `_InfoRow`, `_MissionCard`, `_TimeDonutChart`, `_CircleStatusIcon` ...) 을 `lib/core/widgets/` 로 승격. 명명은 `Bridge` prefix.

### 2.1 Atoms (단일 요소)
| 컴포넌트 | 대상 위치 | 통합 대상 |
|---|---|---|
| `BridgeButton` | `lib/core/widgets/buttons/bridge_button.dart` | `_LoginButton`, `_SignupButton`, `_PasswordChangeButton`, `_MyPageActionButton`, 인트로 회원가입 버튼 |
| `BridgeTextField` | `lib/core/widgets/inputs/bridge_text_field.dart` | `_LoginField`, `_SignupField`, `_PasswordChangeField` (variant: helperText / checkmark / clearButton 옵션) |
| `BridgeToast` | `lib/core/widgets/feedback/bridge_toast.dart` | `_LoginToast`, `_SignupToast` (variant: warning/error/info) |
| `BridgeAppBar` | `lib/core/widgets/layout/bridge_app_bar.dart` | mypage / password_change 의 _TopBar 공통 패턴 |
| `BridgeSectionDivider` | `lib/core/widgets/layout/bridge_divider.dart` | mypage divider 등 |
| `BridgeCircleIcon` | `lib/core/widgets/icons/bridge_circle_icon.dart` | `_CircleStatusIcon` (20/24/32 변형) |

### 2.2 Molecules (Atom 조합)
| 컴포넌트 | 용도 | 비고 |
|---|---|---|
| `BridgeInfoRow` | label-value row | mypage 의 _InfoRow 승격 |
| `BridgeMissionCard` | 미션 카드 (상태별) | child_home + 미션 화면 공용. status enum: pendingCheck/rejected/reviewing/completed |
| `BridgeNotificationTile` | 알림 항목 | 신규. 읽음/안읽음 + 시간 + 액션 영역 |
| `BridgeTimeBlock` | 일별 시간 슬롯 표시 | 시간 설정 그리드용. 신규 |
| `BridgeWeekdaySelector` | 요일 선택 (월~일) | 시간 설정 신규 |
| `BridgeDayProgressBar` | 일별 진척 막대 | 사용 리포트 / 주별 분배 화면 신규 |

### 2.3 Organisms (페이지급 단위)
| 컴포넌트 | 용도 |
|---|---|
| `BridgeBottomNav` | 하단 탭 (홈/리포트/알림/마이) — StatefulShellRoute 와 결합 |
| `TimeDonutChart` | child_home 의 듀얼 링 도넛 → 파라미터화하여 재사용 |
| `BridgeTimeBottomSheet` | 시·분 휠 피커 바텀시트 (시간 설정 다수 화면에서 호출) |
| `BridgeConfirmDialog` | 탈퇴 확인 등 |
| `BridgeErrorBanner` | "설정시간 초과" / "설정시간 남음" 인라인 에러 |

### 2.4 Layout helpers
- `BridgePageScaffold` — SafeArea + 배경 색상 + 표준 padding 일관성
- `BridgeFormSection` — 섹션 헤더 + 본문 컨테이너

---

## 3. 단계별 실행 계획 (서브에이전트 병렬 분할 정책 포함)

> **분할 정책**: 각 Phase 마다 8개 이상의 서브에이전트가 병렬 가능하도록 단위를 쪼개 명시. Foreground/Background 표시.

### Phase 0 — 토큰·인프라 보강 (Figma exports 도착 전 무관하게 진행 가능)

목표: 신규 화면 작업에 필요한 테마/위젯 인프라를 미리 깔아둔다.

| # | 작업 단위 | 산출물 | 에이전트 |
|---|---|---|---|
| 0-1 | BottomNavigationBarTheme 추가 | app_theme.dart 패치 | frontend-architect |
| 0-2 | BottomSheetTheme + DialogTheme + SnackBarTheme 추가 | app_theme.dart 패치 | frontend-architect |
| 0-3 | OutlinedButton / TextButton 테마 추가 | app_theme.dart 패치 | frontend-architect |
| 0-4 | Elevation 토큰 정의 | app_tokens.dart 확장 | frontend-architect |
| 0-5 | `lib/core/widgets/` 디렉터리 골격 + barrel files | 폴더 + index.dart | general-purpose |
| 0-6 | StatefulShellRoute 기반 하단 탭 셸 라우트 도입 | app_router.dart 리팩터 | backend-architect |
| 0-7 | `lib/features/*/data/models/` + `mock/` 폴더 구조 생성 | 폴더 골격 | general-purpose |
| 0-8 | Mock 데이터 정책 문서화 | `docs/mock-data-policy.md` | technical-writer |
| 0-9 | 누락 아이콘 자리표시자 — `assets/icons/_missing/` 폴더에 placeholder 등록 | 자리표시자 + assets 등록 | general-purpose |

→ 9 개 병렬.

### Phase 1 — 재사용 컴포넌트 추출 (기존 page 들에서 inline 위젯 승격)

목표: §2 카탈로그를 실제 파일로 만들고, 기존 page 들이 이 컴포넌트를 사용하도록 리팩터.

| # | 작업 단위 | 입력 | 산출물 | 에이전트 |
|---|---|---|---|---|
| 1-1 | BridgeButton 추출 | login/signup/mypage/password_change/home 의 button 위젯 | bridge_button.dart + 기존 5개 파일 패치 | refactoring-expert |
| 1-2 | BridgeTextField 추출 (variant 3종) | login/signup/password_change 의 field 위젯 | bridge_text_field.dart + 3개 파일 패치 | refactoring-expert |
| 1-3 | BridgeToast 추출 | login/signup 의 toast 위젯 | bridge_toast.dart + 2개 파일 패치 | refactoring-expert |
| 1-4 | BridgeAppBar 추출 | mypage/password_change 의 top bar | bridge_app_bar.dart + 2개 파일 패치 | refactoring-expert |
| 1-5 | BridgeInfoRow 추출 | mypage 의 _InfoRow | bridge_info_row.dart + mypage 패치 | refactoring-expert |
| 1-6 | BridgeMissionCard 추출 | child_home 의 _MissionCard + status icons | bridge_mission_card.dart + child_home 패치 | refactoring-expert |
| 1-7 | TimeDonutChart 추출 + 파라미터화 | child_home 의 _TimeDonutChart | time_donut_chart.dart + child_home 패치 | refactoring-expert |
| 1-8 | BridgeCircleIcon + BridgeSectionDivider 추출 | child_home / mypage | 2개 파일 + 패치 | refactoring-expert |
| 1-9 | 회귀 검증 — 기존 화면이 시각적으로 동일한지 확인 | 전부 빌드 + 스크린샷 비교 권고 | quality-engineer |

→ 9 개 병렬, 1-9 는 1-1~1-8 종료 후 순차.

### Phase 2 — 기존 화면 디자인 정합화 (Figma exports 도착 후 실행)

목표: 이미 구현된 8개 화면(인트로/로그인/회원가입/자녀홈/마이/비번변경/탈퇴완료)을 Figma 비교 검수 + 수정.

| # | 화면 | 비교 대상 Figma 노드 | 에이전트 |
|---|---|---|---|
| 2-1 | 인트로 (`HomePage`) | 426-20978, 426-21005 | frontend-architect |
| 2-2 | 로그인 | 662-8356 | frontend-architect |
| 2-3 | 회원가입 | (Figma에 명시 안 됨 — 사용자 확인 필요) | frontend-architect |
| 2-4 | 자녀 홈 | 426-20978, 426-21005 | frontend-architect |
| 2-5 | 마이페이지 | 773-11103 | frontend-architect |
| 2-6 | 비밀번호 변경 (6 variant) | 773-11124, 11134, 12009, 11733, 11519, 11626 | frontend-architect |
| 2-7 | 탈퇴 확인 다이얼로그 | 773-11838 | frontend-architect |
| 2-8 | 탈퇴 완료 | 773-11070 | frontend-architect |

→ 8 개 병렬. 각 에이전트는 (a) 해당 PNG export 를 Read 로 직독 (b) 현재 페이지와 diff (c) 수정 patch 적용.

### Phase 3 — 신규 화면: 알림 + 사용 리포트

| # | 작업 단위 | Figma 노드 | 에이전트 |
|---|---|---|---|
| 3-1 | NotificationsPage 스캐폴드 + 라우트 | 426-19287 (empty) | frontend-architect |
| 3-2 | NotificationsPage 데이터 있는 상태 | 426-19293 | frontend-architect |
| 3-3 | 알림 삭제 인터랙션 (swipe / 버튼) | 773-12916, 773-12903 | frontend-architect |
| 3-4 | BridgeNotificationTile 컴포넌트 | (위 4개 기반) | frontend-architect |
| 3-5 | NotificationMock 데이터 정의 | `notifications/data/mock/` | python-expert→Dart |
| 3-6 | UsageReportPage 스캐폴드 + 라우트 | 662-11497 | frontend-architect |
| 3-7 | 사용 리포트 차트 구현 (bar/donut — Figma 확인 필요) | 662-11497 | frontend-architect |
| 3-8 | UsageReportMock + Period selector | `report/data/mock/` | general-purpose |
| 3-9 | 하단 탭에 두 화면 연결 (셸 라우트) | app_router | backend-architect |

→ 9 개 병렬 (3-9 는 마지막).

### Phase 4 — 신규 화면: 시간 설정 v1 (16 화면, 최대 작업량)

플로우 가설(검증 필요): 진입 → 주별 총 시간 → 시간 바텀시트 → 주별 분배 완성 → 일별 분배 → 일별 바텀시트 (empty/시간설정/채움/filled) → 에러(초과/남음) → 완성/완료

| # | 작업 단위 | Figma 노드 | 에이전트 |
|---|---|---|---|
| 4-1 | TimeSetupRoot 페이지 (진입) | 695-8850 | frontend-architect |
| 4-2 | ScheduleRegister 화면 1, 2 | 695-8924, 695-9115 | frontend-architect |
| 4-3 | WeeklyTimeSetup 페이지 | 695-11870 | frontend-architect |
| 4-4 | TimeBottomSheet (시·분 휠) 컴포넌트 | 695-13485 | frontend-architect |
| 4-5 | WeeklyDistributionComplete 화면 | 695-8694 | frontend-architect |
| 4-6 | DailyTimeSetup 페이지 + 완료 후 스케쥴 | 695-9743, 695-11096 | frontend-architect |
| 4-7 | DailyDistributionBottomSheet (empty/설정/채움/filled 4 variant) | 695-12148, 12742, 13019, 13193 | frontend-architect |
| 4-8 | ErrorBanner: 초과 / 남음 2종 | 695-10675, 695-10817 | frontend-architect |
| 4-9 | 완성/완료 화면 | 695-11487, 695-12086 | frontend-architect |
| 4-10 | BridgeTimeBlock + BridgeWeekdaySelector 컴포넌트 | (전체 참조) | frontend-architect |
| 4-11 | TimeSetupViewModel (ChangeNotifier) + Mock 상태 머신 | 4-1~4-9 통합 | backend-architect |

→ 11 개 병렬. 4-10/4-11 은 4-1~4-9 와 부분 의존.

### Phase 5 — 시간 설정 v2 (수정 플로우, 9 화면) + 시간 설정 확인 (3 화면)

| # | 작업 단위 | Figma 노드 | 에이전트 |
|---|---|---|---|
| 5-1 | v2 진입 + 기존 스케쥴 로딩 표시 | 750-13034 | frontend-architect |
| 5-2 | v2 편집 화면 (4 variant) | 750-12671, 11991, 13450, 13105 | frontend-architect |
| 5-3 | v2 추가 변형 | 750-13686, 14708, 13854, 13624 | frontend-architect |
| 5-4 | v1→v2 컴포넌트 재사용 매핑 | — | refactoring-expert |
| 5-5 | TimeConfirm 화면 1 (요약) | 744-11326 | frontend-architect |
| 5-6 | TimeConfirm 화면 2, 3 | 662-11322, 662-11249 | frontend-architect |
| 5-7 | TimeConfirmViewModel (자녀 승인/요청 응답 액션 mock) | 5-5/5-6 통합 | backend-architect |
| 5-8 | 라우트 연결 + 진입점 | app_router | backend-architect |

→ 8 개 병렬.

### Phase 6 — 신규 화면: 미션 정보 / 수행 (8 화면, 카메라 연동)

| # | 작업 단위 | Figma 노드 | 에이전트 |
|---|---|---|---|
| 6-1 | MissionInfo 페이지 (정보 카드) | 746-11392 | frontend-architect |
| 6-2 | MissionPerform 페이지 (수행 입력) | 746-11380 | frontend-architect |
| 6-3 | 카메라 진입 화면 + 권한 안내 | 426-18960 | frontend-architect |
| 6-4 | 사진 촬영 후 확인 화면 | 426-19035 | frontend-architect |
| 6-5 | 제출 진행/완료 상태 | 426-18995, 426-18974 | frontend-architect |
| 6-6 | 승인 대기/완료 상태 | 426-19052, 426-19062 | frontend-architect |
| 6-7 | MissionViewModel + Mock 상태 머신 (info→perform→camera→submitted→reviewing→approved) | 통합 | backend-architect |
| 6-8 | 카메라 통합 — `image_picker` (source: camera only) 의존성 추가 + 권한 분기 | pubspec.yaml + 권한 헬퍼 | devops-architect |
| 6-9 | BridgeMissionCard 확장 (상태 8종) + assets | core/widgets | frontend-architect |

→ 9 개 병렬.

### Phase 7 — 통합 검증

| # | 작업 단위 | 에이전트 |
|---|---|---|
| 7-1 | 모든 화면 골든 스크린샷 캡처 + Figma export 와 시각 diff | quality-engineer |
| 7-2 | Mock 데이터 시드 정리 + 시나리오별 토글 (`AppFlags`) | backend-architect |
| 7-3 | 라우팅 그래프 검증 (모든 화면 도달 가능, 뒤로가기 일관성) | quality-engineer |
| 7-4 | A11y 1차 패스 (Semantics, contrast, 폰트 스케일) | quality-engineer |
| 7-5 | flutter analyze / dart format 통과 | refactoring-expert |
| 7-6 | 빌드 검증 — Android emulator + iOS simulator | devops-architect |
| 7-7 | docs/UI-figma.md 의 각 항목을 구현 PR 링크와 매핑한 트레이서빌리티 표 작성 | technical-writer |
| 7-8 | 누락 화면/상태 최종 점검 | requirements-analyst |

→ 8 개 병렬.

---

## 4. Mock 데이터 전략

- **위치**: `lib/features/<feature>/data/mock/<entity>_mock.dart`
- **포맷**: `const`로 정의된 데이터 리스트 + 시나리오 enum (`empty`, `partial`, `full`, `error`)
- **토글**: `lib/core/dev/app_flags.dart` 에서 시나리오 선택 → ViewModel 이 mock 소스 분기
- **금지**: page 파일 안에 hardcoded mock 추가 (child_home 의 현 패턴은 Phase 1 에서 정리)
- **모델 클래스**: 실제 백엔드 스키마 결정 전이므로 UI 표시 필드 위주로 단순화 (`MissionMock { id, title, reward, status, ... }`)

---

## 5. 일정 가이드 (참고용 — Figma exports 도착 가정)

| Phase | 병렬 에이전트 수 | 추정 단일 라운드 시간 |
|---|---|---|
| 0 | 9 | 30 분 |
| 1 | 9 | 60 분 |
| 2 | 8 | 90 분 (검수 다회) |
| 3 | 9 | 90 분 |
| 4 | 11 | 180 분 (최대 작업) |
| 5 | 8 | 120 분 |
| 6 | 9 | 120 분 (카메라 통합 변수) |
| 7 | 8 | 60 분 |

> 시간은 에이전트 동시 실행 시 wall-clock 기준. 검증/수정 반복은 미포함.

---

## 6. 즉시 실행 가능한 다음 액션

1. **[사용자]** Figma exports 옵션 A 채택 여부 결정 + `docs/figma-exports/` 에 PNG 업로드
2. **[클로드]** Figma 자료 도착과 무관하게 **Phase 0 (토큰·인프라 보강)** 즉시 착수 가능 — 사용자 승인 시 9 개 병렬 에이전트 실행
3. **[클로드]** Figma 자료 도착 후 **Phase 1 (컴포넌트 추출)** 시작 → 기존 화면이 우선 정합화됨
4. **[사용자]** 회원가입 화면이 Figma에 누락된 이유 확인 (별도 디자인이 있는지 / 디자인 무관하게 자체 구현인지)

---

## 7. 미해결 결정사항

- 상태관리 라이브러리: 백엔드 합류 시점에 Riverpod / Bloc 도입 여부 결정
- 다국어: 현재 모든 텍스트 한국어 하드코딩 — l10n 도입 시점 미정
- 다크모드: AppTheme.light() 만 존재. 디자인 시안에 다크 변형 있는지 확인 필요
- 자녀앱 ↔ 부모앱 연동 프로토콜: 본 작업 범위 외
- 카메라 권한 거부 시 폴백 UX: Figma 미커버 추정 — 사용자 확인 필요
