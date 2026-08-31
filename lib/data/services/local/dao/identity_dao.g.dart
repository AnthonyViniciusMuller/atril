// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_dao.dart';

// ignore_for_file: type=lint
mixin _$IdentityDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $BoundDeviceTable get boundDevice => attachedDatabase.boundDevice;
  $KnownServersTable get knownServers => attachedDatabase.knownServers;
  $SignedInReaderTable get signedInReader => attachedDatabase.signedInReader;
  $ClockFloorTable get clockFloor => attachedDatabase.clockFloor;
  IdentityDaoManager get managers => IdentityDaoManager(this);
}

class IdentityDaoManager {
  final _$IdentityDaoMixin _db;
  IdentityDaoManager(this._db);
  $$BoundDeviceTableTableManager get boundDevice =>
      $$BoundDeviceTableTableManager(_db.attachedDatabase, _db.boundDevice);
  $$KnownServersTableTableManager get knownServers =>
      $$KnownServersTableTableManager(_db.attachedDatabase, _db.knownServers);
  $$SignedInReaderTableTableManager get signedInReader =>
      $$SignedInReaderTableTableManager(
        _db.attachedDatabase,
        _db.signedInReader,
      );
  $$ClockFloorTableTableManager get clockFloor =>
      $$ClockFloorTableTableManager(_db.attachedDatabase, _db.clockFloor);
}
