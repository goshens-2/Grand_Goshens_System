import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

/// Brand colors used for the engineering credits shown across the app.
class CompanyCreditColors {
  const CompanyCreditColors._();

  /// Vision Technologies brand color.
  static const Color visionTechnologies = Color(0xFF0066FF);

  /// Altrastate Technologies brand color.
  static const Color altrastateTechnologies = Color(0xFF7C3AED);
}

/// Plain, non-clickable "VISION TECHNOLOGIES" credit text.
///
/// Used on the splash/loading screen and the patient and admin settings
/// screens, where the credit must not be a clickable link.
class VisionTechnologiesCredit extends StatelessWidget {
  const VisionTechnologiesCredit({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      'VISION TECHNOLOGIES',
      style: (style ?? const TextStyle()).copyWith(
        color: CompanyCreditColors.visionTechnologies,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// "Engineered by" credit row shown on the login form, with clickable links
/// (and a link icon) for both Vision Technologies and Altrastate
/// Technologies.
class EngineeredByCredits extends StatelessWidget {
  const EngineeredByCredits({super.key});

  static final Uri _visionUri = Uri(
    scheme: 'mailto',
    path: 'thevisiontechnologies337@gmail.com',
  );
  static final Uri _altrastateUri = Uri.parse('https://www.altrastate.com/');

  static Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme} link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Engineered by: ',
          style: TextStyle(color: AppColors.muted(context), fontSize: 12),
        ),
        _CreditLink(
          label: 'VISION TECHNOLOGIES',
          color: CompanyCreditColors.visionTechnologies,
          onTap: () => _launch(context, _visionUri),
        ),
        Text(
          ' in conjunction with ',
          style: TextStyle(color: AppColors.muted(context), fontSize: 12),
        ),
        _CreditLink(
          label: 'ALTRASTATE TECHNOLOGIES',
          color: CompanyCreditColors.altrastateTechnologies,
          onTap: () => _launch(context, _altrastateUri),
        ),
      ],
    );
  }
}

class _CreditLink extends StatelessWidget {
  const _CreditLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
          ),
        ],
      ),
    );
  }
}
