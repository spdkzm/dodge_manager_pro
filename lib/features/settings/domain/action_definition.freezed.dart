// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ActionDefinition _$ActionDefinitionFromJson(Map<String, dynamic> json) {
  return _ActionDefinition.fromJson(json);
}

/// @nodoc
mixin _$ActionDefinition {
  String get id => throw _privateConstructorUsedError;
  set id(String value) => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  set name(String value) => throw _privateConstructorUsedError;
  Map<String, List<String>> get subActionsMap =>
      throw _privateConstructorUsedError;
  set subActionsMap(Map<String, List<String>> value) =>
      throw _privateConstructorUsedError;
  bool get isSubRequired => throw _privateConstructorUsedError;
  set isSubRequired(bool value) => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  set sortOrder(int value) => throw _privateConstructorUsedError;
  int get positionIndex => throw _privateConstructorUsedError;
  set positionIndex(int value) =>
      throw _privateConstructorUsedError; // 通常ボタンの位置
  int get successPositionIndex =>
      throw _privateConstructorUsedError; // 通常ボタンの位置
  set successPositionIndex(int value) =>
      throw _privateConstructorUsedError; // ★追加: 成功ボタンの位置
  int get failurePositionIndex =>
      throw _privateConstructorUsedError; // ★追加: 成功ボタンの位置
  set failurePositionIndex(int value) =>
      throw _privateConstructorUsedError; // ★追加: 失敗ボタンの位置
  bool get hasSuccess => throw _privateConstructorUsedError; // ★追加: 失敗ボタンの位置
  set hasSuccess(bool value) => throw _privateConstructorUsedError;
  bool get hasFailure => throw _privateConstructorUsedError;
  set hasFailure(bool value) => throw _privateConstructorUsedError;

  /// Serializes this ActionDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActionDefinitionCopyWith<ActionDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActionDefinitionCopyWith<$Res> {
  factory $ActionDefinitionCopyWith(
    ActionDefinition value,
    $Res Function(ActionDefinition) then,
  ) = _$ActionDefinitionCopyWithImpl<$Res, ActionDefinition>;
  @useResult
  $Res call({
    String id,
    String name,
    Map<String, List<String>> subActionsMap,
    bool isSubRequired,
    int sortOrder,
    int positionIndex,
    int successPositionIndex,
    int failurePositionIndex,
    bool hasSuccess,
    bool hasFailure,
  });
}

/// @nodoc
class _$ActionDefinitionCopyWithImpl<$Res, $Val extends ActionDefinition>
    implements $ActionDefinitionCopyWith<$Res> {
  _$ActionDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? subActionsMap = null,
    Object? isSubRequired = null,
    Object? sortOrder = null,
    Object? positionIndex = null,
    Object? successPositionIndex = null,
    Object? failurePositionIndex = null,
    Object? hasSuccess = null,
    Object? hasFailure = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            subActionsMap: null == subActionsMap
                ? _value.subActionsMap
                : subActionsMap // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<String>>,
            isSubRequired: null == isSubRequired
                ? _value.isSubRequired
                : isSubRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            positionIndex: null == positionIndex
                ? _value.positionIndex
                : positionIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            successPositionIndex: null == successPositionIndex
                ? _value.successPositionIndex
                : successPositionIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            failurePositionIndex: null == failurePositionIndex
                ? _value.failurePositionIndex
                : failurePositionIndex // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$ActionDefinitionImplCopyWith<$Res>
    implements $ActionDefinitionCopyWith<$Res> {
  factory _$$ActionDefinitionImplCopyWith(
    _$ActionDefinitionImpl value,
    $Res Function(_$ActionDefinitionImpl) then,
  ) = __$$ActionDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    Map<String, List<String>> subActionsMap,
    bool isSubRequired,
    int sortOrder,
    int positionIndex,
    int successPositionIndex,
    int failurePositionIndex,
    bool hasSuccess,
    bool hasFailure,
  });
}

