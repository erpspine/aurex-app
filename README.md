# AUREX member app

The Flutter app that AUREX gym members use to browse exercises and workout programmes, run guided workout sessions, follow a diet plan and track their progress. It talks to the Laravel API in [`../backend`](../backend).

## Running it

```bash
flutter pub get
flutter run -d chrome --web-port 58125
```

By default the app uses the production API at `https://api.aurex-performance.com/api`. To use a local backend, start it with `php artisan serve --port=8000` and pass its URL:

```bash
flutter run -d chrome --web-port 58125 \
  --dart-define=AUREX_API_BASE_URL=http://localhost:8000/api
```

On the web, use port **58125**. It is the only Flutter dev port listed in `allowed_origins` in `backend/config/cors.php`, so on any other port the browser blocks every API call.

Members can only call the endpoints allowed in `backend/app/Http/Middleware/AuthenticateApiToken.php`. That allow-list must include read access to `workouts`, `exercises`, `equipment`, `workout-levels`, `app-banners` and `diet-plans`, plus everything under `activity/`. Without them, the Home, exercise, Diet and Progress screens can't load for member accounts.

## Checks

```bash
flutter analyze
flutter test
```

## How the code is organised

| File | Purpose |
| --- | --- |
| `lib/main.dart` | Loads `SharedPreferences`, then starts the app in a Riverpod `ProviderScope`. |
| `lib/router.dart` | go_router configuration. It sends signed-out users to `/login` and hosts the five tabs (Home, Workouts, Diet, Progress, Profile) in a `StatefulShellRoute`. Every screen has its own URL, so a browser refresh reopens it. |
| `lib/providers.dart` | All app state: the session (restored at startup), the API client, catalogue data (cached until pulled to refresh), profile, workout history, food diary, water log, diet preferences and the live workout-session timer. |
| `lib/api_client.dart` | REST client built on `package:http`, so it works on mobile, desktop and web. A 401 on an authenticated call signs the user out. |
| `lib/http_client*.dart` | Chooses the HTTP client per platform; on web it sends the auth cookie with API requests. |
| `lib/models.dart` | API models (`MobileWorkout`, `MobileExercise`, `MobileDietPlan`, ...) and `AurexSession`. |
| `lib/activity.dart` | Workout log and food diary models. |
| `lib/config.dart` | `AUREX_API_BASE_URL`. |
| Screen files | `landing.dart` (Home), `workouts.dart`, `workout_plan_detail.dart`, `exercise_list.dart`, `exercise_detail_list.dart`, `workout_detail.dart` (single exercise), `workout_session.dart`, `diet.dart`, `diet_form.dart`, `progress.dart`, `profile.dart`, `login.dart`. |

### Activity data

Workout sessions, the food diary, water intake and diet preferences are saved through the `/api/activity/*` endpoints (`MemberActivityController`), so they follow the member across devices. Each save carries an id created by the app, so retrying after a network error does not create a duplicate.

### Sign-in and token storage

- **Web:** the app logs in with the header `X-Aurex-Auth: cookie`. The API stores the token in an `HttpOnly; SameSite=Lax` cookie scoped to `/api`, which page scripts cannot read. It does not return the token in the response. Every cookie-authenticated request must send `X-Requested-With: XMLHttpRequest`; this blocks cross-site request forgery. At startup the app calls `/me` to check whether the cookie is still valid.
- **Android, iOS and desktop:** the bearer token is stored with `flutter_secure_storage` (Keychain or Keystore).
- **Same site:** the cookie only works when the app and the API are on the same site, as `app.aurex-performance.com` and `api.aurex-performance.com` are. For local development, run the backend on `http://localhost:8000`, not `127.0.0.1`. If a build on `localhost` talks to the production API, the server also returns the token, which the app keeps in memory only, so you log in again after every refresh.
- **Settings:** cookie options are in `backend/config/aurex.php` (`AUREX_AUTH_COOKIE_*` environment variables).
