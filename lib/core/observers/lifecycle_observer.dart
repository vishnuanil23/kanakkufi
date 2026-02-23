import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanakkufi/core/providers/app_lifecycle_provider.dart';

class LifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  LifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }
}
