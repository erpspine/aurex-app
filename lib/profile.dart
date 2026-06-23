import 'package:flutter/material.dart';

import 'bottom_nav.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(28, 54, 28, 126),
              children: const [
                _TopBar(),
                SizedBox(height: 26),
                _ProfileHero(),
                SizedBox(height: 28),
                _ProfileStats(),
                SizedBox(height: 28),
                _CompletionCard(),
                SizedBox(height: 22),
                _ShortcutPanel(),
                SizedBox(height: 22),
                _SettingsPanel(),
                SizedBox(height: 22),
                _LogoutButton(),
              ],
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(currentIndex: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Image.asset(
          'assets/images/aurex_logo_app.png',
          width: 176,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 31,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _ProfileColors.softGold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings, color: Colors.white, size: 29),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: _ProfileColors.gold,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/profile_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.person,
                        color: _ProfileColors.gold,
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 6,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _ProfileColors.softGold,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 34),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'John Doe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'john.doe@email.com',
                style: TextStyle(color: _ProfileColors.muted, fontSize: 19),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      color: _ProfileColors.gold,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Intermediate',
                      style: TextStyle(
                        color: _ProfileColors.softGold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.calendar_month, 'Member Since', 'Jan 2024'),
      (Icons.accessibility_new_rounded, 'Height', '178 cm'),
      (Icons.work_rounded, 'Weight', '72 kg'),
      (Icons.track_changes_rounded, 'Goal', 'Muscle Gain'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620
            ? (constraints.maxWidth - 16) / 2
            : (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 18,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Row(
                  children: [
                    Icon(item.$1, color: _ProfileColors.gold, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ProfileColors.muted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfileColors.gold.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 214,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Completion',
                  style: TextStyle(color: Colors.white, fontSize: 21),
                ),
                SizedBox(height: 8),
                Text(
                  '80% Complete',
                  style: TextStyle(
                    color: _ProfileColors.softGold,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: 0.8,
                minHeight: 12,
                backgroundColor: Color(0xFF313131),
                valueColor: AlwaysStoppedAnimation(_ProfileColors.softGold),
              ),
            ),
          ),
          const SizedBox(width: 26),
          const Icon(
            Icons.chevron_right,
            color: _ProfileColors.softGold,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.assignment_outlined, 'My Plan', 'View Plan'),
      (Icons.straighten, 'Measurements', 'Track Stats'),
      (Icons.image_outlined, 'Photos', 'Progress Pics'),
      (Icons.emoji_events_outlined, 'Achievements', 'View Badges'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: _panelDecoration(),
      child: SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (context, index) => Container(
            width: 1,
            height: 112,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white.withValues(alpha: 0.14),
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return SizedBox(
              width: 130,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, color: _ProfileColors.gold, size: 38),
                  const SizedBox(height: 16),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProfileColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: _ProfileColors.softGold,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.person_outline,
        'Personal Information',
        'Update your personal details',
      ),
      (
        Icons.track_changes_rounded,
        'Fitness Goals',
        'Manage your fitness goals',
      ),
      (
        Icons.fitness_center_rounded,
        'Training Preferences',
        'Set your training preferences',
      ),
      (
        Icons.notifications_none,
        'Notifications',
        'Manage notification settings',
      ),
      (Icons.security, 'Privacy & Security', 'Manage your privacy'),
      (Icons.help_outline, 'Help & Support', 'Get help and support'),
      (Icons.star_rate_rounded, 'About AUREX', 'App version 1.0.0'),
    ];

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SettingsRow(
              icon: items[i].$1,
              title: items[i].$2,
              subtitle: items[i].$3,
            ),
            if (i < items.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 23),
        child: Row(
          children: [
            Icon(icon, color: _ProfileColors.gold, size: 36),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ProfileColors.muted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: _ProfileColors.muted,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF5A4F),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout, size: 26),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.035),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
  );
}

class _ProfileColors {
  const _ProfileColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
