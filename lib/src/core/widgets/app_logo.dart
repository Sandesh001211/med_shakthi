import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CleanLogoPainter()),
    );
  }
}

class _CleanLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Background rounded square
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final RRect rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(w * 0.24),
    );
    final Paint bgPaint = Paint()..color = const Color(0xFF5FA59A);
    canvas.drawRRect(rRect, bgPaint);

    // Thick stroke for body shapes
    final Paint bodyStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Thinner stroke for heartbeat
    final Paint heartStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint headFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 2. Heads
    final double headR = w * 0.10;
    final double headY = h * 0.29;
    canvas.drawCircle(Offset(w * 0.33, headY), headR, headFill);
    canvas.drawCircle(Offset(w * 0.67, headY), headR, headFill);

    // 3. Body arcs (neat tall shapes)
    final Path leftBody = Path()
      ..moveTo(w * 0.24, h * 0.63)
      ..quadraticBezierTo(w * 0.20, h * 0.37, w * 0.47, h * 0.39);

    final Path rightBody = Path()
      ..moveTo(w * 0.76, h * 0.63)
      ..quadraticBezierTo(w * 0.80, h * 0.37, w * 0.53, h * 0.39);

    canvas.drawPath(leftBody, bodyStroke);
    canvas.drawPath(rightBody, bodyStroke);

    // 4. Heartbeat (thin, across the middle)
    final double baseY = h * 0.58;
    final Path ecg = Path()
      ..moveTo(w * 0.16, baseY)
      ..lineTo(w * 0.34, baseY)
      ..lineTo(w * 0.40, baseY - h * 0.10)
      ..lineTo(w * 0.47, baseY + h * 0.05)
      ..lineTo(w * 0.55, baseY - h * 0.10)
      ..lineTo(w * 0.62, baseY)
      ..lineTo(w * 0.84, baseY);

    canvas.drawPath(ecg, heartStroke);

    // 5. Bottom arc REMOVED (no drawArc)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
