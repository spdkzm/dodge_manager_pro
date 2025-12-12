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

SubActionDefinition _$SubActionDefinitionFromJson(Map<String, dynamic> json) {
  return _SubActionDefinition.fromJson(json);
}

/// @nodoc
mixin _$SubActionDefinition {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category =>
      throw _privateConstructorUsedError; // AppConstants.categorySuccess etc.
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this SubActionDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubActionDefinitionCopyWith<SubActionDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubActionDefinitionCopyWith<$Res> {
  factory $SubActionDefinitionCopyWith(
    SubActionDefinition value,
    $Res Function(SubActionDefinition) then,
  ) = _$SubActionDefinitionCopyWithImpl<$Res, SubActionDefinition>;
  @useResult
  $Res call({String id, String name, String category, int sortOrder});
}

/// @nodoc
class _$SubActionDefinitionCopyWithImpl<$Res, $Val extends SubActionDefinition>
    implements $SubActionDefinitionCopyWith<$Res> {
  _$SubActionDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? sortOrder = null,
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
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubActionDefinitionImplCopyWith<$Res>
    implements $SubActionDefinitionCopyWith<$Res> {
  factory _$$SubActionDefinitionImplCopyWith(
    _$SubActionDefinitionImpl value,
    $Res Function(_$SubActionDefinitionImpl) then,
  ) = __$$SubActionDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String category, int sortOrder});
}

/// @nodoc
class __$$SubActionDefinitionImplCopyWithImpl<$Res>
    extends _$SubActionDefinitionCopyWithImpl<$Res, _$SubActionDefinitionImpl>
    implements _$$SubActionDefinitionImplCopyWith<$Res> {
  __$$SubActionDefinitionImplCopyWithImpl(
    _$SubActionDefinitionImpl _value,
    $Res Function(_$SubActionDefinitionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _$SubActionDefinitionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubActionDefinitionImpl implements _SubActionDefinition {
  const _$SubActionDefinitionImpl({
    required this.id,
    required this.name,
    required this.category,
    this.sortOrder = 0,
  });

  factory _$SubActionDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubActionDefinitionImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String category;
  // AppConstants.categorySuccess etc.
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'SubActionDefinition(id: $id, name: $name, category: $category, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubActionDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, category, sortOrder);

  /// Create a copy of SubActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubActionDefinitionImplCopyWith<_$SubActionDefinitionImpl> get copyWith =>
      __$$SubActionDefinitionImplCopyWithImpl<_$SubActionDefinitionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubActionDefinitionImplToJson(this);
  }
}

abstract class _SubActionDefinition implements SubActionDefinition {
  const factory _SubActionDefinition({
    required final String id,
    required final String name,
    required final String category,
    final int sortOrder,
  }) = _$SubActionDefinitionImpl;

  factory _SubActionDefinition.fromJson(Map<String, dynamic> json) =
      _$SubActionDefinitionImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get category; // AppConstants.categorySuccess etc.
  @override
  int get sortOrder;

  /// Create a copy of SubActionDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubActionDefinitionImplCopyWith<_$SubActionDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActionDefinition _$ActionDefinitionFromJson(Map<String, dynamic> json) {
  return _ActionDefinition.fromJson(json);
}

/// @nodoc
mixin _$ActionDefinition {
  String get id => throw _privateConstructorUsedError;
  set id(String value) => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  set name(String value) => throw _privateConstructorUsedError;
  List<SubActionDefinition> get subActions =>
      throw _privateConstructorUsedError;
  set subActions(List<SubActionDefinition> value) =>
      throw _privateConstructorUsedError;
  bool get isSubRequired => throw _privateConstructorUsedError;
  set isSubRequired(bool value) => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  set sortOrder(int value) => throw _privateConstructorUsedError;
  int get positionIndex => throw _privateConstructorUsedError;
  set positionIndex(int value) => throw _privateConstructorUsedError;
  int get successPositionIndex => throw _privateConstructorUsedError;
  set successPositionIndex(int value) => throw _privateConstructorUsedError;
  int get failurePositionIndex => throw _privateConstructorUsedError;
  set failurePositionIndex(int value) => throw _privateConstructorUsedError;
  bool get hasSuccess => throw _privateConstructorUsedError;
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
    List<SubActionDefinition> subActions,
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
    Object? subActions = null,
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
            subActions: null == subActions
                ? _value.subActions
                : subActions // ignore: cast_nullable_to_non_nullable
                      as List<SubActionDefinition>,
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
    List<SubActionDefinition> subActions,
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
    Object? subActions = null,
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
        subActions: null == subActions
            ? _value.subActions
            : subActions // ignore: cast_nullable_to_non_nullable
                  as List<SubActionDefinition>,
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
    this.subActions = const [],
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
  List<SubActionDefinition> subActions;
  @override
  @JsonKey()
  bool isSubRequired;
  @override
  @JsonKey()
  int sortOrder;
  @override
  @JsonKey()
  int positionIndex;
  @override
  @JsonKey()
  int successPositionIndex;
  @override
  @JsonKey()
  int failurePositionIndex;
  @override
  @JsonKey()
  bool hasSuccess;
  @override
  @JsonKey()
  bool hasFailure;

  @override
  String toString() {
    return 'ActionDefinition(id: $id, name: $name, subActions: $subActions, isSubRequired: $isSubRequired, sortOrder: $sortOrder, positionIndex: $positionIndex, successPositionIndex: $successPositionIndex, failurePositionIndex: $failurePositionIndex, hasSuccess: $hasSuccess, hasFailure: $hasFailure)';
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
    List<SubActionDefinition> subActions,
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
  List<SubActionDefinition> get subActions;
  set subActions(List<SubActionDefinition> value);
  @override
  bool get isSubRequired;
  set isSubRequired(bool value);
  @override
  int get sortOrder;
  set sortOrder(int value);
  @override
  int get positionIndex;
  set positionIndex(int value);
  @override
  int get successPositionIndex;
  set successPositionIndex(int value);
  @override
  int get failurePositionIndex;
  set failurePositionIndex(int value);
  @override
  bool get hasSuccess;
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
