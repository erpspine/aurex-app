import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aurex/activity.dart';
import 'package:aurex/models.dart';
import 'package:aurex/providers.dart';

ProviderContainer _container({
  Map<String, String> secureStorage = const {},
  http.Client? client,
  bool cookieAuth = false,
}) {
  FlutterSecureStorage.setMockInitialValues({...secureStorage});
  return ProviderContainer.test(
    overrides: [
      cookieAuthProvider.overrideWithValue(cookieAuth),
      httpClientProvider.overrideWithValue(
        client ??
            MockClient(
              (request) async => http.Response('{"message":"?"}', 404),
            ),
      ),
    ],
    retry: (retryCount, error) => null,
  );
}

const _session = AurexSession(token: 'tok', user: {'id': 3, 'name': 'Kofi'});

Future<String?> _stored() =>
    const FlutterSecureStorage().read(key: 'aurex.session');

void main() {
  group('native session', () {
    test('sign in writes the token to secure storage', () async {
      final container = _container();
      expect(await container.read(sessionProvider.future), isNull);

      await container.read(sessionProvider.notifier).signIn(_session);
      final stored = await _stored();
      expect(jsonDecode(stored!)['token'], 'tok');

      final restored = _container(secureStorage: {'aurex.session': stored});
      expect((await restored.read(sessionProvider.future))?.token, 'tok');
    });

    test('corrupt stored session is discarded', () async {
      final container = _container(secureStorage: {'aurex.session': '{oops'});
      expect(await container.read(sessionProvider.future), isNull);
      expect(await _stored(), isNull);
    });

    test('sign out revokes the token and clears storage', () async {
      final requests = <String>[];
      final container = _container(
        client: MockClient((request) async {
          requests.add(
            '${request.method} ${request.url.path} '
            '${request.headers['Authorization']}',
          );
          return http.Response('{"message":"ok"}', 200);
        }),
      );
      await container.read(sessionProvider.future);
      await container.read(sessionProvider.notifier).signIn(_session);
      await container.read(sessionProvider.notifier).signOut();

      expect(requests, ['POST /api/logout Bearer tok']);
      expect(container.read(sessionProvider).value, isNull);
      expect(await _stored(), isNull);
    });

    test('a 401 from any request signs the user out', () async {
      final container = _container(
        client: MockClient(
          (request) async => http.Response('{"message":"expired"}', 401),
        ),
      );
      await container.read(sessionProvider.future);
      await container.read(sessionProvider.notifier).signIn(_session);

      await expectLater(
        container.read(workoutsProvider.future),
        throwsA(anything),
      );
      expect(container.read(sessionProvider).value, isNull);
    });
  });

  group('web cookie session', () {
    test('restores from the cookie via /me and never stores a token', () async {
      final container = _container(
        cookieAuth: true,
        client: MockClient((request) async {
          expect(request.url.path, '/api/me');
          expect(request.headers['Authorization'], isNull);
          expect(request.headers['X-Requested-With'], 'XMLHttpRequest');
          expect(request.headers['X-Aurex-Auth'], 'cookie');
          return http.Response(
            jsonEncode({
              'user': {'id': 9, 'name': 'Web Member'},
              'member': {'full_name': 'Web Member'},
            }),
            200,
          );
        }),
      );

      final session = await container.read(sessionProvider.future);
      expect(session?.user['id'], 9);
      expect(session?.token, isNull);

      await container
          .read(sessionProvider.notifier)
          .signIn(const AurexSession(user: {'id': 9}));
      expect(await _stored(), isNull);
    });

    test('no cookie means signed out', () async {
      final container = _container(
        cookieAuth: true,
        client: MockClient(
          (request) async =>
              http.Response('{"message":"Unauthenticated."}', 401),
        ),
      );

      expect(await container.read(sessionProvider.future), isNull);
    });

    test(
      'a network failure surfaces so the splash can offer a retry',
      () async {
        final container = _container(
          cookieAuth: true,
          client: MockClient(
            (request) async => throw http.ClientException('offline'),
          ),
        );

        await expectLater(
          container.read(sessionProvider.future),
          throwsA(anything),
        );
      },
    );
  });

  test('catalogue providers hide unpublished items', () async {
    final container = _container(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'workouts': [
              {
                'id': 'a',
                'name': 'Live',
                'publish_status': 'Published',
                'show_in_mobile_app': true,
              },
              {
                'id': 'b',
                'name': 'Draft',
                'publish_status': 'Draft',
                'show_in_mobile_app': true,
              },
              {
                'id': 'c',
                'name': 'Hidden from app',
                'publish_status': 'Published',
                'show_in_mobile_app': false,
              },
            ],
          }),
          200,
        ),
      ),
    );

    final workouts = await container.read(workoutsProvider.future);
    expect(workouts.map((w) => w.name), ['Live']);
    expect(
      (await container.read(workoutByIdProvider('a').future))?.name,
      'Live',
    );
    expect(await container.read(workoutByIdProvider('b').future), isNull);
  });

  group('activity syncs with the API', () {
    late List<http.Request> requests;
    late ProviderContainer container;

    setUp(() async {
      requests = [];
      container = _container(
        client: MockClient((request) async {
          requests.add(request);
          final body = switch ('${request.method} ${request.url.path}') {
            'GET /api/activity/workouts' => {
              'workout_logs': [
                {
                  'id': 'w1',
                  'exercise_name': 'Squat',
                  'completed_at': '2026-10-20T07:00:00+03:00',
                  'duration_seconds': 600,
                  'sets': [
                    {'reps': 8, 'weight_kg': 60},
                  ],
                },
              ],
            },
            'POST /api/activity/workouts' => {
              'workout_log': {
                ...jsonDecode(request.body) as Map<String, dynamic>,
                'id': 'w2',
              },
            },
            'GET /api/activity/food' => {'food_entries': []},
            'POST /api/activity/food' => {
              'food_entry': {
                ...jsonDecode(request.body) as Map<String, dynamic>,
                'id': 'f1',
              },
            },
            'DELETE /api/activity/food/f1' => {'message': 'ok'},
            'GET /api/activity/water' => {
              'water_logs': [
                {'date': '2026-10-22', 'cups': 2},
              ],
            },
            'PUT /api/activity/water/2026-10-22' => {'water_log': {}},
            _ => null,
          };
          return body == null
              ? http.Response('{"message":"Server error"}', 500)
              : http.Response(jsonEncode(body), 200);
        }),
      );
      await container.read(sessionProvider.future);
      await container.read(sessionProvider.notifier).signIn(_session);
    });

    test('workout history loads and saves with a client id', () async {
      final history = await container.read(workoutHistoryProvider.future);
      expect(history.single.exerciseName, 'Squat');
      expect(history.single.completedAt.isUtc, isFalse);

      await container
          .read(workoutHistoryProvider.notifier)
          .add(
            WorkoutLogEntry(
              id: 'session-1',
              exerciseId: 'ex',
              exerciseName: 'Bench',
              bodyPart: 'Chest',
              completedAt: DateTime(2026, 10, 22, 7),
              durationSeconds: 300,
              sets: const [LoggedSet(reps: 5, weightKg: 80)],
            ),
          );

      final post = requests.last;
      final sent = jsonDecode(post.body) as Map<String, dynamic>;
      expect(sent['client_id'], 'session-1');
      expect(sent['completed_at'], endsWith('Z'));
      expect(container.read(workoutHistoryProvider).value!.map((e) => e.id), [
        'w2',
        'w1',
      ]);
    });

    test('food entries are added and removed through the API', () async {
      await container.read(foodLogProvider.future);
      await container
          .read(foodLogProvider.notifier)
          .add(
            const FoodEntry(
              id: 'client-1',
              date: '2026-10-22',
              mealType: 'Lunch',
              time: '12:30',
              name: 'Rice',
              servings: 1,
              amountGrams: 200,
              calories: 260,
              protein: 5,
              carbs: 56,
              fat: 1,
            ),
          );
      expect(container.read(foodLogProvider).value!.single.id, 'f1');

      await container.read(foodLogProvider.notifier).remove('f1');
      expect(container.read(foodLogProvider).value, isEmpty);
    });

    test('water updates optimistically and rolls back on failure', () async {
      expect((await container.read(waterLogProvider.future))['2026-10-22'], 2);

      await container.read(waterLogProvider.notifier).setCups('2026-10-22', 5);
      expect(container.read(waterLogProvider).value!['2026-10-22'], 5);

      await expectLater(
        container.read(waterLogProvider.notifier).setCups('2026-10-21', 3),
        throwsA(anything),
      );
      expect(container.read(waterLogProvider).value!['2026-10-21'], isNull);
    });
  });

  group('workout session', () {
    const plan = (exerciseId: 'ex', sets: 3, reps: 10, restSeconds: 30);

    test('completing sets starts rest and finishes the session', () {
      final container = _container();
      final subscription = container.listen(
        workoutSessionProvider(plan),
        (_, _) {},
      );
      final controller = container.read(workoutSessionProvider(plan).notifier);
      final id = subscription.read().id;

      controller.setWeight(40);
      controller.completeSet();
      var state = subscription.read();
      expect(state.completedCount, 1);
      expect(state.restRemaining, 30);
      expect(state.currentIndex, 1);
      expect(state.sets.every((set) => set.weightKg == 40), isTrue);

      controller.skipRest();
      controller.setReps(6);
      controller.completeSet();
      controller.skipRest();
      controller.completeSet();

      state = subscription.read();
      expect(state.finished, isTrue);
      expect(state.restRemaining, 0);
      expect(state.sets.map((set) => set.reps), [10, 6, 10]);
      expect(state.id, id);
    });
  });

  test('streak counts consecutive training days', () {
    WorkoutLogEntry on(DateTime day) => WorkoutLogEntry(
      id: '$day',
      exerciseId: '',
      exerciseName: 'x',
      bodyPart: '',
      completedAt: day,
      durationSeconds: 60,
      sets: const [],
    );
    final now = DateTime(2026, 10, 22, 18);

    expect(workoutStreak([], now), 0);
    expect(
      workoutStreak([
        on(DateTime(2026, 10, 22, 7)),
        on(DateTime(2026, 10, 21, 7)),
        on(DateTime(2026, 10, 20, 7)),
        on(DateTime(2026, 10, 18, 7)),
      ], now),
      3,
    );
    // A streak that ended yesterday still counts until today is over.
    expect(workoutStreak([on(DateTime(2026, 10, 21, 7))], now), 1);
  });

  test('exercise and diet plan parsing', () {
    final exercise = MobileExercise.fromJson({
      'sets': '4 Sets',
      'reps': '8-12 Reps',
      'rest_time': '2 min',
    });
    expect(exercise.setCount, 4);
    expect(exercise.targetReps, 8);
    expect(exercise.restSeconds, 120);

    final plan = MobileDietPlan.fromJson({
      'name': 'Lean',
      'daily_calories': '2,400 kcal',
      'protein': '160g',
      'meals': [
        {'name': 'Breakfast', 'food': 'Oats', 'calories': '520 kcal'},
      ],
    });
    expect(plan.calorieTarget, 2400);
    expect(plan.proteinTarget, 160);
    expect(plan.meals.single.calorieValue, 520);
  });
}
