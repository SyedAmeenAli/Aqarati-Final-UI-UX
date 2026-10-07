import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/property.dart';

enum _GalleryCategory { all, video, floorPlan }

extension on _GalleryCategory {
  String get label {
    switch (this) {
      case _GalleryCategory.all:
        return 'Photos';
      case _GalleryCategory.video:
        return 'Video';
      case _GalleryCategory.floorPlan:
        return 'Floor Plan';
    }
  }
}

/// Dark, editorial media viewer — deliberately breaks from the light app
/// theme, matching the Figma gallery's dark chrome for photography focus.
class PropertyGalleryScreen extends StatefulWidget {
  final Property property;

  const PropertyGalleryScreen({super.key, required this.property});

  @override
  State<PropertyGalleryScreen> createState() => _PropertyGalleryScreenState();
}

class _PropertyGalleryScreenState extends State<PropertyGalleryScreen> {
  _GalleryCategory _category = _GalleryCategory.all;
  int _index = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.property.imageUrls;
    final videos = widget.property.videoUrls;
    final isFloorPlan = _category == _GalleryCategory.floorPlan;
    final isVideo = _category == _GalleryCategory.video;
    final categories = [
      _GalleryCategory.all,
      if (videos.isNotEmpty) _GalleryCategory.video,
      _GalleryCategory.floorPlan,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  isFloorPlan
                      ? const _FloorPlanUnavailableView()
                      : isVideo
                          ? _VideoView(videoUrls: videos)
                          : images.isEmpty
                              ? const _EmptyMediaView()
                              : _PhotoPageView(
                                  controller: _pageController,
                                  imageUrls: images,
                                  onPageChanged: (i) => setState(() => _index = i),
                                ),
                  Positioned(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: _GlassIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                  ),
                  Positioned(
                    right: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: _GlassIconButton(icon: Icons.ios_share_rounded, onTap: () {}),
                  ),
                  if (!isFloorPlan && !isVideo && images.isNotEmpty)
                    Positioned(
                      bottom: AppSpacing.md,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text('${_index + 1} / ${images.length}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.property.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(widget.property.locationLabel.split(',').take(2).join(','), style: const TextStyle(color: Colors.white60, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(widget.property.price.compact, style: const TextStyle(color: AppColors.red400, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final selected = cat == _category;
                    return ChoiceChip(
                      label: Text(cat.label),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                      side: BorderSide.none,
                      onSelected: (_) => setState(() {
                        _category = cat;
                        _index = 0;
                      }),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _PhotoPageView extends StatelessWidget {
  final PageController controller;
  final List<String> imageUrls;
  final ValueChanged<int> onPageChanged;

  const _PhotoPageView({required this.controller, required this.imageUrls, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: imageUrls.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Image.asset(
            imageUrls[i],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const Center(
              child: Icon(Icons.landscape_outlined, size: 64, color: Colors.white24),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyMediaView extends StatelessWidget {
  const _EmptyMediaView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No photos available yet', style: TextStyle(color: Colors.white54)),
    );
  }
}

class _VideoView extends StatefulWidget {
  final List<String> videoUrls;

  const _VideoView({required this.videoUrls});

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  VideoPlayerController? _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  void _load(int i) {
    _controller?.dispose();
    if (widget.videoUrls.isEmpty) return;
    final controller = VideoPlayerController.asset(widget.videoUrls[i]);
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrls.isEmpty) {
      return const Center(
        child: Text('No video available for this property', style: TextStyle(color: Colors.white54)),
      );
    }
    final controller = _controller;
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Center(
              child: controller != null && controller.value.isInitialized
                  ? GestureDetector(
                      onTap: () => setState(() {
                        controller.value.isPlaying ? controller.pause() : controller.play();
                      }),
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(controller),
                            if (!controller.value.isPlaying)
                              const Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white70),
                          ],
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(color: Colors.white70),
            ),
          ),
        ),
        if (widget.videoUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: widget.videoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() {
                    _index = i;
                    _load(i);
                  }),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : Colors.white12,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.videocam_outlined, color: i == _index ? Colors.white : Colors.white54, size: 18),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: Colors.white, size: AppIconSize.compact),
        ),
      ),
    );
  }
}

class _FloorPlanUnavailableView extends StatelessWidget {
  const _FloorPlanUnavailableView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, size: 48, color: Colors.white24),
            SizedBox(height: AppSpacing.md),
            Text('Floor plan not available for this listing', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
