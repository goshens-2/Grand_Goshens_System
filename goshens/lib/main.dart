import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/constants/app_constants.dart';

import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'features/notifications/presentation/notification_host.dart';
import 'features/auth/data/auth_repository.dart';

bool _appStarted = false;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF3F8FB),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    if (kIsWeb) {
      usePathUrlStrategy();
    }

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint(details.toString());
      }
    };

    await _bootstrap();
    _appStarted = true;
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error\n$stackTrace');
    if (!_appStarted) {
      runApp(ProviderScope(child: _StartupErrorApp(message: error.toString())));
    }
  });
}

Future<void> _bootstrap() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Release APKs inject Supabase config via --dart-define-from-file at build time.
  }

  if (!EnvConfig.isConfigured) {
    runApp(const ProviderScope(child: _ConfigurationErrorApp()));
    return;
  }

  if (kDebugMode && EnvConfig.hasServiceRoleLeak) {
    debugPrint('WARNING: Remove SUPABASE_SERVICE_ROLE_KEY from .env before shipping. The app does not use it.');
  }

  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: EnvConfig.supabaseAnonKey,
    );
  } catch (error) {
    runApp(
      ProviderScope(
        child: _StartupErrorApp(
          message: 'Could not connect to Supabase.\n$error',
        ),
      ),
    );
    return;
  }

  runApp(
    const ProviderScope(
      child: GoshensApp(),
    ),
  );
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F9FC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Color(0xFFDC3545)),
                  const SizedBox(height: 16),
                  Text(
                    '${AppConstants.appName} failed to start',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F9FC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  '${AppConstants.appName} is missing configuration.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Copy .env.example to .env and set only SUPABASE_URL and SUPABASE_ANON_KEY. Never put the service-role key in the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoshensApp extends ConsumerWidget {
  const GoshensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          router.goNamed(RouteNames.resetPassword);
        }
      });
    });

    return NotificationHost(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ),
            child: MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25),
              ),
              child: IconTheme(
                data: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
        routerConfig: router,
      ),
    );
  }
}
