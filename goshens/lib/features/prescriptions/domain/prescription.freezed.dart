// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prescription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Prescription {

 String get id;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'appointment_id') String? get appointmentId;@JsonKey(name: 'doctor_name') String get doctorName; List<String> get medications; String get instructions;@JsonKey(name: 'pdf_url') String? get pdfUrl;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'profiles') Map<String, dynamic>? get patientProfile;
/// Create a copy of Prescription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrescriptionCopyWith<Prescription> get copyWith => _$PrescriptionCopyWithImpl<Prescription>(this as Prescription, _$identity);

  /// Serializes this Prescription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Prescription&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.doctorName, doctorName) || other.doctorName == doctorName)&&const DeepCollectionEquality().equals(other.medications, medications)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.patientProfile, patientProfile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,appointmentId,doctorName,const DeepCollectionEquality().hash(medications),instructions,pdfUrl,createdAt,const DeepCollectionEquality().hash(patientProfile));

@override
String toString() {
  return 'Prescription(id: $id, patientId: $patientId, appointmentId: $appointmentId, doctorName: $doctorName, medications: $medications, instructions: $instructions, pdfUrl: $pdfUrl, createdAt: $createdAt, patientProfile: $patientProfile)';
}


}

/// @nodoc
abstract mixin class $PrescriptionCopyWith<$Res>  {
  factory $PrescriptionCopyWith(Prescription value, $Res Function(Prescription) _then) = _$PrescriptionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'appointment_id') String? appointmentId,@JsonKey(name: 'doctor_name') String doctorName, List<String> medications, String instructions,@JsonKey(name: 'pdf_url') String? pdfUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'profiles') Map<String, dynamic>? patientProfile
});




}
/// @nodoc
class _$PrescriptionCopyWithImpl<$Res>
    implements $PrescriptionCopyWith<$Res> {
  _$PrescriptionCopyWithImpl(this._self, this._then);

  final Prescription _self;
  final $Res Function(Prescription) _then;

/// Create a copy of Prescription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? appointmentId = freezed,Object? doctorName = null,Object? medications = null,Object? instructions = null,Object? pdfUrl = freezed,Object? createdAt = null,Object? patientProfile = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,doctorName: null == doctorName ? _self.doctorName : doctorName // ignore: cast_nullable_to_non_nullable
as String,medications: null == medications ? _self.medications : medications // ignore: cast_nullable_to_non_nullable
as List<String>,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,pdfUrl: freezed == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,patientProfile: freezed == patientProfile ? _self.patientProfile : patientProfile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Prescription].
extension PrescriptionPatterns on Prescription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Prescription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Prescription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Prescription value)  $default,){
final _that = this;
switch (_that) {
case _Prescription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Prescription value)?  $default,){
final _that = this;
switch (_that) {
case _Prescription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'appointment_id')  String? appointmentId, @JsonKey(name: 'doctor_name')  String doctorName,  List<String> medications,  String instructions, @JsonKey(name: 'pdf_url')  String? pdfUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? patientProfile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Prescription() when $default != null:
return $default(_that.id,_that.patientId,_that.appointmentId,_that.doctorName,_that.medications,_that.instructions,_that.pdfUrl,_that.createdAt,_that.patientProfile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'appointment_id')  String? appointmentId, @JsonKey(name: 'doctor_name')  String doctorName,  List<String> medications,  String instructions, @JsonKey(name: 'pdf_url')  String? pdfUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? patientProfile)  $default,) {final _that = this;
switch (_that) {
case _Prescription():
return $default(_that.id,_that.patientId,_that.appointmentId,_that.doctorName,_that.medications,_that.instructions,_that.pdfUrl,_that.createdAt,_that.patientProfile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'appointment_id')  String? appointmentId, @JsonKey(name: 'doctor_name')  String doctorName,  List<String> medications,  String instructions, @JsonKey(name: 'pdf_url')  String? pdfUrl, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? patientProfile)?  $default,) {final _that = this;
switch (_that) {
case _Prescription() when $default != null:
return $default(_that.id,_that.patientId,_that.appointmentId,_that.doctorName,_that.medications,_that.instructions,_that.pdfUrl,_that.createdAt,_that.patientProfile);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Prescription implements Prescription {
  const _Prescription({required this.id, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'appointment_id') this.appointmentId, @JsonKey(name: 'doctor_name') required this.doctorName, required final  List<String> medications, required this.instructions, @JsonKey(name: 'pdf_url') this.pdfUrl, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'profiles') final  Map<String, dynamic>? patientProfile}): _medications = medications,_patientProfile = patientProfile;
  factory _Prescription.fromJson(Map<String, dynamic> json) => _$PrescriptionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'appointment_id') final  String? appointmentId;
@override@JsonKey(name: 'doctor_name') final  String doctorName;
 final  List<String> _medications;
@override List<String> get medications {
  if (_medications is EqualUnmodifiableListView) return _medications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_medications);
}

@override final  String instructions;
@override@JsonKey(name: 'pdf_url') final  String? pdfUrl;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
 final  Map<String, dynamic>? _patientProfile;
@override@JsonKey(name: 'profiles') Map<String, dynamic>? get patientProfile {
  final value = _patientProfile;
  if (value == null) return null;
  if (_patientProfile is EqualUnmodifiableMapView) return _patientProfile;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Prescription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrescriptionCopyWith<_Prescription> get copyWith => __$PrescriptionCopyWithImpl<_Prescription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrescriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Prescription&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.doctorName, doctorName) || other.doctorName == doctorName)&&const DeepCollectionEquality().equals(other._medications, _medications)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._patientProfile, _patientProfile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,appointmentId,doctorName,const DeepCollectionEquality().hash(_medications),instructions,pdfUrl,createdAt,const DeepCollectionEquality().hash(_patientProfile));

@override
String toString() {
  return 'Prescription(id: $id, patientId: $patientId, appointmentId: $appointmentId, doctorName: $doctorName, medications: $medications, instructions: $instructions, pdfUrl: $pdfUrl, createdAt: $createdAt, patientProfile: $patientProfile)';
}


}

/// @nodoc
abstract mixin class _$PrescriptionCopyWith<$Res> implements $PrescriptionCopyWith<$Res> {
  factory _$PrescriptionCopyWith(_Prescription value, $Res Function(_Prescription) _then) = __$PrescriptionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'appointment_id') String? appointmentId,@JsonKey(name: 'doctor_name') String doctorName, List<String> medications, String instructions,@JsonKey(name: 'pdf_url') String? pdfUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'profiles') Map<String, dynamic>? patientProfile
});




}
/// @nodoc
class __$PrescriptionCopyWithImpl<$Res>
    implements _$PrescriptionCopyWith<$Res> {
  __$PrescriptionCopyWithImpl(this._self, this._then);

  final _Prescription _self;
  final $Res Function(_Prescription) _then;

/// Create a copy of Prescription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? appointmentId = freezed,Object? doctorName = null,Object? medications = null,Object? instructions = null,Object? pdfUrl = freezed,Object? createdAt = null,Object? patientProfile = freezed,}) {
  return _then(_Prescription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,doctorName: null == doctorName ? _self.doctorName : doctorName // ignore: cast_nullable_to_non_nullable
as String,medications: null == medications ? _self._medications : medications // ignore: cast_nullable_to_non_nullable
as List<String>,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,pdfUrl: freezed == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,patientProfile: freezed == patientProfile ? _self._patientProfile : patientProfile // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
