import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/Constant.dart';

/// Reusable background for 252PAY screens — matches Ewareeji (gradient secondryColor → secondryColor 0.82).
class Pay252ScreenBackground extends StatelessWidget {
  const Pay252ScreenBackground({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // Stronger gradient so 252pay body is visibly different from a flat bar color
    // (was secondry → secondry@0.82: nearly invisible on screen).
    final bottomShade = Color.lerp(secondryColor, Colors.black, 0.42)!;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            secondryColor,
            Color.lerp(secondryColor, bottomShade, 0.55)!,
            bottomShade,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// App bar gradient style for 252PAY using app primary and secondary colors.
BoxDecoration pay252AppBarGradient() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        secondryColor,
        secondryColor,
        primaryColor.withValues(alpha: 0.85),
      ],
      stops: const [0.0, 0.6, 1.0],
    ),
  );
}

/// Card decoration for 252PAY — matches Ewareeji _sectionCard (white, 16 radius, soft shadow).
BoxDecoration pay252CardDecoration({bool elevated = true}) {
  return BoxDecoration(
    color: pureWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : null,
  );
}

/// Section header on gradient — matches Ewareeji (white text on gradient).
class Pay252SectionHeader extends StatelessWidget {
  const Pay252SectionHeader({
    super.key,
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: Colors.white.withOpacity(0.95)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
