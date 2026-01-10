import 'dart:io';

import 'package:image/image.dart' as img;

const _brandTealArgb = 0xFF005F5C;

void main(List<String> args) {
  final repoRoot = Directory.current;
  final outDir = Directory('${repoRoot.path}/assets/branding');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final iconPath = File('${outDir.path}/saripos_icon_1024.png');
  final splashPath = File('${outDir.path}/saripos_splash_mark_1024.png');

  final icon = _renderIcon(size: 1024);
  iconPath.writeAsBytesSync(img.encodePng(icon, level: 9));

  final splash = _renderSplashMark(size: 1024);
  splashPath.writeAsBytesSync(img.encodePng(splash, level: 9));

  stdout.writeln('Generated: ${iconPath.path}');
  stdout.writeln('Generated: ${splashPath.path}');
}

img.Image _renderIcon({required int size}) {
  final image = img.Image(width: size, height: size);
  img.fill(image, color: _colorFromArgb(_brandTealArgb));

  // Receipt card (simple rounded rectangle)
  final receiptW = (size * 0.54).round();
  final receiptH = (size * 0.66).round();
  final receiptX = ((size - receiptW) / 2).round();
  final receiptY = (size * 0.18).round();
  _fillRoundedRect(
    image,
    x: receiptX,
    y: receiptY,
    w: receiptW,
    h: receiptH,
    r: (size * 0.07).round(),
    color: _colorFromArgb(0xF2FFFFFF),
  );

  // Header + item lines (teal with low alpha)
  final lineColor = _colorFromArgb(_withAlpha(_brandTealArgb, 40));
  _fillRoundedRect(
    image,
    x: receiptX + (receiptW * 0.10).round(),
    y: receiptY + (receiptH * 0.12).round(),
    w: (receiptW * 0.72).round(),
    h: (receiptH * 0.09).round(),
    r: (size * 0.03).round(),
    color: lineColor,
  );

  void itemLine(double yFrac, double wFrac) {
    _fillRoundedRect(
      image,
      x: receiptX + (receiptW * 0.10).round(),
      y: receiptY + (receiptH * yFrac).round(),
      w: (receiptW * wFrac).round(),
      h: (receiptH * 0.075).round(),
      r: (size * 0.028).round(),
      color: _colorFromArgb(_withAlpha(_brandTealArgb, 45)),
    );
  }

  itemLine(0.30, 0.58);
  itemLine(0.42, 0.66);
  itemLine(0.54, 0.50);

  // Check badge
  final badgeR = (size * 0.11).round();
  final badgeCx = receiptX + (receiptW * 0.78).round();
  final badgeCy = receiptY + (receiptH * 0.68).round();

  img.fillCircle(
    image,
    x: badgeCx,
    y: badgeCy,
    radius: badgeR,
    color: _colorFromArgb(_withAlpha(_brandTealArgb, 46)),
  );

  // Checkmark (thick lines)
  final p1 = (badgeCx - (badgeR * 0.35)).round();
  final p1y = (badgeCy + (badgeR * 0.05)).round();
  final p2 = (badgeCx - (badgeR * 0.05)).round();
  final p2y = (badgeCy + (badgeR * 0.32)).round();
  final p3 = (badgeCx + (badgeR * 0.45)).round();
  final p3y = (badgeCy - (badgeR * 0.30)).round();

  _drawThickLine(image, x1: p1, y1: p1y, x2: p2, y2: p2y, thickness: (size * 0.018).round(), color: _colorFromArgb(_brandTealArgb));
  _drawThickLine(image, x1: p2, y1: p2y, x2: p3, y2: p3y, thickness: (size * 0.018).round(), color: _colorFromArgb(_brandTealArgb));

  return image;
}

