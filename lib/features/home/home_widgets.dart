part of 'home_page.dart';

// Widget kecil Beranda: banner kunci, pill topik, kartu fitur & riwayat.

class _KeyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _KeyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.homeHeader(context.isDark),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atur API key Gemini terlebih dahulu untuk mulai menggunakan aplikasi.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Text(
                        'Atur Sekarang',
                        style: TextStyle(
                          color: Color(0xFF13203A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 4,
            child: ArtImage(
              asset: Art.homeBanner,
              fallbackIcon: AppIcons.key,
              fallbackSize: 56,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Pill kategori ─────────────────────────

class _TopicPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _TopicPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    // Gelap: pil diberi rona warnanya sendiri (bukan abu seragam) biar hidup.
    final surface = context.cs.surface;
    final bg = filled
        ? color
        : dark
            ? Color.alphaBlend(context.chipBg(color), surface)
            : surface;
    final fg = filled ? Colors.white : context.textColor;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(26),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: (!filled && dark)
                ? Border.all(color: context.chipBorder(color))
                : null,
            boxShadow: (!filled && !dark)
                ? [
                    BoxShadow(
                      color: AppColors.blue600.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? Colors.white.withValues(alpha: 0.28) : color,
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Kartu fitur (carousel) ─────────────────────────

class _FeatureCard extends StatelessWidget {
  final Gradient gradient;
  final Color shadow;
  final String asset;
  final IconData fallback;
  final String title;
  final String subtitle;
  final List<(IconData, String)> chips;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.gradient,
    required this.shadow,
    required this.asset,
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(26));
    return Container(
      width: 216,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: shadow.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient.forMode(context.isDark),
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        Positioned.fill(
                          child: ArtImage(asset: asset, fallbackIcon: fallback),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var k = 0; k < chips.length; k++) ...[
                        if (k > 0) const SizedBox(width: 12),
                        _MiniStat(icon: chips[k].$1, text: chips[k].$2),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Kartu riwayat berwarna ─────────────────────────

class _RecentCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  const _RecentCard({required this.item, required this.onTap});

  Gradient get _gradient {
    switch (item.type) {
      case HistoryType.ocr:
        return AppColors.gradOcr;
      case HistoryType.quran:
        return AppColors.gradQuran;
      case HistoryType.nahwu:
        return AppColors.gradNahwu;
    }
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(22));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: _gradient.forMode(context.isDark),
          borderRadius: radius,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  child: Icon(historyIcon(item.type), size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${historyLabel(item.type)} · ${timeAgo(item.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(AppIcons.chevronRight, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
