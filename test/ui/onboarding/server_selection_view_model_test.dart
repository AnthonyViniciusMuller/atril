/// The state behind the server selection screen.
library;

import 'package:atril/config/environment.dart';
import 'package:atril/data/repositories/server/server_repository.dart';
import 'package:atril/domain/models/server.dart';
import 'package:atril/ui/onboarding/view_model/server_selection_view_model.dart';
import 'package:atril/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server_repository.dart';

ServerSelectionViewModel modelOver(
  FakeServerRepository servers, {
  Environment? environment,
}) {
  final model = ServerSelectionViewModel(
    servers: servers,
    environment: environment ?? Environment.production(),
  );

  addTearDown(model.dispose);

  return model;
}

void main() {
  test('reads the node this device is pointed at, once', () async {
    final servers = FakeServerRepository()
      ..node = const ServerDescriptor(
        domain: 'quire-a.example',
        baseUrl: 'https://quire-a.example',
      );

    final model = modelOver(servers);
    await model.load.execute();

    expect(model.chosen?.domain, 'quire-a.example');
  });

  test('holds the node a choice settled on', () async {
    final model = modelOver(FakeServerRepository());

    await model.choose.execute(const ServerChoice('quire-b.example'));

    expect(model.choose.completed, isTrue);
    expect(model.chosen?.domain, 'quire-b.example');
  });

  test('remembers which domain a refusal was about', () async {
    // A reader who starts editing after a refusal should keep seeing what was
    // refused until they ask again, so the message cannot be built from the
    // text field.
    final servers = FakeServerRepository()
      ..refusal = const AppException(kind: ErrorKind.failedPrecondition);

    final model = modelOver(servers);

    await model.choose.execute(const ServerChoice('example.com'));

    expect(model.choose.error, isTrue);
    expect(model.attempted, 'example.com');
    expect(model.chosen, isNull);
  });

  test('offers the federation the build knows and nothing else', () {
    expect(modelOver(FakeServerRepository()).federation, isEmpty);
    expect(
      modelOver(
        FakeServerRepository(),
        environment: Environment.development(),
      ).federation,
      hasLength(2),
    );
  });
}
