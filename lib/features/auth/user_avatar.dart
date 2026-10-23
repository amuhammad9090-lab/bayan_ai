import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'auth_models.dart';

/// Foto profil (kalau ada) atau inisial di lingkaran gradien.
class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  const UserAvatar({super.key, required this.user, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final initial = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.buttonGradient,
      ),
      child: Text(
        u?.initial ?? '؟',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    final url = u?.photoUrl ?? '';
    if (url.isEmpty) return initial;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initial,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : initial,
      ),
    );
  }
}
