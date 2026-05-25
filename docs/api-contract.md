# Bridge-K Child App — API Contract (Draft)

작성일: 2026-05-25 (refreshed)

> 본 명세는 클라이언트의 `Api*Repository` 구현과 cross-reference로 검증됨. endpoint/path/body/response shape은 코드와 100% 일치. 백엔드 명세 합의 후 변경되는 경우 코드와 본 문서를 동시 업데이트한다.

이 문서는 클라이언트(자녀 앱)가 가정한 백엔드 API 명세 초안이다. 실제 백엔드 명세와는 추후 조율한다. 클라이언트의 `Api*Repository` 구현은 이 문서를 따른다.

## 공통

### Base
- Base URL: `https://api.bridge-k.example.com` (`EnvironmentConfig.production`)
- Staging: `https://api.staging.bridge-k.example.com`
- Dev: `https://api.dev.bridge-k.example.com`

### 인증
- 모든 보호 endpoint는 `Authorization: Bearer <accessToken>` 헤더 필요.
- Access token이 만료(401)되면 클라이언트는 1회 `/auth/refresh`로 갱신 후 원 요청 재시도.
- Refresh 실패(401)면 로그아웃 후 시작 화면으로 이동.

### 요청/응답
- Content-Type: `application/json` (멀티파트는 `multipart/form-data`).
- 모든 날짜는 ISO-8601 (`2026-05-25T14:30:00Z`).
- 빈 응답이 적절한 경우 `204 No Content`.

### 표준 에러 응답
모든 4xx/5xx 응답은 다음 shape:
```json
{
  "error": {
    "code": "DUPLICATE_USERNAME",
    "message": "이미 사용 중인 아이디예요.",
    "details": { "field": "username" }
  }
}
```
- `code`: SCREAMING_SNAKE_CASE, 클라이언트가 분기에 사용.
- `message`: 한국어 사용자 친화 메시지. 그대로 노출 가능.
- `details`: 선택. 검증 실패 등에서 필드 정보.

### HTTP 상태
- `200 OK`: 데이터 응답.
- `201 Created`: 생성 성공 + 새 리소스.
- `204 No Content`: 성공 + 본문 없음.
- `400 Bad Request`: 잘못된 요청.
- `401 Unauthorized`: 토큰 만료/누락/무효 → refresh 시도.
- `403 Forbidden`: 권한 없음.
- `404 Not Found`: 리소스 없음.
- `409 Conflict`: 중복(예: username).
- `422 Unprocessable Entity`: 검증 실패. `details`에 필드 에러.
- `5xx`: 서버 에러. 사용자에겐 `'잠시 후 다시 시도해 주세요.'`.

---

## Auth

### `POST /auth/login`
- Body: `{ "username": "gdg12", "password": "Gdg123456789!" }`
- `200`: `{ "accessToken": "...", "refreshToken": "...", "username": "gdg12" }`
- `401 INVALID_CREDENTIALS`: 비밀번호 불일치 → `'비밀번호가 일치하지 않아요.'`
- `404 USER_NOT_FOUND`: 아이디 없음 → `'아이디를 다시 확인해 주세요.'`

### `POST /auth/signup`
- Body: `{ "username": "gdg12", "password": "Gdg123456789!" }`
- `201`: `{ "accessToken": "...", "refreshToken": "...", "username": "gdg12" }`
- `409 DUPLICATE_USERNAME`: `'이미 사용 중인 아이디예요.'`
- `422 INVALID_FORMAT`: `'아이디/비밀번호 형식이 올바르지 않아요.'`

### `POST /auth/refresh`
- Body: `{ "refreshToken": "..." }`
- `200`: `{ "accessToken": "...", "refreshToken": "..." }`  (refresh token rotation)
- `401 INVALID_REFRESH_TOKEN`: 강제 로그아웃.

