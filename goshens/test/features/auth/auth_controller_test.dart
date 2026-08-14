import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:goshens/features/auth/data/auth_controller.dart';
import 'package:goshens/features/auth/data/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  supabase.User? _currentUser;

  @override
  supabase.User? get currentUser => _currentUser;

  @override
  Stream<supabase.AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<supabase.AuthResponse> signInWithEmailPassword(String email, String password) async {
    if (email == 'patient@test.com' && password == 'password') {
      _currentUser = const supabase.User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00.000Z',
      );
      return supabase.AuthResponse(user: _currentUser);
    } else if (email == 'admin@goshens.com' && password == 'admin123') {
      _currentUser = const supabase.User(
        id: 'admin-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00.000Z',
      );
      return supabase.AuthResponse(user: _currentUser);
    } else {
      throw const supabase.AuthException('Invalid login credentials');
    }
  }

  @override
  Future<supabase.AuthResponse> signUp(String email, String password, String fullName) async {
    _currentUser = const supabase.User(
      id: 'new-user-456',
      appMetadata: {},
      userMetadata: {'full_name': 'New Patient'},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00.000Z',
    );
    return supabase.AuthResponse(user: _currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> updateEmail(String email) async {}
}

void main() {
  group('AuthController Tests', () {
    test('Initial state is AsyncData(null)', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
      );

      final state = container.read(authControllerProvider);
      expect(state, const AsyncData<void>(null));
    });

    test('Sign in with valid patient credentials succeeds', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(authControllerProvider.notifier).signIn('patient@test.com', 'password');

      final state = container.read(authControllerProvider);
      expect(state.hasError, false);
      expect(mockRepo.currentUser?.id, 'user-123');
    });

    test('Sign in with invalid credentials sets AsyncError', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(authControllerProvider.notifier).signIn('wrong@test.com', 'wrongpass');

      final state = container.read(authControllerProvider);
      expect(state.hasError, true);
      expect(state.error.toString(), contains('Incorrect email or password'));
    });

    test('Sign up creates new account successfully', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(authControllerProvider.notifier).signUp('new@test.com', 'password', 'New Patient');

      final state = container.read(authControllerProvider);
      expect(state.hasError, false);
      expect(mockRepo.currentUser?.id, 'new-user-456');
    });

    test('Sign out resets session', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(authControllerProvider.notifier).signIn('patient@test.com', 'password');
      expect(mockRepo.currentUser, isNotNull);

      await container.read(authControllerProvider.notifier).signOut();
      expect(mockRepo.currentUser, isNull);
    });
  });
}
