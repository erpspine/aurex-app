import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';
import 'bottom_nav.dart';
import 'exercise_list.dart';
import 'workouts.dart';

const _aurexPlaceholderAsset = 'assets/images/placeholder.png';

class AurexLandingScreen extends StatefulWidget {
  const AurexLandingScreen({super.key});

  @override
  State<AurexLandingScreen> createState() => _AurexLandingScreenState();
}

class _AurexLandingScreenState extends State<AurexLandingScreen> {
  late Future<List<MobileAppBanner>> _bannersFuture;
  late Future<List<MobileExercise>> _exercisesFuture;
  late Future<List<MobileEquipment>> _equipmentFuture;
  late Future<List<MobileWorkout>> _workoutsFuture;
  late Future<List<MobileWorkoutLevel>> _levelsFuture;

  static const _bodyParts = [
    _ImageTileData('Chest', _aurexPlaceholderAsset, true),
    _ImageTileData('Back', _aurexPlaceholderAsset, false),
    _ImageTileData('Shoulders', _aurexPlaceholderAsset, false),
    _ImageTileData('Arms', _aurexPlaceholderAsset, false),
    _ImageTileData('Legs', _aurexPlaceholderAsset, false),
    _ImageTileData('Abs', _aurexPlaceholderAsset, false),
  ];

  static const _equipment = [
    _ImageTileData('Dumbbell', _aurexPlaceholderAsset, false),
    _ImageTileData('Barbell', _aurexPlaceholderAsset, false),
    _ImageTileData('Kettlebell', _aurexPlaceholderAsset, false),
    _ImageTileData('Resistance Band', _aurexPlaceholderAsset, false),
    _ImageTileData('Machine', _aurexPlaceholderAsset, false),
  ];

  static const _workouts = [
    _WorkoutData('Full Body\nStrength', _aurexPlaceholderAsset),
    _WorkoutData('Upper Body\nPower', _aurexPlaceholderAsset),
    _WorkoutData('Lower Body\nBurn', _aurexPlaceholderAsset),
  ];

  @override
  void initState() {
    super.initState();
    _assignLandingDataFutures();
  }

  Future<void> _refreshLandingData() async {
    setState(() {
      _assignLandingDataFutures(forceRefresh: true);
    });

    await Future.wait([
      _ignoreErrors(_bannersFuture),
      _ignoreErrors(_exercisesFuture),
      _ignoreErrors(_equipmentFuture),
      _ignoreErrors(_workoutsFuture),
      _ignoreErrors(_levelsFuture),
    ]);
  }

  void _assignLandingDataFutures({bool forceRefresh = false}) {
    _bannersFuture = AurexApiClient.fetchHomeBanners(
      forceRefresh: forceRefresh,
    );
    _exercisesFuture = AurexApiClient.fetchExercises(
      forceRefresh: forceRefresh,
    );
    _equipmentFuture = AurexApiClient.fetchEquipment(
      forceRefresh: forceRefresh,
    );
    _workoutsFuture = AurexApiClient.fetchWorkouts(forceRefresh: forceRefresh);
    _levelsFuture = AurexApiClient.fetchWorkoutLevels(
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _ignoreErrors<T>(Future<List<T>> future) async {
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LandingColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: _LandingColors.softGold,
              backgroundColor: _LandingColors.black,
              onRefresh: _refreshLandingData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 116),
                children: [
                  _HeroSection(bannersFuture: _bannersFuture),
                  const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'BODY PART EXERCISES',
                    onSeeAll: () => _openBodyPartList(context),
                  ),
                  _BodyPartTiles(
                    exercisesFuture: _exercisesFuture,
                    fallbackItems: _bodyParts,
                    width: 142,
                    onTap: () => _openBodyPartList(context),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'EQUIPMENT BASED EXERCISES',
                    onSeeAll: () => _openEquipmentList(context),
                  ),
                  _EquipmentTiles(
                    equipmentFuture: _equipmentFuture,
                    fallbackItems: _equipment,
                    width: 154,
                    onTap: () => _openEquipmentList(context),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'WORKOUTS',
                    onSeeAll: () => _openWorkouts(context),
                  ),
                  _WorkoutList(
                    workoutsFuture: _workoutsFuture,
                    fallbackItems: _workouts,
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(
                    title: 'WORKOUT LEVELS',
                    showSeeAll: false,
                  ),
                  _WorkoutLevelTiles(levelsFuture: _levelsFuture, width: 200),
                ],
              ),
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

  void _openWorkouts(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WorkoutsPage()));
  }
}

class _HeroSection extends StatefulWidget {
  const _HeroSection({required this.bannersFuture});

  final Future<List<MobileAppBanner>> bannersFuture;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MobileAppBanner>>(
      future: widget.bannersFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const _HeroLoadingState();
        }

        final banners = snapshot.data ?? const <MobileAppBanner>[];
        final slides = banners.map(_HeroSlideData.fromBanner).toList();

