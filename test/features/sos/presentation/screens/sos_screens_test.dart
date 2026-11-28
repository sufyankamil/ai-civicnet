import 'dart:async';

import 'package:civic_net/features/sos/data/sos_remote_data_source.dart';
import 'package:civic_net/features/sos/domain/sos_failure.dart';
import 'package:civic_net/features/sos/domain/sos_models.dart';
import 'package:civic_net/features/sos/presentation/screens/sos_screen.dart';
import 'package:civic_net/features/sos/presentation/screens/sos_sheet.dart';
import 'package:civic_net/features/sos/presentation/screens/sos_waiting_screen.dart';
import 'package:civic_net/features/sos/presentation/viewmodels/sos_viewmodel.dart';
import 'package:civic_net/features/sos/presentation/widgets/hold_to_confirm_button.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeData implements SosRemoteDataSource {
  final created = <String?>[];
  final ended = <int>[];
  Object? createError;
  SosStatus status = SosStatus(
    id: 7,
    alertCount: 4,
    expiresAt: DateTime.now().add(const Duration(minutes: 45)),
    closed: false,
  );

  @override
  Future<int> createSos({
    required double lat,
    required double lng,
    String? note,
  }) async {
    if (createError != null) throw createError!;
    created.add(note);
    return status.id;
  }

  @override
  Future<void> endSos(int id) async => ended.add(id);

  @override
  Future<SosStatus> getStatus(int id) async => status;
}

void main() {
  late FakeData data;
  late SosViewModel vm;

  setUp(() {
    Get.reset();
    data = FakeData();
    vm = SosViewModel(
      dataSource: data,
      position: () async => const SosPosition(19.07, 72.87),
    );
    Get.put(vm);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pump();
  }

  group('emergency number from location', () {
    testWidgets('the sheet shows the number of the location country', (
      tester,
    ) async {
      Get.reset();
      final answer = Completer<String?>();
      Get.put(
        SosViewModel(
          dataSource: data,
          position: () async => const SosPosition(25.2, 55.3),
          deviceRegion: () => 'IN',
          countryLookup: () => answer.future,
        ),
      );
      await pump(tester, const SosSheet());
      expect(find.text('Call 112'), findsOneWidget);

      answer.complete('AE');
      await tester.pump();
      await tester.pump();

      expect(find.text('Call 999'), findsOneWidget);
      expect(find.text('Call 112'), findsNothing);
    });

    testWidgets('the running SOS page also uses the location country', (
      tester,
    ) async {
      Get.reset();
      final model = SosViewModel(
        dataSource: data,
        position: () async => const SosPosition(25.2, 55.3),
        deviceRegion: () => 'IN',
        countryLookup: () async => 'AE',
      );
      Get.put(model);
      await model.start();
      await pump(
        tester,
        const SizedBox(height: 900, child: SosWaitingScreenBody()),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Call 999'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('opening the sheet looks the country up', (tester) async {
      Get.reset();
      var looked = 0;
      Get.put(
        SosViewModel(
          dataSource: data,
          position: () async => null,
          deviceRegion: () => 'IN',
          countryLookup: () async {
            looked++;
            return 'GB';
          },
        ),
      );
      await pump(tester, const SosSheet());
      await tester.pump();
      await tester.pump();

      expect(looked, 1);
      expect(find.text('Call 999'), findsOneWidget);
    });
  });

  group('SosSheet', () {
    testWidgets('puts the national emergency number first', (tester) async {
      await pump(tester, const SosSheet(countryCode: 'AE'));

      expect(find.text('Call 999'), findsOneWidget);
      expect(find.textContaining('not an emergency service'), findsOneWidget);
      expect(find.byType(HoldToConfirmButton), findsOneWidget);
    });

    testWidgets('sending needs a hold, then reports success', (tester) async {
      var started = 0;
      await pump(
        tester,
        SosSheet(countryCode: 'IN', onStarted: () => started++),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirmButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(data.created, hasLength(1));
      expect(started, 1);
    });

    testWidgets('a quick tap sends nothing', (tester) async {
      await pump(tester, const SosSheet(countryCode: 'IN'));
      await tester.tap(find.byType(HoldToConfirmButton));
      await tester.pump(const Duration(milliseconds: 300));

      expect(data.created, isEmpty);
    });

    testWidgets('shows the reason when the server refuses', (tester) async {
      data.createError = const SosFailure(SosFailureType.rateLimited);
      await pump(tester, SosSheet(countryCode: 'IN', onStarted: () {}));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirmButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('wait a few minutes'), findsOneWidget);
    });

    testWidgets('tells the user when location is unavailable', (tester) async {
      vm.error.value = SosFailureType.locationUnavailable;
      await pump(tester, const SosSheet(countryCode: 'IN'));

      expect(find.textContaining("couldn't get your location"), findsOneWidget);
    });
  });

  group('SosWaitingScreenBody', () {
    testWidgets('shows how many helpers were alerted and the time left', (
      tester,
    ) async {
      await vm.start();
      await pump(
        tester,
        const SizedBox(
          height: 900,
          child: SosWaitingScreenBody(countryCode: 'IN'),
        ),
      );

      expect(find.text('Your SOS is active'), findsOneWidget);
      expect(find.text('4 helpers nearby were alerted'), findsOneWidget);
      expect(find.textContaining('min left'), findsOneWidget);
      expect(find.text("I'm safe"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('says so while the alert is still going out', (tester) async {
      data.status = SosStatus(
        id: 7,
        alertCount: null,
        expiresAt: DateTime.now().add(const Duration(minutes: 60)),
        closed: false,
      );
      await vm.start();
      await pump(
        tester,
        const SizedBox(
          height: 900,
          child: SosWaitingScreenBody(countryCode: 'IN'),
        ),
      );

      expect(find.text('Alerting helpers near you…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no one alerted points to the emergency number', (
      tester,
    ) async {
      data.status = SosStatus(
        id: 7,
        alertCount: 0,
        expiresAt: DateTime.now().add(const Duration(minutes: 60)),
        closed: false,
      );
      await vm.start();
      await pump(
        tester,
        const SizedBox(
          height: 900,
          child: SosWaitingScreenBody(countryCode: 'IN'),
        ),
      );

      expect(
        find.text('No helpers nearby have been alerted yet'),
        findsOneWidget,
      );
      expect(find.textContaining('Call 112'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("I'm safe ends the alert", (tester) async {
      await vm.start();
      await pump(
        tester,
        const SizedBox(
          height: 900,
          child: SosWaitingScreenBody(countryCode: 'IN'),
        ),
      );

      await tester.tap(find.text("I'm safe"));
      await tester.pump();
      await tester.pump();

      expect(data.ended, [7]);
      expect(find.text('Your SOS has ended'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('SosScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SosScreen(countryCode: 'IN'),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the alert form when no SOS is running', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Do you need help right now?'), findsOneWidget);
      expect(find.text('Your SOS is active'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows the running SOS when one is active', (tester) async {
      await vm.start();
      await pumpScreen(tester);

      expect(find.text('Your SOS is active'), findsOneWidget);
      expect(find.text('Do you need help right now?'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('switches to the running SOS once one starts', (tester) async {
      await pumpScreen(tester);
      await vm.start();
      await tester.pump();

      expect(find.text('Your SOS is active'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('after ending it shows the ended page, not the form', (
      tester,
    ) async {
      await vm.start();
      await pumpScreen(tester);
      await tester.tap(find.text("I'm safe"));
      await tester.pump();
      await tester.pump();

      expect(find.text('Your SOS has ended'), findsOneWidget);
      expect(find.text('Do you need help right now?'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
