// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_dao.dart';

// ignore_for_file: type=lint
mixin _$LibraryDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $EbooksTable get ebooks => attachedDatabase.ebooks;
  $CollectionsTable get collections => attachedDatabase.collections;
  $EbookCollectionsTable get ebookCollections =>
      attachedDatabase.ebookCollections;
  LibraryDaoManager get managers => LibraryDaoManager(this);
}

class LibraryDaoManager {
  final _$LibraryDaoMixin _db;
  LibraryDaoManager(this._db);
  $$EbooksTableTableManager get ebooks =>
      $$EbooksTableTableManager(_db.attachedDatabase, _db.ebooks);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db.attachedDatabase, _db.collections);
  $$EbookCollectionsTableTableManager get ebookCollections =>
      $$EbookCollectionsTableTableManager(
        _db.attachedDatabase,
        _db.ebookCollections,
      );
}