### `POST /auth/logout`
- 토큰 blocklist 운영 시 사용. 운영 안 하면 클라이언트는 호출 안 해도 됨.
- Body: 빈 객체 `{}` (Authorization 헤더의 access token으로 식별)
- `204`: 서버 측 세션 무효화 완료. 클라이언트는 응답 후 로컬 토큰/세션 정리.

---

## Push Notification (FCM)

자녀 앱은 Firebase Cloud Messaging을 통해 OS push를 받는다. 백엔드(Spring + AWS)는 Firebase Admin SDK로 메시지를 전송한다.

### `POST /devices`
- 로그인 직후 + 토큰 회전 시 호출. 같은 device를 두 번 등록하면 백엔드는 기존 row를 갱신해야 함 (upsert).
- Body: `{ "fcmToken": "eXxxxx...", "platform": "ios" | "android" }`
- `201`: `{ "id": "device-uuid" }` — 클라이언트는 이 id를 `clearTokens` 시점에 `DELETE /devices/:id`로 정리할 때 사용.
- `409 ALREADY_REGISTERED`: 동일 fcmToken이 다른 user에 묶여있음. 백엔드가 transfer 처리. 클라이언트는 그냥 201 흐름과 동일하게 취급.

### `DELETE /devices/:id`
- 로그아웃 / 계정 탈퇴 시 호출. 실패해도 클라이언트 흐름은 진행 (fire-and-forget).
- `204`: 삭제 완료.

### Push payload 명세
서버가 FCM Admin SDK로 보내는 메시지는 다음 shape의 `data` 필드를 포함한다 (`notification` 필드는 OS가 자동으로 트레이에 띄울 때 사용):

```json
{
  "notification": {
    "title": "미션 완료",
    "body": "숙제하기 미션 수행을 AI가 확인했어요."
  },
  "data": {
    "type": "missionCompleted",
    "deeplink": "/child-home",
    "notificationId": "noti-uuid",
    "missionId": "mission-uuid"
  }
}
```

- `data.type`: NotificationType enum과 동일 — `weeklyReport` / `timeConfigured` / `missionCompleted` / `missionConfirmationRequested` / `missionRejected`.
- `data.deeplink`: 클라이언트가 알림 탭 시 라우팅할 경로. 기존 라우터의 path를 사용 (예: `/child-home/report`, `/child-home/time-setup/confirm`).
- `data.notificationId`: in-app 알림 row와 매칭. 클라이언트가 탭 시 자동으로 read 처리할 때 사용.
- `data.<entity>Id`: 필요한 도메인 id (mission, report, schedule 등).

### 클라이언트 동작 요약
- **Foreground**: in-app 토스트나 배지 새로고침. 알림 페이지 로드 트리거.
- **Background / Terminated**: OS가 자동 표시. 사용자가 탭 → 앱 진입 시 `data.deeplink`로 라우팅.
- **권한**: iOS는 첫 로그인 후 권한 요청. Android 13+는 `POST_NOTIFICATIONS` 권한 별도.

---

## Mission

### `GET /missions`
- 자녀에게 할당된 미션 목록(완료 포함, 오늘+최근).
- `200`: `{ "missions": Mission[] }`
- Mission shape: `mission.dart`의 `Mission.toJson()`과 동일.

### `GET /missions/:id`
- `200`: `Mission`
- `404 MISSION_NOT_FOUND`: `'미션을 찾을 수 없어요.'`

### `POST /missions/:id/submit`
- Body: `{ "photoUrls": ["https://cdn.../1.jpg", "https://cdn.../2.jpg"] }`
- `200`: 갱신된 `Mission` (status가 `reviewing` 또는 `completed`).
- `422 NO_PHOTOS`: `'사진을 한 장 이상 첨부해 주세요.'`

---

## Time Setup

### `GET /time-setup/previous-week`
- 직전 주차 스케줄 (v2 진입용).
- `200`: `TimeSchedule` (이전 주차 1개 row만 채워져 있어도 됨; 4주 budget 포함)

### `GET /time-setup/current`
- 현재 진행 중 월의 사용자 스케줄.
- `200`: `TimeSchedule` 또는 `null` (이번달 미설정)
- 응답 본문: `{ "schedule": null | TimeSchedule }`로 wrap.

