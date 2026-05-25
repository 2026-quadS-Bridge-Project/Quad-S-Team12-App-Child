# UI Figma Current Audit

작성일: 2026-05-20

대상: `docs/UI-figma.md`의 Figma 링크 53개와 현재 Flutter 구현.

검증 방식:
- `docs/UI-figma.md` 링크를 노드 단위로 분리
- `docs/figma-specs/*`의 기존 Figma 추출 스펙과 현재 코드 대조
- Figma MCP metadata로 대표 노드 재확인: `662:8356`, `426:20978`, `426:21005`, `695:9743`, `695:12742`, `662:11497`, `426:18960`
- 실제 픽셀 스크린샷 diff는 아직 수행하지 않음. 아래는 Phase 0/1/2/3/4 반영 후 코드/스펙 기반 감사 결과

## Phase 0/1/2/3/4 갱신 요약

현재 문서는 Phase 4 미션 정리 후 worktree 기준이다. 실제 픽셀 스크린샷 diff는 아직 수행하지 않았다.

### 고정됨

- 공통: `BridgeAppBar` title weight가 `headlineMedium`으로 변경됨. 시작 화면 Bridge 아이콘은 90x90으로 조정됨.
- 레거시 route: `/child-home/onboarding` 직접 접근 후 dismiss 시 `/child-home`으로 route가 정리됨.
- 시간 설정 진입: v1/v2 모두 `TimeSetupIntroPage`를 거치며, v2 intro와 schedule step copy가 Figma v2 문구로 분기됨.
- 시간 설정 Step 1: grid label이 `7..12, 1..11` 계열로 바뀌고 empty/selected cell color가 Figma 방향으로 정리됨.
- 시간 설정 Step 2: `BridgeTotalTimeCard.compact` 50px bordered box와 50px/radius 12 `BridgeWeekRow`가 적용됨. v2는 1주차를 dim/locked 처리하고 2-4주차만 편집함.
- 시간 선택 sheet: `BridgeTimeBottomSheet`와 `BridgeTimeAllocBottomSheet.timePicker` 모두 `시간`/`분` label overlap 방지 좌표 방식으로 통일됨.
- 시간 설정 Step 3: `일별 시간 분배` header, `스케줄 보기`, v2 `사용리포트 보기`, rows frame, delta frame/banner 구조가 반영됨.
- Controller/model: per-week totals, v2 locked past week, remaining cap, auto-distribute, day allocation regroup/replace, current-week delta validation이 추가됨.
- 시간 확인 filled: compact total time card를 사용하도록 맞춰짐.
- 알림 filled: Figma 6종 순서/child-facing copy가 `NotificationsMock`에 반영되고 `weeklyReport`, `missionRejected` 타입/색상/deeplink가 추가됨.
- 리포트: 첫 card y offset이 `SafeArea(top:false)` + top padding 0으로 Figma Side Panel 시작점에 가까워졌고, Plan/Analysis/Suggestion header copy, time row `시간/분` 표시, on-plan marker, under-plan delta color가 보정됨. cat은 emoji placeholder에서 `assets/icons/cat.svg` 렌더링으로 교체됨.
- 시간 확인 empty/filled/onboarding: empty가 text-only + `확인` CTA로 맞춰지고, filled divider/`일간 사용 계획` title/per-week total lookup이 반영됨. onboarding tooltip은 dark surface, title, bullet, underline, close X, top arrow 구조로 개선됨.
- 미션 수행: info tab 190px centered tabbar, camera prompt upload y offset, dashed upload tile, `ImageSource.camera` only capture, submit gating, photo grid 12px gap, max 4/delete/add tile, submitted/completed copy/CTA/status 진입 분기가 반영됨.

### 부분 고정 / 재검증 필요

- 시간 설정 화면 전반은 구조가 Figma에 가까워졌지만 spacing/y offset은 screenshot diff로 재확인 필요.
- v2 weekly 화면은 remaining budget/auto-calc 상태와 2-4주차 합계 validation을 실제 walkthrough로 확인해야 함.
- daily/reference sheets는 placeholder에서 실제 preview sheet로 개선됐지만 Figma 원본과 동일한 modal인지 별도 확인 필요.
- review 화면은 compact card/header 구조가 반영됐지만 `스케줄 보기` pill action과 exact read-only layout은 후속 점검 필요.
- 알림은 6종 mock/copy와 delete confirm secondary-yellow warning icon이 맞춰졌지만 list start y, card height/gap은 screenshot diff 필요.
- 리포트는 첫 card y offset과 주요 copy가 보정됐지만 card heights, chart/list pixel parity, `cat.svg`가 Figma multi-color illustration과 같은지 screenshot diff가 필요.
- 시간 설정 confirm empty/onboarding variant는 시각 구조가 개선됐지만 여전히 query/test constructor 중심 접근이다. tooltip 위치/크기와 `수정하기` pill token은 screenshot diff 필요.
- 미션 camera/photo/submitted flow는 코드/스펙 기준 대부분 맞춰졌지만 native camera permission/device walkthrough, captured image rendering, submitted icon/text exact y/order는 screenshot diff 필요.

