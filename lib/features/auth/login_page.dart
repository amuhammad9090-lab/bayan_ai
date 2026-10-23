import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/common.dart';
import 'auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _shake.dispose();
    super.dispose();
  }

  static bool _validEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  void _setMode(bool register) {
    if (_register == register) return;
    context.read<AuthProvider>().clearError();
    setState(() => _register = register);
  }

  void _shakeForm() {
    HapticFeedback.mediumImpact();
    _shake.forward(from: 0);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    if (!(_form.currentState?.validate() ?? false)) {
      _shakeForm();
      return;
    }
    final ok = _register
        ? await auth.register(_name.text, _email.text, _pass.text)
        : await auth.signIn(_email.text, _pass.text);
    if (!ok && mounted && auth.error != null) _shakeForm();
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!ok && mounted && auth.error != null) _shakeForm();
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      showSnack(
        context,
        'Isi email yang valid dulu, lalu ketuk "Lupa password?"',
        error: true,
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(email);
    if (!mounted) return;
    showSnack(
      context,
      ok
          ? 'Link reset dikirim ke $email'
          : (auth.error ?? 'Gagal mengirim link reset'),
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final configured = auth.status != AuthStatus.unconfigured;
    final busy = auth.busy;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          <Widget>[
                if (!configured) const _ConfigWarning(),
                if (!configured) const SizedBox(height: 14),
                _AuthTabs(register: _register, onChanged: _setMode),
                const SizedBox(height: 18),
                Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _register
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    // Autofill dimatikan di web: bikin field macet di Edge.
                                    autofillHints:
                                        kIsWeb ? null : const [AutofillHints.name],
                                    decoration: const InputDecoration(
                                      hintText: 'Nama lengkap',
                                      prefixIcon: Icon(AppIcons.user, size: 20),
                                    ),
                                    validator: (v) =>
                                        (_register &&
                                            (v ?? '').trim().length < 2)
                                        ? 'Nama minimal 2 huruf'
                                        : null,
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: kIsWeb ? null : const [AutofillHints.email],
                          autocorrect: false,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(AppIcons.mail, size: 20),
                          ),
                          validator: (v) =>
                              _validEmail(v ?? '') ? null : 'Email nggak valid',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: kIsWeb
                              ? null
                              : [
                                  _register
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                          onFieldSubmitted: (_) =>
                              configured && !busy ? _submit() : null,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(AppIcons.lock, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? AppIcons.eye : AppIcons.eyeOff,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (v) => (v ?? '').length < 6
                              ? 'Password minimal 6 karakter'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: auth.error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            key: ValueKey(auth.errorTick),
                            padding: const EdgeInsets.only(top: 12),
                            child: ErrorCard(message: auth.error!),
                          ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _register ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: _register || !configured,
                        child: TextButton(
                          onPressed: _forgot,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: busy
                      ? 'Memproses…'
                      : (_register ? 'Buat akun' : 'Masuk'),
                  icon: _register ? AppIcons.user : AppIcons.logIn,
                  loading: busy,
                  onPressed: configured ? _submit : null,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau',
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: (configured && !busy) ? _google : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        context.isDark ? AppColors.darkSurface2 : Colors.white,
                    disabledBackgroundColor:
                        context.isDark ? AppColors.darkSurface2 : Colors.white,
                    foregroundColor: context.textColor,
                    disabledForegroundColor: context.muted,
                    minimumSize: const Size(0, 54),
                    elevation: context.isDark ? 0 : 1.5,
                    shadowColor: Colors.black.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: context.isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFD5DCE8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GoogleG(),
                      SizedBox(width: 10),
                      Text('Lanjut dengan Google'),
                    ],
                  ),
                ),
                if (!configured) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: auth.continueAsGuest,
                    child: const Text('Lanjut tanpa akun (mode dev)'),
                  ),
                ],
              ]
              .animate(interval: 70.ms)
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              _Header(register: _register),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    child: AnimatedBuilder(
                      animation: _shake,
                      child: form,
                      builder: (context, child) {
                        final dx =
                            math.sin(_shake.value * math.pi * 6) *
                            10 *
                            (1 - _shake.value);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                    ),
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

// ───────────────────────── Bagian-bagian UI ─────────────────────────

class _Header extends StatelessWidget {
  final bool register;
  const _Header({required this.register});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24, top + 28, 24, 32),
        decoration: BoxDecoration(gradient: AppColors.cardBlue.forMode(context.isDark)),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const Positioned.fill(child: FloatingLetters()),
            Column(
              children: [
                LoopBuilder(
                      duration: const Duration(seconds: 3),
                      reverse: true,
                      builder: (context, t) => Transform.translate(
                        offset: Offset(0, -6 * Curves.easeInOut.transform(t)),
                        child: const SizedBox(
                          height: 118,
                          child: ArtImage(
                            asset: Art.homeBanner,
                            fallbackIcon: AppIcons.key,
                            fallbackSize: 64,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scaleXY(
                      begin: 0.5,
                      end: 1,
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 14),
                const Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'أَهْلًا وَسَهْلًا',
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: 30,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    register ? 'Buat akun Bayan AI' : 'Masuk ke Bayan AI',
                    key: ValueKey(register),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Simpan akun dan lanjutkan belajar di mana saja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle Masuk / Daftar dengan pil yang meluncur.
class _AuthTabs extends StatelessWidget {
  final bool register;
  final ValueChanged<bool> onChanged;
  const _AuthTabs({required this.register, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: register ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue600.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab(context, 'Masuk', !register, () => onChanged(false)),
              _tab(context, 'Daftar', register, () => onChanged(true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.muted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: context.isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: amber.withValues(alpha: 0.45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.warning, size: 18, color: amber),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Firebase belum dikonfigurasi, jadi login dimatikan dulu. '
              'Jalankan "flutterfire configure" lalu jalankan ulang app. '
              'Sementara itu lu bisa lanjut tanpa akun.',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: context.border),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
