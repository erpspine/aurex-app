import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'activity.dart';
import 'api_client.dart';
import 'http_client.dart';
import 'models.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = createHttpClient();
  ref.onDispose(client.close);
  return client;
});

/// Whether the API keeps the token in an HttpOnly cookie (web) rather than
/// the app holding a bearer token (mobile and desktop).
final cookieAuthProvider = Provider<bool>((ref) => kIsWeb);

/// Where native apps keep the bearer token: the iOS/macOS Keychain, the
/// Android Keystore or the desktop credential store.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

// ---------------------------------------------------------------- session

/// The signed-in user. Loading while the app checks for a saved session.
class SessionNotifier extends AsyncNotifier<AurexSession?> {
  static const _storageKey = 'aurex.session';

  bool get _cookieAuth => ref.read(cookieAuthProvider);

  // Built directly because apiClientProvider depends on this notifier.
  AurexApiClient _client(String? token) => AurexApiClient(
    httpClient: ref.read(httpClientProvider),
    token: token,
    cookieAuth: _cookieAuth,
  );

  @override
  Future<AurexSession?> build() async {
    if (_cookieAuth) {
      // The token is in an HttpOnly cookie the app cannot read; ask the API
      // whether it still identifies a user.
      try {
        return await _client(null).fetchSession();
      } on AurexApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          return null;
        }
        rethrow;
      }
    }

    final storage = ref.read(secureStorageProvider);
    try {
      final raw = await storage.read(key: _storageKey);
      return raw == null
          ? null
          : AurexSession.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            );
    } on Object catch (error) {
      if (error is! FormatException &&
          error is! TypeError &&
          error is! PlatformException) {
        rethrow;
      }
      await storage.delete(key: _storageKey);
      return null;
    }
  }

  Future<void> signIn(AurexSession session) async {
    state = AsyncData(session);

    // On the web nothing is persisted: the cookie keeps the session. A token
    // returned to a cross-site dev build stays in memory only.
    if (!_cookieAuth && session.token != null) {
      await ref
          .read(secureStorageProvider)
          .write(key: _storageKey, value: jsonEncode(session.toJson()));
    }
  }

  /// Revokes the token on the server (best effort) and clears it locally.
  Future<void> signOut() async {
    final session = state.value;
    if (session == null) {
      return;
    }

    try {
      await _client(session.token).logout();
    } on AurexApiException {
      // The session is dropped locally either way.
    }
    await expire();
  }

  /// Clears the session without contacting the server, e.g. after a 401.
  Future<void> expire() async {
    state = const AsyncData(null);
    if (!_cookieAuth) {
      await ref.read(secureStorageProvider).delete(key: _storageKey);
    }
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AurexSession?>(
  SessionNotifier.new,
);

final apiClientProvider = Provider<AurexApiClient>((ref) {
  final session = ref.read(sessionProvider.notifier);
  // Keyed on the user as well as the token: on the web the token is hidden in
  // a cookie, and cached data must never carry over to the next account.
  final identity = ref.watch(
    sessionProvider.select(
      (s) => (token: s.value?.token, user: '${s.value?.user['id'] ?? ''}'),
    ),
  );

  return AurexApiClient(
    httpClient: ref.watch(httpClientProvider),
    token: identity.token,
    cookieAuth: ref.watch(cookieAuthProvider),
    onUnauthorized: () => unawaited(session.expire()),
  );
});

bool _signedIn(Ref ref) =>
    ref.watch(sessionProvider.select((session) => session.value != null));

// --------------------------------------------------------------- catalogue

final workoutsProvider = FutureProvider<List<MobileWorkout>>((ref) async {
  final items = await ref.watch(apiClientProvider).fetchWorkouts();
  return items.where((item) => item.isPublishedMobile).toList();
});

final exercisesProvider = FutureProvider<List<MobileExercise>>((ref) async {
  final items = await ref.watch(apiClientProvider).fetchExercises();
  return items.where((item) => item.isPublishedMobile).toList();
});

final equipmentProvider = FutureProvider<List<MobileEquipment>>((ref) async {
  final items = await ref.watch(apiClientProvider).fetchEquipment();
  return items.where((item) => item.isPublishedMobile).toList();
});

final workoutLevelsProvider = FutureProvider<List<MobileWorkoutLevel>>((
  ref,
) async {
  final items = await ref.watch(apiClientProvider).fetchWorkoutLevels();
  return items.where((item) => item.isPublishedMobile).toList()
    ..sort((a, b) => a.difficultyRank.compareTo(b.difficultyRank));
});

final homeBannersProvider = FutureProvider<List<MobileAppBanner>>(
  (ref) => ref.watch(apiClientProvider).fetchHomeBanners(),
);

final dietPlansProvider = FutureProvider<List<MobileDietPlan>>((ref) async {
  final items = await ref.watch(apiClientProvider).fetchDietPlans();
  return items.where((item) => item.isPublishedMobile).toList();
});

final workoutByIdProvider = FutureProvider.family<MobileWorkout?, String>((
  ref,
  id,
) async {
  final workouts = await ref.watch(workoutsProvider.future);
  return workouts.where((workout) => workout.id == id).firstOrNull;
});

final exerciseByIdProvider = FutureProvider.family<MobileExercise?, String>((
  ref,
  id,
) async {
  final exercises = await ref.watch(exercisesProvider.future);
  return exercises.where((exercise) => exercise.id == id).firstOrNull;
});

// ----------------------------------------------------------------- profile

class ProfileNotifier extends AsyncNotifier<MobileProfile> {
  @override
  Future<MobileProfile> build() => ref.watch(apiClientProvider).fetchProfile();

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> save(Map<String, dynamic> values) async {
    final profile = await ref.read(apiClientProvider).updateProfile(values);
    state = AsyncData(profile);
  }

  Future<void> uploadPhoto(Uint8List bytes, String fileName) async {
    final profile = await ref
        .read(apiClientProvider)
        .uploadProfilePhoto(bytes: bytes, fileName: fileName);
    state = AsyncData(profile);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, MobileProfile>(
  ProfileNotifier.new,
);

// ---------------------------------------------------------------- activity

class WorkoutHistoryNotifier extends AsyncNotifier<List<WorkoutLogEntry>> {
  @override
  Future<List<WorkoutLogEntry>> build() async {
    final api = ref.watch(apiClientProvider);
    if (!_signedIn(ref)) {
      return const [];
    }

    final logs = await api.fetchWorkoutLogs();
    return logs..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Future<void> add(WorkoutLogEntry entry) async {
    final saved = await ref.read(apiClientProvider).createWorkoutLog(entry);
    state = AsyncData([
      saved,
      ...?state.value?.where((item) => item.id != saved.id),
    ]);
  }
}

final workoutHistoryProvider =
    AsyncNotifierProvider<WorkoutHistoryNotifier, List<WorkoutLogEntry>>(
      WorkoutHistoryNotifier.new,
    );

class FoodLogNotifier extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() async {
    final api = ref.watch(apiClientProvider);
    return _signedIn(ref) ? api.fetchFoodEntries() : const [];
  }

  Future<void> add(FoodEntry entry) async {
    final saved = await ref.read(apiClientProvider).createFoodEntry(entry);
    state = AsyncData([
      ...?state.value?.where((item) => item.id != saved.id),
      saved,
    ]);
  }

  Future<void> remove(String id) async {
    await ref.read(apiClientProvider).deleteFoodEntry(id);
    state = AsyncData([...?state.value?.where((entry) => entry.id != id)]);
  }
}

final foodLogProvider = AsyncNotifierProvider<FoodLogNotifier, List<FoodEntry>>(
  FoodLogNotifier.new,
);

class WaterLogNotifier extends AsyncNotifier<Map<String, int>> {
  static const dailyCups = 10;

  @override
  Future<Map<String, int>> build() async {
    final api = ref.watch(apiClientProvider);
    return _signedIn(ref) ? api.fetchWaterLogs() : const {};
  }

  /// Updates the cup count immediately and rolls back if saving fails.
  Future<void> setCups(String day, int cups) async {
    final previous = state.value ?? const <String, int>{};
    final next = cups.clamp(0, dailyCups);
    state = AsyncData({...previous, day: next});

    try {
      await ref.read(apiClientProvider).saveWater(day, next);
    } on AurexApiException {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final waterLogProvider =
    AsyncNotifierProvider<WaterLogNotifier, Map<String, int>>(
      WaterLogNotifier.new,
    );

class DietPreferences {
  const DietPreferences({this.calorieGoal, this.planId});

  final int? calorieGoal;
  final String? planId;
}

class DietPreferencesNotifier extends AsyncNotifier<DietPreferences> {
  @override
  Future<DietPreferences> build() async {
    final api = ref.watch(apiClientProvider);
    if (!_signedIn(ref)) {
      return const DietPreferences();
    }

    final saved = await api.fetchDietPreferences();
    return DietPreferences(
      calorieGoal: saved.calorieGoal,
      planId: saved.planId,
    );
  }

  Future<void> setCalorieGoal(int? goal) =>
      _save(calorieGoal: goal, planId: state.value?.planId);

  Future<void> selectPlan(String? planId) =>
      _save(calorieGoal: state.value?.calorieGoal, planId: planId);

  Future<void> _save({int? calorieGoal, String? planId}) async {
    final saved = await ref
        .read(apiClientProvider)
        .saveDietPreferences(calorieGoal: calorieGoal, planId: planId);
    state = AsyncData(
      DietPreferences(calorieGoal: saved.calorieGoal, planId: saved.planId),
    );
  }
}

final dietPreferencesProvider =
    AsyncNotifierProvider<DietPreferencesNotifier, DietPreferences>(
      DietPreferencesNotifier.new,
    );

/// The diet plan to follow: the member's choice, otherwise the published plan
/// that best matches their fitness goal.
final activeDietPlanProvider = FutureProvider<MobileDietPlan?>((ref) async {
  final plans = await ref.watch(dietPlansProvider.future);
  if (plans.isEmpty) {
    return null;
  }

  final chosen = ref.watch(dietPreferencesProvider).value?.planId;
  final selected = plans.where((plan) => plan.id == chosen).firstOrNull;
  if (selected != null) {
    return selected;
  }

  final goal = ref.watch(profileProvider).value?.fitnessGoal.toLowerCase();
  return plans
          .where((plan) => goal != null && plan.goal.toLowerCase() == goal)
          .firstOrNull ??
      plans.first;
});

class SelectedDietDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void select(DateTime day) => state = dateOnly(day);

  void shift(int days) => state = state.add(Duration(days: days));
}

final selectedDietDayProvider =
    NotifierProvider<SelectedDietDayNotifier, DateTime>(
      SelectedDietDayNotifier.new,
    );

// --------------------------------------------------------- workout session

typedef WorkoutSessionPlan = ({
  String exerciseId,
  int sets,
  int reps,
  int restSeconds,
});

class SessionSet {
  const SessionSet({
    required this.reps,
    required this.weightKg,
    this.done = false,
  });

  final int reps;
  final double weightKg;
  final bool done;

  SessionSet copyWith({int? reps, double? weightKg, bool? done}) => SessionSet(
    reps: reps ?? this.reps,
    weightKg: weightKg ?? this.weightKg,
    done: done ?? this.done,
  );
}

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.sets,
    required this.restSeconds,
    required this.id,
    this.elapsedSeconds = 0,
    this.restRemaining = 0,
    this.paused = false,
  });

  /// Identifies this session when it is saved, so retries are not duplicated.
  final String id;
  final List<SessionSet> sets;
  final int restSeconds;
  final int elapsedSeconds;
  final int restRemaining;
  final bool paused;

  int get completedCount => sets.where((set) => set.done).length;
  bool get finished => completedCount == sets.length;
  bool get resting => restRemaining > 0;

  /// Index of the set being worked on, or `sets.length` when finished.
  int get currentIndex {
    final index = sets.indexWhere((set) => !set.done);
    return index == -1 ? sets.length : index;
  }

  WorkoutSessionState copyWith({
    List<SessionSet>? sets,
    int? elapsedSeconds,
    int? restRemaining,
    bool? paused,
  }) {
    return WorkoutSessionState(
      id: id,
      sets: sets ?? this.sets,
      restSeconds: restSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      restRemaining: restRemaining ?? this.restRemaining,
      paused: paused ?? this.paused,
    );
  }
}

class WorkoutSessionController extends Notifier<WorkoutSessionState> {
  WorkoutSessionController(this.plan);

  final WorkoutSessionPlan plan;

  @override
  WorkoutSessionState build() {
    final timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(timer.cancel);

    return WorkoutSessionState(
      id: '${plan.exerciseId}-${DateTime.now().microsecondsSinceEpoch}',
      sets: List.generate(
        plan.sets,
        (_) => SessionSet(reps: plan.reps, weightKg: 0),
      ),
      restSeconds: plan.restSeconds,
    );
  }

  void _tick() {
    if (state.paused || state.finished) {
      return;
    }

    state = state.copyWith(
      elapsedSeconds: state.elapsedSeconds + 1,
      restRemaining: state.resting ? state.restRemaining - 1 : 0,
    );
  }

  void togglePause() => state = state.copyWith(paused: !state.paused);

  void skipRest() => state = state.copyWith(restRemaining: 0);

  void completeSet() {
    final index = state.currentIndex;
    if (index >= state.sets.length) {
      return;
    }

    final sets = [...state.sets];
    sets[index] = sets[index].copyWith(done: true);
    final finished = sets.every((set) => set.done);

    state = state.copyWith(
      sets: sets,
      restRemaining: finished ? 0 : state.restSeconds,
      paused: false,
    );
  }

  /// Applies [weightKg] to the current set and every set after it.
  void setWeight(double weightKg) {
    final current = state.currentIndex;
    state = state.copyWith(
      sets: [
        for (var i = 0; i < state.sets.length; i++)
          i >= current
              ? state.sets[i].copyWith(weightKg: weightKg)
              : state.sets[i],
      ],
    );
  }

  void setReps(int reps) {
    final current = state.currentIndex;
    if (current >= state.sets.length || reps < 1) {
      return;
    }

    final sets = [...state.sets];
    sets[current] = sets[current].copyWith(reps: reps);
    state = state.copyWith(sets: sets);
  }
}

final workoutSessionProvider = NotifierProvider.autoDispose
    .family<WorkoutSessionController, WorkoutSessionState, WorkoutSessionPlan>(
      WorkoutSessionController.new,
    );