### 후속 Phase 미해결

- 리포트: card/chart/list pixel diff, cat illustration asset fidelity.
- 알림: list/card exact pixel diff와 swipe threshold 정책.
- 시간 확인: empty/onboarding 자연 진입 정책, tooltip/pill exact pixel diff.
- 미션: rejected detail 디자인 부재. 반려 사유/재시도 UX는 Figma node가 없는 제품/디자인 gap.
- Auth/account: 실제 login/signup form은 Figma 문서에 없고, 비밀번호 변경 title copy(`수정` vs `변경`) 판단 필요.
- 통합: 53개 route walkthrough, analyzer/test, screenshot diff 후보 재감사.

## 우선순위 이슈

| 상태 | 우선순위 | 이슈 | 메모 |
|---|---|---|---|
| 고정 | P0 | 시간 설정 v1 인트로 미노출 | v1 기본 step이 `intro`로 바뀌고 root에서 intro를 렌더링함. |
| 고정 | P0 | `/child-home/onboarding` dismiss 후 route 미전환 | dismiss callback으로 `/child-home` 전환. 호출 경로 부재는 legacy 판단으로 남음. |
| 고정 | P0 | `BridgeTotalTimeCard`가 Figma time box와 다름 | compact variant가 주별/일별/확인 화면에 적용됨. |
| 고정 | P0 | 주별 row 높이/radius가 Figma보다 큼 | 50px/radius 12 row로 변경됨. |
| 부분 고정 | P0 | 일간 시간 설정 header/pill/rows frame 구조 | header/action/frame은 반영. exact spacing과 reference modal parity는 재검증 필요. |
| 고정 | P1 | `BridgeTimeAllocBottomSheet` 시간 label overlap 가능 | weekly/daily time picker label 배치가 동일한 band-coordinate 방식으로 정리됨. |
| 고정 | P1 | v2 intro copy가 Figma v2가 아니라 v1 문구 | mode별 copy 분기 적용. |
| 부분 고정 | P1 | 시간 grid label/color drift | label/color/hatch는 수정. 전체 높이와 scroll frame은 screenshot diff 필요. |
| 고정 | P1 | 공통 AppBar title weight가 medium이 아니라 bold | `headlineMedium` 적용. |
| 고정 | P1 | 알림 Figma 6종 mock/copy 누락 | child-facing 6종 mock, `weeklyReport`/`missionRejected` 타입, deeplink가 반영됨. |
| 부분 고정 | P1 | 리포트 cat asset placeholder와 시작 y offset | 시작 y offset, emoji placeholder, 주요 row indicator는 개선됨. `cat.svg` fidelity와 card/chart spacing은 screenshot diff 필요. |
| 부분 고정 | P1 | 시간 확인 empty/onboarding drift | text-only empty, CTA, divider/title, dark tooltip 구조는 반영. 자연 진입 경로, pill token, exact placement는 남음. |
| 대체로 고정 | P2 | 미션 camera prompt/photo/submitted flow | centered tabbar, upload y offset, camera-only capture, photo grid 12px gap, max 4/delete/add tile, submit gating, submitted/completed copy/status 진입이 반영됨. device/screenshot diff는 필요. |
| 미해결 | P2 | 미션 rejected full-screen design 부재 | `11-mission.md`에도 explicit rejected node가 없음. 반려 사유/재시도 UX 제품/디자인 결정 필요. |

## Route/State 역방향 체크

`UI-figma.md`의 53개 노드에서 시작하는 전수 체크와 별개로, 현재 앱 route와 controller state에서만 드러나는 화면/상태를 역방향으로 확인했다.

### 현재 route 목록

