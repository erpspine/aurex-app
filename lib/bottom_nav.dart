import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hosts the five main tabs and keeps the floating navigation bar on top.
class AurexShell extends StatelessWidget {
  const AurexShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: AurexBottomNavigation(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AurexBottomNavigation extends StatelessWidget {
  const AurexBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.fitness_center_rounded, 'Workouts'),
    (Icons.restaurant_rounded, 'Diet'),
    (Icons.insights_rounded, 'Progress'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xF20A0A0A),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: Semantics(
                selected: index == currentIndex,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[index].$1,
                        color: index == currentIndex
                            ? _NavColors.softGold
                            : Colors.white.withValues(alpha: 0.55),
                        size: 27,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _items[index].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: index == currentIndex
                              ? _NavColors.softGold
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavColors {
  const _NavColors._();

  static const softGold = Color(0xFFE9C460);
}
