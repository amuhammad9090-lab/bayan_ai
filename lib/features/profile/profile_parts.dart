import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_provider.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// "12 Okt 2026"
String formatDate(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

// ───────────────────────── Statistik ─────────────────────────

/// Kartu angka (OCR / Qur'an / Nahwu). Angkanya naik pelan-pelan saat muncul.
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final int index;
  final VoidCallback onTap;
  const StatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.tone(color);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDark ? 0.22 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: c),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: Duration(milliseconds: 700 + index * 120),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              v.round().toString(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.muted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    )
        .animate(delay: (80 * index).ms)
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}

// ───────────────────────── Baris info ─────────────────────────

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData? trailing;
  final VoidCallback? onTap;
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: context.accentSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: context.cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11.5, color: context.muted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Icon(trailing, size: 17, color: context.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Baris aksi (ikon + judul + deskripsi + chevron).
class ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData trailing;
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing = AppIcons.chevronRight,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: context.accentSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: context.cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 11.5, height: 1.35, color: context.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailing, size: 17, color: context.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol keluar: merah lembut, selebar kartu.
class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.tone(AppColors.danger);
    return Material(
      color: AppColors.danger.withValues(alpha: context.isDark ? 0.16 : 0.09),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.logOut, size: 18, color: c),
              const SizedBox(width: 10),
              Text(
                'Keluar dari akun',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Ubah nama ─────────────────────────

Future<void> showEditNameSheet(BuildContext context, String current) {
  return showAppSheet<void>(
    context,
    title: 'Ubah nama',
    icon: AppIcons.user,
    builder: (ctx) => _EditNameForm(initial: current),
  );
}

class _EditNameForm extends StatefulWidget {
  final String initial;
  const _EditNameForm({required this.initial});

  @override
  State<_EditNameForm> createState() => _EditNameFormState();
}

class _EditNameFormState extends State<_EditNameForm> {
  late final _c = TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _c.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Nama minimal 2 huruf.');
      return;
    }
    if (name == widget.initial) {
      Navigator.of(context).pop();
      return;
    }
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await auth.updateName(name);
    if (!mounted) return;
    if (ok) {
      showSnack(context, 'Nama diperbarui');
      navigator.pop();
    } else {
      setState(() {
        _saving = false;
        _error = auth.error ?? 'Gagal menyimpan nama.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _c,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: const InputDecoration(
            hintText: 'Nama lengkap',
            prefixIcon: Icon(AppIcons.user, size: 19),
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          ErrorCard(message: _error!),
        ],
        const SizedBox(height: 14),
        GradientButton(
          label: _saving ? 'Menyimpan…' : 'Simpan',
          icon: AppIcons.check,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