### `POST /time-setup`
- Body: `TimeSchedule` (전체 저장).
- `200`: 저장된 `TimeSchedule` (서버가 정규화/검증 후 echo).
- `422 INVALID_SCHEDULE`: `'주별 합이 월 한도와 맞지 않아요.'`

---

## Time Confirm

### `GET /time-confirm/current`
- 자녀가 확인할 (부모가 설정한) 스케줄.
- `200`: `TimeConfirmData` shape — `{ "schedule": null | TimeSchedule }`.

### `POST /time-confirm/request-modification`
- Body: 빈 객체 `{}` (필요 시 사유 추가)
- `204`: 부모에게 수정 요청 알림 전송.
- `409 ALREADY_REQUESTED`: `'이미 수정 요청 중이에요.'`

### `POST /time-confirm/acknowledge`
- Body: 빈 객체 `{}`
- `204`: 자녀가 스케줄을 확인했음을 기록.

---

## Notification

### `GET /notifications`
- 최신순으로 정렬된 알림 목록.
- `200`: `{ "notifications": NotificationItem[] }`
- NotificationItem shape는 `notification_item.dart`의 `toJson()`과 동일. `createdAt`은 ISO-8601.

### `DELETE /notifications/:id`
- `204`: 삭제 완료.
- `404 NOTIFICATION_NOT_FOUND`: `'이미 삭제된 알림이에요.'`

### `PATCH /notifications/:id/read`
- `204`: 읽음 처리.
- `404 NOTIFICATION_NOT_FOUND`: 존재하지 않는 알림.

---

## Usage Report

### `GET /reports/weekly`
- 이번 주 사용 리포트.
- Query: `weekOf=2026-05-25` (선택; 없으면 이번 주 기준).
- `200`: `UsageReport` (전체 카드 데이터)
- `404 REPORT_NOT_READY`: `'아직 이번 주 리포트가 준비되지 않았어요.'`

---

## My Page

### `GET /user/profile`
- 본인 프로필.
- `200`: `UserProfile` shape — `{ "username": "...", "accountType": "자녀회원", "childCode": "XY785eZ" }`.

### `PATCH /user/password`
- Body: `{ "currentPassword": "...", "newPassword": "..." }`
- `204`: 변경 완료.
- `401 WRONG_CURRENT_PASSWORD`: `'현재 비밀번호가 일치하지 않아요.'`
- `422 SAME_AS_CURRENT`: `'기존 비밀번호와 다르게 설정해 주세요.'`
- `422 INVALID_FORMAT`: `'비밀번호 형식이 올바르지 않아요.'`

### `DELETE /user/account`
- `204`: 탈퇴 처리. 서버에서 모든 세션/데이터 정리.
- 클라이언트는 응답 후 `AuthSession.clearLogin()` + `clearTokens()`.

---

## Photo Upload

### `POST /uploads/photo`
- Content-Type: `multipart/form-data`
- 필드: `file` (이미지 바이너리), 선택적으로 `purpose=mission`.
- `201`: `{ "url": "https://cdn.bridge-k.example.com/photos/abc123.jpg" }`
- `413 PAYLOAD_TOO_LARGE`: `'사진 용량이 너무 커요.'`
- `415 UNSUPPORTED_MEDIA`: `'지원하지 않는 사진 형식이에요.'`

---

## 클라이언트 매핑 정책

- 에러 응답의 `error.message`를 그대로 `Result.failure(message)`에 넣는다.
- 일부 endpoint(예: Auth login)는 클라이언트의 UI가 `code`별 분기를 필요로 하므로 `Failure`의 `cause`에 `code`를 함께 실어 보낸다.
- 네트워크 에러(연결 실패/타임아웃)는 `'네트워크 연결을 확인해 주세요.'`로 통일.
- 알 수 없는 에러: `'잠시 후 다시 시도해 주세요.'`.

---

