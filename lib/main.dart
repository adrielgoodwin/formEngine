import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/case_repository.dart';
import 'data/load_form.dart';
import 'data/repository_factory.dart';
import 'demo_seed.dart';
import 'logging/app_logger.dart';
import 'pages/dashboard_screen.dart';
import 'state/form_state.dart';

void main() {
  // Initialize logger early, before any Flutter bindings
  final logger = AppLogger.instance;

  // Capture Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    try {
      logger.error(
        'app',
        'Flutter framework error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
    } catch (_) {
      // Never let logging crash the app
    }
    // In debug mode, also show the error in the console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // Capture uncaught async errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final formDef = await loadFormDefinition();
      final repo = await createRepository();

      // Seed demo cases for any repository type (works for both InMemory and File)
      await seedDemoCasesIfEmpty(formDef, repo);

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CaseRepository>(
              create: (_) => repo,
            ),
            ChangeNotifierProvider(
              create: (_) => FormStateProvider(repository: repo),
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      try {
        logger.error(
          'app',
          'Uncaught async error: $error',
          error: error,
          stackTrace: stackTrace,
        );
      } catch (_) {
        // Never let logging crash the app
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Engine',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: _NoTransitionBuilder(),
            TargetPlatform.linux: _NoTransitionBuilder(),
            TargetPlatform.macOS: _NoTransitionBuilder(),
            TargetPlatform.android: _NoTransitionBuilder(),
            TargetPlatform.iOS: _NoTransitionBuilder(),
            TargetPlatform.fuchsia: _NoTransitionBuilder(),
          },
        ),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
