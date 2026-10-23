import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../shell/nav_provider.dart';
import 'auth_provider.dart';
import 'user_avatar.dart';

/// Kartu akun di Setelan: info user, status sinkron Firestore, tombol keluar.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final nav = context.read<NavProvider>();
    final guest = auth.status == AuthStatus.guest;

    if (!guest) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.cs.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(fontSize: 17),
          ),
          content: const Text('Lu perlu masuk lagi untuk memakai app ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await auth.signOut();
    nav.go(NavProvider.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final guest = auth.status == AuthStatus.guest;
    final user = auth.user;

    final name = guest ? 'Mode tamu' : (user?.shownName ?? 'Pengguna');
    final sub = guest ? 'Firebase belum dikonfigurasi' : (user?.email ?? '');

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(user: guest ? null : user, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: context.muted),
                        ),
                      ],
                      if (!guest && auth.firestoreOk != null) ...[
                        const SizedBox(height: 8),
                        auth.firestoreOk == true
                            ? const Pill(
                                label: 'Tersinkron',
                                color: AppColors.success,
                                icon: AppIcons.cloud,
                              )
                            : const Pill(
                                label: 'Firestore gagal, cek Rules',
                                color: AppColors.danger,
                                icon: AppIcons.warning,
                              ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            onTap: () => _logout(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    guest ? AppIcons.logIn : AppIcons.logOut,
                    size: 18,
                    color: guest ? context.cs.primary : context.tone(AppColors.danger),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guest ? 'Masuk ke akun' : 'Keluar dari akun',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: guest ? context.cs.primary : context.tone(AppColors.danger),
                      ),
                    ),
                  ),
                  Icon(AppIcons.chevronRight, size: 17, color: context.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