## 후속 사항

- 페이지네이션이 필요한 endpoint(`/notifications`, `/missions`)는 추후 cursor 기반(`?cursor=...&limit=20`)으로 확장.
- 실시간 미션 승인 통지는 WebSocket 또는 SSE로 분리. 본 contract는 풀(`GET /missions/:id`) 기반.
- Refresh token 회전(rotation) 정책: 새 access token 발급 시 refresh token도 새로 발급.
- `/auth/logout` 클라이언트 호출처는 현재 코드에 없음 (서버 token blocklist 운영 결정 후 추가).

---

## Appendix A: 모델 JSON shape

클라이언트의 `fromJson` / `toJson`이 받아들이는 정확한 wire format. 백엔드가 응답 정의 시 이 shape을 따른다.

### `AuthToken` — Auth login/signup/refresh 응답

```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi...",
  "username": "gdg12"
}
```
- `refreshToken`은 선택 (null 허용). `/auth/refresh`도 같은 shape.

### `UserProfile` — GET /user/profile

```json
{
  "username": "gdg12",
  "accountType": "자녀회원",
  "childCode": "XY785eZ"
}
```
- `accountType` 누락 시 클라이언트는 `'자녀회원'`로 폴백.

### `Mission` — GET /missions/:id, list 응답의 각 row, submit 응답

```json
{
  "id": "1",
  "title": "방청소 하기",
  "rewardHours": 0,
  "rewardMinutes": 30,
  "status": "pendingCheck",
  "description": "방청소하고 깨끗하진 방 사진 찍기",
  "assignedBy": "parent",
  "photoUrls": ["https://cdn.../1.jpg"],
  "deadline": null,
  "category": "청소",
  "categoryOptions": ["루틴", "학습", "운동", "청소", "심부름"],
  "resetCycle": "매일",
  "resetCycleOptions": ["매일", "일주일", "한 달"],
  "confirmationMethod": "childSelf",
  "confirmationMethodOptions": ["aiAuto", "childSelf", "parentApproval"],
  "payoutTime": null,
  "captureInstruction": "깨끗해진 방을 찍어서 올려주세요!"
}
```
- `status` enum: `pendingCheck` / `reviewing` / `completed` / `rejected`. 누락 또는 알 수 없는 값 → `pendingCheck`.
- `confirmationMethod` enum: `aiAuto` / `childSelf` / `parentApproval`. 누락 → `childSelf`.
- `*Options` 배열은 미션 편집 UI의 chip row 옵션 — 백엔드가 미션마다 동일한 기본값을 보내거나 아예 안 보내도 됨 (클라이언트가 기본값 가짐).
- `deadline`은 ISO-8601 또는 null.

### `TimeSchedule` — GET/POST /time-setup, GET /time-confirm/current.schedule

```json
{
  "allowedHours": [
    { "weekday": 0, "hour": 7 },
    { "weekday": 0, "hour": 8 }
  ],
  "weeklyTotals": [
    { "weekIndex": 0, "hours": 15, "minutes": 0 },
    { "weekIndex": 1, "hours": 15, "minutes": 0 },
    { "weekIndex": 2, "hours": 15, "minutes": 0 },
    { "weekIndex": 3, "hours": 15, "minutes": 30 }
  ],
  "dayAllocations": [
    {
      "daysLabel": "월,수,금",
      "weekdayIndices": [0, 2, 4],
      "hours": 3,
      "minutes": 0
    }
  ]
}
```
- `weekday`/`weekdayIndices`: `0..6` (월=0 ... 일=6).
- `hour`: `0..23` (UI는 7..23만 노출).
- `weekIndex`: `0..3` (이번 달의 1~4주차).
- `daysLabel`: 표시용 — 백엔드는 `weekdayIndices`만 채워줘도 클라이언트가 `'월,수,금'` 형태로 조립 가능 (현재는 둘 다 받음).

### `TimeConfirmData` — GET /time-confirm/current

