import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_info.dart';
import 'core/theme.dart';
import 'features/settings/settings_provider.dart';
import 'features/shell/shell_page.dart';

class BayanAiApp extends StatelessWidget {
  const BayanAiApp ({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: kAppName,
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
                dark ? AppColors.darkSurface : AppColors.lightSurface,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
          child: child!,
        );
      },
      home: const ShellPage(),
    );
  }
}
