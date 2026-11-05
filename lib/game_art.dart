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
  final int seed;
  final Widget Function(BuildContext, double, Widget)? builder;
  const _ArtMotion(
      {required this.child,
      this.active = true,
      this.amplitude = 2,
      this.seed = 0,
      this.builder});

  @override
  State<_ArtMotion> createState() => _ArtMotionState();
}

class _ArtMotionState extends State<_ArtMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: Duration(milliseconds: 6400 + widget.seed * 173));
  bool _enabled = false;

  void _sync() {
    // Keep compatibility with the project's Flutter 3.16 minimum.
    final animate = widget.active &&
        !MediaQuery.of(context).disableAnimations &&
        // ignore: deprecated_member_use
        TickerMode.of(context);
    _enabled = animate;
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
    _controller.duration = Duration(milliseconds: 6400 + widget.seed * 173);
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
        builder: (context, child) {
          final phase =
              _enabled ? (_controller.value + widget.seed * .137) % 1 : 0.0;
          return Transform.translate(
            offset: Offset(
                0,
                (math.sin(phase * math.pi * 4) * widget.amplitude)
                    .roundToDouble()),
            child: widget.builder?.call(context, phase, child!) ?? child,
          );
        },
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
      this.size = 56});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final accent = bidder.taunted
        ? Colors.redAccent
        : leading
            ? Colors.amber
            : Colors.blueGrey;
    return Semantics(
      label:
          '${bidder.name}${bidder.taunted ? ', angry after being taunted' : ''}',
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
            seed: bidder.persona.index,
            amplitude: 1,
            builder: (context, phase, child) {
              // Brief blink, then a longer sideways glance; idle dominates.
              final frame = phase > .42 && phase < .445
                  ? 1
                  : phase > .72 && phase < .82
                      ? 2
                      : 0;
              return Transform.translate(
                offset: Offset(
                    bidder.taunted && phase > .85
                        ? math.sin(phase * math.pi * 48).roundToDouble()
                        : leading && phase > .55 && phase < .7
                            ? 1
                            : 0,
                    0),
                child: Padding(
                    padding: const EdgeInsets.all(3),
                    // Keep every rival square even when a parent (such as a
                    // dense ListTile leading slot) offers a shorter box.
                    child: Center(
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: _AtlasTile(
                                bidder.taunted
                                    ? 'assets/art/rivals-angry-v1.png'
                                    : frame == 0
                                        ? 'assets/art/rivals-neutral-v3.png'
                                        : 'assets/art/rivals-idle-v3.png',
                                bidder.persona.index +
                                    (bidder.taunted ? 0 : frame * 10),
                                5,
                                bidder.taunted ? 2 : 6)))),
              );
            },
            child: const SizedBox.shrink(),
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
              amplitude: artifact.category == Category.idol ? 1 : 2,
              seed: artifactArtIndex(artifact),
              builder: (context, phase, child) => Stack(
                fit: StackFit.expand,
                children: [
                  // Tiny stepped rocking; heavy idols stay planted upright.
                  Transform.rotate(
                    angle: artifact.category == Category.idol
                        ? 0
                        : (math.sin(phase * math.pi * 2) * 2).round() * .012,
                    filterQuality: FilterQuality.none,
                    child: child,
                  ),
                  IgnorePointer(
                      child: CustomPaint(
                    painter: _ArtifactGlint(phase, artifact.category),
                  )),
                ],
              ),
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _AtlasTile('assets/art/artifacts-pixel-v2.png',
                      artifactArtIndex(artifact), 4, 4)),
            ),
          ),
        ),
      );
}

/// Sparse pixel highlights are decorative, never indicators of a hidden curse.
class _ArtifactGlint extends CustomPainter {
  final double phase;
  final Category category;
  const _ArtifactGlint(this.phase, this.category);

  @override
  void paint(Canvas canvas, Size size) {
    if (phase < .55 || phase > .68) return;
    final bright = phase > .59 && phase < .64;
    final paint = Paint()
      ..isAntiAlias = false
      ..color =
          (category == Category.tome ? Colors.tealAccent : Colors.amberAccent)
              .withAlpha(bright ? 210 : 100);
    final x = (size.width * .67).roundToDouble();
    final y = (size.height * .28).roundToDouble();
    canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), paint);
    if (bright) {
      canvas.drawRect(Rect.fromLTWH(x - 2, y, 6, 2), paint);
      canvas.drawRect(Rect.fromLTWH(x, y - 2, 2, 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArtifactGlint oldDelegate) =>
      phase != oldDelegate.phase || category != oldDelegate.category;
}
