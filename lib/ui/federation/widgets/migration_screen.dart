/// Moving to another origin server (UC16, RF17) — the operation this project
/// exists to demonstrate.
///
/// **It is a wizard because it cannot be undone.** Everything before the last
/// step is deliberation: what the move does, where to, what travels, and only
/// then the one call. The four steps are also the four things a reader can be
/// wrong about, in the order they would think of them.
///
/// **This device is pointed at the new node at the last step and not before.**
/// Discovering the domain early would validate it, and it would also leave the
/// app talking to a node the reader has no account on while they fill in a
/// form — every call failing for a reason nothing on screen explains. So the
/// domain is checked for *shape* where it is typed, the node is reached once,
/// and committing and connecting are the same act. A migration that fails
/// points the device back.
///
/// **The devices are worked out when the wizard opens.** `ListDevices` is a
/// call to the node being *left*, and the last thing this screen does is stop
/// talking to it. When that node does not answer the identifiers come out of
/// the replica's own clocks instead and the names do not exist — which the
/// step says plainly, because a migration is still correct without the names
/// and is not correct without the identifiers (C11).
///
/// **Nothing is cleared on the way through.** The outbox, the causal state and
/// the replica are what the devices then push to the new node; a client that
/// emptied them would have completed the migration by discarding what was
/// being migrated.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/federation/federation_repository.dart';
import '../../../domain/models/server.dart';
import '../../../domain/models/user.dart';
import '../../../utils/errors.dart';
import '../../../utils/result.dart';
import '../../core/localization/localization.dart';
import '../view_model/migration_view_model.dart';

/// The home server migration screen.
class MigrationScreen extends StatefulWidget {
  /// Creates the home server migration screen.
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  late final MigrationViewModel _model = MigrationViewModel(
    federation: context.read<FederationRepository>(),
    auth: context.read<AuthRepository>(),
  );

  final TextEditingController _domain = TextEditingController();
  final TextEditingController _localName = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  /// The last step, which is the one that makes the call.
  static const int _confirmStep = 3;

  int _step = 0;

  @override
  void initState() {
    super.initState();
    _model.migrate.addListener(_onMoved);
  }

