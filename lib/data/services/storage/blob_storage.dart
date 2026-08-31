/// The blob store this platform has, chosen at compile time.
///
/// It is the third and last conditional export in the app, and it is one for
/// the same reason the other two are: a `dart:io` import does not parse for the
/// web target and a `package:web` one does not parse for the others, so the two
/// stores cannot be implementations picked at run time — both branches would
/// still have to compile. `architecture.md` states the rule and lists all
/// three.
///
/// What a caller sees is [BlobStore] and two functions. Which file answered is
/// not something anything above this directory can ask.
library;

export 'blob_store.dart';
export 'blob_store_io.dart'
    if (dart.library.js_interop) 'blob_store_web.dart'
    show blobChunkBytes, blobStoreIsSupported, openBlobStore;
