import 'package:flutter/material.dart';

import 'profile.dart';
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
    (Icons.fitness_center_rounded, 'Workouts'),
    (Icons.person_rounded, 'Profile'),
  ];

  int get _activeIndex => currentIndex == 4 ? 1 : 0;

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
                      color: index == _activeIndex
                          ? _NavColors.softGold
                          : Colors.white.withValues(alpha: 0.55),
                      size: 30,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _items[index].$2,
                      style: TextStyle(
                        color: index == _activeIndex
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
    if (index == 0) {
      if (_activeIndex == 0) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WorkoutsPage()),
        (route) => false,
      );
      return;
    }

    if (index == 1) {
      if (_activeIndex == 1) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfilePage()),
        (route) => false,
      );
      return;
    }
  }
}

class _NavColors {
  const _NavColors._();

  static const softGold = Color(0xFFE9C460);
}