  @override
  void dispose() {
    _model.migrate.removeListener(_onMoved);
    _domain.dispose();
    _localName.dispose();
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onMoved() {
    if (_model.migrate.running || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    switch (_model.migrate.result) {
      case Ok<User>(:final value):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.migrationDone(value.federatedId))),
        );
      case Error<User>(:final error):
        // A refusal about what was typed is shown on the step the typing is
        // on, so the reader is taken back to it. A vertical stepper shows one
        // step's content at a time, and a field error under a collapsed step
        // is an error nobody sees.
        if (error is AppException && error.fields.isNotEmpty) {
          setState(() => _step = 1);

          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException && error.kind == ErrorKind.alreadyExists
                  ? l10n.migrationNameTaken
                  : l10n.migrationFailed,
            ),
          ),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsMigrate)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _model,
          _model.devices,
          _model.migrate,
        ]),
        builder: (BuildContext context, Widget? _) => Stepper(
          type: StepperType.vertical,
          currentStep: _step,
          onStepTapped: _model.migrate.running
              ? null
              : (int step) => setState(() => _step = step),
          onStepContinue: _model.migrate.running ? null : _continue,
          onStepCancel: _step == 0 || _model.migrate.running
              ? null
              : () => setState(() => _step--),
          // A vertical stepper builds the controls of every step, so the label
          // is chosen from the step being built and not from the one the
          // reader is on: reading `_step` here would put *move* under the
          // first step and *continue* under the last.
          controlsBuilder: (BuildContext context, ControlsDetails controls) {
            final last = controls.stepIndex == _confirmStep;

            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OverflowBar(
                spacing: 12,
                children: <Widget>[
                  FilledButton(
                    onPressed: controls.onStepContinue,
                    child: last && _model.migrate.running
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(last ? l10n.migrationGo : l10n.migrationNext),
                  ),
                  if (controls.stepIndex > 0)
                    TextButton(
                      onPressed: controls.onStepCancel,
                      child: Text(l10n.migrationBack),
                    ),
                ],
              ),
            );
          },
          steps: <Step>[
            Step(
              title: Text(l10n.migrationStepWhat),
              isActive: _step >= 0,
              content: _what(l10n),
            ),
            Step(
              title: Text(l10n.migrationStepServer),
              isActive: _step >= 1,
              content: _where(l10n),
            ),
            Step(
              title: Text(l10n.migrationStepDevices),
              isActive: _step >= 2,
              content: _travelling(l10n),
            ),
            Step(
              title: Text(l10n.migrationStepConfirm),
              isActive: _step >= 3,
              content: _confirm(l10n),
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    if (_step < _confirmStep) {
      setState(() => _step++);

      return;
    }

    unawaited(
      _model.migrate.execute(
        HomeServerMigration(
          domain: _domain.text,
          localName: _localName.text,
          displayName: _displayName.text,
          email: _email.text,
          password: _password.text,
          devices: _model.carrying(_nameOf),
        ),
      ),
    );
  }

  /// What a device the node being left could not name is called.
  ///
  /// The identifier's first characters go into it so that two of them can be
  /// told apart in a list — a device named nothing in particular is a device
  /// the reader cannot rename with any confidence afterwards.
  String _nameOf(CarriedDevice device) =>
      AppLocalizations.of(context)
          .migrationUnnamedDevice(device.id.substring(0, 8));

  Widget _what(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final reader = _model.signedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.migrationExplanation, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (reader != null)
          _warning(
            theme,
            Icons.badge_outlined,
            l10n.migrationIdentifierChanges(
              reader.localName,
              reader.originServerDomain,
            ),
          ),
        _warning(theme, Icons.copy_all_outlined, l10n.migrationReauthorize),
        _warning(
          theme,
          Icons.warning_amber_outlined,
          l10n.migrationIrreversible,
        ),
      ],
    );
  }

  Widget _where(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _destination(l10n),
        const SizedBox(height: 8),
        Text(
          l10n.migrationConnectsAtTheEnd,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _localName,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.migrationLocalNameLabel,
            border: const OutlineInputBorder(),
            errorText: _faulted('local_name', l10n),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _displayName,
          decoration: InputDecoration(
            labelText: l10n.migrationDisplayNameLabel,
            border: const OutlineInputBorder(),
            errorText: _faulted('display_name', l10n),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.migrationEmailLabel,
            border: const OutlineInputBorder(),
            errorText: _faulted('email', l10n),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.migrationPasswordLabel,
            border: const OutlineInputBorder(),
            errorText: _faulted('password', l10n),
          ),
        ),
      ],
    );
  }

  /// Where the migration goes: the nodes already discovered, and the field
  /// that takes any other.
  ///
  /// One control and not two, because it is one question. A `DropdownMenu` is
  /// a text field that also drops a list down, so the reader who has added the
  /// destination to their catalogue picks it and the reader who has not types
  /// it — and nothing has to decide in advance which of the two they are.
  ///
  /// It falls back to a plain field when the catalogue is empty or could not be
  /// read, rather than offering a list with nothing in it: a menu that opens
  /// onto nothing reads as a broken control, and the domain was always
  /// typeable.
  Widget _destination(AppLocalizations l10n) {
    final known = _model.destinations;
    final failure = _faulted('domain', l10n);

    if (known.isEmpty) {
      return TextField(
        controller: _domain,
        autocorrect: false,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: l10n.migrationDomainLabel,
          hintText: l10n.federationAddHint,
          border: const OutlineInputBorder(),
          errorText: failure,
        ),
      );
    }

    return DropdownMenu<String>(
      controller: _domain,
      enabled: !_model.migrate.running,
      // The field is the primary way in and the list is the shortcut, so a tap
      // puts the cursor in it and what is typed narrows what is offered.
      requestFocusOnTap: true,
      enableFilter: true,
      expandedInsets: EdgeInsets.zero,
      keyboardType: TextInputType.url,
      label: Text(l10n.migrationDomainLabel),
      hintText: l10n.federationAddHint,
      errorText: failure,
      dropdownMenuEntries: <DropdownMenuEntry<String>>[
        for (final server in known)
          DropdownMenuEntry<String>(
            value: server.descriptor.domain,
            // A domain is a domain in both languages, and this one is the
            // reader's own text rather than a message of the app's.
            label: server.descriptor.domain,
            leadingIcon: const Icon(Icons.dns_outlined),
          ),
      ],
    );
  }

  Widget _travelling(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final carried = _model.carried;

    if (_model.devices.running) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (carried == null) {
      return Text(
        l10n.migrationDevicesFailed,
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.migrationDevicesExplanation,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (!carried.named)
          _warning(theme, Icons.help_outline, l10n.migrationDevicesUnnamed),
        for (final device in carried.devices)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              device.isThisDevice
                  ? Icons.smartphone
                  : Icons.devices_other_outlined,
            ),
            title: Text(device.name ?? _nameOf(device)),
            subtitle: device.isThisDevice
                ? Text(l10n.migrationThisDevice)
                : null,
          ),
      ],
    );
  }

  Widget _confirm(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.migrationSummary(
            canonicalLocalName(_localName.text),
            canonicalServerDomain(_domain.text),
            _model.deviceCount,
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.migrationNothingIsCleared,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// What the last attempt faulted about [field], or `null`.
  ///
  /// The whole form is checked at once and every violation comes back
  /// together, so a reader who typed four things wrong learns four things
  /// rather than submitting four times.
  String? _faulted(String field, AppLocalizations l10n) {
    if (_model.migrate.result case Error<User>(:final error)
        when error is AppException) {
      for (final failure in error.fields) {
        if (failure.name == field) {
          return switch (field) {
            'domain' => l10n.migrationInvalidDomain,
            'local_name' => l10n.migrationInvalidLocalName,
            'display_name' => l10n.migrationInvalidDisplayName,
            'email' => l10n.migrationInvalidEmail,
            _ => l10n.migrationInvalidPassword,
          };
        }
      }
    }

    return null;
  }

  Widget _warning(ThemeData theme, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );
}
