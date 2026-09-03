/// What the account deletion screen knows.
///
/// It reads one thing besides the reader, and it reads it for the sentence
/// rather than for the act: the replica permissions, so that *the servers that
/// already hold a copy* can be named instead of alluded to. A node that does
/// not answer costs the names and nothing else — the deletion neither needs
/// them nor reaches them.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/federation/federation_repository.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../../utils/logging.dart';
import '../../../utils/result.dart';

final _log = loggerFor('ui/account');

/// The state of the account deletion screen.
final class DeleteAccountViewModel extends ChangeNotifier {
  /// The view model over [account], naming the reader out of [auth] and the
  /// replicas out of [federation].
  DeleteAccountViewModel({
    required this.account,
    required this.auth,
    required this.federation,
  }) {
    delete = Command1<void, String>(account.deleteAccount);
    _reader = auth.reader().listen(_onReader);
    unawaited(_readReplicas());
  }

  /// Where the account is deleted.
  final AccountRepository account;

  /// Who is signed in here, which is whose account this is.
  final AuthRepository auth;

  /// Where the replica permissions come from.
  final FederationRepository federation;

  /// Removes the reader from this node, proved with their password.
  late final Command1<void, String> delete;

  late final StreamSubscription<Result<User?>> _reader;

  User? _signedIn;

  /// The reader, as this device holds them.
  User? get signedIn => _signedIn;

  List<String> _replicas = const <String>[];

  /// The nodes that hold a copy, by domain, or empty where the node did not
  /// say.
  ///
  /// Empty means *not known* and not *none*. The screen therefore keeps the
  /// sentence about replicas either way and only adds the names when it has
  /// them: a list that disappeared would read as a promise nothing made.
  List<String> get replicas => _replicas;

  Future<void> _readReplicas() async {
    final grants = await federation.replicas();

    if (grants case Ok<List<ReplicaAuthorization>>(:final value)) {
      _replicas = <String>[
        for (final grant in value)
          if (grant.active) grant.serverDomain,
      ];
      notifyListeners();
    }
  }

  void _onReader(Result<User?> reader) {
    // A failure here leaves the reader as they were rather than blanking the
    // surface that names them: the row is still in the replica and the next
    // answer will carry it, and a screen that forgot who was signed in
    // because one query failed would be the worse of the two wrong answers.
    switch (reader) {
      case Ok<User?>(:final User? value):
        _signedIn = value;
        notifyListeners();
      case Error<User?>(:final Exception error):
        _log.warning('the signed-in reader could not be read', error);
    }
  }

  @override
  void dispose() {
    unawaited(_reader.cancel());
    delete.dispose();
    super.dispose();
  }
}
