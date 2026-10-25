import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'providers.dart';
import 'router.dart';

const _aurexPlaceholderAsset = 'assets/images/placeholder.png';

/// Body parts and equipment the gym catalogue is organised by. The artwork
/// already contains the label, so tiles do not draw a title on top.
const aurexBodyParts = [
  ('Chest', 'assets/images/body_chest.png'),
  ('Back', 'assets/images/body_back.png'),
  ('Shoulders', 'assets/images/body_shoulders.png'),
  ('Arms', 'assets/images/body_arms.png'),
  ('Legs', 'assets/images/body_legs.png'),
  ('Abs', 'assets/images/body_abs.png'),
];

const aurexEquipment = [
  ('Dumbbell', 'assets/images/equip_dumbbell.png'),
  ('Barbell', 'assets/images/equip_barbell.png'),
  ('Kettlebell', 'assets/images/equip_kettlebell.png'),
  ('Resistance Band', 'assets/images/equip_band.png'),
  ('Machine', 'assets/images/equip_machine.png'),
];

/// Artwork for an equipment name from the API, matched by keyword.
String? equipmentArtwork(String name) {
  final normalized = name.toLowerCase();
  for (final (label, asset) in aurexEquipment) {
    if (normalized.contains(label.toLowerCase().split(' ').last) ||
        label.toLowerCase().contains(normalized)) {
      return asset;
    }
  }
  return null;
}

class AurexLandingScreen extends ConsumerWidget {
  const AurexLandingScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    // Each section shows its own error state, so failures are ignored here.
    Future<void> settle(Future<Object?> future) =>
        future.then((_) {}, onError: (_) {});

    await Future.wait([
      settle(ref.refresh(homeBannersProvider.future)),
      settle(ref.refresh(equipmentProvider.future)),
      settle(ref.refresh(workoutsProvider.future)),
      settle(ref.refresh(workoutLevelsProvider.future)),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _LandingColors.black,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _LandingColors.softGold,
          backgroundColor: _LandingColors.black,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 116),
            children: [
              const _HeroSection(),
              const SizedBox(height: 8),
              _SectionHeader(
                title: 'BODY PART EXERCISES',
                onSeeAll: () => context.push(AurexRoutes.bodyParts),
              ),
              _HorizontalImageTiles(
                width: 142,
                showTitle: false,
                items: [
                  for (final (name, asset) in aurexBodyParts)
                    _ImageTileData(
                      name,
                      asset,
                      onTap: () => context.push(
                        AurexRoutes.exerciseGroup('Body Part', name),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'EQUIPMENT BASED EXERCISES',
                onSeeAll: () => context.push(AurexRoutes.equipment),
              ),
              const _EquipmentTiles(width: 154),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'WORKOUTS',
                onSeeAll: () => context.go(AurexRoutes.workouts),
              ),
              const _WorkoutList(),
              const SizedBox(height: 28),
              const _SectionHeader(title: 'WORKOUT LEVELS', showSeeAll: false),
              const _WorkoutLevelTiles(width: 200),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends ConsumerWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slides = (ref.watch(homeBannersProvider).value ?? const [])
        .map(_HeroSlideData.fromBanner)
        .toList();

    if (slides.isEmpty) {
      return const _HeroLoadingState();
    }

    return _HeroCarousel(
      key: ValueKey(slides.map((slide) => slide.identity).join('|')),
      slides: slides,
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
        _RemoteOrAssetImage(
          imageUrl: slide.imageUrl,
          asset: slide.fallbackAsset,
          alignment: Alignment.topCenter,
          allowAssetFallback: true,
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

  factory _HeroSlideData.fromBanner(MobileAppBanner banner) {
    return _HeroSlideData(
      imageUrl: banner.imageUrl,
      fallbackAsset: _aurexPlaceholderAsset,
      title: banner.title,
      subtitle: banner.subtitle,
      backgroundColor: _colorFromHex(banner.backgroundColor),
    );
  }
}

class _HeroLoadingState extends StatelessWidget {
  const _HeroLoadingState();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 853 / 650,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_LandingColors.nearBlack, _LandingColors.black],
          ),
        ),
      ),
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

class _EquipmentTiles extends ConsumerWidget {
  const _EquipmentTiles({required this.width});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipment = ref.watch(equipmentProvider).value ?? const [];

    // Prefer the gym's own equipment list; fall back to the standard groups.
    final names = equipment.isEmpty
        ? [for (final (name, _) in aurexEquipment) name]
        : equipment.map((item) => item.name).toSet().take(10).toList();

    return _HorizontalImageTiles(
      width: width,
      showTitle: false,
      items: [
        for (final name in names)
          _ImageTileData(
            name,
            equipmentArtwork(name) ?? _aurexPlaceholderAsset,
            onTap: () =>
                context.push(AurexRoutes.exerciseGroup('Equipment', name)),
          ),
      ],
    );
  }
}

class _WorkoutLevelTiles extends ConsumerWidget {
  const _WorkoutLevelTiles({required this.width});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(workoutLevelsProvider).value ?? const [];

    if (levels.isEmpty) {
      return _HorizontalImageTilePlaceholders(width: width);
    }

    return _HorizontalImageTiles(
      width: width,
      imageFit: BoxFit.contain,
      showTitle: false,
      items: [
        for (final level in levels)
          _ImageTileData(
            level.name,
            _levelArtwork(level.name),
            imageUrl: level.coverImageUrl,
            onTap: () => context.go(
              Uri(
                path: AurexRoutes.workouts,
                queryParameters: {'level': level.name},
              ).toString(),
            ),
          ),
      ],
    );
  }

  static String _levelArtwork(String name) {
    final normalized = name.toLowerCase();
    for (final level in ['beginner', 'intermediate', 'advanced', 'elite']) {
      if (normalized.contains(level)) {
        return 'assets/images/level_$level.png';
      }
    }
    return _aurexPlaceholderAsset;
  }
}

class _HorizontalImageTiles extends StatelessWidget {
  const _HorizontalImageTiles({
    required this.items,
    required this.width,
    this.imageFit = BoxFit.cover,
    this.showTitle = true,
  });

