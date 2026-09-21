import 'package:riverpod/riverpod.dart';

import 'activity.dart';
import 'provider.dart';

/// Reads [activityProvider], which is declared in `provider.dart` and generated
/// by `riverpod_generator`.
///
/// Two reads, in the order that makes the point:
///
///  1. **Overridden.** The provider is replaced with a fixed value, so the read
///     is deterministic and makes no network call. Being able to swap a
///     provider out without touching the code that depends on it is the reason
///     to use Riverpod at all.
///  2. **Real.** The same provider, unmodified, calling the Bored API. Wrapped
///     in a try/catch so this example still runs without a network.
Future<void> main() async {
  final fixed = Activity(
    activity: 'Learn how Riverpod overrides work',
    type: 'education',
    participants: 1,
    price: 0,
  );

  final overridden = ProviderContainer(
    overrides: [activityProvider.overrideWith((ref) async => fixed)],
  );
  print('overridden: ${(await overridden.read(activityProvider.future)).activity}');
  overridden.dispose();

  final live = ProviderContainer();
  try {
    final activity = await live.read(activityProvider.future);
    print('live:       ${activity.activity} (${activity.type})');
  } catch (e) {
    print('live:       unavailable ($e)');
  }
  live.dispose();
}
