import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'providers.dart';
import 'router.dart';

const _aurexPlaceholderAsset = 'assets/images/placeholder.png';

/// Home screen. Every section is loaded from the API; while loading it shows
/// placeholders, and on failure an inline message with Retry.
class AurexLandingScreen extends ConsumerWidget {
  const AurexLandingScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    // Each section shows its own error state, so failures are ignored here.
    Future<void> settle(Future<Object?> future) =>
        future.then((_) {}, onError: (_) {});

    await Future.wait([
      settle(ref.refresh(homeBannersProvider.future)),
      settle(ref.refresh(profileProvider.future)),
      settle(ref.refresh(bodyPartsProvider.future)),
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
              const _Greeting(),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'BODY PART EXERCISES',
                onSeeAll: () => context.push(AurexRoutes.bodyParts),
              ),
              _CatalogueTiles<MobileBodyPart>(
                provider: bodyPartsProvider,
                width: 150,
                emptyMessage: 'No body parts have been published yet.',
                tile: (context, part) => _ImageTileData(
                  part.name,
                  imageUrl: part.imageUrl,
                  subtitle:
                      '${part.exerciseCount} exercise'
                      '${part.exerciseCount == 1 ? '' : 's'}',
                  onTap: () => context.push(
                    AurexRoutes.exerciseGroup('Body Part', part.name),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'EQUIPMENT BASED EXERCISES',
                onSeeAll: () => context.push(AurexRoutes.equipment),
              ),
              _CatalogueTiles<MobileEquipment>(
                provider: equipmentProvider,
                width: 160,
                emptyMessage: 'No equipment has been published yet.',
                tile: (context, item) => _ImageTileData(
                  item.name,
                  imageUrl: item.imageUrl,
                  subtitle: item.category,
                  onTap: () => context.push(
                    AurexRoutes.exerciseGroup('Equipment', item.name),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'WORKOUTS',
                onSeeAll: () => context.go(AurexRoutes.workouts),
              ),
              const _WorkoutList(),
              const SizedBox(height: 28),
              const _SectionHeader(title: 'WORKOUT LEVELS', showSeeAll: false),
              _CatalogueTiles<MobileWorkoutLevel>(
                provider: workoutLevelsProvider,
                width: 200,
                emptyMessage: 'No workout levels have been published yet.',
                tile: (context, level) => _ImageTileData(
                  level.name,
                  imageUrl: level.coverImageUrl,
                  subtitle: level.intensity,
                  onTap: () => context.go(
                    Uri(
                      path: AurexRoutes.workouts,
                      queryParameters: {'level': level.name},
                    ).toString(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Welcome back" line with the member's name and membership from `/me`.
class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final firstName = profile.fullName.split(' ').first;
    final days = profile.daysBeforeExpiry;
    final membership = [
      if (profile.membershipPlanName.isNotEmpty) profile.membershipPlanName,
      if (profile.membershipStatus.isNotEmpty) profile.membershipStatus,
      if (days != null)
        days < 0 ? 'expired' : '$days day${days == 1 ? '' : 's'} left',
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'Welcome back, ',
              children: [
                TextSpan(
                  text: firstName,
                  style: const TextStyle(color: _LandingColors.softGold),
                ),
              ],
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (membership.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              membership,
              style: TextStyle(
                color: days != null && days < 7
                    ? const Color(0xFFFF8A80)
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroSection extends ConsumerWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeBannersProvider);
    final slides = (banners.value ?? const [])
        .map(_HeroSlideData.fromBanner)
        .toList();

    if (slides.isEmpty) {
      // Still loading: keep the space. Nothing published (or banners failed to
      // load): leave room for the status bar only; banners are optional.
      return banners.isLoading
          ? const _HeroLoadingState()
          : SizedBox(height: MediaQuery.paddingOf(context).top + 24);
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

/// A horizontal row of catalogue tiles loaded from [provider].
class _CatalogueTiles<T> extends ConsumerWidget {
  const _CatalogueTiles({
    required this.provider,
    required this.tile,
    required this.width,
    required this.emptyMessage,
  });

  final FutureProvider<List<T>> provider;
  final _ImageTileData Function(BuildContext context, T item) tile;
  final double width;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(provider);
    final values = items.value;

    if (values == null) {
      return items.hasError
          ? _InlineMessage(
              message: items.error.toString(),
              onRetry: () => ref.invalidate(provider),
            )
          : _HorizontalImageTilePlaceholders(width: width);
    }

    if (values.isEmpty) {
      return _InlineMessage(message: emptyMessage);
    }

    return _HorizontalImageTiles(
      width: width,
      items: [for (final item in values) tile(context, item)],
    );
  }
}

class _HorizontalImageTiles extends StatelessWidget {
  const _HorizontalImageTiles({required this.items, required this.width});

  final List<_ImageTileData> items;
  final double width;

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
            label: [
              item.title,
              item.subtitle,
            ].where((text) => text.isNotEmpty).join(', '),
            excludeSemantics: true,
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
                        if (item.imageUrl.isEmpty)
                          const _NoImage()
                        else
                          _RemoteOrAssetImage(
                            imageUrl: item.imageUrl,
                            asset: _aurexPlaceholderAsset,
                          ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.78),
                                ],
                                stops: const [0.35, 1],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                              if (item.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _LandingColors.softGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
    this.alignment = Alignment.center,
    this.allowAssetFallback = true,
  });

  final String imageUrl;
  final String asset;
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
        fit: BoxFit.cover,
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
            fit: BoxFit.cover,
            alignment: widget.alignment,
          );
        }

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
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

/// Tile background for catalogue items that have no image uploaded yet.
class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C1C), _LandingColors.black],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Icon(
          Icons.fitness_center_rounded,
          size: 42,
          color: _LandingColors.softGold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ImageTileData {
  const _ImageTileData(
    this.title, {
    this.imageUrl = '',
    this.subtitle = '',
    this.onTap,
  });

  final String title;
  final String imageUrl;
  final String subtitle;
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
