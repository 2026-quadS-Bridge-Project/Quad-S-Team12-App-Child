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

All API impls are wired against the deployed AWS Swagger surface at
`https://leyoung.shop/swagger-ui/index.html`. Verb/path entries below
match the current implementation. If a feature has no AWS endpoint, the
API implementation does not call a legacy compatibility path.

### Mission — [mission_repository.dart](../lib/features/mission/data/repositories/mission_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `listMissions` | `Future<Result<List<Mission>>>` | Returns `MissionMock.all` | `GET /api/v1/missions` |
| `fetchMission` | `Future<Result<Mission>>(String id)` | Looks up by id; Failure when absent | `GET /api/v1/missions/{missionId}` |
| `submitMission` | `Future<Result<void>>({id, photoPaths})` | Echoes success | `POST /api/v1/missions/{missionId}/performances` multipart `image` |

Notes: `submitMission` accepts local paths and uploads the first file
directly to the mission performance endpoint. `PhotoUploadService` remains
a defer/no-op layer for this flow.

### TimeSetup — [time_setup_repository.dart](../lib/features/time_setup/data/repositories/time_setup_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `fetchPreviousWeekSchedule` | `Future<Result<TimeSchedule>>` | Returns `TimeScheduleMock.previousWeek` | `GET /api/v1/schedules/daily?date=<today-7d>` + `GET /api/v1/schedules/routines` |
| `fetchCurrentSchedule` | `Future<Result<TimeSchedule?>>` | Returns saved fixture or `null` | `GET /api/v1/schedules/daily?date=<today>` + `GET /api/v1/schedules/routines` |
| `saveSchedule` | `Future<Result<void>>(TimeSchedule)` | Mutates in-memory fixture | `POST /api/v1/schedules/weekly-budgets`, `PUT /api/v1/schedules/templates`, `GET/POST/DELETE /api/v1/schedules/routines` |

### TimeConfirm — [time_confirm_repository.dart](../lib/features/time_confirm/data/repositories/time_confirm_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `fetchCurrentSchedule` | `Future<Result<TimeConfirmData>>` | Returns `TimeConfirmMock.current` | `GET /api/v1/schedules/daily?date=<today>` |
| `requestModification` | `Future<Result<void>>` | No-op success | Local-only success; no AWS endpoint |
| `acknowledgeSchedule` | `Future<Result<void>>` | No-op success | Local-only success; no AWS endpoint |

### Notification — [notification_repository.dart](../lib/features/notifications/data/repositories/notification_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `listNotifications` | `Future<Result<List<NotificationItem>>>` | Returns `NotificationsMock.all` | `GET /api/v1/notifications` |
| `deleteNotification` | `Future<Result<void>>(String id)` | Removes from in-memory list | `DELETE /api/v1/notifications/{notificationId}` |
| `markAsRead` | `Future<Result<void>>(String id)` | Flips `isRead` on fixture | `PATCH /api/v1/notifications/{notificationId}/read` |

### UsageReport — [usage_report_repository.dart](../lib/features/report/data/repositories/usage_report_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `fetchCurrentWeekReport` | `Future<Result<UsageReport>>` | Returns `UsageReportMock.currentWeek` | Derived from seven `GET /api/v1/schedules/daily` calls; no `/reports/weekly` call |

### MyPage — [my_page_repository.dart](../lib/features/my_page/data/repositories/my_page_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `fetchProfile` | `Future<Result<UserProfile>>` | Returns canned profile | Local session-derived profile; no AWS profile-read endpoint |
| `changePassword` | `Future<Result<void>>({currentPassword, newPassword})` | Validates against demo password | `PATCH /api/v1/members/password` |
| `deleteAccount` | `Future<Result<void>>` | No-op success | `DELETE /api/v1/members` |

### Auth — [auth_repository.dart](../lib/features/auth/data/repositories/auth_repository.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `login` | `Future<Result<AuthToken>>({username, password})` | Validates against demo creds | `POST /auth/children/login` body `{email,password}` |
| `signup` | `Future<Result<AuthToken>>({name, username, password})` | Failure with `AuthFailureMessages.duplicatedUsername` on collision | `POST /auth/children/signup` body `{name,email,password}` |
| `refreshToken` | `Future<Result<AuthToken>>(refreshToken)` | Rotates mock token | `POST /auth/token/refresh` |

Failure strings live as constants on `AuthFailureMessages` so pages
match exactly — no substring checks.

### PhotoUpload — [photo_upload_service.dart](../lib/core/services/photo_upload_service.dart)

| Method | Signature | Mock behavior | AWS behavior |
|---|---|---|---|
| `uploadPhoto` | `Future<Result<String>>(String localPath)` | Echoes the local path | Local defer; mission submission uploads via `POST /api/v1/missions/{missionId}/performances` |

Lives under `core/services` because it crosses feature boundaries
(mission submission, future profile photo, etc.).

## 3. How to point the app at a real backend

The app now defaults to real API mode in development:
`currentEnvironment` is `.development()`, `useMocks` defaults to `false`,
and the base URL defaults to `https://leyoung.shop`.

1. **Confirm the backend contract** — sanity-check
   [api-contract.md](api-contract.md) against the staging server.
   Any drift here surfaces as `Failure` with a server-supplied Korean
   message (see [api_error.dart](../lib/core/network/api_error.dart)).
2. **Choose the base URL** — no flag is needed for the shared AWS-backed
   backend. For a local Spring Boot backend on Android emulator, run
   `flutter run --dart-define=BRIDGE_API_BASE_URL=http://10.0.2.2:8080`.
   For another remote server, pass that server URL via the same dart-define.
3. **Use mocks only when needed** — run with
   `--dart-define=BRIDGE_USE_MOCKS=true` to restore fixture-backed UI.
   No code changes are required because every feature factory reads
   `currentEnvironment.useMocks`.
4. **Verify** — run `flutter test` and exercise the auth → mission →
   time-setup happy paths manually. The 401-refresh interceptor
   already handles token rotation; new failures should originate
   from contract drift, not the client.

## 4. Outstanding mock-only UX to revisit

| Area | Current behavior | Action when wired |
|---|---|---|
| Mission AI auto-approve | Mock listener uses a local `Timer`; real API listener is a no-op so submitted AI missions stay `reviewing` until refreshed | Replace with real polling against `GET /missions/{id}` or a push channel |
| TimeConfirm 수정하기 SnackBar | No AWS modification-request endpoint exists | Keep local-only success or add a backend endpoint |
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
- **Standalone photo upload service** — mission photo upload is direct to
  `POST /api/v1/missions/{missionId}/performances`. A standalone upload
  service is only needed for future profile/photo flows.
- **End-to-end route walkthrough** — the 53-route Phase 5 verification
  pass from the old plan has not been run against this scaffolding.

**Already done since the original draft:**
- 401-refresh interceptor is live in
  [dio_config.dart](../lib/core/config/dio_config.dart) — rotates
  tokens via `/auth/token/refresh` and replays the failing request.
- FCM client wiring (registration + foreground / background / tap
  handlers + deeplink) is in
  [`core/services/fcm_*`](../lib/core/services/) and
  [`features/devices/`](../lib/features/devices/).
