import 'package:flutter/material.dart';

import '../../chat/presentation/clinic_chat_screen.dart';

class PatientChatScreen extends StatelessWidget {
  const PatientChatScreen({
    super.key,
    this.conversationId,
    this.patientId,
    this.title,
    this.peerAvatarPath,
  });

  final String? conversationId;
  final String? patientId;
  final String? title;
  final String? peerAvatarPath;

  @override
  Widget build(BuildContext context) {
    return ClinicChatScreen(
      conversationId: conversationId,
      patientId: patientId,
      title: title,
      peerAvatarPath: peerAvatarPath,
    );
  }
}
