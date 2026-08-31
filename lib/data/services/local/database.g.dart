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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    id,
    domain,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
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
  /// The node's identifier as it names itself, in canonical lowercase text.
  final String id;

  /// The federation domain, which is the authority a lookup is addressed to and
  /// the second half of every identifier hosted there.
  final String domain;

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
    required this.id,
    required this.domain,
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
    map['id'] = Variable<String>(id);
    map['domain'] = Variable<String>(domain);
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
      id: Value(id),
      domain: Value(domain),
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
      id: serializer.fromJson<String>(json['id']),
      domain: serializer.fromJson<String>(json['domain']),
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
      'id': serializer.toJson<String>(id),
      'domain': serializer.toJson<String>(domain),
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
    String? id,
    String? domain,
    String? baseUrl,
    Value<String?> jwksUri = const Value.absent(),
    Value<String?> certificateFingerprint = const Value.absent(),
    Value<String?> grpcAuthority = const Value.absent(),
    bool? isOrigin,
    Value<DateTime?> discoveredAt = const Value.absent(),
    bool? active,
  }) => ServerRow(
    id: id ?? this.id,
    domain: domain ?? this.domain,
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
      id: data.id.present ? data.id.value : this.id,
      domain: data.domain.present ? data.domain.value : this.domain,
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
          ..write('id: $id, ')
          ..write('domain: $domain, ')
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
    id,
    domain,
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
          other.id == this.id &&
          other.domain == this.domain &&
          other.baseUrl == this.baseUrl &&
          other.jwksUri == this.jwksUri &&
          other.certificateFingerprint == this.certificateFingerprint &&
          other.grpcAuthority == this.grpcAuthority &&
          other.isOrigin == this.isOrigin &&
          other.discoveredAt == this.discoveredAt &&
          other.active == this.active);
}

