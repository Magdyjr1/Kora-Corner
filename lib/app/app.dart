import 'package:flutter/material.dart';
import 'package:kora_corner/app/router.dart';


import '../core/theme/app_theme.dart';

class KoraCornerApp extends StatelessWidget {
  const KoraCornerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kora Corner',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
