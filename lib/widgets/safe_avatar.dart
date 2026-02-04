// lib/widgets/safe_avatar.dart

import 'package:flutter/material.dart';
import 'package:asalpay/services/api_urls.dart';

const _fallbackAssetPath = 'assets/asalicon01.png';

/// Returns `null` for any “bad” imagePaths (null, empty, "0", "null",
/// contains the Somali error message, or fails to parse to a real host),
/// otherwise returns a well‑formed URL string.
String? sanitizeImageUrl(String? raw) {
  if (raw == null) return null;

  final s = raw.trim();
  if (s.isEmpty) return null;

  final lower = s.toLowerCase();

  // Drop any “null”, “0”, or known‑bad placeholders
  if (lower == 'null' ||
      lower == '0' ||
      lower.contains('path ayaa qaldan') ||
      lower.contains('path%20ayaa%20qaldan')) {
    return null;
  }

  // If it already starts with http(s), just validate it
  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      final uri = Uri.parse(s);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        return s;
      }
    } catch (_) {
      return null;
    }
  }

  // Otherwise prefix it once with your BASE_URL, encoding segments
  final prefix = ApiUrls.BASE_URL;
  String suffix = s;
  if (s.startsWith(prefix)) {
    // already has prefix
    suffix = s.substring(prefix.length);
  }
  // percent‑encode each path segment to avoid spaces, etc
  final encoded = suffix.split('/').map(Uri.encodeComponent).join('/');
  final candidate = '$prefix$encoded';

  // final validation
  try {
    final uri = Uri.parse(candidate);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      return candidate;
    }
  } catch (_) {
    // bad URI
  }

  return null;
}

class SafeAvatar extends StatelessWidget {
  /// your raw image field from the model
  final String? imagePath;

  /// diameter of the circle
  final double size;

  /// optional override for corner radius
  final BorderRadius? borderRadius;

  const SafeAvatar({
    Key? key,
    required this.imagePath,
    this.size = 42,
    this.borderRadius,
    required int radius,
    required String imageUrl,
  }) : super(key: key);

  /// Widget shown when there is no user image (icon instead of broken image).
  static Widget _buildPlaceholderIcon(double size) {
    return Icon(
      Icons.person,
      size: size * 0.6,
      color: Colors.white70,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = sanitizeImageUrl(imagePath);

    Widget img;
    if (safeUrl != null) {
      img = Image.network(
        safeUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildPlaceholderIcon(size);
        },
      );
    } else {
      img = _buildPlaceholderIcon(size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        child: img,
      ),
    );
  }
}
