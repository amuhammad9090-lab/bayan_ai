part of 'home_page.dart';

// Header Beranda: banner collapsing, sapaan, kolom cari + filter.

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double top;
  final bool dark;
  final TextEditingController controller;
  final String hint;
  final bool filtered;
  final ValueChanged<String> onSubmit;
  final VoidCallback onFilter;
  _HomeHeaderDelegate({
    required this.top,
    required this.dark,
    required this.controller,
    required this.hint,
    required this.filtered,
    required this.onSubmit,
    required this.onFilter,
  });

  static const _expanded = 150.0;
  static const _collapsed = 74.0;

  @override
  double get maxExtent => top + _expanded;
  @override
  double get minExtent => top + _collapsed;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate old) =>
      old.hint != hint ||
      old.filtered != filtered ||
      old.dark != dark ||
      old.top != top;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final radius = BorderRadius.vertical(bottom: Radius.circular(30 - 8 * t));
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.homeHeader(dark),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: dark
                ? AppColors.homeDarkAccent.withValues(alpha: 0.22 + 0.08 * t)
                : AppColors.blue500.withValues(alpha: 0.2 + 0.1 * t),
            blurRadius: dark ? 28 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
        children: [
          // Huruf hijaiyyah melayang pelan di latar (sama dengan halaman masuk).
          Positioned.fill(
            child: Opacity(
              opacity: (1 - t * 1.4).clamp(0.0, 1.0),
              child: const FloatingLetters(count: 12),
            ),
          ),
          // Sapaan + avatar: naik dan memudar saat di-scroll.
          Positioned(
            left: 16,
            right: 16,
            top: top + 14 - 18 * t,
            child: Opacity(
              opacity: (1 - t * 1.8).clamp(0.0, 1.0),
              child: const _Greeting(),
            ),
          ),
          // Pencarian + filter: selalu menempel di bawah header.
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            height: 46,
            child: _SearchRow(
              controller: controller,
              hint: hint,
              filtered: filtered,
              onSubmit: onSubmit,
              onFilter: onFilter,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

/// Bagian hari berdasarkan jam di HP: (kata sapaan, emoji).
(String, String) _dayPart(int hour) {
  if (hour >= 4 && hour < 11) return ('pagi', '🌤️');
  if (hour >= 11 && hour < 15) return ('siang', '☀️');
  if (hour >= 15 && hour < 18) return ('sore', '🌇');
  return ('malam', '🌙');
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final guest = auth.status == AuthStatus.guest;
    final name = guest ? 'Tamu' : (auth.user?.shownName ?? '');
    final (part, emoji) = _dayPart(DateTime.now().hour);

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Assalamualaikum, selamat $part',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    // Nama panjang mengecil dulu (maks ~20%), baru dipotong "…".
                    child: LayoutBuilder(
                      builder: (context, c) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: c.maxWidth * 1.25),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(emoji, style: const TextStyle(fontSize: 19)),
                ],
              ),
            ],
          ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: guest ? null : () => openProfile(context),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: UserAvatar(user: guest ? null : auth.user, size: 40),
          ),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool filtered;
  final ValueChanged<String> onSubmit;
  final VoidCallback onFilter;
  const _SearchRow({
    required this.controller,
    required this.hint,
    required this.filtered,
    required this.onSubmit,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              // Terang: kolom putih. Gelap: kaca transparan, bukan blok gelap
              // di atas gradien.
              color: dark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: dark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.28))
                  : null,
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmit,
              cursorColor: dark ? Colors.white : null,
              style: TextStyle(
                fontSize: 14,
                color: dark ? Colors.white : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.lightMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                suffixIcon: IconButton(
                  onPressed: () => onSubmit(controller.text),
                  icon: Icon(
                    AppIcons.search,
                    size: 18,
                    color: dark ? Colors.white : AppColors.lightText,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onFilter,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(AppIcons.tune, size: 19, color: Colors.white),
                ),
              ),
            ),
            if (filtered)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ScopeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.tone(color);
    return Material(
      color: selected ? c.withValues(alpha: context.isDark ? 0.2 : 0.12) : context.surface2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: context.muted)),
                  ],
                ),
              ),
              Icon(
                selected ? AppIcons.success : AppIcons.chevronRight,
                size: selected ? 22 : 18,
                color: selected ? c : context.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Banner API key ─────────────────────────
