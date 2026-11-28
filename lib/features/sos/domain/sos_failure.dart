enum SosFailureType {
  /// One SOS in the last 10 minutes already.
  rateLimited,

  /// Three SOS in the last 24 hours already.
  dailyLimit,

  /// An SOS is still open.
  alreadyActive,
  notSignedIn,

  /// Location is off, denied or could not be read in time.
  locationUnavailable,
  network,
}

class SosFailure implements Exception {
  const SosFailure(this.type);

  final SosFailureType type;

  @override
  String toString() => 'SosFailure($type)';
}
