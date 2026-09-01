/// The one question the surface answers, and the two ways it is asked.
///
/// A reader who cannot tell whether their notes are only on this phone has not
/// been given the guarantee this app makes, so what is pinned here is that the
/// number is in front of them without their asking — on the navigation surface
/// — and that the screen behind it distinguishes *waiting* from *wrong*. An
/// offline-first application whose ordinary state looks like a failure has
/// taught its reader to ignore the one time it is not.
library;

import 'package:atril/domain/crdt/vector_clock.dart';
import 'package:atril/domain/models/operation.dart';
import 'package:atril/domain/models/sync_state.dart';
import 'package:atril/routing/routes.dart';
import 'package:atril/ui/core/localization/localization.dart';
import 'package:atril/ui/sync/widgets/sync_screen.dart';
import 'package:atril/utils/errors.dart';
import 'package:atril/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../repository_fakes.dart';

/// A change this device authored and the node would not take.
final Operation _change = Operation(
  id: '00000001-1111-4111-8111-111111111111',
  deviceId: '11111111-1111-4111-8111-111111111111',
  entity: TargetEntity.ebook,
  targetId: 'aaaaaaaa-1111-4111-8111-111111111111',
  kind: OperationKind.insert,
  delta: const <String, Object?>{'title': 'Sagarana'},
  vectorClock: VectorClock.of(const <String, int>{
    '11111111-1111-4111-8111-111111111111': 1,
  }),
  createdAt: DateTime.utc(2026, 3, 14),
);

final List<RefusedChange> _refusals = <RefusedChange>[
  RefusedChange(
    change: _change,
    reason: 'o formato desta obra não é aceito por este nó',
    refusedAt: DateTime.utc(2026, 3, 14),
  ),
];

