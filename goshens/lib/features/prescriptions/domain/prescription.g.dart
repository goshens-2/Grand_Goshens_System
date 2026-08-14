// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Prescription _$PrescriptionFromJson(Map<String, dynamic> json) =>
    _Prescription(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      doctorName: json['doctor_name'] as String,
      medications: (json['medications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      instructions: json['instructions'] as String,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientProfile: json['profiles'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PrescriptionToJson(_Prescription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'appointment_id': instance.appointmentId,
      'doctor_name': instance.doctorName,
      'medications': instance.medications,
      'instructions': instance.instructions,
      'pdf_url': instance.pdfUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'profiles': instance.patientProfile,
    };
