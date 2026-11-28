import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Switches read from `.env`. They are not secrets (the file ships in the app).
class FeatureFlags {
  const FeatureFlags._();

  /// Emergency SOS ships switched off. Set `SOS_ENABLED=true` once
  /// `sql_scripts/sos_schema.sql` is applied and `notify-sos` is deployed,
  /// otherwise the button would send alerts that nobody receives.
  static bool get sosEnabled =>
      dotenv.isInitialized && dotenv.maybeGet('SOS_ENABLED') == 'true';
}
