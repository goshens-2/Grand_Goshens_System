import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_appointment_repository.dart';

class AdminQrScannerScreen extends ConsumerStatefulWidget {
  const AdminQrScannerScreen({super.key});

  @override
  ConsumerState<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends ConsumerState<AdminQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkInWithToken(String rawValue) async {
    if (_isProcessing || rawValue.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final appointment = await ref
          .read(adminAppointmentRepositoryProvider)
          .getAppointmentByQrToken(rawValue.trim());

      if (appointment != null) {
        final appointmentId = appointment['id'];
        final patientId = appointment['patient_id'];

        await ref.read(adminAppointmentRepositoryProvider).updateAppointmentStatus(
              appointmentId,
              'checked_in',
              patientId: patientId,
              note: 'Patient checked in at clinic.',
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient successfully checked in!'),
              backgroundColor: AppColors.primary,
            ),
          );
          context.pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR Code. Appointment not found.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking in: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        await _checkInWithToken(rawValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Appointment Card'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutWidth = size.width * 0.7;
    final cutoutHeight = cutoutWidth;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    path.addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final borderPath = Path();
    const cornerLength = 30.0;

    borderPath.moveTo(cutoutRect.left, cutoutRect.top + cornerLength);
    borderPath.lineTo(cutoutRect.left, cutoutRect.top);
    borderPath.lineTo(cutoutRect.left + cornerLength, cutoutRect.top);

    borderPath.moveTo(cutoutRect.right - cornerLength, cutoutRect.top);
    borderPath.lineTo(cutoutRect.right, cutoutRect.top);
    borderPath.lineTo(cutoutRect.right, cutoutRect.top + cornerLength);

    borderPath.moveTo(cutoutRect.right, cutoutRect.bottom - cornerLength);
    borderPath.lineTo(cutoutRect.right, cutoutRect.bottom);
    borderPath.lineTo(cutoutRect.right - cornerLength, cutoutRect.bottom);

    borderPath.moveTo(cutoutRect.left + cornerLength, cutoutRect.bottom);
    borderPath.lineTo(cutoutRect.left, cutoutRect.bottom);
    borderPath.lineTo(cutoutRect.left, cutoutRect.bottom - cornerLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
