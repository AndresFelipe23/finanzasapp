import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'neo_bank_theme.dart';

/// Superficie de vidrio. `blur: false` omite el BackdropFilter y mantiene el
/// relleno translúcido — obligatorio dentro de listas con scroll.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.blur = true,
    this.blurSigma,
    this.strong = false,
    this.shadow = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool blur;
  final double? blurSigma;
  final bool strong;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = borderRadius ?? BorderRadius.circular(t.radiusMd);
    final sigma = blurSigma ?? t.blurCard;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: strong ? t.glassFillStrong : t.glassFill,
        borderRadius: radius,
      ),
      child: child,
    );

    if (blur) {
      content = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      );
    }

    Widget surface = CustomPaint(
      foregroundPainter: _GlassBorderPainter(
        radius: radius,
        start: t.glassStrokeStart,
        end: t.glassStrokeEnd,
      ),
      child: ClipRRect(borderRadius: radius, child: content),
    );

    if (onTap != null) {
      surface = Stack(
        children: [
          surface,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: t.accent.withValues(alpha: 0.08),
                highlightColor: t.accent.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      );
    }

    if (shadow) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: t.glassShadow,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: surface,
      );
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}

class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({
    required this.radius,
    required this.start,
    required this.end,
  });

  final BorderRadius radius;
  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
        start,
        end,
      ]);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassBorderPainter old) =>
      old.radius != radius || old.start != start || old.end != end;
}

/// Capa de fondo — gradiente y blobs de color. Es lo que el vidrio difumina.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.bgTop, t.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _Blob(color: t.blobAccent, size: 320),
          ),
          Positioned(
            top: 180,
            right: -110,
            child: _Blob(color: t.blobTransfer, size: 300),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: _Blob(color: t.blobSuccess, size: 280),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
