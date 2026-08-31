import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static bool get hasServiceRoleLeak {
    const fromDefine = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (fromDefine.trim().isNotEmpty) return true;
    final leaked = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? dotenv.env['SERVICE_ROLE_KEY'] ?? '';
    return leaked.trim().isNotEmpty;
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
