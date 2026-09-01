// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BoundDeviceTable extends BoundDevice
    with TableInfo<$BoundDeviceTable, BoundDeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoundDeviceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _onlyRowMeta = const VerificationMeta(
    'onlyRow',
  );
  @override
  late final GeneratedColumn<int> onlyRow = GeneratedColumn<int>(
    'only_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> boundAt =
      GeneratedColumn<int>(
        'bound_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BoundDeviceTable.$converterboundAt);
  @override
  List<GeneratedColumn> get $columns => [onlyRow, id, name, platform, boundAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bound_device';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoundDeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('only_row')) {
      context.handle(
        _onlyRowMeta,
        onlyRow.isAcceptableOrUnknown(data['only_row']!, _onlyRowMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {onlyRow};
  @override
  BoundDeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoundDeviceRow(
      onlyRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}only_row'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      boundAt: $BoundDeviceTable.$converterboundAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}bound_at'],
        )!,
      ),
    );
  }

  @override
  $BoundDeviceTable createAlias(String alias) {
    return $BoundDeviceTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterboundAt =
      const InstantConverter();
}

class BoundDeviceRow extends DataClass implements Insertable<BoundDeviceRow> {
  /// The single row, spelled as a column so that sqlite is what refuses a
  /// second one. See [singleRow].
  final int onlyRow;

  /// The identifier the node minted when this device was bound, in canonical
  /// lowercase text. It is the key of this device's entry in every vector
  /// clock in the replica.
  final String id;

  /// What the reader calls this device, as it was sent at binding.
  final String name;

  /// `android`, `ios`, `web`, `linux`, `macos` or `windows`. It is free-form in
  /// the contract on purpose, so that a seventh does not need the node
  /// redeployed, and it is free-form here for the same reason.
  final String platform;

