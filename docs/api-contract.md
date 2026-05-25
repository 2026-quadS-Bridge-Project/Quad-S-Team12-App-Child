# Bridge-K Child App — API Contract (Draft)

작성일: 2026-05-25

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
