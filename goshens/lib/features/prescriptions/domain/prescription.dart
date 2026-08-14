import 'package:freezed_annotation/freezed_annotation.dart';

part 'prescription.freezed.dart';
part 'prescription.g.dart';

@freezed
abstract class Prescription with _$Prescription {
  const factory Prescription({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'appointment_id') String? appointmentId,
    @JsonKey(name: 'doctor_name') required String doctorName,
    required List<String> medications,
    required String instructions,
    @JsonKey(name: 'pdf_url') String? pdfUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'profiles') Map<String, dynamic>? patientProfile,
  }) = _Prescription;

  factory Prescription.fromJson(Map<String, dynamic> json) => _$PrescriptionFromJson(json);
}
