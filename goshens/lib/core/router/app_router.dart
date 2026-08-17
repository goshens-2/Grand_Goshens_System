import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'route_names.dart';
import 'route_extras.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_session_cache.dart';
import '../../features/auth/data/auth_routing_service.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/patient/presentation/patient_main_screen.dart';
import '../../features/patient/presentation/patient_profile_setup_screen.dart';
import '../../features/patient/presentation/patient_booking_screen.dart';
import '../../features/patient/presentation/patient_bookings_screen.dart';
import '../../features/patient/presentation/appointment_card_screen.dart';
import '../../features/patient/presentation/patient_chat_screen.dart';
import '../../features/admin/presentation/admin_main_screen.dart';
import '../../features/admin/presentation/admin_qr_scanner_screen.dart';
import '../../features/admin/presentation/admin_service_editor_screen.dart';
import '../../features/admin/presentation/admin_availability_screen.dart';
import '../../features/admin/presentation/admin_visit_note_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/prescriptions/presentation/admin_prescription_screen.dart';
import '../../features/prescriptions/presentation/prescriptions_screen.dart';
import '../../features/admin/presentation/admin_patients_list_screen.dart';
import '../../features/admin/presentation/admin_patient_detail_screen.dart';
import '../../features/admin/presentation/admin_appointments_screen.dart';
import '../../features/admin/presentation/admin_clinic_settings_screen.dart';
import '../../features/patient/presentation/clinic_information_screen.dart';
import '../../features/patient/presentation/privacy_information_screen.dart';
import '../../features/patient/presentation/help_support_screen.dart';
import '../../features/patient/presentation/account_settings_screen.dart';
import '../../features/patient/presentation/patient_services_screen.dart';
import '../../features/patient/presentation/service_detail_screen.dart';
import '../../features/admin/presentation/admin_comments_screen.dart';
import '../../features/admin/presentation/admin_analytics_screen.dart';
import '../../features/chat/presentation/admin_chat_inbox_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final refresh = ValueNotifier<int>(0);

  ref.listen(authStateChangesProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  const publicLocations = {'/', '/sign-in', '/sign-up', '/reset-password'};
  const adminPrefixes = ['/admin'];

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) async {
      final isSignedIn = Supabase.instance.client.auth.currentSession != null;
      final location = state.matchedLocation;
      final isPublic = publicLocations.contains(location);

      if (!isSignedIn && !isPublic) {
        return '/sign-in';
      }

      if (!isSignedIn) {
        return null;
      }

      if (location == '/reset-password') {
        return null;
      }

      if (location == '/sign-in' || location == '/sign-up') {
        return '/';
      }

      final isAdminPath = adminPrefixes.any(location.startsWith);
      if (isAdminPath || location == '/patient-home') {
        var role = AuthSessionCache.role;
        if (role == null) {
          final decision = await AuthRoutingService(Supabase.instance.client).resolvePostAuthRoute();
          role = AuthSessionCache.role;
          if (decision.shouldSignOut) {
            await Supabase.instance.client.auth.signOut();
            return '/sign-in';
          }
        }
        if (isAdminPath && role != 'admin') {
          return '/patient-home';
        }
        if (location == '/patient-home' && role == 'admin') {
          return '/admin-dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: RouteNames.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: RouteNames.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/patient-home',
        name: RouteNames.patientHome,
        builder: (context, state) => const PatientMainScreen(),
      ),
      GoRoute(
        path: '/patient-profile-setup',
        name: RouteNames.patientProfileSetup,
        builder: (context, state) => const PatientProfileSetupScreen(),
      ),
      GoRoute(
        path: '/patient-bookings',
        name: RouteNames.patientBookings,
        builder: (context, state) => const PatientBookingsScreen(),
      ),
      GoRoute(
        path: '/patient-services',
        name: RouteNames.patientServices,
        builder: (context, state) {
          final extra = state.extra;
          final query = extra is Map ? extra['query'] as String? : extra as String?;
          return PatientServicesScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/patient-service-detail',
        name: RouteNames.patientServiceDetail,
        builder: (context, state) {
          final extra = asStringKeyedMap(state.extra);
          return ServiceDetailScreen(
            serviceId: extra?['id'] as String? ?? extra?['serviceId'] as String? ?? '',
            initialService: extra,
          );
        },
      ),
      GoRoute(
        path: '/patient-booking',
        name: RouteNames.patientBooking,
        builder: (context, state) {
          final extra = asStringKeyedMap(state.extra);
          return PatientBookingScreen(
            serviceId: extra?['serviceId'] as String? ?? extra?['id'] as String? ?? '',
            serviceName: extra?['serviceName'] as String? ?? extra?['name'] as String? ?? 'General Dental Care',
          );
        },
      ),
      GoRoute(
        path: '/patient-appointment-card',
        name: RouteNames.patientAppointmentCard,
        builder: (context, state) {
          final appointment = asStringKeyedMap(state.extra);
          if (appointment == null) {
            return const PatientBookingsScreen();
          }
          return AppointmentCardScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/patient-chat',
        name: RouteNames.patientChat,
        builder: (context, state) {
          final extra = asStringKeyedMap(state.extra);
          return PatientChatScreen(
            conversationId: extra?['conversationId'] as String?,
            patientId: extra?['patientId'] as String?,
            title: extra?['title'] as String?,
            peerAvatarPath: extra?['avatarPath'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/admin-chats',
        name: RouteNames.adminChats,
        builder: (context, state) => const AdminChatInboxScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: RouteNames.adminDashboard,
        builder: (context, state) => const AdminMainScreen(),
      ),
      GoRoute(
        path: '/admin-qr-scanner',
        name: RouteNames.adminQrScanner,
        builder: (context, state) => const AdminQrScannerScreen(),
      ),
      GoRoute(
        path: '/admin-service-editor',
        name: RouteNames.adminServiceEditor,
        builder: (context, state) {
          final service = asStringKeyedMap(state.extra);
          return AdminServiceEditorScreen(service: service);
        },
      ),
      GoRoute(
        path: '/admin-availability',
        name: RouteNames.adminAvailability,
        builder: (context, state) => const AdminAvailabilityScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin-prescription',
        name: RouteNames.adminPrescription,
        builder: (context, state) {
          final extra = asStringKeyedMap(state.extra);
          return AdminPrescriptionScreen(patientContext: extra);
        },
      ),
      GoRoute(
        path: '/prescriptions',
        name: RouteNames.patientPrescriptions,
        builder: (context, state) => const PrescriptionsScreen(),
      ),
      GoRoute(
        path: '/admin-patients',
        name: RouteNames.adminPatientsList,
        builder: (context, state) => const AdminPatientsListScreen(),
      ),
      GoRoute(
        path: '/admin-patient-detail',
        name: RouteNames.adminPatientDetail,
        builder: (context, state) {
          final patientData = asStringKeyedMap(state.extra);
          if (patientData == null) {
            return const AdminPatientsListScreen();
          }
          return AdminPatientDetailScreen(patientData: patientData);
        },
      ),
      GoRoute(
        path: '/admin-appointments',
        name: RouteNames.adminAppointments,
        builder: (context, state) => const AdminAppointmentsScreen(),
      ),
      GoRoute(
        path: '/admin-visit-note',
        name: RouteNames.adminVisitNote,
        builder: (context, state) {
          final appointment = asStringKeyedMap(state.extra);
          if (appointment == null) {
            return const AdminAppointmentsScreen();
          }
          return AdminVisitNoteScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/admin-clinic-settings',
        name: RouteNames.adminClinicSettings,
        builder: (context, state) => const AdminClinicSettingsScreen(),
      ),
      GoRoute(
        path: '/clinic-information',
        name: RouteNames.clinicInformation,
        builder: (context, state) => const ClinicInformationScreen(),
      ),
      GoRoute(
        path: '/account-settings',
        name: RouteNames.accountSettings,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/admin-comments',
        name: RouteNames.adminComments,
        builder: (context, state) => const AdminCommentsScreen(),
      ),
      GoRoute(
        path: '/admin-analytics',
        name: RouteNames.adminAnalytics,
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/privacy-information',
        name: RouteNames.privacyInformation,
        builder: (context, state) => const PrivacyInformationScreen(),
      ),
      GoRoute(
        path: '/help-support',
        name: RouteNames.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
    ],
  );
}