  final List<_ImageTileData> items;
  final double width;
  final BoxFit imageFit;
  final bool showTitle;

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
          return Semantics(
            button: item.onTap != null,
            label: item.title,
            child: GestureDetector(
              onTap: item.onTap,
              child: SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _RemoteOrAssetImage(
                          imageUrl: item.imageUrl,
                          asset: item.image,
                          fit: imageFit,
                        ),
                        if (showTitle) ...[
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkoutList extends ConsumerWidget {
  const _WorkoutList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final workouts = workoutsAsync.value;

    if (workouts == null) {
      return workoutsAsync.hasError
          ? _InlineMessage(
              message: workoutsAsync.error.toString(),
              onRetry: () => ref.invalidate(workoutsProvider),
            )
          : const _HorizontalImageTilePlaceholders(width: 278, height: 164);
    }

    if (workouts.isEmpty) {
      return const _InlineMessage(message: 'No workouts published yet.');
    }

    return SizedBox(
      height: 164,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        scrollDirection: Axis.horizontal,
        itemCount: workouts.length.clamp(0, 8),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Semantics(
            button: true,
            label: workout.name,
            child: GestureDetector(
              onTap: () => context.push(AurexRoutes.workout(workout.id)),
              child: SizedBox(
                width: 278,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _RemoteOrAssetImage(
                        imageUrl: workout.coverImageUrl,
                        asset: 'assets/images/workouts_program_push.png',
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Text(
                          workout.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: _LandingColors.softGold),
              ),
            ),
        ],
      ),
    );
  }
}

class _RemoteOrAssetImage extends StatefulWidget {
  const _RemoteOrAssetImage({
    required this.imageUrl,
    required this.asset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.allowAssetFallback = true,
  });

  final String imageUrl;
  final String asset;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool allowAssetFallback;

  @override
  State<_RemoteOrAssetImage> createState() => _RemoteOrAssetImageState();
}

class _RemoteOrAssetImageState extends State<_RemoteOrAssetImage> {
  late Future<Uint8List?> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _LandingImageCache.load(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _RemoteOrAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _bytesFuture = _LandingImageCache.load(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      if (!widget.allowAssetFallback) {
        return const _ImageLoadPlaceholder();
      }

      return Image.asset(
        widget.asset,
        fit: widget.fit,
        alignment: widget.alignment,
      );
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;

    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const _ImageLoadPlaceholder();
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          if (!widget.allowAssetFallback) {
            return const _ImageLoadPlaceholder();
          }

          return Image.asset(
            widget.asset,
            fit: widget.fit,
            alignment: widget.alignment,
          );
        }

        return Image.memory(
          bytes,
          fit: widget.fit,
          alignment: widget.alignment,
          cacheWidth: (300 * dpr).round(),
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _LandingImageCache {
  const _LandingImageCache._();

  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> load(String url) {
    if (url.isEmpty) {
      return Future<Uint8List?>.value(null);
    }

    return _cache.putIfAbsent(url, () {
      return _loadBytesWithRetry(url).then((bytes) {
        if (bytes == null || bytes.isEmpty) {
          _cache.remove(url);
        }

        return bytes;
      });
    });
  }

  static Future<Uint8List?> _loadBytesWithRetry(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final bundle = NetworkAssetBundle(uri);
        final byteData = await bundle.load(url);
        return byteData.buffer.asUint8List();
      } catch (_) {
        if (attempt == maxAttempts) {
          return null;
        }

        await Future<void>.delayed(Duration(milliseconds: 220 * attempt));
      }
    }

    return null;
  }
}

class _ImageLoadPlaceholder extends StatelessWidget {
  const _ImageLoadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerSurface();
  }
}

class _ShimmerSurface extends StatefulWidget {
  const _ShimmerSurface();

  @override
  State<_ShimmerSurface> createState() => _ShimmerSurfaceState();
}

class _ShimmerSurfaceState extends State<_ShimmerSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.4 + value * 2.8, -0.9),
              end: Alignment(-0.4 + value * 2.8, 0.9),
              colors: [
                Colors.white.withValues(alpha: 0.045),
                Colors.white.withValues(alpha: 0.13),
                Colors.white.withValues(alpha: 0.045),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

class _ImageTileData {
  const _ImageTileData(
    this.title,
    this.image, {
    this.imageUrl = '',
    this.onTap,
  });

  final String title;
  final String image;
  final String imageUrl;
  final VoidCallback? onTap;
}

class _HorizontalImageTilePlaceholders extends StatelessWidget {
  const _HorizontalImageTilePlaceholders({
    required this.width,
    this.height = 178,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Image.asset(
                    _aurexPlaceholderAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LandingColors {
  const _LandingColors._();

  static const nearBlack = Color(0xFF121212);
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
