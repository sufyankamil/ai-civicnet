class SosPosition {
  const SosPosition(this.lat, this.lng);

  final double lat;
  final double lng;
}

class SosStatus {
  const SosStatus({
    required this.id,
    required this.alertCount,
    required this.expiresAt,
    required this.closed,
  });

  final int id;

  /// How many helpers were sent a push. Null until the server has sent them.
  final int? alertCount;
  final DateTime expiresAt;
  final bool closed;

  SosStatus copyWith({int? alertCount, DateTime? expiresAt, bool? closed}) =>
      SosStatus(
        id: id,
        alertCount: alertCount ?? this.alertCount,
        expiresAt: expiresAt ?? this.expiresAt,
        closed: closed ?? this.closed,
      );
}
