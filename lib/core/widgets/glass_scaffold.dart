import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Mandatory Reusable Widget #1: GlassScaffold
/// Provides Deep Navy Slate (#0F172A) canvas + 2-3 static ambient radial glow orbs
/// so BackdropFilter frosted glass surfaces have visual depth without heavy animations.
class GlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool showTertiaryOrb;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.showTertiaryOrb = false,
    this.extendBody = true,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Deep Navy Slate base gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgCanvasDeep,
                  AppColors.bgCanvas,
                ],
              ),
            ),
          ),
          // Static Ambient Radial Orbs (wrapped in RepaintBoundary for 60 FPS)
          RepaintBoundary(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Orb 1 (Top-Left): Electric Indigo 18% -> 0%
                  const Positioned(
                    top: -120,
                    left: -100,
                    child: _AmbientOrb(
                      size: 380,
                      color: AppColors.orbPrimary,
                    ),
                  ),
                  // Orb 2 (Bottom-Right): Emerald Green 12% -> 0%
                  const Positioned(
                    bottom: -140,
                    right: -110,
                    child: _AmbientOrb(
                      size: 400,
                      color: AppColors.orbSecondary,
                    ),
                  ),
                  // Orb 3 (Optional Center Accent for Admin/Kasir): Vivid Amber 8% -> 0%
                  if (showTertiaryOrb)
                    const Positioned(
                      top: 220,
                      right: -80,
                      child: _AmbientOrb(
                        size: 320,
                        color: AppColors.orbTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Foreground content
          body,
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
