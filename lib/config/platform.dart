/// What this device calls itself when it asks to be bound.
///
/// The contract leaves `Device.platform` free-form on purpose, so that a
/// seventh platform does not need the node redeployed, and this is the one
/// place the six this app is built for are spelled. It is read at the edge for
/// the same reason `Environment` reads the compile-time flags there: a
/// repository that asked the framework what platform it was on would be a
/// repository that could not be tested as any other.
///
/// The guard is `kIsWeb` and `defaultTargetPlatform` and not `dart:io`, which
/// does not parse for the web target.
library;

import 'package:flutter/foundation.dart';

/// The platform string this device binds under.
///
/// It is `android`, `ios`, `web`, `linux`, `macos` or `windows`, which is what
/// `Device.platform` documents and what the node stores unexamined.
String get devicePlatform {
  if (kIsWeb) {
    return 'web';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.linux => 'linux',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

/// How a platform is written where a reader sees it.
///
/// They are proper nouns and are the same in both languages, which is why they
/// are here rather than in the ARB: a translator handed `macOS` has nothing to
/// decide, and six messages that must never be translated are six messages to
/// keep identical in every file. What *is* in the ARB is the sentence they are
/// substituted into, which is the part that has a grammar.
String labelOfPlatform(String platform) => switch (platform) {
  'android' => 'Android',
  'ios' => 'iOS',
  'web' => 'Web',
  'linux' => 'Linux',
  'macos' => 'macOS',
  'windows' => 'Windows',
  _ => platform,
};