| Route / 상태 | 현재 화면 | Figma 문서 매핑 | 체크 결과 |
|---|---|---|---|
| `/` | `HomePage` intro/start | `662:8356` | `UI-figma.md`에는 `로그인`으로 적혀 있지만 실제로는 start/intro 화면. 매핑됨. |
| `/login` | 실제 로그인 폼 | 없음 | Figma 문서에 실제 로그인 form 화면이 없음. 현재 구현은 별도 앱 전용 화면이라 parity 판단 불가. |
| `/signup` | 실제 회원가입 폼 | 없음 | Figma 문서에 회원가입 form 화면이 없음. 현재 구현은 별도 앱 전용 화면이라 parity 판단 불가. |
| `/mypage` | 마이페이지 | `773:11103` | 매핑됨. |
| `/mypage/password` | 비밀번호 변경 form states | `773:11124`, `773:11134`, `773:12009`, `773:11733`, `773:11519`, `773:11626` | 매핑됨. 단 Figma copy는 `비밀번호 수정`, 현재 copy는 `비밀번호 변경`. |
| `/mypage/delete-complete` | 탈퇴 완료 | `773:11070` | 매핑됨. |
| `/child-home` | 홈 기본 route | `426:20978`, `426:21005` | 부분 매핑. 현재 기본값은 `showContent=true`, `_hasSchedule=false`라 Figma home2의 donut 화면은 debug long-press 전에는 바로 보이지 않음. |
| `/child-home/onboarding` | 홈 + 부모 연결 guide overlay | 명확한 개별 노드 없음 | 부분 고정. overlay 전용 Figma는 없지만, 직접 접근 후 dismiss 시 `/child-home`으로 route가 정리됨. |
| `/child-home/report` | 사용 리포트 | `662:11497` | 부분 고정. first card y offset, header copy, cat SVG 렌더링이 개선됨. card/chart/list pixel diff와 cat asset fidelity는 남음. |
| `/child-home/notifications` | 알림 filled/empty/delete | `426:19287`, `426:19293`, `773:12916`, `773:12903` | 부분 고정. Figma 6종 mock/copy, type color, delete confirm warning color는 반영됨. list exact spacing과 swipe threshold 정책은 남음. |
| `/child-home/time-setup` | v1 시간 설정 wizard | `695:*` v1 그룹 | 부분 고정. v1 intro, grid, weekly, daily 구조가 반영됨. pixel diff는 남음. |
| `/child-home/time-setup/v2` | v2 시간 설정 wizard | `750:*` v2 그룹 | 부분 고정. v2 copy, locked past week, editable weeks, reference actions가 반영됨. walkthrough 필요. |
| `/child-home/time-setup/confirm` | 시간 설정 확인 | `744:11326`, `662:11322`, `662:11249` | 부분 고정. empty CTA/divider/title/dark tooltip이 개선됨. empty/onboarding은 여전히 `?variant=empty|onboarding` query로만 접근 가능. |
| `/child-home/mission/:id` | 미션 정보/수행 flow | `746:*`, `426:*` mission 그룹 | 매핑됨. camera/photo/submitted flow는 코드상 구현됨. reviewing/completed mock은 submitted/completed 화면으로 직접 진입하고, rejected는 Figma detail node가 없어 정보 tab fallback으로 둠. |

### 앱에는 있는데 Figma 문서에 없는 화면/상태

| 앱 상태 | 위치 | 판단 |
|---|---|---|
| 실제 로그인 form + 로그인 error toast | `lib/features/login/presentation/pages/login_page.dart` | `UI-figma.md`의 `로그인` 노드는 실제 로그인 form이 아니라 start 화면이다. 별도 Figma 필요. |
| 실제 회원가입 form + validation states | `lib/features/signup/presentation/pages/signup_page.dart` | 회원가입 CTA는 Figma start 화면에 있지만 회원가입 form node는 문서에 없다. 별도 Figma 필요. |
| 홈 onboarding overlay | `lib/features/child_home/presentation/pages/child_home_page.dart` | 부모 연결 guide bubble 상태가 route로 존재하지만 `UI-figma.md`에 개별 링크가 없다. dismiss route는 Phase 0에서 정리됨. |
| 시간 설정 `review` step | `lib/features/time_setup/presentation/pages/time_setup_review_page.dart` | v1의 `695:11487`과 매핑할 수는 있지만, Figma상 "valid filled state"인지 "별도 review step"인지 애매하다. 현재 앱은 별도 step으로 분리됨. |
| 시간 설정 확인 query variants | `lib/features/time_confirm/presentation/pages/time_confirm_page.dart:49` | Figma 3개 상태가 구현되어 있고 Phase 3에서 empty/onboarding visual이 개선됨. 다만 앱 내 버튼으로 empty/onboarding variant에 들어가는 경로는 없음. |
| 미션 rejected detail | `lib/features/mission/data/mock/mission_mock.dart:16` | home/mock에는 rejected 상태가 있는데 `UI-figma.md`와 `11-mission.md`에는 rejected detail node가 없다. 현재 별도 반려 사유/재시도 화면은 없으므로 제품/디자인 gap. |

