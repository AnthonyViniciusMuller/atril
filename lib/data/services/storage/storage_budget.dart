/// What the store holds, and what it may hold.
///
/// It exists because the web build spends its budget deliberately rather than
/// discovering it. A browser gives an origin a share of the disk and may take
/// it back; a reader whose next download fails deserves a sentence rather than
/// a crash, and one whose book was evicted deserves never to find out that way.
/// So the number is asked for and shown, and phase 8's per-book pinning is
/// spent against it.
///
/// The five native targets answer only half of it, and that is a decision
/// rather than an omission — see [StorageBudget.available].
library;

/// How much room there is for the reader's books.
final class StorageBudget {
  /// A budget holding [used] bytes, of [quota] where one is known.
  const StorageBudget({required this.used, this.quota});

  /// The budget of a store that could not be measured at all.
  static const StorageBudget unknown = StorageBudget(used: 0);

  /// What this app's blob store is holding, in bytes.
  ///
  /// It is measured from the store itself and not from the metadata: what a
  /// reader is being told is how much room their books take, and a sum over
  /// `ebooks.size_bytes` would count books whose bytes are on another device.
  final int used;

  /// What the store may hold in total, or `null` where nothing can say.
  ///
  /// On the web it is `navigator.storage.estimate().quota`, which is the
  /// browser's own answer and the one that decides whether the next download
  /// succeeds.
  ///
  /// On the five native targets it is `null`, deliberately. Dart offers no
  /// portable way to ask a volume how much room is left, and no package on pub
  /// covers all five — the maintained one has no macOS — so the choice was
  /// between a number that is absent on one target, a number this session
  /// could not verify on four, and no number at all. The third is the only one
  /// that does not risk telling a reader something false, and it costs least:
  /// a native install keeps every book by default and has no budget to spend,
  /// while the web build, which does, has a real answer. Phase 8 is where the
  /// number is first shown, and where this is worth revisiting.
  final int? quota;

  /// What is left, or `null` where [quota] is.
  int? get available {
    final total = quota;

    return total == null ? null : (total - used).clamp(0, total);
  }

  /// Whether anything is known beyond what the store holds.
  bool get isMeasured => quota != null;

  /// Whether [bytes] more would fit.
  ///
  /// A store with no quota answers that it would. That is the honest answer
  /// and not an optimistic one: nothing here knows of a limit, so nothing here
  /// should refuse a download the platform has not refused.
  bool fits(int bytes) {
    final room = available;

    return room == null || bytes <= room;
  }

  @override
  String toString() =>
      'StorageBudget(used: $used, quota: ${quota ?? 'unknown'})';
}
