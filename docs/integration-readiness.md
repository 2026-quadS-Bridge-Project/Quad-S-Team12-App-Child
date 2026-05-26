# Integration Readiness

Reference for the engineer wiring real backend endpoints into the
child-side Flutter app. Describes the layers in place, where the seams
are, and what to do next.

## 1. Overview

| Concern | Choice | Location |
|---|---|---|
| State management | `ChangeNotifier` + `InheritedNotifier` scope (no Provider/Riverpod) | per-feature `state/` and `presentation/` |
| Data layer | Per-feature `Repository` abstraction with Mock + Api impls | `lib/features/<feature>/data/repositories/` |
| HTTP client | `dio` via a single factory | [dio_config.dart](../lib/core/config/dio_config.dart) |
| Result type | Sealed `Result<T>` (Success / Failure) | [result.dart](../lib/core/models/result.dart) |
| Auth session | `AuthSession` static helpers (legacy bool + JWT tokens) | [auth_session.dart](../lib/core/auth/auth_session.dart) |
| Environment | Top-level `const currentEnvironment` drives `useMocks` toggle | [environment.dart](../lib/core/config/environment.dart) |

### Repository factory pattern

Every feature exposes a `create<Feature>Repository()` top-level
function. The function inspects `currentEnvironment.useMocks` and
returns either the mock or the API implementation. Pages instantiate
once via a `late final` field and cache for the widget's lifetime.

### AuthSession surface

Two parallel sets of helpers — kept independent so the legacy bool flag
and the JWT scaffolding can evolve separately.

| Concern | Methods |
|---|---|
| Legacy login flag | `saveLogin`, `username`, `isLoggedIn`, `clearLogin` |
| JWT tokens | `saveTokens`, `accessToken`, `refreshToken`, `clearTokens` |

The Dio interceptor reads `AuthSession.accessToken()` on every request
and injects `Authorization: Bearer <token>` when present.

## 2. Per-feature repository catalog

All API impls are wired against the endpoints documented in
[`api-contract.md`](api-contract.md). Verb/path entries below match
the impls and are kept here as a quick reference; the contract doc
is the canonical source.

### Mission — [mission_repository.dart](../lib/features/mission/data/repositories/mission_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `listMissions` | `Future<Result<List<Mission>>>` | Returns `MissionMock.all` | `GET /missions` |
| `fetchMission` | `Future<Result<Mission>>(String id)` | Looks up by id; Failure when absent | `GET /missions/{id}` |
| `submitMission` | `Future<Result<Mission>>({id, photoPaths})` | Echoes mission with attached `photoUrls`; controller owns status transitions | `POST /missions/{id}/submit` |

Notes: `submitMission` accepts local paths today. After photo upload
goes live the controller should pass remote URLs returned by
`PhotoUploadService`.

### TimeSetup — [time_setup_repository.dart](../lib/features/time_setup/data/repositories/time_setup_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `fetchPreviousWeekSchedule` | `Future<Result<TimeSchedule>>` | Returns `TimeScheduleMock.previousWeek` | `GET /time-setup/previous-week` |
| `fetchCurrentSchedule` | `Future<Result<TimeSchedule?>>` | Returns saved fixture or `null` | `GET /time-setup/current` |
| `saveSchedule` | `Future<Result<void>>(TimeSchedule)` | Mutates in-memory fixture | `POST /time-setup` |

### TimeConfirm — [time_confirm_repository.dart](../lib/features/time_confirm/data/repositories/time_confirm_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `fetchCurrentSchedule` | `Future<Result<TimeConfirmData>>` | Returns `TimeConfirmMock.current` | `GET /time-confirm/current` |
| `requestModification` | `Future<Result<void>>` | No-op success | `POST /time-confirm/request-modification` |
| `acknowledgeSchedule` | `Future<Result<void>>` | No-op success | `POST /time-confirm/acknowledge` |

### Notification — [notification_repository.dart](../lib/features/notifications/data/repositories/notification_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `listNotifications` | `Future<Result<List<NotificationItem>>>` | Returns `NotificationsMock.all` | `GET /notifications` |
| `deleteNotification` | `Future<Result<void>>(String id)` | Removes from in-memory list | `DELETE /notifications/{id}` |
| `markAsRead` | `Future<Result<void>>(String id)` | Flips `isRead` on fixture | `PATCH /notifications/{id}/read` |

### UsageReport — [usage_report_repository.dart](../lib/features/report/data/repositories/usage_report_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `fetchCurrentWeekReport` | `Future<Result<UsageReport>>` | Returns `UsageReportMock.currentWeek` | `GET /reports/weekly` |

### MyPage — [my_page_repository.dart](../lib/features/my_page/data/repositories/my_page_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `fetchProfile` | `Future<Result<UserProfile>>` | Returns canned profile | `GET /user/profile` |
| `changePassword` | `Future<Result<void>>({currentPassword, newPassword})` | Validates against demo password; Failure with `'현재 비밀번호가 일치하지 않아요.'` on mismatch | `PATCH /user/password` |
| `deleteAccount` | `Future<Result<void>>` | No-op success | `DELETE /user/account` |