### Figma에는 있는데 현재 앱에서 바로 도달하기 어려운 화면/상태

| Figma 상태 | Node | 현재 접근성 |
|---|---|---|
| 스케줄 등록 empty | `695:8924` | 새 v1 시작 시 가능. |
| 스케줄 등록 filled | `695:9115` | 셀 선택 후 가능. |
| 주별 bottom sheet | `695:13485`, `750:13450` | 주별 row tap으로 가능. |
| 일별 bottom sheet empty/time/filled | `695:12148`, `695:12742`, `695:13019` | plus/edit tap으로 가능. time mode label overlap은 Phase 2에서 고정됨. |
| 알림 empty | `426:19287` | route 진입 기본은 filled mock. 모든 알림 삭제 후 가능. |
| 시간 설정 확인 empty/onboarding | `744:11326`, `662:11249` | URL query나 test constructor로만 쉽게 접근 가능. 앱 내 자연 진입은 filled. Phase 3 visual 개선 후에도 접근 정책은 미정. |
| 미션 photo 3/4 variants | `426:18995`, `426:18974` | 실제 카메라로 여러 장 추가하면 도달 가능. mock/deeplink는 없고 device camera walkthrough 필요. |

## 레거시/Dead Screen 체크

현재 `lib/features/**/presentation/pages/*.dart` 기준으로 파일 단위에서 완전히 orphan 된 page 파일은 보이지 않는다. 모든 page 파일은 `GoRouter` route이거나, 시간 설정 wizard root에서 step child로 사용된다. 다만 route/state 단위에서는 아래처럼 과거 흐름 또는 문서화되지 않은 상태가 남아 있다.

### Onboarding 관련 결론

말씀한 "스텝만 안내하고 실제 화면으로 안 넘어가는" 계열은 현재 두 갈래로 확인된다.

| 대상 | 현재 상태 | 판단 | 권장 정리 |
|---|---|---|---|
| 홈 부모연결 onboarding | `/child-home/onboarding`이 `ChildHomePage(showOnboarding:true, showContent:false)`로 남아 있음. 현재 생산 코드에서 이 route로 `go/push`하는 call site는 없음. | route 자체는 legacy/dead 가능성이 높지만, 직접 접근 dismiss 후 `/child-home` 전환은 고정됨. | 첫 부모연결 튜토리얼이 필요하면 auth/onboarding gate에서 명시적으로 진입. 필요 없으면 route 제거. |
| 시간 설정 v1 intro | Figma `695:8850`은 3단계 안내 + `시작` CTA. | 고정됨. v1 controller 기본 step이 `intro`이고 root에서 `TimeSetupIntroPage`를 렌더링함. | exact spacing만 screenshot diff로 확인. |
| 시간 설정 v2 intro | `/child-home/time-setup/v2`는 `TimeSetupController.v2NextWeek`로 `intro`에 진입하고, `시작` 버튼이 `scheduleRegister`로 이동함. | 고정됨. mode별 v2 subtitle copy가 적용됨. | exact spacing만 screenshot diff로 확인. |

### 기타 남은 레거시/애매한 상태

| 대상 | 근거 | 판단/조치 |
|---|---|---|
| 시간 확인 empty/onboarding variant | `TimeConfirmPage`가 `?variant=empty|filled|onboarding` query로만 초기 variant를 고름. | Figma 상태와 tooltip visual은 Phase 3에서 가까워짐. 앱 내 자연 진입 경로는 filled 중심이라 첫 방문 tooltip/empty 조건을 실제 데이터와 연결할지 결정 필요. |
| 미션 rejected detail | mock에는 `MissionStatus.rejected`가 있고 홈 카드 상태도 존재하지만, full-screen rejected Figma node는 없음. 현재 별도 반려 사유/재시도 화면은 없고 rejected mission detail은 정보 tab fallback으로 진입함. | 레거시라기보다는 미정 디자인 상태. 반려 사유/재시도 UX가 필요하면 Figma node 추가 필요. |
| 알림 mock/copy | 현재 child 앱 mock은 Figma filled의 6종 child-facing 알림으로 교체됨. | backend deeplink/service 연결 전까지는 mock 기반이다. delete dialog icon color와 exact list spacing은 별도 재검증 필요. |
| 과거 audit 문서 | `_audit-routing.md` 등 일부 문서는 예전 `/child-home/onboarding` 진입 흐름과 signup 동작을 기준으로 쓴 내용이 남아 있음. | 현재 소스 기준으로는 로그인/회원가입/캐시 로그인 모두 `/child-home`으로 이동함. 최신 판단은 이 문서를 기준으로 보는 것이 안전함. |

