import 'package:supabase_flutter/supabase_flutter.dart';

String formatAuthErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message;

    if (message.contains('Database error querying schema') ||
        message.contains('unexpected_failure')) {
      return 'Supabase auth account is misconfigured. In Supabase SQL Editor, run '
          'supabase_migrations/fix_admin_login.sql, then try again.';
    }

    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }

    if (message.contains('Email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }

    return message;
  }

  return error.toString();
}
