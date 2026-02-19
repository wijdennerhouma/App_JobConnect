import 'package:flutter/material.dart';
import 'glass_container.dart';

/// Skeleton placeholder with glassmorphism style and subtle pulse.
class GlassSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const GlassSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends State<GlassSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.grey;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: baseColor.withOpacity(_animation.value * 0.15),
          ),
        );
      },
    );
  }
}

/// Skeleton that mimics a job card layout.
class GlassJobCardSkeleton extends StatelessWidget {
  const GlassJobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final padding = isWeb ? 24.0 : 20.0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding - 4, vertical: 8),
      child: GlassContainer(
        borderRadius: 24,
        padding: EdgeInsets.all(padding),
        opacity: 0.2,
        blur: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassSkeleton(width: 56, height: 56, borderRadius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlassSkeleton(height: 20, borderRadius: 8),
                      const SizedBox(height: 8),
                      const GlassSkeleton(height: 14, width: 120, borderRadius: 6),
                      const SizedBox(height: 6),
                      const GlassSkeleton(height: 12, width: 180, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GlassSkeleton(height: 28, width: 80, borderRadius: 8),
                const SizedBox(width: 8),
                GlassSkeleton(height: 28, width: 70, borderRadius: 8),
                const SizedBox(width: 8),
                GlassSkeleton(height: 28, width: 60, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 16),
            const GlassSkeleton(height: 14, borderRadius: 6),
            const SizedBox(height: 6),
            const GlassSkeleton(height: 14, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list for job lists or application lists.
class GlassJobListSkeleton extends StatelessWidget {
  final int itemCount;

  const GlassJobListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (_, __) => const GlassJobCardSkeleton(),
    );
  }
}
