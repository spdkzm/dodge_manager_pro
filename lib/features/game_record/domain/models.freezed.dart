// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UIActionItem {
  String get name => throw _privateConstructorUsedError;
  String get parentName => throw _privateConstructorUsedError;
  ActionResult get fixedResult => throw _privateConstructorUsedError;
  List<SubActionDefinition> get subActions =>
      throw _privateConstructorUsedError;
  bool get isSubRequired => throw _privateConstructorUsedError;
  bool get hasSuccess => throw _privateConstructorUsedError;
  bool get hasFailure => throw _privateConstructorUsedError;

  /// Create a copy of UIActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UIActionItemCopyWith<UIActionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UIActionItemCopyWith<$Res> {
  factory $UIActionItemCopyWith(
    UIActionItem value,
    $Res Function(UIActionItem) then,
  ) = _$UIActionItemCopyWithImpl<$Res, UIActionItem>;
  @useResult
  $Res call({
    String name,
    String parentName,
    ActionResult fixedResult,
    List<SubActionDefinition> subActions,
    bool isSubRequired,
    bool hasSuccess,
    bool hasFailure,
  });
}

/// @nodoc
class _$UIActionItemCopyWithImpl<$Res, $Val extends UIActionItem>
    implements $UIActionItemCopyWith<$Res> {
  _$UIActionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UIActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? parentName = null,
    Object? fixedResult = null,
    Object? subActions = null,
    Object? isSubRequired = null,
    Object? hasSuccess = null,
    Object? hasFailure = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            parentName: null == parentName
                ? _value.parentName
                : parentName // ignore: cast_nullable_to_non_nullable
                      as String,
            fixedResult: null == fixedResult
                ? _value.fixedResult
                : fixedResult // ignore: cast_nullable_to_non_nullable
                      as ActionResult,
            subActions: null == subActions
                ? _value.subActions
                : subActions // ignore: cast_nullable_to_non_nullable
                      as List<SubActionDefinition>,
            isSubRequired: null == isSubRequired
                ? _value.isSubRequired
                : isSubRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasSuccess: null == hasSuccess
                ? _value.hasSuccess
                : hasSuccess // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasFailure: null == hasFailure
                ? _value.hasFailure
                : hasFailure // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UIActionItemImplCopyWith<$Res>
    implements $UIActionItemCopyWith<$Res> {
  factory _$$UIActionItemImplCopyWith(
    _$UIActionItemImpl value,
    $Res Function(_$UIActionItemImpl) then,
  ) = __$$UIActionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String parentName,
    ActionResult fixedResult,
    List<SubActionDefinition> subActions,
    bool isSubRequired,
    bool hasSuccess,
    bool hasFailure,
  });
}

/// @nodoc
class __$$UIActionItemImplCopyWithImpl<$Res>
    extends _$UIActionItemCopyWithImpl<$Res, _$UIActionItemImpl>
    implements _$$UIActionItemImplCopyWith<$Res> {
  __$$UIActionItemImplCopyWithImpl(
    _$UIActionItemImpl _value,
    $Res Function(_$UIActionItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UIActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? parentName = null,
    Object? fixedResult = null,
    Object? subActions = null,
    Object? isSubRequired = null,
    Object? hasSuccess = null,
    Object? hasFailure = null,
  }) {
    return _then(
      _$UIActionItemImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        parentName: null == parentName
            ? _value.parentName
            : parentName // ignore: cast_nullable_to_non_nullable
                  as String,
        fixedResult: null == fixedResult
            ? _value.fixedResult
            : fixedResult // ignore: cast_nullable_to_non_nullable
                  as ActionResult,
        subActions: null == subActions
            ? _value._subActions
            : subActions // ignore: cast_nullable_to_non_nullable
                  as List<SubActionDefinition>,
        isSubRequired: null == isSubRequired
            ? _value.isSubRequired
            : isSubRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasSuccess: null == hasSuccess
            ? _value.hasSuccess
            : hasSuccess // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasFailure: null == hasFailure
            ? _value.hasFailure
            : hasFailure // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UIActionItemImpl implements _UIActionItem {
  const _$UIActionItemImpl({
    required this.name,
    required this.parentName,
    required this.fixedResult,
    required final List<SubActionDefinition> subActions,
    required this.isSubRequired,
    this.hasSuccess = false,
    this.hasFailure = false,
  }) : _subActions = subActions;

  @override
  final String name;
  @override
  final String parentName;
  @override
  final ActionResult fixedResult;
  final List<SubActionDefinition> _subActions;
  @override
  List<SubActionDefinition> get subActions {
    if (_subActions is EqualUnmodifiableListView) return _subActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subActions);
  }

  @override
  final bool isSubRequired;
  @override
  @JsonKey()
  final bool hasSuccess;
  @override
  @JsonKey()
  final bool hasFailure;

  @override
  String toString() {
    return 'UIActionItem(name: $name, parentName: $parentName, fixedResult: $fixedResult, subActions: $subActions, isSubRequired: $isSubRequired, hasSuccess: $hasSuccess, hasFailure: $hasFailure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UIActionItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentName, parentName) ||
                other.parentName == parentName) &&
            (identical(other.fixedResult, fixedResult) ||
                other.fixedResult == fixedResult) &&
            const DeepCollectionEquality().equals(
              other._subActions,
              _subActions,
            ) &&
            (identical(other.isSubRequired, isSubRequired) ||
                other.isSubRequired == isSubRequired) &&
            (identical(other.hasSuccess, hasSuccess) ||
                other.hasSuccess == hasSuccess) &&
            (identical(other.hasFailure, hasFailure) ||
                other.hasFailure == hasFailure));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    parentName,
    fixedResult,
    const DeepCollectionEquality().hash(_subActions),
    isSubRequired,
    hasSuccess,
    hasFailure,
  );

  /// Create a copy of UIActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UIActionItemImplCopyWith<_$UIActionItemImpl> get copyWith =>
      __$$UIActionItemImplCopyWithImpl<_$UIActionItemImpl>(this, _$identity);
}

