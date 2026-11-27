import 'package:civic_net/core/utils/legal_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacy and terms point at civicnet.app over https', () {
    expect(LegalLinks.privacy.toString(), 'https://civicnet.app/privacy');
    expect(LegalLinks.terms.toString(), 'https://civicnet.app/terms');
  });

  test('no legal link uses the old Vercel host', () {
    for (final link in [LegalLinks.privacy, LegalLinks.terms]) {
      expect(link.host, isNot(contains('vercel.app')));
      expect(link.scheme, 'https');
    }
  });
}
