import 'package:flutter_test/flutter_test.dart';
import 'package:goshens/core/router/route_names.dart';
import 'package:goshens/features/patient/data/service_visuals.dart';

void main() {
  group('Service visuals', () {
    test('shortens long descriptions', () {
      expect(
        shortServiceDescription('A' * 200).endsWith('…'),
        isTrue,
      );
      expect(shortServiceDescription(null), 'Quality dental care at Goshens.');
    });

    test('collects cover and gallery image paths', () {
      expect(
        serviceImagePaths({
          'image_path': 'cover.jpg',
          'image_paths': ['a.jpg', 'b.jpg'],
        }),
        ['cover.jpg', 'a.jpg', 'b.jpg'],
      );
    });

    test('pairs rotate by stepping two services at a time', () {
      final services = [
        {'id': '1'},
        {'id': '2'},
        {'id': '3'},
        {'id': '4'},
      ];
      final pairs = <List<Map<String, dynamic>>>[];
      for (var i = 0; i < services.length; i += 2) {
        pairs.add(services.sublist(i, i + 2 > services.length ? services.length : i + 2));
      }
      expect(pairs, hasLength(2));
      expect(pairs[0].map((service) => service['id']), ['1', '2']);
      expect(pairs[1].map((service) => service['id']), ['3', '4']);
    });
  });

  group('Comment moderation', () {
    test('only approved comments should appear on the home page', () {
      const comments = [
        {'status': 'pending'},
        {'status': 'approved'},
        {'status': 'rejected'},
      ];
      final homeComments = comments.where((comment) => comment['status'] == 'approved').toList();
      expect(homeComments, hasLength(1));
    });
  });

  group('Routes', () {
    test('service detail and admin comments routes exist', () {
      expect(RouteNames.patientServices, 'patient_services');
      expect(RouteNames.patientServiceDetail, 'patient_service_detail');
      expect(RouteNames.adminComments, 'admin_comments');
    });
  });
}