abstract class _UIActionItem implements UIActionItem {
  const factory _UIActionItem({
    required final String name,
    required final String parentName,
    required final ActionResult fixedResult,
    required final List<SubActionDefinition> subActions,
    required final bool isSubRequired,
    final bool hasSuccess,
    final bool hasFailure,
  }) = _$UIActionItemImpl;

  @override
  String get name;
  @override
  String get parentName;
  @override
  ActionResult get fixedResult;
  @override
  List<SubActionDefinition> get subActions;
  @override
  bool get isSubRequired;
  @override
  bool get hasSuccess;
  @override
  bool get hasFailure;

  /// Create a copy of UIActionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UIActionItemImplCopyWith<_$UIActionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) {
  return _LogEntry.fromJson(json);
}

/// @nodoc
mixin _$LogEntry {
  String get id => throw _privateConstructorUsedError;
  set id(String value) => throw _privateConstructorUsedError;
  String get matchDate => throw _privateConstructorUsedError;
  set matchDate(String value) => throw _privateConstructorUsedError;
  String get opponent => throw _privateConstructorUsedError;
  set opponent(String value) => throw _privateConstructorUsedError;
  String get gameTime => throw _privateConstructorUsedError;
  set gameTime(String value) => throw _privateConstructorUsedError;
  String get playerNumber => throw _privateConstructorUsedError;
  set playerNumber(String value) => throw _privateConstructorUsedError;
  String? get playerId => throw _privateConstructorUsedError;
  set playerId(String? value) => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  set action(String value) => throw _privateConstructorUsedError;
  String? get subAction => throw _privateConstructorUsedError;
  set subAction(String? value) => throw _privateConstructorUsedError;
  String? get subActionId => throw _privateConstructorUsedError;
  set subActionId(String? value) => throw _privateConstructorUsedError;
  @LogTypeConverter()
  LogType get type => throw _privateConstructorUsedError;
  @LogTypeConverter()
  set type(LogType value) => throw _privateConstructorUsedError;
  @ActionResultConverter()
  ActionResult get result => throw _privateConstructorUsedError;
  @ActionResultConverter()
  set result(ActionResult value) => throw _privateConstructorUsedError;

  /// Serializes this LogEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogEntryCopyWith<LogEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogEntryCopyWith<$Res> {
  factory $LogEntryCopyWith(LogEntry value, $Res Function(LogEntry) then) =
      _$LogEntryCopyWithImpl<$Res, LogEntry>;
  @useResult
  $Res call({
    String id,
    String matchDate,
    String opponent,
    String gameTime,
    String playerNumber,
    String? playerId,
    String action,
    String? subAction,
    String? subActionId,
    @LogTypeConverter() LogType type,
    @ActionResultConverter() ActionResult result,
  });
}

