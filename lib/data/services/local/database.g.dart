// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
abstract class _$AtrilDatabase extends GeneratedDatabase {
  _$AtrilDatabase(QueryExecutor e) : super(e);
  $AtrilDatabaseManager get managers => $AtrilDatabaseManager(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
}

class $AtrilDatabaseManager {
  final _$AtrilDatabase _db;
  $AtrilDatabaseManager(this._db);
}