```json
{ "schedule": null | TimeSchedule }
```
- `null`이면 empty 상태 (부모가 아직 미설정).

### `NotificationItem` — GET /notifications row

```json
{
  "id": "weekly-report-20260520",
  "type": "weeklyReport",
  "title": "위클리 사용 리포트",
  "message": "2월 1주차 사용 분석이 담긴 리포트가 도착했어요!\n리포트를 통해 더 나은 계획을 세워봐요.",
  "createdAt": "2026-05-25T14:30:00Z",
  "actionLabel": "확인하러 가기",
  "deeplink": "/child-home/report"
}
```
- `type` enum: `weeklyReport` / `timeConfigured` / `missionCompleted` / `missionConfirmationRequested` / `missionRejected`.
- `actionLabel` 누락 시 클라이언트 폴백 `'확인하러 가기'`.
- `deeplink` 누락 시 클라이언트가 `type` 기반 fallback route 사용.
- `createdAt`은 ISO-8601 UTC (`Z` 또는 `+00:00`).

### `UsageReport` — GET /reports/weekly

```json
{
  "weekLabel": "2월 1주차 사용리포트",
  "plan": {
    "totalHours": 21,
    "daySets": [
      { "daysLabel": "월,수,금", "hoursPerDay": 7 },
      { "daysLabel": "화,목",   "hoursPerDay": 7 },
      { "daysLabel": "토,일",   "hoursPerDay": 7 }
    ]
  },
  "dailyRows": [
    { "dayKor": "월", "plannedMinutes": 420, "actualMinutes": 300 }
  ],
  "compliance": {
    "onPlanPct": 20.0,
    "overPct":   50.0,
    "underPct":  30.0
  },
  "suggestions": [
    {
      "daysLabel": "월,수,금",
      "suggestedHours": 7,
      "deltaHours": -1,
      "tone": "positive"
    }
  ]
}
```
- `dailyRows`: 7개 entry (월~일). `deltaMinutes`는 클라이언트가 `actualMinutes - plannedMinutes`로 계산.
- `compliance.overPct`: 클라이언트가 "계획 이행률 NN%" 표시에 사용 (over-plan slice = 이행률 정의).
- `suggestions.tone` enum: `positive` / `neutral` / `destructive`. 누락 → `neutral`.

---

## Appendix B: 에러 코드 매핑

클라이언트가 분기 로직에 사용하는 `error.code` 목록. 백엔드는 동일 코드 + 한국어 메시지를 발급해야 함 (메시지는 그대로 사용자에게 노출됨).

| code | endpoint | message | 클라이언트 동작 |
|---|---|---|---|
| `INVALID_CREDENTIALS` | POST /auth/login | 비밀번호가 일치하지 않아요. | 비밀번호 필드 red border + 토스트 |
| `USER_NOT_FOUND` | POST /auth/login | 아이디를 다시 확인해 주세요. | 아이디 필드 red border + 토스트 |
| `INVALID_REFRESH_TOKEN` | POST /auth/refresh | (메시지 무관) | 강제 로그아웃 → 시작 화면 |
| `DUPLICATE_USERNAME` | POST /auth/signup | 이미 사용 중인 아이디예요. | 아이디 필드 헬퍼 텍스트 + 토스트 |
| `INVALID_FORMAT` | POST /auth/signup, PATCH /user/password | 아이디/비밀번호 형식이 올바르지 않아요. | 토스트 (클라이언트도 regex로 1차 차단) |
| `WRONG_CURRENT_PASSWORD` | PATCH /user/password | 현재 비밀번호가 일치하지 않아요. | "현재 비밀번호" 필드 헬퍼 텍스트 (메시지 substring 매칭) |
| `SAME_AS_CURRENT` | PATCH /user/password | 기존 비밀번호와 다르게 설정해 주세요. | "새 비밀번호" 필드 헬퍼 텍스트 (TODO: 클라이언트 매핑 추가 예정) |
| `MISSION_NOT_FOUND` | GET /missions/:id | 미션을 찾을 수 없어요. | 토스트 + 이전 화면 유지 |
| `NO_PHOTOS` | POST /missions/:id/submit | 사진을 한 장 이상 첨부해 주세요. | 토스트 (클라이언트도 빈 리스트 제출 막음) |
| `INVALID_SCHEDULE` | POST /time-setup | 주별 합이 월 한도와 맞지 않아요. | 토스트 + review 화면 유지 |
| `ALREADY_REQUESTED` | POST /time-confirm/request-modification | 이미 수정 요청 중이에요. | 수정하기 pill SnackBar |
| `REPORT_NOT_READY` | GET /reports/weekly | 아직 이번 주 리포트가 준비되지 않았어요. | 토스트 + seed 데이터 유지 |
| `NOTIFICATION_NOT_FOUND` | DELETE/PATCH /notifications/:id | (메시지 무관) | 토스트 + 로컬 목록 새로고침 |
| `ALREADY_REGISTERED` | POST /devices | (메시지 무관) | 응답 body에서 새 device id 추출 후 성공 처리 (transfer case) |
| `PAYLOAD_TOO_LARGE` | POST /uploads/photo | 사진 용량이 너무 커요. | 토스트 + 사진 추가 막음 |
| `UNSUPPORTED_MEDIA` | POST /uploads/photo | 지원하지 않는 사진 형식이에요. | 토스트 + 사진 추가 막음 |

