// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfers_dao.dart';

// ignore_for_file: type=lint
mixin _$TransfersDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $ContentUploadsTable get contentUploads => attachedDatabase.contentUploads;
  $ContentPinsTable get contentPins => attachedDatabase.contentPins;
  TransfersDaoManager get managers => TransfersDaoManager(this);
}

class TransfersDaoManager {
  final _$TransfersDaoMixin _db;
  TransfersDaoManager(this._db);
  $$ContentUploadsTableTableManager get contentUploads =>
      $$ContentUploadsTableTableManager(
        _db.attachedDatabase,
        _db.contentUploads,
      );
  $$ContentPinsTableTableManager get contentPins =>
      $$ContentPinsTableTableManager(_db.attachedDatabase, _db.contentPins);
}