img.Image _renderSplashMark({required int size}) {
  // Transparent background; mark is white so it sits on teal splash background.
  final image = img.Image(width: size, height: size);
  img.fill(image, color: _colorFromArgb(0x00000000));

  final receiptW = (size * 0.56).round();
  final receiptH = (size * 0.66).round();
  final receiptX = ((size - receiptW) / 2).round();
  final receiptY = ((size - receiptH) / 2).round();

  _fillRoundedRect(
    image,
    x: receiptX,
    y: receiptY,
    w: receiptW,
    h: receiptH,
    r: (size * 0.075).round(),
    color: _colorFromArgb(0xF2FFFFFF),
  );

  // Simple header lines (subtle white alpha variation)
  _fillRoundedRect(
    image,
    x: receiptX + (receiptW * 0.12).round(),
    y: receiptY + (receiptH * 0.14).round(),
    w: (receiptW * 0.70).round(),
    h: (receiptH * 0.095).round(),
    r: (size * 0.03).round(),
    color: _colorFromArgb(0x22FFFFFF),
  );

  void itemLine(double yFrac, double wFrac) {
    _fillRoundedRect(
      image,
      x: receiptX + (receiptW * 0.12).round(),
      y: receiptY + (receiptH * yFrac).round(),
      w: (receiptW * wFrac).round(),
      h: (receiptH * 0.075).round(),
      r: (size * 0.028).round(),
      color: _colorFromArgb(0x28FFFFFF),
    );
  }

  itemLine(0.34, 0.58);
  itemLine(0.46, 0.66);
  itemLine(0.58, 0.50);

  // Badge and check in white
  final badgeR = (size * 0.115).round();
  final badgeCx = receiptX + (receiptW * 0.80).round();
  final badgeCy = receiptY + (receiptH * 0.70).round();
  img.fillCircle(
    image,
    x: badgeCx,
    y: badgeCy,
    radius: badgeR,
    color: _colorFromArgb(0x22FFFFFF),
  );

  final p1 = (badgeCx - (badgeR * 0.35)).round();
  final p1y = (badgeCy + (badgeR * 0.05)).round();
  final p2 = (badgeCx - (badgeR * 0.05)).round();
  final p2y = (badgeCy + (badgeR * 0.32)).round();
  final p3 = (badgeCx + (badgeR * 0.45)).round();
  final p3y = (badgeCy - (badgeR * 0.30)).round();

  _drawThickLine(
    image,
    x1: p1,
    y1: p1y,
    x2: p2,
    y2: p2y,
    thickness: (size * 0.018).round(),
    color: _colorFromArgb(0xF2FFFFFF),
  );
  _drawThickLine(
    image,
    x1: p2,
    y1: p2y,
    x2: p3,
    y2: p3y,
    thickness: (size * 0.018).round(),
    color: _colorFromArgb(0xF2FFFFFF),
  );

  return image;
}

void _fillRoundedRect(
  img.Image image, {
  required int x,
  required int y,
  required int w,
  required int h,
  required int r,
  required img.Color color,
}) {
  final radius = r.clamp(0, (w < h ? w : h) ~/ 2);

  // Center rects
  img.fillRect(
    image,
    x1: x + radius,
    y1: y,
    x2: x + w - radius - 1,
    y2: y + h - 1,
    color: color,
  );
  img.fillRect(
    image,
    x1: x,
    y1: y + radius,
    x2: x + w - 1,
    y2: y + h - radius - 1,
    color: color,
  );

  // Corners
  img.fillCircle(image, x: x + radius, y: y + radius, radius: radius, color: color);
  img.fillCircle(image, x: x + w - radius - 1, y: y + radius, radius: radius, color: color);
  img.fillCircle(image, x: x + radius, y: y + h - radius - 1, radius: radius, color: color);
  img.fillCircle(image, x: x + w - radius - 1, y: y + h - radius - 1, radius: radius, color: color);
}

void _drawThickLine(
  img.Image image, {
  required int x1,
  required int y1,
  required int x2,
  required int y2,
  required int thickness,
  required img.Color color,
}) {
  final t = thickness.clamp(1, 64);
  final half = t ~/ 2;

  // Simple square brush around the line.
  for (var ox = -half; ox <= half; ox++) {
    for (var oy = -half; oy <= half; oy++) {
      img.drawLine(image, x1: x1 + ox, y1: y1 + oy, x2: x2 + ox, y2: y2 + oy, color: color);
    }
  }
}

img.Color _colorFromArgb(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = (argb) & 0xFF;
  return img.ColorRgba8(r, g, b, a);
}

int _withAlpha(int argb, int alpha) {
  final a = alpha.clamp(0, 255);
  return (a << 24) | (argb & 0x00FFFFFF);
}
