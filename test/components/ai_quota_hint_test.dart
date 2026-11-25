import 'package:civic_net/components/ai_quota_hint.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:civic_net/services/ai_quota_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, AiQuotaService quota) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AiQuotaHint(quota: quota)),
      ),
    );
    await tester.pump();
  }

  Map<String, dynamic> row({
    int used = 3,
    bool pro = false,
    bool enforced = true,
  }) => {
    'used': used,
    'quota_limit': 10,
    'resets_at': null,
    'is_pro': pro,
    'enforced': enforced,
  };

  testWidgets('shows remaining free AI actions', (tester) async {
    final quota = AiQuotaService.forTest(() async => row());
    await quota.refresh();
    await pump(tester, quota);

    expect(
      find.text('7 of 10 free AI actions left this month'),
      findsOneWidget,
    );
  });

  testWidgets('shows zero left when the quota is used up', (tester) async {
    final quota = AiQuotaService.forTest(() async => row(used: 10));
    await quota.refresh();
    await pump(tester, quota);

    expect(
      find.text('0 of 10 free AI actions left this month'),
      findsOneWidget,
    );
  });

  testWidgets('is hidden for Pro users', (tester) async {
    final quota = AiQuotaService.forTest(() async => row(pro: true));
    await quota.refresh();
    await pump(tester, quota);

    expect(find.textContaining('free AI actions'), findsNothing);
  });

  testWidgets('is hidden when enforcement is off', (tester) async {
    final quota = AiQuotaService.forTest(() async => row(enforced: false));
    await quota.refresh();
    await pump(tester, quota);

    expect(find.textContaining('free AI actions'), findsNothing);
  });

  testWidgets('is hidden before the status is known', (tester) async {
    final quota = AiQuotaService.forTest(() async => null);
    await pump(tester, quota);

    expect(find.textContaining('free AI actions'), findsNothing);
  });
}
