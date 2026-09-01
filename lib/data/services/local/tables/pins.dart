/// Which files this device keeps.
///
/// It is **one mechanism with two defaults** rather than two features, because
/// the question a reader is answering is the same one on all six targets — *is
/// this book here when the network is not* — and only the honest answer differs
/// by platform. On the five native targets a book is kept unless the reader
/// released it; in a browser nothing is kept until they ask, because the origin
/// is lent a share of a disk that the browser may take back.
///
/// So a row here is a **decision**, and its absence is the platform's default.
/// A table of *kept* books would have to be filled in on a native install for
/// every book that ever arrived; a table of *released* ones could not express a
/// browser's opt-in. Recording the decision expresses both, and it is why
/// `content_pins` carries a boolean rather than being a membership list.
///
/// It replicates to nobody. What a reader keeps on their phone is not a claim
/// about the work, and a device that inherited another's decisions would fill a
/// browser's quota with a desktop's library.
///
/// **The key is the digest and not the work**, as it is in the blob store and
/// in the queue. Two works naming one file are one file: a reader who keeps one
/// of them keeps the bytes, and there is nothing to release separately.
library;

import 'package:drift/drift.dart';

import '../converters.dart';

/// What the reader decided about one file.
@DataClassName('ContentPinRow')
class ContentPins extends Table {
  /// The file, lowercase hex sha-256.
  TextColumn get contentHash => text().withLength(min: 64, max: 64)();

  /// Whether this device keeps it.
  ///
  /// A row saying `false` is a reader who released a book on a native install;
  /// a row saying `true` is one who asked for a book in a browser. The absence
  /// of a row is neither, and is what the platform's default answers.
  BoolColumn get kept => boolean()();

  /// When they decided, so that a screen can order what is held by when the
  /// reader asked for it.
  IntColumn get decidedAt => integer().map(const InstantConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{contentHash};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (content_hash GLOB '[0-9a-f]*' AND length(content_hash) = 64)",
  ];
}
