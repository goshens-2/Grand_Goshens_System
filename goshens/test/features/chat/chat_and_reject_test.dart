import 'package:flutter_test/flutter_test.dart';
import 'package:goshens/core/router/route_names.dart';

String chatPreview(String type, String? content) {
  switch (type) {
    case 'image':
      return 'Photo';
    case 'video':
      return 'Video';
    case 'file':
      return 'File';
    default:
      final text = (content ?? '').trim();
      return text.isEmpty ? 'Message' : text;
  }
}

bool canRejectWithReason(String? reason) {
  return (reason ?? '').trim().length >= 6;
}

void main() {
  group('Chat previews', () {
    test('uses media labels for non-text messages', () {
      expect(chatPreview('image', 'nice'), 'Photo');
      expect(chatPreview('video', null), 'Video');
      expect(chatPreview('file', 'x-ray.pdf'), 'File');
      expect(chatPreview('text', 'Hello doctor'), 'Hello doctor');
    });
  });

  group('Reject reason', () {
    test('requires a real reason before rejecting', () {
      expect(canRejectWithReason(null), isFalse);
      expect(canRejectWithReason('no'), isFalse);
      expect(canRejectWithReason('That date is fully booked.'), isTrue);
    });
  });

  group('Chat routes', () {
    test('admin and patient chat routes exist', () {
      expect(RouteNames.patientChat, 'patient_chat');
      expect(RouteNames.adminChats, 'admin_chats');
    });
  });
}
