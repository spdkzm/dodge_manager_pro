// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ActionStats {
  String get actionName => throw _privateConstructorUsedError;
  int get successCount => throw _privateConstructorUsedError;
  int get failureCount => throw _privateConstructorUsedError;
  int get totalCount =>
      throw _privateConstructorUsedError; // ★追加: 詳細項目ごとのカウント (例: {"正面": 5, "横": 2})
  Map<String, int> get subActionCounts => throw _privateConstructorUsedError;

  /// Create a copy of ActionStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionStatsCopyWith<ActionStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionStatsCopyWith<$Res> {
  factory $ActionStatsCopyWith(
    ActionStats value,
    $Res Function(ActionStats) then,
  ) = _$ActionStatsCopyWithImpl<$Res, ActionStats>;
  @useResult
  $Res call({
    String actionName,
    int successCount,
    int failureCount,
    int totalCount,
    Map<String, int> subActionCounts,
  });
}

/// @nodoc
class _$ActionStatsCopyWithImpl<$Res, $Val extends ActionStats>
    implements $ActionStatsCopyWith<$Res> {
  _$ActionStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? actionName = null,
    Object? successCount = null,
    Object? failureCount = null,
    Object? totalCount = null,
    Object? subActionCounts = null,
  }) {
    return _then(
      _value.copyWith(
            actionName: null == actionName
                ? _value.actionName
                : actionName // ignore: cast_nullable_to_non_nullable
                      as String,
            successCount: null == successCount
                ? _value.successCount
                : successCount // ignore: cast_nullable_to_non_nullable
                      as int,
            failureCount: null == failureCount
                ? _value.failureCount
                : failureCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCount: null == totalCount
                ? _value.totalCount
                : totalCount // ignore: cast_nullable_to_non_nullable
                      as int,
            subActionCounts: null == subActionCounts
                ? _value.subActionCounts
                : subActionCounts // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActionStatsImplCopyWith<$Res>
    implements $ActionStatsCopyWith<$Res> {
  factory _$$ActionStatsImplCopyWith(
    _$ActionStatsImpl value,
    $Res Function(_$ActionStatsImpl) then,
  ) = __$$ActionStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String actionName,
    int successCount,
    int failureCount,
    int totalCount,
    Map<String, int> subActionCounts,
  });
}

/// @nodoc
class __$$ActionStatsImplCopyWithImpl<$Res>
    extends _$ActionStatsCopyWithImpl<$Res, _$ActionStatsImpl>
    implements _$$ActionStatsImplCopyWith<$Res> {
  __$$ActionStatsImplCopyWithImpl(
    _$ActionStatsImpl _value,
    $Res Function(_$ActionStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActionStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? actionName = null,
    Object? successCount = null,
    Object? failureCount = null,
    Object? totalCount = null,
    Object? subActionCounts = null,
  }) {
    return _then(
      _$ActionStatsImpl(
        actionName: null == actionName
            ? _value.actionName
            : actionName // ignore: cast_nullable_to_non_nullable
                  as String,
        successCount: null == successCount
            ? _value.successCount
            : successCount // ignore: cast_nullable_to_non_nullable
                  as int,
        failureCount: null == failureCount
            ? _value.failureCount
            : failureCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCount: null == totalCount
            ? _value.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        subActionCounts: null == subActionCounts
            ? _value._subActionCounts
            : subActionCounts // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc

class _$ActionStatsImpl implements _ActionStats {
  const _$ActionStatsImpl({
    required this.actionName,
    this.successCount = 0,
    this.failureCount = 0,
    this.totalCount = 0,
    final Map<String, int> subActionCounts = const {},
  }) : _subActionCounts = subActionCounts;

  @override
  final String actionName;
  @override
  @JsonKey()
  final int successCount;
  @override
  @JsonKey()
  final int failureCount;
  @override
  @JsonKey()
  final int totalCount;
  // ★追加: 詳細項目ごとのカウント (例: {"正面": 5, "横": 2})
  final Map<String, int> _subActionCounts;
  // ★追加: 詳細項目ごとのカウント (例: {"正面": 5, "横": 2})
  @override
  @JsonKey()
  Map<String, int> get subActionCounts {
    if (_subActionCounts is EqualUnmodifiableMapView) return _subActionCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_subActionCounts);
  }

  @override
  String toString() {
    return 'ActionStats(actionName: $actionName, successCount: $successCount, failureCount: $failureCount, totalCount: $totalCount, subActionCounts: $subActionCounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActionStatsImpl &&
            (identical(other.actionName, actionName) ||
                other.actionName == actionName) &&
            (identical(other.successCount, successCount) ||
                other.successCount == successCount) &&
            (identical(other.failureCount, failureCount) ||
                other.failureCount == failureCount) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            const DeepCollectionEquality().equals(
              other._subActionCounts,
              _subActionCounts,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    actionName,
    successCount,
    failureCount,
    totalCount,
    const DeepCollectionEquality().hash(_subActionCounts),
  );

  /// Create a copy of ActionStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionStatsImplCopyWith<_$ActionStatsImpl> get copyWith =>
      __$$ActionStatsImplCopyWithImpl<_$ActionStatsImpl>(this, _$identity);
}

abstract class _ActionStats implements ActionStats {
  const factory _ActionStats({
    required final String actionName,
    final int successCount,
    final int failureCount,
    final int totalCount,
    final Map<String, int> subActionCounts,
  }) = _$ActionStatsImpl;

  @override
  String get actionName;
  @override
  int get successCount;
  @override
  int get failureCount;
  @override
  int get totalCount; // ★追加: 詳細項目ごとのカウント (例: {"正面": 5, "横": 2})
  @override
  Map<String, int> get subActionCounts;

  /// Create a copy of ActionStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionStatsImplCopyWith<_$ActionStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PlayerStats {
  String get playerId => throw _privateConstructorUsedError;
  String get playerNumber => throw _privateConstructorUsedError;
  String get playerName => throw _privateConstructorUsedError;
  int get matchesPlayed => throw _privateConstructorUsedError;
  Map<String, ActionStats> get actions => throw _privateConstructorUsedError;

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerStatsCopyWith<PlayerStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStatsCopyWith<$Res> {
  factory $PlayerStatsCopyWith(
    PlayerStats value,
    $Res Function(PlayerStats) then,
  ) = _$PlayerStatsCopyWithImpl<$Res, PlayerStats>;
  @useResult
  $Res call({
    String playerId,
    String playerNumber,
    String playerName,
    int matchesPlayed,
    Map<String, ActionStats> actions,
  });
}

/// @nodoc
class _$PlayerStatsCopyWithImpl<$Res, $Val extends PlayerStats>
    implements $PlayerStatsCopyWith<$Res> {
  _$PlayerStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerNumber = null,
    Object? playerName = null,
    Object? matchesPlayed = null,
    Object? actions = null,
  }) {
    return _then(
      _value.copyWith(
            playerId: null == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String,
            playerNumber: null == playerNumber
                ? _value.playerNumber
                : playerNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            playerName: null == playerName
                ? _value.playerName
                : playerName // ignore: cast_nullable_to_non_nullable
                      as String,
            matchesPlayed: null == matchesPlayed
                ? _value.matchesPlayed
                : matchesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            actions: null == actions
                ? _value.actions
                : actions // ignore: cast_nullable_to_non_nullable
                      as Map<String, ActionStats>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerStatsImplCopyWith<$Res>
    implements $PlayerStatsCopyWith<$Res> {
  factory _$$PlayerStatsImplCopyWith(
    _$PlayerStatsImpl value,
    $Res Function(_$PlayerStatsImpl) then,
  ) = __$$PlayerStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String playerId,
    String playerNumber,
    String playerName,
    int matchesPlayed,
    Map<String, ActionStats> actions,
  });
}

/// @nodoc
class __$$PlayerStatsImplCopyWithImpl<$Res>
    extends _$PlayerStatsCopyWithImpl<$Res, _$PlayerStatsImpl>
    implements _$$PlayerStatsImplCopyWith<$Res> {
  __$$PlayerStatsImplCopyWithImpl(
    _$PlayerStatsImpl _value,
    $Res Function(_$PlayerStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerNumber = null,
    Object? playerName = null,
    Object? matchesPlayed = null,
    Object? actions = null,
  }) {
    return _then(
      _$PlayerStatsImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        playerNumber: null == playerNumber
            ? _value.playerNumber
            : playerNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        playerName: null == playerName
            ? _value.playerName
            : playerName // ignore: cast_nullable_to_non_nullable
                  as String,
        matchesPlayed: null == matchesPlayed
            ? _value.matchesPlayed
            : matchesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        actions: null == actions
            ? _value._actions
            : actions // ignore: cast_nullable_to_non_nullable
                  as Map<String, ActionStats>,
      ),
    );
  }
}

/// @nodoc

class _$PlayerStatsImpl implements _PlayerStats {
  const _$PlayerStatsImpl({
    required this.playerId,
    required this.playerNumber,
    required this.playerName,
    this.matchesPlayed = 0,
    final Map<String, ActionStats> actions = const {},
  }) : _actions = actions;

  @override
  final String playerId;
  @override
  final String playerNumber;
  @override
  final String playerName;
  @override
  @JsonKey()
  final int matchesPlayed;
  final Map<String, ActionStats> _actions;
  @override
  @JsonKey()
  Map<String, ActionStats> get actions {
    if (_actions is EqualUnmodifiableMapView) return _actions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_actions);
  }

  @override
  String toString() {
    return 'PlayerStats(playerId: $playerId, playerNumber: $playerNumber, playerName: $playerName, matchesPlayed: $matchesPlayed, actions: $actions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStatsImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.playerNumber, playerNumber) ||
                other.playerNumber == playerNumber) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.matchesPlayed, matchesPlayed) ||
                other.matchesPlayed == matchesPlayed) &&
            const DeepCollectionEquality().equals(other._actions, _actions));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    playerId,
    playerNumber,
    playerName,
    matchesPlayed,
    const DeepCollectionEquality().hash(_actions),
  );

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStatsImplCopyWith<_$PlayerStatsImpl> get copyWith =>
      __$$PlayerStatsImplCopyWithImpl<_$PlayerStatsImpl>(this, _$identity);
}

abstract class _PlayerStats implements PlayerStats {
  const factory _PlayerStats({
    required final String playerId,
    required final String playerNumber,
    required final String playerName,
    final int matchesPlayed,
    final Map<String, ActionStats> actions,
  }) = _$PlayerStatsImpl;

  @override
  String get playerId;
  @override
  String get playerNumber;
  @override
  String get playerName;
  @override
  int get matchesPlayed;
  @override
  Map<String, ActionStats> get actions;

  /// Create a copy of PlayerStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerStatsImplCopyWith<_$PlayerStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
