import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../auth/auth_models.dart';
import '../auth/user_avatar.dart';

/// Header profil yang collapsing: foto besar + nama + email di tengah,
/// mengecil jadi app bar ramping (foto kecil di kiri, nama di samping).
class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AppUser? user;
  final String name;
  final String subtitle;
  final String badge;
  final bool dark;
  final double top;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  ProfileHeaderDelegate({
    required this.user,
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.dark,
    required this.top,
    required this.onBack,
    required this.onEdit,
  });

  static const _expanded = 262.0;
  static const _collapsed = 60.0;

  @override
  double get maxExtent => top + _expanded;
  @override
  double get minExtent => top + _collapsed;

  @override
  bool shouldRebuild(covariant ProfileHeaderDelegate old) =>
      old.user?.photoUrl != user?.photoUrl ||
      old.name != name ||
      old.subtitle != subtitle ||
      old.badge != badge ||
      old.dark != dark ||
      old.top != top ||
      (old.onEdit == null) != (onEdit == null);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(t);
    final width = MediaQuery.of(context).size.width;
    final gradient = AppColors.homeHeader(dark);
    final radius = Radius.circular(32 - 10 * t);

    final avatarSize = 98.0 - 62.0 * e; // 98 -> 36
    final avatarLeft = (width - avatarSize) / 2 + ((60 - (width - avatarSize) / 2)) * e;
    final avatarTop = top + 56 - 44 * e;

    final fade = (1 - t * 2.4).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(bottom: radius),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.blue600.withValues(alpha: 0.18 + 0.1 * t),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: radius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Hiasan lingkaran lembut di latar (memudar saat collapse).
            Positioned(
              right: -40 - 20 * t,
              top: top - 30,
              child: _Bubble(size: 190, opacity: 0.10 * fade),
            ),
            Positioned(
              left: -50,
              top: top + 90 - 30 * t,
              child: _Bubble(size: 150, opacity: 0.08 * fade),
            ),

            // Foto: membesar di tengah, mengecil ke kiri saat collapse.
            Positioned(
              left: avatarLeft,
              top: avatarTop,
              child: Container(
                padding: EdgeInsets.all(4 - 1.5 * e),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18 * fade),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: UserAvatar(user: user, size: avatarSize - (8 - 3 * e)),
              ),
            ),

            // Nama: di tengah (besar) -> kiri, sejajar app bar (kecil).
            Positioned(
              left: 20 + 84 * e,
              right: 20 + 36 * e + (onEdit != null ? 24 * e : 0),
              top: top + 166 - 146 * e,
              child: Align(
                alignment: Alignment(-e, 0),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 - 5 * e,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (subtitle.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                top: top + 196,
                child: Opacity(
                  opacity: fade,
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if (badge.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: top + 222,
                child: Opacity(
                  opacity: fade,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Tombol kembali & ubah nama.
            Positioned(
              left: 12,
              top: top + 10,
              child: _RoundBtn(icon: AppIcons.back, tooltip: 'Kembali', onTap: onBack),
            ),
            if (onEdit != null)
              Positioned(
                right: 12,
                top: top + 10,
                child: _RoundBtn(icon: AppIcons.pencil, tooltip: 'Ubah nama', onTap: onEdit!),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 19, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