/// @nodoc
class _$LogEntryCopyWithImpl<$Res, $Val extends LogEntry>
    implements $LogEntryCopyWith<$Res> {
  _$LogEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? matchDate = null,
    Object? opponent = null,
    Object? gameTime = null,
    Object? playerNumber = null,
    Object? playerId = freezed,
    Object? action = null,
    Object? subAction = freezed,
    Object? subActionId = freezed,
    Object? type = null,
    Object? result = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            matchDate: null == matchDate
                ? _value.matchDate
                : matchDate // ignore: cast_nullable_to_non_nullable
                      as String,
            opponent: null == opponent
                ? _value.opponent
                : opponent // ignore: cast_nullable_to_non_nullable
                      as String,
            gameTime: null == gameTime
                ? _value.gameTime
                : gameTime // ignore: cast_nullable_to_non_nullable
                      as String,
            playerNumber: null == playerNumber
                ? _value.playerNumber
                : playerNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            playerId: freezed == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            subAction: freezed == subAction
                ? _value.subAction
                : subAction // ignore: cast_nullable_to_non_nullable
                      as String?,
            subActionId: freezed == subActionId
                ? _value.subActionId
                : subActionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as LogType,
            result: null == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as ActionResult,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LogEntryImplCopyWith<$Res>
    implements $LogEntryCopyWith<$Res> {
  factory _$$LogEntryImplCopyWith(
    _$LogEntryImpl value,
    $Res Function(_$LogEntryImpl) then,
  ) = __$$LogEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String matchDate,
    String opponent,
    String gameTime,
    String playerNumber,
    String? playerId,
    String action,
    String? subAction,
    String? subActionId,
    @LogTypeConverter() LogType type,
    @ActionResultConverter() ActionResult result,
  });
}

