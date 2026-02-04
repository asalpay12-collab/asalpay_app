import 'package:flutter/material.dart';
import 'package:logo_n_spinner/src/paint_arc.dart';

class Logospinner2 extends StatefulWidget {
  final String imageAssets;
  final bool reverse;
  final Color arcColor;
  final Duration spinSpeed;
  final double spinnerRadius; // New parameter

  const Logospinner2({
    Key? key,
    required this.imageAssets,
    this.reverse = false,
    this.spinSpeed = const Duration(seconds: 2),
    this.arcColor = Colors.blueAccent,
    this.spinnerRadius = 40.0, // Default size
  }) : super(key: key);

  @override
  State<Logospinner2> createState() => _Logospinner2State();
}

class _Logospinner2State extends State<Logospinner2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> animationRotation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.spinSpeed,
    );
    
    animationRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
    
    _controller.repeat(reverse: widget.reverse);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.spinnerRadius,
      height: widget.spinnerRadius,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo image (scaled to spinner size)
            SizedBox(
              width: widget.spinnerRadius * 0.9, // 60% of spinner size
              height: widget.spinnerRadius * 0.9, // 60% of spinner size
              child: Image.asset(
                widget.imageAssets,
                fit: BoxFit.contain,
              ),
            ),
            
            // Spinning arc
            RotationTransition(
              turns: animationRotation,
              child: buildRing(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRing() {
    return CustomPaint(
      size: Size(widget.spinnerRadius, widget.spinnerRadius),
      painter: _ArcPainter(
        arcColor: widget.arcColor,
        spinnerRadius: widget.spinnerRadius,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color arcColor;
  final double spinnerRadius;

  _ArcPainter({required this.arcColor, required this.spinnerRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = arcColor
      ..strokeWidth = spinnerRadius * 0.08 // Responsive stroke width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = spinnerRadius * 0.45; // Slightly smaller than container

    // Draw two arcs (top and bottom)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _degreeToRadian(2),
      _degreeToRadian(40), // Longer arc segment
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _degreeToRadian(182),
      _degreeToRadian(40), // Longer arc segment
      false,
      paint,
    );
  }

  double _degreeToRadian(double degree) {
    return degree * (3.1415926535 / 180);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}