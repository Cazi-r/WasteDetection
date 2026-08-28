import 'package:flutter/material.dart';
import '../../models/recognition.dart';
import 'dart:math' as math;

class BoundingBoxPainter extends CustomPainter {
  final List<Recognition> recognitions;
  final Size previewSize;
  final Size screenSize;

  BoundingBoxPainter({
    required this.recognitions,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (recognitions.isEmpty ||
        previewSize.width == 0 ||
        previewSize.height == 0)
      return;

    // BoxFit.contain mantığına göre resmin ekrandaki yerini hesapla
    double scale = math.min(
      size.width / previewSize.width,
      size.height / previewSize.height,
    );

    double imageWidth = previewSize.width * scale;
    double imageHeight = previewSize.height * scale;

    double offsetX = (size.width - imageWidth) / 2;
    double offsetY = (size.height - imageHeight) / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    );

    for (var recognition in recognitions) {
      paint.color = _getCategoryColor(recognition.label);

      // Koordinatları hesapla (Null safety: değer yoksa 0.0 al)
      final double rX = recognition.x ?? 0.0;
      final double rY = recognition.y ?? 0.0;
      final double rW = recognition.w ?? 0.0;
      final double rH = recognition.h ?? 0.0;

      final double left = offsetX + (rX * imageWidth);
      final double top = offsetY + (rY * imageHeight);
      final double width = rW * imageWidth;
      final double height = rH * imageHeight;

      final Rect rect = Rect.fromLTWH(left, top, width, height);

      // Kutuyu çiz
      canvas.drawRect(rect, paint);

      // Etiket çizimi
      final String labelText =
          "${recognition.label} ${(recognition.confidence * 100).toStringAsFixed(0)}%";
      final TextSpan span = TextSpan(text: labelText, style: textStyle);
      final TextPainter textPainter = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Etiket konumunu ayarla (Çakışmayı önlemek için basit kaydırma)
      // Aynı kutuya sahip önceki etiketleri say
      int stackIndex = 0;
      for (var other in recognitions) {
        if (other == recognition) break;
        // Eğer koordinatlar çok yakınsa (aynı nesne veya classification sonucu)
        final double oX = other.x ?? 0.0;
        final double oY = other.y ?? 0.0;

        if ((oX - rX).abs() < 0.01 && (oY - rY).abs() < 0.01) {
          stackIndex++;
        }
      }

      final double labelHeight = textPainter.height + 4;
      // Etiketi kutunun üstüne, eğer yer yoksa veya çakışma varsa yukarı doğru sırala
      final double labelTop =
          top - labelHeight - (stackIndex * (labelHeight + 2));

      // Etiket arka planı
      canvas.drawRect(
        Rect.fromLTWH(left, labelTop, textPainter.width + 8, labelHeight),
        Paint()..color = paint.color,
      );

      // Etiketi yaz
      textPainter.paint(canvas, Offset(left + 4, labelTop + 2));
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'plastik':
        return Colors.blue;
      case 'kağıt':
      case 'kagit':
        return Colors.brown;
      case 'metal':
        return Colors.grey;
      case 'cam':
        return Colors.green;
      case 'organik':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