/// @nodoc
class __$$LogEntryImplCopyWithImpl<$Res>
    extends _$LogEntryCopyWithImpl<$Res, _$LogEntryImpl>
    implements _$$LogEntryImplCopyWith<$Res> {
  __$$LogEntryImplCopyWithImpl(
    _$LogEntryImpl _value,
    $Res Function(_$LogEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? matchDate = null,
    Object? opponent = null,
    Object? gameTime = null,
    Object? playerNumber = null,
    Object? playerId = freezed,
    Object? action = null,
    Object? subAction = freezed,
    Object? subActionId = freezed,
    Object? type = null,
    Object? result = null,
  }) {
    return _then(
      _$LogEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        matchDate: null == matchDate
            ? _value.matchDate
            : matchDate // ignore: cast_nullable_to_non_nullable
                  as String,
        opponent: null == opponent
            ? _value.opponent
            : opponent // ignore: cast_nullable_to_non_nullable
                  as String,
        gameTime: null == gameTime
            ? _value.gameTime
            : gameTime // ignore: cast_nullable_to_non_nullable
                  as String,
        playerNumber: null == playerNumber
            ? _value.playerNumber
            : playerNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        playerId: freezed == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        subAction: freezed == subAction
            ? _value.subAction
            : subAction // ignore: cast_nullable_to_non_nullable
                  as String?,
        subActionId: freezed == subActionId
            ? _value.subActionId
            : subActionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as LogType,
        result: null == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as ActionResult,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LogEntryImpl implements _LogEntry {
  _$LogEntryImpl({
    required this.id,
    required this.matchDate,
    required this.opponent,
    required this.gameTime,
    required this.playerNumber,
    this.playerId,
    required this.action,
    this.subAction,
    this.subActionId,
    @LogTypeConverter() this.type = LogType.action,
    @ActionResultConverter() this.result = ActionResult.none,
  });

  factory _$LogEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogEntryImplFromJson(json);

  @override
  String id;
  @override
  String matchDate;
  @override
  String opponent;
  @override
  String gameTime;
  @override
  String playerNumber;
  @override
  String? playerId;
  @override
  String action;
  @override
  String? subAction;
  @override
  String? subActionId;
  @override
  @JsonKey()
  @LogTypeConverter()
  LogType type;
  @override
  @JsonKey()
  @ActionResultConverter()
  ActionResult result;

  @override
  String toString() {
    return 'LogEntry(id: $id, matchDate: $matchDate, opponent: $opponent, gameTime: $gameTime, playerNumber: $playerNumber, playerId: $playerId, action: $action, subAction: $subAction, subActionId: $subActionId, type: $type, result: $result)';
  }

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogEntryImplCopyWith<_$LogEntryImpl> get copyWith =>
      __$$LogEntryImplCopyWithImpl<_$LogEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogEntryImplToJson(this);
  }
}

abstract class _LogEntry implements LogEntry {
  factory _LogEntry({
    required String id,
    required String matchDate,
    required String opponent,
    required String gameTime,
    required String playerNumber,
    String? playerId,
    required String action,
    String? subAction,
    String? subActionId,
    @LogTypeConverter() LogType type,
    @ActionResultConverter() ActionResult result,
  }) = _$LogEntryImpl;

  factory _LogEntry.fromJson(Map<String, dynamic> json) =
      _$LogEntryImpl.fromJson;

  @override
  String get id;
  set id(String value);
  @override
  String get matchDate;
  set matchDate(String value);
  @override
  String get opponent;
  set opponent(String value);
  @override
  String get gameTime;
  set gameTime(String value);
  @override
  String get playerNumber;
  set playerNumber(String value);
  @override
  String? get playerId;
  set playerId(String? value);
  @override
  String get action;
  set action(String value);
  @override
  String? get subAction;
  set subAction(String? value);
  @override
  String? get subActionId;
  set subActionId(String? value);
  @override
  @LogTypeConverter()
  LogType get type;
  @LogTypeConverter()
  set type(LogType value);
  @override
  @ActionResultConverter()
  ActionResult get result;
  @ActionResultConverter()
  set result(ActionResult value);

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogEntryImplCopyWith<_$LogEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchRecord _$MatchRecordFromJson(Map<String, dynamic> json) {
  return _MatchRecord.fromJson(json);
}

/// @nodoc
mixin _$MatchRecord {
  String get id => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get opponent => throw _privateConstructorUsedError;
  String? get opponentId => throw _privateConstructorUsedError;
  String? get venueName => throw _privateConstructorUsedError;
  String? get venueId => throw _privateConstructorUsedError;
  List<LogEntry> get logs => throw _privateConstructorUsedError;
  @MatchTypeConverter()
  MatchType get matchType => throw _privateConstructorUsedError;
  @MatchResultConverter()
  MatchResult get result => throw _privateConstructorUsedError;
  int? get scoreOwn => throw _privateConstructorUsedError;
  int? get scoreOpponent => throw _privateConstructorUsedError;
  bool get isExtraTime => throw _privateConstructorUsedError;
  int? get extraScoreOwn => throw _privateConstructorUsedError;
  int? get extraScoreOpponent => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MatchRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchRecordCopyWith<MatchRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchRecordCopyWith<$Res> {
  factory $MatchRecordCopyWith(
    MatchRecord value,
    $Res Function(MatchRecord) then,
  ) = _$MatchRecordCopyWithImpl<$Res, MatchRecord>;
  @useResult
  $Res call({
    String id,
    String date,
    String opponent,
    String? opponentId,
    String? venueName,
    String? venueId,
    List<LogEntry> logs,
    @MatchTypeConverter() MatchType matchType,
    @MatchResultConverter() MatchResult result,
    int? scoreOwn,
    int? scoreOpponent,
    bool isExtraTime,
    int? extraScoreOwn,
    int? extraScoreOpponent,
    String? note,
    String? createdAt,
  });
}

/// @nodoc
class _$MatchRecordCopyWithImpl<$Res, $Val extends MatchRecord>
    implements $MatchRecordCopyWith<$Res> {
  _$MatchRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? opponent = null,
    Object? opponentId = freezed,
    Object? venueName = freezed,
    Object? venueId = freezed,
    Object? logs = null,
    Object? matchType = null,
    Object? result = null,
    Object? scoreOwn = freezed,
    Object? scoreOpponent = freezed,
    Object? isExtraTime = null,
    Object? extraScoreOwn = freezed,
    Object? extraScoreOpponent = freezed,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            opponent: null == opponent
                ? _value.opponent
                : opponent // ignore: cast_nullable_to_non_nullable
                      as String,
            opponentId: freezed == opponentId
                ? _value.opponentId
                : opponentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            venueName: freezed == venueName
                ? _value.venueName
                : venueName // ignore: cast_nullable_to_non_nullable
                      as String?,
            venueId: freezed == venueId
                ? _value.venueId
                : venueId // ignore: cast_nullable_to_non_nullable
                      as String?,
            logs: null == logs
                ? _value.logs
                : logs // ignore: cast_nullable_to_non_nullable
                      as List<LogEntry>,
            matchType: null == matchType
                ? _value.matchType
                : matchType // ignore: cast_nullable_to_non_nullable
                      as MatchType,
            result: null == result
                ? _value.result
                : result // ignore: cast_nullable_to_non_nullable
                      as MatchResult,
            scoreOwn: freezed == scoreOwn
                ? _value.scoreOwn
                : scoreOwn // ignore: cast_nullable_to_non_nullable
                      as int?,
            scoreOpponent: freezed == scoreOpponent
                ? _value.scoreOpponent
                : scoreOpponent // ignore: cast_nullable_to_non_nullable
                      as int?,
            isExtraTime: null == isExtraTime
                ? _value.isExtraTime
                : isExtraTime // ignore: cast_nullable_to_non_nullable
                      as bool,
            extraScoreOwn: freezed == extraScoreOwn
                ? _value.extraScoreOwn
                : extraScoreOwn // ignore: cast_nullable_to_non_nullable
                      as int?,
            extraScoreOpponent: freezed == extraScoreOpponent
                ? _value.extraScoreOpponent
                : extraScoreOpponent // ignore: cast_nullable_to_non_nullable
                      as int?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatchRecordImplCopyWith<$Res>
    implements $MatchRecordCopyWith<$Res> {
  factory _$$MatchRecordImplCopyWith(
    _$MatchRecordImpl value,
    $Res Function(_$MatchRecordImpl) then,
  ) = __$$MatchRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String date,
    String opponent,
    String? opponentId,
    String? venueName,
    String? venueId,
    List<LogEntry> logs,
    @MatchTypeConverter() MatchType matchType,
    @MatchResultConverter() MatchResult result,
    int? scoreOwn,
    int? scoreOpponent,
    bool isExtraTime,
    int? extraScoreOwn,
    int? extraScoreOpponent,
    String? note,
    String? createdAt,
  });
}

/// @nodoc
class __$$MatchRecordImplCopyWithImpl<$Res>
    extends _$MatchRecordCopyWithImpl<$Res, _$MatchRecordImpl>
    implements _$$MatchRecordImplCopyWith<$Res> {
  __$$MatchRecordImplCopyWithImpl(
    _$MatchRecordImpl _value,
    $Res Function(_$MatchRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? opponent = null,
    Object? opponentId = freezed,
    Object? venueName = freezed,
    Object? venueId = freezed,
    Object? logs = null,
    Object? matchType = null,
    Object? result = null,
    Object? scoreOwn = freezed,
    Object? scoreOpponent = freezed,
    Object? isExtraTime = null,
    Object? extraScoreOwn = freezed,
    Object? extraScoreOpponent = freezed,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$MatchRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        opponent: null == opponent
            ? _value.opponent
            : opponent // ignore: cast_nullable_to_non_nullable
                  as String,
        opponentId: freezed == opponentId
            ? _value.opponentId
            : opponentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        venueName: freezed == venueName
            ? _value.venueName
            : venueName // ignore: cast_nullable_to_non_nullable
                  as String?,
        venueId: freezed == venueId
            ? _value.venueId
            : venueId // ignore: cast_nullable_to_non_nullable
                  as String?,
        logs: null == logs
            ? _value._logs
            : logs // ignore: cast_nullable_to_non_nullable
                  as List<LogEntry>,
        matchType: null == matchType
            ? _value.matchType
            : matchType // ignore: cast_nullable_to_non_nullable
                  as MatchType,
        result: null == result
            ? _value.result
            : result // ignore: cast_nullable_to_non_nullable
                  as MatchResult,
        scoreOwn: freezed == scoreOwn
            ? _value.scoreOwn
            : scoreOwn // ignore: cast_nullable_to_non_nullable
                  as int?,
        scoreOpponent: freezed == scoreOpponent
            ? _value.scoreOpponent
            : scoreOpponent // ignore: cast_nullable_to_non_nullable
                  as int?,
        isExtraTime: null == isExtraTime
            ? _value.isExtraTime
            : isExtraTime // ignore: cast_nullable_to_non_nullable
                  as bool,
        extraScoreOwn: freezed == extraScoreOwn
            ? _value.extraScoreOwn
            : extraScoreOwn // ignore: cast_nullable_to_non_nullable
                  as int?,
        extraScoreOpponent: freezed == extraScoreOpponent
            ? _value.extraScoreOpponent
            : extraScoreOpponent // ignore: cast_nullable_to_non_nullable
                  as int?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchRecordImpl implements _MatchRecord {
  const _$MatchRecordImpl({
    required this.id,
    required this.date,
    required this.opponent,
    this.opponentId,
    this.venueName,
    this.venueId,
    required final List<LogEntry> logs,
    @MatchTypeConverter() this.matchType = MatchType.official,
    @MatchResultConverter() this.result = MatchResult.none,
    this.scoreOwn,
    this.scoreOpponent,
    this.isExtraTime = false,
    this.extraScoreOwn,
    this.extraScoreOpponent,
    this.note,
    this.createdAt,
  }) : _logs = logs;

  factory _$MatchRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String date;
  @override
  final String opponent;
  @override
  final String? opponentId;
  @override
  final String? venueName;
  @override
  final String? venueId;
  final List<LogEntry> _logs;
  @override
  List<LogEntry> get logs {
    if (_logs is EqualUnmodifiableListView) return _logs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_logs);
  }

  @override
  @JsonKey()
  @MatchTypeConverter()
  final MatchType matchType;
  @override
  @JsonKey()
  @MatchResultConverter()
  final MatchResult result;
  @override
  final int? scoreOwn;
  @override
  final int? scoreOpponent;
  @override
  @JsonKey()
  final bool isExtraTime;
  @override
  final int? extraScoreOwn;
  @override
  final int? extraScoreOpponent;
  @override
  final String? note;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'MatchRecord(id: $id, date: $date, opponent: $opponent, opponentId: $opponentId, venueName: $venueName, venueId: $venueId, logs: $logs, matchType: $matchType, result: $result, scoreOwn: $scoreOwn, scoreOpponent: $scoreOpponent, isExtraTime: $isExtraTime, extraScoreOwn: $extraScoreOwn, extraScoreOpponent: $extraScoreOpponent, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.opponent, opponent) ||
                other.opponent == opponent) &&
            (identical(other.opponentId, opponentId) ||
                other.opponentId == opponentId) &&
            (identical(other.venueName, venueName) ||
                other.venueName == venueName) &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            const DeepCollectionEquality().equals(other._logs, _logs) &&
            (identical(other.matchType, matchType) ||
                other.matchType == matchType) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.scoreOwn, scoreOwn) ||
                other.scoreOwn == scoreOwn) &&
            (identical(other.scoreOpponent, scoreOpponent) ||
                other.scoreOpponent == scoreOpponent) &&
            (identical(other.isExtraTime, isExtraTime) ||
                other.isExtraTime == isExtraTime) &&
            (identical(other.extraScoreOwn, extraScoreOwn) ||
                other.extraScoreOwn == extraScoreOwn) &&
            (identical(other.extraScoreOpponent, extraScoreOpponent) ||
                other.extraScoreOpponent == extraScoreOpponent) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    opponent,
    opponentId,
    venueName,
    venueId,
    const DeepCollectionEquality().hash(_logs),
    matchType,
    result,
    scoreOwn,
    scoreOpponent,
    isExtraTime,
    extraScoreOwn,
    extraScoreOpponent,
    note,
    createdAt,
  );

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchRecordImplCopyWith<_$MatchRecordImpl> get copyWith =>
      __$$MatchRecordImplCopyWithImpl<_$MatchRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchRecordImplToJson(this);
  }
}

