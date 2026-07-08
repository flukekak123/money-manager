import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../l10n/gen/app_localizations.dart';

/// Gates the app behind biometric/device auth when app lock is enabled.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  bool _unlocked = false;
  bool _authInProgress = false;

  Future<void> _authenticate() async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    final ok = await ref.read(appLockServiceProvider).authenticate();
    if (!mounted) return;
    setState(() {
      _unlocked = ok;
      _authInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Web has no biometric/device auth — app-lock is inactive (BR-W-WEB1).
    if (kIsWeb) return widget.child;

    final settings = ref.watch(settingsProvider);
    final lockEnabled = settings.asData?.value.appLockEnabled ?? false;

    if (!lockEnabled || _unlocked) {
      return widget.child;
    }

    // Kick off auth once the settings resolve.
    if (!_authInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 72),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).appLockedTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('app-lock-unlock-button'),
              onPressed: _authInProgress ? null : _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: Text(AppLocalizations.of(context).unlock),
            ),
          ],
        ),
      ),
    );
  }
}
