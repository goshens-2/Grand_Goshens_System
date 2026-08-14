import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'auth_error_messages.dart';
import '../../notifications/data/device_notifications.dart';
import '../../notifications/data/notification_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmailPassword(email, password);
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    } catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signUp(email, password, fullName);
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    } catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      await DeviceNotifications.instance.cancelAll();
      ref.invalidate(userNotificationsProvider);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    } catch (e) {
      state = AsyncError(formatAuthErrorMessage(e), StackTrace.current);
    }
  }
}
