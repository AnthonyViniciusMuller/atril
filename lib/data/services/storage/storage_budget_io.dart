/// The storage budget on the five native targets.
library;

import 'blob_store.dart';
import 'storage_budget.dart';

/// What [store] holds, with no total.
///
/// There is no portable way to ask a volume how much room is left, and the
/// reason that is tolerable is in [StorageBudget.quota]: a native install keeps
/// every book by default, so there is no budget being spent here. What is
/// reported is what the store holds, which is what a reader releasing a book
/// wants to see.
Future<StorageBudget> readStorageBudget(BlobStore store) async =>
    StorageBudget(used: await store.usedBytes());