abstract class _MatchRecord implements MatchRecord {
  const factory _MatchRecord({
    required final String id,
    required final String date,
    required final String opponent,
    final String? opponentId,
    final String? venueName,
    final String? venueId,
    required final List<LogEntry> logs,
    @MatchTypeConverter() final MatchType matchType,
    @MatchResultConverter() final MatchResult result,
    final int? scoreOwn,
    final int? scoreOpponent,
    final bool isExtraTime,
    final int? extraScoreOwn,
    final int? extraScoreOpponent,
    final String? note,
    final String? createdAt,
  }) = _$MatchRecordImpl;

  factory _MatchRecord.fromJson(Map<String, dynamic> json) =
      _$MatchRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get date;
  @override
  String get opponent;
  @override
  String? get opponentId;
  @override
  String? get venueName;
  @override
  String? get venueId;
  @override
  List<LogEntry> get logs;
  @override
  @MatchTypeConverter()
  MatchType get matchType;
  @override
  @MatchResultConverter()
  MatchResult get result;
  @override
  int? get scoreOwn;
  @override
  int? get scoreOpponent;
  @override
  bool get isExtraTime;
  @override
  int? get extraScoreOwn;
  @override
  int? get extraScoreOpponent;
  @override
  String? get note;
  @override
  String? get createdAt;

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchRecordImplCopyWith<_$MatchRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActionItem _$ActionItemFromJson(Map<String, dynamic> json) {
  return _ActionItem.fromJson(json);
}

/// @nodoc
mixin _$ActionItem {
  String get name => throw _privateConstructorUsedError;
  List<String> get subActions => throw _privateConstructorUsedError;
  bool get isSubRequired => throw _privateConstructorUsedError;
  bool get hasSuccess => throw _privateConstructorUsedError;
  bool get hasFailure => throw _privateConstructorUsedError;

  /// Serializes this ActionItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionItemCopyWith<ActionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionItemCopyWith<$Res> {
  factory $ActionItemCopyWith(
    ActionItem value,
    $Res Function(ActionItem) then,
  ) = _$ActionItemCopyWithImpl<$Res, ActionItem>;
  @useResult
  $Res call({
    String name,
    List<String> subActions,
    bool isSubRequired,
    bool hasSuccess,
    bool hasFailure,
  });
}

/// @nodoc
class _$ActionItemCopyWithImpl<$Res, $Val extends ActionItem>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? subActions = null,
    Object? isSubRequired = null,
    Object? hasSuccess = null,
    Object? hasFailure = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            subActions: null == subActions
                ? _value.subActions
                : subActions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isSubRequired: null == isSubRequired
                ? _value.isSubRequired
                : isSubRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasSuccess: null == hasSuccess
                ? _value.hasSuccess
                : hasSuccess // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasFailure: null == hasFailure
                ? _value.hasFailure
                : hasFailure // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActionItemImplCopyWith<$Res>
    implements $ActionItemCopyWith<$Res> {
  factory _$$ActionItemImplCopyWith(
    _$ActionItemImpl value,
    $Res Function(_$ActionItemImpl) then,
  ) = __$$ActionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    List<String> subActions,
    bool isSubRequired,
    bool hasSuccess,
    bool hasFailure,
  });
}

