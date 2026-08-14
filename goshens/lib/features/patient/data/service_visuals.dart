import 'package:flutter/material.dart';

const kServiceCardRotateInterval = Duration(minutes: 5);

const kServiceIconChoices = <String, String>{
  'medical_services': 'General care',
  'cleaning_services': 'Cleaning',
  'healing': 'Treatment',
  'health_and_safety': 'Checkup',
  'sentiment_very_satisfied': 'Whitening / cosmetic',
  'face_retouching_natural': 'Smile design',
  'spa': 'Comfort care',
  'local_hospital': 'Clinic procedure',
  'vaccines': 'Prevention',
  'emergency': 'Emergency',
};

IconData iconForService(String? name) {
  switch (name) {
    case 'cleaning_services':
      return Icons.cleaning_services;
    case 'healing':
      return Icons.healing;
    case 'health_and_safety':
      return Icons.health_and_safety;
    case 'sentiment_very_satisfied':
      return Icons.sentiment_very_satisfied;
    case 'face_retouching_natural':
      return Icons.face_retouching_natural;
    case 'spa':
      return Icons.spa;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'vaccines':
      return Icons.vaccines;
    case 'emergency':
      return Icons.emergency;
    default:
      return Icons.medical_services_outlined;
  }
}

List<String> serviceImagePaths(Map<String, dynamic> service) {
  final paths = <String>[];
  final raw = service['image_paths'];
  if (raw is List) {
    for (final item in raw) {
      if (item is String && item.trim().isNotEmpty) paths.add(item.trim());
    }
  }
  final cover = service['image_path'] as String?;
  if (cover != null && cover.trim().isNotEmpty && !paths.contains(cover.trim())) {
    paths.insert(0, cover.trim());
  }
  return paths;
}

String shortServiceDescription(String? description, {int maxChars = 90}) {
  final text = (description ?? '').trim();
  if (text.isEmpty) return 'Quality dental care at Goshens.';
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars).trimRight()}…';
}
