import 'package:goshens/core/constants/app_constants.dart';
import 'package:goshens/core/router/route_names.dart';
import 'package:goshens/features/auth/data/auth_routing_service.dart';

AuthRouteDecision resolveRouteFromSessionData({
  required String? role,
  required String? email,
  required String? fullName,
  String? lookupError,
}) {
  if (lookupError != null) {
    if (email?.trim().toLowerCase() == AppConstants.adminEmail) {
      return AuthRouteDecision(
        routeName: RouteNames.signIn,
        shouldSignOut: true,
        errorMessage: 'Admin sign-in succeeded, but role lookup failed: $lookupError',
      );
    }

    return AuthRouteDecision(
      routeName: RouteNames.patientProfileSetup,
      errorMessage: 'Could not load your account details. Complete your profile to continue.',
    );
  }

  if (role == 'admin') {
    return const AuthRouteDecision(routeName: RouteNames.adminDashboard);
  }

  if (email?.trim().toLowerCase() == AppConstants.adminEmail) {
    return const AuthRouteDecision(
      routeName: RouteNames.signIn,
      shouldSignOut: true,
      errorMessage:
          'This admin account is not activated yet. In Supabase SQL Editor, run:\n'
          'select private.provision_goshens_admin(id)\n'
          'from auth.users where lower(email) = \'admin@goshens.com\';',
    );
  }

  if (fullName == null || fullName.trim().isEmpty) {
    return const AuthRouteDecision(routeName: RouteNames.patientProfileSetup);
  }

  return const AuthRouteDecision(routeName: RouteNames.patientHome);
}
