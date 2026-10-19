import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Renders a book cover from either:
/// 1. A Base64 Data URI (`data:image/...;base64,...`) from gallery picker
/// 2. A regular Web URL (`http://...` or `https://...`)
/// 3. A fallback gradient & icon when no image is available or on error.
class BookCoverImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const BookCoverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();

    Widget imageWidget;

    if (trimmed.startsWith('data:image') || _isLikelyBase64(trimmed)) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64String =
            commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final Uint8List bytes = base64Decode(base64String);

        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (_) {
        imageWidget = _buildFallback();
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      imageWidget = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  bool _isLikelyBase64(String str) {
    return str.length > 200 && !str.contains(' ') && !str.startsWith('http');
  }

  Widget _buildFallback() {
    if (fallback != null) return fallback!;

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