/// @nodoc
class __$$ActionItemImplCopyWithImpl<$Res>
    extends _$ActionItemCopyWithImpl<$Res, _$ActionItemImpl>
    implements _$$ActionItemImplCopyWith<$Res> {
  __$$ActionItemImplCopyWithImpl(
    _$ActionItemImpl _value,
    $Res Function(_$ActionItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? subActions = null,
    Object? isSubRequired = null,
    Object? hasSuccess = null,
    Object? hasFailure = null,
  }) {
    return _then(
      _$ActionItemImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        subActions: null == subActions
            ? _value._subActions
            : subActions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isSubRequired: null == isSubRequired
            ? _value.isSubRequired
            : isSubRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasSuccess: null == hasSuccess
            ? _value.hasSuccess
            : hasSuccess // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasFailure: null == hasFailure
            ? _value.hasFailure
            : hasFailure // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActionItemImpl implements _ActionItem {
  const _$ActionItemImpl({
    required this.name,
    final List<String> subActions = const [],
    this.isSubRequired = false,
    this.hasSuccess = false,
    this.hasFailure = false,
  }) : _subActions = subActions;

  factory _$ActionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActionItemImplFromJson(json);

  @override
  final String name;
  final List<String> _subActions;
  @override
  @JsonKey()
  List<String> get subActions {
    if (_subActions is EqualUnmodifiableListView) return _subActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subActions);
  }

  @override
  @JsonKey()
  final bool isSubRequired;
  @override
  @JsonKey()
  final bool hasSuccess;
  @override
  @JsonKey()
  final bool hasFailure;

  @override
  String toString() {
    return 'ActionItem(name: $name, subActions: $subActions, isSubRequired: $isSubRequired, hasSuccess: $hasSuccess, hasFailure: $hasFailure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(
              other._subActions,
              _subActions,
            ) &&
            (identical(other.isSubRequired, isSubRequired) ||
                other.isSubRequired == isSubRequired) &&
            (identical(other.hasSuccess, hasSuccess) ||
                other.hasSuccess == hasSuccess) &&
            (identical(other.hasFailure, hasFailure) ||
                other.hasFailure == hasFailure));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    const DeepCollectionEquality().hash(_subActions),
    isSubRequired,
    hasSuccess,
    hasFailure,
  );

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      __$$ActionItemImplCopyWithImpl<_$ActionItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActionItemImplToJson(this);
  }
}

