import 'package:flutter/material.dart';
import 'package:kanakkufi/core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class KanakkuFiApp extends StatelessWidget {
  const KanakkuFiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KanakkuFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