### Auth — [auth_repository.dart](../lib/features/auth/data/repositories/auth_repository.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `login` | `Future<Result<AuthToken>>({username, password})` | Validates against demo creds; Failure messages exposed via `AuthFailureMessages` | `POST /auth/login` |
| `signup` | `Future<Result<AuthToken>>({username, password})` | Failure with `AuthFailureMessages.duplicatedUsername` on collision | `POST /auth/signup` |

Failure strings live as constants on `AuthFailureMessages` so pages
match exactly — no substring checks.

### PhotoUpload — [photo_upload_service.dart](../lib/core/services/photo_upload_service.dart)

| Method | Signature | Mock behavior | Tentative endpoint |
|---|---|---|---|
| `uploadPhoto` | `Future<Result<String>>(String localPath)` | Echoes the local path as the remote URL | `POST /uploads/photo` (multipart) |

Lives under `core/services` because it crosses feature boundaries
(mission submission, future profile photo, etc.).

## 3. How to point the app at a real backend

The Api* repositories are already implemented; switching environments
is a one-line config change.

1. **Confirm the backend contract** — sanity-check
   [api-contract.md](api-contract.md) against the staging server.
   Any drift here surfaces as `Failure` with a server-supplied Korean
   message (see [api_error.dart](../lib/core/network/api_error.dart)).
2. **Flip the environment toggle** — edit
   [environment.dart](../lib/core/config/environment.dart) so the
   top-level `currentEnvironment` points at `.staging()` /
   `.production()` (both default to `useMocks: false`). No other code
   changes are required — every feature factory reads this const.
3. **Verify** — run `flutter test` and exercise the auth → mission →
   time-setup happy paths manually. The 401-refresh interceptor
   already handles token rotation; new failures should originate
   from contract drift, not the client.

## 4. Outstanding mock-only UX to revisit

| Area | Current behavior | Action when wired |
|---|---|---|
| Mission AI auto-approve | `MissionController` runs a local `Timer` to flip `reviewing → completed` after a short delay | Replace with real polling against `GET /missions/{id}` or a push channel |
| TimeConfirm 수정하기 SnackBar | Copy reads `'수정 요청은 곧 연결될 예정이에요'` | Update copy and remove the placeholder once `POST /schedules/modification-requests` succeeds |
| Home notification badge | Derived from `hasContent` over the local mock list | Use an API-provided unread count |
| Hardcoded calendar labels | Strings like `'2월'`, `'1주차'` are baked into widgets | Source from a calendar service or backend-provided strings |

## 5. JSON model coverage

All models below ship hand-written `fromJson` / `toJson`. Decoders
default missing fields to safe values so partial payloads still render.

| Model | File | Notes |
|---|---|---|
| `Mission` | [mission.dart](../lib/features/mission/data/models/mission.dart) | `MissionStatus` and `ConfirmationMethod` serialised via `Enum.name`; lookups fall back to `pendingCheck` / `childSelf` on unknown values |
| `TimeSchedule` (+ nested rows/blocks) | [time_schedule.dart](../lib/features/time_setup/data/models/time_schedule.dart) | Nested day/week structures encode/decode independently |
| `TimeConfirmData` | [time_confirm_data.dart](../lib/features/time_confirm/data/models/time_confirm_data.dart) | Parent-proposed snapshot |
| `NotificationItem` | [notification_item.dart](../lib/features/notifications/data/models/notification_item.dart) | `createdAt` parsed/emitted as ISO-8601 |
| `UsageReport` (+ nested per-day buckets) | [usage_report.dart](../lib/features/report/data/models/usage_report.dart) | Weekly bucket structure |
| `UserProfile` | [user_profile.dart](../lib/features/my_page/data/models/user_profile.dart) | Profile card payload |
| `AuthToken` | [auth_token.dart](../lib/features/auth/data/models/auth_token.dart) | Access + refresh token pair |

## 6. What was NOT done in this prep cycle

The following are explicitly out of scope for the current scaffolding
and will need follow-up tickets:

- **Loading skeletons / error UI** — pages do not yet render skeleton
  placeholders or styled error states for non-mock failure paths.
  Deferred until the API contracts are known so error copy can be
  authored once.
- **WebSocket / real-time listeners** — no push channel exists.
  Mission status changes, notification arrivals, and schedule pushes
  rely on pull-only endpoints + FCM fan-out.
- **Multipart photo upload** — `ApiPhotoUploadService.uploadPhoto`
  throws. Wire `MultipartFile.fromFile(localPath)` once the upload
  endpoint is finalised.
- **End-to-end route walkthrough** — the 53-route Phase 5 verification
  pass from the old plan has not been run against this scaffolding.

**Already done since the original draft:**
- 401-refresh interceptor is live in
  [dio_config.dart](../lib/core/config/dio_config.dart) — rotates
  tokens via `/auth/refresh` and replays the failing request.
- FCM client wiring (registration + foreground / background / tap
  handlers + deeplink) is in
  [`core/services/fcm_*`](../lib/core/services/) and
  [`features/devices/`](../lib/features/devices/).