## 화면별 체크표

| # | UI-figma 항목 | Figma node | 현재 구현 | 판정 | 체크 내용 |
|---:|---|---|---|---|---|
| 1 | 로그인 | `662:8356` | `HomePage` intro | 부분 고정 | Figma상 실제 intro/start 화면. Bridge 아이콘은 90x90으로 조정됨. 실제 로그인/회원가입 화면은 이 문서에 별도 Figma가 없음. |
| 2 | 홈 | `426:20978` | `ChildHomePage(showContent:false/onboarding)` 계열 | 대체로 양호 | topbar y=56, 컨테이너 y=108 계열은 현재 구조와 근접. 단 empty state plus와 settings/report affordance는 현재 상태 분기와 실제 진입 경로 재확인 필요. |
| 3 | 홈 2 | `426:21005` | `ChildHomePage(showContent:true)` | 부분 고정 | Figma 컨테이너 y=118에 맞춰 content gap이 30px로 조정됨. donut 상태는 `_hasSchedule=false` 기본값 때문에 일반 사용자에게 바로 노출되지 않음. |
| 4 | 마이페이지 | `773:11103` | `MyPage` | 양호 | 로그아웃 버튼은 현재 제거되어 Figma와 맞음. AppBar title weight도 공통 수정 반영. |
| 5 | 비밀번호 변경 empty | `773:11124` | `PasswordChangePage` | 부분 불일치 | Figma title은 `비밀번호 수정`, 현재 `비밀번호 변경`. field top/gap은 실제 화면에서 확인 필요. |
| 6 | 비밀번호 변경 typing | `773:11134` | `PasswordChangePage` | 부분 불일치 | neutral helper 처리 로직은 현재 개선되어 있으나 copy/title 차이와 helper reserved height를 실제 화면에서 확인 필요. |
| 7 | 비밀번호 변경 완료 | `773:12009` | `PasswordChangePage` | 부분 불일치 | 버튼 enabled/field neutral 상태는 구조상 가능. title copy 차이 유지. |
| 8 | 비밀번호 변경 기존 비밀번호 error | `773:11733` | `PasswordChangePage` | 부분 불일치 | error helper/border는 구현됨. Figma variant의 placeholder-only error와 현재 입력값 유지 정책이 다를 수 있음. |
| 9 | 비밀번호 변경 새 비밀번호 error | `773:11519` | `PasswordChangePage` | 부분 불일치 | same-as-current error 로직 구현됨. title copy 차이. |
| 10 | 비밀번호 변경 확인 error | `773:11626` | `PasswordChangePage` | 부분 불일치 | mismatch error 구현됨. title copy 차이. |
| 11 | 탈퇴 dialog | `773:11838` | `_DeleteAccountDialog` | 대체로 양호 | dialog 크기는 Figma fractional 값을 따름. warning icon이 Figma yellow 계열인지 현재 destructive red 계열인지 재확인 필요. |
| 12 | 탈퇴 완료 | `773:11070` | `DeleteAccountCompletePage` | 대체로 양호 | centered text/redirect 구현. weight와 exact y는 screenshot diff 필요. |
| 13 | 알림 empty | `426:19287` | `NotificationsPage` empty state | 양호 | empty copy/text-only 구조 일치. 현재 mock 기본은 filled라 empty state는 삭제 후 접근. |
| 14 | 알림 filled | `426:19293` | `NotificationsPage` + `NotificationCard` | 부분 고정 | Figma 6종 mock/copy, `weeklyReport`/`missionRejected` type color, report/time deeplink가 반영됨. list start y/card gap은 screenshot diff 필요. |
| 15 | 알림 swipe delete | `773:12916` | `NotificationCard` drag state | 양호 | custom horizontal drag + reveal 구현. max slide는 Figma scale 값을 따름. |
| 16 | 알림 delete confirm | `773:12903` | `_DeleteNotificationDialog` | 대체로 양호 | dialog 구조, scrim token, secondary-yellow warning icon이 구현됨. fractional sizing은 screenshot diff 필요. |
| 17 | 사용 리포트 | `662:11497` | `ReportPage` | 부분 고정 | Side Panel y offset은 `SafeArea(top:false)`와 top padding 0으로 개선됨. cat은 `assets/icons/cat.svg`로 렌더링되고 주요 card caption/summary copy, row time text, on-plan marker가 보강됨. card heights/chart/list/cat fidelity는 screenshot diff 필요. |
| 18 | 시간 설정 intro v1 | `695:8850` | `TimeSetupIntroPage` | 고정 | `/child-home/time-setup` 기본 flow가 intro에서 시작하고 `시작` CTA로 schedule register에 진입함. |
| 19 | 스케줄 등록 empty | `695:8924` | `ScheduleRegisterPage` | 부분 고정 | Grid label/color/hatch가 Figma 방향으로 수정됨. 전체 frame 높이와 scroll 처리만 screenshot diff 필요. |
| 20 | 스케줄 등록 filled | `695:9115` | `ScheduleRegisterPage` | 부분 고정 | selected cell이 primary로 변경됨. grid frame/spacing은 screenshot diff 필요. |
| 21 | 초기 주별 사용시간 설정 | `695:11870` | `WeeklyTimeSetupPage` | 부분 고정 | `2월 총 사용 시간`, 50px bordered compact card, 50px week rows, weekly header가 반영됨. exact spacing은 재확인 필요. |
| 22 | 초기 시간 설정 bottom sheet | `695:13485` | `BridgeTimeBottomSheet` | 고정 | 시간/분 label overlap 방지 좌표 방식 적용. title 띄어쓰기만 copy 판단 필요. |
| 23 | 주별 시간 분배 완성 | `695:8694` | `WeeklyTimeSetupPage` | 부분 고정 | per-week filled state 가능. v1 auto-calc disabled/active 정책은 Figma 상태와 재확인 필요. |
| 24 | 일간 시간 설정 empty | `695:9743` | `DailyTimeSetupPage` | 부분 고정 | `일별 시간 분배` header, `스케줄 보기` pill, rows frame/add button 구조가 반영됨. exact y offset은 재확인 필요. |
| 25 | 일별 시간 설정 완료 스케줄 화면 | `695:11096` | `DailyTimeSetupPage` filled | 부분 고정 | grouping/validation과 header/pill/frame이 반영됨. row spacing은 screenshot diff 필요. |
| 26 | 일별 bottom sheet empty | `695:12148` | `BridgeTimeAllocBottomSheet.dayPicker` | 부분 고정 | weekday selector + time row + sheet chrome 유지. exact chip spacing 확인 필요. |
| 27 | 일별 bottom sheet time | `695:12742` | `BridgeTimeAllocBottomSheet.timePicker` | 고정 | 시간/분 label 배치를 `BridgeTimeBottomSheet`와 같은 좌표 기반 band label로 통일함. |
| 28 | 일별 bottom sheet filled | `695:13019` | `BridgeTimeAllocBottomSheet.dayPicker` | 부분 고정 | commit 후 dayPicker로 돌아오는 상태 있음. exact chip/time row 색상은 screenshot diff 필요. |
| 29 | 일별 분배 filled | `695:13193` | `DailyTimeSetupPage` | 부분 고정 | grouping 로직과 layout header/pill/frame이 반영됨. exact spacing은 재확인 필요. |
| 30 | 일별 error 초과 | `695:10675` | `DailyTimeSetupPage` | 부분 고정 | over delta banner, disabled CTA, red rows frame이 구현됨. exact annotation/spacing 확인 필요. |
| 31 | 일별 error 남음 | `695:10817` | `DailyTimeSetupPage` | 부분 고정 | under banner와 primary rows frame이 구현됨. exact spacing 확인 필요. |
| 32 | 초기 시간 설정 완성 | `695:11487` | `TimeSetupReviewPage` | 부분 고정 | compact total card와 read-only day rows 적용. `스케줄 보기` action과 exact review layout은 후속 점검 필요. |
| 33 | 초기 시간 설정 완료 | `695:12086` | `TimeSetupCompletePage` | 양호 | 완료 화면 구조/문구는 대체로 맞음. check icon size와 vertical center는 screenshot diff 필요. |
| 34 | 시간 설정 v2 intro | `750:13034` | `TimeSetupIntroPage` | 고정 | v2 전용 subtitle(`저번주 피드백...`)로 분기됨. exact spacing은 screenshot diff 필요. |
| 35 | 시간 설정 v2 step1 | `750:12671` | `ScheduleRegisterPage` with previous data | 부분 고정 | previous schedule seed와 v2 description copy가 반영됨. grid frame/spacing은 재확인 필요. |
| 36 | 시간 설정 v2 step2 empty | `750:11991` | `WeeklyTimeSetupPage` v2 mode | 부분 고정 | `2월 잔여 시간`, locked 1주차, editable 2-4주차, compact total/rows가 반영됨. remaining budget/auto-calc walkthrough 필요. |
| 37 | 시간 설정 v2 weekly bottom sheet | `750:13450` | `BridgeTimeBottomSheet` | 고정 | shared bottom sheet label overlap이 고정됨. background weekly exact layout은 재확인 필요. |
| 38 | 시간 설정 v2 step2 filled | `750:13105` | `WeeklyTimeSetupPage` v2 mode | 부분 고정 | past week dim, 4 rows, compact card가 반영됨. auto-calc enabled/disabled 상태는 walkthrough 필요. |
| 39 | 시간 설정 v2 daily over | `750:13686` | `DailyTimeSetupPage` v2 mode | 부분 고정 | `스케줄 보기`, `사용리포트 보기`, real preview sheets, over frame/banner가 반영됨. exact modal parity는 재확인 필요. |
| 40 | 시간 설정 v2 daily under | `750:14708` | `DailyTimeSetupPage` v2 mode | 부분 고정 | under frame/banner와 reference actions가 반영됨. exact spacing 재확인 필요. |
| 41 | 시간 설정 v2 daily filled | `750:13854` | `DailyTimeSetupPage` / `TimeSetupReviewPage` | 부분 고정 | happy path와 v2 reference affordance가 구현됨. review path/exact layout 재확인 필요. |
| 42 | 시간 설정 v2 complete | `750:13624` | `TimeSetupCompletePage` | 양호 | v1/v2 completion copy 통일되어 있음. |
| 43 | 시간 설정 확인 empty | `744:11326` | `TimeConfirmPage?variant=empty` | 부분 고정 | text-only empty message와 `확인` CTA가 맞춰짐. exact y는 screenshot diff 필요. |
| 44 | 시간 설정 확인 filled | `662:11322` | `TimeConfirmPage` filled | 부분 고정 | divider, `일간 사용 계획` title, compact 50px total card, first-week total lookup이 반영됨. exact y/spacing은 screenshot diff 필요. |
| 45 | 시간 설정 확인 onboarding | `662:11249` | `TimeConfirmPage?variant=onboarding` | 부분 고정 | dark tooltip, title/bullets/underline/close X/top arrow 구조가 반영됨. `수정하기` pill은 Figma gray disabled-like surface 대비 현재 ghost/active 성격이고 tooltip placement는 screenshot diff 필요. |
| 46 | 미션 정보 tab | `746:11392` | `MissionInfoPage` info tab | 대체로 양호 | 190px centered tabbar와 5 sections/chips 구현. exact chip widths는 Wrap 기반이라 Figma 고정 폭과 다를 수 있음. |
| 47 | 미션 수행정보 tab | `746:11380` | `MissionInfoPage` perform tab | 양호 | empty text + sticky CTA 구현. |
| 48 | 미션 camera prompt | `426:18960` | `_CameraPromptView` | 대체로 고정 | upload section y=304 목표 gap, dashed 2px upload tile, camera-only tap, disabled submit이 반영됨. exact y는 screenshot diff 필요. |
| 49 | 미션 photo 1 | `426:19035` | `_PhotoPreviewView` | 대체로 고정 | `ImageSource.camera` path를 `Image.file` tile로 렌더링하고 2-column grid/add tile/20px delete circle/submit enabled 구조가 있음. device image rendering 확인 필요. |
| 50 | 미션 photo 3 | `426:18995` | `_PhotoPreviewView` | 대체로 고정 | 2-column grid, `photoGap=12`, count<4 add tile, 20px delete circle이 반영됨. 실제 3-photo 진입은 반복 camera capture로 확인 필요. |
| 51 | 미션 photo 4 | `426:18974` | `_PhotoPreviewView` | 고정 | controller max 4 cap과 add tile 숨김이 구현됨. 삭제 시 add tile 재노출됨. |
| 52 | 미션 submitted/reviewing | `426:19052` | `_SubmittedView` reviewing | 대체로 고정 | submit 후 parent/AI 확인은 reviewing 상태, text block first + 60px check icon + `홈으로` CTA가 반영됨. reviewing mock은 이 화면으로 직접 진입함. exact y/order는 screenshot diff 필요. |
| 53 | 미션 completed | `426:19062` | `_SubmittedView` completed | 대체로 고정 | completed mock 직접 진입, self-confirm immediate complete, reward subtitle/`홈으로` CTA 분기가 있음. exact y/order는 screenshot diff 필요. |

