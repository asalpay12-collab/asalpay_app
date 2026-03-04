import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable search field for 252PAY (categories, subcategories, products).
/// Rounded container, search icon, optional clear button, hint text.
class Pay252SearchBar extends StatelessWidget {
  const Pay252SearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.primaryColor,
    this.cardBg,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final Color? primaryColor;
  final Color? cardBg;

  static const Color _defaultPrimary = Color(0xFF005653);
  static const Color _defaultCardBg = Color(0xFFF8FAFA);
  static final BorderRadius _br = BorderRadius.circular(12);

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? _defaultPrimary;
    final bg = cardBg ?? _defaultCardBg;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _br,
        border: Border.all(color: primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          prefixIcon: Icon(Icons.search, color: primary, size: 22),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.clear, color: primary, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: _br,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: _br,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _br,
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
