import 'package:flutter/material.dart';
import 'brand.dart';

/// Logo de Financially: la F en menta con el punto durazno sobre un cuadro
/// redondeado (el mismo dibujo que el ícono de la app,
/// `res/drawable/ic_launcher_foreground.xml`).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.background = Brand.deep});

  final double size;

  /// Fondo del cuadro. Sobre el verde profundo (splash, bienvenida) conviene
  /// [Brand.deepCard] para que el cuadro se distinga.
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Financially',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(background),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.background);

  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujo en una cuadrícula de 96 × 96, escalada al tamaño pedido
    canvas.scale(size.width / 96);
    RRect r(double x, double y, double w, double h, double radio) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radio));

    canvas.drawRRect(r(0, 0, 96, 96, 24), Paint()..color = background);
    final menta = Paint()..color = Brand.mint;
    canvas.drawRRect(r(30, 22, 13, 52, 4), menta); // trazo vertical
    canvas.drawRRect(r(30, 22, 38, 13, 4), menta); // brazo superior
    canvas.drawRRect(r(30, 43, 27, 12, 4), menta); // brazo del medio
    canvas.drawCircle(const Offset(68, 67), 7, Paint()..color = Brand.peach);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.background != background;
}