  /// When the binding happened. A wall clock reading, shown to a reader on the
  /// device screen and never compared against a hybrid one.
  final DateTime boundAt;
  const BoundDeviceRow({
    required this.onlyRow,
    required this.id,
    required this.name,
    required this.platform,
    required this.boundAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['only_row'] = Variable<int>(onlyRow);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['platform'] = Variable<String>(platform);
    {
      map['bound_at'] = Variable<int>(
        $BoundDeviceTable.$converterboundAt.toSql(boundAt),
      );
    }
    return map;
  }

  BoundDeviceCompanion toCompanion(bool nullToAbsent) {
    return BoundDeviceCompanion(
      onlyRow: Value(onlyRow),
      id: Value(id),
      name: Value(name),
      platform: Value(platform),
      boundAt: Value(boundAt),
    );
  }

  factory BoundDeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoundDeviceRow(
      onlyRow: serializer.fromJson<int>(json['onlyRow']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      platform: serializer.fromJson<String>(json['platform']),
      boundAt: serializer.fromJson<DateTime>(json['boundAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'onlyRow': serializer.toJson<int>(onlyRow),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'platform': serializer.toJson<String>(platform),
      'boundAt': serializer.toJson<DateTime>(boundAt),
    };
  }

  BoundDeviceRow copyWith({
    int? onlyRow,
    String? id,
    String? name,
    String? platform,
    DateTime? boundAt,
  }) => BoundDeviceRow(
    onlyRow: onlyRow ?? this.onlyRow,
    id: id ?? this.id,
    name: name ?? this.name,
    platform: platform ?? this.platform,
    boundAt: boundAt ?? this.boundAt,
  );
  BoundDeviceRow copyWithCompanion(BoundDeviceCompanion data) {
    return BoundDeviceRow(
      onlyRow: data.onlyRow.present ? data.onlyRow.value : this.onlyRow,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      platform: data.platform.present ? data.platform.value : this.platform,
      boundAt: data.boundAt.present ? data.boundAt.value : this.boundAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoundDeviceRow(')
          ..write('onlyRow: $onlyRow, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('boundAt: $boundAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(onlyRow, id, name, platform, boundAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoundDeviceRow &&
          other.onlyRow == this.onlyRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.platform == this.platform &&
          other.boundAt == this.boundAt);
}

class BoundDeviceCompanion extends UpdateCompanion<BoundDeviceRow> {
  final Value<int> onlyRow;
  final Value<String> id;
  final Value<String> name;
  final Value<String> platform;
  final Value<DateTime> boundAt;
  const BoundDeviceCompanion({
    this.onlyRow = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.platform = const Value.absent(),
    this.boundAt = const Value.absent(),
  });
  BoundDeviceCompanion.insert({
    this.onlyRow = const Value.absent(),
    required String id,
    required String name,
    required String platform,
    required DateTime boundAt,
  }) : id = Value(id),
       name = Value(name),
       platform = Value(platform),
       boundAt = Value(boundAt);
  static Insertable<BoundDeviceRow> custom({
    Expression<int>? onlyRow,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? platform,
    Expression<int>? boundAt,
  }) {
    return RawValuesInsertable({
      if (onlyRow != null) 'only_row': onlyRow,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (platform != null) 'platform': platform,
      if (boundAt != null) 'bound_at': boundAt,
    });
  }

  BoundDeviceCompanion copyWith({
    Value<int>? onlyRow,
    Value<String>? id,
    Value<String>? name,
    Value<String>? platform,
    Value<DateTime>? boundAt,
  }) {
    return BoundDeviceCompanion(
      onlyRow: onlyRow ?? this.onlyRow,
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      boundAt: boundAt ?? this.boundAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (onlyRow.present) {
      map['only_row'] = Variable<int>(onlyRow.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (boundAt.present) {
      map['bound_at'] = Variable<int>(
        $BoundDeviceTable.$converterboundAt.toSql(boundAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoundDeviceCompanion(')
          ..write('onlyRow: $onlyRow, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('boundAt: $boundAt')
          ..write(')'))
        .toString();
  }
}

class $KnownServersTable extends KnownServers
    with TableInfo<$KnownServersTable, ServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jwksUriMeta = const VerificationMeta(
    'jwksUri',
  );
  @override
  late final GeneratedColumn<String> jwksUri = GeneratedColumn<String>(
    'jwks_uri',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificateFingerprintMeta =
      const VerificationMeta('certificateFingerprint');
  @override
  late final GeneratedColumn<String> certificateFingerprint =
      GeneratedColumn<String>(
        'certificate_fingerprint',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 128),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _grpcAuthorityMeta = const VerificationMeta(
    'grpcAuthority',
  );
  @override
  late final GeneratedColumn<String> grpcAuthority = GeneratedColumn<String>(
    'grpc_authority',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOriginMeta = const VerificationMeta(
    'isOrigin',
  );
  @override
  late final GeneratedColumn<bool> isOrigin = GeneratedColumn<bool>(
    'is_origin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_origin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> discoveredAt =
      GeneratedColumn<int>(
        'discovered_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($KnownServersTable.$converterdiscoveredAtn);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    domain,
    remoteId,
    baseUrl,
    jwksUri,
    certificateFingerprint,
    grpcAuthority,
    isOrigin,
    discoveredAt,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('jwks_uri')) {
      context.handle(
        _jwksUriMeta,
        jwksUri.isAcceptableOrUnknown(data['jwks_uri']!, _jwksUriMeta),
      );
    }
    if (data.containsKey('certificate_fingerprint')) {
      context.handle(
        _certificateFingerprintMeta,
        certificateFingerprint.isAcceptableOrUnknown(
          data['certificate_fingerprint']!,
          _certificateFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('grpc_authority')) {
      context.handle(
        _grpcAuthorityMeta,
        grpcAuthority.isAcceptableOrUnknown(
          data['grpc_authority']!,
          _grpcAuthorityMeta,
        ),
      );
    }
    if (data.containsKey('is_origin')) {
      context.handle(
        _isOriginMeta,
        isOrigin.isAcceptableOrUnknown(data['is_origin']!, _isOriginMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {domain};
  @override
  ServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerRow(
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      jwksUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jwks_uri'],
      ),
      certificateFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_fingerprint'],
      ),
      grpcAuthority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grpc_authority'],
      ),
      isOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_origin'],
      )!,
      discoveredAt: $KnownServersTable.$converterdiscoveredAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}discovered_at'],
        ),
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $KnownServersTable createAlias(String alias) {
    return $KnownServersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdiscoveredAt =
      const InstantConverter();
  static TypeConverter<DateTime?, int?> $converterdiscoveredAtn =
      NullAwareTypeConverter.wrap($converterdiscoveredAt);
}

class ServerRow extends DataClass implements Insertable<ServerRow> {
  /// The federation domain, which is the authority a lookup is addressed to,
  /// the second half of every identifier hosted there, and the key this device
  /// addresses a node by.
  ///
  /// It is the primary key and the node's own identifier is not, because a node
  /// discovered directly has no identifier to be keyed by: the client discovery
  /// document publishes `base_url` and `grpc` and nothing else, and the id in
  /// `federation.servers` is a value only the node itself can report. The domain
  /// is what a reader types, what the lookup is addressed to and what every
  /// federated identifier carries, so it is the one name for a node that exists
  /// at every point in this app's life.
  final String domain;

  /// The identifier the node calls itself by, once something has heard it say
  /// so.
  ///
  /// It is null on a node this device discovered for itself and is filled in by
  /// `ListKnownServers`, which is the only call that reports it. It is
  /// provenance rather than an address: nothing here resolves a node by it, and
  /// a node that answered with a different one would be a node that had been
  /// reinstalled rather than a second node.
  final String? remoteId;

  /// Where the node answers, which is deliberately separate from the domain: a
  /// node may be identified by one host and served from another.
  final String baseUrl;

  /// Where it publishes the keys its tokens are signed with.
  final String? jwksUri;

  /// `spki-sha256:<base64>`, the key a peer pins. Absent on a node whose
  /// document publishes none.
  final String? certificateFingerprint;

  /// The authority to dial for gRPC, as `host:port`.
  ///
  /// It is published separately from the base URL because the two are only the
  /// same address where a gateway collapses them (D06). It is absent on a node
  /// this device can record and cannot dial — and, on the web, it is not what
  /// is dialled at all: a browser reaches the gateway the environment names,
  /// because this authority is the one a *peer* dials for replication.
  final String? grpcAuthority;

  /// Whether this is the node the reader is signed in at.
  final bool isOrigin;

  /// When this device last read the node's discovery document. A key that has
  /// rotated is found by asking again, and this is what says how long ago that
  /// was.
  final DateTime? discoveredAt;

  /// False once the reader has removed the node from their catalogue. The row
  /// stays either way, because a revoked replica that still holds a copy is
  /// something the reader should keep being able to see.
  final bool active;
  const ServerRow({
    required this.domain,
    this.remoteId,
    required this.baseUrl,
    this.jwksUri,
    this.certificateFingerprint,
    this.grpcAuthority,
    required this.isOrigin,
    this.discoveredAt,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['domain'] = Variable<String>(domain);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['base_url'] = Variable<String>(baseUrl);
    if (!nullToAbsent || jwksUri != null) {
      map['jwks_uri'] = Variable<String>(jwksUri);
    }
    if (!nullToAbsent || certificateFingerprint != null) {
      map['certificate_fingerprint'] = Variable<String>(certificateFingerprint);
    }
    if (!nullToAbsent || grpcAuthority != null) {
      map['grpc_authority'] = Variable<String>(grpcAuthority);
    }
    map['is_origin'] = Variable<bool>(isOrigin);
    if (!nullToAbsent || discoveredAt != null) {
      map['discovered_at'] = Variable<int>(
        $KnownServersTable.$converterdiscoveredAtn.toSql(discoveredAt),
      );
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  KnownServersCompanion toCompanion(bool nullToAbsent) {
    return KnownServersCompanion(
      domain: Value(domain),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      baseUrl: Value(baseUrl),
      jwksUri: jwksUri == null && nullToAbsent
          ? const Value.absent()
          : Value(jwksUri),
      certificateFingerprint: certificateFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(certificateFingerprint),
      grpcAuthority: grpcAuthority == null && nullToAbsent
          ? const Value.absent()
          : Value(grpcAuthority),
      isOrigin: Value(isOrigin),
      discoveredAt: discoveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(discoveredAt),
      active: Value(active),
    );
  }

  factory ServerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerRow(
      domain: serializer.fromJson<String>(json['domain']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      jwksUri: serializer.fromJson<String?>(json['jwksUri']),
      certificateFingerprint: serializer.fromJson<String?>(
        json['certificateFingerprint'],
      ),
      grpcAuthority: serializer.fromJson<String?>(json['grpcAuthority']),
      isOrigin: serializer.fromJson<bool>(json['isOrigin']),
      discoveredAt: serializer.fromJson<DateTime?>(json['discoveredAt']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'domain': serializer.toJson<String>(domain),
      'remoteId': serializer.toJson<String?>(remoteId),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'jwksUri': serializer.toJson<String?>(jwksUri),
      'certificateFingerprint': serializer.toJson<String?>(
        certificateFingerprint,
      ),
      'grpcAuthority': serializer.toJson<String?>(grpcAuthority),
      'isOrigin': serializer.toJson<bool>(isOrigin),
      'discoveredAt': serializer.toJson<DateTime?>(discoveredAt),
      'active': serializer.toJson<bool>(active),
    };
  }

  ServerRow copyWith({
    String? domain,
    Value<String?> remoteId = const Value.absent(),
    String? baseUrl,
    Value<String?> jwksUri = const Value.absent(),
    Value<String?> certificateFingerprint = const Value.absent(),
    Value<String?> grpcAuthority = const Value.absent(),
    bool? isOrigin,
    Value<DateTime?> discoveredAt = const Value.absent(),
    bool? active,
  }) => ServerRow(
    domain: domain ?? this.domain,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    baseUrl: baseUrl ?? this.baseUrl,
    jwksUri: jwksUri.present ? jwksUri.value : this.jwksUri,
    certificateFingerprint: certificateFingerprint.present
        ? certificateFingerprint.value
        : this.certificateFingerprint,
    grpcAuthority: grpcAuthority.present
        ? grpcAuthority.value
        : this.grpcAuthority,
    isOrigin: isOrigin ?? this.isOrigin,
    discoveredAt: discoveredAt.present ? discoveredAt.value : this.discoveredAt,
    active: active ?? this.active,
  );
  ServerRow copyWithCompanion(KnownServersCompanion data) {
    return ServerRow(
      domain: data.domain.present ? data.domain.value : this.domain,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      jwksUri: data.jwksUri.present ? data.jwksUri.value : this.jwksUri,
      certificateFingerprint: data.certificateFingerprint.present
          ? data.certificateFingerprint.value
          : this.certificateFingerprint,
      grpcAuthority: data.grpcAuthority.present
          ? data.grpcAuthority.value
          : this.grpcAuthority,
      isOrigin: data.isOrigin.present ? data.isOrigin.value : this.isOrigin,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerRow(')
          ..write('domain: $domain, ')
          ..write('remoteId: $remoteId, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('jwksUri: $jwksUri, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('grpcAuthority: $grpcAuthority, ')
          ..write('isOrigin: $isOrigin, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    domain,
    remoteId,
    baseUrl,
    jwksUri,
    certificateFingerprint,
    grpcAuthority,
    isOrigin,
    discoveredAt,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerRow &&
          other.domain == this.domain &&
          other.remoteId == this.remoteId &&
          other.baseUrl == this.baseUrl &&
          other.jwksUri == this.jwksUri &&
          other.certificateFingerprint == this.certificateFingerprint &&
          other.grpcAuthority == this.grpcAuthority &&
          other.isOrigin == this.isOrigin &&
          other.discoveredAt == this.discoveredAt &&
          other.active == this.active);
}

class KnownServersCompanion extends UpdateCompanion<ServerRow> {
  final Value<String> domain;
  final Value<String?> remoteId;
  final Value<String> baseUrl;
  final Value<String?> jwksUri;
  final Value<String?> certificateFingerprint;
  final Value<String?> grpcAuthority;
  final Value<bool> isOrigin;
  final Value<DateTime?> discoveredAt;
  final Value<bool> active;
  final Value<int> rowid;
  const KnownServersCompanion({
    this.domain = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.jwksUri = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.grpcAuthority = const Value.absent(),
    this.isOrigin = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnownServersCompanion.insert({
    required String domain,
    this.remoteId = const Value.absent(),
    required String baseUrl,
    this.jwksUri = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.grpcAuthority = const Value.absent(),
    this.isOrigin = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : domain = Value(domain),
       baseUrl = Value(baseUrl);
  static Insertable<ServerRow> custom({
    Expression<String>? domain,
    Expression<String>? remoteId,
    Expression<String>? baseUrl,
    Expression<String>? jwksUri,
    Expression<String>? certificateFingerprint,
    Expression<String>? grpcAuthority,
    Expression<bool>? isOrigin,
    Expression<int>? discoveredAt,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (domain != null) 'domain': domain,
      if (remoteId != null) 'remote_id': remoteId,
      if (baseUrl != null) 'base_url': baseUrl,
      if (jwksUri != null) 'jwks_uri': jwksUri,
      if (certificateFingerprint != null)
        'certificate_fingerprint': certificateFingerprint,
      if (grpcAuthority != null) 'grpc_authority': grpcAuthority,
      if (isOrigin != null) 'is_origin': isOrigin,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnownServersCompanion copyWith({
    Value<String>? domain,
    Value<String?>? remoteId,
    Value<String>? baseUrl,
    Value<String?>? jwksUri,
    Value<String?>? certificateFingerprint,
    Value<String?>? grpcAuthority,
    Value<bool>? isOrigin,
    Value<DateTime?>? discoveredAt,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return KnownServersCompanion(
      domain: domain ?? this.domain,
      remoteId: remoteId ?? this.remoteId,
      baseUrl: baseUrl ?? this.baseUrl,
      jwksUri: jwksUri ?? this.jwksUri,
      certificateFingerprint:
          certificateFingerprint ?? this.certificateFingerprint,
      grpcAuthority: grpcAuthority ?? this.grpcAuthority,
      isOrigin: isOrigin ?? this.isOrigin,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (jwksUri.present) {
      map['jwks_uri'] = Variable<String>(jwksUri.value);
    }
    if (certificateFingerprint.present) {
      map['certificate_fingerprint'] = Variable<String>(
        certificateFingerprint.value,
      );
    }
    if (grpcAuthority.present) {
      map['grpc_authority'] = Variable<String>(grpcAuthority.value);
    }
    if (isOrigin.present) {
      map['is_origin'] = Variable<bool>(isOrigin.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<int>(
        $KnownServersTable.$converterdiscoveredAtn.toSql(discoveredAt.value),
      );
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownServersCompanion(')
          ..write('domain: $domain, ')
          ..write('remoteId: $remoteId, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('jwksUri: $jwksUri, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('grpcAuthority: $grpcAuthority, ')
          ..write('isOrigin: $isOrigin, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignedInReaderTable extends SignedInReader
    with TableInfo<$SignedInReaderTable, ReaderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignedInReaderTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _onlyRowMeta = const VerificationMeta(
    'onlyRow',
  );
  @override
  late final GeneratedColumn<int> onlyRow = GeneratedColumn<int>(
    'only_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localNameMeta = const VerificationMeta(
    'localName',
  );
  @override
  late final GeneratedColumn<String> localName = GeneratedColumn<String>(
    'local_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originServerDomainMeta =
      const VerificationMeta('originServerDomain');
  @override
  late final GeneratedColumn<String> originServerDomain =
      GeneratedColumn<String>(
        'origin_server_domain',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES known_servers (domain) ON DELETE RESTRICT',
        ),
      );
  static const VerificationMeta _federatedIdMeta = const VerificationMeta(
    'federatedId',
  );
  @override
  late final GeneratedColumn<String> federatedId = GeneratedColumn<String>(
    'federated_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 320,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SignedInReaderTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    onlyRow,
    id,
    localName,
    displayName,
    originServerDomain,
    federatedId,
    email,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signed_in_reader';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('only_row')) {
      context.handle(
        _onlyRowMeta,
        onlyRow.isAcceptableOrUnknown(data['only_row']!, _onlyRowMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_name')) {
      context.handle(
        _localNameMeta,
        localName.isAcceptableOrUnknown(data['local_name']!, _localNameMeta),
      );
    } else if (isInserting) {
      context.missing(_localNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('origin_server_domain')) {
      context.handle(
        _originServerDomainMeta,
        originServerDomain.isAcceptableOrUnknown(
          data['origin_server_domain']!,
          _originServerDomainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originServerDomainMeta);
    }
    if (data.containsKey('federated_id')) {
      context.handle(
        _federatedIdMeta,
        federatedId.isAcceptableOrUnknown(
          data['federated_id']!,
          _federatedIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_federatedIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {onlyRow};
  @override
  ReaderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderRow(
      onlyRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}only_row'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      originServerDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_server_domain'],
      )!,
      federatedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}federated_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      createdAt: $SignedInReaderTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $SignedInReaderTable createAlias(String alias) {
    return $SignedInReaderTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
}

class ReaderRow extends DataClass implements Insertable<ReaderRow> {
  /// The single row. See [singleRow].
  final int onlyRow;

  /// The reader's identifier at their origin node, in canonical lowercase text.
  final String id;

  /// The first half of the federated identifier, constrained by the node to
  /// `^[a-z0-9]([a-z0-9._-]{0,62}[a-z0-9])?$`. It is not re-checked here: the
  /// node is what admits a name, and a device that refused one the node had
  /// accepted could not store the reader it is signed in as.
  final String localName;

  /// What the reader calls themselves, and the only name meant to be shown.
  final String displayName;

  /// The node that authenticates this reader (RN08), which is the second half
  /// of their identifier.
  ///
  /// It is the domain and not an identifier, because the domain is what this
  /// device can always know: it is what the reader typed, what the `.well-known`
  /// lookup was addressed to, and what `LoginResponse.User.origin_server_domain`
  /// answers with. See [KnownServers.domain].
  final String originServerDomain;

  /// `@local_name:domain`, as the node assembled it. It is stored rather than
  /// composed here so that every client renders the identifier the same way.
  final String federatedId;

  /// Absent on a node that only replicates this reader, and absent from every
  /// reply but their own (RN09, C03).
  final String? email;

  /// When the account was created, as the node reports it.
  final DateTime createdAt;
  const ReaderRow({
    required this.onlyRow,
    required this.id,
    required this.localName,
    required this.displayName,
    required this.originServerDomain,
    required this.federatedId,
    this.email,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['only_row'] = Variable<int>(onlyRow);
    map['id'] = Variable<String>(id);
    map['local_name'] = Variable<String>(localName);
    map['display_name'] = Variable<String>(displayName);
    map['origin_server_domain'] = Variable<String>(originServerDomain);
    map['federated_id'] = Variable<String>(federatedId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    {
      map['created_at'] = Variable<int>(
        $SignedInReaderTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  SignedInReaderCompanion toCompanion(bool nullToAbsent) {
    return SignedInReaderCompanion(
      onlyRow: Value(onlyRow),
      id: Value(id),
      localName: Value(localName),
      displayName: Value(displayName),
      originServerDomain: Value(originServerDomain),
      federatedId: Value(federatedId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      createdAt: Value(createdAt),
    );
  }

  factory ReaderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderRow(
      onlyRow: serializer.fromJson<int>(json['onlyRow']),
      id: serializer.fromJson<String>(json['id']),
      localName: serializer.fromJson<String>(json['localName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      originServerDomain: serializer.fromJson<String>(
        json['originServerDomain'],
      ),
      federatedId: serializer.fromJson<String>(json['federatedId']),
      email: serializer.fromJson<String?>(json['email']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'onlyRow': serializer.toJson<int>(onlyRow),
      'id': serializer.toJson<String>(id),
      'localName': serializer.toJson<String>(localName),
      'displayName': serializer.toJson<String>(displayName),
      'originServerDomain': serializer.toJson<String>(originServerDomain),
      'federatedId': serializer.toJson<String>(federatedId),
      'email': serializer.toJson<String?>(email),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReaderRow copyWith({
    int? onlyRow,
    String? id,
    String? localName,
    String? displayName,
    String? originServerDomain,
    String? federatedId,
    Value<String?> email = const Value.absent(),
    DateTime? createdAt,
  }) => ReaderRow(
    onlyRow: onlyRow ?? this.onlyRow,
    id: id ?? this.id,
    localName: localName ?? this.localName,
    displayName: displayName ?? this.displayName,
    originServerDomain: originServerDomain ?? this.originServerDomain,
    federatedId: federatedId ?? this.federatedId,
    email: email.present ? email.value : this.email,
    createdAt: createdAt ?? this.createdAt,
  );
  ReaderRow copyWithCompanion(SignedInReaderCompanion data) {
    return ReaderRow(
      onlyRow: data.onlyRow.present ? data.onlyRow.value : this.onlyRow,
      id: data.id.present ? data.id.value : this.id,
      localName: data.localName.present ? data.localName.value : this.localName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      originServerDomain: data.originServerDomain.present
          ? data.originServerDomain.value
          : this.originServerDomain,
      federatedId: data.federatedId.present
          ? data.federatedId.value
          : this.federatedId,
      email: data.email.present ? data.email.value : this.email,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderRow(')
          ..write('onlyRow: $onlyRow, ')
          ..write('id: $id, ')
          ..write('localName: $localName, ')
          ..write('displayName: $displayName, ')
          ..write('originServerDomain: $originServerDomain, ')
          ..write('federatedId: $federatedId, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    onlyRow,
    id,
    localName,
    displayName,
    originServerDomain,
    federatedId,
    email,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderRow &&
          other.onlyRow == this.onlyRow &&
          other.id == this.id &&
          other.localName == this.localName &&
          other.displayName == this.displayName &&
          other.originServerDomain == this.originServerDomain &&
          other.federatedId == this.federatedId &&
          other.email == this.email &&
          other.createdAt == this.createdAt);
}

class SignedInReaderCompanion extends UpdateCompanion<ReaderRow> {
  final Value<int> onlyRow;
  final Value<String> id;
  final Value<String> localName;
  final Value<String> displayName;
  final Value<String> originServerDomain;
  final Value<String> federatedId;
  final Value<String?> email;
  final Value<DateTime> createdAt;
  const SignedInReaderCompanion({
    this.onlyRow = const Value.absent(),
    this.id = const Value.absent(),
    this.localName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.originServerDomain = const Value.absent(),
    this.federatedId = const Value.absent(),
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignedInReaderCompanion.insert({
    this.onlyRow = const Value.absent(),
    required String id,
    required String localName,
    required String displayName,
    required String originServerDomain,
    required String federatedId,
    this.email = const Value.absent(),
    required DateTime createdAt,
  }) : id = Value(id),
       localName = Value(localName),
       displayName = Value(displayName),
       originServerDomain = Value(originServerDomain),
       federatedId = Value(federatedId),
       createdAt = Value(createdAt);
  static Insertable<ReaderRow> custom({
    Expression<int>? onlyRow,
    Expression<String>? id,
    Expression<String>? localName,
    Expression<String>? displayName,
    Expression<String>? originServerDomain,
    Expression<String>? federatedId,
    Expression<String>? email,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (onlyRow != null) 'only_row': onlyRow,
      if (id != null) 'id': id,
      if (localName != null) 'local_name': localName,
      if (displayName != null) 'display_name': displayName,
      if (originServerDomain != null)
        'origin_server_domain': originServerDomain,
      if (federatedId != null) 'federated_id': federatedId,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SignedInReaderCompanion copyWith({
    Value<int>? onlyRow,
    Value<String>? id,
    Value<String>? localName,
    Value<String>? displayName,
    Value<String>? originServerDomain,
    Value<String>? federatedId,
    Value<String?>? email,
    Value<DateTime>? createdAt,
  }) {
    return SignedInReaderCompanion(
      onlyRow: onlyRow ?? this.onlyRow,
      id: id ?? this.id,
      localName: localName ?? this.localName,
      displayName: displayName ?? this.displayName,
      originServerDomain: originServerDomain ?? this.originServerDomain,
      federatedId: federatedId ?? this.federatedId,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (onlyRow.present) {
      map['only_row'] = Variable<int>(onlyRow.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localName.present) {
      map['local_name'] = Variable<String>(localName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (originServerDomain.present) {
      map['origin_server_domain'] = Variable<String>(originServerDomain.value);
    }
    if (federatedId.present) {
      map['federated_id'] = Variable<String>(federatedId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SignedInReaderTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignedInReaderCompanion(')
          ..write('onlyRow: $onlyRow, ')
          ..write('id: $id, ')
          ..write('localName: $localName, ')
          ..write('displayName: $displayName, ')
          ..write('originServerDomain: $originServerDomain, ')
          ..write('federatedId: $federatedId, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ClockFloorTable extends ClockFloor
    with TableInfo<$ClockFloorTable, ClockFloorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClockFloorTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _onlyRowMeta = const VerificationMeta(
    'onlyRow',
  );
  @override
  late final GeneratedColumn<int> onlyRow = GeneratedColumn<int>(
    'only_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> observedAt =
      GeneratedColumn<int>(
        'observed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ClockFloorTable.$converterobservedAt);
  @override
  List<GeneratedColumn> get $columns => [onlyRow, observedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clock_floor';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClockFloorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('only_row')) {
      context.handle(
        _onlyRowMeta,
        onlyRow.isAcceptableOrUnknown(data['only_row']!, _onlyRowMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {onlyRow};
  @override
  ClockFloorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClockFloorRow(
      onlyRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}only_row'],
      )!,
      observedAt: $ClockFloorTable.$converterobservedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}observed_at'],
        )!,
      ),
    );
  }

  @override
  $ClockFloorTable createAlias(String alias) {
    return $ClockFloorTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterobservedAt =
      const InstantConverter();
}

class ClockFloorRow extends DataClass implements Insertable<ClockFloorRow> {
  /// The single row. See [singleRow].
  final int onlyRow;

  /// The greatest instant this device has stamped or seen.
  final DateTime observedAt;
  const ClockFloorRow({required this.onlyRow, required this.observedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['only_row'] = Variable<int>(onlyRow);
    {
      map['observed_at'] = Variable<int>(
        $ClockFloorTable.$converterobservedAt.toSql(observedAt),
      );
    }
    return map;
  }

  ClockFloorCompanion toCompanion(bool nullToAbsent) {
    return ClockFloorCompanion(
      onlyRow: Value(onlyRow),
      observedAt: Value(observedAt),
    );
  }

  factory ClockFloorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClockFloorRow(
      onlyRow: serializer.fromJson<int>(json['onlyRow']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'onlyRow': serializer.toJson<int>(onlyRow),
      'observedAt': serializer.toJson<DateTime>(observedAt),
    };
  }

  ClockFloorRow copyWith({int? onlyRow, DateTime? observedAt}) => ClockFloorRow(
    onlyRow: onlyRow ?? this.onlyRow,
    observedAt: observedAt ?? this.observedAt,
  );
  ClockFloorRow copyWithCompanion(ClockFloorCompanion data) {
    return ClockFloorRow(
      onlyRow: data.onlyRow.present ? data.onlyRow.value : this.onlyRow,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClockFloorRow(')
          ..write('onlyRow: $onlyRow, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(onlyRow, observedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClockFloorRow &&
          other.onlyRow == this.onlyRow &&
          other.observedAt == this.observedAt);
}

class ClockFloorCompanion extends UpdateCompanion<ClockFloorRow> {
  final Value<int> onlyRow;
  final Value<DateTime> observedAt;
  const ClockFloorCompanion({
    this.onlyRow = const Value.absent(),
    this.observedAt = const Value.absent(),
  });
  ClockFloorCompanion.insert({
    this.onlyRow = const Value.absent(),
    required DateTime observedAt,
  }) : observedAt = Value(observedAt);
  static Insertable<ClockFloorRow> custom({
    Expression<int>? onlyRow,
    Expression<int>? observedAt,
  }) {
    return RawValuesInsertable({
      if (onlyRow != null) 'only_row': onlyRow,
      if (observedAt != null) 'observed_at': observedAt,
    });
  }

  ClockFloorCompanion copyWith({
    Value<int>? onlyRow,
    Value<DateTime>? observedAt,
  }) {
    return ClockFloorCompanion(
      onlyRow: onlyRow ?? this.onlyRow,
      observedAt: observedAt ?? this.observedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (onlyRow.present) {
      map['only_row'] = Variable<int>(onlyRow.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<int>(
        $ClockFloorTable.$converterobservedAt.toSql(observedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClockFloorCompanion(')
          ..write('onlyRow: $onlyRow, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }
}

class $EbooksTable extends Ebooks with TableInfo<$EbooksTable, EbookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EbooksTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>($EbooksTable.$convertervectorClock);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($EbooksTable.$converterupdatedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraMetadataMeta = const VerificationMeta(
    'extraMetadata',
  );
  @override
  late final GeneratedColumn<String> extraMetadata = GeneratedColumn<String>(
    'extra_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> importedAt =
      GeneratedColumn<int>(
        'imported_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($EbooksTable.$converterimportedAt);
  @override
  List<GeneratedColumn> get $columns => [
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    title,
    author,
    publisher,
    language,
    format,
    contentHash,
    sizeBytes,
    extraMetadata,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ebooks';
  @override
  VerificationContext validateIntegrity(
    Insertable<EbookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('extra_metadata')) {
      context.handle(
        _extraMetadataMeta,
        extraMetadata.isAcceptableOrUnknown(
          data['extra_metadata']!,
          _extraMetadataMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EbookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EbookRow(
      vectorClock: $EbooksTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
      updatedAt: $EbooksTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      extraMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_metadata'],
      ),
      importedAt: $EbooksTable.$converterimportedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}imported_at'],
        )!,
      ),
    );
  }

  @override
  $EbooksTable createAlias(String alias) {
    return $EbooksTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $converterimportedAt =
      const InstantConverter();
}

class EbookRow extends DataClass implements Insertable<EbookRow> {
  /// The causal version of the record, as the JSON object the node stores in
  /// `jsonb`. The reconciler consults it first and consults nothing else unless
  /// it reports two versions concurrent.
  final VectorClock vectorClock;

  /// The first half of the tie-break, on the hybrid clock C01 describes. It is
  /// not a wall clock reading, and nothing renders it to a reader.
  final DateTime updatedAt;

  /// The second half: the device whose write the record currently reflects,
  /// never the one that created it (C10).
  final String deviceId;

  /// The tombstone. A record removed outright is resurrected by the next
  /// replica that had not yet heard about the deletion, so deletion is a write
  /// like any other and reconciles like one.
  final bool deleted;

  /// The identifier the device that imported the work minted, and the one
  /// every annotation and every reading position references. It travels: a
  /// work is created once, and no replica ever mints another for it.
  final String id;

  /// What the work is called.
  final String title;

  /// Absent rather than empty when the file did not say. A work whose author is
  /// unknown and one whose author is the empty string are different claims, and
  /// the contract spells the difference with `optional`.
  final String? author;

  /// Absent rather than empty, as [author] is.
  final String? publisher;

  /// Absent rather than empty, as [author] is.
  final String? language;

  /// One of [ebookFormats].
  final String format;

  /// The digest of the file, lowercase hex sha-256.
  ///
  /// It is what identifies the bytes across the whole federation — the same
  /// work imported by two devices converges on one stored object — and it is
  /// deliberately not a reference to anything this device holds. A device that
  /// has the row and not the file is the ordinary state of a book that has not
  /// been downloaded yet.
  final String contentHash;

  /// The length of the file, absent until something has seen it.
  final int? sizeBytes;

  /// The metadata a format carries and the contract does not name — series,
  /// ISBN, subjects (RF05).
  ///
  /// It is an object and never a scalar, which the check below enforces as the
  /// node's `jsonb` constraint does. It is stored as the text the delta carried
  /// rather than decoded, because per-field reconciliation replaces this field
  /// whole and nothing here reads inside it.
  final String? extraMetadata;

  /// When the work entered the collection. A wall clock instant the reader is
  /// shown, and not the hybrid one the merge orders by.
  final DateTime importedAt;
  const EbookRow({
    required this.vectorClock,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.id,
    required this.title,
    this.author,
    this.publisher,
    this.language,
    required this.format,
    required this.contentHash,
    this.sizeBytes,
    this.extraMetadata,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['vector_clock'] = Variable<String>(
        $EbooksTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $EbooksTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    map['format'] = Variable<String>(format);
    map['content_hash'] = Variable<String>(contentHash);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || extraMetadata != null) {
      map['extra_metadata'] = Variable<String>(extraMetadata);
    }
    {
      map['imported_at'] = Variable<int>(
        $EbooksTable.$converterimportedAt.toSql(importedAt),
      );
    }
    return map;
  }

  EbooksCompanion toCompanion(bool nullToAbsent) {
    return EbooksCompanion(
      vectorClock: Value(vectorClock),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      id: Value(id),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      format: Value(format),
      contentHash: Value(contentHash),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      extraMetadata: extraMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(extraMetadata),
      importedAt: Value(importedAt),
    );
  }

  factory EbookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EbookRow(
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      language: serializer.fromJson<String?>(json['language']),
      format: serializer.fromJson<String>(json['format']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      extraMetadata: serializer.fromJson<String?>(json['extraMetadata']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'publisher': serializer.toJson<String?>(publisher),
      'language': serializer.toJson<String?>(language),
      'format': serializer.toJson<String>(format),
      'contentHash': serializer.toJson<String>(contentHash),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'extraMetadata': serializer.toJson<String?>(extraMetadata),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  EbookRow copyWith({
    VectorClock? vectorClock,
    DateTime? updatedAt,
    String? deviceId,
    bool? deleted,
    String? id,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    Value<String?> language = const Value.absent(),
    String? format,
    String? contentHash,
    Value<int?> sizeBytes = const Value.absent(),
    Value<String?> extraMetadata = const Value.absent(),
    DateTime? importedAt,
  }) => EbookRow(
    vectorClock: vectorClock ?? this.vectorClock,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    publisher: publisher.present ? publisher.value : this.publisher,
    language: language.present ? language.value : this.language,
    format: format ?? this.format,
    contentHash: contentHash ?? this.contentHash,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    extraMetadata: extraMetadata.present
        ? extraMetadata.value
        : this.extraMetadata,
    importedAt: importedAt ?? this.importedAt,
  );
  EbookRow copyWithCompanion(EbooksCompanion data) {
    return EbookRow(
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      language: data.language.present ? data.language.value : this.language,
      format: data.format.present ? data.format.value : this.format,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      extraMetadata: data.extraMetadata.present
          ? data.extraMetadata.value
          : this.extraMetadata,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EbookRow(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('language: $language, ')
          ..write('format: $format, ')
          ..write('contentHash: $contentHash, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('extraMetadata: $extraMetadata, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    title,
    author,
    publisher,
    language,
    format,
    contentHash,
    sizeBytes,
    extraMetadata,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EbookRow &&
          other.vectorClock == this.vectorClock &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.publisher == this.publisher &&
          other.language == this.language &&
          other.format == this.format &&
          other.contentHash == this.contentHash &&
          other.sizeBytes == this.sizeBytes &&
          other.extraMetadata == this.extraMetadata &&
          other.importedAt == this.importedAt);
}

class EbooksCompanion extends UpdateCompanion<EbookRow> {
  final Value<VectorClock> vectorClock;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> publisher;
  final Value<String?> language;
  final Value<String> format;
  final Value<String> contentHash;
  final Value<int?> sizeBytes;
  final Value<String?> extraMetadata;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const EbooksCompanion({
    this.vectorClock = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.language = const Value.absent(),
    this.format = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.extraMetadata = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EbooksCompanion.insert({
    required VectorClock vectorClock,
    required DateTime updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String id,
    required String title,
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.language = const Value.absent(),
    required String format,
    required String contentHash,
    this.sizeBytes = const Value.absent(),
    this.extraMetadata = const Value.absent(),
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : vectorClock = Value(vectorClock),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       id = Value(id),
       title = Value(title),
       format = Value(format),
       contentHash = Value(contentHash),
       importedAt = Value(importedAt);
  static Insertable<EbookRow> custom({
    Expression<String>? vectorClock,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? publisher,
    Expression<String>? language,
    Expression<String>? format,
    Expression<String>? contentHash,
    Expression<int>? sizeBytes,
    Expression<String>? extraMetadata,
    Expression<int>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (publisher != null) 'publisher': publisher,
      if (language != null) 'language': language,
      if (format != null) 'format': format,
      if (contentHash != null) 'content_hash': contentHash,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (extraMetadata != null) 'extra_metadata': extraMetadata,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EbooksCompanion copyWith({
    Value<VectorClock>? vectorClock,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? publisher,
    Value<String?>? language,
    Value<String>? format,
    Value<String>? contentHash,
    Value<int?>? sizeBytes,
    Value<String?>? extraMetadata,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return EbooksCompanion(
      vectorClock: vectorClock ?? this.vectorClock,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      format: format ?? this.format,
      contentHash: contentHash ?? this.contentHash,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      extraMetadata: extraMetadata ?? this.extraMetadata,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $EbooksTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $EbooksTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (extraMetadata.present) {
      map['extra_metadata'] = Variable<String>(extraMetadata.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(
        $EbooksTable.$converterimportedAt.toSql(importedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EbooksCompanion(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('language: $language, ')
          ..write('format: $format, ')
          ..write('contentHash: $contentHash, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('extraMetadata: $extraMetadata, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, CollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>($CollectionsTable.$convertervectorClock);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CollectionsTable.$converterupdatedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('collection'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CollectionsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    name,
    kind,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionRow(
      vectorClock: $CollectionsTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
      updatedAt: $CollectionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: $CollectionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
}

class CollectionRow extends DataClass implements Insertable<CollectionRow> {
  /// The causal version of the record, as the JSON object the node stores in
  /// `jsonb`. The reconciler consults it first and consults nothing else unless
  /// it reports two versions concurrent.
  final VectorClock vectorClock;

  /// The first half of the tie-break, on the hybrid clock C01 describes. It is
  /// not a wall clock reading, and nothing renders it to a reader.
  final DateTime updatedAt;

  /// The second half: the device whose write the record currently reflects,
  /// never the one that created it (C10).
  final String deviceId;

  /// The tombstone. A record removed outright is resurrected by the next
  /// replica that had not yet heard about the deletion, so deletion is a write
  /// like any other and reconciles like one.
  final bool deleted;

  /// The identifier the device that created the grouping minted.
  final String id;

  /// What the reader called it.
  final String name;

  /// One of [collectionKinds]. A collection is a grouping the reader defined
  /// and a category is a subject they filed under; they are one structure with
  /// two meanings, which is what lets RF05 offer both without a second entity.
  final String kind;

  /// What the reader said it is for, if anything.
  final String? description;

  /// When it was created, on a wall clock.
  final DateTime createdAt;
  const CollectionRow({
    required this.vectorClock,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.id,
    required this.name,
    required this.kind,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['vector_clock'] = Variable<String>(
        $CollectionsTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $CollectionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['created_at'] = Variable<int>(
        $CollectionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      vectorClock: Value(vectorClock),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory CollectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionRow(
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CollectionRow copyWith({
    VectorClock? vectorClock,
    DateTime? updatedAt,
    String? deviceId,
    bool? deleted,
    String? id,
    String? name,
    String? kind,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => CollectionRow(
    vectorClock: vectorClock ?? this.vectorClock,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  CollectionRow copyWithCompanion(CollectionsCompanion data) {
    return CollectionRow(
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionRow(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    name,
    kind,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionRow &&
          other.vectorClock == this.vectorClock &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class CollectionsCompanion extends UpdateCompanion<CollectionRow> {
  final Value<VectorClock> vectorClock;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.vectorClock = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required VectorClock vectorClock,
    required DateTime updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String id,
    required String name,
    this.kind = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : vectorClock = Value(vectorClock),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CollectionRow> custom({
    Expression<String>? vectorClock,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<VectorClock>? vectorClock,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      vectorClock: vectorClock ?? this.vectorClock,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $CollectionsTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CollectionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CollectionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EbookCollectionsTable extends EbookCollections
    with TableInfo<$EbookCollectionsTable, EbookCollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EbookCollectionsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>(
        $EbookCollectionsTable.$convertervectorClock,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($EbookCollectionsTable.$converterupdatedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ebookIdMeta = const VerificationMeta(
    'ebookId',
  );
  @override
  late final GeneratedColumn<String> ebookId = GeneratedColumn<String>(
    'ebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ebooks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collections (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    ebookId,
    collectionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ebook_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<EbookCollectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ebook_id')) {
      context.handle(
        _ebookIdMeta,
        ebookId.isAcceptableOrUnknown(data['ebook_id']!, _ebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ebookIdMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ebookId, collectionId},
  ];
  @override
  EbookCollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EbookCollectionRow(
      vectorClock: $EbookCollectionsTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
      updatedAt: $EbookCollectionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ebook_id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
    );
  }

  @override
  $EbookCollectionsTable createAlias(String alias) {
    return $EbookCollectionsTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
}

class EbookCollectionRow extends DataClass
    implements Insertable<EbookCollectionRow> {
  /// The causal version of the record, as the JSON object the node stores in
  /// `jsonb`. The reconciler consults it first and consults nothing else unless
  /// it reports two versions concurrent.
  final VectorClock vectorClock;

  /// The first half of the tie-break, on the hybrid clock C01 describes. It is
  /// not a wall clock reading, and nothing renders it to a reader.
  final DateTime updatedAt;

  /// The second half: the device whose write the record currently reflects,
  /// never the one that created it (C10).
  final String deviceId;

  /// The tombstone. A record removed outright is resurrected by the next
  /// replica that had not yet heard about the deletion, so deletion is a write
  /// like any other and reconciles like one.
  final bool deleted;

  /// The surrogate identifier this device minted for the pair. It is
  /// provenance, not identity.
  final String id;

  /// The work.
  final String ebookId;

  /// The grouping.
  final String collectionId;
  const EbookCollectionRow({
    required this.vectorClock,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.id,
    required this.ebookId,
    required this.collectionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['vector_clock'] = Variable<String>(
        $EbookCollectionsTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $EbookCollectionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['ebook_id'] = Variable<String>(ebookId);
    map['collection_id'] = Variable<String>(collectionId);
    return map;
  }

  EbookCollectionsCompanion toCompanion(bool nullToAbsent) {
    return EbookCollectionsCompanion(
      vectorClock: Value(vectorClock),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      id: Value(id),
      ebookId: Value(ebookId),
      collectionId: Value(collectionId),
    );
  }

  factory EbookCollectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EbookCollectionRow(
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      ebookId: serializer.fromJson<String>(json['ebookId']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'ebookId': serializer.toJson<String>(ebookId),
      'collectionId': serializer.toJson<String>(collectionId),
    };
  }

  EbookCollectionRow copyWith({
    VectorClock? vectorClock,
    DateTime? updatedAt,
    String? deviceId,
    bool? deleted,
    String? id,
    String? ebookId,
    String? collectionId,
  }) => EbookCollectionRow(
    vectorClock: vectorClock ?? this.vectorClock,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    ebookId: ebookId ?? this.ebookId,
    collectionId: collectionId ?? this.collectionId,
  );
  EbookCollectionRow copyWithCompanion(EbookCollectionsCompanion data) {
    return EbookCollectionRow(
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      ebookId: data.ebookId.present ? data.ebookId.value : this.ebookId,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EbookCollectionRow(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('ebookId: $ebookId, ')
          ..write('collectionId: $collectionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    ebookId,
    collectionId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EbookCollectionRow &&
          other.vectorClock == this.vectorClock &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.ebookId == this.ebookId &&
          other.collectionId == this.collectionId);
}

class EbookCollectionsCompanion extends UpdateCompanion<EbookCollectionRow> {
  final Value<VectorClock> vectorClock;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> ebookId;
  final Value<String> collectionId;
  final Value<int> rowid;
  const EbookCollectionsCompanion({
    this.vectorClock = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.ebookId = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EbookCollectionsCompanion.insert({
    required VectorClock vectorClock,
    required DateTime updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String id,
    required String ebookId,
    required String collectionId,
    this.rowid = const Value.absent(),
  }) : vectorClock = Value(vectorClock),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       id = Value(id),
       ebookId = Value(ebookId),
       collectionId = Value(collectionId);
  static Insertable<EbookCollectionRow> custom({
    Expression<String>? vectorClock,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? ebookId,
    Expression<String>? collectionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (ebookId != null) 'ebook_id': ebookId,
      if (collectionId != null) 'collection_id': collectionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EbookCollectionsCompanion copyWith({
    Value<VectorClock>? vectorClock,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? ebookId,
    Value<String>? collectionId,
    Value<int>? rowid,
  }) {
    return EbookCollectionsCompanion(
      vectorClock: vectorClock ?? this.vectorClock,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      ebookId: ebookId ?? this.ebookId,
      collectionId: collectionId ?? this.collectionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $EbookCollectionsTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $EbookCollectionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ebookId.present) {
      map['ebook_id'] = Variable<String>(ebookId.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EbookCollectionsCompanion(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('ebookId: $ebookId, ')
          ..write('collectionId: $collectionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EbookCoversTable extends EbookCovers
    with TableInfo<$EbookCoversTable, EbookCoverRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EbookCoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ebookIdMeta = const VerificationMeta(
    'ebookId',
  );
  @override
  late final GeneratedColumn<String> ebookId = GeneratedColumn<String>(
    'ebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ebooks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ebookId, mediaType, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ebook_covers';
  @override
  VerificationContext validateIntegrity(
    Insertable<EbookCoverRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ebook_id')) {
      context.handle(
        _ebookIdMeta,
        ebookId.isAcceptableOrUnknown(data['ebook_id']!, _ebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ebookIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ebookId};
  @override
  EbookCoverRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EbookCoverRow(
      ebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ebook_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $EbookCoversTable createAlias(String alias) {
    return $EbookCoversTable(attachedDatabase, alias);
  }
}

class EbookCoverRow extends DataClass implements Insertable<EbookCoverRow> {
  /// The work it belongs to.
  ///
  /// It is the primary key, so a work has one cover: the file carried one
  /// picture and there is nothing to choose between. The cascade is what makes
  /// the row disappear with the work rather than outliving it.
  final String ebookId;

  /// What the manifest said the image is.
  final String mediaType;

  /// The image.
  final Uint8List bytes;
  const EbookCoverRow({
    required this.ebookId,
    required this.mediaType,
    required this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ebook_id'] = Variable<String>(ebookId);
    map['media_type'] = Variable<String>(mediaType);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  EbookCoversCompanion toCompanion(bool nullToAbsent) {
    return EbookCoversCompanion(
      ebookId: Value(ebookId),
      mediaType: Value(mediaType),
      bytes: Value(bytes),
    );
  }

  factory EbookCoverRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EbookCoverRow(
      ebookId: serializer.fromJson<String>(json['ebookId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ebookId': serializer.toJson<String>(ebookId),
      'mediaType': serializer.toJson<String>(mediaType),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  EbookCoverRow copyWith({
    String? ebookId,
    String? mediaType,
    Uint8List? bytes,
  }) => EbookCoverRow(
    ebookId: ebookId ?? this.ebookId,
    mediaType: mediaType ?? this.mediaType,
    bytes: bytes ?? this.bytes,
  );
  EbookCoverRow copyWithCompanion(EbookCoversCompanion data) {
    return EbookCoverRow(
      ebookId: data.ebookId.present ? data.ebookId.value : this.ebookId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EbookCoverRow(')
          ..write('ebookId: $ebookId, ')
          ..write('mediaType: $mediaType, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ebookId, mediaType, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EbookCoverRow &&
          other.ebookId == this.ebookId &&
          other.mediaType == this.mediaType &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class EbookCoversCompanion extends UpdateCompanion<EbookCoverRow> {
  final Value<String> ebookId;
  final Value<String> mediaType;
  final Value<Uint8List> bytes;
  final Value<int> rowid;
  const EbookCoversCompanion({
    this.ebookId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EbookCoversCompanion.insert({
    required String ebookId,
    required String mediaType,
    required Uint8List bytes,
    this.rowid = const Value.absent(),
  }) : ebookId = Value(ebookId),
       mediaType = Value(mediaType),
       bytes = Value(bytes);
  static Insertable<EbookCoverRow> custom({
    Expression<String>? ebookId,
    Expression<String>? mediaType,
    Expression<Uint8List>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ebookId != null) 'ebook_id': ebookId,
      if (mediaType != null) 'media_type': mediaType,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EbookCoversCompanion copyWith({
    Value<String>? ebookId,
    Value<String>? mediaType,
    Value<Uint8List>? bytes,
    Value<int>? rowid,
  }) {
    return EbookCoversCompanion(
      ebookId: ebookId ?? this.ebookId,
      mediaType: mediaType ?? this.mediaType,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ebookId.present) {
      map['ebook_id'] = Variable<String>(ebookId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EbookCoversCompanion(')
          ..write('ebookId: $ebookId, ')
          ..write('mediaType: $mediaType, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, AnnotationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>($AnnotationsTable.$convertervectorClock);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AnnotationsTable.$converterupdatedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ebookIdMeta = const VerificationMeta(
    'ebookId',
  );
  @override
  late final GeneratedColumn<String> ebookId = GeneratedColumn<String>(
    'ebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ebooks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locatorMeta = const VerificationMeta(
    'locator',
  );
  @override
  late final GeneratedColumn<String> locator = GeneratedColumn<String>(
    'locator',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    ebookId,
    kind,
    content,
    locator,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ebook_id')) {
      context.handle(
        _ebookIdMeta,
        ebookId.isAcceptableOrUnknown(data['ebook_id']!, _ebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ebookIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    }
    if (data.containsKey('locator')) {
      context.handle(
        _locatorMeta,
        locator.isAcceptableOrUnknown(data['locator']!, _locatorMeta),
      );
    } else if (isInserting) {
      context.missing(_locatorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationRow(
      vectorClock: $AnnotationsTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
      updatedAt: $AnnotationsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ebook_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      locator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locator'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
}

class AnnotationRow extends DataClass implements Insertable<AnnotationRow> {
  /// The causal version of the record, as the JSON object the node stores in
  /// `jsonb`. The reconciler consults it first and consults nothing else unless
  /// it reports two versions concurrent.
  final VectorClock vectorClock;

  /// The first half of the tie-break, on the hybrid clock C01 describes. It is
  /// not a wall clock reading, and nothing renders it to a reader.
  final DateTime updatedAt;

  /// The second half: the device whose write the record currently reflects,
  /// never the one that created it (C10).
  final String deviceId;

  /// The tombstone. A record removed outright is resurrected by the next
  /// replica that had not yet heard about the deletion, so deletion is a write
  /// like any other and reconciles like one.
  final bool deleted;

  /// The identifier the device that made the mark minted.
  final String id;

  /// The work the mark is in.
  ///
  /// A mark is made in a work and stays in it: it is not among the fields an
  /// update may write, because a note that moved between books would be a note
  /// about a passage that is not there.
  final String ebookId;

  /// One of [annotationKinds].
  final String kind;

  /// Required for a note, which is otherwise an empty note; optional on the
  /// other two.
  ///
  /// The column is named `text` because that is what the contract, the delta
  /// and the node's own column call it. The getter cannot be: it would shadow
  /// the column builder it is declared with.
  final String? content;

  /// The passage, expressed so that it survives the format: a CFI in an EPUB, a
  /// page in a PDF.
  ///
  /// It is the one value in this schema that is authored by a renderer rather
  /// than by the app, and it is replicated to the reader's other devices, which
  /// is the whole reason phase 9 insists on one CFI implementation across the
  /// six targets. Two of them would disagree here, and the disagreement would
  /// arrive as a highlight on the wrong paragraph.
  final String locator;
  const AnnotationRow({
    required this.vectorClock,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.id,
    required this.ebookId,
    required this.kind,
    this.content,
    required this.locator,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['vector_clock'] = Variable<String>(
        $AnnotationsTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $AnnotationsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['ebook_id'] = Variable<String>(ebookId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || content != null) {
      map['text'] = Variable<String>(content);
    }
    map['locator'] = Variable<String>(locator);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      vectorClock: Value(vectorClock),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      id: Value(id),
      ebookId: Value(ebookId),
      kind: Value(kind),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      locator: Value(locator),
    );
  }

  factory AnnotationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationRow(
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      ebookId: serializer.fromJson<String>(json['ebookId']),
      kind: serializer.fromJson<String>(json['kind']),
      content: serializer.fromJson<String?>(json['content']),
      locator: serializer.fromJson<String>(json['locator']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'ebookId': serializer.toJson<String>(ebookId),
      'kind': serializer.toJson<String>(kind),
      'content': serializer.toJson<String?>(content),
      'locator': serializer.toJson<String>(locator),
    };
  }

  AnnotationRow copyWith({
    VectorClock? vectorClock,
    DateTime? updatedAt,
    String? deviceId,
    bool? deleted,
    String? id,
    String? ebookId,
    String? kind,
    Value<String?> content = const Value.absent(),
    String? locator,
  }) => AnnotationRow(
    vectorClock: vectorClock ?? this.vectorClock,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    ebookId: ebookId ?? this.ebookId,
    kind: kind ?? this.kind,
    content: content.present ? content.value : this.content,
    locator: locator ?? this.locator,
  );
  AnnotationRow copyWithCompanion(AnnotationsCompanion data) {
    return AnnotationRow(
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      ebookId: data.ebookId.present ? data.ebookId.value : this.ebookId,
      kind: data.kind.present ? data.kind.value : this.kind,
      content: data.content.present ? data.content.value : this.content,
      locator: data.locator.present ? data.locator.value : this.locator,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationRow(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('ebookId: $ebookId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('locator: $locator')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vectorClock,
    updatedAt,
    deviceId,
    deleted,
    id,
    ebookId,
    kind,
    content,
    locator,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationRow &&
          other.vectorClock == this.vectorClock &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.ebookId == this.ebookId &&
          other.kind == this.kind &&
          other.content == this.content &&
          other.locator == this.locator);
}

class AnnotationsCompanion extends UpdateCompanion<AnnotationRow> {
  final Value<VectorClock> vectorClock;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> ebookId;
  final Value<String> kind;
  final Value<String?> content;
  final Value<String> locator;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.vectorClock = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.ebookId = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.locator = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    required VectorClock vectorClock,
    required DateTime updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String id,
    required String ebookId,
    required String kind,
    this.content = const Value.absent(),
    required String locator,
    this.rowid = const Value.absent(),
  }) : vectorClock = Value(vectorClock),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       id = Value(id),
       ebookId = Value(ebookId),
       kind = Value(kind),
       locator = Value(locator);
  static Insertable<AnnotationRow> custom({
    Expression<String>? vectorClock,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? ebookId,
    Expression<String>? kind,
    Expression<String>? content,
    Expression<String>? locator,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (ebookId != null) 'ebook_id': ebookId,
      if (kind != null) 'kind': kind,
      if (content != null) 'text': content,
      if (locator != null) 'locator': locator,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith({
    Value<VectorClock>? vectorClock,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? ebookId,
    Value<String>? kind,
    Value<String?>? content,
    Value<String>? locator,
    Value<int>? rowid,
  }) {
    return AnnotationsCompanion(
      vectorClock: vectorClock ?? this.vectorClock,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      ebookId: ebookId ?? this.ebookId,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      locator: locator ?? this.locator,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $AnnotationsTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AnnotationsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ebookId.present) {
      map['ebook_id'] = Variable<String>(ebookId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (locator.present) {
      map['locator'] = Variable<String>(locator.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('ebookId: $ebookId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('locator: $locator, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressTable extends Progress
    with TableInfo<$ProgressTable, ProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ebookIdMeta = const VerificationMeta(
    'ebookId',
  );
  @override
  late final GeneratedColumn<String> ebookId = GeneratedColumn<String>(
    'ebook_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ebooks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locatorMeta = const VerificationMeta(
    'locator',
  );
  @override
  late final GeneratedColumn<String> locator = GeneratedColumn<String>(
    'locator',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<double> percent = GeneratedColumn<double>(
    'percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>($ProgressTable.$convertervectorClock);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ProgressTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ebookId,
    deviceId,
    locator,
    percent,
    vectorClock,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ebook_id')) {
      context.handle(
        _ebookIdMeta,
        ebookId.isAcceptableOrUnknown(data['ebook_id']!, _ebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ebookIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('locator')) {
      context.handle(
        _locatorMeta,
        locator.isAcceptableOrUnknown(data['locator']!, _locatorMeta),
      );
    } else if (isInserting) {
      context.missing(_locatorMeta);
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ebookId, deviceId},
  ];
  @override
  ProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ebook_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      locator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locator'],
      )!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percent'],
      ),
      vectorClock: $ProgressTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
      updatedAt: $ProgressTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ProgressTable createAlias(String alias) {
    return $ProgressTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const InstantConverter();
}

class ProgressRow extends DataClass implements Insertable<ProgressRow> {
  /// The surrogate identifier this device minted for the pair below.
  ///
  /// It is provenance and not identity, exactly as a filing's is (C18): the
  /// record is addressed across the federation by `(ebook_id, device_id)`, and
  /// a device that forgot the identifier it minted would mint another on every
  /// write.
  final String id;

  /// The work the position is in.
  final String ebookId;

  /// The device the position belongs to, and half of the row's natural key.
  ///
  /// It is not a tie-break. Nothing here ever ties, and the column is not the
  /// `device_id` [RevisionColumns] carries even though it is spelled the same:
  /// that one is whichever device wrote last, and this one is whose position
  /// this is.
  final String deviceId;

  /// Where the reader stopped, in the same format-independent form an
  /// annotation's passage uses.
  final String locator;

  /// How far through, 0 to 100.
  ///
  /// Derived from the locator and stored anyway, so that a device which cannot
  /// open a format can still report that the reader is forty percent through
  /// it. It is absent where nothing could compute it.
  final double? percent;

  /// The causal version. Because the row has one writer it always has exactly
  /// one entry, and it grows by one on every write.
  final VectorClock vectorClock;

  /// When the position was written, on the hybrid clock.
  final DateTime updatedAt;
  const ProgressRow({
    required this.id,
    required this.ebookId,
    required this.deviceId,
    required this.locator,
    this.percent,
    required this.vectorClock,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ebook_id'] = Variable<String>(ebookId);
    map['device_id'] = Variable<String>(deviceId);
    map['locator'] = Variable<String>(locator);
    if (!nullToAbsent || percent != null) {
      map['percent'] = Variable<double>(percent);
    }
    {
      map['vector_clock'] = Variable<String>(
        $ProgressTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $ProgressTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ProgressCompanion toCompanion(bool nullToAbsent) {
    return ProgressCompanion(
      id: Value(id),
      ebookId: Value(ebookId),
      deviceId: Value(deviceId),
      locator: Value(locator),
      percent: percent == null && nullToAbsent
          ? const Value.absent()
          : Value(percent),
      vectorClock: Value(vectorClock),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressRow(
      id: serializer.fromJson<String>(json['id']),
      ebookId: serializer.fromJson<String>(json['ebookId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      locator: serializer.fromJson<String>(json['locator']),
      percent: serializer.fromJson<double?>(json['percent']),
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ebookId': serializer.toJson<String>(ebookId),
      'deviceId': serializer.toJson<String>(deviceId),
      'locator': serializer.toJson<String>(locator),
      'percent': serializer.toJson<double?>(percent),
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProgressRow copyWith({
    String? id,
    String? ebookId,
    String? deviceId,
    String? locator,
    Value<double?> percent = const Value.absent(),
    VectorClock? vectorClock,
    DateTime? updatedAt,
  }) => ProgressRow(
    id: id ?? this.id,
    ebookId: ebookId ?? this.ebookId,
    deviceId: deviceId ?? this.deviceId,
    locator: locator ?? this.locator,
    percent: percent.present ? percent.value : this.percent,
    vectorClock: vectorClock ?? this.vectorClock,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProgressRow copyWithCompanion(ProgressCompanion data) {
    return ProgressRow(
      id: data.id.present ? data.id.value : this.id,
      ebookId: data.ebookId.present ? data.ebookId.value : this.ebookId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      locator: data.locator.present ? data.locator.value : this.locator,
      percent: data.percent.present ? data.percent.value : this.percent,
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRow(')
          ..write('id: $id, ')
          ..write('ebookId: $ebookId, ')
          ..write('deviceId: $deviceId, ')
          ..write('locator: $locator, ')
          ..write('percent: $percent, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ebookId,
    deviceId,
    locator,
    percent,
    vectorClock,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressRow &&
          other.id == this.id &&
          other.ebookId == this.ebookId &&
          other.deviceId == this.deviceId &&
          other.locator == this.locator &&
          other.percent == this.percent &&
          other.vectorClock == this.vectorClock &&
          other.updatedAt == this.updatedAt);
}

class ProgressCompanion extends UpdateCompanion<ProgressRow> {
  final Value<String> id;
  final Value<String> ebookId;
  final Value<String> deviceId;
  final Value<String> locator;
  final Value<double?> percent;
  final Value<VectorClock> vectorClock;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProgressCompanion({
    this.id = const Value.absent(),
    this.ebookId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.locator = const Value.absent(),
    this.percent = const Value.absent(),
    this.vectorClock = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressCompanion.insert({
    required String id,
    required String ebookId,
    required String deviceId,
    required String locator,
    this.percent = const Value.absent(),
    required VectorClock vectorClock,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ebookId = Value(ebookId),
       deviceId = Value(deviceId),
       locator = Value(locator),
       vectorClock = Value(vectorClock),
       updatedAt = Value(updatedAt);
  static Insertable<ProgressRow> custom({
    Expression<String>? id,
    Expression<String>? ebookId,
    Expression<String>? deviceId,
    Expression<String>? locator,
    Expression<double>? percent,
    Expression<String>? vectorClock,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ebookId != null) 'ebook_id': ebookId,
      if (deviceId != null) 'device_id': deviceId,
      if (locator != null) 'locator': locator,
      if (percent != null) 'percent': percent,
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressCompanion copyWith({
    Value<String>? id,
    Value<String>? ebookId,
    Value<String>? deviceId,
    Value<String>? locator,
    Value<double?>? percent,
    Value<VectorClock>? vectorClock,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProgressCompanion(
      id: id ?? this.id,
      ebookId: ebookId ?? this.ebookId,
      deviceId: deviceId ?? this.deviceId,
      locator: locator ?? this.locator,
      percent: percent ?? this.percent,
      vectorClock: vectorClock ?? this.vectorClock,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ebookId.present) {
      map['ebook_id'] = Variable<String>(ebookId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (locator.present) {
      map['locator'] = Variable<String>(locator.value);
    }
    if (percent.present) {
      map['percent'] = Variable<double>(percent.value);
    }
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $ProgressTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ProgressTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressCompanion(')
          ..write('id: $id, ')
          ..write('ebookId: $ebookId, ')
          ..write('deviceId: $deviceId, ')
          ..write('locator: $locator, ')
          ..write('percent: $percent, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetEntityMeta = const VerificationMeta(
    'targetEntity',
  );
  @override
  late final GeneratedColumn<String> targetEntity = GeneratedColumn<String>(
    'target_entity',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<String> delta = GeneratedColumn<String>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>(
        $PendingOperationsTable.$convertervectorClock,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PendingOperationsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    id,
    deviceId,
    targetEntity,
    targetId,
    operation,
    delta,
    vectorClock,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('target_entity')) {
      context.handle(
        _targetEntityMeta,
        targetEntity.isAcceptableOrUnknown(
          data['target_entity']!,
          _targetEntityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetEntityMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  PendingOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperationRow(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      targetEntity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_entity'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delta'],
      )!,
      vectorClock: $PendingOperationsTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
      createdAt: $PendingOperationsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const InstantConverter();
}

class PendingOperationRow extends DataClass
    implements Insertable<PendingOperationRow> {
  /// This device's authoring order. It is the rowid, so it is assigned by
  /// sqlite and never reused while the log has an entry above it.
  final int sequence;

  /// The identifier this device minted for the change, which every replica
  /// recognizes it by.
  final String id;

  /// The device that authored it, which is this one. It is stored rather than
  /// inferred because an operation carries its author across the wire, and
  /// because a migration to another node pushes what was authored *here* under
  /// the identity it was authored with.
  final String deviceId;

  /// Which kind of record changed.
  final String targetEntity;

  /// The record the change names.
  final String targetId;

  /// What the change did.
  final String operation;

  /// The changed fields and nothing else, as the JSON object the contract
  /// carries in `Operation.delta`.
  ///
  /// It is stored as text rather than decoded because nothing between here and
  /// the wire reads inside it: the push renders it and the reconciler on the
  /// other side decodes it. A field named as JSON null is a field the change
  /// cleared, so the nulls have to survive being stored, which they do here and
  /// would not in a map that dropped them.
  final String delta;

  /// The causal version the change was authored at.
  final VectorClock vectorClock;

  /// When it was stamped, on the hybrid clock.
  final DateTime createdAt;
  const PendingOperationRow({
    required this.sequence,
    required this.id,
    required this.deviceId,
    required this.targetEntity,
    required this.targetId,
    required this.operation,
    required this.delta,
    required this.vectorClock,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['id'] = Variable<String>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['target_entity'] = Variable<String>(targetEntity);
    map['target_id'] = Variable<String>(targetId);
    map['operation'] = Variable<String>(operation);
    map['delta'] = Variable<String>(delta);
    {
      map['vector_clock'] = Variable<String>(
        $PendingOperationsTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $PendingOperationsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      sequence: Value(sequence),
      id: Value(id),
      deviceId: Value(deviceId),
      targetEntity: Value(targetEntity),
      targetId: Value(targetId),
      operation: Value(operation),
      delta: Value(delta),
      vectorClock: Value(vectorClock),
      createdAt: Value(createdAt),
    );
  }

  factory PendingOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperationRow(
      sequence: serializer.fromJson<int>(json['sequence']),
      id: serializer.fromJson<String>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      targetEntity: serializer.fromJson<String>(json['targetEntity']),
      targetId: serializer.fromJson<String>(json['targetId']),
      operation: serializer.fromJson<String>(json['operation']),
      delta: serializer.fromJson<String>(json['delta']),
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'id': serializer.toJson<String>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'targetEntity': serializer.toJson<String>(targetEntity),
      'targetId': serializer.toJson<String>(targetId),
      'operation': serializer.toJson<String>(operation),
      'delta': serializer.toJson<String>(delta),
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingOperationRow copyWith({
    int? sequence,
    String? id,
    String? deviceId,
    String? targetEntity,
    String? targetId,
    String? operation,
    String? delta,
    VectorClock? vectorClock,
    DateTime? createdAt,
  }) => PendingOperationRow(
    sequence: sequence ?? this.sequence,
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    targetEntity: targetEntity ?? this.targetEntity,
    targetId: targetId ?? this.targetId,
    operation: operation ?? this.operation,
    delta: delta ?? this.delta,
    vectorClock: vectorClock ?? this.vectorClock,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingOperationRow copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperationRow(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      targetEntity: data.targetEntity.present
          ? data.targetEntity.value
          : this.targetEntity,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      operation: data.operation.present ? data.operation.value : this.operation,
      delta: data.delta.present ? data.delta.value : this.delta,
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationRow(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('targetEntity: $targetEntity, ')
          ..write('targetId: $targetId, ')
          ..write('operation: $operation, ')
          ..write('delta: $delta, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sequence,
    id,
    deviceId,
    targetEntity,
    targetId,
    operation,
    delta,
    vectorClock,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperationRow &&
          other.sequence == this.sequence &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.targetEntity == this.targetEntity &&
          other.targetId == this.targetId &&
          other.operation == this.operation &&
          other.delta == this.delta &&
          other.vectorClock == this.vectorClock &&
          other.createdAt == this.createdAt);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperationRow> {
  final Value<int> sequence;
  final Value<String> id;
  final Value<String> deviceId;
  final Value<String> targetEntity;
  final Value<String> targetId;
  final Value<String> operation;
  final Value<String> delta;
  final Value<VectorClock> vectorClock;
  final Value<DateTime> createdAt;
  const PendingOperationsCompanion({
    this.sequence = const Value.absent(),
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.targetEntity = const Value.absent(),
    this.targetId = const Value.absent(),
    this.operation = const Value.absent(),
    this.delta = const Value.absent(),
    this.vectorClock = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.sequence = const Value.absent(),
    required String id,
    required String deviceId,
    required String targetEntity,
    required String targetId,
    required String operation,
    required String delta,
    required VectorClock vectorClock,
    required DateTime createdAt,
  }) : id = Value(id),
       deviceId = Value(deviceId),
       targetEntity = Value(targetEntity),
       targetId = Value(targetId),
       operation = Value(operation),
       delta = Value(delta),
       vectorClock = Value(vectorClock),
       createdAt = Value(createdAt);
  static Insertable<PendingOperationRow> custom({
    Expression<int>? sequence,
    Expression<String>? id,
    Expression<String>? deviceId,
    Expression<String>? targetEntity,
    Expression<String>? targetId,
    Expression<String>? operation,
    Expression<String>? delta,
    Expression<String>? vectorClock,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (targetEntity != null) 'target_entity': targetEntity,
      if (targetId != null) 'target_id': targetId,
      if (operation != null) 'operation': operation,
      if (delta != null) 'delta': delta,
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<int>? sequence,
    Value<String>? id,
    Value<String>? deviceId,
    Value<String>? targetEntity,
    Value<String>? targetId,
    Value<String>? operation,
    Value<String>? delta,
    Value<VectorClock>? vectorClock,
    Value<DateTime>? createdAt,
  }) {
    return PendingOperationsCompanion(
      sequence: sequence ?? this.sequence,
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      targetEntity: targetEntity ?? this.targetEntity,
      targetId: targetId ?? this.targetId,
      operation: operation ?? this.operation,
      delta: delta ?? this.delta,
      vectorClock: vectorClock ?? this.vectorClock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (targetEntity.present) {
      map['target_entity'] = Variable<String>(targetEntity.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (delta.present) {
      map['delta'] = Variable<String>(delta.value);
    }
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $PendingOperationsTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $PendingOperationsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('targetEntity: $targetEntity, ')
          ..write('targetId: $targetId, ')
          ..write('operation: $operation, ')
          ..write('delta: $delta, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NodeCursorsTable extends NodeCursors
    with TableInfo<$NodeCursorsTable, NodeCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverDomainMeta = const VerificationMeta(
    'serverDomain',
  );
  @override
  late final GeneratedColumn<String> serverDomain = GeneratedColumn<String>(
    'server_domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES known_servers (domain) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _lastPositionMeta = const VerificationMeta(
    'lastPosition',
  );
  @override
  late final GeneratedColumn<int> lastPosition = GeneratedColumn<int>(
    'last_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($NodeCursorsTable.$converterpulledAtn);
  @override
  List<GeneratedColumn> get $columns => [serverDomain, lastPosition, pulledAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_domain')) {
      context.handle(
        _serverDomainMeta,
        serverDomain.isAcceptableOrUnknown(
          data['server_domain']!,
          _serverDomainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverDomainMeta);
    }
    if (data.containsKey('last_position')) {
      context.handle(
        _lastPositionMeta,
        lastPosition.isAcceptableOrUnknown(
          data['last_position']!,
          _lastPositionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverDomain};
  @override
  NodeCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeCursorRow(
      serverDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_domain'],
      )!,
      lastPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position'],
      )!,
      pulledAt: $NodeCursorsTable.$converterpulledAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        ),
      ),
    );
  }

  @override
  $NodeCursorsTable createAlias(String alias) {
    return $NodeCursorsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterpulledAt =
      const InstantConverter();
  static TypeConverter<DateTime?, int?> $converterpulledAtn =
      NullAwareTypeConverter.wrap($converterpulledAt);
}

class NodeCursorRow extends DataClass implements Insertable<NodeCursorRow> {
  /// The node this position belongs to, by the domain this device addresses it
  /// at. See [KnownServers.domain] for why that is the key and not the node's
  /// own identifier.
  final String serverDomain;

  /// The last position this device has pulled and committed.
  ///
  /// It is advanced after the batch is written and not after it is received: an
  /// operation read from a socket is not an operation written to disk, and a
  /// device that dies in between must come back to the same place. Zero is a
  /// device that has pulled nothing, which is what a freshly bound one asks
  /// from.
  final int lastPosition;

  /// When the cursor last moved, on a wall clock.
  ///
  /// It is a diagnostic and never a cursor: it is what the sync surface of
  /// phase 11 shows a reader who wants to know whether their notes are only on
  /// this phone.
  final DateTime? pulledAt;
  const NodeCursorRow({
    required this.serverDomain,
    required this.lastPosition,
    this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_domain'] = Variable<String>(serverDomain);
    map['last_position'] = Variable<int>(lastPosition);
    if (!nullToAbsent || pulledAt != null) {
      map['pulled_at'] = Variable<int>(
        $NodeCursorsTable.$converterpulledAtn.toSql(pulledAt),
      );
    }
    return map;
  }

  NodeCursorsCompanion toCompanion(bool nullToAbsent) {
    return NodeCursorsCompanion(
      serverDomain: Value(serverDomain),
      lastPosition: Value(lastPosition),
      pulledAt: pulledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pulledAt),
    );
  }

  factory NodeCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeCursorRow(
      serverDomain: serializer.fromJson<String>(json['serverDomain']),
      lastPosition: serializer.fromJson<int>(json['lastPosition']),
      pulledAt: serializer.fromJson<DateTime?>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverDomain': serializer.toJson<String>(serverDomain),
      'lastPosition': serializer.toJson<int>(lastPosition),
      'pulledAt': serializer.toJson<DateTime?>(pulledAt),
    };
  }

  NodeCursorRow copyWith({
    String? serverDomain,
    int? lastPosition,
    Value<DateTime?> pulledAt = const Value.absent(),
  }) => NodeCursorRow(
    serverDomain: serverDomain ?? this.serverDomain,
    lastPosition: lastPosition ?? this.lastPosition,
    pulledAt: pulledAt.present ? pulledAt.value : this.pulledAt,
  );
  NodeCursorRow copyWithCompanion(NodeCursorsCompanion data) {
    return NodeCursorRow(
      serverDomain: data.serverDomain.present
          ? data.serverDomain.value
          : this.serverDomain,
      lastPosition: data.lastPosition.present
          ? data.lastPosition.value
          : this.lastPosition,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeCursorRow(')
          ..write('serverDomain: $serverDomain, ')
          ..write('lastPosition: $lastPosition, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverDomain, lastPosition, pulledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeCursorRow &&
          other.serverDomain == this.serverDomain &&
          other.lastPosition == this.lastPosition &&
          other.pulledAt == this.pulledAt);
}

class NodeCursorsCompanion extends UpdateCompanion<NodeCursorRow> {
  final Value<String> serverDomain;
  final Value<int> lastPosition;
  final Value<DateTime?> pulledAt;
  final Value<int> rowid;
  const NodeCursorsCompanion({
    this.serverDomain = const Value.absent(),
    this.lastPosition = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeCursorsCompanion.insert({
    required String serverDomain,
    this.lastPosition = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : serverDomain = Value(serverDomain);
  static Insertable<NodeCursorRow> custom({
    Expression<String>? serverDomain,
    Expression<int>? lastPosition,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverDomain != null) 'server_domain': serverDomain,
      if (lastPosition != null) 'last_position': lastPosition,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeCursorsCompanion copyWith({
    Value<String>? serverDomain,
    Value<int>? lastPosition,
    Value<DateTime?>? pulledAt,
    Value<int>? rowid,
  }) {
    return NodeCursorsCompanion(
      serverDomain: serverDomain ?? this.serverDomain,
      lastPosition: lastPosition ?? this.lastPosition,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverDomain.present) {
      map['server_domain'] = Variable<String>(serverDomain.value);
    }
    if (lastPosition.present) {
      map['last_position'] = Variable<int>(lastPosition.value);
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $NodeCursorsTable.$converterpulledAtn.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeCursorsCompanion(')
          ..write('serverDomain: $serverDomain, ')
          ..write('lastPosition: $lastPosition, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppliedOperationsTable extends AppliedOperations
    with TableInfo<$AppliedOperationsTable, AppliedOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppliedOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> appliedAt =
      GeneratedColumn<int>(
        'applied_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AppliedOperationsTable.$converterappliedAt);
  @override
  List<GeneratedColumn> get $columns => [id, appliedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'applied_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppliedOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppliedOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppliedOperationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      appliedAt: $AppliedOperationsTable.$converterappliedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}applied_at'],
        )!,
      ),
    );
  }

  @override
  $AppliedOperationsTable createAlias(String alias) {
    return $AppliedOperationsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterappliedAt =
      const InstantConverter();
}

class AppliedOperationRow extends DataClass
    implements Insertable<AppliedOperationRow> {
  /// The identifier the authoring device minted.
  final String id;

  /// When this device applied it, on a wall clock. It is a diagnostic, and it
  /// is what a later phase would prune by.
  final DateTime appliedAt;
  const AppliedOperationRow({required this.id, required this.appliedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['applied_at'] = Variable<int>(
        $AppliedOperationsTable.$converterappliedAt.toSql(appliedAt),
      );
    }
    return map;
  }

  AppliedOperationsCompanion toCompanion(bool nullToAbsent) {
    return AppliedOperationsCompanion(
      id: Value(id),
      appliedAt: Value(appliedAt),
    );
  }

  factory AppliedOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppliedOperationRow(
      id: serializer.fromJson<String>(json['id']),
      appliedAt: serializer.fromJson<DateTime>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appliedAt': serializer.toJson<DateTime>(appliedAt),
    };
  }

  AppliedOperationRow copyWith({String? id, DateTime? appliedAt}) =>
      AppliedOperationRow(
        id: id ?? this.id,
        appliedAt: appliedAt ?? this.appliedAt,
      );
  AppliedOperationRow copyWithCompanion(AppliedOperationsCompanion data) {
    return AppliedOperationRow(
      id: data.id.present ? data.id.value : this.id,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppliedOperationRow(')
          ..write('id: $id, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppliedOperationRow &&
          other.id == this.id &&
          other.appliedAt == this.appliedAt);
}

class AppliedOperationsCompanion extends UpdateCompanion<AppliedOperationRow> {
  final Value<String> id;
  final Value<DateTime> appliedAt;
  final Value<int> rowid;
  const AppliedOperationsCompanion({
    this.id = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppliedOperationsCompanion.insert({
    required String id,
    required DateTime appliedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       appliedAt = Value(appliedAt);
  static Insertable<AppliedOperationRow> custom({
    Expression<String>? id,
    Expression<int>? appliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppliedOperationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? appliedAt,
    Value<int>? rowid,
  }) {
    return AppliedOperationsCompanion(
      id: id ?? this.id,
      appliedAt: appliedAt ?? this.appliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(
        $AppliedOperationsTable.$converterappliedAt.toSql(appliedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppliedOperationsCompanion(')
          ..write('id: $id, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordVersionsTable extends RecordVersions
    with TableInfo<$RecordVersionsTable, RecordVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityMeta = const VerificationMeta(
    'identity',
  );
  @override
  late final GeneratedColumn<String> identity = GeneratedColumn<String>(
    'identity',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VectorClock, String> vectorClock =
      GeneratedColumn<String>(
        'vector_clock',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VectorClock>($RecordVersionsTable.$convertervectorClock);
  @override
  List<GeneratedColumn> get $columns => [
    entity,
    identity,
    recordId,
    vectorClock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('identity')) {
      context.handle(
        _identityMeta,
        identity.isAcceptableOrUnknown(data['identity']!, _identityMeta),
      );
    } else if (isInserting) {
      context.missing(_identityMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, identity};
  @override
  RecordVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordVersionRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      identity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      vectorClock: $RecordVersionsTable.$convertervectorClock.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vector_clock'],
        )!,
      ),
    );
  }

  @override
  $RecordVersionsTable createAlias(String alias) {
    return $RecordVersionsTable(attachedDatabase, alias);
  }

  static TypeConverter<VectorClock, String> $convertervectorClock =
      const VectorClockConverter();
}

class RecordVersionRow extends DataClass
    implements Insertable<RecordVersionRow> {
  /// Which kind of record.
  final String entity;

  /// What identifies it: its own identifier for three of the five entities, and
  /// the natural key for the two C18 names.
  final String identity;

  /// The identifier this device uses for the row — the record's own where it
  /// has one, and the surrogate this device minted where it does not.
  final String recordId;

  /// The causal version last seen.
  ///
  /// It is merged and never replaced. A device holding a change it has not
  /// pushed knows a version the node does not, and a reply that overwrote this
  /// with the node's would let the next write be stamped underneath a write
  /// this device itself made.
  final VectorClock vectorClock;
  const RecordVersionRow({
    required this.entity,
    required this.identity,
    required this.recordId,
    required this.vectorClock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['identity'] = Variable<String>(identity);
    map['record_id'] = Variable<String>(recordId);
    {
      map['vector_clock'] = Variable<String>(
        $RecordVersionsTable.$convertervectorClock.toSql(vectorClock),
      );
    }
    return map;
  }

  RecordVersionsCompanion toCompanion(bool nullToAbsent) {
    return RecordVersionsCompanion(
      entity: Value(entity),
      identity: Value(identity),
      recordId: Value(recordId),
      vectorClock: Value(vectorClock),
    );
  }

  factory RecordVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordVersionRow(
      entity: serializer.fromJson<String>(json['entity']),
      identity: serializer.fromJson<String>(json['identity']),
      recordId: serializer.fromJson<String>(json['recordId']),
      vectorClock: serializer.fromJson<VectorClock>(json['vectorClock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'identity': serializer.toJson<String>(identity),
      'recordId': serializer.toJson<String>(recordId),
      'vectorClock': serializer.toJson<VectorClock>(vectorClock),
    };
  }

  RecordVersionRow copyWith({
    String? entity,
    String? identity,
    String? recordId,
    VectorClock? vectorClock,
  }) => RecordVersionRow(
    entity: entity ?? this.entity,
    identity: identity ?? this.identity,
    recordId: recordId ?? this.recordId,
    vectorClock: vectorClock ?? this.vectorClock,
  );
  RecordVersionRow copyWithCompanion(RecordVersionsCompanion data) {
    return RecordVersionRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      identity: data.identity.present ? data.identity.value : this.identity,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      vectorClock: data.vectorClock.present
          ? data.vectorClock.value
          : this.vectorClock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordVersionRow(')
          ..write('entity: $entity, ')
          ..write('identity: $identity, ')
          ..write('recordId: $recordId, ')
          ..write('vectorClock: $vectorClock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, identity, recordId, vectorClock);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordVersionRow &&
          other.entity == this.entity &&
          other.identity == this.identity &&
          other.recordId == this.recordId &&
          other.vectorClock == this.vectorClock);
}

class RecordVersionsCompanion extends UpdateCompanion<RecordVersionRow> {
  final Value<String> entity;
  final Value<String> identity;
  final Value<String> recordId;
  final Value<VectorClock> vectorClock;
  final Value<int> rowid;
  const RecordVersionsCompanion({
    this.entity = const Value.absent(),
    this.identity = const Value.absent(),
    this.recordId = const Value.absent(),
    this.vectorClock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordVersionsCompanion.insert({
    required String entity,
    required String identity,
    required String recordId,
    required VectorClock vectorClock,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       identity = Value(identity),
       recordId = Value(recordId),
       vectorClock = Value(vectorClock);
  static Insertable<RecordVersionRow> custom({
    Expression<String>? entity,
    Expression<String>? identity,
    Expression<String>? recordId,
    Expression<String>? vectorClock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (identity != null) 'identity': identity,
      if (recordId != null) 'record_id': recordId,
      if (vectorClock != null) 'vector_clock': vectorClock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordVersionsCompanion copyWith({
    Value<String>? entity,
    Value<String>? identity,
    Value<String>? recordId,
    Value<VectorClock>? vectorClock,
    Value<int>? rowid,
  }) {
    return RecordVersionsCompanion(
      entity: entity ?? this.entity,
      identity: identity ?? this.identity,
      recordId: recordId ?? this.recordId,
      vectorClock: vectorClock ?? this.vectorClock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (identity.present) {
      map['identity'] = Variable<String>(identity.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (vectorClock.present) {
      map['vector_clock'] = Variable<String>(
        $RecordVersionsTable.$convertervectorClock.toSql(vectorClock.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordVersionsCompanion(')
          ..write('entity: $entity, ')
          ..write('identity: $identity, ')
          ..write('recordId: $recordId, ')
          ..write('vectorClock: $vectorClock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentUploadsTable extends ContentUploads
    with TableInfo<$ContentUploadsTable, ContentUploadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadIdMeta = const VerificationMeta(
    'uploadId',
  );
  @override
  late final GeneratedColumn<String> uploadId = GeneratedColumn<String>(
    'upload_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentBytesMeta = const VerificationMeta(
    'sentBytes',
  );
  @override
  late final GeneratedColumn<int> sentBytes = GeneratedColumn<int>(
    'sent_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> queuedAt =
      GeneratedColumn<int>(
        'queued_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ContentUploadsTable.$converterqueuedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> attemptedAt =
      GeneratedColumn<int>(
        'attempted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ContentUploadsTable.$converterattemptedAtn);
  static const VerificationMeta _refusedCodeMeta = const VerificationMeta(
    'refusedCode',
  );
  @override
  late final GeneratedColumn<String> refusedCode = GeneratedColumn<String>(
    'refused_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    contentHash,
    mediaType,
    sizeBytes,
    uploadId,
    sentBytes,
    queuedAt,
    attemptedAt,
    refusedCode,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_uploads';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentUploadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('upload_id')) {
      context.handle(
        _uploadIdMeta,
        uploadId.isAcceptableOrUnknown(data['upload_id']!, _uploadIdMeta),
      );
    }
    if (data.containsKey('sent_bytes')) {
      context.handle(
        _sentBytesMeta,
        sentBytes.isAcceptableOrUnknown(data['sent_bytes']!, _sentBytesMeta),
      );
    }
    if (data.containsKey('refused_code')) {
      context.handle(
        _refusedCodeMeta,
        refusedCode.isAcceptableOrUnknown(
          data['refused_code']!,
          _refusedCodeMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentHash};
  @override
  ContentUploadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentUploadRow(
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      uploadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_id'],
      ),
      sentBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_bytes'],
      )!,
      queuedAt: $ContentUploadsTable.$converterqueuedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}queued_at'],
        )!,
      ),
      attemptedAt: $ContentUploadsTable.$converterattemptedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}attempted_at'],
        ),
      ),
      refusedCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refused_code'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $ContentUploadsTable createAlias(String alias) {
    return $ContentUploadsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterqueuedAt =
      const InstantConverter();
  static TypeConverter<DateTime, int> $converterattemptedAt =
      const InstantConverter();
  static TypeConverter<DateTime?, int?> $converterattemptedAtn =
      NullAwareTypeConverter.wrap($converterattemptedAt);
}

class ContentUploadRow extends DataClass
    implements Insertable<ContentUploadRow> {
  /// The file, lowercase hex sha-256.
  final String contentHash;

  /// What it is, as it was declared to the node.
  ///
  /// It is stored rather than derived on each attempt because it is part of
  /// the declaration the node checked: a build that changed its mind about
  /// what a `.mobi` is called would otherwise resume a transfer under a
  /// description the node did not agree to.
  final String mediaType;

  /// How many bytes there are, by this device's own count.
  final int sizeBytes;

  /// The session the node opened, or `null` for a transfer that has not
  /// started or whose session is known to be gone.
  final String? uploadId;

  /// How many bytes the node last said it holds.
  ///
  /// It is what the node reported and never what this device sent. A device
  /// that recorded what it *sent* would resume past bytes that never landed,
  /// and the digest at the end is what would notice — after the whole file had
  /// travelled.
  final int sentBytes;

  /// When the transfer entered the queue.
  final DateTime queuedAt;

  /// When it was last attempted, or `null` for one nothing has tried.
  final DateTime? attemptedAt;

  /// Why the last attempt did not finish, as the node's stable reason or this
  /// app's own code, or `null` for one that has not failed.
  ///
  /// `unclaimed_content` is the one worth naming here, because it is not a
  /// failure at all: C16 refuses an upload for a digest no work of the reader's
  /// names, and this app never calls `CreateEbook`, so every freshly imported
  /// book answers that until the operation creating it has been pushed. The
  /// row stays queued and the next attempt after a push succeeds.
  final String? refusedCode;

  /// How many attempts have been made, so that a screen can say *this one is
  /// not working* rather than showing a queue that silently never drains.
  final int attempts;
  const ContentUploadRow({
    required this.contentHash,
    required this.mediaType,
    required this.sizeBytes,
    this.uploadId,
    required this.sentBytes,
    required this.queuedAt,
    this.attemptedAt,
    this.refusedCode,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_hash'] = Variable<String>(contentHash);
    map['media_type'] = Variable<String>(mediaType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || uploadId != null) {
      map['upload_id'] = Variable<String>(uploadId);
    }
    map['sent_bytes'] = Variable<int>(sentBytes);
    {
      map['queued_at'] = Variable<int>(
        $ContentUploadsTable.$converterqueuedAt.toSql(queuedAt),
      );
    }
    if (!nullToAbsent || attemptedAt != null) {
      map['attempted_at'] = Variable<int>(
        $ContentUploadsTable.$converterattemptedAtn.toSql(attemptedAt),
      );
    }
    if (!nullToAbsent || refusedCode != null) {
      map['refused_code'] = Variable<String>(refusedCode);
    }
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  ContentUploadsCompanion toCompanion(bool nullToAbsent) {
    return ContentUploadsCompanion(
      contentHash: Value(contentHash),
      mediaType: Value(mediaType),
      sizeBytes: Value(sizeBytes),
      uploadId: uploadId == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadId),
      sentBytes: Value(sentBytes),
      queuedAt: Value(queuedAt),
      attemptedAt: attemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(attemptedAt),
      refusedCode: refusedCode == null && nullToAbsent
          ? const Value.absent()
          : Value(refusedCode),
      attempts: Value(attempts),
    );
  }

  factory ContentUploadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentUploadRow(
      contentHash: serializer.fromJson<String>(json['contentHash']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      uploadId: serializer.fromJson<String?>(json['uploadId']),
      sentBytes: serializer.fromJson<int>(json['sentBytes']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      attemptedAt: serializer.fromJson<DateTime?>(json['attemptedAt']),
      refusedCode: serializer.fromJson<String?>(json['refusedCode']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentHash': serializer.toJson<String>(contentHash),
      'mediaType': serializer.toJson<String>(mediaType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'uploadId': serializer.toJson<String?>(uploadId),
      'sentBytes': serializer.toJson<int>(sentBytes),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'attemptedAt': serializer.toJson<DateTime?>(attemptedAt),
      'refusedCode': serializer.toJson<String?>(refusedCode),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  ContentUploadRow copyWith({
    String? contentHash,
    String? mediaType,
    int? sizeBytes,
    Value<String?> uploadId = const Value.absent(),
    int? sentBytes,
    DateTime? queuedAt,
    Value<DateTime?> attemptedAt = const Value.absent(),
    Value<String?> refusedCode = const Value.absent(),
    int? attempts,
  }) => ContentUploadRow(
    contentHash: contentHash ?? this.contentHash,
    mediaType: mediaType ?? this.mediaType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    uploadId: uploadId.present ? uploadId.value : this.uploadId,
    sentBytes: sentBytes ?? this.sentBytes,
    queuedAt: queuedAt ?? this.queuedAt,
    attemptedAt: attemptedAt.present ? attemptedAt.value : this.attemptedAt,
    refusedCode: refusedCode.present ? refusedCode.value : this.refusedCode,
    attempts: attempts ?? this.attempts,
  );
  ContentUploadRow copyWithCompanion(ContentUploadsCompanion data) {
    return ContentUploadRow(
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      uploadId: data.uploadId.present ? data.uploadId.value : this.uploadId,
      sentBytes: data.sentBytes.present ? data.sentBytes.value : this.sentBytes,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      attemptedAt: data.attemptedAt.present
          ? data.attemptedAt.value
          : this.attemptedAt,
      refusedCode: data.refusedCode.present
          ? data.refusedCode.value
          : this.refusedCode,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentUploadRow(')
          ..write('contentHash: $contentHash, ')
          ..write('mediaType: $mediaType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadId: $uploadId, ')
          ..write('sentBytes: $sentBytes, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('refusedCode: $refusedCode, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentHash,
    mediaType,
    sizeBytes,
    uploadId,
    sentBytes,
    queuedAt,
    attemptedAt,
    refusedCode,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentUploadRow &&
          other.contentHash == this.contentHash &&
          other.mediaType == this.mediaType &&
          other.sizeBytes == this.sizeBytes &&
          other.uploadId == this.uploadId &&
          other.sentBytes == this.sentBytes &&
          other.queuedAt == this.queuedAt &&
          other.attemptedAt == this.attemptedAt &&
          other.refusedCode == this.refusedCode &&
          other.attempts == this.attempts);
}

class ContentUploadsCompanion extends UpdateCompanion<ContentUploadRow> {
  final Value<String> contentHash;
  final Value<String> mediaType;
  final Value<int> sizeBytes;
  final Value<String?> uploadId;
  final Value<int> sentBytes;
  final Value<DateTime> queuedAt;
  final Value<DateTime?> attemptedAt;
  final Value<String?> refusedCode;
  final Value<int> attempts;
  final Value<int> rowid;
  const ContentUploadsCompanion({
    this.contentHash = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.uploadId = const Value.absent(),
    this.sentBytes = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.attemptedAt = const Value.absent(),
    this.refusedCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentUploadsCompanion.insert({
    required String contentHash,
    required String mediaType,
    required int sizeBytes,
    this.uploadId = const Value.absent(),
    this.sentBytes = const Value.absent(),
    required DateTime queuedAt,
    this.attemptedAt = const Value.absent(),
    this.refusedCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contentHash = Value(contentHash),
       mediaType = Value(mediaType),
       sizeBytes = Value(sizeBytes),
       queuedAt = Value(queuedAt);
  static Insertable<ContentUploadRow> custom({
    Expression<String>? contentHash,
    Expression<String>? mediaType,
    Expression<int>? sizeBytes,
    Expression<String>? uploadId,
    Expression<int>? sentBytes,
    Expression<int>? queuedAt,
    Expression<int>? attemptedAt,
    Expression<String>? refusedCode,
    Expression<int>? attempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentHash != null) 'content_hash': contentHash,
      if (mediaType != null) 'media_type': mediaType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (uploadId != null) 'upload_id': uploadId,
      if (sentBytes != null) 'sent_bytes': sentBytes,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (attemptedAt != null) 'attempted_at': attemptedAt,
      if (refusedCode != null) 'refused_code': refusedCode,
      if (attempts != null) 'attempts': attempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentUploadsCompanion copyWith({
    Value<String>? contentHash,
    Value<String>? mediaType,
    Value<int>? sizeBytes,
    Value<String?>? uploadId,
    Value<int>? sentBytes,
    Value<DateTime>? queuedAt,
    Value<DateTime?>? attemptedAt,
    Value<String?>? refusedCode,
    Value<int>? attempts,
    Value<int>? rowid,
  }) {
    return ContentUploadsCompanion(
      contentHash: contentHash ?? this.contentHash,
      mediaType: mediaType ?? this.mediaType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadId: uploadId ?? this.uploadId,
      sentBytes: sentBytes ?? this.sentBytes,
      queuedAt: queuedAt ?? this.queuedAt,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      refusedCode: refusedCode ?? this.refusedCode,
      attempts: attempts ?? this.attempts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (uploadId.present) {
      map['upload_id'] = Variable<String>(uploadId.value);
    }
    if (sentBytes.present) {
      map['sent_bytes'] = Variable<int>(sentBytes.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<int>(
        $ContentUploadsTable.$converterqueuedAt.toSql(queuedAt.value),
      );
    }
    if (attemptedAt.present) {
      map['attempted_at'] = Variable<int>(
        $ContentUploadsTable.$converterattemptedAtn.toSql(attemptedAt.value),
      );
    }
    if (refusedCode.present) {
      map['refused_code'] = Variable<String>(refusedCode.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentUploadsCompanion(')
          ..write('contentHash: $contentHash, ')
          ..write('mediaType: $mediaType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadId: $uploadId, ')
          ..write('sentBytes: $sentBytes, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('refusedCode: $refusedCode, ')
          ..write('attempts: $attempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentPinsTable extends ContentPins
    with TableInfo<$ContentPinsTable, ContentPinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentPinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keptMeta = const VerificationMeta('kept');
  @override
  late final GeneratedColumn<bool> kept = GeneratedColumn<bool>(
    'kept',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kept" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> decidedAt =
      GeneratedColumn<int>(
        'decided_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ContentPinsTable.$converterdecidedAt);
  @override
  List<GeneratedColumn> get $columns => [contentHash, kept, decidedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentPinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('kept')) {
      context.handle(
        _keptMeta,
        kept.isAcceptableOrUnknown(data['kept']!, _keptMeta),
      );
    } else if (isInserting) {
      context.missing(_keptMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentHash};
  @override
  ContentPinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentPinRow(
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      kept: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kept'],
      )!,
      decidedAt: $ContentPinsTable.$converterdecidedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}decided_at'],
        )!,
      ),
    );
  }

  @override
  $ContentPinsTable createAlias(String alias) {
    return $ContentPinsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdecidedAt =
      const InstantConverter();
}

class ContentPinRow extends DataClass implements Insertable<ContentPinRow> {
  /// The file, lowercase hex sha-256.
  final String contentHash;

  /// Whether this device keeps it.
  ///
  /// A row saying `false` is a reader who released a book on a native install;
  /// a row saying `true` is one who asked for a book in a browser. The absence
  /// of a row is neither, and is what the platform's default answers.
  final bool kept;

  /// When they decided, so that a screen can order what is held by when the
  /// reader asked for it.
  final DateTime decidedAt;
  const ContentPinRow({
    required this.contentHash,
    required this.kept,
    required this.decidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_hash'] = Variable<String>(contentHash);
    map['kept'] = Variable<bool>(kept);
    {
      map['decided_at'] = Variable<int>(
        $ContentPinsTable.$converterdecidedAt.toSql(decidedAt),
      );
    }
    return map;
  }

  ContentPinsCompanion toCompanion(bool nullToAbsent) {
    return ContentPinsCompanion(
      contentHash: Value(contentHash),
      kept: Value(kept),
      decidedAt: Value(decidedAt),
    );
  }

  factory ContentPinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentPinRow(
      contentHash: serializer.fromJson<String>(json['contentHash']),
      kept: serializer.fromJson<bool>(json['kept']),
      decidedAt: serializer.fromJson<DateTime>(json['decidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentHash': serializer.toJson<String>(contentHash),
      'kept': serializer.toJson<bool>(kept),
      'decidedAt': serializer.toJson<DateTime>(decidedAt),
    };
  }

  ContentPinRow copyWith({
    String? contentHash,
    bool? kept,
    DateTime? decidedAt,
  }) => ContentPinRow(
    contentHash: contentHash ?? this.contentHash,
    kept: kept ?? this.kept,
    decidedAt: decidedAt ?? this.decidedAt,
  );
  ContentPinRow copyWithCompanion(ContentPinsCompanion data) {
    return ContentPinRow(
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      kept: data.kept.present ? data.kept.value : this.kept,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentPinRow(')
          ..write('contentHash: $contentHash, ')
          ..write('kept: $kept, ')
          ..write('decidedAt: $decidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contentHash, kept, decidedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentPinRow &&
          other.contentHash == this.contentHash &&
          other.kept == this.kept &&
          other.decidedAt == this.decidedAt);
}

class ContentPinsCompanion extends UpdateCompanion<ContentPinRow> {
  final Value<String> contentHash;
  final Value<bool> kept;
  final Value<DateTime> decidedAt;
  final Value<int> rowid;
  const ContentPinsCompanion({
    this.contentHash = const Value.absent(),
    this.kept = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentPinsCompanion.insert({
    required String contentHash,
    required bool kept,
    required DateTime decidedAt,
    this.rowid = const Value.absent(),
  }) : contentHash = Value(contentHash),
       kept = Value(kept),
       decidedAt = Value(decidedAt);
  static Insertable<ContentPinRow> custom({
    Expression<String>? contentHash,
    Expression<bool>? kept,
    Expression<int>? decidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentHash != null) 'content_hash': contentHash,
      if (kept != null) 'kept': kept,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentPinsCompanion copyWith({
    Value<String>? contentHash,
    Value<bool>? kept,
    Value<DateTime>? decidedAt,
    Value<int>? rowid,
  }) {
    return ContentPinsCompanion(
      contentHash: contentHash ?? this.contentHash,
      kept: kept ?? this.kept,
      decidedAt: decidedAt ?? this.decidedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (kept.present) {
      map['kept'] = Variable<bool>(kept.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<int>(
        $ContentPinsTable.$converterdecidedAt.toSql(decidedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentPinsCompanion(')
          ..write('contentHash: $contentHash, ')
          ..write('kept: $kept, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AtrilDatabase extends GeneratedDatabase {
  _$AtrilDatabase(QueryExecutor e) : super(e);
  $AtrilDatabaseManager get managers => $AtrilDatabaseManager(this);
  late final $BoundDeviceTable boundDevice = $BoundDeviceTable(this);
  late final $KnownServersTable knownServers = $KnownServersTable(this);
  late final $SignedInReaderTable signedInReader = $SignedInReaderTable(this);
  late final $ClockFloorTable clockFloor = $ClockFloorTable(this);
  late final $EbooksTable ebooks = $EbooksTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $EbookCollectionsTable ebookCollections = $EbookCollectionsTable(
    this,
  );
  late final $EbookCoversTable ebookCovers = $EbookCoversTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $ProgressTable progress = $ProgressTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  late final $NodeCursorsTable nodeCursors = $NodeCursorsTable(this);
  late final $AppliedOperationsTable appliedOperations =
      $AppliedOperationsTable(this);
  late final $RecordVersionsTable recordVersions = $RecordVersionsTable(this);
  late final $ContentUploadsTable contentUploads = $ContentUploadsTable(this);
  late final $ContentPinsTable contentPins = $ContentPinsTable(this);
  late final Index knownServersOrigin = Index(
    'known_servers_origin',
    'CREATE UNIQUE INDEX known_servers_origin ON known_servers (is_origin) WHERE is_origin',
  );
  late final Index ebooksContentHash = Index(
    'ebooks_content_hash',
    'CREATE INDEX ebooks_content_hash ON ebooks (content_hash)',
  );
  late final Index ebookCollectionsCollection = Index(
    'ebook_collections_collection',
    'CREATE INDEX ebook_collections_collection ON ebook_collections (collection_id)',
  );
  late final Index annotationsEbook = Index(
    'annotations_ebook',
    'CREATE INDEX annotations_ebook ON annotations (ebook_id)',
  );
  late final IdentityDao identityDao = IdentityDao(this as AtrilDatabase);
  late final LibraryDao libraryDao = LibraryDao(this as AtrilDatabase);
  late final SyncDao syncDao = SyncDao(this as AtrilDatabase);
  late final RecordsDao recordsDao = RecordsDao(this as AtrilDatabase);
  late final TransfersDao transfersDao = TransfersDao(this as AtrilDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    boundDevice,
    knownServers,
    signedInReader,
    clockFloor,
    ebooks,
    collections,
    ebookCollections,
    ebookCovers,
    annotations,
    progress,
    pendingOperations,
    nodeCursors,
    appliedOperations,
    recordVersions,
    contentUploads,
    contentPins,
    knownServersOrigin,
    ebooksContentHash,
    ebookCollectionsCollection,
    annotationsEbook,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ebook_collections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ebook_collections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ebook_covers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('annotations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'known_servers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_cursors', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BoundDeviceTableCreateCompanionBuilder =
    BoundDeviceCompanion Function({
      Value<int> onlyRow,
      required String id,
      required String name,
      required String platform,
      required DateTime boundAt,
    });
typedef $$BoundDeviceTableUpdateCompanionBuilder =
    BoundDeviceCompanion Function({
      Value<int> onlyRow,
      Value<String> id,
      Value<String> name,
      Value<String> platform,
      Value<DateTime> boundAt,
    });

class $$BoundDeviceTableFilterComposer
    extends Composer<_$AtrilDatabase, $BoundDeviceTable> {
  $$BoundDeviceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get onlyRow => $composableBuilder(
    column: $table.onlyRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get boundAt =>
      $composableBuilder(
        column: $table.boundAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$BoundDeviceTableOrderingComposer
    extends Composer<_$AtrilDatabase, $BoundDeviceTable> {
  $$BoundDeviceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get onlyRow => $composableBuilder(
    column: $table.onlyRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boundAt => $composableBuilder(
    column: $table.boundAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoundDeviceTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $BoundDeviceTable> {
  $$BoundDeviceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get onlyRow =>
      $composableBuilder(column: $table.onlyRow, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get boundAt =>
      $composableBuilder(column: $table.boundAt, builder: (column) => column);
}

class $$BoundDeviceTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $BoundDeviceTable,
          BoundDeviceRow,
          $$BoundDeviceTableFilterComposer,
          $$BoundDeviceTableOrderingComposer,
          $$BoundDeviceTableAnnotationComposer,
          $$BoundDeviceTableCreateCompanionBuilder,
          $$BoundDeviceTableUpdateCompanionBuilder,
          (
            BoundDeviceRow,
            BaseReferences<_$AtrilDatabase, $BoundDeviceTable, BoundDeviceRow>,
          ),
          BoundDeviceRow,
          PrefetchHooks Function()
        > {
  $$BoundDeviceTableTableManager(_$AtrilDatabase db, $BoundDeviceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoundDeviceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoundDeviceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoundDeviceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> onlyRow = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<DateTime> boundAt = const Value.absent(),
              }) => BoundDeviceCompanion(
                onlyRow: onlyRow,
                id: id,
                name: name,
                platform: platform,
                boundAt: boundAt,
              ),
          createCompanionCallback:
              ({
                Value<int> onlyRow = const Value.absent(),
                required String id,
                required String name,
                required String platform,
                required DateTime boundAt,
              }) => BoundDeviceCompanion.insert(
                onlyRow: onlyRow,
                id: id,
                name: name,
                platform: platform,
                boundAt: boundAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoundDeviceTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $BoundDeviceTable,
      BoundDeviceRow,
      $$BoundDeviceTableFilterComposer,
      $$BoundDeviceTableOrderingComposer,
      $$BoundDeviceTableAnnotationComposer,
      $$BoundDeviceTableCreateCompanionBuilder,
      $$BoundDeviceTableUpdateCompanionBuilder,
      (
        BoundDeviceRow,
        BaseReferences<_$AtrilDatabase, $BoundDeviceTable, BoundDeviceRow>,
      ),
      BoundDeviceRow,
      PrefetchHooks Function()
    >;
typedef $$KnownServersTableCreateCompanionBuilder =
    KnownServersCompanion Function({
      required String domain,
      Value<String?> remoteId,
      required String baseUrl,
      Value<String?> jwksUri,
      Value<String?> certificateFingerprint,
      Value<String?> grpcAuthority,
      Value<bool> isOrigin,
      Value<DateTime?> discoveredAt,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$KnownServersTableUpdateCompanionBuilder =
    KnownServersCompanion Function({
      Value<String> domain,
      Value<String?> remoteId,
      Value<String> baseUrl,
      Value<String?> jwksUri,
      Value<String?> certificateFingerprint,
      Value<String?> grpcAuthority,
      Value<bool> isOrigin,
      Value<DateTime?> discoveredAt,
      Value<bool> active,
      Value<int> rowid,
    });

final class $$KnownServersTableReferences
    extends BaseReferences<_$AtrilDatabase, $KnownServersTable, ServerRow> {
  $$KnownServersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SignedInReaderTable, List<ReaderRow>>
  _signedInReaderRefsTable(_$AtrilDatabase db) => MultiTypedResultKey.fromTable(
    db.signedInReader,
    aliasName: 'known_servers__domain__signed_in_reader__origin_server_domain',
  );

  $$SignedInReaderTableProcessedTableManager get signedInReaderRefs {
    final manager = $$SignedInReaderTableTableManager($_db, $_db.signedInReader)
        .filter(
          (f) => f.originServerDomain.domain.sqlEquals(
            $_itemColumn<String>('domain')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_signedInReaderRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NodeCursorsTable, List<NodeCursorRow>>
  _nodeCursorsRefsTable(_$AtrilDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeCursors,
    aliasName: 'known_servers__domain__node_cursors__server_domain',
  );

  $$NodeCursorsTableProcessedTableManager get nodeCursorsRefs {
    final manager = $$NodeCursorsTableTableManager($_db, $_db.nodeCursors)
        .filter(
          (f) =>
              f.serverDomain.domain.sqlEquals($_itemColumn<String>('domain')!),
        );

    final cache = $_typedResult.readTableOrNull(_nodeCursorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KnownServersTableFilterComposer
    extends Composer<_$AtrilDatabase, $KnownServersTable> {
  $$KnownServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jwksUri => $composableBuilder(
    column: $table.jwksUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grpcAuthority => $composableBuilder(
    column: $table.grpcAuthority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOrigin => $composableBuilder(
    column: $table.isOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get discoveredAt =>
      $composableBuilder(
        column: $table.discoveredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> signedInReaderRefs(
    Expression<bool> Function($$SignedInReaderTableFilterComposer f) f,
  ) {
    final $$SignedInReaderTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.domain,
      referencedTable: $db.signedInReader,
      getReferencedColumn: (t) => t.originServerDomain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SignedInReaderTableFilterComposer(
            $db: $db,
            $table: $db.signedInReader,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nodeCursorsRefs(
    Expression<bool> Function($$NodeCursorsTableFilterComposer f) f,
  ) {
    final $$NodeCursorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.domain,
      referencedTable: $db.nodeCursors,
      getReferencedColumn: (t) => t.serverDomain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeCursorsTableFilterComposer(
            $db: $db,
            $table: $db.nodeCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KnownServersTableOrderingComposer
    extends Composer<_$AtrilDatabase, $KnownServersTable> {
  $$KnownServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jwksUri => $composableBuilder(
    column: $table.jwksUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grpcAuthority => $composableBuilder(
    column: $table.grpcAuthority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOrigin => $composableBuilder(
    column: $table.isOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnownServersTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $KnownServersTable> {
  $$KnownServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get jwksUri =>
      $composableBuilder(column: $table.jwksUri, builder: (column) => column);

  GeneratedColumn<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grpcAuthority => $composableBuilder(
    column: $table.grpcAuthority,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOrigin =>
      $composableBuilder(column: $table.isOrigin, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get discoveredAt =>
      $composableBuilder(
        column: $table.discoveredAt,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> signedInReaderRefs<T extends Object>(
    Expression<T> Function($$SignedInReaderTableAnnotationComposer a) f,
  ) {
    final $$SignedInReaderTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.domain,
      referencedTable: $db.signedInReader,
      getReferencedColumn: (t) => t.originServerDomain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SignedInReaderTableAnnotationComposer(
            $db: $db,
            $table: $db.signedInReader,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nodeCursorsRefs<T extends Object>(
    Expression<T> Function($$NodeCursorsTableAnnotationComposer a) f,
  ) {
    final $$NodeCursorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.domain,
      referencedTable: $db.nodeCursors,
      getReferencedColumn: (t) => t.serverDomain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeCursorsTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KnownServersTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $KnownServersTable,
          ServerRow,
          $$KnownServersTableFilterComposer,
          $$KnownServersTableOrderingComposer,
          $$KnownServersTableAnnotationComposer,
          $$KnownServersTableCreateCompanionBuilder,
          $$KnownServersTableUpdateCompanionBuilder,
          (ServerRow, $$KnownServersTableReferences),
          ServerRow,
          PrefetchHooks Function({
            bool signedInReaderRefs,
            bool nodeCursorsRefs,
          })
        > {
  $$KnownServersTableTableManager(_$AtrilDatabase db, $KnownServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnownServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnownServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnownServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> domain = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String?> jwksUri = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String?> grpcAuthority = const Value.absent(),
                Value<bool> isOrigin = const Value.absent(),
                Value<DateTime?> discoveredAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownServersCompanion(
                domain: domain,
                remoteId: remoteId,
                baseUrl: baseUrl,
                jwksUri: jwksUri,
                certificateFingerprint: certificateFingerprint,
                grpcAuthority: grpcAuthority,
                isOrigin: isOrigin,
                discoveredAt: discoveredAt,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String domain,
                Value<String?> remoteId = const Value.absent(),
                required String baseUrl,
                Value<String?> jwksUri = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String?> grpcAuthority = const Value.absent(),
                Value<bool> isOrigin = const Value.absent(),
                Value<DateTime?> discoveredAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownServersCompanion.insert(
                domain: domain,
                remoteId: remoteId,
                baseUrl: baseUrl,
                jwksUri: jwksUri,
                certificateFingerprint: certificateFingerprint,
                grpcAuthority: grpcAuthority,
                isOrigin: isOrigin,
                discoveredAt: discoveredAt,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KnownServersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({signedInReaderRefs = false, nodeCursorsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (signedInReaderRefs) db.signedInReader,
                    if (nodeCursorsRefs) db.nodeCursors,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (signedInReaderRefs)
                        await $_getPrefetchedData<
                          ServerRow,
                          $KnownServersTable,
                          ReaderRow
                        >(
                          currentTable: table,
                          referencedTable: $$KnownServersTableReferences
                              ._signedInReaderRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KnownServersTableReferences(
                                db,
                                table,
                                p0,
                              ).signedInReaderRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.originServerDomain == item.domain,
                              ),
                          typedResults: items,
                        ),
                      if (nodeCursorsRefs)
                        await $_getPrefetchedData<
                          ServerRow,
                          $KnownServersTable,
                          NodeCursorRow
                        >(
                          currentTable: table,
                          referencedTable: $$KnownServersTableReferences
                              ._nodeCursorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KnownServersTableReferences(
                                db,
                                table,
                                p0,
                              ).nodeCursorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serverDomain == item.domain,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$KnownServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $KnownServersTable,
      ServerRow,
      $$KnownServersTableFilterComposer,
      $$KnownServersTableOrderingComposer,
      $$KnownServersTableAnnotationComposer,
      $$KnownServersTableCreateCompanionBuilder,
      $$KnownServersTableUpdateCompanionBuilder,
      (ServerRow, $$KnownServersTableReferences),
      ServerRow,
      PrefetchHooks Function({bool signedInReaderRefs, bool nodeCursorsRefs})
    >;
typedef $$SignedInReaderTableCreateCompanionBuilder =
    SignedInReaderCompanion Function({
      Value<int> onlyRow,
      required String id,
      required String localName,
      required String displayName,
      required String originServerDomain,
      required String federatedId,
      Value<String?> email,
      required DateTime createdAt,
    });
typedef $$SignedInReaderTableUpdateCompanionBuilder =
    SignedInReaderCompanion Function({
      Value<int> onlyRow,
      Value<String> id,
      Value<String> localName,
      Value<String> displayName,
      Value<String> originServerDomain,
      Value<String> federatedId,
      Value<String?> email,
      Value<DateTime> createdAt,
    });

final class $$SignedInReaderTableReferences
    extends BaseReferences<_$AtrilDatabase, $SignedInReaderTable, ReaderRow> {
  $$SignedInReaderTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $KnownServersTable _originServerDomainTable(_$AtrilDatabase db) =>
      db.knownServers.createAlias(
        'signed_in_reader__origin_server_domain__known_servers__domain',
      );

  $$KnownServersTableProcessedTableManager get originServerDomain {
    final $_column = $_itemColumn<String>('origin_server_domain')!;

    final manager = $$KnownServersTableTableManager(
      $_db,
      $_db.knownServers,
    ).filter((f) => f.domain.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originServerDomainTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SignedInReaderTableFilterComposer
    extends Composer<_$AtrilDatabase, $SignedInReaderTable> {
  $$SignedInReaderTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get onlyRow => $composableBuilder(
    column: $table.onlyRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localName => $composableBuilder(
    column: $table.localName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get federatedId => $composableBuilder(
    column: $table.federatedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$KnownServersTableFilterComposer get originServerDomain {
    final $$KnownServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originServerDomain,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.domain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnownServersTableFilterComposer(
            $db: $db,
            $table: $db.knownServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SignedInReaderTableOrderingComposer
    extends Composer<_$AtrilDatabase, $SignedInReaderTable> {
  $$SignedInReaderTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get onlyRow => $composableBuilder(
    column: $table.onlyRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localName => $composableBuilder(
    column: $table.localName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get federatedId => $composableBuilder(
    column: $table.federatedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$KnownServersTableOrderingComposer get originServerDomain {
    final $$KnownServersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originServerDomain,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.domain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnownServersTableOrderingComposer(
            $db: $db,
            $table: $db.knownServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SignedInReaderTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $SignedInReaderTable> {
  $$SignedInReaderTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get onlyRow =>
      $composableBuilder(column: $table.onlyRow, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localName =>
      $composableBuilder(column: $table.localName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get federatedId => $composableBuilder(
    column: $table.federatedId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$KnownServersTableAnnotationComposer get originServerDomain {
    final $$KnownServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originServerDomain,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.domain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnownServersTableAnnotationComposer(
            $db: $db,
            $table: $db.knownServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SignedInReaderTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $SignedInReaderTable,
          ReaderRow,
          $$SignedInReaderTableFilterComposer,
          $$SignedInReaderTableOrderingComposer,
          $$SignedInReaderTableAnnotationComposer,
          $$SignedInReaderTableCreateCompanionBuilder,
          $$SignedInReaderTableUpdateCompanionBuilder,
          (ReaderRow, $$SignedInReaderTableReferences),
          ReaderRow,
          PrefetchHooks Function({bool originServerDomain})
        > {
  $$SignedInReaderTableTableManager(
    _$AtrilDatabase db,
    $SignedInReaderTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignedInReaderTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignedInReaderTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignedInReaderTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> onlyRow = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> localName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> originServerDomain = const Value.absent(),
                Value<String> federatedId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SignedInReaderCompanion(
                onlyRow: onlyRow,
                id: id,
                localName: localName,
                displayName: displayName,
                originServerDomain: originServerDomain,
                federatedId: federatedId,
                email: email,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> onlyRow = const Value.absent(),
                required String id,
                required String localName,
                required String displayName,
                required String originServerDomain,
                required String federatedId,
                Value<String?> email = const Value.absent(),
                required DateTime createdAt,
              }) => SignedInReaderCompanion.insert(
                onlyRow: onlyRow,
                id: id,
                localName: localName,
                displayName: displayName,
                originServerDomain: originServerDomain,
                federatedId: federatedId,
                email: email,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SignedInReaderTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({originServerDomain = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (originServerDomain) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.originServerDomain,
                        referencedTable: $$SignedInReaderTableReferences
                            ._originServerDomainTable(db),
                        referencedColumn: $$SignedInReaderTableReferences
                            ._originServerDomainTable(db)
                            .domain,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SignedInReaderTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $SignedInReaderTable,
      ReaderRow,
      $$SignedInReaderTableFilterComposer,
      $$SignedInReaderTableOrderingComposer,
      $$SignedInReaderTableAnnotationComposer,
      $$SignedInReaderTableCreateCompanionBuilder,
      $$SignedInReaderTableUpdateCompanionBuilder,
      (ReaderRow, $$SignedInReaderTableReferences),
      ReaderRow,
      PrefetchHooks Function({bool originServerDomain})
    >;
typedef $$ClockFloorTableCreateCompanionBuilder = ClockFloorCompanion Function({
  Value<int> onlyRow,
  required DateTime observedAt,
});
typedef $$ClockFloorTableUpdateCompanionBuilder = ClockFloorCompanion Function({
  Value<int> onlyRow,
  Value<DateTime> observedAt,
});

class $$ClockFloorTableFilterComposer
    extends Composer<_$AtrilDatabase, $ClockFloorTable> {
  $$ClockFloorTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get onlyRow => $composableBuilder(
    column: $table.onlyRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get observedAt =>
      $composableBuilder(
        column: $table.observedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ClockFloorTableOrderingComposer
    extends Composer<_$AtrilDatabase, $ClockFloorTable> {
  $$ClockFloorTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get onlyRow => $composableBuilder(
    column: $table.onlyRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClockFloorTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $ClockFloorTable> {
  $$ClockFloorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get onlyRow =>
      $composableBuilder(column: $table.onlyRow, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get observedAt =>
      $composableBuilder(
        column: $table.observedAt,
        builder: (column) => column,
      );
}

class $$ClockFloorTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $ClockFloorTable,
          ClockFloorRow,
          $$ClockFloorTableFilterComposer,
          $$ClockFloorTableOrderingComposer,
          $$ClockFloorTableAnnotationComposer,
          $$ClockFloorTableCreateCompanionBuilder,
          $$ClockFloorTableUpdateCompanionBuilder,
          (
            ClockFloorRow,
            BaseReferences<_$AtrilDatabase, $ClockFloorTable, ClockFloorRow>,
          ),
          ClockFloorRow,
          PrefetchHooks Function()
        > {
  $$ClockFloorTableTableManager(_$AtrilDatabase db, $ClockFloorTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClockFloorTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClockFloorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClockFloorTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> onlyRow = const Value.absent(),
            Value<DateTime> observedAt = const Value.absent(),
          }) => ClockFloorCompanion(onlyRow: onlyRow, observedAt: observedAt),
          createCompanionCallback:
              ({
                Value<int> onlyRow = const Value.absent(),
                required DateTime observedAt,
              }) => ClockFloorCompanion.insert(
                onlyRow: onlyRow,
                observedAt: observedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClockFloorTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $ClockFloorTable,
      ClockFloorRow,
      $$ClockFloorTableFilterComposer,
      $$ClockFloorTableOrderingComposer,
      $$ClockFloorTableAnnotationComposer,
      $$ClockFloorTableCreateCompanionBuilder,
      $$ClockFloorTableUpdateCompanionBuilder,
      (
        ClockFloorRow,
        BaseReferences<_$AtrilDatabase, $ClockFloorTable, ClockFloorRow>,
      ),
      ClockFloorRow,
      PrefetchHooks Function()
    >;
typedef $$EbooksTableCreateCompanionBuilder = EbooksCompanion Function({
  required VectorClock vectorClock,
  required DateTime updatedAt,
  required String deviceId,
  Value<bool> deleted,
  required String id,
  required String title,
  Value<String?> author,
  Value<String?> publisher,
  Value<String?> language,
  required String format,
  required String contentHash,
  Value<int?> sizeBytes,
  Value<String?> extraMetadata,
  required DateTime importedAt,
  Value<int> rowid,
});
typedef $$EbooksTableUpdateCompanionBuilder = EbooksCompanion Function({
  Value<VectorClock> vectorClock,
  Value<DateTime> updatedAt,
  Value<String> deviceId,
  Value<bool> deleted,
  Value<String> id,
  Value<String> title,
  Value<String?> author,
  Value<String?> publisher,
  Value<String?> language,
  Value<String> format,
  Value<String> contentHash,
  Value<int?> sizeBytes,
  Value<String?> extraMetadata,
  Value<DateTime> importedAt,
  Value<int> rowid,
});

final class $$EbooksTableReferences
    extends BaseReferences<_$AtrilDatabase, $EbooksTable, EbookRow> {
  $$EbooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EbookCollectionsTable, List<EbookCollectionRow>>
  _ebookCollectionsRefsTable(_$AtrilDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ebookCollections,
        aliasName: 'ebooks__id__ebook_collections__ebook_id',
      );

  $$EbookCollectionsTableProcessedTableManager get ebookCollectionsRefs {
    final manager = $$EbookCollectionsTableTableManager(
      $_db,
      $_db.ebookCollections,
    ).filter((f) => f.ebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ebookCollectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EbookCoversTable, List<EbookCoverRow>>
  _ebookCoversRefsTable(_$AtrilDatabase db) => MultiTypedResultKey.fromTable(
    db.ebookCovers,
    aliasName: 'ebooks__id__ebook_covers__ebook_id',
  );

  $$EbookCoversTableProcessedTableManager get ebookCoversRefs {
    final manager = $$EbookCoversTableTableManager(
      $_db,
      $_db.ebookCovers,
    ).filter((f) => f.ebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ebookCoversRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnnotationsTable, List<AnnotationRow>>
  _annotationsRefsTable(_$AtrilDatabase db) => MultiTypedResultKey.fromTable(
    db.annotations,
    aliasName: 'ebooks__id__annotations__ebook_id',
  );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.ebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProgressTable, List<ProgressRow>>
  _progressRefsTable(_$AtrilDatabase db) => MultiTypedResultKey.fromTable(
    db.progress,
    aliasName: 'ebooks__id__progress__ebook_id',
  );

  $$ProgressTableProcessedTableManager get progressRefs {
    final manager = $$ProgressTableTableManager(
      $_db,
      $_db.progress,
    ).filter((f) => f.ebookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_progressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EbooksTableFilterComposer
    extends Composer<_$AtrilDatabase, $EbooksTable> {
  $$EbooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraMetadata => $composableBuilder(
    column: $table.extraMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get importedAt =>
      $composableBuilder(
        column: $table.importedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> ebookCollectionsRefs(
    Expression<bool> Function($$EbookCollectionsTableFilterComposer f) f,
  ) {
    final $$EbookCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ebookCollections,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbookCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.ebookCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ebookCoversRefs(
    Expression<bool> Function($$EbookCoversTableFilterComposer f) f,
  ) {
    final $$EbookCoversTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ebookCovers,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbookCoversTableFilterComposer(
            $db: $db,
            $table: $db.ebookCovers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> annotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> progressRefs(
    Expression<bool> Function($$ProgressTableFilterComposer f) f,
  ) {
    final $$ProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progress,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressTableFilterComposer(
            $db: $db,
            $table: $db.progress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EbooksTableOrderingComposer
    extends Composer<_$AtrilDatabase, $EbooksTable> {
  $$EbooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraMetadata => $composableBuilder(
    column: $table.extraMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EbooksTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $EbooksTable> {
  $$EbooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get extraMetadata => $composableBuilder(
    column: $table.extraMetadata,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get importedAt =>
      $composableBuilder(
        column: $table.importedAt,
        builder: (column) => column,
      );

  Expression<T> ebookCollectionsRefs<T extends Object>(
    Expression<T> Function($$EbookCollectionsTableAnnotationComposer a) f,
  ) {
    final $$EbookCollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ebookCollections,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbookCollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.ebookCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ebookCoversRefs<T extends Object>(
    Expression<T> Function($$EbookCoversTableAnnotationComposer a) f,
  ) {
    final $$EbookCoversTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ebookCovers,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbookCoversTableAnnotationComposer(
            $db: $db,
            $table: $db.ebookCovers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> annotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> progressRefs<T extends Object>(
    Expression<T> Function($$ProgressTableAnnotationComposer a) f,
  ) {
    final $$ProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progress,
      getReferencedColumn: (t) => t.ebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.progress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EbooksTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $EbooksTable,
          EbookRow,
          $$EbooksTableFilterComposer,
          $$EbooksTableOrderingComposer,
          $$EbooksTableAnnotationComposer,
          $$EbooksTableCreateCompanionBuilder,
          $$EbooksTableUpdateCompanionBuilder,
          (EbookRow, $$EbooksTableReferences),
          EbookRow,
          PrefetchHooks Function({
            bool ebookCollectionsRefs,
            bool ebookCoversRefs,
            bool annotationsRefs,
            bool progressRefs,
          })
        > {
  $$EbooksTableTableManager(_$AtrilDatabase db, $EbooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EbooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EbooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EbooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> extraMetadata = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EbooksCompanion(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                title: title,
                author: author,
                publisher: publisher,
                language: language,
                format: format,
                contentHash: contentHash,
                sizeBytes: sizeBytes,
                extraMetadata: extraMetadata,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required VectorClock vectorClock,
                required DateTime updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> language = const Value.absent(),
                required String format,
                required String contentHash,
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> extraMetadata = const Value.absent(),
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => EbooksCompanion.insert(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                title: title,
                author: author,
                publisher: publisher,
                language: language,
                format: format,
                contentHash: contentHash,
                sizeBytes: sizeBytes,
                extraMetadata: extraMetadata,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$EbooksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ebookCollectionsRefs = false,
                ebookCoversRefs = false,
                annotationsRefs = false,
                progressRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ebookCollectionsRefs) db.ebookCollections,
                    if (ebookCoversRefs) db.ebookCovers,
                    if (annotationsRefs) db.annotations,
                    if (progressRefs) db.progress,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ebookCollectionsRefs)
                        await $_getPrefetchedData<
                          EbookRow,
                          $EbooksTable,
                          EbookCollectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$EbooksTableReferences
                              ._ebookCollectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EbooksTableReferences(
                                db,
                                table,
                                p0,
                              ).ebookCollectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ebookCoversRefs)
                        await $_getPrefetchedData<
                          EbookRow,
                          $EbooksTable,
                          EbookCoverRow
                        >(
                          currentTable: table,
                          referencedTable: $$EbooksTableReferences
                              ._ebookCoversRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EbooksTableReferences(
                                db,
                                table,
                                p0,
                              ).ebookCoversRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (annotationsRefs)
                        await $_getPrefetchedData<
                          EbookRow,
                          $EbooksTable,
                          AnnotationRow
                        >(
                          currentTable: table,
                          referencedTable: $$EbooksTableReferences
                              ._annotationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EbooksTableReferences(
                                db,
                                table,
                                p0,
                              ).annotationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (progressRefs)
                        await $_getPrefetchedData<
                          EbookRow,
                          $EbooksTable,
                          ProgressRow
                        >(
                          currentTable: table,
                          referencedTable: $$EbooksTableReferences
                              ._progressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EbooksTableReferences(
                                db,
                                table,
                                p0,
                              ).progressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EbooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $EbooksTable,
      EbookRow,
      $$EbooksTableFilterComposer,
      $$EbooksTableOrderingComposer,
      $$EbooksTableAnnotationComposer,
      $$EbooksTableCreateCompanionBuilder,
      $$EbooksTableUpdateCompanionBuilder,
      (EbookRow, $$EbooksTableReferences),
      EbookRow,
      PrefetchHooks Function({
        bool ebookCollectionsRefs,
        bool ebookCoversRefs,
        bool annotationsRefs,
        bool progressRefs,
      })
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required VectorClock vectorClock,
      required DateTime updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String id,
      required String name,
      Value<String> kind,
      Value<String?> description,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<VectorClock> vectorClock,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CollectionsTableReferences
    extends BaseReferences<_$AtrilDatabase, $CollectionsTable, CollectionRow> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EbookCollectionsTable, List<EbookCollectionRow>>
  _ebookCollectionsRefsTable(_$AtrilDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ebookCollections,
        aliasName: 'collections__id__ebook_collections__collection_id',
      );

  $$EbookCollectionsTableProcessedTableManager get ebookCollectionsRefs {
    final manager = $$EbookCollectionsTableTableManager(
      $_db,
      $_db.ebookCollections,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ebookCollectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$AtrilDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> ebookCollectionsRefs(
    Expression<bool> Function($$EbookCollectionsTableFilterComposer f) f,
  ) {
    final $$EbookCollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ebookCollections,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbookCollectionsTableFilterComposer(
            $db: $db,
            $table: $db.ebookCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ebookCollectionsRefs<T extends Object>(
    Expression<T> Function($$EbookCollectionsTableAnnotationComposer a) f,
  ) {
    final $$EbookCollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ebookCollections,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbookCollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.ebookCollections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $CollectionsTable,
          CollectionRow,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (CollectionRow, $$CollectionsTableReferences),
          CollectionRow,
          PrefetchHooks Function({bool ebookCollectionsRefs})
        > {
  $$CollectionsTableTableManager(_$AtrilDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                name: name,
                kind: kind,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required VectorClock vectorClock,
                required DateTime updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String name,
                Value<String> kind = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                name: name,
                kind: kind,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ebookCollectionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ebookCollectionsRefs) db.ebookCollections,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ebookCollectionsRefs)
                    await $_getPrefetchedData<
                      CollectionRow,
                      $CollectionsTable,
                      EbookCollectionRow
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionsTableReferences
                          ._ebookCollectionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).ebookCollectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $CollectionsTable,
      CollectionRow,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (CollectionRow, $$CollectionsTableReferences),
      CollectionRow,
      PrefetchHooks Function({bool ebookCollectionsRefs})
    >;
typedef $$EbookCollectionsTableCreateCompanionBuilder =
    EbookCollectionsCompanion Function({
      required VectorClock vectorClock,
      required DateTime updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String id,
      required String ebookId,
      required String collectionId,
      Value<int> rowid,
    });
typedef $$EbookCollectionsTableUpdateCompanionBuilder =
    EbookCollectionsCompanion Function({
      Value<VectorClock> vectorClock,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> id,
      Value<String> ebookId,
      Value<String> collectionId,
      Value<int> rowid,
    });

final class $$EbookCollectionsTableReferences
    extends
        BaseReferences<
          _$AtrilDatabase,
          $EbookCollectionsTable,
          EbookCollectionRow
        > {
  $$EbookCollectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EbooksTable _ebookIdTable(_$AtrilDatabase db) =>
      db.ebooks.createAlias('ebook_collections__ebook_id__ebooks__id');

  $$EbooksTableProcessedTableManager get ebookId {
    final $_column = $_itemColumn<String>('ebook_id')!;

    final manager = $$EbooksTableTableManager(
      $_db,
      $_db.ebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CollectionsTable _collectionIdTable(_$AtrilDatabase db) => db
      .collections
      .createAlias('ebook_collections__collection_id__collections__id');

  $$CollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$CollectionsTableTableManager(
      $_db,
      $_db.collections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EbookCollectionsTableFilterComposer
    extends Composer<_$AtrilDatabase, $EbookCollectionsTable> {
  $$EbookCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  $$EbooksTableFilterComposer get ebookId {
    final $$EbooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableFilterComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableFilterComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EbookCollectionsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $EbookCollectionsTable> {
  $$EbookCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  $$EbooksTableOrderingComposer get ebookId {
    final $$EbooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableOrderingComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EbookCollectionsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $EbookCollectionsTable> {
  $$EbookCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  $$EbooksTableAnnotationComposer get ebookId {
    final $$EbooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableAnnotationComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EbookCollectionsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $EbookCollectionsTable,
          EbookCollectionRow,
          $$EbookCollectionsTableFilterComposer,
          $$EbookCollectionsTableOrderingComposer,
          $$EbookCollectionsTableAnnotationComposer,
          $$EbookCollectionsTableCreateCompanionBuilder,
          $$EbookCollectionsTableUpdateCompanionBuilder,
          (EbookCollectionRow, $$EbookCollectionsTableReferences),
          EbookCollectionRow,
          PrefetchHooks Function({bool ebookId, bool collectionId})
        > {
  $$EbookCollectionsTableTableManager(
    _$AtrilDatabase db,
    $EbookCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EbookCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EbookCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EbookCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> ebookId = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EbookCollectionsCompanion(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                ebookId: ebookId,
                collectionId: collectionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required VectorClock vectorClock,
                required DateTime updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String ebookId,
                required String collectionId,
                Value<int> rowid = const Value.absent(),
              }) => EbookCollectionsCompanion.insert(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                ebookId: ebookId,
                collectionId: collectionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EbookCollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ebookId = false, collectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ebookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ebookId,
                        referencedTable: $$EbookCollectionsTableReferences
                            ._ebookIdTable(db),
                        referencedColumn: $$EbookCollectionsTableReferences
                            ._ebookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (collectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.collectionId,
                        referencedTable: $$EbookCollectionsTableReferences
                            ._collectionIdTable(db),
                        referencedColumn: $$EbookCollectionsTableReferences
                            ._collectionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EbookCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $EbookCollectionsTable,
      EbookCollectionRow,
      $$EbookCollectionsTableFilterComposer,
      $$EbookCollectionsTableOrderingComposer,
      $$EbookCollectionsTableAnnotationComposer,
      $$EbookCollectionsTableCreateCompanionBuilder,
      $$EbookCollectionsTableUpdateCompanionBuilder,
      (EbookCollectionRow, $$EbookCollectionsTableReferences),
      EbookCollectionRow,
      PrefetchHooks Function({bool ebookId, bool collectionId})
    >;
typedef $$EbookCoversTableCreateCompanionBuilder =
    EbookCoversCompanion Function({
      required String ebookId,
      required String mediaType,
      required Uint8List bytes,
      Value<int> rowid,
    });
typedef $$EbookCoversTableUpdateCompanionBuilder =
    EbookCoversCompanion Function({
      Value<String> ebookId,
      Value<String> mediaType,
      Value<Uint8List> bytes,
      Value<int> rowid,
    });

final class $$EbookCoversTableReferences
    extends BaseReferences<_$AtrilDatabase, $EbookCoversTable, EbookCoverRow> {
  $$EbookCoversTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EbooksTable _ebookIdTable(_$AtrilDatabase db) =>
      db.ebooks.createAlias('ebook_covers__ebook_id__ebooks__id');

  $$EbooksTableProcessedTableManager get ebookId {
    final $_column = $_itemColumn<String>('ebook_id')!;

    final manager = $$EbooksTableTableManager(
      $_db,
      $_db.ebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EbookCoversTableFilterComposer
    extends Composer<_$AtrilDatabase, $EbookCoversTable> {
  $$EbookCoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  $$EbooksTableFilterComposer get ebookId {
    final $$EbooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableFilterComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EbookCoversTableOrderingComposer
    extends Composer<_$AtrilDatabase, $EbookCoversTable> {
  $$EbookCoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  $$EbooksTableOrderingComposer get ebookId {
    final $$EbooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableOrderingComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EbookCoversTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $EbookCoversTable> {
  $$EbookCoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  $$EbooksTableAnnotationComposer get ebookId {
    final $$EbooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableAnnotationComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EbookCoversTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $EbookCoversTable,
          EbookCoverRow,
          $$EbookCoversTableFilterComposer,
          $$EbookCoversTableOrderingComposer,
          $$EbookCoversTableAnnotationComposer,
          $$EbookCoversTableCreateCompanionBuilder,
          $$EbookCoversTableUpdateCompanionBuilder,
          (EbookCoverRow, $$EbookCoversTableReferences),
          EbookCoverRow,
          PrefetchHooks Function({bool ebookId})
        > {
  $$EbookCoversTableTableManager(_$AtrilDatabase db, $EbookCoversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EbookCoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EbookCoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EbookCoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ebookId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EbookCoversCompanion(
                ebookId: ebookId,
                mediaType: mediaType,
                bytes: bytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ebookId,
                required String mediaType,
                required Uint8List bytes,
                Value<int> rowid = const Value.absent(),
              }) => EbookCoversCompanion.insert(
                ebookId: ebookId,
                mediaType: mediaType,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EbookCoversTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ebookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ebookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ebookId,
                        referencedTable: $$EbookCoversTableReferences
                            ._ebookIdTable(db),
                        referencedColumn: $$EbookCoversTableReferences
                            ._ebookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EbookCoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $EbookCoversTable,
      EbookCoverRow,
      $$EbookCoversTableFilterComposer,
      $$EbookCoversTableOrderingComposer,
      $$EbookCoversTableAnnotationComposer,
      $$EbookCoversTableCreateCompanionBuilder,
      $$EbookCoversTableUpdateCompanionBuilder,
      (EbookCoverRow, $$EbookCoversTableReferences),
      EbookCoverRow,
      PrefetchHooks Function({bool ebookId})
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      required VectorClock vectorClock,
      required DateTime updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String id,
      required String ebookId,
      required String kind,
      Value<String?> content,
      required String locator,
      Value<int> rowid,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<VectorClock> vectorClock,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> id,
      Value<String> ebookId,
      Value<String> kind,
      Value<String?> content,
      Value<String> locator,
      Value<int> rowid,
    });

final class $$AnnotationsTableReferences
    extends BaseReferences<_$AtrilDatabase, $AnnotationsTable, AnnotationRow> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EbooksTable _ebookIdTable(_$AtrilDatabase db) =>
      db.ebooks.createAlias('annotations__ebook_id__ebooks__id');

  $$EbooksTableProcessedTableManager get ebookId {
    final $_column = $_itemColumn<String>('ebook_id')!;

    final manager = $$EbooksTableTableManager(
      $_db,
      $_db.ebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationsTableFilterComposer
    extends Composer<_$AtrilDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnFilters(column),
  );

  $$EbooksTableFilterComposer get ebookId {
    final $$EbooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableFilterComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnOrderings(column),
  );

  $$EbooksTableOrderingComposer get ebookId {
    final $$EbooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableOrderingComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get locator =>
      $composableBuilder(column: $table.locator, builder: (column) => column);

  $$EbooksTableAnnotationComposer get ebookId {
    final $$EbooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableAnnotationComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $AnnotationsTable,
          AnnotationRow,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (AnnotationRow, $$AnnotationsTableReferences),
          AnnotationRow,
          PrefetchHooks Function({bool ebookId})
        > {
  $$AnnotationsTableTableManager(_$AtrilDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> ebookId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> locator = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                ebookId: ebookId,
                kind: kind,
                content: content,
                locator: locator,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required VectorClock vectorClock,
                required DateTime updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String ebookId,
                required String kind,
                Value<String?> content = const Value.absent(),
                required String locator,
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                id: id,
                ebookId: ebookId,
                kind: kind,
                content: content,
                locator: locator,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ebookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ebookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ebookId,
                        referencedTable: $$AnnotationsTableReferences
                            ._ebookIdTable(db),
                        referencedColumn: $$AnnotationsTableReferences
                            ._ebookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $AnnotationsTable,
      AnnotationRow,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (AnnotationRow, $$AnnotationsTableReferences),
      AnnotationRow,
      PrefetchHooks Function({bool ebookId})
    >;
typedef $$ProgressTableCreateCompanionBuilder = ProgressCompanion Function({
  required String id,
  required String ebookId,
  required String deviceId,
  required String locator,
  Value<double?> percent,
  required VectorClock vectorClock,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProgressTableUpdateCompanionBuilder = ProgressCompanion Function({
  Value<String> id,
  Value<String> ebookId,
  Value<String> deviceId,
  Value<String> locator,
  Value<double?> percent,
  Value<VectorClock> vectorClock,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProgressTableReferences
    extends BaseReferences<_$AtrilDatabase, $ProgressTable, ProgressRow> {
  $$ProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EbooksTable _ebookIdTable(_$AtrilDatabase db) =>
      db.ebooks.createAlias('progress__ebook_id__ebooks__id');

  $$EbooksTableProcessedTableManager get ebookId {
    final $_column = $_itemColumn<String>('ebook_id')!;

    final manager = $$EbooksTableTableManager(
      $_db,
      $_db.ebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgressTableFilterComposer
    extends Composer<_$AtrilDatabase, $ProgressTable> {
  $$ProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$EbooksTableFilterComposer get ebookId {
    final $$EbooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableFilterComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressTableOrderingComposer
    extends Composer<_$AtrilDatabase, $ProgressTable> {
  $$ProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EbooksTableOrderingComposer get ebookId {
    final $$EbooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableOrderingComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $ProgressTable> {
  $$ProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get locator =>
      $composableBuilder(column: $table.locator, builder: (column) => column);

  GeneratedColumn<double> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EbooksTableAnnotationComposer get ebookId {
    final $$EbooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ebookId,
      referencedTable: $db.ebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EbooksTableAnnotationComposer(
            $db: $db,
            $table: $db.ebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $ProgressTable,
          ProgressRow,
          $$ProgressTableFilterComposer,
          $$ProgressTableOrderingComposer,
          $$ProgressTableAnnotationComposer,
          $$ProgressTableCreateCompanionBuilder,
          $$ProgressTableUpdateCompanionBuilder,
          (ProgressRow, $$ProgressTableReferences),
          ProgressRow,
          PrefetchHooks Function({bool ebookId})
        > {
  $$ProgressTableTableManager(_$AtrilDatabase db, $ProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ebookId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> locator = const Value.absent(),
                Value<double?> percent = const Value.absent(),
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressCompanion(
                id: id,
                ebookId: ebookId,
                deviceId: deviceId,
                locator: locator,
                percent: percent,
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ebookId,
                required String deviceId,
                required String locator,
                Value<double?> percent = const Value.absent(),
                required VectorClock vectorClock,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressCompanion.insert(
                id: id,
                ebookId: ebookId,
                deviceId: deviceId,
                locator: locator,
                percent: percent,
                vectorClock: vectorClock,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ebookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ebookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ebookId,
                        referencedTable: $$ProgressTableReferences
                            ._ebookIdTable(db),
                        referencedColumn: $$ProgressTableReferences
                            ._ebookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $ProgressTable,
      ProgressRow,
      $$ProgressTableFilterComposer,
      $$ProgressTableOrderingComposer,
      $$ProgressTableAnnotationComposer,
      $$ProgressTableCreateCompanionBuilder,
      $$ProgressTableUpdateCompanionBuilder,
      (ProgressRow, $$ProgressTableReferences),
      ProgressRow,
      PrefetchHooks Function({bool ebookId})
    >;
typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> sequence,
      required String id,
      required String deviceId,
      required String targetEntity,
      required String targetId,
      required String operation,
      required String delta,
      required VectorClock vectorClock,
      required DateTime createdAt,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> sequence,
      Value<String> id,
      Value<String> deviceId,
      Value<String> targetEntity,
      Value<String> targetId,
      Value<String> operation,
      Value<String> delta,
      Value<VectorClock> vectorClock,
      Value<DateTime> createdAt,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AtrilDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetEntity => $composableBuilder(
    column: $table.targetEntity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetEntity => $composableBuilder(
    column: $table.targetEntity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get targetEntity => $composableBuilder(
    column: $table.targetEntity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $PendingOperationsTable,
          PendingOperationRow,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperationRow,
            BaseReferences<
              _$AtrilDatabase,
              $PendingOperationsTable,
              PendingOperationRow
            >,
          ),
          PendingOperationRow,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AtrilDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> targetEntity = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> delta = const Value.absent(),
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingOperationsCompanion(
                sequence: sequence,
                id: id,
                deviceId: deviceId,
                targetEntity: targetEntity,
                targetId: targetId,
                operation: operation,
                delta: delta,
                vectorClock: vectorClock,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String id,
                required String deviceId,
                required String targetEntity,
                required String targetId,
                required String operation,
                required String delta,
                required VectorClock vectorClock,
                required DateTime createdAt,
              }) => PendingOperationsCompanion.insert(
                sequence: sequence,
                id: id,
                deviceId: deviceId,
                targetEntity: targetEntity,
                targetId: targetId,
                operation: operation,
                delta: delta,
                vectorClock: vectorClock,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $PendingOperationsTable,
      PendingOperationRow,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperationRow,
        BaseReferences<
          _$AtrilDatabase,
          $PendingOperationsTable,
          PendingOperationRow
        >,
      ),
      PendingOperationRow,
      PrefetchHooks Function()
    >;
typedef $$NodeCursorsTableCreateCompanionBuilder =
    NodeCursorsCompanion Function({
      required String serverDomain,
      Value<int> lastPosition,
      Value<DateTime?> pulledAt,
      Value<int> rowid,
    });
typedef $$NodeCursorsTableUpdateCompanionBuilder =
    NodeCursorsCompanion Function({
      Value<String> serverDomain,
      Value<int> lastPosition,
      Value<DateTime?> pulledAt,
      Value<int> rowid,
    });

final class $$NodeCursorsTableReferences
    extends BaseReferences<_$AtrilDatabase, $NodeCursorsTable, NodeCursorRow> {
  $$NodeCursorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KnownServersTable _serverDomainTable(_$AtrilDatabase db) => db
      .knownServers
      .createAlias('node_cursors__server_domain__known_servers__domain');

  $$KnownServersTableProcessedTableManager get serverDomain {
    final $_column = $_itemColumn<String>('server_domain')!;

    final manager = $$KnownServersTableTableManager(
      $_db,
      $_db.knownServers,
    ).filter((f) => f.domain.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serverDomainTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodeCursorsTableFilterComposer
    extends Composer<_$AtrilDatabase, $NodeCursorsTable> {
  $$NodeCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lastPosition => $composableBuilder(
    column: $table.lastPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get pulledAt =>
      $composableBuilder(
        column: $table.pulledAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$KnownServersTableFilterComposer get serverDomain {
    final $$KnownServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverDomain,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.domain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnownServersTableFilterComposer(
            $db: $db,
            $table: $db.knownServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeCursorsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $NodeCursorsTable> {
  $$NodeCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lastPosition => $composableBuilder(
    column: $table.lastPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulledAt => $composableBuilder(
    column: $table.pulledAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$KnownServersTableOrderingComposer get serverDomain {
    final $$KnownServersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverDomain,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.domain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnownServersTableOrderingComposer(
            $db: $db,
            $table: $db.knownServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeCursorsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $NodeCursorsTable> {
  $$NodeCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lastPosition => $composableBuilder(
    column: $table.lastPosition,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get pulledAt =>
      $composableBuilder(column: $table.pulledAt, builder: (column) => column);

  $$KnownServersTableAnnotationComposer get serverDomain {
    final $$KnownServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverDomain,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.domain,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnownServersTableAnnotationComposer(
            $db: $db,
            $table: $db.knownServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeCursorsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $NodeCursorsTable,
          NodeCursorRow,
          $$NodeCursorsTableFilterComposer,
          $$NodeCursorsTableOrderingComposer,
          $$NodeCursorsTableAnnotationComposer,
          $$NodeCursorsTableCreateCompanionBuilder,
          $$NodeCursorsTableUpdateCompanionBuilder,
          (NodeCursorRow, $$NodeCursorsTableReferences),
          NodeCursorRow,
          PrefetchHooks Function({bool serverDomain})
        > {
  $$NodeCursorsTableTableManager(_$AtrilDatabase db, $NodeCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> serverDomain = const Value.absent(),
                Value<int> lastPosition = const Value.absent(),
                Value<DateTime?> pulledAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeCursorsCompanion(
                serverDomain: serverDomain,
                lastPosition: lastPosition,
                pulledAt: pulledAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverDomain,
                Value<int> lastPosition = const Value.absent(),
                Value<DateTime?> pulledAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeCursorsCompanion.insert(
                serverDomain: serverDomain,
                lastPosition: lastPosition,
                pulledAt: pulledAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NodeCursorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({serverDomain = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (serverDomain) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.serverDomain,
                        referencedTable: $$NodeCursorsTableReferences
                            ._serverDomainTable(db),
                        referencedColumn: $$NodeCursorsTableReferences
                            ._serverDomainTable(db)
                            .domain,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodeCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $NodeCursorsTable,
      NodeCursorRow,
      $$NodeCursorsTableFilterComposer,
      $$NodeCursorsTableOrderingComposer,
      $$NodeCursorsTableAnnotationComposer,
      $$NodeCursorsTableCreateCompanionBuilder,
      $$NodeCursorsTableUpdateCompanionBuilder,
      (NodeCursorRow, $$NodeCursorsTableReferences),
      NodeCursorRow,
      PrefetchHooks Function({bool serverDomain})
    >;
typedef $$AppliedOperationsTableCreateCompanionBuilder =
    AppliedOperationsCompanion Function({
      required String id,
      required DateTime appliedAt,
      Value<int> rowid,
    });
typedef $$AppliedOperationsTableUpdateCompanionBuilder =
    AppliedOperationsCompanion Function({
      Value<String> id,
      Value<DateTime> appliedAt,
      Value<int> rowid,
    });

class $$AppliedOperationsTableFilterComposer
    extends Composer<_$AtrilDatabase, $AppliedOperationsTable> {
  $$AppliedOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get appliedAt =>
      $composableBuilder(
        column: $table.appliedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$AppliedOperationsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $AppliedOperationsTable> {
  $$AppliedOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppliedOperationsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $AppliedOperationsTable> {
  $$AppliedOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);
}

class $$AppliedOperationsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $AppliedOperationsTable,
          AppliedOperationRow,
          $$AppliedOperationsTableFilterComposer,
          $$AppliedOperationsTableOrderingComposer,
          $$AppliedOperationsTableAnnotationComposer,
          $$AppliedOperationsTableCreateCompanionBuilder,
          $$AppliedOperationsTableUpdateCompanionBuilder,
          (
            AppliedOperationRow,
            BaseReferences<
              _$AtrilDatabase,
              $AppliedOperationsTable,
              AppliedOperationRow
            >,
          ),
          AppliedOperationRow,
          PrefetchHooks Function()
        > {
  $$AppliedOperationsTableTableManager(
    _$AtrilDatabase db,
    $AppliedOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppliedOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppliedOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppliedOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppliedOperationsCompanion(
                id: id,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime appliedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppliedOperationsCompanion.insert(
                id: id,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppliedOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $AppliedOperationsTable,
      AppliedOperationRow,
      $$AppliedOperationsTableFilterComposer,
      $$AppliedOperationsTableOrderingComposer,
      $$AppliedOperationsTableAnnotationComposer,
      $$AppliedOperationsTableCreateCompanionBuilder,
      $$AppliedOperationsTableUpdateCompanionBuilder,
      (
        AppliedOperationRow,
        BaseReferences<
          _$AtrilDatabase,
          $AppliedOperationsTable,
          AppliedOperationRow
        >,
      ),
      AppliedOperationRow,
      PrefetchHooks Function()
    >;
typedef $$RecordVersionsTableCreateCompanionBuilder =
    RecordVersionsCompanion Function({
      required String entity,
      required String identity,
      required String recordId,
      required VectorClock vectorClock,
      Value<int> rowid,
    });
typedef $$RecordVersionsTableUpdateCompanionBuilder =
    RecordVersionsCompanion Function({
      Value<String> entity,
      Value<String> identity,
      Value<String> recordId,
      Value<VectorClock> vectorClock,
      Value<int> rowid,
    });

class $$RecordVersionsTableFilterComposer
    extends Composer<_$AtrilDatabase, $RecordVersionsTable> {
  $$RecordVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identity => $composableBuilder(
    column: $table.identity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VectorClock, VectorClock, String>
  get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$RecordVersionsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $RecordVersionsTable> {
  $$RecordVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identity => $composableBuilder(
    column: $table.identity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vectorClock => $composableBuilder(
    column: $table.vectorClock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordVersionsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $RecordVersionsTable> {
  $$RecordVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get identity =>
      $composableBuilder(column: $table.identity, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VectorClock, String> get vectorClock =>
      $composableBuilder(
        column: $table.vectorClock,
        builder: (column) => column,
      );
}

class $$RecordVersionsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $RecordVersionsTable,
          RecordVersionRow,
          $$RecordVersionsTableFilterComposer,
          $$RecordVersionsTableOrderingComposer,
          $$RecordVersionsTableAnnotationComposer,
          $$RecordVersionsTableCreateCompanionBuilder,
          $$RecordVersionsTableUpdateCompanionBuilder,
          (
            RecordVersionRow,
            BaseReferences<
              _$AtrilDatabase,
              $RecordVersionsTable,
              RecordVersionRow
            >,
          ),
          RecordVersionRow,
          PrefetchHooks Function()
        > {
  $$RecordVersionsTableTableManager(
    _$AtrilDatabase db,
    $RecordVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> identity = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<VectorClock> vectorClock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordVersionsCompanion(
                entity: entity,
                identity: identity,
                recordId: recordId,
                vectorClock: vectorClock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String identity,
                required String recordId,
                required VectorClock vectorClock,
                Value<int> rowid = const Value.absent(),
              }) => RecordVersionsCompanion.insert(
                entity: entity,
                identity: identity,
                recordId: recordId,
                vectorClock: vectorClock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $RecordVersionsTable,
      RecordVersionRow,
      $$RecordVersionsTableFilterComposer,
      $$RecordVersionsTableOrderingComposer,
      $$RecordVersionsTableAnnotationComposer,
      $$RecordVersionsTableCreateCompanionBuilder,
      $$RecordVersionsTableUpdateCompanionBuilder,
      (
        RecordVersionRow,
        BaseReferences<_$AtrilDatabase, $RecordVersionsTable, RecordVersionRow>,
      ),
      RecordVersionRow,
      PrefetchHooks Function()
    >;
typedef $$ContentUploadsTableCreateCompanionBuilder =
    ContentUploadsCompanion Function({
      required String contentHash,
      required String mediaType,
      required int sizeBytes,
      Value<String?> uploadId,
      Value<int> sentBytes,
      required DateTime queuedAt,
      Value<DateTime?> attemptedAt,
      Value<String?> refusedCode,
      Value<int> attempts,
      Value<int> rowid,
    });
typedef $$ContentUploadsTableUpdateCompanionBuilder =
    ContentUploadsCompanion Function({
      Value<String> contentHash,
      Value<String> mediaType,
      Value<int> sizeBytes,
      Value<String?> uploadId,
      Value<int> sentBytes,
      Value<DateTime> queuedAt,
      Value<DateTime?> attemptedAt,
      Value<String?> refusedCode,
      Value<int> attempts,
      Value<int> rowid,
    });

class $$ContentUploadsTableFilterComposer
    extends Composer<_$AtrilDatabase, $ContentUploadsTable> {
  $$ContentUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentBytes => $composableBuilder(
    column: $table.sentBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get queuedAt =>
      $composableBuilder(
        column: $table.queuedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get attemptedAt =>
      $composableBuilder(
        column: $table.attemptedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get refusedCode => $composableBuilder(
    column: $table.refusedCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentUploadsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $ContentUploadsTable> {
  $$ContentUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentBytes => $composableBuilder(
    column: $table.sentBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refusedCode => $composableBuilder(
    column: $table.refusedCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentUploadsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $ContentUploadsTable> {
  $$ContentUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get uploadId =>
      $composableBuilder(column: $table.uploadId, builder: (column) => column);

  GeneratedColumn<int> get sentBytes =>
      $composableBuilder(column: $table.sentBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get attemptedAt =>
      $composableBuilder(
        column: $table.attemptedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get refusedCode => $composableBuilder(
    column: $table.refusedCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$ContentUploadsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $ContentUploadsTable,
          ContentUploadRow,
          $$ContentUploadsTableFilterComposer,
          $$ContentUploadsTableOrderingComposer,
          $$ContentUploadsTableAnnotationComposer,
          $$ContentUploadsTableCreateCompanionBuilder,
          $$ContentUploadsTableUpdateCompanionBuilder,
          (
            ContentUploadRow,
            BaseReferences<
              _$AtrilDatabase,
              $ContentUploadsTable,
              ContentUploadRow
            >,
          ),
          ContentUploadRow,
          PrefetchHooks Function()
        > {
  $$ContentUploadsTableTableManager(
    _$AtrilDatabase db,
    $ContentUploadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contentHash = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> uploadId = const Value.absent(),
                Value<int> sentBytes = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<DateTime?> attemptedAt = const Value.absent(),
                Value<String?> refusedCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentUploadsCompanion(
                contentHash: contentHash,
                mediaType: mediaType,
                sizeBytes: sizeBytes,
                uploadId: uploadId,
                sentBytes: sentBytes,
                queuedAt: queuedAt,
                attemptedAt: attemptedAt,
                refusedCode: refusedCode,
                attempts: attempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentHash,
                required String mediaType,
                required int sizeBytes,
                Value<String?> uploadId = const Value.absent(),
                Value<int> sentBytes = const Value.absent(),
                required DateTime queuedAt,
                Value<DateTime?> attemptedAt = const Value.absent(),
                Value<String?> refusedCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentUploadsCompanion.insert(
                contentHash: contentHash,
                mediaType: mediaType,
                sizeBytes: sizeBytes,
                uploadId: uploadId,
                sentBytes: sentBytes,
                queuedAt: queuedAt,
                attemptedAt: attemptedAt,
                refusedCode: refusedCode,
                attempts: attempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentUploadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $ContentUploadsTable,
      ContentUploadRow,
      $$ContentUploadsTableFilterComposer,
      $$ContentUploadsTableOrderingComposer,
      $$ContentUploadsTableAnnotationComposer,
      $$ContentUploadsTableCreateCompanionBuilder,
      $$ContentUploadsTableUpdateCompanionBuilder,
      (
        ContentUploadRow,
        BaseReferences<_$AtrilDatabase, $ContentUploadsTable, ContentUploadRow>,
      ),
      ContentUploadRow,
      PrefetchHooks Function()
    >;
typedef $$ContentPinsTableCreateCompanionBuilder =
    ContentPinsCompanion Function({
      required String contentHash,
      required bool kept,
      required DateTime decidedAt,
      Value<int> rowid,
    });
typedef $$ContentPinsTableUpdateCompanionBuilder =
    ContentPinsCompanion Function({
      Value<String> contentHash,
      Value<bool> kept,
      Value<DateTime> decidedAt,
      Value<int> rowid,
    });

class $$ContentPinsTableFilterComposer
    extends Composer<_$AtrilDatabase, $ContentPinsTable> {
  $$ContentPinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kept => $composableBuilder(
    column: $table.kept,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get decidedAt =>
      $composableBuilder(
        column: $table.decidedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ContentPinsTableOrderingComposer
    extends Composer<_$AtrilDatabase, $ContentPinsTable> {
  $$ContentPinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kept => $composableBuilder(
    column: $table.kept,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentPinsTableAnnotationComposer
    extends Composer<_$AtrilDatabase, $ContentPinsTable> {
  $$ContentPinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kept =>
      $composableBuilder(column: $table.kept, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);
}

class $$ContentPinsTableTableManager
    extends
        RootTableManager<
          _$AtrilDatabase,
          $ContentPinsTable,
          ContentPinRow,
          $$ContentPinsTableFilterComposer,
          $$ContentPinsTableOrderingComposer,
          $$ContentPinsTableAnnotationComposer,
          $$ContentPinsTableCreateCompanionBuilder,
          $$ContentPinsTableUpdateCompanionBuilder,
          (
            ContentPinRow,
            BaseReferences<_$AtrilDatabase, $ContentPinsTable, ContentPinRow>,
          ),
          ContentPinRow,
          PrefetchHooks Function()
        > {
  $$ContentPinsTableTableManager(_$AtrilDatabase db, $ContentPinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentPinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentPinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentPinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contentHash = const Value.absent(),
                Value<bool> kept = const Value.absent(),
                Value<DateTime> decidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPinsCompanion(
                contentHash: contentHash,
                kept: kept,
                decidedAt: decidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentHash,
                required bool kept,
                required DateTime decidedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentPinsCompanion.insert(
                contentHash: contentHash,
                kept: kept,
                decidedAt: decidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentPinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtrilDatabase,
      $ContentPinsTable,
      ContentPinRow,
      $$ContentPinsTableFilterComposer,
      $$ContentPinsTableOrderingComposer,
      $$ContentPinsTableAnnotationComposer,
      $$ContentPinsTableCreateCompanionBuilder,
      $$ContentPinsTableUpdateCompanionBuilder,
      (
        ContentPinRow,
        BaseReferences<_$AtrilDatabase, $ContentPinsTable, ContentPinRow>,
      ),
      ContentPinRow,
      PrefetchHooks Function()
    >;

class $AtrilDatabaseManager {
  final _$AtrilDatabase _db;
  $AtrilDatabaseManager(this._db);
  $$BoundDeviceTableTableManager get boundDevice =>
      $$BoundDeviceTableTableManager(_db, _db.boundDevice);
  $$KnownServersTableTableManager get knownServers =>
      $$KnownServersTableTableManager(_db, _db.knownServers);
  $$SignedInReaderTableTableManager get signedInReader =>
      $$SignedInReaderTableTableManager(_db, _db.signedInReader);
  $$ClockFloorTableTableManager get clockFloor =>
      $$ClockFloorTableTableManager(_db, _db.clockFloor);
  $$EbooksTableTableManager get ebooks =>
      $$EbooksTableTableManager(_db, _db.ebooks);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$EbookCollectionsTableTableManager get ebookCollections =>
      $$EbookCollectionsTableTableManager(_db, _db.ebookCollections);
  $$EbookCoversTableTableManager get ebookCovers =>
      $$EbookCoversTableTableManager(_db, _db.ebookCovers);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$ProgressTableTableManager get progress =>
      $$ProgressTableTableManager(_db, _db.progress);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
  $$NodeCursorsTableTableManager get nodeCursors =>
      $$NodeCursorsTableTableManager(_db, _db.nodeCursors);
  $$AppliedOperationsTableTableManager get appliedOperations =>
      $$AppliedOperationsTableTableManager(_db, _db.appliedOperations);
  $$RecordVersionsTableTableManager get recordVersions =>
      $$RecordVersionsTableTableManager(_db, _db.recordVersions);
  $$ContentUploadsTableTableManager get contentUploads =>
      $$ContentUploadsTableTableManager(_db, _db.contentUploads);
  $$ContentPinsTableTableManager get contentPins =>
      $$ContentPinsTableTableManager(_db, _db.contentPins);
}
