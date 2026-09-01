// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $EbooksTable get ebooks => attachedDatabase.ebooks;
  $ProgressTable get progress => attachedDatabase.progress;
  ReadingDaoManager get managers => ReadingDaoManager(this);
}

class ReadingDaoManager {
  final _$ReadingDaoMixin _db;
  ReadingDaoManager(this._db);
  $$EbooksTableTableManager get ebooks =>
      $$EbooksTableTableManager(_db.attachedDatabase, _db.ebooks);
  $$ProgressTableTableManager get progress =>
      $$ProgressTableTableManager(_db.attachedDatabase, _db.progress);
}
