import 'package:drift/drift.dart';

@TableIndex(name: 'idx_events_session_seq', columns: {#sessionId, #sequence})
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text()();
  TextColumn get eventType => text()();
  TextColumn get eventData => text()();
  IntColumn get sequence => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn? get parentId => text().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get agent => text().withDefault(const Constant('general'))();
  TextColumn? get modelRef => text().nullable()();
  RealColumn get cost => real().withDefault(const Constant(0.0))();
  IntColumn get tokensInput => integer().withDefault(const Constant(0))();
  IntColumn get tokensOutput => integer().withDefault(const Constant(0))();
  IntColumn get tokensReasoning => integer().withDefault(const Constant(0))();
  IntColumn get tokensCacheRead => integer().withDefault(const Constant(0))();
  IntColumn get tokensCacheWrite => integer().withDefault(const Constant(0))();
  TextColumn? get permissionRules => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn? get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_messages_session_seq', columns: {#sessionId, #seq})
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  IntColumn get seq => integer()();
  TextColumn get role => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn? get model => text().nullable()();
  TextColumn? get reasoning => text().nullable()();
  TextColumn? get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_tool_results_session', columns: {#sessionId})
class ToolResults extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get messageId => text()();
  TextColumn get toolName => text()();
  TextColumn get inputJson => text().withDefault(const Constant('{}'))();
  TextColumn get outputText => text().withDefault(const Constant(''))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('success'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_context_epochs_session', columns: {#sessionId})
class ContextEpochs extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  IntColumn get revision => integer()();
  TextColumn get promptText => text().withDefault(const Constant(''))();
  TextColumn get agent => text().withDefault(const Constant('general'))();
  TextColumn? get modelRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_session_snapshots_session', columns: {#sessionId})
class SessionSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get stepNumber => text()();
  TextColumn get request => text()();
  TextColumn get response => text()();
  TextColumn? get toolCallId => text().nullable()();
  TextColumn? get toolName => text().nullable()();
  IntColumn get tokensInput => integer().withDefault(const Constant(0))();
  IntColumn get tokensOutput => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
