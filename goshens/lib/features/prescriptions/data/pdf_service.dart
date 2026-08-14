import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/prescription.dart';

part 'pdf_service.g.dart';

class PdfService {
  final SupabaseClient _supabase;

  PdfService(this._supabase);

  Future<String?> generateAndUploadPrescriptionPdf(Prescription prescription, String patientName) async {
    try {
      final pdf = pw.Document();

      // Load Goshens Logo if possible
      pw.Widget? logoWidget;
      try {
        final ByteData bytes = await rootBundle.load('assets/images/Goshens_logo.png');
        final buffer = bytes.buffer;
        final logoImage = pw.MemoryImage(
          buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        logoWidget = pw.Image(logoImage, height: 60);
      } catch (_) {
        // Fallback if logo fails to load
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('GOSHENS DENTAL CARE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('Creating Perfect Smiles', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        pw.SizedBox(height: 5),
                        pw.Text('Kampala, Uganda', style: const pw.TextStyle(fontSize: 12)),
                      ]
                    ),
                    if (logoWidget != null) logoWidget,
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(color: PdfColors.blueGrey),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text('PRESCRIPTION', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Text('Patient: $patientName', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Doctor: ${prescription.doctorName}', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text('Medications:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...prescription.medications.map((med) => pw.Bullet(text: med, style: const pw.TextStyle(fontSize: 14))),
                pw.SizedBox(height: 20),
                pw.Text('Instructions:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(prescription.instructions, style: const pw.TextStyle(fontSize: 14)),
                pw.Spacer(),
                pw.Divider(color: PdfColors.blueGrey),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('Thank you for choosing Goshens Dental Care.', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                )
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // Upload to Supabase Storage (works on web and mobile)
      final storagePath = '${prescription.patientId}/${prescription.id}.pdf';
      await _supabase.storage.from('prescriptions').uploadBinary(
        storagePath,
        pdfBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final pdfUrl = _supabase.storage.from('prescriptions').getPublicUrl(storagePath);
      return pdfUrl;
    } catch (e) {
      debugPrint('Error generating or uploading PDF: $e');
      return null;
    }
  }
}

@riverpod
PdfService pdfService(PdfServiceRef ref) {
  return PdfService(Supabase.instance.client);
}
