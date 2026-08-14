import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';

class AppointmentCardScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentCardScreen({super.key, required this.appointment});

  @override
  State<AppointmentCardScreen> createState() => _AppointmentCardScreenState();
}

class _AppointmentCardScreenState extends State<AppointmentCardScreen> {
  String? _secureToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSecureToken();
  }

  String _formatAppointmentDate(dynamic value) {
    if (value == null) return 'To be confirmed';
    final dateTime = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dateTime == null) return value.toString();
    return DateFormat('EEEE, MMM d, yyyy • h:mm a').format(dateTime.toLocal());
  }

  Future<void> _fetchSecureToken() async {
    try {
      final response = await Supabase.instance.client
          .from('appointment_qr_tokens')
          .select('secure_token')
          .eq('appointment_id', widget.appointment['id'])
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _secureToken = response?['secure_token'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    if (_secureToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot generate PDF: Secure token missing')),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      final serviceName = widget.appointment['services']?['name'] ?? 'Dental appointment';
      final date = _formatAppointmentDate(widget.appointment['final_start_at'] ?? widget.appointment['requested_date']);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Goshens Dental Care', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Appointment Card', style: const pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blueGrey),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Service: $serviceName', style: const pw.TextStyle(fontSize: 16)),
                        pw.SizedBox(height: 10),
                        pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 16)),
                        pw.SizedBox(height: 20),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: _secureToken!,
                          width: 200,
                          height: 200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'appointment_${widget.appointment['id']}.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ready to download or share')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.appointment['services']?['name'] ?? 'Dental appointment';
    final date = _formatAppointmentDate(widget.appointment['final_start_at'] ?? widget.appointment['requested_date']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment card'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Image.asset('assets/images/Goshens_logo.png', height: 60, errorBuilder: (context, error, stackTrace) => Icon(Icons.local_hospital, size: 60, color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Text(
                        'Goshens Dental Care',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink(context)),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        serviceName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        date,
                        style: TextStyle(fontSize: 16, color: AppColors.muted(context)),
                      ),
                      const SizedBox(height: 32),
                      if (_secureToken != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: QrImageView(
                            data: _secureToken!,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          _secureToken!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Present this QR code at the clinic. Staff can also paste the token above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                        ),
                      ] else ...[
                        Text('QR Code not available yet.', style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _fetchSecureToken();
                          },
                          child: Text('Refresh card'),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _secureToken == null ? null : () => _generateAndSharePDF(context),
                icon: Icon(Icons.download),
                label: Text('Download / Share PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
