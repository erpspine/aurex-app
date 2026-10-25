import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep the browser URL in sync with pushed pages so a refresh reopens them.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  unawaited(removeLegacyLocalData());

  runApp(
    ProviderScope(
      // Fail fast on API errors instead of Riverpod's automatic retries; every
      // screen offers its own Retry action.
      retry: (retryCount, error) => null,
      child: const AurexApp(),
    ),
  );
}

/// Earlier builds kept the login token and the activity log in
/// SharedPreferences (localStorage on the web). Both now live elsewhere, so
/// the old copies are deleted.
Future<void> removeLegacyLocalData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith('aurex.'))) {
      await prefs.remove(key);
    }
  } on Object {
    // Storage can be unavailable (e.g. private browsing); nothing to clean.
  }
}

class AurexApp extends ConsumerWidget {
  const AurexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Aurex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AurexLoginScreen.gold,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AurexLoginScreen.black,
        fontFamily: 'Roboto',
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