**기본 폴백** (위 코드에 매칭 안 되는 모든 4xx/5xx):
- 401 (refresh 후에도 실패) → `'로그인이 만료되었어요. 다시 로그인해 주세요.'`
- 403 → `'권한이 없어요.'`
- 404 (위 매핑 외) → `'찾을 수 없어요.'`
- 5xx → `'잠시 후 다시 시도해 주세요.'`
- 네트워크/타임아웃 → `'네트워크 연결을 확인해 주세요.'`

---

## Appendix C: 클라이언트 endpoint 호출 매트릭스

각 ApiX*Repository가 호출하는 endpoint 일람 — 코드 grep으로 자동 검증 가능.

| Repository | Method | Endpoint | Body |
|---|---|---|---|
| ApiAuthRepository | POST | /auth/login | `{username, password}` |
| ApiAuthRepository | POST | /auth/signup | `{username, password}` |
| ApiAuthRepository | POST | /auth/refresh | `{refreshToken}` |
| ApiMissionRepository | GET | /missions | — |
| ApiMissionRepository | GET | /missions/:id | — |
| ApiMissionRepository | POST | /missions/:id/submit | `{photoUrls: [...]}` |
| ApiTimeSetupRepository | GET | /time-setup/previous-week | — |
| ApiTimeSetupRepository | GET | /time-setup/current | — |
| ApiTimeSetupRepository | POST | /time-setup | `TimeSchedule` |
| ApiTimeConfirmRepository | GET | /time-confirm/current | — |
| ApiTimeConfirmRepository | POST | /time-confirm/request-modification | `{}` |
| ApiTimeConfirmRepository | POST | /time-confirm/acknowledge | `{}` |
| ApiNotificationRepository | GET | /notifications | — |
| ApiNotificationRepository | DELETE | /notifications/:id | — |
| ApiNotificationRepository | PATCH | /notifications/:id/read | — |
| ApiUsageReportRepository | GET | /reports/weekly | — |
| ApiMyPageRepository | GET | /user/profile | — |
| ApiMyPageRepository | PATCH | /user/password | `{currentPassword, newPassword}` |
| ApiMyPageRepository | DELETE | /user/account | — |
| ApiDeviceRepository | POST | /devices | `{fcmToken, platform}` |
| ApiDeviceRepository | DELETE | /devices/:id | — |
| ApiPhotoUploadService | POST | /uploads/photo | multipart `{file, purpose}` |

총 21 endpoint. `dio_config.dart`의 Bearer interceptor가 모든 호출에 토큰을 자동 첨부 (`/auth/*`은 토큰 없어도 동작).
