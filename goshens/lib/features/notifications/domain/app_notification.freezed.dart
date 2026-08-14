// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppNotification {

 String get id;@JsonKey(name: 'recipient_id') String get recipientId; String get type; String get title; String get body;@JsonKey(name: 'related_appointment_id') String? get relatedAppointmentId;@JsonKey(name: 'related_prescription_id') String? get relatedPrescriptionId;@JsonKey(name: 'related_conversation_id') String? get relatedConversationId;@JsonKey(name: 'is_read') bool get isRead;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.relatedAppointmentId, relatedAppointmentId) || other.relatedAppointmentId == relatedAppointmentId)&&(identical(other.relatedPrescriptionId, relatedPrescriptionId) || other.relatedPrescriptionId == relatedPrescriptionId)&&(identical(other.relatedConversationId, relatedConversationId) || other.relatedConversationId == relatedConversationId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recipientId,type,title,body,relatedAppointmentId,relatedPrescriptionId,relatedConversationId,isRead,createdAt);

@override
String toString() {
  return 'AppNotification(id: $id, recipientId: $recipientId, type: $type, title: $title, body: $body, relatedAppointmentId: $relatedAppointmentId, relatedPrescriptionId: $relatedPrescriptionId, relatedConversationId: $relatedConversationId, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'recipient_id') String recipientId, String type, String title, String body,@JsonKey(name: 'related_appointment_id') String? relatedAppointmentId,@JsonKey(name: 'related_prescription_id') String? relatedPrescriptionId,@JsonKey(name: 'related_conversation_id') String? relatedConversationId,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recipientId = null,Object? type = null,Object? title = null,Object? body = null,Object? relatedAppointmentId = freezed,Object? relatedPrescriptionId = freezed,Object? relatedConversationId = freezed,Object? isRead = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,relatedAppointmentId: freezed == relatedAppointmentId ? _self.relatedAppointmentId : relatedAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,relatedPrescriptionId: freezed == relatedPrescriptionId ? _self.relatedPrescriptionId : relatedPrescriptionId // ignore: cast_nullable_to_non_nullable
as String?,relatedConversationId: freezed == relatedConversationId ? _self.relatedConversationId : relatedConversationId // ignore: cast_nullable_to_non_nullable
as String?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'recipient_id')  String recipientId,  String type,  String title,  String body, @JsonKey(name: 'related_appointment_id')  String? relatedAppointmentId, @JsonKey(name: 'related_prescription_id')  String? relatedPrescriptionId, @JsonKey(name: 'related_conversation_id')  String? relatedConversationId, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.recipientId,_that.type,_that.title,_that.body,_that.relatedAppointmentId,_that.relatedPrescriptionId,_that.relatedConversationId,_that.isRead,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'recipient_id')  String recipientId,  String type,  String title,  String body, @JsonKey(name: 'related_appointment_id')  String? relatedAppointmentId, @JsonKey(name: 'related_prescription_id')  String? relatedPrescriptionId, @JsonKey(name: 'related_conversation_id')  String? relatedConversationId, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.id,_that.recipientId,_that.type,_that.title,_that.body,_that.relatedAppointmentId,_that.relatedPrescriptionId,_that.relatedConversationId,_that.isRead,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'recipient_id')  String recipientId,  String type,  String title,  String body, @JsonKey(name: 'related_appointment_id')  String? relatedAppointmentId, @JsonKey(name: 'related_prescription_id')  String? relatedPrescriptionId, @JsonKey(name: 'related_conversation_id')  String? relatedConversationId, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.recipientId,_that.type,_that.title,_that.body,_that.relatedAppointmentId,_that.relatedPrescriptionId,_that.relatedConversationId,_that.isRead,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppNotification implements AppNotification {
  const _AppNotification({required this.id, @JsonKey(name: 'recipient_id') required this.recipientId, required this.type, required this.title, required this.body, @JsonKey(name: 'related_appointment_id') this.relatedAppointmentId, @JsonKey(name: 'related_prescription_id') this.relatedPrescriptionId, @JsonKey(name: 'related_conversation_id') this.relatedConversationId, @JsonKey(name: 'is_read') this.isRead = false, @JsonKey(name: 'created_at') required this.createdAt});
  factory _AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'recipient_id') final  String recipientId;
@override final  String type;
@override final  String title;
@override final  String body;
@override@JsonKey(name: 'related_appointment_id') final  String? relatedAppointmentId;
@override@JsonKey(name: 'related_prescription_id') final  String? relatedPrescriptionId;
@override@JsonKey(name: 'related_conversation_id') final  String? relatedConversationId;
@override@JsonKey(name: 'is_read') final  bool isRead;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.relatedAppointmentId, relatedAppointmentId) || other.relatedAppointmentId == relatedAppointmentId)&&(identical(other.relatedPrescriptionId, relatedPrescriptionId) || other.relatedPrescriptionId == relatedPrescriptionId)&&(identical(other.relatedConversationId, relatedConversationId) || other.relatedConversationId == relatedConversationId)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recipientId,type,title,body,relatedAppointmentId,relatedPrescriptionId,relatedConversationId,isRead,createdAt);

@override
String toString() {
  return 'AppNotification(id: $id, recipientId: $recipientId, type: $type, title: $title, body: $body, relatedAppointmentId: $relatedAppointmentId, relatedPrescriptionId: $relatedPrescriptionId, relatedConversationId: $relatedConversationId, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'recipient_id') String recipientId, String type, String title, String body,@JsonKey(name: 'related_appointment_id') String? relatedAppointmentId,@JsonKey(name: 'related_prescription_id') String? relatedPrescriptionId,@JsonKey(name: 'related_conversation_id') String? relatedConversationId,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recipientId = null,Object? type = null,Object? title = null,Object? body = null,Object? relatedAppointmentId = freezed,Object? relatedPrescriptionId = freezed,Object? relatedConversationId = freezed,Object? isRead = null,Object? createdAt = null,}) {
  return _then(_AppNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,relatedAppointmentId: freezed == relatedAppointmentId ? _self.relatedAppointmentId : relatedAppointmentId // ignore: cast_nullable_to_non_nullable
as String?,relatedPrescriptionId: freezed == relatedPrescriptionId ? _self.relatedPrescriptionId : relatedPrescriptionId // ignore: cast_nullable_to_non_nullable
as String?,relatedConversationId: freezed == relatedConversationId ? _self.relatedConversationId : relatedConversationId // ignore: cast_nullable_to_non_nullable
as String?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
