import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static bool get hasServiceRoleLeak {
    final leaked = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? dotenv.env['SERVICE_ROLE_KEY'] ?? '';
    return leaked.trim().isNotEmpty;
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
