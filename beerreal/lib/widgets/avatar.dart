import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_cache_manager.dart';
import '../core/avatar_color_util.dart';
import '../theme.dart';
import 'img_placeholder.dart';

class PintAvatar extends StatelessWidget {
  final ImgTone tone;
  final double size;
  final bool ring;
  final String? imageUrl;
  final String? initials;
  final String? avatarColor;

  const PintAvatar({
    super.key,
    this.tone = ImgTone.avatar,
    this.size = 40,
    this.ring = false,
    this.imageUrl,
    this.initials,
    this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring ? Border.all(color: t.gold, width: 2) : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                cacheManager: AppCacheManager.instance,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                memCacheWidth: (size * 3).ceil(),
                errorWidget: (_, __, ___) => _buildColoredAvatar(),
              )
            : _buildColoredAvatar(),
      ),
    );
  }

  Widget _buildColoredAvatar() {
    if (avatarColor != null && initials != null) {
      final bgColor = hexToColor(avatarColor);
      final textColor = shouldUseWhiteText(bgColor)
          ? Colors.white
          : Colors.black87;

      return Container(
        color: bgColor,
        child: Center(
          child: Text(
            initials!.toUpperCase(),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      );
    }
    return ImgPlaceholder(tone: tone);
  }
}