abstract class _ActionItem implements ActionItem {
  const factory _ActionItem({
    required final String name,
    final List<String> subActions,
    final bool isSubRequired,
    final bool hasSuccess,
    final bool hasFailure,
  }) = _$ActionItemImpl;

  factory _ActionItem.fromJson(Map<String, dynamic> json) =
      _$ActionItemImpl.fromJson;

  @override
  String get name;
  @override
  List<String> get subActions;
  @override
  bool get isSubRequired;
  @override
  bool get hasSuccess;
  @override
  bool get hasFailure;

  /// Create a copy of ActionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionItemImplCopyWith<_$ActionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) {
  return _AppSettings.fromJson(json);
}

/// @nodoc
mixin _$AppSettings {
  List<String> get squadNumbers => throw _privateConstructorUsedError;
  set squadNumbers(List<String> value) => throw _privateConstructorUsedError;
  List<ActionItem> get actions => throw _privateConstructorUsedError;
  set actions(List<ActionItem> value) => throw _privateConstructorUsedError;
  int get matchDurationMinutes => throw _privateConstructorUsedError;
  set matchDurationMinutes(int value) => throw _privateConstructorUsedError;
  int get gridColumns => throw _privateConstructorUsedError;
  set gridColumns(int value) => throw _privateConstructorUsedError;
  String get lastOpponent => throw _privateConstructorUsedError;
  set lastOpponent(String value) => throw _privateConstructorUsedError;
  bool get isResultRecordingEnabled => throw _privateConstructorUsedError;
  set isResultRecordingEnabled(bool value) =>
      throw _privateConstructorUsedError;
  bool get isScoreRecordingEnabled => throw _privateConstructorUsedError;
  set isScoreRecordingEnabled(bool value) => throw _privateConstructorUsedError;

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
    AppSettings value,
    $Res Function(AppSettings) then,
  ) = _$AppSettingsCopyWithImpl<$Res, AppSettings>;
  @useResult
  $Res call({
    List<String> squadNumbers,
    List<ActionItem> actions,
    int matchDurationMinutes,
    int gridColumns,
    String lastOpponent,
    bool isResultRecordingEnabled,
    bool isScoreRecordingEnabled,
  });
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res, $Val extends AppSettings>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? squadNumbers = null,
    Object? actions = null,
    Object? matchDurationMinutes = null,
    Object? gridColumns = null,
    Object? lastOpponent = null,
    Object? isResultRecordingEnabled = null,
    Object? isScoreRecordingEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            squadNumbers: null == squadNumbers
                ? _value.squadNumbers
                : squadNumbers // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            actions: null == actions
                ? _value.actions
                : actions // ignore: cast_nullable_to_non_nullable
                      as List<ActionItem>,
            matchDurationMinutes: null == matchDurationMinutes
                ? _value.matchDurationMinutes
                : matchDurationMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            gridColumns: null == gridColumns
                ? _value.gridColumns
                : gridColumns // ignore: cast_nullable_to_non_nullable
                      as int,
            lastOpponent: null == lastOpponent
                ? _value.lastOpponent
                : lastOpponent // ignore: cast_nullable_to_non_nullable
                      as String,
            isResultRecordingEnabled: null == isResultRecordingEnabled
                ? _value.isResultRecordingEnabled
                : isResultRecordingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isScoreRecordingEnabled: null == isScoreRecordingEnabled
                ? _value.isScoreRecordingEnabled
                : isScoreRecordingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppSettingsImplCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$$AppSettingsImplCopyWith(
    _$AppSettingsImpl value,
    $Res Function(_$AppSettingsImpl) then,
  ) = __$$AppSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> squadNumbers,
    List<ActionItem> actions,
    int matchDurationMinutes,
    int gridColumns,
    String lastOpponent,
    bool isResultRecordingEnabled,
    bool isScoreRecordingEnabled,
  });
}

