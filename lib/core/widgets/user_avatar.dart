import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? profileUrl;
  final bool isOnline;
  final double size;
  final bool showOnlineDot;

  const UserAvatar({
    super.key,
    required this.name,
    this.profileUrl,
    this.isOnline = false,
    this.size = 52,
    this.showOnlineDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final accent = AppTheme.avatarColorFor(name);
    final url = profileUrl ?? '';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                      child: SizedBox(
                        width: size * 0.35,
                        height: size * 0.35,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _Initials(
                      initials: initials,
                      color: accent,
                      size: size,
                    ),
                  )
                : _Initials(initials: initials, color: accent, size: size),
          ),
          if (showOnlineDot && isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppTheme.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.backgroundColor,
                    width: size * 0.05,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const _Initials({
    required this.initials,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.sora(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
