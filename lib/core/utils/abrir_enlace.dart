import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/brand.dart';

/// Abre [url] en el navegador del teléfono. Si no se puede (sin navegador o
/// sin conexión al abrirlo), avisa con un mensaje.
Future<void> abrirEnlace(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showBrandSnack(context, 'No se pudo abrir el enlace: $url');
  }
}
