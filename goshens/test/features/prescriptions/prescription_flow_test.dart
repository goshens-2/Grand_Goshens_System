import 'package:flutter_test/flutter_test.dart';
import 'package:goshens/core/router/route_names.dart';
import 'package:goshens/features/prescriptions/data/prescription_repository.dart';

void main() {
  group('Prescription medications', () {
    test('parses one medication per line and ignores blanks', () {
      expect(
        parseMedicationLines('Amoxicillin 500mg\n\n Ibuprofen 400mg \n'),
        ['Amoxicillin 500mg', 'Ibuprofen 400mg'],
      );
    });

    test('rejects empty prescriptions', () {
      expect(parseMedicationLines('   \n  '), isEmpty);
    });
  });

  group('Prescription routes', () {
    test('admin can open the writer from a patient record', () {
      expect(RouteNames.adminPatientDetail, 'admin_patient_detail');
      expect(RouteNames.adminPrescription, 'admin_prescription');
      expect(RouteNames.patientPrescriptions, 'patient_prescriptions');
    });
  });
}