/// The screen over [sync], in Brazilian Portuguese as the app's default is.
Future<void> _pump(WidgetTester tester, FakeSyncRepository sync) async {
  addTearDown(sync.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: repositoryProviders(sync: sync),
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SyncScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('counts what has not left this device', (
    WidgetTester tester,
  ) async {
    final sync = FakeSyncRepository()
      ..emit(const SyncState(activity: SyncActivity.live, pending: 3));

    await _pump(tester, sync);

    expect(find.text('3 alterações esperando'), findsOneWidget);
    expect(
      find.text(
        'Elas estão guardadas aqui e vão embora assim que este aparelho '
        'alcançar o nó. Nada se perde enquanto isso.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('says so plainly when there is nothing waiting', (
    WidgetTester tester,
  ) async {
    final sync = FakeSyncRepository()
      ..emit(const SyncState(activity: SyncActivity.live));

    await _pump(tester, sync);

    expect(find.text('Nada esperando'), findsOneWidget);
    expect(find.text('Tudo o que você fez já saiu daqui.'), findsOneWidget);
  });

  testWidgets('shows when this device last reached its node', (
    WidgetTester tester,
  ) async {
    final sync = FakeSyncRepository()
      ..emit(
        SyncState(
          activity: SyncActivity.live,
          lastSyncedAt: DateTime(2026, 3, 14, 15, 9),
        ),
      );

    await _pump(tester, sync);

    expect(find.textContaining('Falou com o nó em'), findsOneWidget);
  });

  testWidgets('says a device that never reached one has not', (
    WidgetTester tester,
  ) async {
    // It is a different sentence and not an empty date. A device that has been
    // signed in for a week and never connected is the case the reader most
    // needs told, and a blank would read as *recently*.
    await _pump(tester, FakeSyncRepository());

    expect(
      find.text('Este aparelho ainda não alcançou o nó.'),
      findsOneWidget,
    );
  });

  testWidgets('calls an unanswering node a wait and not a fault', (
    WidgetTester tester,
  ) async {
    final sync = FakeSyncRepository()
      ..emit(
        const SyncState(
          activity: SyncActivity.waiting,
          pending: 1,
          failure: AppException(
            kind: ErrorKind.unavailable,
            message: 'the node is not answering',
          ),
        ),
      );

    await _pump(tester, sync);

    expect(
      find.text('O nó não respondeu. Este aparelho tenta de novo sozinho.'),
      findsOneWidget,
    );
  });

  testWidgets('says what went wrong where no retry fixes it', (
    WidgetTester tester,
  ) async {
    // The reason is written for whoever gives support rather than for the
    // reader, and showing it is still better than a screen that knows why and
    // does not say.
    final sync = FakeSyncRepository()
      ..emit(
        const SyncState(
          activity: SyncActivity.waiting,
          failure: AppException(
            kind: ErrorKind.permissionDenied,
            message: 'this device is not bound to that reader',
          ),
        ),
      );

    await _pump(tester, sync);

    expect(
      find.textContaining('this device is not bound to that reader'),
      findsOneWidget,
    );
  });

  testWidgets('synchronizes at the reader\'s asking', (
    WidgetTester tester,
  ) async {
    final sync = FakeSyncRepository();

    await _pump(tester, sync);
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(sync.asked, 1);
  });

  testWidgets('says so when the asking could not be made', (
    WidgetTester tester,
  ) async {
    final sync = FakeSyncRepository()
      ..answers = Result<void>.error(
        const AppException(kind: ErrorKind.internal, message: 'no'),
      );

    await _pump(tester, sync);
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível sincronizar agora.'), findsOneWidget);
  });

  testWidgets('follows the state as it changes', (WidgetTester tester) async {
    final sync = FakeSyncRepository();

    await _pump(tester, sync);

    expect(find.text('Conectado ao nó'), findsNothing);

    sync.emit(const SyncState(activity: SyncActivity.live));
    await tester.pumpAndSettle();

    expect(find.text('Conectado ao nó'), findsOneWidget);
  });

  group('a change the node refused', () {
    testWidgets('is listed with the node\'s own reason', (
      WidgetTester tester,
    ) async {
      final sync = FakeSyncRepository()..emit(SyncState(refusals: _refusals));

      await _pump(tester, sync);

      expect(find.text('Recusadas pelo nó'), findsOneWidget);
      expect(find.text('Um livro'), findsOneWidget);
      expect(
        find.text('o formato desta obra não é aceito por este nó'),
        findsOneWidget,
      );
    });

    testWidgets('is absent while there is nothing refused', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeSyncRepository());

      expect(find.text('Recusadas pelo nó'), findsNothing);
    });

    testWidgets('says the node gave no reason where it gave none', (
      WidgetTester tester,
    ) async {
      // The contract lets a node refuse without explaining, and a blank line
      // would read as a fault in this screen rather than a silence on the
      // other side.
      final sync = FakeSyncRepository()
        ..emit(
          SyncState(
            refusals: <RefusedChange>[
              RefusedChange(
                change: _change,
                reason: '',
                refusedAt: DateTime.utc(2026, 3, 14),
              ),
            ],
          ),
        );

      await _pump(tester, sync);

      expect(find.text('O nó não disse por quê.'), findsOneWidget);
    });

    testWidgets('is discarded only after the reader is told what that is', (
      WidgetTester tester,
    ) async {
      // Without the sentence the action reads as *delete my change*, which is
      // exactly what this app refuses to do about a refusal.
      final sync = FakeSyncRepository()..emit(SyncState(refusals: _refusals));

      await _pump(tester, sync);
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Descartar não desfaz o que você fez. Só faz este aparelho parar '
          'de guardar uma entrega que não vai acontecer.',
        ),
        findsOneWidget,
      );
      expect(sync.discarded, isEmpty);

      await tester.tap(find.text('Descartar').last);
      await tester.pumpAndSettle();

      expect(sync.discarded, <String>[_change.id]);
      expect(find.text('Alteração descartada.'), findsOneWidget);
    });

    testWidgets('is kept when the reader changes their mind', (
      WidgetTester tester,
    ) async {
      final sync = FakeSyncRepository()..emit(SyncState(refusals: _refusals));

      await _pump(tester, sync);
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(sync.discarded, isEmpty);
    });

    testWidgets('says so when the discard could not be made', (
      WidgetTester tester,
    ) async {
      final sync = FakeSyncRepository()
        ..emit(SyncState(refusals: _refusals))
        ..discards = Result<void>.error(
          const AppException(kind: ErrorKind.internal, message: 'no'),
        );

      await _pump(tester, sync);
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar').last);
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível descartar.'), findsOneWidget);
    });
  });

  test('the sync screen is a location below the settings', () {
    // Below, and not a fourth destination: synchronization is a property of
    // the app rather than a place to visit, and what belongs in front of the
    // reader at all times is the one number the badge carries.
    expect(Routes.sync, '${Routes.settings}/${Routes.syncSegment}');
    expect(Routes.shell, isNot(contains(Routes.sync)));
  });
}
