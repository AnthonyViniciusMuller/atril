// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $PendingOperationsTable get pendingOperations =>
      attachedDatabase.pendingOperations;
  $KnownServersTable get knownServers => attachedDatabase.knownServers;
  $NodeCursorsTable get nodeCursors => attachedDatabase.nodeCursors;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(
        _db.attachedDatabase,
        _db.pendingOperations,
      );
  $$KnownServersTableTableManager get knownServers =>
      $$KnownServersTableTableManager(_db.attachedDatabase, _db.knownServers);
  $$NodeCursorsTableTableManager get nodeCursors =>
      $$NodeCursorsTableTableManager(_db.attachedDatabase, _db.nodeCursors);
}
