// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'records_dao.dart';

// ignore_for_file: type=lint
mixin _$RecordsDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $RecordVersionsTable get recordVersions => attachedDatabase.recordVersions;
  RecordsDaoManager get managers => RecordsDaoManager(this);
}

class RecordsDaoManager {
  final _$RecordsDaoMixin _db;
  RecordsDaoManager(this._db);
  $$RecordVersionsTableTableManager get recordVersions =>
      $$RecordVersionsTableTableManager(
        _db.attachedDatabase,
        _db.recordVersions,
      );
}
