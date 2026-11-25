import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';

/// Opens the paywall from code that has no BuildContext (view models).
void openPaywall() {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;
  GoRouter.of(context).push('/subscription');
}