## Phase 2 구현 메모

Phase 2에서 시간 설정 wizard는 "route reachable + 구조 parity"까지 올라왔다. v1/v2 intro, Step 1 grid, Step 2 compact weekly rows, Step 3 daily header/reference/error frame, bottom sheet label overlap, v2 locked past week/editable weeks, day allocation regroup validation이 반영됐다. 남은 일은 실제 device/simulator walkthrough와 screenshot diff로 spacing, modal parity, enabled/disabled state를 검증하는 것이다.

## Phase 3 구현 메모

Phase 3에서는 알림 filled mock/copy가 Figma 6종 child surface로 교체됐고 delete confirm warning icon도 secondary yellow로 정리됐다. 리포트는 first card y offset/copy/cat SVG/row indicator 방향으로 보정됐다. 시간 확인은 text-only empty, filled divider/title/weekly lookup, onboarding dark tooltip 구조가 반영됐다. 남은 일은 report cat asset fidelity와 chart/list/card pixel diff, notification swipe threshold, time-confirm empty/onboarding 자연 진입 정책 및 tooltip/pill screenshot diff다.

## Phase 4 구현 메모

Phase 4에서는 미션 수행 flow가 `11-mission.md`의 camera/photo/submitted lifecycle에 맞춰졌다. `CameraService.capturePhoto()`는 `ImageSource.camera`만 사용하고, mission flow에는 `ImageSource.gallery` 호출이 없다. `_InfoTabsBar`는 190px centered tabbar로 맞췄고, `_CameraPromptView`는 Figma y=304 목표 gap과 disabled submit을 반영했다. `_PhotoPreviewView`는 `photoGap=12`, 2-column grid, max 4 cap, 20px delete circle/add tile, submit gating을 사용한다. `_SubmittedView`는 text block first, 60px check icon, reviewing/completed copy와 `홈으로` CTA를 분기한다. controller는 reviewing/completed mock을 submitted 화면으로 직접 진입시키고, self-confirm mission은 제출 즉시 완료로 전환한다. 남은 일은 native camera permission/device walkthrough, screenshot diff, 그리고 rejected full-screen node 부재에 대한 제품/디자인 결정이다.

