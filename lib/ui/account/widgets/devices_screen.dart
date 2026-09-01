/// The reader's devices, and what can be done to one (RF11).
///
/// **A revoked device says *unbound* and not *deleted*, and the word is the
/// design.** The row survives revocation and so does its entry in every vector
/// clock that names it: an operation whose author nobody can resolve cannot be
/// explained to a reader or checked against RN10, so this list is the only
/// place an identifier the history carries gets a name. A screen that removed
/// the row would make its own history unreadable, and one that said *deleted*
/// would be describing something that did not happen.
///
/// **The device holding the screen cannot unbind itself.** The node cannot tell
/// that request apart from any other and would carry it out, ending this
/// session and every future one with nothing left on screen to undo the act. So
/// it is refused here, and the row says which device it is rather than offering
/// a control that is going to be refused.
///
/// **Only the name is editable.** The platform is what it is, and the
/// identifier is referenced by every clock the device appears in — the contract
/// admits exactly one field for the same reason.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/account/account_repository_impl.dart';
import '../../../domain/models/device.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/devices_view_model.dart';

/// The devices screen.
class DevicesScreen extends StatefulWidget {
  /// Creates the devices screen.
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late final DevicesViewModel _model = DevicesViewModel(
    account: context.read<AccountRepository>(),
  );

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDevices)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_model, _model.load]),
        builder: (BuildContext context, Widget? _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.devicesExplanation,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            ..._body(l10n, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(AppLocalizations l10n, ThemeData theme) {
    if (_model.load.running && _model.devices.isEmpty) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_model.load.error && _model.devices.isEmpty) {
      return <Widget>[
        ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(l10n.devicesFailed),
          trailing: TextButton(
            onPressed: _model.load.execute,
            child: Text(l10n.federationRetry),
          ),
        ),
      ];
    }

    return <Widget>[
      for (final device in _model.devices)
        _DeviceTile(
          device: device,
          isThisDevice: device.id == _model.thisDevice,
          onRename: () => _rename(device),
          onRevoke: () => _confirmRevoke(device),
        ),
    ];
  }

  Future<void> _rename(Device device) async {
    final l10n = AppLocalizations.of(context);

    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _RenameDialog(device: device),
    );

    if (name == null) {
      return;
    }

    final renamed = await _model.rename(device, name);

    _say(switch (renamed) {
      Ok<Device>(:final value) => l10n.devicesRenamed(value.name),
      Error<Device>() => l10n.devicesRenameFailed,
    });
  }

  Future<void> _confirmRevoke(Device device) async {
    final l10n = AppLocalizations.of(context);

    final revoke = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.devicesRevokeTitle(device.name)),
        content: Text(l10n.devicesRevokeExplanation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.federationCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.devicesRevoke),
          ),
        ],
      ),
    );

    if (revoke != true) {
      return;
    }

    final revoked = await _model.revoke(device);

    _say(switch (revoked) {
      Ok<void>() => l10n.devicesRevoked(device.name),
      // The one refusal this app makes itself, and the one worth naming: a
      // device that unbound itself would have no way back.
      Error<void>(:final error)
          when error is AppException &&
              error.code == codeCannotRevokeThisDevice =>
        l10n.devicesCannotRevokeThisOne,
      Error<void>() => l10n.devicesRevokeFailed,
    });
  }

  void _say(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// One device, and the two things that can be done to it.
class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isThisDevice,
    required this.onRename,
    required this.onRevoke,
  });

  final Device device;
  final bool isThisDevice;
  final VoidCallback onRename;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        isThisDevice ? Icons.smartphone : Icons.devices_other_outlined,
        color: device.active ? null : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(device.name),
      isThreeLine: true,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isThisDevice
                ? l10n.devicesThisOne
                : device.active
                ? device.platform
                : l10n.devicesUnbound,
          ),
          Text(
            device.active
                ? _synchronized(context, l10n)
                : l10n.devicesUnboundExplanation,
          ),
        ],
      ),
      trailing: device.active
          ? OverflowBar(
              children: <Widget>[
                TextButton(
                  onPressed: onRename,
                  child: Text(l10n.devicesRename),
                ),
                // The device holding the screen is not offered an unbind it
                // would only be refused: it cannot end its own binding, and
                // saying so with an absence is quieter than saying it with an
                // error the reader had to provoke.
                if (!isThisDevice)
                  TextButton(
                    onPressed: onRevoke,
                    child: Text(l10n.devicesRevoke),
                  ),
              ],
            )
          : null,
    );
  }

  String _synchronized(BuildContext context, AppLocalizations l10n) {
    final at = device.lastSyncedAt;

    if (at == null) {
      return l10n.devicesNeverSynced;
    }

    return l10n.devicesLastSynced(
      MaterialLocalizations.of(context).formatMediumDate(at.toLocal()),
    );
  }
}

/// The one field of a bound device that is editable.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.device});

  final Device device;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.device.name,
  );

  bool _faulted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.devicesRenameTitle),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.devicesNameLabel,
          border: const OutlineInputBorder(),
          errorText: _faulted ? l10n.devicesNameInvalid : null,
        ),
        onSubmitted: (String _) => _save(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.federationCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.devicesSave)),
      ],
    );
  }

  /// Checks the shape here, so that a blank name is not a round trip.
  ///
  /// The node checks it again and is the authority; what this saves is a
  /// dialog that closes, fails, and reopens for something the field could have
  /// said.
  void _save() {
    if (deviceNameViolation(_name.text.trim()) != null) {
      setState(() => _faulted = true);

      return;
    }

    Navigator.of(context).pop(_name.text.trim());
  }
}
