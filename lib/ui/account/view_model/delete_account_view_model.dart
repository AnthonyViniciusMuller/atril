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
import '../../../utils/result.dart';

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

  late final StreamSubscription<User?> _reader;

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

  void _onReader(User? reader) {
    _signedIn = reader;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_reader.cancel());
    delete.dispose();
    super.dispose();
  }
}