        if (slides.isEmpty) {
          return const _HeroLoadingState();
        }

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

class _BodyPartTiles extends StatelessWidget {
  const _BodyPartTiles({
    required this.exercisesFuture,
    required this.fallbackItems,
    required this.width,
    required this.onTap,
  });

  final Future<List<MobileExercise>> exercisesFuture;
  final List<_ImageTileData> fallbackItems;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MobileExercise>>(
      future: exercisesFuture,
      builder: (context, snapshot) {
        final exercises =
            snapshot.data
                ?.where(
                  (exercise) =>
                      exercise.isPublishedMobile &&
                      exercise.category.toLowerCase().contains('body part'),
                )
                .toList() ??
            const <MobileExercise>[];
        final items = exercises.isEmpty
            ? fallbackItems
            : exercises
                  .take(8)
                  .map(
                    (exercise) => _ImageTileData(
                      exercise.name,
                      _aurexPlaceholderAsset,
                      false,
                      exercise.imageUrl,
                    ),
                  )
                  .toList();

        return _HorizontalImageTiles(
          items: items,
          width: width,
          showTitle: false,
          onTap: onTap,
        );
      },
    );
  }
}

class _EquipmentTiles extends StatelessWidget {
  const _EquipmentTiles({
    required this.equipmentFuture,
    required this.fallbackItems,
    required this.width,
    required this.onTap,
  });

  final Future<List<MobileEquipment>> equipmentFuture;
  final List<_ImageTileData> fallbackItems;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MobileEquipment>>(
      future: equipmentFuture,
      builder: (context, snapshot) {
        final equipment =
            snapshot.data?.where((item) => item.isPublishedMobile).toList() ??
            const <MobileEquipment>[];
        final items = equipment.isEmpty
            ? fallbackItems
            : equipment
                  .take(8)
                  .map(
                    (item) => _ImageTileData(
                      item.name,
                      _aurexPlaceholderAsset,
                      false,
                    ),
                  )
                  .toList();

        return _HorizontalImageTiles(
          items: items,
          width: width,
          showTitle: false,
          onTap: onTap,
        );
      },
    );
  }
}

class _WorkoutLevelTiles extends StatelessWidget {
  const _WorkoutLevelTiles({required this.levelsFuture, required this.width});

  final Future<List<MobileWorkoutLevel>> levelsFuture;
  final double width;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MobileWorkoutLevel>>(
      future: levelsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return _HorizontalImageTilePlaceholders(width: width);
        }

        final levels =
            snapshot.data?.where((level) => level.isPublishedMobile).toList() ??
            const <MobileWorkoutLevel>[];

        if (levels.isEmpty) {
          return _HorizontalImageTilePlaceholders(width: width);
        }

        final items = levels
            .map(
              (level) => _ImageTileData(
                level.name,
                _aurexPlaceholderAsset,
                false,
                level.coverImageUrl,
              ),
            )
            .toList();

        return _HorizontalImageTiles(
          items: items,
          width: width,
          imageFit: BoxFit.contain,
          showTitle: false,
          allowAssetFallback: true,
        );
      },
    );
  }
}

class _HorizontalImageTiles extends StatelessWidget {
  const _HorizontalImageTiles({
    required this.items,
    required this.width,
    this.imageFit = BoxFit.cover,
    this.showTitle = true,
    this.allowAssetFallback = true,
    this.onTap,
  });

  final List<_ImageTileData> items;
  final double width;
  final BoxFit imageFit;
  final bool showTitle;
  final bool allowAssetFallback;
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _RemoteOrAssetImage(
                        imageUrl: item.imageUrl,
                        asset: item.image,
                        fit: imageFit,
                        allowAssetFallback: allowAssetFallback,
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
          );
        },
      ),
    );
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({
    required this.workoutsFuture,
    required this.fallbackItems,
  });

  final Future<List<MobileWorkout>> workoutsFuture;
  final List<_WorkoutData> fallbackItems;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MobileWorkout>>(
      future: workoutsFuture,
      builder: (context, snapshot) {
        final workouts =
            snapshot.data
                ?.where((workout) => workout.isPublishedMobile)
                .toList() ??
            const <MobileWorkout>[];
        final items = workouts.isEmpty
            ? fallbackItems
            : workouts
                  .take(8)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) => _WorkoutData(
                      entry.value.name,
                      _aurexPlaceholderAsset,
                      entry.value.coverImageUrl,
                    ),
                  )
                  .toList();

        return _WorkoutRail(items: items);
      },
    );
  }
}

class _WorkoutRail extends StatelessWidget {
  const _WorkoutRail({required this.items});

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
              child: _RemoteOrAssetImage(
                imageUrl: item.imageUrl,
                asset: item.image,
              ),
            ),
          );
        },
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
    this.image,
    this.highlight, [
    this.imageUrl = '',
  ]);

  final String title;
  final String image;
  final bool highlight;
  final String imageUrl;
}

class _WorkoutData {
  const _WorkoutData(this.title, this.image, [this.imageUrl = '']);

  final String title;
  final String image;
  final String imageUrl;
}

class _HorizontalImageTilePlaceholders extends StatelessWidget {
  const _HorizontalImageTilePlaceholders({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
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
