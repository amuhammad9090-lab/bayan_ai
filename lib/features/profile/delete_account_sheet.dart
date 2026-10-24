import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_provider.dart';
import '../shell/nav_provider.dart';

/// Hapus akun permanen (wajib ada di dalam aplikasi menurut kebijakan Google Play).
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'Hapus akun',
    icon: AppIcons.userX,
    builder: (_) => const _DeleteAccountForm(),
  );
}

class _DeleteAccountForm extends StatefulWidget {
  const _DeleteAccountForm();

  @override
  State<_DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  final _password = TextEditingController();
  bool _agree = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete(bool needsPassword) async {
    if (needsPassword && _password.text.isEmpty) {
      setState(() => _error = 'Masukkan kata sandi untuk konfirmasi.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final nav = context.read<NavProvider>();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await auth.deleteAccount(password: needsPassword ? _password.text : null);
    if (ok) {
      // Akun terhapus: sesi berakhir dan aplikasi kembali ke halaman masuk.
      nav.go(NavProvider.home);
      if (navigator.mounted) navigator.popUntil((r) => r.isFirst);
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = auth.error ?? 'Gagal menghapus akun. Silakan coba lagi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AppUser?>((a) => a.user);
    final needsPassword = user?.hasPassword ?? false;
    final danger = context.chipFg(AppColors.danger);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.chipBg(AppColors.danger),
              borderRadius: BorderRadius.circular(16),
              border: context.isDark
                  ? Border.all(color: context.chipBorder(AppColors.danger))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.warning, size: 18, color: danger),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tindakan ini permanen dan tidak bisa dibatalkan. Yang akan dihapus:\n'
                    '• Akun masuk kamu\n'
                    '• Data profil yang tersimpan di server\n'
                    '• Riwayat dan cache AI akun ini di perangkat ini',
                    style: TextStyle(fontSize: 12.5, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (needsPassword)
            TextField(
              controller: _password,
              obscureText: _obscure,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Kata sandi',
                prefixIcon: const Icon(AppIcons.lock, size: 19),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 18),
                ),
              ),
            )
          else
            Text(
              'Untuk konfirmasi, kamu akan diminta memilih akun Google sekali lagi.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: context.muted),
            ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: _agree,
            onChanged: _busy ? null : (v) => setState(() => _agree = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.danger,
            title: const Text(
              'Saya mengerti akun dan datanya akan dihapus permanen.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            ErrorCard(message: _error!),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: (!_agree || _busy) ? null : () => _delete(needsPassword),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(AppIcons.trash, size: 18),
              label: Text(_busy ? 'Menghapus…' : 'Hapus akun permanen'),
            ),
          ),
        ],
    );
  }
}
