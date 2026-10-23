import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/common.dart';
import '../auth/account_card.dart' show confirmLogout;
import '../auth/auth_provider.dart';
import '../history/history_provider.dart';
import '../history/history_sheet.dart';
import 'profile_header.dart';
import 'profile_parts.dart';

/// Buka halaman Profil dengan transisi fade + naik tipis.
Future<void> openProfile(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const ProfilePage(),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _refresh(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final history = context.read<HistoryProvider>();
    history.reload();
    await auth.refreshProfile();
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(email);
    if (!context.mounted) return;
    showSnack(
      context,
      ok ? 'Tautan ubah kata sandi dikirim ke $email' : (auth.error ?? 'Gagal mengirim tautan.'),
      error: !ok,
    );
  }

  Future<void> _openGoogle(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse('https://myaccount.google.com'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) showSnack(context, 'Tidak bisa membuka browser.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final history = context.watch<HistoryProvider>();
    final user = auth.user;
    final guest = auth.status == AuthStatus.guest;
    final dark = context.isDark;
    final top = MediaQuery.of(context).padding.top;

    // Sesi berakhir saat halaman ini terbuka -> tutup halaman.
    if (user == null && !guest && auth.status != AuthStatus.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    final name = guest ? 'Mode tamu' : (user?.shownName ?? 'Pengguna');
    final email = guest ? 'Firebase belum dikonfigurasi' : (user?.email ?? '');
    final badge = guest ? 'Belum masuk' : (user?.providerLabel ?? '');

    final recent = history.items.take(3).toList();
    final total = history.items.length;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F1FD), AppColors.lightBg],
                ),
          color: dark ? AppColors.darkBg : null,
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            AppRefreshControl(onRefresh: () => _refresh(context)),
            SliverPersistentHeader(
              pinned: true,
              delegate: ProfileHeaderDelegate(
                user: guest ? null : user,
                name: name,
                subtitle: email,
                badge: badge,
                dark: dark,
                top: top,
                onBack: () => Navigator.of(context).maybePop(),
                onEdit: guest ? null : () => showEditNameSheet(context, user?.shownName ?? ''),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 28 + MediaQuery.of(context).padding.bottom),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  // ── Statistik ──
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          index: 0,
                          icon: AppIcons.ocr,
                          color: AppColors.ocr,
                          value: history.count(HistoryType.ocr),
                          label: 'Pindai OCR',
                          onTap: () => showHistorySheet(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          index: 1,
                          icon: AppIcons.quran,
                          color: AppColors.quran,
                          value: history.count(HistoryType.quran),
                          label: "Cari Qur'an",
                          onTap: () => showHistorySheet(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          index: 2,
                          icon: AppIcons.nahwu,
                          color: AppColors.purple,
                          value: history.count(HistoryType.nahwu),
                          label: 'Analisis',
                          onTap: () => showHistorySheet(context),
                        ),
                      ),
                    ],
                  ),
                  PageGap.section,

                  // ── Aktivitas terakhir ──
                  SectionLabel(
                    'Aktivitas terakhir',
                    hint: total == 0 ? null : '$total tersimpan',
                    trailing: total > 3
                        ? TextButton(
                            onPressed: () => showHistorySheet(context),
                            child: const Text('Lihat semua'),
                          )
                        : null,
                  ),
                  if (recent.isEmpty)
                    const AppCard(
                      shadow: false,
                      child: EmptyState(
                        icon: AppIcons.sparkles,
                        title: 'Belum ada aktivitas',
                        subtitle: 'Hasil pindai, pencarian ayat, dan analisis nahwu akan muncul di sini.',
                      ),
                    )
                  else
                    for (final h in recent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HistoryTile(
                          item: h,
                          onTap: () {
                            reuseHistory(context, h);
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                  PageGap.section,

                  // ── Info akun ──
                  if (!guest && user != null) ...[
                    const SectionLabel('Informasi akun'),
                    GroupCard(
                      children: [
                        InfoRow(
                          icon: AppIcons.user,
                          label: 'Nama',
                          value: user.shownName,
                          trailing: AppIcons.pencil,
                          onTap: () => showEditNameSheet(context, user.shownName),
                        ),
                        InfoRow(
                          icon: AppIcons.mail,
                          label: 'Email',
                          value: user.email.isEmpty ? '-' : user.email,
                          trailing: AppIcons.copy,
                          onTap: user.email.isEmpty
                              ? null
                              : () => copyText(context, user.email, label: 'Email'),
                        ),
                        InfoRow(
                          icon: AppIcons.logIn,
                          label: 'Masuk dengan',
                          value: user.providerLabel,
                        ),
                        if (user.createdAt != null)
                          InfoRow(
                            icon: AppIcons.calendar,
                            label: 'Bergabung sejak',
                            value: formatDate(user.createdAt!),
                          ),
                        if (user.lastSignInAt != null)
                          InfoRow(
                            icon: AppIcons.clock,
                            label: 'Terakhir masuk',
                            value: timeAgo(user.lastSignInAt!),
                          ),
                        InfoRow(
                          icon: AppIcons.hash,
                          label: 'ID akun',
                          value: user.uid.length > 14 ? '${user.uid.substring(0, 14)}…' : user.uid,
                          trailing: AppIcons.copy,
                          onTap: () => copyText(context, user.uid, label: 'ID akun'),
                        ),
                      ],
                    ),
                    PageGap.section,

                    // ── Keamanan ──
                    const SectionLabel('Keamanan'),
                    GroupCard(
                      children: [
                        if (user.hasPassword && user.email.isNotEmpty)
                          ActionRow(
                            icon: AppIcons.lock,
                            title: 'Ubah kata sandi',
                            subtitle: 'Kirim tautan penggantian ke email lu',
                            onTap: auth.busy ? null : () => _resetPassword(context, user.email),
                          ),
                        if (user.isGoogle)
                          ActionRow(
                            icon: AppIcons.shield,
                            title: 'Kelola akun Google',
                            subtitle: 'Kata sandi & keamanan diatur di Google',
                            trailing: AppIcons.external,
                            onTap: () => _openGoogle(context),
                          ),
                        ActionRow(
                          icon: AppIcons.cloud,
                          title: 'Sinkron akun',
                          subtitle: auth.firestoreOk == false
                              ? 'Gagal menyimpan ke Firestore, cek Rules'
                              : 'Profil tersimpan di akun lu',
                          trailing: auth.firestoreOk == false ? AppIcons.warning : AppIcons.success,
                        ),
                      ],
                    ),
                    PageGap.section,
                  ],

                  // ── Keluar ──
                  if (guest)
                    const Footnote('Lu lagi di mode tamu. Hubungkan Firebase untuk punya akun dan profil.')
                  else
                    LogoutButton(onTap: () => confirmLogout(context)),
                ]
                    .animate(interval: 40.ms)
                    .fadeIn(duration: 300.ms)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
