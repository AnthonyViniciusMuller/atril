// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotations_dao.dart';

// ignore_for_file: type=lint
mixin _$AnnotationsDaoMixin on DatabaseAccessor<AtrilDatabase> {
  $EbooksTable get ebooks => attachedDatabase.ebooks;
  $AnnotationsTable get annotations => attachedDatabase.annotations;
  AnnotationsDaoManager get managers => AnnotationsDaoManager(this);
}

class AnnotationsDaoManager {
  final _$AnnotationsDaoMixin _db;
  AnnotationsDaoManager(this._db);
  $$EbooksTableTableManager get ebooks =>
      $$EbooksTableTableManager(_db.attachedDatabase, _db.ebooks);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db.attachedDatabase, _db.annotations);
}
