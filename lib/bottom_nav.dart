import 'package:flutter/material.dart';

import 'diet.dart';
import 'landing.dart';
import 'profile.dart';
import 'progress.dart';
import 'workouts.dart';

class AurexBottomNavigation extends StatelessWidget {
  const AurexBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.homeIsRoot = false,
  });

  final int currentIndex;
  final bool homeIsRoot;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.fitness_center_rounded, 'Workouts'),
    (Icons.bar_chart_rounded, 'Progress'),
    (Icons.restaurant_rounded, 'Diet'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xF20A0A0A),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _handleTap(context, index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _items[index].$1,
                      color: index == currentIndex
                          ? _NavColors.softGold
                          : Colors.white.withValues(alpha: 0.55),
                      size: 30,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _items[index].$2,
                      style: TextStyle(
                        color: index == currentIndex
                            ? _NavColors.softGold
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (index == 1) {
      if (currentIndex == 1) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WorkoutsPage()),
        (route) => false,
      );
      return;
    }

    if (index == 2) {
      if (currentIndex == 2) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProgressPage()),
        (route) => false,
      );
      return;
    }

    if (index == 3) {
      if (currentIndex == 3) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DietPage()),
        (route) => false,
      );
      return;
    }

    if (index == 4) {
      if (currentIndex == 4) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfilePage()),
        (route) => false,
      );
      return;
    }

    if (index != 0) {
      return;
    }

    final navigator = Navigator.of(context);
    if (homeIsRoot && !navigator.canPop()) {
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AurexLandingScreen()),
      (route) => false,
    );
  }
}

class _NavColors {
  const _NavColors._();

  static const softGold = Color(0xFFE9C460);
}