class KnownServersCompanion extends UpdateCompanion<ServerRow> {
  final Value<String> id;
  final Value<String> domain;
  final Value<String> baseUrl;
  final Value<String?> jwksUri;
  final Value<String?> certificateFingerprint;
  final Value<String?> grpcAuthority;
  final Value<bool> isOrigin;
  final Value<DateTime?> discoveredAt;
  final Value<bool> active;
  final Value<int> rowid;
  const KnownServersCompanion({
    this.id = const Value.absent(),
    this.domain = const Value.absent(),
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
    required String id,
    required String domain,
    required String baseUrl,
    this.jwksUri = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.grpcAuthority = const Value.absent(),
    this.isOrigin = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       domain = Value(domain),
       baseUrl = Value(baseUrl);
  static Insertable<ServerRow> custom({
    Expression<String>? id,
    Expression<String>? domain,
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
      if (id != null) 'id': id,
      if (domain != null) 'domain': domain,
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
    Value<String>? id,
    Value<String>? domain,
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
      id: id ?? this.id,
      domain: domain ?? this.domain,
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
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
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
          ..write('id: $id, ')
          ..write('domain: $domain, ')
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
  static const VerificationMeta _originServerIdMeta = const VerificationMeta(
    'originServerId',
  );
  @override
  late final GeneratedColumn<String> originServerId = GeneratedColumn<String>(
    'origin_server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES known_servers (id) ON DELETE RESTRICT',
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
    originServerId,
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
    if (data.containsKey('origin_server_id')) {
      context.handle(
        _originServerIdMeta,
        originServerId.isAcceptableOrUnknown(
          data['origin_server_id']!,
          _originServerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originServerIdMeta);
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
      originServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_server_id'],
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
  final String originServerId;

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
    required this.originServerId,
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
    map['origin_server_id'] = Variable<String>(originServerId);
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
      originServerId: Value(originServerId),
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
      originServerId: serializer.fromJson<String>(json['originServerId']),
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
      'originServerId': serializer.toJson<String>(originServerId),
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
    String? originServerId,
    String? federatedId,
    Value<String?> email = const Value.absent(),
    DateTime? createdAt,
  }) => ReaderRow(
    onlyRow: onlyRow ?? this.onlyRow,
    id: id ?? this.id,
    localName: localName ?? this.localName,
    displayName: displayName ?? this.displayName,
    originServerId: originServerId ?? this.originServerId,
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
      originServerId: data.originServerId.present
          ? data.originServerId.value
          : this.originServerId,
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
          ..write('originServerId: $originServerId, ')
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
    originServerId,
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
          other.originServerId == this.originServerId &&
          other.federatedId == this.federatedId &&
          other.email == this.email &&
          other.createdAt == this.createdAt);
}

class SignedInReaderCompanion extends UpdateCompanion<ReaderRow> {
  final Value<int> onlyRow;
  final Value<String> id;
  final Value<String> localName;
  final Value<String> displayName;
  final Value<String> originServerId;
  final Value<String> federatedId;
  final Value<String?> email;
  final Value<DateTime> createdAt;
  const SignedInReaderCompanion({
    this.onlyRow = const Value.absent(),
    this.id = const Value.absent(),
    this.localName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.originServerId = const Value.absent(),
    this.federatedId = const Value.absent(),
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignedInReaderCompanion.insert({
    this.onlyRow = const Value.absent(),
    required String id,
    required String localName,
    required String displayName,
    required String originServerId,
    required String federatedId,
    this.email = const Value.absent(),
    required DateTime createdAt,
  }) : id = Value(id),
       localName = Value(localName),
       displayName = Value(displayName),
       originServerId = Value(originServerId),
       federatedId = Value(federatedId),
       createdAt = Value(createdAt);
  static Insertable<ReaderRow> custom({
    Expression<int>? onlyRow,
    Expression<String>? id,
    Expression<String>? localName,
    Expression<String>? displayName,
    Expression<String>? originServerId,
    Expression<String>? federatedId,
    Expression<String>? email,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (onlyRow != null) 'only_row': onlyRow,
      if (id != null) 'id': id,
      if (localName != null) 'local_name': localName,
      if (displayName != null) 'display_name': displayName,
      if (originServerId != null) 'origin_server_id': originServerId,
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
    Value<String>? originServerId,
    Value<String>? federatedId,
    Value<String?>? email,
    Value<DateTime>? createdAt,
  }) {
    return SignedInReaderCompanion(
      onlyRow: onlyRow ?? this.onlyRow,
      id: id ?? this.id,
      localName: localName ?? this.localName,
      displayName: displayName ?? this.displayName,
      originServerId: originServerId ?? this.originServerId,
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
    if (originServerId.present) {
      map['origin_server_id'] = Variable<String>(originServerId.value);
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
          ..write('originServerId: $originServerId, ')
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

abstract class _$AtrilDatabase extends GeneratedDatabase {
  _$AtrilDatabase(QueryExecutor e) : super(e);
  $AtrilDatabaseManager get managers => $AtrilDatabaseManager(this);
  late final $BoundDeviceTable boundDevice = $BoundDeviceTable(this);
  late final $KnownServersTable knownServers = $KnownServersTable(this);
  late final $SignedInReaderTable signedInReader = $SignedInReaderTable(this);
  late final $ClockFloorTable clockFloor = $ClockFloorTable(this);
  late final Index knownServersOrigin = Index(
    'known_servers_origin',
    'CREATE UNIQUE INDEX known_servers_origin ON known_servers (is_origin) WHERE is_origin',
  );
  late final IdentityDao identityDao = IdentityDao(this as AtrilDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    boundDevice,
    knownServers,
    signedInReader,
    clockFloor,
    knownServersOrigin,
  ];
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
      required String id,
      required String domain,
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
      Value<String> id,
      Value<String> domain,
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
    aliasName: 'known_servers__id__signed_in_reader__origin_server_id',
  );

  $$SignedInReaderTableProcessedTableManager get signedInReaderRefs {
    final manager = $$SignedInReaderTableTableManager(
      $_db,
      $_db.signedInReader,
    ).filter((f) => f.originServerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_signedInReaderRefsTable($_db));
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.signedInReader,
      getReferencedColumn: (t) => t.originServerId,
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.signedInReader,
      getReferencedColumn: (t) => t.originServerId,
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
          PrefetchHooks Function({bool signedInReaderRefs})
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
                Value<String> id = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String?> jwksUri = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String?> grpcAuthority = const Value.absent(),
                Value<bool> isOrigin = const Value.absent(),
                Value<DateTime?> discoveredAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownServersCompanion(
                id: id,
                domain: domain,
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
                required String id,
                required String domain,
                required String baseUrl,
                Value<String?> jwksUri = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<String?> grpcAuthority = const Value.absent(),
                Value<bool> isOrigin = const Value.absent(),
                Value<DateTime?> discoveredAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownServersCompanion.insert(
                id: id,
                domain: domain,
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
          prefetchHooksCallback: ({signedInReaderRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (signedInReaderRefs) db.signedInReader,
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.originServerId == item.id,
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
      PrefetchHooks Function({bool signedInReaderRefs})
    >;
typedef $$SignedInReaderTableCreateCompanionBuilder =
    SignedInReaderCompanion Function({
      Value<int> onlyRow,
      required String id,
      required String localName,
      required String displayName,
      required String originServerId,
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
      Value<String> originServerId,
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

  static $KnownServersTable _originServerIdTable(_$AtrilDatabase db) => db
      .knownServers
      .createAlias('signed_in_reader__origin_server_id__known_servers__id');

  $$KnownServersTableProcessedTableManager get originServerId {
    final $_column = $_itemColumn<String>('origin_server_id')!;

    final manager = $$KnownServersTableTableManager(
      $_db,
      $_db.knownServers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originServerIdTable($_db));
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

  $$KnownServersTableFilterComposer get originServerId {
    final $$KnownServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originServerId,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.id,
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

  $$KnownServersTableOrderingComposer get originServerId {
    final $$KnownServersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originServerId,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.id,
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

  $$KnownServersTableAnnotationComposer get originServerId {
    final $$KnownServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originServerId,
      referencedTable: $db.knownServers,
      getReferencedColumn: (t) => t.id,
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
          PrefetchHooks Function({bool originServerId})
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
                Value<String> originServerId = const Value.absent(),
                Value<String> federatedId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SignedInReaderCompanion(
                onlyRow: onlyRow,
                id: id,
                localName: localName,
                displayName: displayName,
                originServerId: originServerId,
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
                required String originServerId,
                required String federatedId,
                Value<String?> email = const Value.absent(),
                required DateTime createdAt,
              }) => SignedInReaderCompanion.insert(
                onlyRow: onlyRow,
                id: id,
                localName: localName,
                displayName: displayName,
                originServerId: originServerId,
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
          prefetchHooksCallback: ({originServerId = false}) {
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
                    if (originServerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.originServerId,
                        referencedTable: $$SignedInReaderTableReferences
                            ._originServerIdTable(db),
                        referencedColumn: $$SignedInReaderTableReferences
                            ._originServerIdTable(db)
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
      PrefetchHooks Function({bool originServerId})
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
}
