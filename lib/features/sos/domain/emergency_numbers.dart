/// National emergency number by ISO region code. Shown first on the SOS sheet
/// because CivicNet is for neighbors helping neighbors, not a replacement for
/// the emergency services. Falls back to 112, which works on mobile networks in
/// many countries.
String emergencyNumberFor(String? countryCode) {
  const numbers = <String, String>{
    'IN': '112',
    'AE': '999',
    'SA': '911',
    'QA': '999',
    'KW': '112',
    'OM': '9999',
    'BH': '999',
    'GB': '999',
    'US': '911',
    'CA': '911',
    'AU': '000',
    'NZ': '111',
    'BD': '999',
  };
  if (countryCode == null || countryCode.isEmpty) return '112';
  return numbers[countryCode.toUpperCase()] ?? '112';
}
