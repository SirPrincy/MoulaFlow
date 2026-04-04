import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';

/// A [ProviderObserver] that logs provider updates to the Dart DevTools Performance timeline.
/// This allows developers to see exactly when and why providers are updating in sync with frames.
base class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didAddProvider(
    ProviderObserverContext context,
    Object? value,
  ) {
    if (kDebugMode) {
      final provider = context.provider;
      Timeline.startSync('Provider Init: ${provider.name ?? provider.runtimeType}');
      Timeline.finishSync();
      log('Riverpod: Added ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (kDebugMode) {
      final provider = context.provider;
      final label = 'Provider Update: ${provider.name ?? provider.runtimeType}';
      Timeline.startSync(label, arguments: {
        'previous': previousValue.toString(),
        'new': newValue.toString(),
      });
      Timeline.finishSync();
      
      log('Riverpod: Updated ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void didDisposeProvider(
    ProviderObserverContext context,
  ) {
    if (kDebugMode) {
      final provider = context.provider;
      log('Riverpod: Disposed ${provider.name ?? provider.runtimeType}');
    }
  }
}
