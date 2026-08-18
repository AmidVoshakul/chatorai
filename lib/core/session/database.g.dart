// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventDataMeta = const VerificationMeta(
    'eventData',
  );
  @override
  late final GeneratedColumn<String> eventData = GeneratedColumn<String>(
    'event_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    eventType,
    eventData,
    sequence,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_data')) {
      context.handle(
        _eventDataMeta,
        eventData.isAcceptableOrUnknown(data['event_data']!, _eventDataMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDataMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      eventData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_data'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final String sessionId;
  final String eventType;
  final String eventData;
  final int sequence;
  final DateTime createdAt;
  const Event({
    required this.id,
    required this.sessionId,
    required this.eventType,
    required this.eventData,
    required this.sequence,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['event_type'] = Variable<String>(eventType);
    map['event_data'] = Variable<String>(eventData);
    map['sequence'] = Variable<int>(sequence);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      eventType: Value(eventType),
      eventData: Value(eventData),
      sequence: Value(sequence),
      createdAt: Value(createdAt),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventData: serializer.fromJson<String>(json['eventData']),
      sequence: serializer.fromJson<int>(json['sequence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'eventType': serializer.toJson<String>(eventType),
      'eventData': serializer.toJson<String>(eventData),
      'sequence': serializer.toJson<int>(sequence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Event copyWith({
    int? id,
    String? sessionId,
    String? eventType,
    String? eventData,
    int? sequence,
    DateTime? createdAt,
  }) => Event(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    eventType: eventType ?? this.eventType,
    eventData: eventData ?? this.eventData,
    sequence: sequence ?? this.sequence,
    createdAt: createdAt ?? this.createdAt,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventData: data.eventData.present ? data.eventData.value : this.eventData,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventType: $eventType, ')
          ..write('eventData: $eventData, ')
          ..write('sequence: $sequence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, eventType, eventData, sequence, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.eventType == this.eventType &&
          other.eventData == this.eventData &&
          other.sequence == this.sequence &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> eventType;
  final Value<String> eventData;
  final Value<int> sequence;
  final Value<DateTime> createdAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventData = const Value.absent(),
    this.sequence = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String eventType,
    required String eventData,
    required int sequence,
    required DateTime createdAt,
  }) : sessionId = Value(sessionId),
       eventType = Value(eventType),
       eventData = Value(eventData),
       sequence = Value(sequence),
       createdAt = Value(createdAt);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? eventType,
    Expression<String>? eventData,
    Expression<int>? sequence,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (eventType != null) 'event_type': eventType,
      if (eventData != null) 'event_data': eventData,
      if (sequence != null) 'sequence': sequence,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? eventType,
    Value<String>? eventData,
    Value<int>? sequence,
    Value<DateTime>? createdAt,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      eventData: eventData ?? this.eventData,
      sequence: sequence ?? this.sequence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventData.present) {
      map['event_data'] = Variable<String>(eventData.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventType: $eventType, ')
          ..write('eventData: $eventData, ')
          ..write('sequence: $sequence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _modelRefMeta = const VerificationMeta(
    'modelRef',
  );
  @override
  late final GeneratedColumn<String> modelRef = GeneratedColumn<String>(
    'model_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _tokensInputMeta = const VerificationMeta(
    'tokensInput',
  );
  @override
  late final GeneratedColumn<int> tokensInput = GeneratedColumn<int>(
    'tokens_input',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensOutputMeta = const VerificationMeta(
    'tokensOutput',
  );
  @override
  late final GeneratedColumn<int> tokensOutput = GeneratedColumn<int>(
    'tokens_output',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensReasoningMeta = const VerificationMeta(
    'tokensReasoning',
  );
  @override
  late final GeneratedColumn<int> tokensReasoning = GeneratedColumn<int>(
    'tokens_reasoning',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensCacheReadMeta = const VerificationMeta(
    'tokensCacheRead',
  );
  @override
  late final GeneratedColumn<int> tokensCacheRead = GeneratedColumn<int>(
    'tokens_cache_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensCacheWriteMeta = const VerificationMeta(
    'tokensCacheWrite',
  );
  @override
  late final GeneratedColumn<int> tokensCacheWrite = GeneratedColumn<int>(
    'tokens_cache_write',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _permissionRulesMeta = const VerificationMeta(
    'permissionRules',
  );
  @override
  late final GeneratedColumn<String> permissionRules = GeneratedColumn<String>(
    'permission_rules',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directoryMeta = const VerificationMeta(
    'directory',
  );
  @override
  late final GeneratedColumn<String> directory = GeneratedColumn<String>(
    'directory',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    title,
    agent,
    modelRef,
    cost,
    tokensInput,
    tokensOutput,
    tokensReasoning,
    tokensCacheRead,
    tokensCacheWrite,
    permissionRules,
    directory,
    createdAt,
    updatedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('agent')) {
      context.handle(
        _agentMeta,
        agent.isAcceptableOrUnknown(data['agent']!, _agentMeta),
      );
    }
    if (data.containsKey('model_ref')) {
      context.handle(
        _modelRefMeta,
        modelRef.isAcceptableOrUnknown(data['model_ref']!, _modelRefMeta),
      );
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('tokens_input')) {
      context.handle(
        _tokensInputMeta,
        tokensInput.isAcceptableOrUnknown(
          data['tokens_input']!,
          _tokensInputMeta,
        ),
      );
    }
    if (data.containsKey('tokens_output')) {
      context.handle(
        _tokensOutputMeta,
        tokensOutput.isAcceptableOrUnknown(
          data['tokens_output']!,
          _tokensOutputMeta,
        ),
      );
    }
    if (data.containsKey('tokens_reasoning')) {
      context.handle(
        _tokensReasoningMeta,
        tokensReasoning.isAcceptableOrUnknown(
          data['tokens_reasoning']!,
          _tokensReasoningMeta,
        ),
      );
    }
    if (data.containsKey('tokens_cache_read')) {
      context.handle(
        _tokensCacheReadMeta,
        tokensCacheRead.isAcceptableOrUnknown(
          data['tokens_cache_read']!,
          _tokensCacheReadMeta,
        ),
      );
    }
    if (data.containsKey('tokens_cache_write')) {
      context.handle(
        _tokensCacheWriteMeta,
        tokensCacheWrite.isAcceptableOrUnknown(
          data['tokens_cache_write']!,
          _tokensCacheWriteMeta,
        ),
      );
    }
    if (data.containsKey('permission_rules')) {
      context.handle(
        _permissionRulesMeta,
        permissionRules.isAcceptableOrUnknown(
          data['permission_rules']!,
          _permissionRulesMeta,
        ),
      );
    }
    if (data.containsKey('directory')) {
      context.handle(
        _directoryMeta,
        directory.isAcceptableOrUnknown(data['directory']!, _directoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      )!,
      modelRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_ref'],
      ),
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
      tokensInput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_input'],
      )!,
      tokensOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_output'],
      )!,
      tokensReasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_reasoning'],
      )!,
      tokensCacheRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_cache_read'],
      )!,
      tokensCacheWrite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_cache_write'],
      )!,
      permissionRules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission_rules'],
      ),
      directory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directory'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String? parentId;
  final String title;
  final String agent;
  final String? modelRef;
  final double cost;
  final int tokensInput;
  final int tokensOutput;
  final int tokensReasoning;
  final int tokensCacheRead;
  final int tokensCacheWrite;
  final String? permissionRules;
  final String? directory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  const Session({
    required this.id,
    this.parentId,
    required this.title,
    required this.agent,
    this.modelRef,
    required this.cost,
    required this.tokensInput,
    required this.tokensOutput,
    required this.tokensReasoning,
    required this.tokensCacheRead,
    required this.tokensCacheWrite,
    this.permissionRules,
    this.directory,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['title'] = Variable<String>(title);
    map['agent'] = Variable<String>(agent);
    if (!nullToAbsent || modelRef != null) {
      map['model_ref'] = Variable<String>(modelRef);
    }
    map['cost'] = Variable<double>(cost);
    map['tokens_input'] = Variable<int>(tokensInput);
    map['tokens_output'] = Variable<int>(tokensOutput);
    map['tokens_reasoning'] = Variable<int>(tokensReasoning);
    map['tokens_cache_read'] = Variable<int>(tokensCacheRead);
    map['tokens_cache_write'] = Variable<int>(tokensCacheWrite);
    if (!nullToAbsent || permissionRules != null) {
      map['permission_rules'] = Variable<String>(permissionRules);
    }
    if (!nullToAbsent || directory != null) {
      map['directory'] = Variable<String>(directory);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      title: Value(title),
      agent: Value(agent),
      modelRef: modelRef == null && nullToAbsent
          ? const Value.absent()
          : Value(modelRef),
      cost: Value(cost),
      tokensInput: Value(tokensInput),
      tokensOutput: Value(tokensOutput),
      tokensReasoning: Value(tokensReasoning),
      tokensCacheRead: Value(tokensCacheRead),
      tokensCacheWrite: Value(tokensCacheWrite),
      permissionRules: permissionRules == null && nullToAbsent
          ? const Value.absent()
          : Value(permissionRules),
      directory: directory == null && nullToAbsent
          ? const Value.absent()
          : Value(directory),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      title: serializer.fromJson<String>(json['title']),
      agent: serializer.fromJson<String>(json['agent']),
      modelRef: serializer.fromJson<String?>(json['modelRef']),
      cost: serializer.fromJson<double>(json['cost']),
      tokensInput: serializer.fromJson<int>(json['tokensInput']),
      tokensOutput: serializer.fromJson<int>(json['tokensOutput']),
      tokensReasoning: serializer.fromJson<int>(json['tokensReasoning']),
      tokensCacheRead: serializer.fromJson<int>(json['tokensCacheRead']),
      tokensCacheWrite: serializer.fromJson<int>(json['tokensCacheWrite']),
      permissionRules: serializer.fromJson<String?>(json['permissionRules']),
      directory: serializer.fromJson<String?>(json['directory']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'title': serializer.toJson<String>(title),
      'agent': serializer.toJson<String>(agent),
      'modelRef': serializer.toJson<String?>(modelRef),
      'cost': serializer.toJson<double>(cost),
      'tokensInput': serializer.toJson<int>(tokensInput),
      'tokensOutput': serializer.toJson<int>(tokensOutput),
      'tokensReasoning': serializer.toJson<int>(tokensReasoning),
      'tokensCacheRead': serializer.toJson<int>(tokensCacheRead),
      'tokensCacheWrite': serializer.toJson<int>(tokensCacheWrite),
      'permissionRules': serializer.toJson<String?>(permissionRules),
      'directory': serializer.toJson<String?>(directory),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  Session copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? title,
    String? agent,
    Value<String?> modelRef = const Value.absent(),
    double? cost,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    int? tokensCacheRead,
    int? tokensCacheWrite,
    Value<String?> permissionRules = const Value.absent(),
    Value<String?> directory = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    title: title ?? this.title,
    agent: agent ?? this.agent,
    modelRef: modelRef.present ? modelRef.value : this.modelRef,
    cost: cost ?? this.cost,
    tokensInput: tokensInput ?? this.tokensInput,
    tokensOutput: tokensOutput ?? this.tokensOutput,
    tokensReasoning: tokensReasoning ?? this.tokensReasoning,
    tokensCacheRead: tokensCacheRead ?? this.tokensCacheRead,
    tokensCacheWrite: tokensCacheWrite ?? this.tokensCacheWrite,
    permissionRules: permissionRules.present
        ? permissionRules.value
        : this.permissionRules,
    directory: directory.present ? directory.value : this.directory,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      title: data.title.present ? data.title.value : this.title,
      agent: data.agent.present ? data.agent.value : this.agent,
      modelRef: data.modelRef.present ? data.modelRef.value : this.modelRef,
      cost: data.cost.present ? data.cost.value : this.cost,
      tokensInput: data.tokensInput.present
          ? data.tokensInput.value
          : this.tokensInput,
      tokensOutput: data.tokensOutput.present
          ? data.tokensOutput.value
          : this.tokensOutput,
      tokensReasoning: data.tokensReasoning.present
          ? data.tokensReasoning.value
          : this.tokensReasoning,
      tokensCacheRead: data.tokensCacheRead.present
          ? data.tokensCacheRead.value
          : this.tokensCacheRead,
      tokensCacheWrite: data.tokensCacheWrite.present
          ? data.tokensCacheWrite.value
          : this.tokensCacheWrite,
      permissionRules: data.permissionRules.present
          ? data.permissionRules.value
          : this.permissionRules,
      directory: data.directory.present ? data.directory.value : this.directory,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('agent: $agent, ')
          ..write('modelRef: $modelRef, ')
          ..write('cost: $cost, ')
          ..write('tokensInput: $tokensInput, ')
          ..write('tokensOutput: $tokensOutput, ')
          ..write('tokensReasoning: $tokensReasoning, ')
          ..write('tokensCacheRead: $tokensCacheRead, ')
          ..write('tokensCacheWrite: $tokensCacheWrite, ')
          ..write('permissionRules: $permissionRules, ')
          ..write('directory: $directory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    title,
    agent,
    modelRef,
    cost,
    tokensInput,
    tokensOutput,
    tokensReasoning,
    tokensCacheRead,
    tokensCacheWrite,
    permissionRules,
    directory,
    createdAt,
    updatedAt,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.title == this.title &&
          other.agent == this.agent &&
          other.modelRef == this.modelRef &&
          other.cost == this.cost &&
          other.tokensInput == this.tokensInput &&
          other.tokensOutput == this.tokensOutput &&
          other.tokensReasoning == this.tokensReasoning &&
          other.tokensCacheRead == this.tokensCacheRead &&
          other.tokensCacheWrite == this.tokensCacheWrite &&
          other.permissionRules == this.permissionRules &&
          other.directory == this.directory &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> title;
  final Value<String> agent;
  final Value<String?> modelRef;
  final Value<double> cost;
  final Value<int> tokensInput;
  final Value<int> tokensOutput;
  final Value<int> tokensReasoning;
  final Value<int> tokensCacheRead;
  final Value<int> tokensCacheWrite;
  final Value<String?> permissionRules;
  final Value<String?> directory;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.title = const Value.absent(),
    this.agent = const Value.absent(),
    this.modelRef = const Value.absent(),
    this.cost = const Value.absent(),
    this.tokensInput = const Value.absent(),
    this.tokensOutput = const Value.absent(),
    this.tokensReasoning = const Value.absent(),
    this.tokensCacheRead = const Value.absent(),
    this.tokensCacheWrite = const Value.absent(),
    this.permissionRules = const Value.absent(),
    this.directory = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    this.title = const Value.absent(),
    this.agent = const Value.absent(),
    this.modelRef = const Value.absent(),
    this.cost = const Value.absent(),
    this.tokensInput = const Value.absent(),
    this.tokensOutput = const Value.absent(),
    this.tokensReasoning = const Value.absent(),
    this.tokensCacheRead = const Value.absent(),
    this.tokensCacheWrite = const Value.absent(),
    this.permissionRules = const Value.absent(),
    this.directory = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? title,
    Expression<String>? agent,
    Expression<String>? modelRef,
    Expression<double>? cost,
    Expression<int>? tokensInput,
    Expression<int>? tokensOutput,
    Expression<int>? tokensReasoning,
    Expression<int>? tokensCacheRead,
    Expression<int>? tokensCacheWrite,
    Expression<String>? permissionRules,
    Expression<String>? directory,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (title != null) 'title': title,
      if (agent != null) 'agent': agent,
      if (modelRef != null) 'model_ref': modelRef,
      if (cost != null) 'cost': cost,
      if (tokensInput != null) 'tokens_input': tokensInput,
      if (tokensOutput != null) 'tokens_output': tokensOutput,
      if (tokensReasoning != null) 'tokens_reasoning': tokensReasoning,
      if (tokensCacheRead != null) 'tokens_cache_read': tokensCacheRead,
      if (tokensCacheWrite != null) 'tokens_cache_write': tokensCacheWrite,
      if (permissionRules != null) 'permission_rules': permissionRules,
      if (directory != null) 'directory': directory,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? title,
    Value<String>? agent,
    Value<String?>? modelRef,
    Value<double>? cost,
    Value<int>? tokensInput,
    Value<int>? tokensOutput,
    Value<int>? tokensReasoning,
    Value<int>? tokensCacheRead,
    Value<int>? tokensCacheWrite,
    Value<String?>? permissionRules,
    Value<String?>? directory,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      agent: agent ?? this.agent,
      modelRef: modelRef ?? this.modelRef,
      cost: cost ?? this.cost,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      tokensCacheRead: tokensCacheRead ?? this.tokensCacheRead,
      tokensCacheWrite: tokensCacheWrite ?? this.tokensCacheWrite,
      permissionRules: permissionRules ?? this.permissionRules,
      directory: directory ?? this.directory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    if (modelRef.present) {
      map['model_ref'] = Variable<String>(modelRef.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (tokensInput.present) {
      map['tokens_input'] = Variable<int>(tokensInput.value);
    }
    if (tokensOutput.present) {
      map['tokens_output'] = Variable<int>(tokensOutput.value);
    }
    if (tokensReasoning.present) {
      map['tokens_reasoning'] = Variable<int>(tokensReasoning.value);
    }
    if (tokensCacheRead.present) {
      map['tokens_cache_read'] = Variable<int>(tokensCacheRead.value);
    }
    if (tokensCacheWrite.present) {
      map['tokens_cache_write'] = Variable<int>(tokensCacheWrite.value);
    }
    if (permissionRules.present) {
      map['permission_rules'] = Variable<String>(permissionRules.value);
    }
    if (directory.present) {
      map['directory'] = Variable<String>(directory.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('agent: $agent, ')
          ..write('modelRef: $modelRef, ')
          ..write('cost: $cost, ')
          ..write('tokensInput: $tokensInput, ')
          ..write('tokensOutput: $tokensOutput, ')
          ..write('tokensReasoning: $tokensReasoning, ')
          ..write('tokensCacheRead: $tokensCacheRead, ')
          ..write('tokensCacheWrite: $tokensCacheWrite, ')
          ..write('permissionRules: $permissionRules, ')
          ..write('directory: $directory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasoningMeta = const VerificationMeta(
    'reasoning',
  );
  @override
  late final GeneratedColumn<String> reasoning = GeneratedColumn<String>(
    'reasoning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensInputMeta = const VerificationMeta(
    'tokensInput',
  );
  @override
  late final GeneratedColumn<int> tokensInput = GeneratedColumn<int>(
    'tokens_input',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensOutputMeta = const VerificationMeta(
    'tokensOutput',
  );
  @override
  late final GeneratedColumn<int> tokensOutput = GeneratedColumn<int>(
    'tokens_output',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensReasoningMeta = const VerificationMeta(
    'tokensReasoning',
  );
  @override
  late final GeneratedColumn<int> tokensReasoning = GeneratedColumn<int>(
    'tokens_reasoning',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    role,
    content,
    model,
    reasoning,
    error,
    tokensInput,
    tokensOutput,
    tokensReasoning,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('reasoning')) {
      context.handle(
        _reasoningMeta,
        reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('tokens_input')) {
      context.handle(
        _tokensInputMeta,
        tokensInput.isAcceptableOrUnknown(
          data['tokens_input']!,
          _tokensInputMeta,
        ),
      );
    }
    if (data.containsKey('tokens_output')) {
      context.handle(
        _tokensOutputMeta,
        tokensOutput.isAcceptableOrUnknown(
          data['tokens_output']!,
          _tokensOutputMeta,
        ),
      );
    }
    if (data.containsKey('tokens_reasoning')) {
      context.handle(
        _tokensReasoningMeta,
        tokensReasoning.isAcceptableOrUnknown(
          data['tokens_reasoning']!,
          _tokensReasoningMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      reasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      tokensInput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_input'],
      )!,
      tokensOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_output'],
      )!,
      tokensReasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_reasoning'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String sessionId;
  final int seq;
  final String role;
  final String content;
  final String? model;
  final String? reasoning;
  final String? error;
  final int tokensInput;
  final int tokensOutput;
  final int tokensReasoning;
  final DateTime createdAt;
  const Message({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.role,
    required this.content,
    this.model,
    this.reasoning,
    this.error,
    required this.tokensInput,
    required this.tokensOutput,
    required this.tokensReasoning,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || reasoning != null) {
      map['reasoning'] = Variable<String>(reasoning);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['tokens_input'] = Variable<int>(tokensInput);
    map['tokens_output'] = Variable<int>(tokensOutput);
    map['tokens_reasoning'] = Variable<int>(tokensReasoning);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      role: Value(role),
      content: Value(content),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      reasoning: reasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoning),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      tokensInput: Value(tokensInput),
      tokensOutput: Value(tokensOutput),
      tokensReasoning: Value(tokensReasoning),
      createdAt: Value(createdAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      model: serializer.fromJson<String?>(json['model']),
      reasoning: serializer.fromJson<String?>(json['reasoning']),
      error: serializer.fromJson<String?>(json['error']),
      tokensInput: serializer.fromJson<int>(json['tokensInput']),
      tokensOutput: serializer.fromJson<int>(json['tokensOutput']),
      tokensReasoning: serializer.fromJson<int>(json['tokensReasoning']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'model': serializer.toJson<String?>(model),
      'reasoning': serializer.toJson<String?>(reasoning),
      'error': serializer.toJson<String?>(error),
      'tokensInput': serializer.toJson<int>(tokensInput),
      'tokensOutput': serializer.toJson<int>(tokensOutput),
      'tokensReasoning': serializer.toJson<int>(tokensReasoning),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Message copyWith({
    String? id,
    String? sessionId,
    int? seq,
    String? role,
    String? content,
    Value<String?> model = const Value.absent(),
    Value<String?> reasoning = const Value.absent(),
    Value<String?> error = const Value.absent(),
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    DateTime? createdAt,
  }) => Message(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    content: content ?? this.content,
    model: model.present ? model.value : this.model,
    reasoning: reasoning.present ? reasoning.value : this.reasoning,
    error: error.present ? error.value : this.error,
    tokensInput: tokensInput ?? this.tokensInput,
    tokensOutput: tokensOutput ?? this.tokensOutput,
    tokensReasoning: tokensReasoning ?? this.tokensReasoning,
    createdAt: createdAt ?? this.createdAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      model: data.model.present ? data.model.value : this.model,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      error: data.error.present ? data.error.value : this.error,
      tokensInput: data.tokensInput.present
          ? data.tokensInput.value
          : this.tokensInput,
      tokensOutput: data.tokensOutput.present
          ? data.tokensOutput.value
          : this.tokensOutput,
      tokensReasoning: data.tokensReasoning.present
          ? data.tokensReasoning.value
          : this.tokensReasoning,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('model: $model, ')
          ..write('reasoning: $reasoning, ')
          ..write('error: $error, ')
          ..write('tokensInput: $tokensInput, ')
          ..write('tokensOutput: $tokensOutput, ')
          ..write('tokensReasoning: $tokensReasoning, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    role,
    content,
    model,
    reasoning,
    error,
    tokensInput,
    tokensOutput,
    tokensReasoning,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.content == this.content &&
          other.model == this.model &&
          other.reasoning == this.reasoning &&
          other.error == this.error &&
          other.tokensInput == this.tokensInput &&
          other.tokensOutput == this.tokensOutput &&
          other.tokensReasoning == this.tokensReasoning &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> model;
  final Value<String?> reasoning;
  final Value<String?> error;
  final Value<int> tokensInput;
  final Value<int> tokensOutput;
  final Value<int> tokensReasoning;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.model = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.error = const Value.absent(),
    this.tokensInput = const Value.absent(),
    this.tokensOutput = const Value.absent(),
    this.tokensReasoning = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String sessionId,
    required int seq,
    required String role,
    this.content = const Value.absent(),
    this.model = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.error = const Value.absent(),
    this.tokensInput = const Value.absent(),
    this.tokensOutput = const Value.absent(),
    this.tokensReasoning = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       seq = Value(seq),
       role = Value(role),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? model,
    Expression<String>? reasoning,
    Expression<String>? error,
    Expression<int>? tokensInput,
    Expression<int>? tokensOutput,
    Expression<int>? tokensReasoning,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (model != null) 'model': model,
      if (reasoning != null) 'reasoning': reasoning,
      if (error != null) 'error': error,
      if (tokensInput != null) 'tokens_input': tokensInput,
      if (tokensOutput != null) 'tokens_output': tokensOutput,
      if (tokensReasoning != null) 'tokens_reasoning': tokensReasoning,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? model,
    Value<String?>? reasoning,
    Value<String?>? error,
    Value<int>? tokensInput,
    Value<int>? tokensOutput,
    Value<int>? tokensReasoning,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      content: content ?? this.content,
      model: model ?? this.model,
      reasoning: reasoning ?? this.reasoning,
      error: error ?? this.error,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<String>(reasoning.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (tokensInput.present) {
      map['tokens_input'] = Variable<int>(tokensInput.value);
    }
    if (tokensOutput.present) {
      map['tokens_output'] = Variable<int>(tokensOutput.value);
    }
    if (tokensReasoning.present) {
      map['tokens_reasoning'] = Variable<int>(tokensReasoning.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('model: $model, ')
          ..write('reasoning: $reasoning, ')
          ..write('error: $error, ')
          ..write('tokensInput: $tokensInput, ')
          ..write('tokensOutput: $tokensOutput, ')
          ..write('tokensReasoning: $tokensReasoning, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ToolResultsTable extends ToolResults
    with TableInfo<$ToolResultsTable, ToolResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToolResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolNameMeta = const VerificationMeta(
    'toolName',
  );
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
    'tool_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputJsonMeta = const VerificationMeta(
    'inputJson',
  );
  @override
  late final GeneratedColumn<String> inputJson = GeneratedColumn<String>(
    'input_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _outputTextMeta = const VerificationMeta(
    'outputText',
  );
  @override
  late final GeneratedColumn<String> outputText = GeneratedColumn<String>(
    'output_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('success'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    messageId,
    toolName,
    inputJson,
    outputText,
    durationMs,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tool_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ToolResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('tool_name')) {
      context.handle(
        _toolNameMeta,
        toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta),
      );
    } else if (isInserting) {
      context.missing(_toolNameMeta);
    }
    if (data.containsKey('input_json')) {
      context.handle(
        _inputJsonMeta,
        inputJson.isAcceptableOrUnknown(data['input_json']!, _inputJsonMeta),
      );
    }
    if (data.containsKey('output_text')) {
      context.handle(
        _outputTextMeta,
        outputText.isAcceptableOrUnknown(data['output_text']!, _outputTextMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ToolResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToolResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      toolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_name'],
      )!,
      inputJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_json'],
      )!,
      outputText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_text'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ToolResultsTable createAlias(String alias) {
    return $ToolResultsTable(attachedDatabase, alias);
  }
}

class ToolResult extends DataClass implements Insertable<ToolResult> {
  final String id;
  final String sessionId;
  final String messageId;
  final String toolName;
  final String inputJson;
  final String outputText;
  final int durationMs;
  final String status;
  final DateTime createdAt;
  const ToolResult({
    required this.id,
    required this.sessionId,
    required this.messageId,
    required this.toolName,
    required this.inputJson,
    required this.outputText,
    required this.durationMs,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['message_id'] = Variable<String>(messageId);
    map['tool_name'] = Variable<String>(toolName);
    map['input_json'] = Variable<String>(inputJson);
    map['output_text'] = Variable<String>(outputText);
    map['duration_ms'] = Variable<int>(durationMs);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ToolResultsCompanion toCompanion(bool nullToAbsent) {
    return ToolResultsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      messageId: Value(messageId),
      toolName: Value(toolName),
      inputJson: Value(inputJson),
      outputText: Value(outputText),
      durationMs: Value(durationMs),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory ToolResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToolResult(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      toolName: serializer.fromJson<String>(json['toolName']),
      inputJson: serializer.fromJson<String>(json['inputJson']),
      outputText: serializer.fromJson<String>(json['outputText']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'messageId': serializer.toJson<String>(messageId),
      'toolName': serializer.toJson<String>(toolName),
      'inputJson': serializer.toJson<String>(inputJson),
      'outputText': serializer.toJson<String>(outputText),
      'durationMs': serializer.toJson<int>(durationMs),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ToolResult copyWith({
    String? id,
    String? sessionId,
    String? messageId,
    String? toolName,
    String? inputJson,
    String? outputText,
    int? durationMs,
    String? status,
    DateTime? createdAt,
  }) => ToolResult(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    messageId: messageId ?? this.messageId,
    toolName: toolName ?? this.toolName,
    inputJson: inputJson ?? this.inputJson,
    outputText: outputText ?? this.outputText,
    durationMs: durationMs ?? this.durationMs,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  ToolResult copyWithCompanion(ToolResultsCompanion data) {
    return ToolResult(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      inputJson: data.inputJson.present ? data.inputJson.value : this.inputJson,
      outputText: data.outputText.present
          ? data.outputText.value
          : this.outputText,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToolResult(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('toolName: $toolName, ')
          ..write('inputJson: $inputJson, ')
          ..write('outputText: $outputText, ')
          ..write('durationMs: $durationMs, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    messageId,
    toolName,
    inputJson,
    outputText,
    durationMs,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolResult &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.messageId == this.messageId &&
          other.toolName == this.toolName &&
          other.inputJson == this.inputJson &&
          other.outputText == this.outputText &&
          other.durationMs == this.durationMs &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class ToolResultsCompanion extends UpdateCompanion<ToolResult> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> messageId;
  final Value<String> toolName;
  final Value<String> inputJson;
  final Value<String> outputText;
  final Value<int> durationMs;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ToolResultsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.toolName = const Value.absent(),
    this.inputJson = const Value.absent(),
    this.outputText = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ToolResultsCompanion.insert({
    required String id,
    required String sessionId,
    required String messageId,
    required String toolName,
    this.inputJson = const Value.absent(),
    this.outputText = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       messageId = Value(messageId),
       toolName = Value(toolName),
       createdAt = Value(createdAt);
  static Insertable<ToolResult> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? messageId,
    Expression<String>? toolName,
    Expression<String>? inputJson,
    Expression<String>? outputText,
    Expression<int>? durationMs,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (messageId != null) 'message_id': messageId,
      if (toolName != null) 'tool_name': toolName,
      if (inputJson != null) 'input_json': inputJson,
      if (outputText != null) 'output_text': outputText,
      if (durationMs != null) 'duration_ms': durationMs,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ToolResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? messageId,
    Value<String>? toolName,
    Value<String>? inputJson,
    Value<String>? outputText,
    Value<int>? durationMs,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ToolResultsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      toolName: toolName ?? this.toolName,
      inputJson: inputJson ?? this.inputJson,
      outputText: outputText ?? this.outputText,
      durationMs: durationMs ?? this.durationMs,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (inputJson.present) {
      map['input_json'] = Variable<String>(inputJson.value);
    }
    if (outputText.present) {
      map['output_text'] = Variable<String>(outputText.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToolResultsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('toolName: $toolName, ')
          ..write('inputJson: $inputJson, ')
          ..write('outputText: $outputText, ')
          ..write('durationMs: $durationMs, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextEpochsTable extends ContextEpochs
    with TableInfo<$ContextEpochsTable, ContextEpoch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextEpochsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptTextMeta = const VerificationMeta(
    'promptText',
  );
  @override
  late final GeneratedColumn<String> promptText = GeneratedColumn<String>(
    'prompt_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _modelRefMeta = const VerificationMeta(
    'modelRef',
  );
  @override
  late final GeneratedColumn<String> modelRef = GeneratedColumn<String>(
    'model_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    revision,
    promptText,
    agent,
    modelRef,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_epochs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContextEpoch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('prompt_text')) {
      context.handle(
        _promptTextMeta,
        promptText.isAcceptableOrUnknown(data['prompt_text']!, _promptTextMeta),
      );
    }
    if (data.containsKey('agent')) {
      context.handle(
        _agentMeta,
        agent.isAcceptableOrUnknown(data['agent']!, _agentMeta),
      );
    }
    if (data.containsKey('model_ref')) {
      context.handle(
        _modelRefMeta,
        modelRef.isAcceptableOrUnknown(data['model_ref']!, _modelRefMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContextEpoch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextEpoch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      promptText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_text'],
      )!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      )!,
      modelRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_ref'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContextEpochsTable createAlias(String alias) {
    return $ContextEpochsTable(attachedDatabase, alias);
  }
}

class ContextEpoch extends DataClass implements Insertable<ContextEpoch> {
  final String id;
  final String sessionId;
  final int revision;
  final String promptText;
  final String agent;
  final String? modelRef;
  final DateTime createdAt;
  const ContextEpoch({
    required this.id,
    required this.sessionId,
    required this.revision,
    required this.promptText,
    required this.agent,
    this.modelRef,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['revision'] = Variable<int>(revision);
    map['prompt_text'] = Variable<String>(promptText);
    map['agent'] = Variable<String>(agent);
    if (!nullToAbsent || modelRef != null) {
      map['model_ref'] = Variable<String>(modelRef);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContextEpochsCompanion toCompanion(bool nullToAbsent) {
    return ContextEpochsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      revision: Value(revision),
      promptText: Value(promptText),
      agent: Value(agent),
      modelRef: modelRef == null && nullToAbsent
          ? const Value.absent()
          : Value(modelRef),
      createdAt: Value(createdAt),
    );
  }

  factory ContextEpoch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextEpoch(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      revision: serializer.fromJson<int>(json['revision']),
      promptText: serializer.fromJson<String>(json['promptText']),
      agent: serializer.fromJson<String>(json['agent']),
      modelRef: serializer.fromJson<String?>(json['modelRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'revision': serializer.toJson<int>(revision),
      'promptText': serializer.toJson<String>(promptText),
      'agent': serializer.toJson<String>(agent),
      'modelRef': serializer.toJson<String?>(modelRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ContextEpoch copyWith({
    String? id,
    String? sessionId,
    int? revision,
    String? promptText,
    String? agent,
    Value<String?> modelRef = const Value.absent(),
    DateTime? createdAt,
  }) => ContextEpoch(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    revision: revision ?? this.revision,
    promptText: promptText ?? this.promptText,
    agent: agent ?? this.agent,
    modelRef: modelRef.present ? modelRef.value : this.modelRef,
    createdAt: createdAt ?? this.createdAt,
  );
  ContextEpoch copyWithCompanion(ContextEpochsCompanion data) {
    return ContextEpoch(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      revision: data.revision.present ? data.revision.value : this.revision,
      promptText: data.promptText.present
          ? data.promptText.value
          : this.promptText,
      agent: data.agent.present ? data.agent.value : this.agent,
      modelRef: data.modelRef.present ? data.modelRef.value : this.modelRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContextEpoch(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('revision: $revision, ')
          ..write('promptText: $promptText, ')
          ..write('agent: $agent, ')
          ..write('modelRef: $modelRef, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    revision,
    promptText,
    agent,
    modelRef,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextEpoch &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.revision == this.revision &&
          other.promptText == this.promptText &&
          other.agent == this.agent &&
          other.modelRef == this.modelRef &&
          other.createdAt == this.createdAt);
}

class ContextEpochsCompanion extends UpdateCompanion<ContextEpoch> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> revision;
  final Value<String> promptText;
  final Value<String> agent;
  final Value<String?> modelRef;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ContextEpochsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.revision = const Value.absent(),
    this.promptText = const Value.absent(),
    this.agent = const Value.absent(),
    this.modelRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextEpochsCompanion.insert({
    required String id,
    required String sessionId,
    required int revision,
    this.promptText = const Value.absent(),
    this.agent = const Value.absent(),
    this.modelRef = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       revision = Value(revision),
       createdAt = Value(createdAt);
  static Insertable<ContextEpoch> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? revision,
    Expression<String>? promptText,
    Expression<String>? agent,
    Expression<String>? modelRef,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (revision != null) 'revision': revision,
      if (promptText != null) 'prompt_text': promptText,
      if (agent != null) 'agent': agent,
      if (modelRef != null) 'model_ref': modelRef,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextEpochsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? revision,
    Value<String>? promptText,
    Value<String>? agent,
    Value<String?>? modelRef,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ContextEpochsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      revision: revision ?? this.revision,
      promptText: promptText ?? this.promptText,
      agent: agent ?? this.agent,
      modelRef: modelRef ?? this.modelRef,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (promptText.present) {
      map['prompt_text'] = Variable<String>(promptText.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    if (modelRef.present) {
      map['model_ref'] = Variable<String>(modelRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextEpochsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('revision: $revision, ')
          ..write('promptText: $promptText, ')
          ..write('agent: $agent, ')
          ..write('modelRef: $modelRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionSnapshotsTable extends SessionSnapshots
    with TableInfo<$SessionSnapshotsTable, SessionSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepNumberMeta = const VerificationMeta(
    'stepNumber',
  );
  @override
  late final GeneratedColumn<String> stepNumber = GeneratedColumn<String>(
    'step_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestMeta = const VerificationMeta(
    'request',
  );
  @override
  late final GeneratedColumn<String> request = GeneratedColumn<String>(
    'request',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta(
    'response',
  );
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolCallIdMeta = const VerificationMeta(
    'toolCallId',
  );
  @override
  late final GeneratedColumn<String> toolCallId = GeneratedColumn<String>(
    'tool_call_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolNameMeta = const VerificationMeta(
    'toolName',
  );
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
    'tool_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokensInputMeta = const VerificationMeta(
    'tokensInput',
  );
  @override
  late final GeneratedColumn<int> tokensInput = GeneratedColumn<int>(
    'tokens_input',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tokensOutputMeta = const VerificationMeta(
    'tokensOutput',
  );
  @override
  late final GeneratedColumn<int> tokensOutput = GeneratedColumn<int>(
    'tokens_output',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    stepNumber,
    request,
    response,
    toolCallId,
    toolName,
    tokensInput,
    tokensOutput,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('step_number')) {
      context.handle(
        _stepNumberMeta,
        stepNumber.isAcceptableOrUnknown(data['step_number']!, _stepNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_stepNumberMeta);
    }
    if (data.containsKey('request')) {
      context.handle(
        _requestMeta,
        request.isAcceptableOrUnknown(data['request']!, _requestMeta),
      );
    } else if (isInserting) {
      context.missing(_requestMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('tool_call_id')) {
      context.handle(
        _toolCallIdMeta,
        toolCallId.isAcceptableOrUnknown(
          data['tool_call_id']!,
          _toolCallIdMeta,
        ),
      );
    }
    if (data.containsKey('tool_name')) {
      context.handle(
        _toolNameMeta,
        toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta),
      );
    }
    if (data.containsKey('tokens_input')) {
      context.handle(
        _tokensInputMeta,
        tokensInput.isAcceptableOrUnknown(
          data['tokens_input']!,
          _tokensInputMeta,
        ),
      );
    }
    if (data.containsKey('tokens_output')) {
      context.handle(
        _tokensOutputMeta,
        tokensOutput.isAcceptableOrUnknown(
          data['tokens_output']!,
          _tokensOutputMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      stepNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_number'],
      )!,
      request: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      )!,
      toolCallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_call_id'],
      ),
      toolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_name'],
      ),
      tokensInput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_input'],
      )!,
      tokensOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tokens_output'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SessionSnapshotsTable createAlias(String alias) {
    return $SessionSnapshotsTable(attachedDatabase, alias);
  }
}

class SessionSnapshot extends DataClass implements Insertable<SessionSnapshot> {
  final String id;
  final String sessionId;
  final String stepNumber;
  final String request;
  final String response;
  final String? toolCallId;
  final String? toolName;
  final int tokensInput;
  final int tokensOutput;
  final DateTime createdAt;
  const SessionSnapshot({
    required this.id,
    required this.sessionId,
    required this.stepNumber,
    required this.request,
    required this.response,
    this.toolCallId,
    this.toolName,
    required this.tokensInput,
    required this.tokensOutput,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['step_number'] = Variable<String>(stepNumber);
    map['request'] = Variable<String>(request);
    map['response'] = Variable<String>(response);
    if (!nullToAbsent || toolCallId != null) {
      map['tool_call_id'] = Variable<String>(toolCallId);
    }
    if (!nullToAbsent || toolName != null) {
      map['tool_name'] = Variable<String>(toolName);
    }
    map['tokens_input'] = Variable<int>(tokensInput);
    map['tokens_output'] = Variable<int>(tokensOutput);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SessionSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SessionSnapshotsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      stepNumber: Value(stepNumber),
      request: Value(request),
      response: Value(response),
      toolCallId: toolCallId == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallId),
      toolName: toolName == null && nullToAbsent
          ? const Value.absent()
          : Value(toolName),
      tokensInput: Value(tokensInput),
      tokensOutput: Value(tokensOutput),
      createdAt: Value(createdAt),
    );
  }

  factory SessionSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSnapshot(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      stepNumber: serializer.fromJson<String>(json['stepNumber']),
      request: serializer.fromJson<String>(json['request']),
      response: serializer.fromJson<String>(json['response']),
      toolCallId: serializer.fromJson<String?>(json['toolCallId']),
      toolName: serializer.fromJson<String?>(json['toolName']),
      tokensInput: serializer.fromJson<int>(json['tokensInput']),
      tokensOutput: serializer.fromJson<int>(json['tokensOutput']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'stepNumber': serializer.toJson<String>(stepNumber),
      'request': serializer.toJson<String>(request),
      'response': serializer.toJson<String>(response),
      'toolCallId': serializer.toJson<String?>(toolCallId),
      'toolName': serializer.toJson<String?>(toolName),
      'tokensInput': serializer.toJson<int>(tokensInput),
      'tokensOutput': serializer.toJson<int>(tokensOutput),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SessionSnapshot copyWith({
    String? id,
    String? sessionId,
    String? stepNumber,
    String? request,
    String? response,
    Value<String?> toolCallId = const Value.absent(),
    Value<String?> toolName = const Value.absent(),
    int? tokensInput,
    int? tokensOutput,
    DateTime? createdAt,
  }) => SessionSnapshot(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    stepNumber: stepNumber ?? this.stepNumber,
    request: request ?? this.request,
    response: response ?? this.response,
    toolCallId: toolCallId.present ? toolCallId.value : this.toolCallId,
    toolName: toolName.present ? toolName.value : this.toolName,
    tokensInput: tokensInput ?? this.tokensInput,
    tokensOutput: tokensOutput ?? this.tokensOutput,
    createdAt: createdAt ?? this.createdAt,
  );
  SessionSnapshot copyWithCompanion(SessionSnapshotsCompanion data) {
    return SessionSnapshot(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      stepNumber: data.stepNumber.present
          ? data.stepNumber.value
          : this.stepNumber,
      request: data.request.present ? data.request.value : this.request,
      response: data.response.present ? data.response.value : this.response,
      toolCallId: data.toolCallId.present
          ? data.toolCallId.value
          : this.toolCallId,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      tokensInput: data.tokensInput.present
          ? data.tokensInput.value
          : this.tokensInput,
      tokensOutput: data.tokensOutput.present
          ? data.tokensOutput.value
          : this.tokensOutput,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSnapshot(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('request: $request, ')
          ..write('response: $response, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolName: $toolName, ')
          ..write('tokensInput: $tokensInput, ')
          ..write('tokensOutput: $tokensOutput, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    stepNumber,
    request,
    response,
    toolCallId,
    toolName,
    tokensInput,
    tokensOutput,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSnapshot &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.stepNumber == this.stepNumber &&
          other.request == this.request &&
          other.response == this.response &&
          other.toolCallId == this.toolCallId &&
          other.toolName == this.toolName &&
          other.tokensInput == this.tokensInput &&
          other.tokensOutput == this.tokensOutput &&
          other.createdAt == this.createdAt);
}

class SessionSnapshotsCompanion extends UpdateCompanion<SessionSnapshot> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> stepNumber;
  final Value<String> request;
  final Value<String> response;
  final Value<String?> toolCallId;
  final Value<String?> toolName;
  final Value<int> tokensInput;
  final Value<int> tokensOutput;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SessionSnapshotsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.stepNumber = const Value.absent(),
    this.request = const Value.absent(),
    this.response = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.toolName = const Value.absent(),
    this.tokensInput = const Value.absent(),
    this.tokensOutput = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionSnapshotsCompanion.insert({
    required String id,
    required String sessionId,
    required String stepNumber,
    required String request,
    required String response,
    this.toolCallId = const Value.absent(),
    this.toolName = const Value.absent(),
    this.tokensInput = const Value.absent(),
    this.tokensOutput = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       stepNumber = Value(stepNumber),
       request = Value(request),
       response = Value(response),
       createdAt = Value(createdAt);
  static Insertable<SessionSnapshot> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? stepNumber,
    Expression<String>? request,
    Expression<String>? response,
    Expression<String>? toolCallId,
    Expression<String>? toolName,
    Expression<int>? tokensInput,
    Expression<int>? tokensOutput,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (stepNumber != null) 'step_number': stepNumber,
      if (request != null) 'request': request,
      if (response != null) 'response': response,
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (toolName != null) 'tool_name': toolName,
      if (tokensInput != null) 'tokens_input': tokensInput,
      if (tokensOutput != null) 'tokens_output': tokensOutput,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? stepNumber,
    Value<String>? request,
    Value<String>? response,
    Value<String?>? toolCallId,
    Value<String?>? toolName,
    Value<int>? tokensInput,
    Value<int>? tokensOutput,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SessionSnapshotsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      stepNumber: stepNumber ?? this.stepNumber,
      request: request ?? this.request,
      response: response ?? this.response,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (stepNumber.present) {
      map['step_number'] = Variable<String>(stepNumber.value);
    }
    if (request.present) {
      map['request'] = Variable<String>(request.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (toolCallId.present) {
      map['tool_call_id'] = Variable<String>(toolCallId.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (tokensInput.present) {
      map['tokens_input'] = Variable<int>(tokensInput.value);
    }
    if (tokensOutput.present) {
      map['tokens_output'] = Variable<int>(tokensOutput.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('request: $request, ')
          ..write('response: $response, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('toolName: $toolName, ')
          ..write('tokensInput: $tokensInput, ')
          ..write('tokensOutput: $tokensOutput, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FileSnapshotsTable extends FileSnapshots
    with TableInfo<$FileSnapshotsTable, FileSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepIdMeta = const VerificationMeta('stepId');
  @override
  late final GeneratedColumn<String> stepId = GeneratedColumn<String>(
    'step_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolNameMeta = const VerificationMeta(
    'toolName',
  );
  @override
  late final GeneratedColumn<String> toolName = GeneratedColumn<String>(
    'tool_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    filePath,
    content,
    stepId,
    toolName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('step_id')) {
      context.handle(
        _stepIdMeta,
        stepId.isAcceptableOrUnknown(data['step_id']!, _stepIdMeta),
      );
    }
    if (data.containsKey('tool_name')) {
      context.handle(
        _toolNameMeta,
        toolName.isAcceptableOrUnknown(data['tool_name']!, _toolNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      stepId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_id'],
      ),
      toolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FileSnapshotsTable createAlias(String alias) {
    return $FileSnapshotsTable(attachedDatabase, alias);
  }
}

class FileSnapshot extends DataClass implements Insertable<FileSnapshot> {
  final String id;
  final String sessionId;
  final String filePath;
  final String content;
  final String? stepId;
  final String? toolName;
  final DateTime createdAt;
  const FileSnapshot({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.content,
    this.stepId,
    this.toolName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['file_path'] = Variable<String>(filePath);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || stepId != null) {
      map['step_id'] = Variable<String>(stepId);
    }
    if (!nullToAbsent || toolName != null) {
      map['tool_name'] = Variable<String>(toolName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FileSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return FileSnapshotsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      filePath: Value(filePath),
      content: Value(content),
      stepId: stepId == null && nullToAbsent
          ? const Value.absent()
          : Value(stepId),
      toolName: toolName == null && nullToAbsent
          ? const Value.absent()
          : Value(toolName),
      createdAt: Value(createdAt),
    );
  }

  factory FileSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileSnapshot(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      content: serializer.fromJson<String>(json['content']),
      stepId: serializer.fromJson<String?>(json['stepId']),
      toolName: serializer.fromJson<String?>(json['toolName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'filePath': serializer.toJson<String>(filePath),
      'content': serializer.toJson<String>(content),
      'stepId': serializer.toJson<String?>(stepId),
      'toolName': serializer.toJson<String?>(toolName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FileSnapshot copyWith({
    String? id,
    String? sessionId,
    String? filePath,
    String? content,
    Value<String?> stepId = const Value.absent(),
    Value<String?> toolName = const Value.absent(),
    DateTime? createdAt,
  }) => FileSnapshot(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    filePath: filePath ?? this.filePath,
    content: content ?? this.content,
    stepId: stepId.present ? stepId.value : this.stepId,
    toolName: toolName.present ? toolName.value : this.toolName,
    createdAt: createdAt ?? this.createdAt,
  );
  FileSnapshot copyWithCompanion(FileSnapshotsCompanion data) {
    return FileSnapshot(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      content: data.content.present ? data.content.value : this.content,
      stepId: data.stepId.present ? data.stepId.value : this.stepId,
      toolName: data.toolName.present ? data.toolName.value : this.toolName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileSnapshot(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('content: $content, ')
          ..write('stepId: $stepId, ')
          ..write('toolName: $toolName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    filePath,
    content,
    stepId,
    toolName,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileSnapshot &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.filePath == this.filePath &&
          other.content == this.content &&
          other.stepId == this.stepId &&
          other.toolName == this.toolName &&
          other.createdAt == this.createdAt);
}

class FileSnapshotsCompanion extends UpdateCompanion<FileSnapshot> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> filePath;
  final Value<String> content;
  final Value<String?> stepId;
  final Value<String?> toolName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FileSnapshotsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.content = const Value.absent(),
    this.stepId = const Value.absent(),
    this.toolName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileSnapshotsCompanion.insert({
    required String id,
    required String sessionId,
    required String filePath,
    required String content,
    this.stepId = const Value.absent(),
    this.toolName = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       filePath = Value(filePath),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<FileSnapshot> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? filePath,
    Expression<String>? content,
    Expression<String>? stepId,
    Expression<String>? toolName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (filePath != null) 'file_path': filePath,
      if (content != null) 'content': content,
      if (stepId != null) 'step_id': stepId,
      if (toolName != null) 'tool_name': toolName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? filePath,
    Value<String>? content,
    Value<String?>? stepId,
    Value<String?>? toolName,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FileSnapshotsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      stepId: stepId ?? this.stepId,
      toolName: toolName ?? this.toolName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (stepId.present) {
      map['step_id'] = Variable<String>(stepId.value);
    }
    if (toolName.present) {
      map['tool_name'] = Variable<String>(toolName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('content: $content, ')
          ..write('stepId: $stepId, ')
          ..write('toolName: $toolName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatSnapshotsTable extends ChatSnapshots
    with TableInfo<$ChatSnapshotsTable, ChatSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventsCountMeta = const VerificationMeta(
    'eventsCount',
  );
  @override
  late final GeneratedColumn<int> eventsCount = GeneratedColumn<int>(
    'events_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatJsonMeta = const VerificationMeta(
    'chatJson',
  );
  @override
  late final GeneratedColumn<String> chatJson = GeneratedColumn<String>(
    'chat_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    eventsCount,
    chatJson,
    updatedAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('events_count')) {
      context.handle(
        _eventsCountMeta,
        eventsCount.isAcceptableOrUnknown(
          data['events_count']!,
          _eventsCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventsCountMeta);
    }
    if (data.containsKey('chat_json')) {
      context.handle(
        _chatJsonMeta,
        chatJson.isAcceptableOrUnknown(data['chat_json']!, _chatJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_chatJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  ChatSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSnapshot(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      eventsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}events_count'],
      )!,
      chatJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $ChatSnapshotsTable createAlias(String alias) {
    return $ChatSnapshotsTable(attachedDatabase, alias);
  }
}

class ChatSnapshot extends DataClass implements Insertable<ChatSnapshot> {
  final String sessionId;
  final int eventsCount;
  final String chatJson;
  final int updatedAt;
  final int schemaVersion;
  const ChatSnapshot({
    required this.sessionId,
    required this.eventsCount,
    required this.chatJson,
    required this.updatedAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['events_count'] = Variable<int>(eventsCount);
    map['chat_json'] = Variable<String>(chatJson);
    map['updated_at'] = Variable<int>(updatedAt);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  ChatSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return ChatSnapshotsCompanion(
      sessionId: Value(sessionId),
      eventsCount: Value(eventsCount),
      chatJson: Value(chatJson),
      updatedAt: Value(updatedAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory ChatSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSnapshot(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      eventsCount: serializer.fromJson<int>(json['eventsCount']),
      chatJson: serializer.fromJson<String>(json['chatJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'eventsCount': serializer.toJson<int>(eventsCount),
      'chatJson': serializer.toJson<String>(chatJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  ChatSnapshot copyWith({
    String? sessionId,
    int? eventsCount,
    String? chatJson,
    int? updatedAt,
    int? schemaVersion,
  }) => ChatSnapshot(
    sessionId: sessionId ?? this.sessionId,
    eventsCount: eventsCount ?? this.eventsCount,
    chatJson: chatJson ?? this.chatJson,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  ChatSnapshot copyWithCompanion(ChatSnapshotsCompanion data) {
    return ChatSnapshot(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      eventsCount: data.eventsCount.present
          ? data.eventsCount.value
          : this.eventsCount,
      chatJson: data.chatJson.present ? data.chatJson.value : this.chatJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSnapshot(')
          ..write('sessionId: $sessionId, ')
          ..write('eventsCount: $eventsCount, ')
          ..write('chatJson: $chatJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, eventsCount, chatJson, updatedAt, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSnapshot &&
          other.sessionId == this.sessionId &&
          other.eventsCount == this.eventsCount &&
          other.chatJson == this.chatJson &&
          other.updatedAt == this.updatedAt &&
          other.schemaVersion == this.schemaVersion);
}

class ChatSnapshotsCompanion extends UpdateCompanion<ChatSnapshot> {
  final Value<String> sessionId;
  final Value<int> eventsCount;
  final Value<String> chatJson;
  final Value<int> updatedAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const ChatSnapshotsCompanion({
    this.sessionId = const Value.absent(),
    this.eventsCount = const Value.absent(),
    this.chatJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSnapshotsCompanion.insert({
    required String sessionId,
    required int eventsCount,
    required String chatJson,
    required int updatedAt,
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       eventsCount = Value(eventsCount),
       chatJson = Value(chatJson),
       updatedAt = Value(updatedAt);
  static Insertable<ChatSnapshot> custom({
    Expression<String>? sessionId,
    Expression<int>? eventsCount,
    Expression<String>? chatJson,
    Expression<int>? updatedAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (eventsCount != null) 'events_count': eventsCount,
      if (chatJson != null) 'chat_json': chatJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSnapshotsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? eventsCount,
    Value<String>? chatJson,
    Value<int>? updatedAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return ChatSnapshotsCompanion(
      sessionId: sessionId ?? this.sessionId,
      eventsCount: eventsCount ?? this.eventsCount,
      chatJson: chatJson ?? this.chatJson,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (eventsCount.present) {
      map['events_count'] = Variable<int>(eventsCount.value);
    }
    if (chatJson.present) {
      map['chat_json'] = Variable<String>(chatJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSnapshotsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('eventsCount: $eventsCount, ')
          ..write('chatJson: $chatJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ToolResultsTable toolResults = $ToolResultsTable(this);
  late final $ContextEpochsTable contextEpochs = $ContextEpochsTable(this);
  late final $SessionSnapshotsTable sessionSnapshots = $SessionSnapshotsTable(
    this,
  );
  late final $FileSnapshotsTable fileSnapshots = $FileSnapshotsTable(this);
  late final $ChatSnapshotsTable chatSnapshots = $ChatSnapshotsTable(this);
  late final Index idxEventsSessionSeq = Index(
    'idx_events_session_seq',
    'CREATE INDEX idx_events_session_seq ON events (session_id, sequence)',
  );
  late final Index idxMessagesSessionSeq = Index(
    'idx_messages_session_seq',
    'CREATE INDEX idx_messages_session_seq ON messages (session_id, seq)',
  );
  late final Index idxToolResultsSession = Index(
    'idx_tool_results_session',
    'CREATE INDEX idx_tool_results_session ON tool_results (session_id)',
  );
  late final Index idxContextEpochsSession = Index(
    'idx_context_epochs_session',
    'CREATE INDEX idx_context_epochs_session ON context_epochs (session_id)',
  );
  late final Index idxSessionSnapshotsSession = Index(
    'idx_session_snapshots_session',
    'CREATE INDEX idx_session_snapshots_session ON session_snapshots (session_id)',
  );
  late final Index idxFileSnapshotsSession = Index(
    'idx_file_snapshots_session',
    'CREATE INDEX idx_file_snapshots_session ON file_snapshots (session_id)',
  );
  late final Index idxFileSnapshotsSessionStepCreated = Index(
    'idx_file_snapshots_session_step_created',
    'CREATE INDEX idx_file_snapshots_session_step_created ON file_snapshots (session_id, step_id, created_at)',
  );
  late final Index idxChatSnapshotsSession = Index(
    'idx_chat_snapshots_session',
    'CREATE INDEX idx_chat_snapshots_session ON chat_snapshots (session_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    sessions,
    messages,
    toolResults,
    contextEpochs,
    sessionSnapshots,
    fileSnapshots,
    chatSnapshots,
    idxEventsSessionSeq,
    idxMessagesSessionSeq,
    idxToolResultsSession,
    idxContextEpochsSession,
    idxSessionSnapshotsSession,
    idxFileSnapshotsSession,
    idxFileSnapshotsSessionStepCreated,
    idxChatSnapshotsSession,
  ];
}

typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      required String sessionId,
      required String eventType,
      required String eventData,
      required int sequence,
      required DateTime createdAt,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<String> eventType,
      Value<String> eventData,
      Value<int> sequence,
      Value<DateTime> createdAt,
    });

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventData => $composableBuilder(
    column: $table.eventData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventData => $composableBuilder(
    column: $table.eventData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get eventData =>
      $composableBuilder(column: $table.eventData, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
          Event,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> eventData = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                sessionId: sessionId,
                eventType: eventType,
                eventData: eventData,
                sequence: sequence,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String eventType,
                required String eventData,
                required int sequence,
                required DateTime createdAt,
              }) => EventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                eventType: eventType,
                eventData: eventData,
                sequence: sequence,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
      Event,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      Value<String?> parentId,
      Value<String> title,
      Value<String> agent,
      Value<String?> modelRef,
      Value<double> cost,
      Value<int> tokensInput,
      Value<int> tokensOutput,
      Value<int> tokensReasoning,
      Value<int> tokensCacheRead,
      Value<int> tokensCacheWrite,
      Value<String?> permissionRules,
      Value<String?> directory,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String> title,
      Value<String> agent,
      Value<String?> modelRef,
      Value<double> cost,
      Value<int> tokensInput,
      Value<int> tokensOutput,
      Value<int> tokensReasoning,
      Value<int> tokensCacheRead,
      Value<int> tokensCacheWrite,
      Value<String?> permissionRules,
      Value<String?> directory,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelRef => $composableBuilder(
    column: $table.modelRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensCacheRead => $composableBuilder(
    column: $table.tokensCacheRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensCacheWrite => $composableBuilder(
    column: $table.tokensCacheWrite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionRules => $composableBuilder(
    column: $table.permissionRules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelRef => $composableBuilder(
    column: $table.modelRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensCacheRead => $composableBuilder(
    column: $table.tokensCacheRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensCacheWrite => $composableBuilder(
    column: $table.tokensCacheWrite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionRules => $composableBuilder(
    column: $table.permissionRules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directory => $composableBuilder(
    column: $table.directory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);

  GeneratedColumn<String> get modelRef =>
      $composableBuilder(column: $table.modelRef, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensCacheRead => $composableBuilder(
    column: $table.tokensCacheRead,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensCacheWrite => $composableBuilder(
    column: $table.tokensCacheWrite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get permissionRules => $composableBuilder(
    column: $table.permissionRules,
    builder: (column) => column,
  );

  GeneratedColumn<String> get directory =>
      $composableBuilder(column: $table.directory, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<String?> modelRef = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<int> tokensInput = const Value.absent(),
                Value<int> tokensOutput = const Value.absent(),
                Value<int> tokensReasoning = const Value.absent(),
                Value<int> tokensCacheRead = const Value.absent(),
                Value<int> tokensCacheWrite = const Value.absent(),
                Value<String?> permissionRules = const Value.absent(),
                Value<String?> directory = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                parentId: parentId,
                title: title,
                agent: agent,
                modelRef: modelRef,
                cost: cost,
                tokensInput: tokensInput,
                tokensOutput: tokensOutput,
                tokensReasoning: tokensReasoning,
                tokensCacheRead: tokensCacheRead,
                tokensCacheWrite: tokensCacheWrite,
                permissionRules: permissionRules,
                directory: directory,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<String?> modelRef = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<int> tokensInput = const Value.absent(),
                Value<int> tokensOutput = const Value.absent(),
                Value<int> tokensReasoning = const Value.absent(),
                Value<int> tokensCacheRead = const Value.absent(),
                Value<int> tokensCacheWrite = const Value.absent(),
                Value<String?> permissionRules = const Value.absent(),
                Value<String?> directory = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                parentId: parentId,
                title: title,
                agent: agent,
                modelRef: modelRef,
                cost: cost,
                tokensInput: tokensInput,
                tokensOutput: tokensOutput,
                tokensReasoning: tokensReasoning,
                tokensCacheRead: tokensCacheRead,
                tokensCacheWrite: tokensCacheWrite,
                permissionRules: permissionRules,
                directory: directory,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String sessionId,
      required int seq,
      required String role,
      Value<String> content,
      Value<String?> model,
      Value<String?> reasoning,
      Value<String?> error,
      Value<int> tokensInput,
      Value<int> tokensOutput,
      Value<int> tokensReasoning,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> seq,
      Value<String> role,
      Value<String> content,
      Value<String?> model,
      Value<String?> reasoning,
      Value<String?> error,
      Value<int> tokensInput,
      Value<int> tokensOutput,
      Value<int> tokensReasoning,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensReasoning => $composableBuilder(
    column: $table.tokensReasoning,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> tokensInput = const Value.absent(),
                Value<int> tokensOutput = const Value.absent(),
                Value<int> tokensReasoning = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                content: content,
                model: model,
                reasoning: reasoning,
                error: error,
                tokensInput: tokensInput,
                tokensOutput: tokensOutput,
                tokensReasoning: tokensReasoning,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int seq,
                required String role,
                Value<String> content = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> tokensInput = const Value.absent(),
                Value<int> tokensOutput = const Value.absent(),
                Value<int> tokensReasoning = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                content: content,
                model: model,
                reasoning: reasoning,
                error: error,
                tokensInput: tokensInput,
                tokensOutput: tokensOutput,
                tokensReasoning: tokensReasoning,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$ToolResultsTableCreateCompanionBuilder =
    ToolResultsCompanion Function({
      required String id,
      required String sessionId,
      required String messageId,
      required String toolName,
      Value<String> inputJson,
      Value<String> outputText,
      Value<int> durationMs,
      Value<String> status,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ToolResultsTableUpdateCompanionBuilder =
    ToolResultsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> messageId,
      Value<String> toolName,
      Value<String> inputJson,
      Value<String> outputText,
      Value<int> durationMs,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ToolResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ToolResultsTable> {
  $$ToolResultsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputJson => $composableBuilder(
    column: $table.inputJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputText => $composableBuilder(
    column: $table.outputText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ToolResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ToolResultsTable> {
  $$ToolResultsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputJson => $composableBuilder(
    column: $table.inputJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputText => $composableBuilder(
    column: $table.outputText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ToolResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToolResultsTable> {
  $$ToolResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<String> get inputJson =>
      $composableBuilder(column: $table.inputJson, builder: (column) => column);

  GeneratedColumn<String> get outputText => $composableBuilder(
    column: $table.outputText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ToolResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ToolResultsTable,
          ToolResult,
          $$ToolResultsTableFilterComposer,
          $$ToolResultsTableOrderingComposer,
          $$ToolResultsTableAnnotationComposer,
          $$ToolResultsTableCreateCompanionBuilder,
          $$ToolResultsTableUpdateCompanionBuilder,
          (
            ToolResult,
            BaseReferences<_$AppDatabase, $ToolResultsTable, ToolResult>,
          ),
          ToolResult,
          PrefetchHooks Function()
        > {
  $$ToolResultsTableTableManager(_$AppDatabase db, $ToolResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToolResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToolResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToolResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> toolName = const Value.absent(),
                Value<String> inputJson = const Value.absent(),
                Value<String> outputText = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToolResultsCompanion(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                toolName: toolName,
                inputJson: inputJson,
                outputText: outputText,
                durationMs: durationMs,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String messageId,
                required String toolName,
                Value<String> inputJson = const Value.absent(),
                Value<String> outputText = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ToolResultsCompanion.insert(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                toolName: toolName,
                inputJson: inputJson,
                outputText: outputText,
                durationMs: durationMs,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ToolResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ToolResultsTable,
      ToolResult,
      $$ToolResultsTableFilterComposer,
      $$ToolResultsTableOrderingComposer,
      $$ToolResultsTableAnnotationComposer,
      $$ToolResultsTableCreateCompanionBuilder,
      $$ToolResultsTableUpdateCompanionBuilder,
      (
        ToolResult,
        BaseReferences<_$AppDatabase, $ToolResultsTable, ToolResult>,
      ),
      ToolResult,
      PrefetchHooks Function()
    >;
typedef $$ContextEpochsTableCreateCompanionBuilder =
    ContextEpochsCompanion Function({
      required String id,
      required String sessionId,
      required int revision,
      Value<String> promptText,
      Value<String> agent,
      Value<String?> modelRef,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ContextEpochsTableUpdateCompanionBuilder =
    ContextEpochsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> revision,
      Value<String> promptText,
      Value<String> agent,
      Value<String?> modelRef,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ContextEpochsTableFilterComposer
    extends Composer<_$AppDatabase, $ContextEpochsTable> {
  $$ContextEpochsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptText => $composableBuilder(
    column: $table.promptText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelRef => $composableBuilder(
    column: $table.modelRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContextEpochsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContextEpochsTable> {
  $$ContextEpochsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptText => $composableBuilder(
    column: $table.promptText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelRef => $composableBuilder(
    column: $table.modelRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContextEpochsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContextEpochsTable> {
  $$ContextEpochsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get promptText => $composableBuilder(
    column: $table.promptText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);

  GeneratedColumn<String> get modelRef =>
      $composableBuilder(column: $table.modelRef, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ContextEpochsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContextEpochsTable,
          ContextEpoch,
          $$ContextEpochsTableFilterComposer,
          $$ContextEpochsTableOrderingComposer,
          $$ContextEpochsTableAnnotationComposer,
          $$ContextEpochsTableCreateCompanionBuilder,
          $$ContextEpochsTableUpdateCompanionBuilder,
          (
            ContextEpoch,
            BaseReferences<_$AppDatabase, $ContextEpochsTable, ContextEpoch>,
          ),
          ContextEpoch,
          PrefetchHooks Function()
        > {
  $$ContextEpochsTableTableManager(_$AppDatabase db, $ContextEpochsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContextEpochsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContextEpochsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContextEpochsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> promptText = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<String?> modelRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContextEpochsCompanion(
                id: id,
                sessionId: sessionId,
                revision: revision,
                promptText: promptText,
                agent: agent,
                modelRef: modelRef,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int revision,
                Value<String> promptText = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<String?> modelRef = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContextEpochsCompanion.insert(
                id: id,
                sessionId: sessionId,
                revision: revision,
                promptText: promptText,
                agent: agent,
                modelRef: modelRef,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContextEpochsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContextEpochsTable,
      ContextEpoch,
      $$ContextEpochsTableFilterComposer,
      $$ContextEpochsTableOrderingComposer,
      $$ContextEpochsTableAnnotationComposer,
      $$ContextEpochsTableCreateCompanionBuilder,
      $$ContextEpochsTableUpdateCompanionBuilder,
      (
        ContextEpoch,
        BaseReferences<_$AppDatabase, $ContextEpochsTable, ContextEpoch>,
      ),
      ContextEpoch,
      PrefetchHooks Function()
    >;
typedef $$SessionSnapshotsTableCreateCompanionBuilder =
    SessionSnapshotsCompanion Function({
      required String id,
      required String sessionId,
      required String stepNumber,
      required String request,
      required String response,
      Value<String?> toolCallId,
      Value<String?> toolName,
      Value<int> tokensInput,
      Value<int> tokensOutput,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SessionSnapshotsTableUpdateCompanionBuilder =
    SessionSnapshotsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> stepNumber,
      Value<String> request,
      Value<String> response,
      Value<String?> toolCallId,
      Value<String?> toolName,
      Value<int> tokensInput,
      Value<int> tokensOutput,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SessionSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSnapshotsTable> {
  $$SessionSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get request => $composableBuilder(
    column: $table.request,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSnapshotsTable> {
  $$SessionSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get request => $composableBuilder(
    column: $table.request,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSnapshotsTable> {
  $$SessionSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get request =>
      $composableBuilder(column: $table.request, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<int> get tokensInput => $composableBuilder(
    column: $table.tokensInput,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tokensOutput => $composableBuilder(
    column: $table.tokensOutput,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SessionSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSnapshotsTable,
          SessionSnapshot,
          $$SessionSnapshotsTableFilterComposer,
          $$SessionSnapshotsTableOrderingComposer,
          $$SessionSnapshotsTableAnnotationComposer,
          $$SessionSnapshotsTableCreateCompanionBuilder,
          $$SessionSnapshotsTableUpdateCompanionBuilder,
          (
            SessionSnapshot,
            BaseReferences<
              _$AppDatabase,
              $SessionSnapshotsTable,
              SessionSnapshot
            >,
          ),
          SessionSnapshot,
          PrefetchHooks Function()
        > {
  $$SessionSnapshotsTableTableManager(
    _$AppDatabase db,
    $SessionSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> stepNumber = const Value.absent(),
                Value<String> request = const Value.absent(),
                Value<String> response = const Value.absent(),
                Value<String?> toolCallId = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                Value<int> tokensInput = const Value.absent(),
                Value<int> tokensOutput = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionSnapshotsCompanion(
                id: id,
                sessionId: sessionId,
                stepNumber: stepNumber,
                request: request,
                response: response,
                toolCallId: toolCallId,
                toolName: toolName,
                tokensInput: tokensInput,
                tokensOutput: tokensOutput,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String stepNumber,
                required String request,
                required String response,
                Value<String?> toolCallId = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                Value<int> tokensInput = const Value.absent(),
                Value<int> tokensOutput = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionSnapshotsCompanion.insert(
                id: id,
                sessionId: sessionId,
                stepNumber: stepNumber,
                request: request,
                response: response,
                toolCallId: toolCallId,
                toolName: toolName,
                tokensInput: tokensInput,
                tokensOutput: tokensOutput,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSnapshotsTable,
      SessionSnapshot,
      $$SessionSnapshotsTableFilterComposer,
      $$SessionSnapshotsTableOrderingComposer,
      $$SessionSnapshotsTableAnnotationComposer,
      $$SessionSnapshotsTableCreateCompanionBuilder,
      $$SessionSnapshotsTableUpdateCompanionBuilder,
      (
        SessionSnapshot,
        BaseReferences<_$AppDatabase, $SessionSnapshotsTable, SessionSnapshot>,
      ),
      SessionSnapshot,
      PrefetchHooks Function()
    >;
typedef $$FileSnapshotsTableCreateCompanionBuilder =
    FileSnapshotsCompanion Function({
      required String id,
      required String sessionId,
      required String filePath,
      required String content,
      Value<String?> stepId,
      Value<String?> toolName,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$FileSnapshotsTableUpdateCompanionBuilder =
    FileSnapshotsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> filePath,
      Value<String> content,
      Value<String?> stepId,
      Value<String?> toolName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$FileSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $FileSnapshotsTable> {
  $$FileSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FileSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $FileSnapshotsTable> {
  $$FileSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolName => $composableBuilder(
    column: $table.toolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FileSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileSnapshotsTable> {
  $$FileSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get stepId =>
      $composableBuilder(column: $table.stepId, builder: (column) => column);

  GeneratedColumn<String> get toolName =>
      $composableBuilder(column: $table.toolName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FileSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileSnapshotsTable,
          FileSnapshot,
          $$FileSnapshotsTableFilterComposer,
          $$FileSnapshotsTableOrderingComposer,
          $$FileSnapshotsTableAnnotationComposer,
          $$FileSnapshotsTableCreateCompanionBuilder,
          $$FileSnapshotsTableUpdateCompanionBuilder,
          (
            FileSnapshot,
            BaseReferences<_$AppDatabase, $FileSnapshotsTable, FileSnapshot>,
          ),
          FileSnapshot,
          PrefetchHooks Function()
        > {
  $$FileSnapshotsTableTableManager(_$AppDatabase db, $FileSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> stepId = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileSnapshotsCompanion(
                id: id,
                sessionId: sessionId,
                filePath: filePath,
                content: content,
                stepId: stepId,
                toolName: toolName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String filePath,
                required String content,
                Value<String?> stepId = const Value.absent(),
                Value<String?> toolName = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FileSnapshotsCompanion.insert(
                id: id,
                sessionId: sessionId,
                filePath: filePath,
                content: content,
                stepId: stepId,
                toolName: toolName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FileSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileSnapshotsTable,
      FileSnapshot,
      $$FileSnapshotsTableFilterComposer,
      $$FileSnapshotsTableOrderingComposer,
      $$FileSnapshotsTableAnnotationComposer,
      $$FileSnapshotsTableCreateCompanionBuilder,
      $$FileSnapshotsTableUpdateCompanionBuilder,
      (
        FileSnapshot,
        BaseReferences<_$AppDatabase, $FileSnapshotsTable, FileSnapshot>,
      ),
      FileSnapshot,
      PrefetchHooks Function()
    >;
typedef $$ChatSnapshotsTableCreateCompanionBuilder =
    ChatSnapshotsCompanion Function({
      required String sessionId,
      required int eventsCount,
      required String chatJson,
      required int updatedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$ChatSnapshotsTableUpdateCompanionBuilder =
    ChatSnapshotsCompanion Function({
      Value<String> sessionId,
      Value<int> eventsCount,
      Value<String> chatJson,
      Value<int> updatedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

class $$ChatSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSnapshotsTable> {
  $$ChatSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventsCount => $composableBuilder(
    column: $table.eventsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatJson => $composableBuilder(
    column: $table.chatJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSnapshotsTable> {
  $$ChatSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventsCount => $composableBuilder(
    column: $table.eventsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatJson => $composableBuilder(
    column: $table.chatJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSnapshotsTable> {
  $$ChatSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get eventsCount => $composableBuilder(
    column: $table.eventsCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chatJson =>
      $composableBuilder(column: $table.chatJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );
}

class $$ChatSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatSnapshotsTable,
          ChatSnapshot,
          $$ChatSnapshotsTableFilterComposer,
          $$ChatSnapshotsTableOrderingComposer,
          $$ChatSnapshotsTableAnnotationComposer,
          $$ChatSnapshotsTableCreateCompanionBuilder,
          $$ChatSnapshotsTableUpdateCompanionBuilder,
          (
            ChatSnapshot,
            BaseReferences<_$AppDatabase, $ChatSnapshotsTable, ChatSnapshot>,
          ),
          ChatSnapshot,
          PrefetchHooks Function()
        > {
  $$ChatSnapshotsTableTableManager(_$AppDatabase db, $ChatSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> eventsCount = const Value.absent(),
                Value<String> chatJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSnapshotsCompanion(
                sessionId: sessionId,
                eventsCount: eventsCount,
                chatJson: chatJson,
                updatedAt: updatedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int eventsCount,
                required String chatJson,
                required int updatedAt,
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSnapshotsCompanion.insert(
                sessionId: sessionId,
                eventsCount: eventsCount,
                chatJson: chatJson,
                updatedAt: updatedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatSnapshotsTable,
      ChatSnapshot,
      $$ChatSnapshotsTableFilterComposer,
      $$ChatSnapshotsTableOrderingComposer,
      $$ChatSnapshotsTableAnnotationComposer,
      $$ChatSnapshotsTableCreateCompanionBuilder,
      $$ChatSnapshotsTableUpdateCompanionBuilder,
      (
        ChatSnapshot,
        BaseReferences<_$AppDatabase, $ChatSnapshotsTable, ChatSnapshot>,
      ),
      ChatSnapshot,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ToolResultsTableTableManager get toolResults =>
      $$ToolResultsTableTableManager(_db, _db.toolResults);
  $$ContextEpochsTableTableManager get contextEpochs =>
      $$ContextEpochsTableTableManager(_db, _db.contextEpochs);
  $$SessionSnapshotsTableTableManager get sessionSnapshots =>
      $$SessionSnapshotsTableTableManager(_db, _db.sessionSnapshots);
  $$FileSnapshotsTableTableManager get fileSnapshots =>
      $$FileSnapshotsTableTableManager(_db, _db.fileSnapshots);
  $$ChatSnapshotsTableTableManager get chatSnapshots =>
      $$ChatSnapshotsTableTableManager(_db, _db.chatSnapshots);
}
