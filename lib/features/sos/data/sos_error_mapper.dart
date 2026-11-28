import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sos_failure.dart';

/// Turns whatever went wrong into one of the cases the screens know about.
SosFailure mapSosError(Object error) {
  if (error is SosFailure) return error;
  if (error is PostgrestException) {
    final message = error.message;
    if (message.contains('sos_rate_limited')) {
      return const SosFailure(SosFailureType.rateLimited);
    }
    if (message.contains('sos_daily_limit')) {
      return const SosFailure(SosFailureType.dailyLimit);
    }
    if (message.contains('sos_already_active')) {
      return const SosFailure(SosFailureType.alreadyActive);
    }
    if (error.code == '28000' || message.contains('not authenticated')) {
      return const SosFailure(SosFailureType.notSignedIn);
    }
  }
  return const SosFailure(SosFailureType.network);
}
