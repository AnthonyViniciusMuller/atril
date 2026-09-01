/// What this device owes, and what it is doing about it.
///
/// The screen answers one question and every line on it is part of the answer:
/// *are my notes only on this phone?* So the count comes first, the durable
/// timestamp under it, and the loop's own state under that — in the order a
/// reader would ask them, and not in the order the app happens to know them.
///
/// **Waiting is not failing, and the screen says which is which.** A change
/// that has not left yet is held here and goes as soon as the device reaches
/// its node; nothing is lost in the meantime, and a screen that showed a
/// warning triangle for the ordinary state of an offline-first application
/// would be teaching the reader to ignore it. The one failure that gets a
/// sentence of its own is the one no retry fixes.
///
/// **The last-reached line is a stored fact and not a session's memory.** It is
/// `node_cursors.pulled_at`, written whenever a channel opens as well as
/// whenever the cursor moves — a device that is up to date exchanges no
/// operations, and a timestamp that only moved on a pull would tell a reader
/// their last sync was whenever somebody last wrote something.
///
/// **The refused section is the only thing here that asks the reader for
/// anything**, and it appears only when there is something in it. A change the
/// node will not take is the state the local-first write path makes possible:
/// the reader watched it land, it is in the replica, and it will reach nobody.
/// The screen names the *kind* of record rather than the record — the record
/// may be exactly what the node does not know about — gives the node's reason,
/// and offers a discard whose confirmation says the one thing a reader could
/// otherwise get wrong: discarding undoes nothing they wrote.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/sync/sync_repository.dart';
import '../../../domain/models/operation.dart';
import '../../../domain/models/sync_state.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/sync_view_model.dart';

/// The synchronization screen.
class SyncScreen extends StatefulWidget {
  /// Creates the synchronization screen.
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  late final SyncViewModel _model = SyncViewModel(
    sync: context.read<SyncRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _model.now.addListener(_onSynchronized);
  }

  @override
  void dispose() {
    _model.now.removeListener(_onSynchronized);
    _model.dispose();
    super.dispose();
  }

  void _onSynchronized() {
    if (_model.now.running || !mounted) {
      return;
    }

    if (_model.now.result case Error<void>()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).syncFailedNow)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_model, _model.now]),
        builder: (BuildContext context, Widget? _) {
          final state = _model.state;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              _heading(theme, l10n.syncChangesSection),
              ListTile(
                leading: Icon(
                  state.isHandedOver
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                ),
                title: Text(l10n.syncPending(state.pending)),
                subtitle: Text(
                  state.isHandedOver
                      ? l10n.syncNothingPending
                      : l10n.syncPendingExplanation,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(_lastReached(context, l10n, state.lastSyncedAt)),
              ),
              _heading(theme, l10n.syncStateSection),
              ListTile(
                leading: Icon(_iconOf(state.activity)),
                title: Text(_activity(l10n, state.activity)),
                subtitle: _trouble(l10n, state.failure),
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(l10n.syncNow),
                enabled: !_model.now.running,
                onTap: _model.now.execute,
              ),
              if (state.refusals.isNotEmpty) ...<Widget>[
                _heading(theme, l10n.syncRefusedSection),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.syncRefusedExplanation,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                for (final refusal in state.refusals)
                  ListTile(
                    leading: const Icon(Icons.report_gmailerrorred_outlined),
                    title: Text(_recordOf(l10n, refusal.change.entity)),
                    subtitle: Text(
                      refusal.reason.isEmpty
                          ? l10n.syncRefusedNoReason
                          : refusal.reason,
                    ),
                    trailing: TextButton(
                      onPressed: () => _confirmDiscard(refusal.change.id),
                      child: Text(l10n.syncDiscard),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Asks before forgetting a refused change, and says what forgetting means.
  ///
  /// The confirmation exists for one sentence: discarding undoes nothing the
  /// reader wrote. Without it the action reads as *delete my change*, which is
  /// exactly what this app refuses to do about a refusal.
  Future<void> _confirmDiscard(String operationId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.syncDiscardTitle),
        content: Text(l10n.syncDiscardExplanation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.syncCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.syncDiscard),
          ),
        ],
      ),
    );

    if (discard != true) {
      return;
    }

    final outcome = await _model.discard(operationId);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome is Ok<void> ? l10n.syncDiscarded : l10n.syncDiscardFailed,
        ),
      ),
    );
  }

  /// What kind of record a refused change was about.
  ///
  /// It names the kind and not the record, because the record may be precisely
  /// what the node does not have: a refusal about a work whose creation never
  /// landed there has no title on that side to report.
  String _recordOf(AppLocalizations l10n, TargetEntity entity) =>
      switch (entity) {
        TargetEntity.ebook => l10n.syncRecordEbook,
        TargetEntity.collection => l10n.syncRecordCollection,
        TargetEntity.ebookCollection => l10n.syncRecordFiling,
        TargetEntity.readingProgress => l10n.syncRecordProgress,
        TargetEntity.annotation => l10n.syncRecordAnnotation,
      };

  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  String _lastReached(
    BuildContext context,
    AppLocalizations l10n,
    DateTime? at,
  ) {
    if (at == null) {
      return l10n.syncNever;
    }

    final dates = MaterialLocalizations.of(context);
    final local = at.toLocal();

    return l10n.syncLastReached(
      dates.formatMediumDate(local),
      dates.formatTimeOfDay(TimeOfDay.fromDateTime(local)),
    );
  }

  String _activity(AppLocalizations l10n, SyncActivity activity) =>
      switch (activity) {
        SyncActivity.idle => l10n.syncActivityIdle,
        SyncActivity.connecting => l10n.syncActivityConnecting,
        SyncActivity.live => l10n.syncActivityLive,
        SyncActivity.waiting => l10n.syncActivityWaiting,
      };

  IconData _iconOf(SyncActivity activity) => switch (activity) {
    SyncActivity.idle => Icons.pause_circle_outline,
    SyncActivity.connecting => Icons.sync,
    SyncActivity.live => Icons.wifi_tethering,
    SyncActivity.waiting => Icons.update,
  };

  /// What went wrong last, where it is worth saying.
  ///
  /// A node that did not answer is a wait and is said plainly; anything else
  /// carries the node's own reason, which is written for whoever gives support
  /// rather than for the reader — and showing it is still better than a screen
  /// that knows why and does not say.
  Widget? _trouble(AppLocalizations l10n, AppException? failure) {
    if (failure == null) {
      return null;
    }

    return Text(
      failure.kind.isRetryable
          ? l10n.syncWaitingOnNode
          : l10n.syncSomethingWrong(failure.message),
    );
  }
}