/// @nodoc
class __$$ActionDefinitionImplCopyWithImpl<$Res>
    extends _$ActionDefinitionCopyWithImpl<$Res, _$ActionDefinitionImpl>
    implements _$$ActionDefinitionImplCopyWith<$Res> {
  __$$ActionDefinitionImplCopyWithImpl(
    _$ActionDefinitionImpl _value,
    $Res Function(_$ActionDefinitionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? subActionsMap = null,
    Object? isSubRequired = null,
    Object? sortOrder = null,
    Object? positionIndex = null,
    Object? successPositionIndex = null,
    Object? failurePositionIndex = null,
    Object? hasSuccess = null,
    Object? hasFailure = null,
  }) {
    return _then(
      _$ActionDefinitionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        subActionsMap: null == subActionsMap
            ? _value.subActionsMap
            : subActionsMap // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<String>>,
        isSubRequired: null == isSubRequired
            ? _value.isSubRequired
            : isSubRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        positionIndex: null == positionIndex
            ? _value.positionIndex
            : positionIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        successPositionIndex: null == successPositionIndex
            ? _value.successPositionIndex
            : successPositionIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        failurePositionIndex: null == failurePositionIndex
            ? _value.failurePositionIndex
            : failurePositionIndex // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$ActionDefinitionImpl implements _ActionDefinition {
  _$ActionDefinitionImpl({
    this.id = '',
    required this.name,
    this.subActionsMap = const {'default': [], 'success': [], 'failure': []},
    this.isSubRequired = false,
    this.sortOrder = 0,
    this.positionIndex = 0,
    this.successPositionIndex = 0,
    this.failurePositionIndex = 0,
    this.hasSuccess = false,
    this.hasFailure = false,
  });

  factory _$ActionDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActionDefinitionImplFromJson(json);

  @override
  @JsonKey()
  String id;
  @override
  String name;
  @override
  @JsonKey()
  Map<String, List<String>> subActionsMap;
  @override
  @JsonKey()
  bool isSubRequired;
  @override
  @JsonKey()
  int sortOrder;
  @override
  @JsonKey()
  int positionIndex;
  // 通常ボタンの位置
  @override
  @JsonKey()
  int successPositionIndex;
  // ★追加: 成功ボタンの位置
  @override
  @JsonKey()
  int failurePositionIndex;
  // ★追加: 失敗ボタンの位置
  @override
  @JsonKey()
  bool hasSuccess;
  @override
  @JsonKey()
  bool hasFailure;

  @override
  String toString() {
    return 'ActionDefinition(id: $id, name: $name, subActionsMap: $subActionsMap, isSubRequired: $isSubRequired, sortOrder: $sortOrder, positionIndex: $positionIndex, successPositionIndex: $successPositionIndex, failurePositionIndex: $failurePositionIndex, hasSuccess: $hasSuccess, hasFailure: $hasFailure)';
  }

  /// Create a copy of ActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActionDefinitionImplCopyWith<_$ActionDefinitionImpl> get copyWith =>
      __$$ActionDefinitionImplCopyWithImpl<_$ActionDefinitionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ActionDefinitionImplToJson(this);
  }
}

abstract class _ActionDefinition implements ActionDefinition {
  factory _ActionDefinition({
    String id,
    required String name,
    Map<String, List<String>> subActionsMap,
    bool isSubRequired,
    int sortOrder,
    int positionIndex,
    int successPositionIndex,
    int failurePositionIndex,
    bool hasSuccess,
    bool hasFailure,
  }) = _$ActionDefinitionImpl;

  factory _ActionDefinition.fromJson(Map<String, dynamic> json) =
      _$ActionDefinitionImpl.fromJson;

  @override
  String get id;
  set id(String value);
  @override
  String get name;
  set name(String value);
  @override
  Map<String, List<String>> get subActionsMap;
  set subActionsMap(Map<String, List<String>> value);
  @override
  bool get isSubRequired;
  set isSubRequired(bool value);
  @override
  int get sortOrder;
  set sortOrder(int value);
  @override
  int get positionIndex;
  set positionIndex(int value); // 通常ボタンの位置
  @override
  int get successPositionIndex; // 通常ボタンの位置
  set successPositionIndex(int value); // ★追加: 成功ボタンの位置
  @override
  int get failurePositionIndex; // ★追加: 成功ボタンの位置
  set failurePositionIndex(int value); // ★追加: 失敗ボタンの位置
  @override
  bool get hasSuccess; // ★追加: 失敗ボタンの位置
  set hasSuccess(bool value);
  @override
  bool get hasFailure;
  set hasFailure(bool value);

  /// Create a copy of ActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActionDefinitionImplCopyWith<_$ActionDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
