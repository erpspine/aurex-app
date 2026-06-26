import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'bottom_nav.dart';
import 'exercise_list.dart';

class AurexLandingScreen extends StatelessWidget {
  const AurexLandingScreen({super.key});

  static const _bodyParts = [
    _ImageTileData('Chest', 'assets/images/body_chest.png', true),
    _ImageTileData('Back', 'assets/images/body_back.png', false),
    _ImageTileData('Shoulders', 'assets/images/body_shoulders.png', false),
    _ImageTileData('Arms', 'assets/images/body_arms.png', false),
    _ImageTileData('Legs', 'assets/images/body_legs.png', false),
    _ImageTileData('Abs', 'assets/images/body_abs.png', false),
  ];

  static const _equipment = [
    _ImageTileData('Dumbbell', 'assets/images/equip_dumbbell.png', false),
    _ImageTileData('Barbell', 'assets/images/equip_barbell.png', false),
    _ImageTileData('Kettlebell', 'assets/images/equip_kettlebell.png', false),
    _ImageTileData('Resistance Band', 'assets/images/equip_band.png', false),
    _ImageTileData('Machine', 'assets/images/equip_machine.png', false),
  ];

  static const _workouts = [
    _WorkoutData('Full Body\nStrength', 'assets/images/workout_full_body.png'),
    _WorkoutData('Upper Body\nPower', 'assets/images/workout_upper.png'),
    _WorkoutData('Lower Body\nBurn', 'assets/images/workout_lower.png'),
  ];

  static const _levels = [
    _ImageTileData('Beginner', 'assets/images/level_beginner.png', false),
    _ImageTileData(
      'Intermediate',
      'assets/images/level_intermediate.png',
      false,
    ),
    _ImageTileData('Advanced', 'assets/images/level_advanced.png', false),
    _ImageTileData('Elite', 'assets/images/level_elite.png', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LandingColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 116),
              children: [
                const _HeroSection(),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'BODY PART EXERCISES',
                  onSeeAll: () => _openBodyPartList(context),
                ),
                _HorizontalImageTiles(
                  items: _bodyParts,
                  width: 142,
                  onTap: () => _openBodyPartList(context),
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'EQUIPMENT BASED EXERCISES',
                  onSeeAll: () => _openEquipmentList(context),
                ),
                _HorizontalImageTiles(
                  items: _equipment,
                  width: 154,
                  onTap: () => _openEquipmentList(context),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'WORKOUTS'),
                const _WorkoutList(items: _workouts),
                const SizedBox(height: 28),
                const _SectionHeader(
                  title: 'WORKOUT LEVELS',
                  showSeeAll: false,
                ),
                const _HorizontalImageTiles(items: _levels, width: 200),
              ],
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(homeIsRoot: true),
            ),
          ],
        ),
      ),
    );
  }

  void _openBodyPartList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExerciseListPage.bodyParts()),
    );
  }

  void _openEquipmentList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExerciseListPage.equipment()),
    );
  }
}

class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  late final Future<List<MobileAppBanner>> _bannerFuture;

  @override
  void initState() {
    super.initState();
    _bannerFuture = AurexApiClient.fetchHomeBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MobileAppBanner>>(
      future: _bannerFuture,
      builder: (context, snapshot) {
        final banners = snapshot.data ?? const <MobileAppBanner>[];
        final slides = banners.isEmpty
            ? _HeroSlideData.fallbackSlides
            : banners.map(_HeroSlideData.fromBanner).toList();

        return _HeroCarousel(
          key: ValueKey(slides.map((slide) => slide.identity).join('|')),
          slides: slides,
        );
      },
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({super.key, required this.slides});

  final List<_HeroSlideData> slides;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }

      if (widget.slides.length < 2) {
        return;
      }

      final nextIndex = (_currentIndex + 1) % widget.slides.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.slides.length) {
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 853 / 650,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _HeroSlide(slide: widget.slides[index]);
            },
          ),
          if (widget.slides.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < widget.slides.length; index++)
                    GestureDetector(
                      onTap: () {
                        _controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: _currentIndex == index ? 10 : 8,
                        height: _currentIndex == index ? 10 : 8,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? _LandingColors.softGold
                              : Colors.white.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.slide});

  final _HeroSlideData slide;

  @override
  Widget build(BuildContext context) {
    final image = slide.imageUrl.isEmpty
        ? Image.asset(
            slide.fallbackAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          )
        : Image.network(
            slide.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                slide.fallbackAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              );
            },
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [slide.backgroundColor, _LandingColors.black],
            ),
          ),
        ),
        image,
        if (slide.title.isNotEmpty || slide.subtitle.isNotEmpty)
          Positioned(
            left: 30,
            right: 30,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (slide.title.isNotEmpty)
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                    ),
                  ),
                if (slide.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    slide.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HeroSlideData {
  const _HeroSlideData({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
  });

  final String imageUrl;
  final String fallbackAsset;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  String get identity => imageUrl.isEmpty ? fallbackAsset : imageUrl;

  static const fallbackSlides = [
    _HeroSlideData(
      imageUrl: '',
      fallbackAsset: 'assets/images/slider_dumbbell.png',
      title: '',
      subtitle: '',
      backgroundColor: _LandingColors.black,
    ),
    _HeroSlideData(
      imageUrl: '',
      fallbackAsset: 'assets/images/slider_barbell.png',
      title: '',
      subtitle: '',
      backgroundColor: _LandingColors.black,
    ),
    _HeroSlideData(
      imageUrl: '',
      fallbackAsset: 'assets/images/slider_ropes.png',
      title: '',
      subtitle: '',
      backgroundColor: _LandingColors.black,
    ),
  ];

  factory _HeroSlideData.fromBanner(MobileAppBanner banner) {
    return _HeroSlideData(
      imageUrl: banner.imageUrl,
      fallbackAsset: 'assets/images/slider_dumbbell.png',
      title: banner.title,
      subtitle: banner.subtitle,
      backgroundColor: _colorFromHex(banner.backgroundColor),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.showSeeAll = true,
    this.onSeeAll,
  });

  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 26, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (showSeeAll)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: _LandingColors.softGold,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      color: _LandingColors.softGold,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HorizontalImageTiles extends StatelessWidget {
  const _HorizontalImageTiles({
    required this.items,
    required this.width,
    this.onTap,
  });

  final List<_ImageTileData> items;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.highlight
                        ? _LandingColors.softGold
                        : Colors.white.withValues(alpha: 0.22),
                    width: item.highlight ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(item.image, fit: BoxFit.cover),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({required this.items});

  final List<_WorkoutData> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 278,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(item.image, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class _ImageTileData {
  const _ImageTileData(this.title, this.image, this.highlight);

  final String title;
  final String image;
  final bool highlight;
}

class _WorkoutData {
  const _WorkoutData(this.title, this.image);

  final String title;
  final String image;
}

class _LandingColors {
  const _LandingColors._();

  static const black = Color(0xFF030303);
  static const softGold = Color(0xFFE9C460);
}

Color _colorFromHex(String value) {
  final hex = value.trim().replaceFirst('#', '');
  final normalized = switch (hex.length) {
    6 => 'FF$hex',
    8 => hex,
    _ => '',
  };

  final colorValue = int.tryParse(normalized, radix: 16);
  if (colorValue == null) {
    return _LandingColors.black;
  }

  return Color(colorValue);
}
