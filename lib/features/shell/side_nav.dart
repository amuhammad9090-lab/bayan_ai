import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../core/theme.dart';
import '../../shared/widgets/logo_mark.dart';
import '../auth/auth_provider.dart';
import '../auth/user_avatar.dart';
import '../profile/profile_page.dart';

/// Navigasi samping untuk layar lebar (pengganti bottom nav).
/// Sama seperti bottom nav: tab aktif berupa pil berwarna tab, ikon tab lain
/// ikut warna tab yang sedang dibuka.
class SideNav extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final List<Color> colors;
  final ValueChanged<int> onTap;
  const SideNav({
    super.key,
    required this.index,
    required this.items,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final active = colors[index];
    final idle = dark ? Color.lerp(active, Colors.white, 0.35)! : active;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: context.cs.surface,
        border: Border(right: BorderSide(color: context.border)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const LogoMark(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          kAppName,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Al-Qur\'an & Nahwu',
                          style: TextStyle(fontSize: 11.5, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: idle),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                builder: (context, idleNow, _) => Column(
                  children: [
                    for (var k = 0; k < items.length; k++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _SideItem(
                          icon: items[k].$1,
                          label: items[k].$2,
                          selected: k == index,
                          color: colors[k],
                          idleColor: idleNow ?? idle,
                          onTap: () => onTap(k),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              const _UserTile(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final Color idleColor;
  final VoidCallback onTap;
  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.idleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected && !context.isDark
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : idleColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Akun di bagian bawah sidebar; ketuk untuk membuka Profil.
class _UserTile extends StatelessWidget {
  const _UserTile();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final guest = auth.status == AuthStatus.guest;
    final user = guest ? null : auth.user;
    return Material(
      color: context.surface2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: guest ? null : () => openProfile(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              UserAvatar(user: user, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest ? 'Tamu' : (user?.shownName ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    if (!guest && (user?.email.isNotEmpty ?? false))
                      Text(
                        user!.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: context.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
