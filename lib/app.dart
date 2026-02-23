import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanakkufi/core/providers/app_lifecycle_provider.dart';
import 'package:kanakkufi/core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class KanakkuFiApp extends ConsumerStatefulWidget {
  const KanakkuFiApp({super.key});

  @override
  ConsumerState<KanakkuFiApp> createState() => _KanakkuFiAppState();
}

class _KanakkuFiAppState extends ConsumerState<KanakkuFiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }

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
