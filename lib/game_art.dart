import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

/// Public appearance only: never select art or motion from a hidden curse or tell.
int artifactArtIndex(Artifact artifact) {
  if (artifact.name == 'Crown of Nine Sorrows') return 15;
  const nouns = [
    'Urn',
    'Reliquary',
    'Mask',
    'Dagger',
    'Scythe',
    'Blade',
    'Grimoire',
    'Codex',
    'Scroll',
    'Crown',
    'Amulet',
    'Locket',
    'Idol',
    'Effigy',
    'Totem'
  ];
  final index = nouns.indexWhere((noun) => artifact.name.endsWith(noun));
  return index < 0 ? artifact.category.index * 3 : index;
}

class _AtlasTile extends StatelessWidget {
  final String asset;
  final int index, columns, rows;
  const _AtlasTile(this.asset, this.index, this.columns, this.rows);

  @override
  Widget build(BuildContext context) => ClipRect(
        child: LayoutBuilder(
            builder: (context, bounds) => Stack(children: [
                  Positioned(
                    left: -(index % columns) * bounds.maxWidth,
                    top: -(index ~/ columns) * bounds.maxHeight,
                    width: bounds.maxWidth * columns,
                    height: bounds.maxHeight * rows,
                    child: Image.asset(asset,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                        isAntiAlias: false,
                        excludeFromSemantics: true),
                  ),
                ])),
      );
}

/// One lightweight motion controller, paused for reduced motion and offstage UI.
class _ArtMotion extends StatefulWidget {
  final Widget child;
  final bool active;
  final double amplitude;
  const _ArtMotion(
      {required this.child, this.active = true, this.amplitude = 2});

  @override
  State<_ArtMotion> createState() => _ArtMotionState();
}

class _ArtMotionState extends State<_ArtMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200));

  void _sync() {
    // Keep compatibility with the project's Flutter 3.16 minimum.
    final animate = widget.active &&
        !MediaQuery.of(context).disableAnimations &&
        // ignore: deprecated_member_use
        TickerMode.of(context);
    if (animate && !_controller.isAnimating) _controller.repeat();
    if (!animate) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ArtMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(
              0,
              (math.sin(_controller.value * math.pi * 2) * widget.amplitude)
                  .roundToDouble()),
          child: child,
        ),
      );
}

class RivalPortrait extends StatelessWidget {
  final Bidder bidder;
  final bool leading, animate;
  final double size;
  const RivalPortrait(
      {super.key,
      required this.bidder,
      this.leading = false,
      this.animate = true,
      this.size = 52});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final accent = bidder.taunted
        ? Colors.redAccent
        : leading
            ? Colors.amber
            : Colors.blueGrey;
    return Semantics(
      label: bidder.name,
      image: true,
      child: AnimatedContainer(
        duration: Duration(milliseconds: reduced ? 0 : 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: accent.withAlpha(leading || bidder.taunted ? 230 : 64)),
        ),
        child: AnimatedOpacity(
          opacity: bidder.folded ? .3 : 1,
          duration: Duration(milliseconds: reduced ? 0 : 250),
          child: _ArtMotion(
            active: animate && !bidder.folded,
            amplitude: bidder.taunted
                ? 2.5
                : leading
                    ? 1.8
                    : .8,
            child: Padding(
                padding: const EdgeInsets.all(3),
                child: _AtlasTile('assets/art/rivals-pixel-v2.png',
                    bidder.persona.index, 5, 2)),
          ),
        ),
      ),
    );
  }
}

class ArtifactDisplay extends StatelessWidget {
  final Artifact artifact;
  final double size;
  const ArtifactDisplay({super.key, required this.artifact, this.size = 104});

  @override
  Widget build(BuildContext context) => Semantics(
        label: artifact.name,
        image: true,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [Color(0x553E827A), Color(0x00212530)])),
            child: _ArtMotion(
              amplitude: 3,
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _AtlasTile('assets/art/artifacts-pixel-v2.png',
                      artifactArtIndex(artifact), 4, 4)),
            ),
          ),
        ),
      );
}