/// @nodoc
class __$$AppSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsCopyWithImpl<$Res, _$AppSettingsImpl>
    implements _$$AppSettingsImplCopyWith<$Res> {
  __$$AppSettingsImplCopyWithImpl(
    _$AppSettingsImpl _value,
    $Res Function(_$AppSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? squadNumbers = null,
    Object? actions = null,
    Object? matchDurationMinutes = null,
    Object? gridColumns = null,
    Object? lastOpponent = null,
    Object? isResultRecordingEnabled = null,
    Object? isScoreRecordingEnabled = null,
  }) {
    return _then(
      _$AppSettingsImpl(
        squadNumbers: null == squadNumbers
            ? _value.squadNumbers
            : squadNumbers // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        actions: null == actions
            ? _value.actions
            : actions // ignore: cast_nullable_to_non_nullable
                  as List<ActionItem>,
        matchDurationMinutes: null == matchDurationMinutes
            ? _value.matchDurationMinutes
            : matchDurationMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        gridColumns: null == gridColumns
            ? _value.gridColumns
            : gridColumns // ignore: cast_nullable_to_non_nullable
                  as int,
        lastOpponent: null == lastOpponent
            ? _value.lastOpponent
            : lastOpponent // ignore: cast_nullable_to_non_nullable
                  as String,
        isResultRecordingEnabled: null == isResultRecordingEnabled
            ? _value.isResultRecordingEnabled
            : isResultRecordingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isScoreRecordingEnabled: null == isScoreRecordingEnabled
            ? _value.isScoreRecordingEnabled
            : isScoreRecordingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsImpl implements _AppSettings {
  _$AppSettingsImpl({
    required this.squadNumbers,
    required this.actions,
    this.matchDurationMinutes = 5,
    this.gridColumns = 3,
    this.lastOpponent = "練習試合",
    this.isResultRecordingEnabled = false,
    this.isScoreRecordingEnabled = false,
  });

  factory _$AppSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsImplFromJson(json);

  @override
  List<String> squadNumbers;
  @override
  List<ActionItem> actions;
  @override
  @JsonKey()
  int matchDurationMinutes;
  @override
  @JsonKey()
  int gridColumns;
  @override
  @JsonKey()
  String lastOpponent;
  @override
  @JsonKey()
  bool isResultRecordingEnabled;
  @override
  @JsonKey()
  bool isScoreRecordingEnabled;

  @override
  String toString() {
    return 'AppSettings(squadNumbers: $squadNumbers, actions: $actions, matchDurationMinutes: $matchDurationMinutes, gridColumns: $gridColumns, lastOpponent: $lastOpponent, isResultRecordingEnabled: $isResultRecordingEnabled, isScoreRecordingEnabled: $isScoreRecordingEnabled)';
  }

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      __$$AppSettingsImplCopyWithImpl<_$AppSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsImplToJson(this);
  }
}

abstract class _AppSettings implements AppSettings {
  factory _AppSettings({
    required List<String> squadNumbers,
    required List<ActionItem> actions,
    int matchDurationMinutes,
    int gridColumns,
    String lastOpponent,
    bool isResultRecordingEnabled,
    bool isScoreRecordingEnabled,
  }) = _$AppSettingsImpl;

  factory _AppSettings.fromJson(Map<String, dynamic> json) =
      _$AppSettingsImpl.fromJson;

  @override
  List<String> get squadNumbers;
  set squadNumbers(List<String> value);
  @override
  List<ActionItem> get actions;
  set actions(List<ActionItem> value);
  @override
  int get matchDurationMinutes;
  set matchDurationMinutes(int value);
  @override
  int get gridColumns;
  set gridColumns(int value);
  @override
  String get lastOpponent;
  set lastOpponent(String value);
  @override
  bool get isResultRecordingEnabled;
  set isResultRecordingEnabled(bool value);
  @override
  bool get isScoreRecordingEnabled;
  set isScoreRecordingEnabled(bool value);

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