## 후속 수정 순서

1. 시간 설정 v1/v2 route walkthrough: intro -> schedule -> weekly -> daily -> review -> complete, v2 auto-calc/remaining budget 포함.
2. 시간 설정 screenshot diff: grid height, weekly row gaps, daily y offset, review read-only layout, confirm variants.
3. Phase 3 잔여: 리포트 cat asset fidelity/card-chart-list diff, notification swipe threshold, time confirm empty/onboarding 접근 정책과 tooltip/pill diff.
4. Phase 4 잔여: 미션 native camera device walkthrough/screenshot diff, rejected detail 디자인 결정.
5. Phase 5: 전체 53개 route 재감사, analyzer/test, 문서 최종 갱신.

## Phase 작업 상태

| Phase | 범위 | 상태 |
|---|---|---|
| 0. 공통 기반/레거시 | AppBar, intro icon, onboarding dismiss, 시간 설정 공통 컴포넌트 기반 | 완료 / screenshot 재확인 필요 |
| 1. 홈/Auth/계정 | #1-12 | 완료 반영. Figma에 없는 login/signup과 password copy 결정은 후속 판단 |
| 2. 시간 설정 v1/v2 | #18-42 | 완료 반영. walkthrough와 pixel diff는 남음 |
| 3. 알림/리포트/시간확인 | #13-17, #43-45 | 완료 반영. 알림 6종/delete icon, 리포트 y/copy/cat SVG/row indicator, 시간확인 empty/divider/tooltip 개선 완료. cat fidelity, 접근 정책, screenshot diff 남음 |
| 4. 미션 | #46-53 | 대부분 반영. camera/photo/submitted/completed flow는 코드/스펙 기준 고정 또는 대체로 고정. rejected detail은 Figma/product design gap으로 미해결 |
| 5. 통합 검증 | 전체 53개 | 대기 |
