import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/route_names.dart';
import 'auth_route_resolver.dart';
import 'auth_session_cache.dart';

class AuthRouteDecision {
  const AuthRouteDecision({
    required this.routeName,
    this.errorMessage,
    this.shouldSignOut = false,
  });

  final String routeName;
  final String? errorMessage;
  final bool shouldSignOut;
}

class AuthRoutingService {
  const AuthRoutingService(this._client);

  final SupabaseClient _client;

  Future<String?> _fetchRole(String userId) async {
    try {
      final role = await _client.rpc('get_my_role');
      if (role is String && role.isNotEmpty) {
        return role;
      }
    } catch (_) {
      // Fall back to direct table read when RPC is not deployed yet.
    }

    final roleResponse = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();

    return roleResponse?['role'] as String?;
  }

  Future<AuthRouteDecision> resolvePostAuthRoute() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return const AuthRouteDecision(routeName: RouteNames.signIn);
    }

    final email = session.user.email?.trim().toLowerCase();

    try {
      final role = await _fetchRole(session.user.id);
      AuthSessionCache.remember(role);

      if (role == 'admin') {
        await _ensureAdminProfile(session.user.id);
      }

      return resolveRouteFromSessionData(
        role: role,
        email: email,
        fullName: role == 'admin'
            ? 'Goshens Admin'
            : await _fetchFullName(session.user.id),
      );
    } catch (error) {
      AuthSessionCache.clear();
      return resolveRouteFromSessionData(
        role: null,
        email: email,
        fullName: null,
        lookupError: error.toString(),
      );
    }
  }

  Future<String?> _fetchFullName(String userId) async {
    final profile = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    return profile?['full_name'] as String?;
  }

  Future<void> _ensureAdminProfile(String userId) async {
    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (profile != null) return;

    await _client.from('profiles').insert({
      'id': userId,
      'full_name': 'Goshens Admin',
    });
  }
}
